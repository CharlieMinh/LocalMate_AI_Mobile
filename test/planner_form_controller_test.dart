import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';
import 'package:localmate_ai_mobile/features/planner/application/planner_form_controller.dart';
import 'package:localmate_ai_mobile/features/planner/data/offline_planner_repository.dart';

import 'planner_controller_test.dart' show ControlledAuth;

void main() {
  final now = DateTime.utc(2026, 10, 19, 3); // 10:00 in Vietnam.
  const tag = PlannerTag('a1000000-0000-4000-8000-000000000001', 'Văn hóa');
  const loaded = AsyncValue<List<PlannerTag>>.data([tag]);

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [authProvider.overrideWith(ControlledAuth.new)],
    );
    addTearDown(c.dispose);
    // Keep the autoDispose form alive for the whole test.
    c.listen(plannerFormProvider, (_, _) {});
    return c;
  }

  test('advances one step at a time and only validates that step', () {
    final c = container();
    final form = c.read(plannerFormProvider.notifier)..setBudget('-1');
    expect(form.advance(catalog: loaded, now: now), isA<PlannerMoved>());
    expect(c.read(plannerFormProvider).step, 1);
    expect(form.advance(catalog: loaded, now: now), isA<PlannerInvalid>());
    expect(c.read(plannerFormProvider).errors.keys, ['BudgetMax']);
    expect(c.read(plannerFormProvider).step, 1);
  });

  test('last step jumps back to the step that owns the error', () {
    final c = container();
    final form = c.read(plannerFormProvider.notifier);
    for (var i = 0; i < 3; i++) {
      form.advance(catalog: loaded, now: now);
    }
    expect(c.read(plannerFormProvider).isLastStep, isTrue);
    form.setDate('2026-02-30');
    expect(form.advance(catalog: loaded, now: now), isA<PlannerInvalid>());
    expect(c.read(plannerFormProvider).step, 1);
    expect(c.read(plannerFormProvider).errors, contains('PlannedDate'));
  });

  test('selected interests block while the catalog cannot verify them', () {
    final c = container();
    final form = c.read(plannerFormProvider.notifier);
    form
      ..advance(catalog: loaded, now: now)
      ..advance(catalog: loaded, now: now)
      ..toggleTag(tag.id);
    final result = form.advance(
      catalog: const AsyncValue<List<PlannerTag>>.loading(),
      now: now,
    );
    expect(result, isA<PlannerBlocked>());
    expect(c.read(plannerFormProvider).errors['TagIds'], unverifiedTagsMessage);
    form.removeTag(tag.id);
    expect(
      form.advance(
        catalog: AsyncValue<List<PlannerTag>>.error(
          StateError('x'),
          StackTrace.empty,
        ),
        now: now,
      ),
      isA<PlannerMoved>(),
    );
  });

  test('ready criteria carry form values; back steps then exits', () {
    final c = container();
    final form = c.read(plannerFormProvider.notifier)
      ..setOrigin(3)
      ..setDestination(5)
      ..setDuration(9)
      ..setBudget('250000')
      ..setNote('  yên   tĩnh ');
    PlannerAdvance result = const PlannerMoved();
    for (var i = 0; i < 4; i++) {
      result = form.advance(catalog: loaded, now: now);
    }
    expect(result, isA<PlannerReady>());
    final criteria = (result as PlannerReady).criteria;
    expect(criteria.destinationStationOrder, 5);
    expect(criteria.durationHours, 9);
    expect(criteria.budgetMax, 250000);
    expect(result.availableTags, {tag.id});
    expect(form.back(), isTrue);
    expect(c.read(plannerFormProvider).step, 2);
    form
      ..back()
      ..back();
    expect(form.back(), isFalse);
  });

  test('auth transition resets the form', () {
    final c = container();
    c.read(plannerFormProvider.notifier)
      ..setOrigin(7)
      ..advance(catalog: loaded, now: now);
    (c.read(authProvider.notifier) as ControlledAuth).transition();
    final state = c.read(plannerFormProvider);
    expect(state.origin, 1);
    expect(state.step, 0);
  });
}
