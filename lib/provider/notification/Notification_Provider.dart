import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';

// 🔧 기존 import 구조 유지
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/app/Notifications_Model.dart';

// 🔧 알림 상수 (기존 구조 유지)
class NotificationConstants {
  static const String channelId = 'epin.nadal.chat.channel';
  static const String channelName = 'Nadal_Chat_ver1.0.0';
  static const String channelDesc = '나스달 알림';
  static const String androidIcon = '@drawable/android_noti_icon';
  static const Color notificationColor = Color(0xFF00C4B4);
}

// 🔧 일관된 알림 그룹 관리 클래스 (서버와 동일)
class NotificationGroupManager {
  static Map<String, String> getGroupInfo(String? type, Map<String, dynamic> data) {
    switch (type) {
      case 'chat':
        final roomId = data['roomId'] ?? '';
        return {
          'tag': 'nadal_room_$roomId',
          'groupKey': 'nadal_chat_group',
          'collapseKey': 'nadal_room_$roomId',
          'threadId': 'nadal_room_$roomId', // iOS용
        };
      case 'schedule':
        final scheduleId = data['scheduleId'] ?? '';
        return {
          'tag': 'nadal_schedule_$scheduleId',
          'groupKey': 'nadal_schedule_group',
          'collapseKey': 'nadal_schedule_$scheduleId',
          'threadId': 'nadal_schedule_$scheduleId',
        };
      default:
        return {
          'tag': 'nadal_general',
          'groupKey': 'nadal_general_group',
          'collapseKey': 'nadal_general',
          'threadId': 'nadal_general',
        };
    }
  }

  static int generateNotificationId(Map<String, dynamic> data) {
    // 🔧 수정: 32비트 정수 범위 내로 제한 + 안전 처리
    if (data['notificationId'] != null) {
      final id = int.tryParse(data['notificationId'].toString());
      if (id != null && id <= 2147483647 && id >= -2147483648) {
        return id;
      }
    }
    if (data['chatId'] != null) {
      final id = int.tryParse(data['chatId'].toString());
      if (id != null && id <= 2147483647 && id >= -2147483648) {
        return id;
      }
    }

    // 🔧 채팅 알림의 경우 roomId와 타임스탬프 조합으로 고유 ID 생성
    if (data['type'] == 'chat' && data['roomId'] != null) {
      final roomId = int.tryParse(data['roomId'].toString()) ?? 0;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final combined = (roomId * 1000 + (timestamp % 1000)) % 2147483647;
      return combined.abs();
    }

    // 🔧 타임스탬프를 32비트 범위 내로 제한
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return (timestamp % 2147483647).abs();
  }
}

// 🔧 알림 추적 관리 클래스 (기존 구조 유지)
class NotificationTracker {
  static final Map<String, Set<int>> _groupNotifications = {};

  static void trackNotification(String groupTag, int notificationId) {
    _groupNotifications[groupTag] ??= <int>{};
    _groupNotifications[groupTag]!.add(notificationId);
    debugPrint('📊 알림 추적 추가: $groupTag -> $notificationId');
  }

  static Set<int> getGroupNotifications(String groupTag) {
    return _groupNotifications[groupTag] ?? <int>{};
  }

  static void clearGroup(String groupTag) {
    _groupNotifications.remove(groupTag);
    debugPrint('🗑️ 그룹 추적 정리: $groupTag');
  }

  static void clearAll() {
    _groupNotifications.clear();
    debugPrint('🗑️ 모든 알림 추적 데이터 정리');
  }
}

// 🔧 백그라운드 알림 터치 핸들러 (기존 구조 유지)
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

// 🔧 백그라운드 메시지 핸들러 (수정: 로컬 알림 생성 제거)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📳 백그라운드 FCM 수신: ${message.data}');

  try {
    if (message.data.isNotEmpty) {
      debugPrint('✅ 백그라운드 메시지 데이터 처리 완료');
      // 🔧 백그라운드에서는 FCM 자체 알림만 사용 (로컬 알림 생성 안함)
    }
  } catch (e) {
    debugPrint('❌ 백그라운드 메시지 처리 오류: $e');
  }
}

