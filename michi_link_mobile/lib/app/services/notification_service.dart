// Service constructor retains public parameter names for dependency injection.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

class NotificationService {
  NotificationService({
    required NotificationRepository notificationRepository,
    DatabaseService? databaseService,
    DeviceInfoService? deviceInfoService,
    LocalStorageService? localStorageService,
    PerformanceService? performanceService,
    CrashService? crashService,
    AnalyticsService? analyticsService,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _notificationRepository = notificationRepository,
       _databaseService = databaseService,
       _deviceInfoService = deviceInfoService,
       _localStorageService = localStorageService,
       _performanceService = performanceService,
       _crashService = crashService,
       _analyticsService = analyticsService,
       _localNotifications =
           localNotifications ??
           (getIt.isRegistered<FlutterLocalNotificationsPlugin>()
               ? getIt<FlutterLocalNotificationsPlugin>()
               : FlutterLocalNotificationsPlugin());

  final NotificationRepository _notificationRepository;
  final DatabaseService? _databaseService;
  final DeviceInfoService? _deviceInfoService;
  final LocalStorageService? _localStorageService;
  final PerformanceService? _performanceService;
  final CrashService? _crashService;
  final AnalyticsService? _analyticsService;
  final FlutterLocalNotificationsPlugin _localNotifications;

  Future<void>? _initializeFuture;
  StreamSubscription<String>? _registeredSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;

  DatabaseService get _db =>
      _databaseService ??
      (getIt.isRegistered<DatabaseService>()
          ? getIt<DatabaseService>()
          : null)!;

  DeviceInfoService get _deviceInfo =>
      _deviceInfoService ??
      (getIt.isRegistered<DeviceInfoService>()
          ? getIt<DeviceInfoService>()
          : null)!;

  LocalStorageService? get _localStorage =>
      _localStorageService ??
      (getIt.isRegistered<LocalStorageService>()
          ? getIt<LocalStorageService>()
          : null);

  PerformanceService? get _perf =>
      _performanceService ??
      (getIt.isRegistered<PerformanceService>()
          ? getIt<PerformanceService>()
          : null);

  CrashService? get _crash =>
      _crashService ??
      (getIt.isRegistered<CrashService>() ? getIt<CrashService>() : null);

  AnalyticsService? get _analytics =>
      _analyticsService ??
      (getIt.isRegistered<AnalyticsService>()
          ? getIt<AnalyticsService>()
          : null);

  Future<void> initialize({
    void Function(String deviceId)? onNotificationOpened,
  }) {
    return _initializeFuture ??= _initialize(
      onNotificationOpened: onNotificationOpened,
    );
  }

  Future<void> _initialize({
    void Function(String deviceId)? onNotificationOpened,
  }) async {
    final trace = _perf?.startTrace('notification_service_initialization');

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _analytics?.logEvent(
              name: 'notification_opened',
              parameters: {'device_id': payload, 'source': 'local_foreground'},
            );
            if (onNotificationOpened != null) {
              onNotificationOpened(payload);
            } else {
              _navigateToNotifications(payload);
            }
          }
        },
      );

