import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/app/Notifications_Model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';

// 🔧 알림 상수 (경량화)
class NotificationConstants {
  static const String channelId = 'epin.nadal.chat.channel';
  static const String channelName = 'Nadal_Chat_ver1.0.0';
  static const String channelDesc = '나스달 알림';
  static const String androidIcon = '@drawable/android_noti_icon';
  static const Color notificationColor = Color(0xFF00C4B4);
}

// 🔧 글로벌 인스턴스 (메모리 효율성)
final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

// 🔧 백그라운드 메시지 핸들러 (안전성 강화)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('🔔 백그라운드 메시지: ${message.messageId}');

    final data = message.data;
    if (data.isEmpty) return;

    await Future.wait([
      _updateBadgeSafely(data),
      _showBackgroundNotificationSafely(data),
    ]);
  } catch (e) {
    debugPrint('❌ 백그라운드 핸들러 오류: $e');
  }
}

// 🔧 안전한 배지 업데이트
Future<void> _updateBadgeSafely(Map<String, dynamic> data) async {
  try {
    final badgeStr = data['badge'] as String?;
    if (badgeStr?.isNotEmpty == true) {
      final count = int.tryParse(badgeStr!) ?? 0;
      if (count >= 0) {
        await AppBadgePlus.updateBadge(count);
      }
    }
  } catch (e) {
    debugPrint('❌ 배지 업데이트 오류: $e');
  }
}

// 🔧 안전한 백그라운드 알림 표시
Future<void> _showBackgroundNotificationSafely(Map<String, dynamic> data) async {
  try {
    const androidDetails = AndroidNotificationDetails(
      NotificationConstants.channelId,
      NotificationConstants.channelName,
      channelDescription: NotificationConstants.channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: NotificationConstants.androidIcon,
      color: NotificationConstants.notificationColor,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
      categoryIdentifier: 'nadal_notification',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(
      id,
      data['title'] ?? '새로운 알림',
      data['body'] ?? '확인해보세요',
      details,
      payload: jsonEncode(data),
    );
  } catch (e) {
    debugPrint('❌ 백그라운드 알림 오류: $e');
  }
}

// 🔧 백그라운드 알림 터치 핸들러 (경량화)
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  try {
    if (response.payload?.isNotEmpty == true) {
      final data = jsonDecode(response.payload!);
      _handleNotificationTapSafely(data);
    }
  } catch (e) {
    debugPrint('❌ 백그라운드 터치 오류: $e');
  }
}

// 🔧 안전한 알림 터치 처리
void _handleNotificationTapSafely(Map<String, dynamic> data) {
  final context = AppRoute.context;
  if (context?.mounted != true) return;

  try {
    // 알림 읽음 처리
    final notificationId = _parseNotificationId(data['notificationId']);
    if (notificationId != null && context!.mounted) {
      final provider = context.read<NotificationProvider>();
      provider.markNotificationAsReadFromPush(notificationId);
    }

    // 라우팅 처리
    final routing = data['routing'] as String?;
    if (routing?.isNotEmpty == true && context!.mounted) {
      _navigateToRouteSafely(context, routing!);
    }
  } catch (e) {
    debugPrint('❌ 알림 터치 처리 오류: $e');
  }
}

// 🔧 안전한 라우팅 처리
Future<void> _navigateToRouteSafely(BuildContext context, String routing) async {
  try {
    if (!context.mounted) return;

    final router = GoRouter.of(context);
    final current = router.state.uri.toString();

    if (current == routing) return;

    // 안전한 라우팅
    if (context.mounted) {
      router.go('/my');
      await Future.delayed(const Duration(milliseconds: 200));

      if (context.mounted) {
        router.push(routing);
      }
    }
  } catch (e) {
    debugPrint('❌ 라우팅 오류: $e');
  }
}

