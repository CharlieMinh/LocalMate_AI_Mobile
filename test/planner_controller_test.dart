import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';
import 'package:localmate_ai_mobile/features/auth/domain/auth_contracts.dart';
import 'package:localmate_ai_mobile/features/planner/application/planner_controller.dart';
import 'package:localmate_ai_mobile/features/planner/data/offline_planner_repository.dart';
import 'package:localmate_ai_mobile/features/planner/domain/planner_criteria.dart';

class ControlledAuth extends AuthController {
  @override
  AuthState build() => const AuthState(AuthPhase.signedOut);
  void transition() => state = AuthState(AuthPhase.signedOut);
  void account(String? owner) {
    ref.read(sessionProvider).changeOwner(owner);
    state = owner == null
        ? const AuthState(AuthPhase.signedOut)
        : AuthState(
            AuthPhase.signedIn,
            profile: AuthProfile(
              id: owner,
              fullName: 'Offline fixture',
              email: 'fixture@example.invalid',
            ),
          );
  }

  @override
  void checkExpiry() {}
}

class DelayedPlanner implements PlannerRepository {
  int calls = 0;
  final pending = <Completer<OfflineDraftPreview>>[];
  final tokens = <CancelToken>[];
  @override
  Future<List<PlannerTag>> loadTags(CancelToken cancel) async => [];
  @override
  Future<OfflineDraftPreview> preview(
    PlannerCriteria c,
    DateTime now,
    String key,
    CancelToken token,
  ) {
    calls++;
    tokens.add(token);
    final completer = Completer<OfflineDraftPreview>();
    pending.add(completer);
    return completer.future;
  }

  void complete(int index) => pending[index].complete(
    OfflineDraftPreview(
      localKey: 'offline-preview:$index',
      criteria: PlannerCriteria(origin: const StationOrigin(1)),
      start: DateTime.utc(2026, 10, 19, 8),
      end: DateTime.utc(2026, 10, 19, 12),
      sampleStops: const [],
    ),
  );
}

void main() {
  late ProviderContainer container;
  late DelayedPlanner repo;
  final criteria = PlannerCriteria(origin: const StationOrigin(1));
  setUp(() {
    repo = DelayedPlanner();
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(ControlledAuth.new),
        plannerRepositoryProvider.overrideWithValue(repo),
        plannerNowProvider.overrideWithValue(
          () => DateTime.utc(2026, 10, 19, 3),
        ),
        apiProvider.overrideWith(
          (_) => throw StateError('Live transport forbidden'),
        ),
      ],
    );
    container.listen(plannerProvider, (_, _) {});
  });
  tearDown(() => container.dispose());
  for (final next in [null, 'offline-A', 'offline-B']) {
    for (final error in [false, true]) {
      test('logout/account switch/relogin $next late error=$error', () async {
        final auth = container.read(authProvider.notifier) as ControlledAuth;
        auth.account('offline-A');
        container.read(plannerProvider);
        final pending = container
            .read(plannerProvider.notifier)
            .submit(criteria);
        auth.account(next);
        expect(container.read(plannerProvider).preview, isNull);
        if (error) {
          repo.pending.single.completeError(StateError('obsolete'));
        } else {
          repo.complete(0);
        }
        expect(await pending, isNull);
        expect(container.read(plannerProvider).phase, PlannerPhase.idle);
      });
    }
  }
  test('double tap blocked synchronously and no automatic retry', () async {
    final notifier = container.read(plannerProvider.notifier);
    final first = notifier.submit(criteria);
    expect(container.read(plannerProvider).phase, PlannerPhase.processing);
    expect(await notifier.submit(criteria), isNull);
    expect(repo.calls, 1);
    repo.pending.single.completeError(StateError('offline failure'));
    expect(await first, isNull);
    expect(container.read(plannerProvider).phase, PlannerPhase.error);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls, 1);
  });
  for (final failure in [false, true]) {
    test(
      'auth transition fences late ${failure ? 'error' : 'success'}',
      () async {
        final first = container.read(plannerProvider.notifier).submit(criteria);
        (container.read(authProvider.notifier) as ControlledAuth).transition();
        expect(container.read(plannerProvider).phase, PlannerPhase.idle);
        expect(repo.tokens.single.isCancelled, isTrue);
        if (failure) {
          repo.pending.single.completeError(StateError('stale'));
        } else {
          repo.complete(0);
        }
        expect(await first, isNull);
        expect(container.read(plannerProvider).preview, isNull);
        expect(container.read(plannerProvider).message, isNull);
      },
    );
  }
  test(
    'same owner generation change fences response even without auth rebuild',
    () async {
      final future = container.read(plannerProvider.notifier).submit(criteria);
      container.read(sessionProvider).changeOwner('same-account');
      container.read(sessionProvider).changeOwner('same-account');
      repo.complete(0);
      expect(await future, isNull);
    },
  );
  test(
    'interrupt background then newer preview cannot be overwritten',
    () async {
      final notifier = container.read(plannerProvider.notifier);
      final first = notifier.submit(criteria);
      notifier.interrupt();
      expect(repo.tokens[0].isCancelled, isTrue);
      final second = notifier.submit(criteria);
      repo.complete(1);
      final latest = await second;
      repo.complete(0);
      expect(await first, isNull);
      expect(container.read(plannerProvider).preview, same(latest));
      expect(repo.calls, 2);
    },
  );
  test('route/provider disposal cannot update or navigate', () async {
    final future = container.read(plannerProvider.notifier).submit(criteria);
    container.invalidate(plannerProvider);
    repo.complete(0);
    expect(await future, isNull);
    expect(container.read(plannerProvider).preview, isNull);
  });
  test('invalid form never calls preview repository', () async {
    await container
        .read(plannerProvider.notifier)
        .submit(PlannerCriteria(origin: const StationOrigin(0)));
    expect(
      container.read(plannerProvider).errors,
      contains('StartStationOrder'),
    );
    expect(repo.calls, 0);
  });
  test('process restart has no persisted preview', () {
    expect(container.read(plannerProvider).preview, isNull);
    expect(container.read(plannerProvider).phase, PlannerPhase.idle);
    expect(repo.calls, 0);
  });
}
