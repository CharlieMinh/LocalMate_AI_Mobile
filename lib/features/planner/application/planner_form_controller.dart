import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../trips/domain/trip_models.dart';
import '../data/offline_planner_repository.dart';
import '../domain/planner_criteria.dart';

/// Wizard steps, in order.
const plannerStepCount = 4;

/// Validation keys owned by each wizard step (last step validates all).
const _stepKeys = <int, Set<String>>{
  0: {'StartStationOrder', 'DestinationStationOrder', 'Origin'},
  1: {'DurationHours', 'PlannedDate', 'StartTime', 'BudgetMax'},
  2: {'TagIds'},
};
const _timeKeys = {'PlannedDate', 'StartTime', 'BudgetMax', 'DurationHours'};

const unverifiedTagsMessage =
    'Sở thích đã chọn chưa thể xác minh. Hãy thử lại hoặc chủ động bỏ lựa chọn.';

class PlannerFormState {
  const PlannerFormState({
    this.step = 0,
    this.origin = 1,
    this.destination,
    this.durationHours = 4,
    this.mode = PlannerTravelMode.auto,
    this.tags = const {},
    this.date = '',
    this.time = '',
    this.budget = '0',
    this.note = '',
    this.errors = const {},
  });

  final int step;
  final int origin;
  final int? destination;
  final int durationHours;
  final PlannerTravelMode mode;
  final Set<String> tags;

  /// Raw `yyyy-MM-dd`; empty = server default (today).
  final String date;

  /// Raw `HH:mm`; empty = server default (08:00).
  final String time;

  /// Raw VND per person, as typed.
  final String budget;
  final String note;

  /// Errors for the current step only.
  final Map<String, String> errors;

  bool get isLastStep => step == plannerStepCount - 1;

  PlannerFormState copyWith({
    int? step,
    int? origin,
    int? Function()? destination,
    int? durationHours,
    PlannerTravelMode? mode,
    Set<String>? tags,
    String? date,
    String? time,
    String? budget,
    String? note,
    Map<String, String>? errors,
  }) => PlannerFormState(
    step: step ?? this.step,
    origin: origin ?? this.origin,
    destination: destination == null ? this.destination : destination(),
    durationHours: durationHours ?? this.durationHours,
    mode: mode ?? this.mode,
    tags: tags ?? this.tags,
    date: date ?? this.date,
    time: time ?? this.time,
    budget: budget ?? this.budget,
    note: note ?? this.note,
    errors: errors ?? this.errors,
  );

  PlannerCriteria toCriteria() => PlannerCriteria(
    origin: StationOrigin(origin),
    destinationStationOrder: destination,
    durationHours: durationHours,
    budgetMax: double.tryParse(budget.trim()) ?? double.nan,
    tagIds: tags.toList(),
    travelMode: mode,
    plannedDate: date.trim().isEmpty ? null : date.trim(),
    startTime: time.trim().isEmpty ? null : time.trim(),
    note: note,
  );
}

/// Outcome of pressing the wizard's primary action.
sealed class PlannerAdvance {
  const PlannerAdvance();
}

/// Selected interests cannot be verified (catalog loading or failed).
class PlannerBlocked extends PlannerAdvance {
  const PlannerBlocked();
}

/// Validation failed; errors are on state (possibly after jumping back).
class PlannerInvalid extends PlannerAdvance {
  const PlannerInvalid();
}

class PlannerMoved extends PlannerAdvance {
  const PlannerMoved();
}

/// Last step validated; criteria are ready for [PlannerController.submit].
class PlannerReady extends PlannerAdvance {
  const PlannerReady(this.criteria, this.availableTags);
  final PlannerCriteria criteria;
  final Set<String> availableTags;
}

/// Wizard form state, separated from the widgets. Any auth transition
/// (including same-account re-login) resets the form, matching the
/// previous behaviour of re-keying the form widget by auth state.
class PlannerFormController extends Notifier<PlannerFormState> {
  @override
  PlannerFormState build() {
    ref.watch(authProvider);
    return const PlannerFormState();
  }

