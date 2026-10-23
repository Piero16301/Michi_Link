// Platform interface packages are used to redirect Hive temporary test storage.
// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPerformanceService extends Mock implements PerformanceService {}

class MockPerformanceTrace extends Mock implements Trace {}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  FakePathProviderPlatform(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(MockPerformanceTrace());
  });

  group('LocalStorageRepository', () {
    test('MockLocalStorageRepository returns default values', () async {
      final repo = MockLocalStorageRepository();

      await repo.initialize();
      expect(repo.getLanguage(), const Locale('en', 'US'));
      expect(repo.getTheme(), ThemeMode.light);
      expect(repo.getBaseColor(), Colors.blue);
      expect(repo.getFontFamily(), 'default');
      expect(repo.getCollars(), isEmpty);
      expect(repo.getCollarsStream(), emitsDone);
      expect(repo.getSelectedCollarId(), isNull);
      expect(repo.getSelectedCollarIdStream(), emitsDone);

      expect(
        () => repo.saveLanguage(language: const Locale('es')),
        returnsNormally,
      );
      expect(() => repo.saveTheme(theme: ThemeMode.dark), returnsNormally);
      expect(() => repo.saveBaseColor(baseColor: Colors.red), returnsNormally);
      expect(() => repo.saveFontFamily(fontFamily: 'Inter'), returnsNormally);
      expect(() => repo.saveCollars(collars: ['1']), returnsNormally);
      expect(() => repo.saveSelectedCollarId(collarId: '1'), returnsNormally);
    });

    group('HiveLocalStorageRepository', () {
      late Directory tempDir;
      late MockPerformanceService performance;
      late MockPerformanceTrace trace;
      late HiveLocalStorageRepository repo;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('hive_test_');
        PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

        trace = MockPerformanceTrace();
        performance = MockPerformanceService();
        when(() => performance.startTrace(any())).thenReturn(trace);
        when(() => performance.stopTrace(any())).thenReturn(null);

        await getIt.reset();
        getIt.registerSingleton<PerformanceService>(performance);

        repo = HiveLocalStorageRepository();
        await repo.initialize();
      });

      tearDown(() async {
        await Hive.close();
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('initialize handles already open boxes', () async {
        final secondRepo = HiveLocalStorageRepository();
        await secondRepo.initialize();
        verify(() => performance.startTrace('hive_initialization')).called(2);
      });

      test('saveLanguage and getLanguage work correctly', () async {
        expect(repo.getLanguage(), isNull);

        const locale = Locale('es', 'ES');
        repo.saveLanguage(language: locale);
        await Future<void>.delayed(Duration.zero);

        expect(repo.getLanguage(), locale);
      });

      test('saveTheme and getTheme work correctly', () async {
        expect(repo.getTheme(), isNull);

        repo.saveTheme(theme: ThemeMode.dark);
        await Future<void>.delayed(Duration.zero);

        expect(repo.getTheme(), ThemeMode.dark);
      });

      test('saveBaseColor and getBaseColor work correctly', () async {
        expect(repo.getBaseColor(), isNull);

        repo.saveBaseColor(baseColor: Colors.deepPurple);
        await Future<void>.delayed(Duration.zero);

        expect(repo.getBaseColor(), Colors.deepPurple);
      });

      test('saveFontFamily and getFontFamily work correctly', () async {
        expect(repo.getFontFamily(), isNull);

        repo.saveFontFamily(fontFamily: 'Roboto');
        await Future<void>.delayed(Duration.zero);

        expect(repo.getFontFamily(), 'Roboto');
      });

      test(
        'saveCollars and getCollars handle empty and non-empty lists',
        () async {
          expect(repo.getCollars(), isEmpty);

          repo.saveCollars(collars: ['COLLAR_1', 'COLLAR_2']);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(repo.getCollars(), ['COLLAR_1', 'COLLAR_2']);

          repo.saveCollars(collars: []);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(repo.getCollars(), isEmpty);
        },
      );

      test('getCollarsStream emits updates when collars change', () async {
        expect(
          repo.getCollarsStream(),
          emitsInOrder([
            isEmpty,
            ['COLLAR_A'],
          ]),
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.saveCollars(collars: ['COLLAR_A']);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      test(
        'saveSelectedCollarId and getSelectedCollarId handle id and null',
        () async {
          expect(repo.getSelectedCollarId(), isNull);

          repo.saveSelectedCollarId(collarId: 'COLLAR_SELECT');
          await Future<void>.delayed(Duration.zero);
          expect(repo.getSelectedCollarId(), 'COLLAR_SELECT');

          repo.saveSelectedCollarId();
          await Future<void>.delayed(Duration.zero);
          expect(repo.getSelectedCollarId(), isNull);
        },
      );

      test(
        'getSelectedCollarIdStream emits updates when selected id changes',
        () async {
          expect(
            repo.getSelectedCollarIdStream(),
            emitsInOrder([isNull, 'COLLAR_99']),
          );

          await Future<void>.delayed(const Duration(milliseconds: 20));
          repo.saveSelectedCollarId(collarId: 'COLLAR_99');
          await Future<void>.delayed(const Duration(milliseconds: 50));
        },
      );
    });
  });
}