      final launchDetails = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        final payload = launchDetails.notificationResponse!.payload!;
        if (payload.isNotEmpty) {
          _analytics?.logEvent(
            name: 'notification_opened',
            parameters: {'device_id': payload, 'source': 'local_launch'},
          );
          if (onNotificationOpened != null) {
            onNotificationOpened(payload);
          } else {
            _navigateToNotifications(payload);
          }
        }
      }

      await _notificationRepository.initialize();

      _messageSubscription = _notificationRepository.onMessage.listen((
        message,
      ) {
        if (kDebugMode) {
          debugPrint('Foreground FCM message: ${message.data}');
        }
        unawaited(_showForegroundNotification(message));
      });

      _messageOpenedAppSubscription = _notificationRepository.onMessageOpenedApp
          .listen((message) {
            _handleMessage(message, onNotificationOpened);
          });

      final initialMessage = await _notificationRepository.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage, onNotificationOpened);
      }

      final currentToken = _notificationRepository.token;
      if (currentToken.isNotEmpty) {
        await syncDeviceAndTopics(currentToken);
      }

      _registeredSubscription = _notificationRepository.onRegistered.listen((
        newToken,
      ) {
        if (newToken.isNotEmpty) {
          unawaited(syncDeviceAndTopics(newToken));
        }
      });
    } on Exception catch (e, stackTrace) {
      _crash?.recordError(
        e,
        stackTrace,
        reason: 'NotificationService initialization error',
      );
    } finally {
      if (trace != null) {
        _perf?.stopTrace(trace);
      }
    }
  }

  Future<void> syncDeviceAndTopics(String token) async {
    if (token.isEmpty) return;
    final trace = _perf?.startTrace('device_sync_duration');

    try {
      final isDbAvailable =
          _databaseService != null || getIt.isRegistered<DatabaseService>();
      final isDeviceAvailable =
          _deviceInfoService != null || getIt.isRegistered<DeviceInfoService>();
      final isStorageAvailable =
          _localStorageService != null ||
          getIt.isRegistered<LocalStorageService>();

      if (isDbAvailable && isDeviceAvailable && isStorageAvailable) {
        final savedCollars = _localStorage?.getCollars() ?? [];

        _db.updateDeviceSettings(
          token: token,
          deviceInfo: _deviceInfo.deviceInfo,
          enabledCollars: savedCollars.isNotEmpty ? savedCollars : null,
        );

        final topicSubscriptions = <Future<void>>[
          subscribeToTopic(AppVariables.allDevicesTopic),
        ];

        if (_deviceInfo.deviceInfo.isPhysicalDevice ?? false) {
          topicSubscriptions.add(subscribeToTopic(AppVariables.androidTopic));
        } else {
          debugPrint('Running on emulator, not subscribing to platform topic');
        }

        if (savedCollars.isNotEmpty) {
          topicSubscriptions.add(syncCollarsTopics(savedCollars));
        }

        await Future.wait(topicSubscriptions);
      }
    } on Exception catch (e, stackTrace) {
      _crash?.recordError(
        e,
        stackTrace,
        reason: 'NotificationService syncDeviceAndTopics error',
      );
    } finally {
      if (trace != null) {
        _perf?.stopTrace(trace);
      }
    }
  }

  static String collarTopic(String deviceId) => deviceId;

  Future<void> syncCollarsTopics(List<String> enabledCollars) async {
    if (enabledCollars.isEmpty) return;
    final trace = _perf?.startTrace('fcm_topics_sync_duration');
    try {
      await Future.wait(
        enabledCollars.map((id) => subscribeToTopic(collarTopic(id))),
      );
    } on Exception catch (e, stackTrace) {
      _crash?.recordError(
        e,
        stackTrace,
        reason: 'NotificationService syncCollarsTopics error',
      );
    } finally {
      if (trace != null) {
        _perf?.stopTrace(trace);
      }
    }
  }

  Future<void> toggleCollarTopic({
    required String deviceId,
    required bool enabled,
  }) async {
    final topic = collarTopic(deviceId);
    if (enabled) {
      await subscribeToTopic(topic);
    } else {
      await unsubscribeFromTopic(topic);
    }
  }

  void _handleMessage(
    RemoteMessage message,
    void Function(String deviceId)? callback,
  ) {
    if (kDebugMode) {
      debugPrint('FCM message opened: ${message.data}');
    }

    final deviceId = message.data['device_id']?.toString();
    if (deviceId == null || deviceId.isEmpty) return;

    _analytics?.logEvent(
      name: 'notification_opened',
      parameters: {'device_id': deviceId, 'source': 'fcm'},
    );
    if (callback != null) {
      callback(deviceId);
    } else {
      _navigateToNotifications(deviceId);
    }
  }

  void _navigateToNotifications(String deviceId) {
    if (deviceId.isEmpty) return;

    void navigate() {
      try {
        if (kDebugMode) {
          debugPrint('Navigating to notifications for device: $deviceId');
        }
        unawaited(
          AppRoutes.router.pushNamed(
            AppRoute.notifications.name,
            pathParameters: {'deviceId': deviceId},
          ),
        );
      } on Exception catch (e, stackTrace) {
        _crash?.recordError(
          e,
          stackTrace,
          reason: 'NotificationService _navigateToNotifications error',
        );
      }
    }

    if (AppRoutes.rootNavigatorKey.currentState != null) {
      navigate();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
    }
  }

  void handleBackgroundMessage(String message) {
    if (kDebugMode) {
      debugPrint('Handling a background message: $message');
    }

    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        final deviceId = decoded['device_id']?.toString();
        if (deviceId != null && deviceId.isNotEmpty) {
          _analytics?.logEvent(
            name: 'notification_opened',
            parameters: {'device_id': deviceId, 'source': 'fcm_background'},
          );
          _navigateToNotifications(deviceId);
        }
      }
    } on Exception catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error parsing background message JSON: $e');
      }
      _crash?.recordError(
        e,
        stackTrace,
        reason: 'handleBackgroundMessage jsonDecode error',
      );
    }
  }

  String get token => _notificationRepository.token;

  Stream<String> get onRegistered => _notificationRepository.onRegistered;

  Future<void> subscribeToTopic(String topic) async {
    await _notificationRepository.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _notificationRepository.unsubscribeFromTopic(topic);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? 'Michi Link';
      final body = message.notification?.body ?? '';
      final deviceId = message.data['device_id']?.toString() ?? '';

      if (title.isEmpty && body.isEmpty) return;

      final incomingChannel = message.notification?.android?.channelId;

      String channelId;
      String channelName;
      String channelDescription;
      Importance importance;
      Priority priority;

      if (incomingChannel == 'michi_critical_channel') {
        channelId = 'michi_critical_channel';
        channelName = 'Alertas Críticas de Collares';
        channelDescription = 'Notificaciones de geocerca y batería crítica';
        importance = Importance.max;
        priority = Priority.high;
      } else if (incomingChannel == 'michi_warning_channel') {
        channelId = 'michi_warning_channel';
        channelName = 'Advertencias de Collares';
        channelDescription =
            'Advertencias de batería baja, señal débil y pérdida de GPS';
        importance = Importance.high;
        priority = Priority.high;
      } else {
        channelId = 'michi_info_channel';
        channelName = 'Información de Collares';
        channelDescription =
            'Notificaciones informativas de estado y reconexión';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: priority,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: deviceId,
      );
    } on Exception catch (e, stackTrace) {
      _crash?.recordError(
        e,
        stackTrace,
        reason: 'NotificationService _showForegroundNotification error',
      );
    }
  }

  Future<void> dispose() async {
    await _registeredSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _messageOpenedAppSubscription?.cancel();
  }
}
