import 'dart:async';

import 'package:expressive_kit/expressive_kit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michi_link_mobile/app/app.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

class MockCrashService extends Mock implements CrashService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockPerformanceService extends Mock implements PerformanceService {}

class MockTrace extends Mock implements Trace {}

class FakeTrace extends Fake implements Trace {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeTrace());
  });

  group('NotificationService', () {
    late MockNotificationRepository mockRepo;
    late MockDatabaseService mockDb;
    late MockDeviceInfoService mockDeviceInfo;
    late MockLocalStorageService mockStorage;
    late MockCrashService mockCrash;
    late MockAnalyticsService mockAnalytics;
    late MockPerformanceService mockPerf;
    late MockTrace mockTrace;
    late NotificationService service;

    late StreamController<String> registeredController;
    late StreamController<RemoteMessage> messageController;
    late StreamController<RemoteMessage> messageOpenedAppController;

    setUp(() {
      mockRepo = MockNotificationRepository();
      mockDb = MockDatabaseService();
      mockDeviceInfo = MockDeviceInfoService();
      mockStorage = MockLocalStorageService();
      mockCrash = MockCrashService();
      mockAnalytics = MockAnalyticsService();
      mockPerf = MockPerformanceService();
      mockTrace = MockTrace();

      registeredController = StreamController<String>.broadcast();
      messageController = StreamController<RemoteMessage>.broadcast();
      messageOpenedAppController = StreamController<RemoteMessage>.broadcast();

      when(() => mockRepo.initialize()).thenAnswer((_) async {});
      when(() => mockRepo.token).thenReturn('token-123');
      when(
        () => mockRepo.onRegistered,
      ).thenAnswer((_) => registeredController.stream);
      when(
        () => mockRepo.onMessage,
      ).thenAnswer((_) => messageController.stream);
      when(
        () => mockRepo.onMessageOpenedApp,
      ).thenAnswer((_) => messageOpenedAppController.stream);
      when(() => mockRepo.getInitialMessage()).thenAnswer((_) async => null);
      when(() => mockRepo.subscribeToTopic(any())).thenAnswer((_) async {});
      when(() => mockRepo.unsubscribeFromTopic(any())).thenAnswer((_) async {});

      when(
        () => mockDeviceInfo.deviceInfo,
      ).thenReturn(const AppDeviceInfo(id: 'mock-id', isPhysicalDevice: true));
      when(() => mockStorage.getCollars()).thenReturn([]);
      when(
        () => mockDb.updateDeviceSettings(
          token: any(named: 'token'),
          deviceInfo: any(named: 'deviceInfo'),
        ),
      ).thenReturn(null);

      when(
        () => mockCrash.recordError(
          any<dynamic>(),
          any<StackTrace?>(),
          reason: any<dynamic>(named: 'reason'),
        ),
      ).thenReturn(null);

      when(
        () => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      when(() => mockPerf.startTrace(any())).thenReturn(mockTrace);
      when(() => mockPerf.stopTrace(any())).thenReturn(null);

      service = NotificationService(
        notificationRepository: mockRepo,
        databaseService: mockDb,
        deviceInfoService: mockDeviceInfo,
        localStorageService: mockStorage,
        performanceService: mockPerf,
        crashService: mockCrash,
        analyticsService: mockAnalytics,
      );
    });

    tearDown(() async {
      await service.dispose();
      await registeredController.close();
      await messageController.close();
      await messageOpenedAppController.close();
    });

    test('initializes and subscribes to default topics', () async {
      await service.initialize();

      verify(() => mockRepo.initialize()).called(1);
      verify(
        () => mockRepo.subscribeToTopic(AppVariables.allDevicesTopic),
      ).called(1);
      verify(
        () => mockRepo.subscribeToTopic(AppVariables.androidTopic),
      ).called(1);
      verify(
        () => mockDb.updateDeviceSettings(
          token: 'token-123',
          deviceInfo: any(named: 'deviceInfo'),
        ),
      ).called(1);
      verify(
        () => mockPerf.startTrace('notification_service_initialization'),
      ).called(1);
      verify(
        () => mockPerf.stopTrace(mockTrace),
      ).called(greaterThanOrEqualTo(1));
    });

    test('calling initialize multiple times returns the same future', () async {
      final f1 = service.initialize();
      final f2 = service.initialize();

      expect(identical(f1, f2), isTrue);
      await f1;
    });

    test('listens to foreground messages', () async {
      await service.initialize();

      messageController.add(const RemoteMessage(data: {'sample': 'data'}));
      await pumpEventQueue();
    });

    test('syncs device when token is refreshed onRegistered', () async {
      await service.initialize();

      registeredController.add('new-token-456');
      await pumpEventQueue();

      verify(
        () => mockDb.updateDeviceSettings(
          token: 'new-token-456',
          deviceInfo: any(named: 'deviceInfo'),
        ),
      ).called(1);

      // Empty new token should not trigger sync
      registeredController.add('');
      await pumpEventQueue();
    });

    test(
      'initialize records error to crash service when repository fails',
      () async {
        final exception = Exception('Init crash');
        when(() => mockRepo.initialize()).thenThrow(exception);

        await service.initialize();

        verify(
          () => mockCrash.recordError(
            exception,
            any<StackTrace?>(),
            reason: 'NotificationService initialization error',
          ),
        ).called(1);
      },
    );

    test(
      'initialize skips syncDeviceAndTopics when currentToken is empty',
      () async {
        when(() => mockRepo.token).thenReturn('');

        await service.initialize();

        verifyNever(
          () => mockDb.updateDeviceSettings(
            token: any(named: 'token'),
            deviceInfo: any(named: 'deviceInfo'),
          ),
        );
      },
    );

    test('syncDeviceAndTopics returns early when token is empty', () async {
      await service.syncDeviceAndTopics('');

      verifyNever(
        () => mockDb.updateDeviceSettings(
          token: any(named: 'token'),
          deviceInfo: any(named: 'deviceInfo'),
        ),
      );
    });

    test('syncDeviceAndTopics on emulator skips androidTopic', () async {
      when(() => mockDeviceInfo.deviceInfo).thenReturn(
        const AppDeviceInfo(id: 'mock-emu', isPhysicalDevice: false),
      );

      await service.syncDeviceAndTopics('token-emu');

      verify(
        () => mockRepo.subscribeToTopic(AppVariables.allDevicesTopic),
      ).called(1);
      verifyNever(() => mockRepo.subscribeToTopic(AppVariables.androidTopic));
    });

    test(
      'syncDeviceAndTopics skips update when services are unavailable',
      () async {
        final standalone = NotificationService(
          notificationRepository: mockRepo,
        );

        await standalone.syncDeviceAndTopics('token-standalone');

        verifyNever(
          () => mockDb.updateDeviceSettings(
            token: any(named: 'token'),
            deviceInfo: any(named: 'deviceInfo'),
          ),
        );
      },
    );

    test('syncDeviceAndTopics records error on failure', () async {
      final exception = Exception('Sync error');
      when(
        () => mockDb.updateDeviceSettings(
          token: any(named: 'token'),
          deviceInfo: any(named: 'deviceInfo'),
        ),
      ).thenThrow(exception);

      await service.syncDeviceAndTopics('token-err');

      verify(
        () => mockCrash.recordError(
          exception,
          any<StackTrace?>(),
          reason: 'NotificationService syncDeviceAndTopics error',
        ),
      ).called(1);
    });

    test('syncCollarsTopics returns early when list is empty', () async {
      await service.syncCollarsTopics([]);

      verifyNever(() => mockRepo.subscribeToTopic(any()));
    });

    test('syncCollarsTopics subscribes to collar topics', () async {
      await service.syncCollarsTopics(['collar_1', 'collar_2']);

      verify(() => mockRepo.subscribeToTopic('collar_1')).called(1);
      verify(() => mockRepo.subscribeToTopic('collar_2')).called(1);
    });

    test('syncCollarsTopics records error on failure', () async {
      final exception = Exception('Topics error');
      when(() => mockRepo.subscribeToTopic('fail_col')).thenThrow(exception);

      await service.syncCollarsTopics(['fail_col']);

      verify(
        () => mockCrash.recordError(
          exception,
          any<StackTrace?>(),
          reason: 'NotificationService syncCollarsTopics error',
        ),
      ).called(1);
    });

    test('toggleCollarTopic subscribes when enabled and unsubscribes '
        'when disabled', () async {
      await service.toggleCollarTopic(deviceId: 'col_1', enabled: true);
      verify(() => mockRepo.subscribeToTopic('col_1')).called(1);

      await service.toggleCollarTopic(deviceId: 'col_1', enabled: false);
      verify(() => mockRepo.unsubscribeFromTopic('col_1')).called(1);
    });

    test('handles message opened app with callback', () async {
      String? openedDeviceId;
      await service.initialize(
        onNotificationOpened: (deviceId) {
          openedDeviceId = deviceId;
        },
      );

      const message = RemoteMessage(data: {'device_id': 'col_test_123'});

      messageOpenedAppController.add(message);
      await pumpEventQueue();

      expect(openedDeviceId, equals('col_test_123'));
      verify(
        () => mockAnalytics.logEvent(
          name: 'notification_opened',
          parameters: {'device_id': 'col_test_123', 'source': 'fcm'},
        ),
      ).called(1);
    });

    test('handles initial message on cold start with device_id', () async {
      when(() => mockRepo.getInitialMessage()).thenAnswer(
        (_) async =>
            const RemoteMessage(data: {'device_id': 'col_cold_start_456'}),
      );

      String? openedDeviceId;
      await service.initialize(
        onNotificationOpened: (deviceId) {
          openedDeviceId = deviceId;
        },
      );

      expect(openedDeviceId, equals('col_cold_start_456'));
    });

    testWidgets(
      'handles message opened app without callback navigates via router',
      (tester) async {
        if (!getIt.isRegistered<AnalyticsService>()) {
          setupServiceLocator(Environment.mock);
        }
        await tester.pumpWidget(const AppPage());
        await tester.pump();

        await service.initialize();

        const message = RemoteMessage(data: {'device_id': 'COLLAR_1'});
        messageOpenedAppController.add(message);
        await tester.pumpAndSettle();

        verify(
          () => mockAnalytics.logEvent(
            name: 'notification_opened',
            parameters: {'device_id': 'COLLAR_1', 'source': 'fcm'},
          ),
        ).called(1);
      },
    );

    test('ignores message with no deviceId or empty deviceId', () async {
      String? openedDeviceId;
      await service.initialize(
        onNotificationOpened: (deviceId) {
          openedDeviceId = deviceId;
        },
      );

      messageOpenedAppController
        ..add(const RemoteMessage(data: {'other': 'value'}))
        ..add(const RemoteMessage(data: {'device_id': ''}));
      await pumpEventQueue();

      expect(openedDeviceId, isNull);
    });

    test('token and onRegistered delegate to repository', () {
      expect(service.token, equals('token-123'));
      expect(service.onRegistered, isA<Stream<String>>());
    });

    test(
      'subscribeToTopic and unsubscribeFromTopic delegate to repository',
      () async {
        await service.subscribeToTopic('my_topic');
        verify(() => mockRepo.subscribeToTopic('my_topic')).called(1);

        await service.unsubscribeFromTopic('my_topic');
        verify(() => mockRepo.unsubscribeFromTopic('my_topic')).called(1);
      },
    );

    test('falls back to getIt when optional services are omitted', () async {
      if (getIt.isRegistered<DatabaseService>()) {
        await getIt.unregister<DatabaseService>();
      }
      if (getIt.isRegistered<DeviceInfoService>()) {
        await getIt.unregister<DeviceInfoService>();
      }
      if (getIt.isRegistered<LocalStorageService>()) {
        await getIt.unregister<LocalStorageService>();
      }
      if (getIt.isRegistered<PerformanceService>()) {
        await getIt.unregister<PerformanceService>();
      }
      if (getIt.isRegistered<CrashService>()) {
        await getIt.unregister<CrashService>();
      }
      if (getIt.isRegistered<AnalyticsService>()) {
        await getIt.unregister<AnalyticsService>();
      }

      getIt
        ..registerSingleton<DatabaseService>(mockDb)
        ..registerSingleton<DeviceInfoService>(mockDeviceInfo)
        ..registerSingleton<LocalStorageService>(mockStorage)
        ..registerSingleton<PerformanceService>(mockPerf)
        ..registerSingleton<CrashService>(mockCrash)
        ..registerSingleton<AnalyticsService>(mockAnalytics);

      addTearDown(() async {
        if (getIt.isRegistered<DatabaseService>()) {
          await getIt.unregister<DatabaseService>();
        }
        if (getIt.isRegistered<DeviceInfoService>()) {
          await getIt.unregister<DeviceInfoService>();
        }
        if (getIt.isRegistered<LocalStorageService>()) {
          await getIt.unregister<LocalStorageService>();
        }
        if (getIt.isRegistered<PerformanceService>()) {
          await getIt.unregister<PerformanceService>();
        }
        if (getIt.isRegistered<CrashService>()) {
          await getIt.unregister<CrashService>();
        }
        if (getIt.isRegistered<AnalyticsService>()) {
          await getIt.unregister<AnalyticsService>();
        }
      });

      final getItService = NotificationService(
        notificationRepository: mockRepo,
      );

      await getItService.syncDeviceAndTopics('token-getit');

      verify(
        () => mockDb.updateDeviceSettings(
          token: 'token-getit',
          deviceInfo: any(named: 'deviceInfo'),
        ),
      ).called(1);
      verify(() => mockPerf.startTrace('device_sync_duration')).called(1);

      // Verify crash fallback using getIt
      final syncException = Exception('getIt sync crash');
      when(
        () => mockDb.updateDeviceSettings(
          token: any(named: 'token'),
          deviceInfo: any(named: 'deviceInfo'),
        ),
      ).thenThrow(syncException);

      await getItService.syncDeviceAndTopics('token-crash-getit');

      verify(
        () => mockCrash.recordError(
          syncException,
          any<StackTrace?>(),
          reason: 'NotificationService syncDeviceAndTopics error',
        ),
      ).called(1);

      // Verify analytics fallback using getIt
      await getItService.initialize();
      messageOpenedAppController.add(
        const RemoteMessage(data: {'device_id': 'col_getit_analytics'}),
      );
      await pumpEventQueue();

      verify(
        () => mockAnalytics.logEvent(
          name: 'notification_opened',
          parameters: {'device_id': 'col_getit_analytics', 'source': 'fcm'},
        ),
      ).called(1);
    });

    group('handleBackgroundMessage', () {
      test('processes valid device_id message and navigates', () {
        expect(
          () => service.handleBackgroundMessage(
            '{"device_id": "COLLAR_TEST_99"}',
          ),
          returnsNormally,
        );

        verify(
          () => mockAnalytics.logEvent(
            name: 'notification_opened',
            parameters: {
              'device_id': 'COLLAR_TEST_99',
              'source': 'fcm_background',
            },
          ),
        ).called(1);
      });

      test('ignores message when device_id is missing or empty', () {
        service
          ..handleBackgroundMessage('{"other": "val"}')
          ..handleBackgroundMessage('{"device_id": ""}')
          ..handleBackgroundMessage('"not-a-map"');

        verifyNever(
          () => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          ),
        );
      });

      test('records error when json is invalid', () {
        service.handleBackgroundMessage('invalid-json');

        verify(
          () => mockCrash.recordError(
            any<dynamic>(),
            any<StackTrace?>(),
            reason: 'handleBackgroundMessage jsonDecode error',
          ),
        ).called(1);
      });
    });

    test(
      'syncDeviceAndTopics subscribes to saved collars in storage',
      () async {
        when(() => mockStorage.getCollars()).thenReturn(['col_1', 'col_2']);

        await service.syncDeviceAndTopics('token-123');

        verify(() => mockRepo.subscribeToTopic('col_1')).called(1);
        verify(() => mockRepo.subscribeToTopic('col_2')).called(1);
      },
    );
  });
}