  void setOrigin(int order) => state = state.copyWith(origin: order);
  void setDestination(int? order) =>
      state = state.copyWith(destination: () => order);
  void setDuration(int hours) => state = state.copyWith(durationHours: hours);
  void setMode(PlannerTravelMode mode) => state = state.copyWith(mode: mode);
  void setDate(String value) => state = state.copyWith(date: value);
  void setTime(String value) => state = state.copyWith(time: value);
  void setBudget(String value) => state = state.copyWith(budget: value);
  void setNote(String value) => state = state.copyWith(note: value);

  /// Applies AI-parsed fields ("Điền giúp tôi") and returns to the first
  /// step so the user reviews every choice. Missing fields keep their value.
  void applyParsed(ParsedTripRequest p) {
    final mode = switch (p.travelMode) {
      'Walking' => PlannerTravelMode.walking,
      'Motorbike' => PlannerTravelMode.motorbike,
      'Metro' => PlannerTravelMode.metro,
      'Auto' => PlannerTravelMode.auto,
      _ => null,
    };
    final time = p.startTime;
    state = state.copyWith(
      step: 0,
      origin: p.startStationOrder,
      destination: p.destinationStationOrder == null
          ? null
          : () => p.destinationStationOrder,
      durationHours: p.durationHours,
      mode: mode,
      tags: p.tagIds.isEmpty ? null : p.tagIds.toSet(),
      date: p.plannedDate,
      time: time != null && time.length >= 5 ? time.substring(0, 5) : null,
      budget: p.budgetMax?.round().toString(),
      note: p.note,
      errors: const {},
    );
  }

  void toggleTag(String id) {
    final tags = {...state.tags};
    tags.contains(id) ? tags.remove(id) : tags.add(id);
    state = state.copyWith(tags: tags);
  }

  void removeTag(String id) =>
      state = state.copyWith(tags: {...state.tags}..remove(id));

  void clearError(String key) =>
      state = state.copyWith(errors: {...state.errors}..remove(key));

  /// Steps back; false when already on the first step (caller leaves).
  bool back() {
    if (state.step == 0) return false;
    state = state.copyWith(step: state.step - 1, errors: const {});
    return true;
  }

  PlannerAdvance advance({
    required AsyncValue<List<PlannerTag>> catalog,
    required DateTime now,
  }) {
    final form = state;
    if (form.step >= 2 &&
        (catalog.isLoading || (catalog.hasError && form.tags.isNotEmpty))) {
      state = form.copyWith(
        step: 2,
        errors: {...form.errors, 'TagIds': unverifiedTagsMessage},
      );
      return const PlannerBlocked();
    }
    final available = (catalog.asData?.value ?? const <PlannerTag>[])
        .map((tag) => tag.id)
        .toSet();
    final criteria = form.toCriteria();
    final errors = criteria.validate(now, availableTags: available);
    final keys = _stepKeys[form.step] ?? errors.keys.toSet();
    final current = {
      for (final e in errors.entries)
        if (keys.contains(e.key)) e.key: e.value,
    };
    if (current.isNotEmpty) {
      var step = form.step;
      if (form.isLastStep) {
        if (current.keys.any(_timeKeys.contains)) {
          step = 1;
        } else if (current.containsKey('TagIds')) {
          step = 2;
        }
      }
      state = form.copyWith(step: step, errors: current);
      return const PlannerInvalid();
    }
    if (!form.isLastStep) {
      state = form.copyWith(step: form.step + 1, errors: const {});
      return const PlannerMoved();
    }
    return PlannerReady(criteria, available);
  }
}

final plannerFormProvider =
    NotifierProvider.autoDispose<PlannerFormController, PlannerFormState>(
      PlannerFormController.new,
    );