// 🔧 안전한 ID 파싱
int? _parseNotificationId(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

// 🔧 메인 알림 프로바이더 (경량화 및 안전성 강화)
class NotificationProvider extends ChangeNotifier {
  // 🔧 상태 변수 (최소화)
  List<NotificationModel>? _notifications;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _fcmToken;

  // 🔧 대기열 (메모리 효율적)
  final Set<int> _pendingReadIds = <int>{};

  // 🔧 Firebase 인스턴스 (지연 초기화)
  FirebaseMessaging? _messaging;

  // Getters
  List<NotificationModel>? get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // 🔧 안전한 초기화 (순차 처리)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 알림 시스템 초기화 시작');

      // 순차 초기화 (안전성 향상)
      await _initializeLocalNotifications();
      await _initializeFCM();
      await _loadNotificationsData();

      _isInitialized = true;
      debugPrint('✅ 알림 시스템 초기화 완료');
    } catch (e) {
      debugPrint('❌ 알림 초기화 오류: $e');
      _isInitialized = true; // 앱 진행을 위해 초기화 완료로 처리
    }
  }

  // 🔧 로컬 알림 초기화 (경량화)
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
          NotificationConstants.androidIcon
      );

      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: true,
        requestBadgePermission: true,
        notificationCategories: [
          DarwinNotificationCategory(
            'nadal_notification',
            actions: [
              DarwinNotificationAction.plain(
                'open',
                '열기',
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
        ],
      );

      final settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler,
      );

      // 플랫폼별 설정
      await Future.wait([
        if (Platform.isAndroid) _createAndroidNotificationChannel(),
        if (Platform.isIOS) _requestIOSPermissions(),
      ]);

      debugPrint('✅ 로컬 알림 초기화 완료');
    } catch (e) {
      debugPrint('❌ 로컬 알림 초기화 오류: $e');
    }
  }

  // 🔧 Android 채널 생성 (간소화)
  Future<void> _createAndroidNotificationChannel() async {
    try {
      const channel = AndroidNotificationChannel(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        description: NotificationConstants.channelDesc,
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('❌ Android 채널 생성 오류: $e');
    }
  }

  // 🔧 iOS 권한 요청 (간소화)
  Future<void> _requestIOSPermissions() async {
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('❌ iOS 권한 요청 오류: $e');
    }
  }

  // 🔧 FCM 초기화 (iOS 포그라운드 알림 수정)
  Future<void> _initializeFCM() async {
    try {
      _messaging = FirebaseMessaging.instance;

      // 권한 요청
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('FCM 권한 거부됨');
        return;
      }

      // 🔥 iOS 포그라운드 알림 활성화 (핵심 수정사항)
      if (Platform.isIOS) {
        await _messaging!.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('✅ iOS 포그라운드 알림 옵션 설정 완료');
      }

      // 토큰 및 리스너 설정
      await Future.wait([
        _setupFCMToken(),
        _setupMessageListeners(),
      ]);

      // 백그라운드 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      debugPrint('✅ FCM 초기화 완료');
    } catch (e) {
      debugPrint('❌ FCM 초기화 오류: $e');
    }
  }

  // 🔧 FCM 토큰 설정 (안전성 강화)
  Future<void> _setupFCMToken() async {
    try {
      final token = await _messaging?.getToken();
      if (token?.isNotEmpty == true && token != _fcmToken) {
        _fcmToken = token;
        await _saveTokenToServerSafely(token!);
      }

      // 토큰 갱신 리스너 (메모리 누수 방지)
      _messaging?.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty && newToken != _fcmToken) {
          _fcmToken = newToken;
          await _saveTokenToServerSafely(newToken);
        }
      }).onError((error) {
        debugPrint('❌ 토큰 갱신 오류: $error');
      });
    } catch (e) {
      debugPrint('❌ FCM 토큰 설정 오류: $e');
    }
  }

  // 🔧 메시지 리스너 설정 (경량화)
  Future<void> _setupMessageListeners() async {
    try {
      // 포그라운드 메시지 처리
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('📱 포그라운드 메시지: ${message.messageId}');
        _handleForegroundMessage(message);
      }).onError((error) {
        debugPrint('❌ 포그라운드 메시지 오류: $error');
      });

      // 앱 실행 중 알림 탭 처리
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('📱 앱 실행 중 알림 탭: ${message.messageId}');
        _handleNotificationTapSafely(message.data);
      }).onError((error) {
        debugPrint('❌ 알림 탭 처리 오류: $error');
      });

      // 앱 종료 상태에서 알림 탭으로 실행
      final initialMessage = await _messaging?.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📱 초기 메시지: ${initialMessage.messageId}');
        Future.microtask(() => _handleNotificationTapSafely(initialMessage.data));
      }
    } catch (e) {
      debugPrint('❌ 메시지 리스너 설정 오류: $e');
    }
  }

  // 🔧 포그라운드 메시지 처리 (간소화)
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.isEmpty) return;

      _updateBadgeSafely(data);

      // 현재 화면 확인 후 알림 표시 여부 결정
      if (_shouldShowForegroundNotification(data)) {
        _showLocalNotificationSafely(data);
      }
    } catch (e) {
      debugPrint('❌ 포그라운드 메시지 처리 오류: $e');
    }
  }

  // 🔧 포그라운드 알림 표시 여부 판단 (최적화)
  bool _shouldShowForegroundNotification(Map<String, dynamic> data) {
    try {
      final context = AppRoute.context;
      if (context == null) return true;

      final router = GoRouter.of(context);
      final currentUri = router.state.uri.toString();
      final routing = data['routing'] as String?;

      if (routing?.isEmpty != false) return true;

      // 채팅방 체크 (간소화)
      if (routing!.contains('/room/') && currentUri.contains('/room/')) {
        final routingRoomId = _extractIdSafely(routing, r'/room/(\d+)');
        final currentRoomId = _extractIdSafely(currentUri, r'/room/(\d+)');
        return routingRoomId != currentRoomId;
      }

      // 스케줄 체크 (간소화)
      if (routing.contains('/schedule/') && currentUri.contains('/schedule/')) {
        final routingScheduleId = _extractIdSafely(routing, r'/schedule/(\d+)');
        final currentScheduleId = _extractIdSafely(currentUri, r'/schedule/(\d+)');
        return routingScheduleId != currentScheduleId;
      }

      return true;
    } catch (e) {
      debugPrint('❌ 알림 표시 여부 판단 오류: $e');
      return true;
    }
  }

  // 🔧 안전한 ID 추출
  String? _extractIdSafely(String path, String pattern) {
    try {
      final match = RegExp(pattern).firstMatch(path);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  // 🔧 안전한 로컬 알림 표시
  Future<void> _showLocalNotificationSafely(Map<String, dynamic> data) async {
    try {
      final title = data['title'] as String? ?? '알림';
      final body = data['body'] as String? ?? '';
      final groupKey = data['roomId'] as String? ?? data['scheduleId'] as String? ?? 'default';
      final badge = int.tryParse(data['badge'] as String? ?? '0') ?? 0;
      final alarm = (data['alarm'] as String?) != '0';

      final androidDetails = AndroidNotificationDetails(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        channelDescription: NotificationConstants.channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        groupKey: groupKey,
        number: badge > 0 ? badge : null,
        playSound: alarm,
        enableVibration: alarm,
        icon: NotificationConstants.androidIcon,
        color: NotificationConstants.notificationColor,
        autoCancel: true,
      );

      final iosDetails = DarwinNotificationDetails(
        presentSound: alarm,
        presentAlert: true, // iOS에서 항상 alert 표시
        presentBadge: badge > 0,
        badgeNumber: badge > 0 ? badge : null,
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: 'nadal_notification',
        threadIdentifier: groupKey,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        groupKey.hashCode,
        title,
        body,
        details,
        payload: jsonEncode(data),
      );

      debugPrint('✅ 로컬 알림 표시: $title');
    } catch (e) {
      debugPrint('❌ 로컬 알림 표시 오류: $e');
    }
  }

  // 🔧 로컬 알림 터치 처리
  void _handleLocalNotificationTap(NotificationResponse response) {
    try {
      if (response.payload?.isNotEmpty == true) {
        final data = jsonDecode(response.payload!);
        _handleNotificationTapSafely(data);
      }
    } catch (e) {
      debugPrint('❌ 로컬 알림 터치 오류: $e');
    }
  }

  // 🔧 안전한 토큰 서버 저장
  Future<void> _saveTokenToServerSafely(String token) async {
    try {
      await serverManager.post('notification/fcmToken', data: {'fcmToken': token});
      debugPrint('✅ FCM 토큰 저장 완료');
    } catch (e) {
      debugPrint('❌ FCM 토큰 저장 오류: $e');
    }
  }

  // 🔧 알림 데이터 로드 (경량화)
  Future<void> _loadNotificationsData() async {
    if (_isLoading) return;

    try {
      _isLoading = true;

      final res = await serverManager.get('notification');
      if (res.statusCode == 200 && res.data != null) {
        final List<dynamic> data = List.from(res.data);
        _notifications = data
            .map((e) => NotificationModel.fromJson(json: e))
            .toList();

        await _processPendingReads();
      }
    } catch (e) {
      debugPrint('❌ 알림 데이터 로드 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔧 대기 중인 읽음 처리 (배치 처리)
  Future<void> _processPendingReads() async {
    if (_pendingReadIds.isEmpty) return;

    final pendingIds = List<int>.from(_pendingReadIds);
    _pendingReadIds.clear();

    for (final id in pendingIds) {
      await _markAsReadSafely(id);
    }
  }

  // 🔧 Push에서 읽음 처리 (Public API)
  Future<void> markNotificationAsReadFromPush(int notificationId) async {
    if (_notifications != null) {
      await _markAsReadSafely(notificationId);
      notifyListeners();
    } else {
      _pendingReadIds.add(notificationId);
    }
  }

  // 🔧 안전한 읽음 처리 (내부)
  Future<void> _markAsReadSafely(int notificationId) async {
    if (_notifications == null) return;

    try {
      final index = _notifications!.indexWhere((e) => e.notificationId == notificationId);
      if (index != -1 && !_notifications![index].isRead) {
        _notifications![index].isRead = true;
        _sendReadToServerSafely(notificationId);
      }
    } catch (e) {
      debugPrint('❌ 읽음 처리 오류: $e');
    }
  }

  // 🔧 안전한 서버 읽음 전송
  Future<void> _sendReadToServerSafely(int notificationId) async {
    try {
      await serverManager.put('notification/read', data: {'notificationId': notificationId});
    } catch (e) {
      debugPrint('❌ 서버 읽음 전송 오류: $e');
    }
  }

  // 🔧 UI에서 읽음 처리 (Public API)
  Future<bool> readNotification(int notificationId) async {
    final index = _notifications?.indexWhere((e) => e.notificationId == notificationId);
    if (index == null || index == -1) return false;
    if (_notifications![index].isRead) return true;

    // 낙관적 업데이트
    _notifications![index].isRead = true;
    notifyListeners();

    try {
      final res = await serverManager.put('notification/read', data: {'notificationId': notificationId});
      return res.statusCode == 204;
    } catch (e) {
      debugPrint('❌ 읽음 처리 오류: $e');
      // 실패 시 롤백
      _notifications![index].isRead = false;
      notifyListeners();
      return false;
    }
  }

  // 🔧 알림 삭제 (Public API)
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final res = await serverManager.delete('notification/remove/$notificationId');

      if (res.statusCode == 200) {
        _notifications?.removeWhere((e) => e.notificationId == notificationId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ 알림 삭제 오류: $e');
      return false;
    }
  }

  // 🔧 알림 전송 (Public API, 최적화)
  Future<List<String>> sendNotification({
    required List<String> receivers,
    required String title,
    required String subTitle,
    required String routing,
  }) async {
    if (receivers.length > 10) {
      DialogManager.warningHandler('메시지를 보낼 인원은 최대 10명까지 가능해요');
      return [];
    }

    final List<String> failed = [];

    try {
      // 병렬 처리로 성능 향상
      final results = await Future.wait(
        receivers.map((receiver) => _sendSingleNotification(
          receiver,
          title,
          subTitle,
          routing,
        )),
        eagerError: false,
      );

      // 실패한 수신자 수집
      for (int i = 0; i < results.length; i++) {
        if (!results[i]) {
          failed.add(receivers[i]);
        }
      }
    } catch (e) {
      debugPrint('❌ 알림 전송 중 오류: $e');
      return receivers; // 모든 수신자를 실패로 처리
    }

    return failed;
  }

  // 🔧 단일 알림 전송 (내부)
  Future<bool> _sendSingleNotification(
      String receiver,
      String title,
      String subTitle,
      String routing,
      ) async {
    try {
      final model = {
        'uid': receiver,
        'title': title,
        'subTitle': subTitle,
        'routing': routing,
      };

      final res = await serverManager.post('notification/create', data: model);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('❌ 단일 알림 전송 오류 (수신자: $receiver): $e');
      return false;
    }
  }

  // 🔧 알림 새로고침 (Public API)
  Future<void> refreshNotifications() async {
    await _loadNotificationsData();
  }

  // 🔧 안전한 정리
  @override
  void dispose() {
    _pendingReadIds.clear();
    super.dispose();
  }
}