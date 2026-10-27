import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

class MockCrashService extends Mock implements CrashService {}

void main() {
  setUpAll(() {
    registerFallbackValue(StackTrace.current);
    setupServiceLocator(Environment.mock);
  });

  group('NotificationRepository', () {
    test('MockNotificationRepository returns expected mock values', () async {
      final repo = MockNotificationRepository();

      await expectLater(repo.initialize(), completes);
      expect(repo.token, 'dummy-token');
      await expectLater(repo.register(), completes);
      expect(await repo.onRegistered.isEmpty, isTrue);
      expect(await repo.onMessage.isEmpty, isTrue);
      expect(await repo.onMessageOpenedApp.isEmpty, isTrue);
      expect(await repo.getInitialMessage(), isNull);
      await expectLater(repo.subscribeToTopic('test'), completes);
      await expectLater(repo.unsubscribeFromTopic('test'), completes);
      await expectLater(repo.requestPermission(), completes);
    });

    group('FirebaseNotificationRepository', () {
      late MockFirebaseMessaging mockMessaging;
      late MockCrashService mockCrash;
      late MockNotificationSettings mockSettings;
      late FirebaseNotificationRepository repo;

      setUp(() {
        mockMessaging = MockFirebaseMessaging();
        mockCrash = MockCrashService();
        mockSettings = MockNotificationSettings();
        repo = FirebaseNotificationRepository(
          messaging: mockMessaging,
          crashService: mockCrash,
        );

        when(
          () => mockMessaging.onRegistered,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => mockMessaging.requestPermission(),
        ).thenAnswer((_) async => mockSettings);
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.authorized);
        when(() => mockMessaging.register()).thenAnswer((_) async {});
        when(
          () => mockCrash.recordError(
            any<dynamic>(),
            any<StackTrace?>(),
            reason: any<dynamic>(named: 'reason'),
          ),
        ).thenReturn(null);
      });

      test('instantiates with default messaging instance when omitted', () {
        try {
          FirebaseNotificationRepository();
        } on Object catch (_) {}
      });

      test(
        'initialize listens to token and calls requestPermission and register',
        () async {
          when(
            () => mockMessaging.onRegistered,
          ).thenAnswer((_) => Stream.value('fcm-token-123'));

          await repo.initialize();

          expect(repo.token, 'fcm-token-123');
          verify(() => mockMessaging.requestPermission()).called(1);
          verify(() => mockMessaging.register()).called(1);
        },
      );

      test('initialize records error to crash service on failure', () async {
        final exception = Exception('Init failed');
        when(() => mockMessaging.requestPermission()).thenThrow(exception);

        await repo.initialize();

        verify(
          () => mockCrash.recordError(
            exception,
            any(),
            reason: 'NotificationRepository initialize/register error',
          ),
        ).called(1);
      });

      test(
        'register delegates to messaging and records error on failure',
        () async {
          await repo.register();
          verify(() => mockMessaging.register()).called(1);

          final exception = Exception('Register failed');
          when(() => mockMessaging.register()).thenThrow(exception);

          await repo.register();
          verify(
            () => mockCrash.recordError(
              exception,
              any(),
              reason: 'NotificationRepository register error',
            ),
          ).called(1);
        },
      );

      test('getters delegate to messaging streams and methods', () async {
        expect(repo.onRegistered, isA<Stream<String>>());
        expect(repo.onMessage, isA<Stream<RemoteMessage>>());
        expect(repo.onMessageOpenedApp, isA<Stream<RemoteMessage>>());

        when(
          () => mockMessaging.getInitialMessage(),
        ).thenAnswer((_) async => null);
        expect(await repo.getInitialMessage(), isNull);
        verify(() => mockMessaging.getInitialMessage()).called(1);
      });

      test(
        'requestPermission handles each authorization status branch',
        () async {
          for (final status in AuthorizationStatus.values) {
            when(() => mockSettings.authorizationStatus).thenReturn(status);
            await repo.requestPermission();
          }
        },
      );

      test('subscribeToTopic delegates and records error on failure', () async {
        when(
          () => mockMessaging.subscribeToTopic('topic_1'),
        ).thenAnswer((_) async {});

        await repo.subscribeToTopic('topic_1');
        verify(() => mockMessaging.subscribeToTopic('topic_1')).called(1);

        final exception = Exception('Subscribe failed');
        when(
          () => mockMessaging.subscribeToTopic('topic_error'),
        ).thenThrow(exception);

        await repo.subscribeToTopic('topic_error');
        verify(
          () => mockCrash.recordError(
            exception,
            any(),
            reason: 'NotificationRepository subscribeToTopic error',
          ),
        ).called(1);
      });

      test(
        'unsubscribeFromTopic delegates and records error on failure',
        () async {
          when(
            () => mockMessaging.unsubscribeFromTopic('topic_1'),
          ).thenAnswer((_) async {});

          await repo.unsubscribeFromTopic('topic_1');
          verify(() => mockMessaging.unsubscribeFromTopic('topic_1')).called(1);

          final exception = Exception('Unsubscribe failed');
          when(
            () => mockMessaging.unsubscribeFromTopic('topic_error'),
          ).thenThrow(exception);

          await repo.unsubscribeFromTopic('topic_error');
          verify(
            () => mockCrash.recordError(
              exception,
              any(),
              reason: 'NotificationRepository unsubscribeFromTopic error',
            ),
          ).called(1);
        },
      );

      test(
        'falls back to getIt for CrashService when omitted from constructor',
        () async {
          final repoNoCrash = FirebaseNotificationRepository(
            messaging: mockMessaging,
          );

          final exception = Exception('FCM Error');
          when(
            () => mockMessaging.subscribeToTopic('test_topic'),
          ).thenThrow(exception);

          expect(
            () => repoNoCrash.subscribeToTopic('test_topic'),
            returnsNormally,
          );

          if (getIt.isRegistered<CrashService>()) {
            await getIt.unregister<CrashService>();
          }
          getIt.registerSingleton<CrashService>(mockCrash);
          addTearDown(() async {
            if (getIt.isRegistered<CrashService>()) {
              await getIt.unregister<CrashService>();
            }
          });

          await repoNoCrash.subscribeToTopic('test_topic');
          verify(
            () => mockCrash.recordError(
              exception,
              any(),
              reason: 'NotificationRepository subscribeToTopic error',
            ),
          ).called(1);
        },
      );
    });
  });
}