// 🔧 안전한 알림 터치 처리 (오류 무시 개선)
void _handleNotificationTapSafely(Map<String, dynamic> data) {
  final context = AppRoute.context;
  if (context?.mounted != true) return;

  try {
    final notificationId = NotificationGroupManager.generateNotificationId(data);

    // 🔧 알림 읽음 처리는 비동기로 실행하되 실패해도 라우팅 진행
    if (context!.mounted) {
      try {
        final provider = context.read<NotificationProvider>();
        // 🔧 await 제거하여 읽음 처리 실패해도 라우팅 계속 진행
        provider.markNotificationAsReadFromPush(notificationId).catchError((error) {
          debugPrint('⚠️ 알림 읽음 처리 실패하지만 라우팅 계속 진행: $error');
        });
      } catch (e) {
        debugPrint('⚠️ 알림 프로바이더 접근 실패 (무시): $e');
      }
    }

    final routing = data['routing'] as String?;
    if (routing?.isNotEmpty == true && context.mounted) {
      _navigateToRouteSafely(context, routing!);
    }
  } catch (e) {
    debugPrint('❌ 알림 터치 처리 오류: $e');
  }
}

// 🔧 안전한 라우팅 처리 (기존 함수명 유지)
Future<void> _navigateToRouteSafely(BuildContext context, String routing) async {
  try {
    final router = GoRouter.of(context);
    final current = router.state.uri.toString();

    if (current == routing) return;

    if (context.mounted) {
      router.go('/my');
      context.read<HomeProvider>().setMenu(0);
      router.push(routing);
    }
  } catch (e) {
    debugPrint('❌ 라우팅 오류: $e');
  }
}

