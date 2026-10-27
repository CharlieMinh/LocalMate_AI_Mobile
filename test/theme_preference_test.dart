import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/ui_providers.dart';

class _MemoryStore implements PreferenceStore {
  _MemoryStore([Map<String, String>? values]) : values = {...?values};
  final Map<String, String> values;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _BrokenStore implements PreferenceStore {
  @override
  Future<String?> read(String key) => Future.error(StateError('no storage'));
  @override
  Future<void> write(String key, String value) =>
      Future.error(StateError('no storage'));
}

ProviderContainer _container(PreferenceStore store) {
  final c = ProviderContainer(
    overrides: [preferenceStoreProvider.overrideWithValue(store)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('appearance choice is saved and restored on next launch', () async {
    final store = _MemoryStore();
    final first = _container(store);
    expect(first.read(themeModeProvider), ThemeMode.system);
    await Future<void>.delayed(Duration.zero);
    first.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    expect(store.values.values, ['dark']);

    final next = _container(store);
    expect(next.read(themeModeProvider), ThemeMode.system);
    await Future<void>.delayed(Duration.zero);
    expect(next.read(themeModeProvider), ThemeMode.dark);
  });

  test('a choice made before the stored value loads wins', () async {
    final c = _container(_MemoryStore({'localmate.prefs.themeMode': 'dark'}));
    c.read(themeModeProvider.notifier).set(ThemeMode.light);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(themeModeProvider), ThemeMode.light);
  });

  test('unknown values and storage errors keep the system default', () async {
    final junk = _container(
      _MemoryStore({'localmate.prefs.themeMode': 'sepia'}),
    );
    junk.read(themeModeProvider);
    await Future<void>.delayed(Duration.zero);
    expect(junk.read(themeModeProvider), ThemeMode.system);

    final broken = _container(_BrokenStore());
    broken.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    expect(broken.read(themeModeProvider), ThemeMode.dark);
  });
}
