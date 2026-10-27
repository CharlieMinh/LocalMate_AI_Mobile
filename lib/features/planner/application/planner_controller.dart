import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/api_messages.dart';
import '../../trips/application/trips_providers.dart';
import '../data/api_planner_repository.dart';
import '../../../core/session/session_scope.dart';
import '../../auth/application/auth_controller.dart';
import '../data/offline_planner_repository.dart';
import '../domain/planner_criteria.dart';

enum PlannerPhase { idle, processing, ready, error, outcomeUnknown }

class PlannerPreviewSequence {
  int value = 0;
}

final plannerPreviewSequenceProvider = Provider(
  (ref) => PlannerPreviewSequence(),
);

class PlannerState {
  const PlannerState({
    this.phase = PlannerPhase.idle,
    this.preview,
    this.errors = const {},
    this.message,
    this.failure,
  });
  final PlannerPhase phase;
  final OfflineDraftPreview? preview;
  final Map<String, String> errors;
  final String? message;
  final ApiFailure? failure;
}

final plannerNowProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final plannerRepositoryProvider = Provider<PlannerRepository>(
  (ref) => ref.watch(configProvider).mockOnly
      ? const OfflinePlannerRepository()
      : ApiPlannerRepository(ref.watch(tripsRepositoryProvider)),
);
final plannerTagsProvider = FutureProvider.autoDispose<List<PlannerTag>>((ref) {
  final token = CancelToken();
  ref.onDispose(() => token.cancel('catalog disposed'));
  return ref.watch(plannerRepositoryProvider).loadTags(token);
}, retry: (_, _) => null);

final plannerProvider =
    NotifierProvider.autoDispose<PlannerController, PlannerState>(
      PlannerController.new,
    );

class PlannerController extends Notifier<PlannerState> {
  int _operation = 0;
  bool _alive = true;
  CancelToken? _cancel;
  late SessionScope _ownerScope;
  late SessionScope _globalScope;
  late SessionLease _globalLease;
  @override
  PlannerState build() {
    // Every auth transition, including same-account reauthentication, discards
    // ephemeral previews. Guests have a local-only owner, never a JWT identity.
    final auth = ref.watch(authProvider);
    _operation++;
    _cancel?.cancel('owner changed');
    _alive = true;
    _globalScope = ref.read(sessionProvider);
    _globalLease = _globalScope.lease;
    final scope = SessionScope()
      ..changeOwner(auth.profile?.id ?? 'offline:guest');
    _ownerScope = scope;
    ref.onDispose(() {
      _alive = false;
      _operation++;
      _cancel?.cancel('planner disposed');
      scope.dispose();
    });
    return const PlannerState();
  }

  bool _current(int operation, SessionScope owner, SessionLease lease) =>
      _alive &&
      operation == _operation &&
      owner.owns(lease) &&
      _globalScope.lease.generation == _globalLease.generation;

  void interrupt() {
    _operation++;
    _cancel?.cancel('planner interrupted');
    if (_alive) state = const PlannerState();
  }

  Future<OfflineDraftPreview?> submit(
    PlannerCriteria criteria, {
    Set<String>? availableTags,
  }) async {
    if (!_alive || state.phase == PlannerPhase.processing) return null;
    final errors = criteria.validate(
      ref.read(plannerNowProvider)(),
      availableTags: availableTags,
    );
    if (errors.isNotEmpty) {
      state = PlannerState(errors: errors);
      return null;
    }
    final operation = ++_operation;
    final owner = _ownerScope;
    final lease = owner.lease;
    _cancel = CancelToken();
    final token = _cancel!;
    // Set synchronously before the first await; never automatically retry.
    state = const PlannerState(phase: PlannerPhase.processing);
    try {
      final preview = await ref
          .read(plannerRepositoryProvider)
          .preview(
            criteria,
            ref.read(plannerNowProvider)(),
            'offline-preview:${++ref.read(plannerPreviewSequenceProvider).value}',
            token,
          );
      if (!_current(operation, owner, lease) || token.isCancelled) return null;
      state = PlannerState(phase: PlannerPhase.ready, preview: preview);
      return preview;
    } catch (error) {
      if (!_current(operation, owner, lease) || token.isCancelled) return null;
      if (error is ApiFailure && !ref.read(configProvider).mockOnly) {
        state = PlannerState(
          phase: PlannerPhase.error,
          failure: error,
          errors: {
            for (final e in error.fields.entries)
              if (e.value.isNotEmpty) e.key: e.value.first,
          },
          message: apiErrorMessage(
            error,
            fallback: 'Chưa tạo được lịch trình. Bạn có thể thử lại.',
          ),
        );
        return null;
      }
      state = const PlannerState(
        phase: PlannerPhase.error,
        failure: ApiFailure(FailureKind.unavailable),
        message: 'Không thể tạo bản mẫu cục bộ. Bạn có thể thử lại; chưa có Trip nào được lưu.',
      );
      return null;
    }
  }
}