// 🔧 메인 알림 프로바이더 (기존 구조 유지)
class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  List<NotificationModel>? _notifications;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _fcmToken;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  final Set<int> _pendingReadIds = <int>{};
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  FirebaseMessaging? _messaging;

  // Getters (기존 유지)
  List<NotificationModel>? get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  // 🔧 초기화 (기존 함수명 유지)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      WidgetsBinding.instance.addObserver(this);

      await Future.wait([
        _initializeLocalNotifications(),
        _initializeFCM(),
        _requestIOSPermissions(),
      ]);

      _isInitialized = true;
      debugPrint('✅ NotificationProvider 초기화 완료');
    } catch (e) {
      debugPrint('❌ NotificationProvider 초기화 오류: $e');
    }
  }

  @override
  void dispose() {
    _pendingReadIds.clear();
    NotificationTracker.clearAll();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🔧 로컬 알림 초기화 (기존 함수명 유지)
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidInitializationSettings = AndroidInitializationSettings(NotificationConstants.androidIcon);
      const iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler,
      );

      // 🔧 안드로이드 채널 생성 (기존 유지)
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
          const AndroidNotificationChannel(
            NotificationConstants.channelId,
            NotificationConstants.channelName,
            description: NotificationConstants.channelDesc,
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );
      }

      debugPrint('✅ 로컬 알림 초기화 완료');
    } catch (e) {
      debugPrint('❌ 로컬 알림 초기화 오류: $e');
    }
  }

  // 🔧 iOS 권한 요청 (기존 함수명 유지)
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

  // 🔧 FCM 초기화 (기존 함수명 유지, iOS 설정 수정)
  Future<void> _initializeFCM() async {
    try {
      _messaging = FirebaseMessaging.instance;

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

      if (Platform.isIOS) {
        // 🔧 수정: iOS 포그라운드에서 FCM 자동 알림 끄고 수동 제어
        await _messaging!.setForegroundNotificationPresentationOptions(
          alert: false,  // FCM 자동 알림 끄고 수동 제어
          badge: true,
          sound: false,  // FCM 자동 사운드 끄고 수동 제어
        );
        debugPrint('✅ iOS FCM 설정 완료 (수동 알림 제어)');
      }

      await Future.wait([
        _setupFCMToken(),
        _setupMessageListeners(),
      ]);

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      debugPrint('✅ FCM 초기화 완료');
    } catch (e) {
      debugPrint('❌ FCM 초기화 오류: $e');
    }
  }

  // 🔧 FCM 토큰 설정 (기존 함수명 유지)
  Future<void> _setupFCMToken() async {
    try {
      final token = await _messaging?.getToken();
      if (token?.isNotEmpty == true && token != _fcmToken) {
        _fcmToken = token;
        await _saveTokenToServerSafely(token!);
      }

      _messaging?.onTokenRefresh.listen((newToken) {
        if (newToken != _fcmToken) {
          _fcmToken = newToken;
          _saveTokenToServerSafely(newToken);
        }
      });

      debugPrint('✅ FCM 토큰 설정 완료');
    } catch (e) {
      debugPrint('❌ FCM 토큰 설정 오류: $e');
    }
  }

  // 🔧 메시지 리스너 설정 (기존 함수명 유지)
  Future<void> _setupMessageListeners() async {
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📨 포그라운드 FCM 수신: ${message.data}');
        _handleForegroundMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📱 백그라운드 알림 탭: ${message.data}');
        _handleNotificationTapSafely(message.data);
      });

      final initialMessage = await _messaging?.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 종료 상태에서 알림으로 앱 시작: ${initialMessage.data}');
        Future.delayed(const Duration(seconds: 2), () {
          _handleNotificationTapSafely(initialMessage.data);
        });
      }

      debugPrint('✅ FCM 메시지 리스너 설정 완료');
    } catch (e) {
      debugPrint('❌ 메시지 리스너 설정 오류: $e');
    }
  }

  // 🔧 포그라운드 메시지 처리 (개선된 라우팅 비교 로직)
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final data = message.data;
      final routing = data['routing'] ?? '';

      final context = AppRoute.context;
      if (context?.mounted != true) return;

      final currentRoute = GoRouter.of(context!).state.uri.toString();

      debugPrint('🔄 포그라운드 알림 처리 - 현재: $currentRoute, 대상: $routing');

      // 🔧 수정: 개선된 라우트 비교 로직
      final shouldShowNotification = _shouldShowForegroundNotification(currentRoute, routing);

      if (shouldShowNotification) {
        debugPrint('✅ 포그라운드에서 로컬 알림 표시');
        showConsistentNotification(data);
      } else {
        debugPrint('⏭️ 포그라운드 알림 건너뛰기 (같은 화면)');
      }

    } catch (e) {
      debugPrint('❌ 포그라운드 메시지 처리 오류: $e');
    }
  }

  // 🔧 개선된 포그라운드 알림 표시 판단 로직 (동적 라우트 파라미터 처리)
  bool _shouldShowForegroundNotification(String currentRoute, String targetRoute) {
    if (targetRoute.isEmpty) return true;
    if (currentRoute == targetRoute) return false;

    // 🔧 동적 라우트 파라미터 추출 및 비교
    final currentSegments = _extractRouteSegments(currentRoute);
    final targetSegments = _extractRouteSegments(targetRoute);

    // 같은 타입의 라우트인지 확인 (예: /room/123 vs /room/456)
    if (currentSegments.length >= 2 && targetSegments.length >= 2) {
      final currentType = currentSegments[1]; // 'room', 'schedule' 등
      final targetType = targetSegments[1];

      if (currentType == targetType && currentSegments.length >= 3 && targetSegments.length >= 3) {
        final currentId = currentSegments[2]; // roomId, scheduleId 등
        final targetId = targetSegments[2];

        // 같은 타입에서 같은 ID이면 알림 표시 안함
        return currentId != targetId;
      }
    }

    return true;
  }

  // 🔧 라우트 세그먼트 추출 헬퍼 함수
  List<String> _extractRouteSegments(String route) {
    return route.split('/').where((segment) => segment.isNotEmpty).toList();
  }

  // 🔧 일관된 알림 표시 (alarm 설정에 따른 소리/진동 제어)
  void showConsistentNotification(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;
      final groupInfo = NotificationGroupManager.getGroupInfo(type, data);
      final groupTag = groupInfo['tag']!;
      final notificationId = NotificationGroupManager.generateNotificationId(data);

      // 🔧 방별 알람 설정 확인 (새로 추가)
      final isAlarmEnabled = _isAlarmEnabled(data);

      debugPrint('📱 일관된 알림 표시: $groupTag (ID: $notificationId, Alarm: $isAlarmEnabled)');

      // 알림 추적
      NotificationTracker.trackNotification(groupTag, notificationId);

      if (Platform.isAndroid) {
        _showAndroidNotification(data, groupInfo, notificationId, isAlarmEnabled);
      } else if (Platform.isIOS) {
        _showIOSNotification(data, groupInfo, notificationId, isAlarmEnabled);
      }
    } catch (e) {
      debugPrint('❌ 일관된 알림 표시 오류: $e');
    }
  }

  // 🔧 방별 알람 설정 확인 함수 (새로 추가)
  bool _isAlarmEnabled(Map<String, dynamic> data) {
    final alarm = data['alarm'] as String?;
    return alarm == '1' || alarm == null; // 기본값은 true
  }

  // 🔧 안드로이드 알림 표시 (alarm 설정 반영)
  Future<void> _showAndroidNotification(
      Map<String, dynamic> data,
      Map<String, String> groupInfo,
      int notificationId,
      bool isAlarmEnabled,
      ) async {
    try {
      final title = data['title'] ?? '';
      final body = data['body'] ?? data['subTitle'] ?? '';
      final groupKey = groupInfo['groupKey']!;
      final tag = groupInfo['tag']!;

      // 🔧 알람 설정에 따른 소리/진동 제어
      final androidDetails = AndroidNotificationDetails(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        channelDescription: NotificationConstants.channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        groupKey: groupKey,
        setAsGroupSummary: false,
        tag: tag,
        color: NotificationConstants.notificationColor,
        // 🔧 alarm 설정에 따른 소리/진동 제어
        playSound: isAlarmEnabled,
        enableVibration: isAlarmEnabled,
        sound: isAlarmEnabled ? null : const RawResourceAndroidNotificationSound(''),
      );

      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: jsonEncode(data),
      );

      // 🔧 그룹 요약 알림 업데이트
      await _updateAndroidGroupSummary(groupKey, tag, isAlarmEnabled);

    } catch (e) {
      debugPrint('❌ 안드로이드 알림 표시 오류: $e');
    }
  }

  // 🔧 iOS 알림 표시 (alarm 설정 반영)
  Future<void> _showIOSNotification(
      Map<String, dynamic> data,
      Map<String, String> groupInfo,
      int notificationId,
      bool isAlarmEnabled,
      ) async {
    try {
      final title = data['title'] ?? '';
      final body = data['body'] ?? data['subTitle'] ?? '';
      final threadId = groupInfo['threadId']!;

      // 🔧 alarm 설정에 따른 소리 제어
      final iosDetails = DarwinNotificationDetails(
        threadIdentifier: threadId,
        presentAlert: true,
        presentBadge: true,
        // 🔧 alarm 설정에 따른 소리 제어
        presentSound: isAlarmEnabled,
        sound: isAlarmEnabled ? null : '',
      );

      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(iOS: iosDetails),
        payload: jsonEncode(data),
      );

    } catch (e) {
      debugPrint('❌ iOS 알림 표시 오류: $e');
    }
  }

  // 🔧 안드로이드 그룹 요약 알림 업데이트 (기존 함수명 유지)
  Future<void> _updateAndroidGroupSummary(String groupKey, String tag, bool isAlarmEnabled) async {
    try {
      // 🔧 수정: 32비트 범위 내로 제한
      final summaryId = (groupKey.hashCode % 2147483647).abs();
      final groupNotifications = NotificationTracker.getGroupNotifications(tag);
      final count = groupNotifications.length;

      if (count > 1) {
        final summaryDetails = AndroidNotificationDetails(
          NotificationConstants.channelId,
          NotificationConstants.channelName,
          channelDescription: NotificationConstants.channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: true,
          color: NotificationConstants.notificationColor,
          // 🔧 alarm 설정에 따른 소리/진동 제어
          playSound: isAlarmEnabled,
          enableVibration: isAlarmEnabled,
        );

        await _localNotifications.show(
          summaryId,
          '나스달',
          '$count개의 새로운 알림',
          NotificationDetails(android: summaryDetails),
        );
      }
    } catch (e) {
      debugPrint('❌ 안드로이드 그룹 요약 업데이트 오류: $e');
    }
  }

  // 🔧 안전한 토큰 저장 (기존 함수명 유지)
  Future<void> _saveTokenToServerSafely(String token) async {
    try {
      await serverManager.post('notification/fcmToken', data: {'fcmToken': token});
      debugPrint('✅ FCM 토큰 서버 저장 성공');
    } catch (e) {
      debugPrint('❌ FCM 토큰 서버 저장 실패: $e');
    }
  }

  // 🔧 로컬 알림 터치 핸들러 (기존 함수명 유지)
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

  // 🔧 그룹 알림 제거 (기존 함수명 유지, 개선된 정리 로직)
  Future<void> clearGroupNotifications(String type, String identifier) async {
    try {
      final data = {type == 'chat' ? 'roomId' : 'scheduleId': identifier};
      final groupInfo = NotificationGroupManager.getGroupInfo(type, data);
      final groupTag = groupInfo['tag']!;

      final notificationIds = NotificationTracker.getGroupNotifications(groupTag);

      debugPrint('🗑️ 그룹 알림 제거 시작: $groupTag (${notificationIds.length}개)');

      // 🔧 개별 알림 제거
      for (final notificationId in notificationIds) {
        await _localNotifications.cancel(notificationId);
      }

      // 🔧 안드로이드 그룹 요약 알림도 제거
      if (Platform.isAndroid && notificationIds.isNotEmpty) {
        // 🔧 수정: 32비트 범위 내로 제한
        final summaryId = (groupTag.hashCode % 2147483647).abs();
        await _localNotifications.cancel(summaryId);
        debugPrint('🗑️ 안드로이드 그룹 요약 알림 제거: $summaryId');
      }

      // 🔧 플랫폼별 추가 정리 (개선된 로직)
      if (Platform.isAndroid) {
        await _clearAndroidNotificationsByTag(groupTag);
      }

      if (Platform.isIOS) {
        await _clearIOSNotificationsByThread(groupTag);
      }

      NotificationTracker.clearGroup(groupTag);

      debugPrint('✅ 그룹 알림 제거 완료: $groupTag');
    } catch (e) {
      debugPrint('❌ 그룹 알림 제거 오류: $e');
    }
  }

  // 🔧 특정 Room의 모든 알림 삭제 (기존 함수명 유지)
  Future<void> clearRoomNotifications(int roomId) async {
    await clearGroupNotifications('chat', roomId.toString());
  }

  // 🔧 특정 Schedule의 모든 알림 삭제 (기존 함수명 유지)
  Future<void> clearScheduleNotifications(int scheduleId) async {
    await clearGroupNotifications('schedule', scheduleId.toString());
  }

  // 🔧 안드로이드 태그별 정리 (개선된 로직)
  Future<void> _clearAndroidNotificationsByTag(String tag) async {
    try {
      final activeNotifications = await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.getActiveNotifications();

      if (activeNotifications != null) {
        for (final notification in activeNotifications) {
          if (notification.tag == tag) {
            await _localNotifications.cancel(notification.id!);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Android 알림 정리 오류: $e');
    }
  }

  // 🔧 iOS 스레드별 정리 (수정: getDeliveredNotifications 제거)
  Future<void> _clearIOSNotificationsByThread(String threadId) async {
    try {
      final pendingNotifications = await _localNotifications.pendingNotificationRequests();

      // 🔧 개선된 thread 식별 로직
      for (final notification in pendingNotifications) {
        if (_isMatchingThread(notification.payload, threadId)) {
          await _localNotifications.cancel(notification.id);
        }
      }
    } catch (e) {
      debugPrint('❌ iOS 알림 정리 오류: $e');
    }
  }

  // 🔧 스레드 매칭 헬퍼 함수 (개선된 파싱 로직)
  bool _isMatchingThread(String? payload, String threadId) {
    if (payload == null || payload.isEmpty) return false;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final roomId = data['roomId']?.toString();
      final scheduleId = data['scheduleId']?.toString();

      if (roomId != null && threadId.contains('room_$roomId')) return true;
      if (scheduleId != null && threadId.contains('schedule_$scheduleId')) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  // 🔧 기존 API 함수들 (함수명 유지, 오류 무시 개선)
  Future<void> markNotificationAsReadFromPush(int notificationId) async {
    try {
      if (_pendingReadIds.contains(notificationId)) return;

      _pendingReadIds.add(notificationId);

      final response = await serverManager.put('notification/read', data: {'notificationId': notificationId});

      // 🔧 404 오류는 무시 (이미 삭제된 알림)
      if (response.statusCode == 404) {
        debugPrint('⚠️ 알림 ID를 찾을 수 없음 (무시): $notificationId');
        _pendingReadIds.remove(notificationId);
        return;
      }

      if (_notifications != null) {
        final index = _notifications!.indexWhere((n) => n.notificationId == notificationId);
        if (index != -1) {
          // 🔧 수정: copyWith 대신 직접 수정
          _notifications![index].isRead = true;
          notifyListeners();
        }
      }

      _pendingReadIds.remove(notificationId);
      debugPrint('✅ 알림 읽음 처리 완료: $notificationId');
    } catch (e) {
      _pendingReadIds.remove(notificationId);
      // 🔧 오류 무시하고 경고만 출력
      debugPrint('⚠️ 알림 읽음 처리 실패 (무시): $notificationId - $e');
    }
  }

  // 🔧 기존 함수: deleteNotification (기존 API 유지)
  Future<void> deleteNotification(int notificationId) async {
    try {
      final res = await serverManager.delete('notification/remove/$notificationId');

      if (res.statusCode == 204) {
        _notifications?.removeWhere((n) => n.notificationId == notificationId);
        notifyListeners();
      }

      debugPrint('✅ 알림 삭제 완료: $notificationId');
    } catch (e) {
      debugPrint('❌ 알림 삭제 오류: $e');
    }
  }

  // 🔧 기존 함수: 알림 전송
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
      final results = await Future.wait(
        receivers.map((receiver) => _sendSingleNotification(
          receiver,
          title,
          subTitle,
          routing,
        )),
        eagerError: false,
      );

      for (int i = 0; i < results.length; i++) {
        if (!results[i]) {
          failed.add(receivers[i]);
        }
      }
    } catch (e) {
      debugPrint('❌ 알림 전송 중 오류: $e');
      return receivers;
    }

    return failed;
  }

  // 🔧 기존 함수: 단일 알림 전송
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

  // 🔧 기존 함수: refreshNotifications (기존 함수명 유지)
  Future<void> refreshNotifications() async {
    await _loadNotificationsData();
  }

  // 🔧 기존 함수: 알림 데이터 로드 (수정: fromJson 호출 방식)
  Future<void> _loadNotificationsData() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await serverManager.get('notification');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // 🔧 수정: fromJson 올바른 호출 방식
        _notifications = data.map((json) => NotificationModel.fromJson(json: json)).toList();

        final unreadCount = _notifications?.where((n) => !n.isRead).length ?? 0;
        await updateAppBadge(unreadCount);
      }

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ 알림 로드 완료: ${_notifications?.length ?? 0}개');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ 알림 데이터 로드 오류: $e');
    }
  }

  // 🔧 기존 함수: clearAllNotifications
  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      NotificationTracker.clearAll();
      debugPrint('✅ 모든 알림 정리 완료');
    } catch (e) {
      debugPrint('❌ 모든 알림 정리 오류: $e');
    }
  }

  // 🔧 기존 함수: updateAppBadge
  Future<void> updateAppBadge(int count) async {
    try {
      if (count > 0) {
        await AppBadgePlus.updateBadge(count);
      } else {
        await AppBadgePlus.updateBadge(0);
      }
      debugPrint('✅ 앱 배지 업데이트: $count');
    } catch (e) {
      debugPrint('❌ 앱 배지 업데이트 오류: $e');
    }
  }

  // 🔧 앱 라이프사이클 관리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      refreshNotifications();
    }
  }
}