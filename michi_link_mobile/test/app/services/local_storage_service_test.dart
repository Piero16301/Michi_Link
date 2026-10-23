import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorageRepositoryInternal extends Mock
    implements LocalStorageRepository {}

void main() {
  group('LocalStorageService', () {
    late MockLocalStorageRepositoryInternal repository;
    late LocalStorageService service;

    setUp(() {
      repository = MockLocalStorageRepositoryInternal();
      service = LocalStorageService(localStorageRepository: repository);
    });

    test('initialize delegates to repository', () async {
      when(() => repository.initialize()).thenAnswer((_) async {});
      await service.initialize();
      verify(() => repository.initialize()).called(1);
    });

    test('saveLanguage and getLanguage delegate to repository', () {
      const locale = Locale('es', 'ES');
      when(() => repository.saveLanguage(language: locale)).thenReturn(null);
      when(() => repository.getLanguage()).thenReturn(locale);

      service.saveLanguage(language: locale);
      verify(() => repository.saveLanguage(language: locale)).called(1);

      expect(service.getLanguage(), locale);
      verify(() => repository.getLanguage()).called(1);
    });

    test('saveTheme and getTheme delegate to repository', () {
      when(() => repository.saveTheme(theme: ThemeMode.dark)).thenReturn(null);
      when(() => repository.getTheme()).thenReturn(ThemeMode.dark);

      service.saveTheme(theme: ThemeMode.dark);
      verify(() => repository.saveTheme(theme: ThemeMode.dark)).called(1);

      expect(service.getTheme(), ThemeMode.dark);
      verify(() => repository.getTheme()).called(1);
    });

    test('saveBaseColor and getBaseColor delegate to repository', () {
      when(
        () => repository.saveBaseColor(baseColor: Colors.purple),
      ).thenReturn(null);
      when(() => repository.getBaseColor()).thenReturn(Colors.purple);

      service.saveBaseColor(baseColor: Colors.purple);
      verify(
        () => repository.saveBaseColor(baseColor: Colors.purple),
      ).called(1);

      expect(service.getBaseColor(), Colors.purple);
      verify(() => repository.getBaseColor()).called(1);
    });

    test('saveFontFamily and getFontFamily delegate to repository', () {
      when(
        () => repository.saveFontFamily(fontFamily: 'Roboto'),
      ).thenReturn(null);
      when(() => repository.getFontFamily()).thenReturn('Roboto');

      service.saveFontFamily(fontFamily: 'Roboto');
      verify(() => repository.saveFontFamily(fontFamily: 'Roboto')).called(1);

      expect(service.getFontFamily(), 'Roboto');
      verify(() => repository.getFontFamily()).called(1);
    });

    test(
      'saveCollars, getCollars and getCollarsStream delegate to repository',
      () {
        final collars = ['COLLAR_1', 'COLLAR_2'];
        when(() => repository.saveCollars(collars: collars)).thenReturn(null);
        when(() => repository.getCollars()).thenReturn(collars);
        when(
          () => repository.getCollarsStream(),
        ).thenAnswer((_) => Stream.value(collars));

        service.saveCollars(collars: collars);
        verify(() => repository.saveCollars(collars: collars)).called(1);

        expect(service.getCollars(), collars);
        verify(() => repository.getCollars()).called(1);

        expect(service.getCollarsStream(), emits(collars));
        verify(() => repository.getCollarsStream()).called(1);
      },
    );

    test('saveSelectedCollarId, getSelectedCollarId and stream delegate', () {
      when(
        () => repository.saveSelectedCollarId(collarId: 'COLLAR_1'),
      ).thenReturn(null);
      when(() => repository.getSelectedCollarId()).thenReturn('COLLAR_1');
      when(
        () => repository.getSelectedCollarIdStream(),
      ).thenAnswer((_) => Stream.value('COLLAR_1'));

      service.saveSelectedCollarId(collarId: 'COLLAR_1');
      verify(
        () => repository.saveSelectedCollarId(collarId: 'COLLAR_1'),
      ).called(1);

      expect(service.getSelectedCollarId(), 'COLLAR_1');
      verify(() => repository.getSelectedCollarId()).called(1);

      expect(service.getSelectedCollarIdStream(), emits('COLLAR_1'));
      verify(() => repository.getSelectedCollarIdStream()).called(1);
    });
  });
}
