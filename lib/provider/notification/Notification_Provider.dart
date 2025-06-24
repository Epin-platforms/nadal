import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
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

// 🔧 일관된 알림 그룹 관리 클래스
class NotificationGroupManager {
  // 🔧 그룹 정보 생성 (FCM과 로컬 알림 모두 동일 사용)
  static Map<String, String> getGroupInfo(String? type, Map<String, dynamic> data) {
    switch (type) {
      case 'chat':
        final roomId = data['roomId'] ?? '';
        return {
          'tag': 'nadal_room_$roomId',
          'groupKey': 'nadal_chat_group',
          'collapseKey': 'nadal_room_$roomId', // 백엔드와 동일
        };
      case 'schedule':
        final scheduleId = data['scheduleId'] ?? '';
        return {
          'tag': 'nadal_schedule_$scheduleId',
          'groupKey': 'nadal_schedule_group',
          'collapseKey': 'nadal_schedule_$scheduleId', // 백엔드와 동일
        };
      default:
        return {
          'tag': 'nadal_general',
          'groupKey': 'nadal_general_group',
          'collapseKey': 'nadal_general', // 백엔드와 동일
        };
    }
  }

  // 🔧 알림 ID 생성 (FCM과 로컬 알림 동일 사용)
  static int generateNotificationId(Map<String, dynamic> data) {
    // 서버에서 온 notificationId가 있으면 사용, 없으면 chatId, 그것도 없으면 타임스탬프
    if (data['notificationId'] != null) {
      return int.tryParse(data['notificationId'].toString()) ?? DateTime.now().millisecondsSinceEpoch;
    }
    if (data['chatId'] != null) {
      return int.tryParse(data['chatId'].toString()) ?? DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }
}

// 🔧 알림 추적 관리 클래스 (기존 구조 유지하되 내부 로직 개선)
class NotificationTracker {
  static final Map<String, Set<int>> _groupNotifications = {};

  // 알림 추가 추적
  static void trackNotification(String groupTag, int notificationId) {
    _groupNotifications[groupTag] ??= <int>{};
    _groupNotifications[groupTag]!.add(notificationId);
    debugPrint('📊 알림 추적 추가: $groupTag -> $notificationId');
  }

  // 그룹의 모든 알림 ID 가져오기
  static Set<int> getGroupNotifications(String groupTag) {
    return _groupNotifications[groupTag] ?? <int>{};
  }

  // 특정 그룹 정리
  static void clearGroup(String groupTag) {
    _groupNotifications.remove(groupTag);
    debugPrint('🗑️ 그룹 추적 정리: $groupTag');
  }

  // 모든 추적 데이터 정리
  static void clearAll() {
    _groupNotifications.clear();
    debugPrint('🗑️ 모든 알림 추적 데이터 정리');
  }
}

// 🔧 백그라운드 알림 터치 핸들러
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

// 🔧 백그라운드 메시지 핸들러 (수정: 로컬 알림 생성 안함)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📳 백그라운드 FCM 수신: ${message.data}');

  // 🔧 백그라운드에서는 FCM 자체 알림만 사용 (로컬 알림 생성 안함)
  try {
    if (message.data.isNotEmpty) {
      debugPrint('✅ 백그라운드 메시지 데이터 처리 완료');
    }
  } catch (e) {
    debugPrint('❌ 백그라운드 메시지 처리 오류: $e');
  }
}

// 🔧 안전한 알림 터치 처리
void _handleNotificationTapSafely(Map<String, dynamic> data) {
  final context = AppRoute.context;
  if (context?.mounted != true) return;

  try {
    final notificationId = NotificationGroupManager.generateNotificationId(data);
    if (context!.mounted) {
      final provider = context.read<NotificationProvider>();
      provider.markNotificationAsReadFromPush(notificationId);
    }

    final routing = data['routing'] as String?;
    if (routing?.isNotEmpty == true && context.mounted) {
      _navigateToRouteSafely(context, routing!);
    }
  } catch (e) {
    debugPrint('❌ 알림 터치 처리 오류: $e');
  }
}

// 🔧 안전한 라우팅 처리
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

  // 🔧 정확한 앱 상태 판단
  bool get isAppInBackground => _appLifecycleState != AppLifecycleState.resumed;

  // 🔧 안전한 초기화 (기존 함수명 유지)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 일관된 알림 시스템 초기화 시작');

      // 🔧 앱 라이프사이클 관찰자 등록
      WidgetsBinding.instance.addObserver(this);

      await _initializeLocalNotifications();
      await _initializeFCM();
      await _loadNotificationsData();

      _isInitialized = true;
      debugPrint('✅ 일관된 알림 시스템 초기화 완료');
    } catch (e) {
      debugPrint('❌ 알림 초기화 오류: $e');
      _isInitialized = true;
    }
  }

  // 🔧 앱 라이프사이클 변화 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appLifecycleState = state;

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 앱이 포그라운드로 전환됨');
        break;
      case AppLifecycleState.paused:
        debugPrint('📱 앱이 백그라운드로 전환됨');
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 앱이 종료됨');
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 앱이 비활성 상태');
        break;
      default : debugPrint('📱 상태: $state');
      break;
    }
  }

  // 🔧 로컬 알림 초기화 (기존 함수명 유지)
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

      await Future.wait([
        if (Platform.isAndroid) _createAndroidNotificationChannels(),
        if (Platform.isIOS) _requestIOSPermissions(),
      ]);

      debugPrint('✅ 로컬 알림 초기화 완료');
    } catch (e) {
      debugPrint('❌ 로컬 알림 초기화 오류: $e');
    }
  }

  // 🔧 Android 채널 생성 (기존 함수명 유지)
  Future<void> _createAndroidNotificationChannels() async {
    try {
      const channel = AndroidNotificationChannel(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        description: NotificationConstants.channelDesc,
        importance: Importance.high,
        groupId: 'nadal_main_group',
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      debugPrint('✅ Android 알림 채널 생성 완료');
    } catch (e) {
      debugPrint('❌ Android 채널 생성 오류: $e');
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

  // 🔧 FCM 초기화 (기존 함수명 유지, 내부 로직만 수정)
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
        // 🔧 수정: iOS 포그라운드 알림 표시 활성화
        await _messaging!.setForegroundNotificationPresentationOptions(
          alert: true,  // 수정: false -> true
          badge: true,
          sound: true,
        );
        debugPrint('✅ iOS FCM 설정 완료 (포그라운드 알림 활성화)');
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

  // 🔧 메시지 리스너 설정 (기존 함수명 유지, 내부 로직 수정)
  Future<void> _setupMessageListeners() async {
    try {
      // 포그라운드 메시지 리스너
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📨 포그라운드 FCM 수신: ${message.data}');
        _handleForegroundMessage(message);
      });

      // 백그라운드에서 알림 탭 리스너
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📱 백그라운드 알림 탭: ${message.data}');
        _handleNotificationTapSafely(message.data);
      });

      // 앱이 종료된 상태에서 알림으로 앱 열기
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

  // 🔧 포그라운드 메시지 처리 (기존 함수명 유지, 내부 로직 개선)
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final data = message.data;
      final routing = data['routing'] ?? '';

      // 현재 라우트 확인
      final context = AppRoute.context;
      if (context?.mounted != true) return;

      final currentRoute = GoRouter.of(context!).state.uri.toString();

      debugPrint('🔄 포그라운드 알림 처리 - 현재: $currentRoute, 대상: $routing');

      // 🔧 수정: 더 정확한 라우트 비교 로직
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

  // 🔧 새로 추가: 포그라운드 알림 표시 판단 로직
  bool _shouldShowForegroundNotification(String currentRoute, String targetRoute) {
    // 빈 라우팅인 경우 항상 표시
    if (targetRoute.isEmpty) return true;

    // 정확히 같은 라우트인 경우 표시 안함
    if (currentRoute == targetRoute) return false;

    // 채팅방 관련 특별 처리
    if (targetRoute.startsWith('/room/') && currentRoute.startsWith('/room/')) {
      return currentRoute != targetRoute;
    }

    // 스케줄 관련 특별 처리
    if (targetRoute.startsWith('/schedule/') && currentRoute.startsWith('/schedule/')) {
      return currentRoute != targetRoute;
    }

    // 그 외의 경우 모두 표시
    return true;
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

  // 🔧 새로 추가: 안드로이드 그룹 요약 알림 생성
  Future<void> _createGroupSummaryNotification(String groupKey, String groupTag, int count) async {
    if (!Platform.isAndroid) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        channelDescription: NotificationConstants.channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: NotificationConstants.androidIcon,
        color: NotificationConstants.notificationColor,
        autoCancel: true,
        groupKey: groupKey,
        setAsGroupSummary: true, // 그룹 요약으로 설정
        styleInformation: InboxStyleInformation(
          [],
          contentTitle: '새 메시지 $count개',
          summaryText: 'Nadal',
        ),
      );

      final details = NotificationDetails(android: androidDetails);
      final summaryId = groupTag.hashCode.abs();

      await _localNotifications.show(
        summaryId,
        '새 알림',
        '$count개의 새 알림이 있습니다',
        details,
      );

      debugPrint('✅ 안드로이드 그룹 요약 알림 생성: $groupKey ($count개)');
    } catch (e) {
      debugPrint('❌ 그룹 요약 알림 생성 오류: $e');
    }
  }

  // 🔧 일관된 알림 표시 (기존 함수명 유지, 내부 로직 개선)
  Future<void> showConsistentNotification(Map<String, dynamic> data) async {
    try {
      final alarm = data['alarm'] == '1';
      int? badge = data['badge'] == null ? null :
      (data['badge'] is String) ? int.parse(data['badge']) : null;

      // 🔧 일관된 그룹 정보 사용
      final type = data['type'];
      final groupInfo = NotificationGroupManager.getGroupInfo(type, data);
      final notificationId = NotificationGroupManager.generateNotificationId(data);

      // 🔧 알림 추적 (FCM과 로컬 알림 모두)
      NotificationTracker.trackNotification(groupInfo['tag']!, notificationId);

      final androidDetails = AndroidNotificationDetails(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        channelDescription: NotificationConstants.channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: NotificationConstants.androidIcon,
        color: NotificationConstants.notificationColor,
        autoCancel: true,
        playSound: alarm,
        enableVibration: alarm,
        // 🔧 일관된 그룹화 정보
        tag: groupInfo['tag'],
        groupKey: groupInfo['groupKey'],
        setAsGroupSummary: false,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: alarm,
        presentBadge: true,
        presentSound: alarm,
        badgeNumber: badge,
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: 'nadal_notification',
        threadIdentifier: groupInfo['tag'], // Android와 동일한 식별자
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      if(data['title'] != null){
        await _localNotifications.show(
          notificationId, // 🔧 일관된 ID 사용
          data['title'],
          data['body'],
          details,
          payload: jsonEncode(data),
        );

        // 🔧 새로 추가: 안드로이드 그룹화를 위한 요약 알림 생성
        if (Platform.isAndroid) {
          final groupNotifications = NotificationTracker.getGroupNotifications(groupInfo['tag']!);
          if (groupNotifications.length > 1) {
            await _createGroupSummaryNotification(
                groupInfo['groupKey']!,
                groupInfo['tag']!,
                groupNotifications.length
            );
          }
        }

        debugPrint('✅ 일관된 알림 표시 완료: ID=$notificationId, Tag=${groupInfo['tag']}');
      }
    } catch (e) {
      debugPrint('❌ 일관된 알림 표시 오류: $e');
    }
  }

  // 🔧 알림 데이터 로드 (기존 함수명 유지)
  Future<void> _loadNotificationsData() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      final res = await serverManager.get('notification');
      if (res.statusCode == 200 && res.data != null) {
        final List<dynamic> data = List.from(res.data);
        _notifications = data
            .map((e) => NotificationModel.fromJson(json: e))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
      debugPrint('✅ 알림 데이터 로드 완료: ${_notifications?.length ?? 0}개');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ 알림 데이터 로드 오류: $e');
    }
  }

  // 🔧 그룹 알림 제거 (기존 함수명 유지, 내부 로직 개선)
  Future<void> clearGroupNotifications(String type, String identifier) async {
    try {
      final data = {type == 'chat' ? 'roomId' : 'scheduleId': identifier};
      final groupInfo = NotificationGroupManager.getGroupInfo(type, data);
      final groupTag = groupInfo['tag']!;

      // 🔧 추적된 모든 알림 ID 가져오기
      final notificationIds = NotificationTracker.getGroupNotifications(groupTag);

      debugPrint('🗑️ 그룹 알림 제거 시작: $groupTag (${notificationIds.length}개)');

      // 🔧 개별 알림 제거 (더 정확함)
      for (final notificationId in notificationIds) {
        await _localNotifications.cancel(notificationId);
      }

      // 🔧 수정: 안드로이드 그룹 요약 알림도 제거
      if (Platform.isAndroid && notificationIds.isNotEmpty) {
        final summaryId = groupTag.hashCode.abs();
        await _localNotifications.cancel(summaryId);
        debugPrint('🗑️ 안드로이드 그룹 요약 알림 제거: $summaryId');
      }

      // 🔧 플랫폼별 추가 정리
      if (Platform.isAndroid) {
        await _clearAndroidNotificationsByTag(groupTag);
      }

      if (Platform.isIOS) {
        await _clearIOSNotificationsByThread(groupTag);
      }

      // 🔧 추적 데이터 정리
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

  // 기존 함수들 (함수명 유지, 내부 로직 개선)
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

  Future<void> _clearIOSNotificationsByThread(String threadId) async {
    try {
      final pendingNotifications = await _localNotifications.pendingNotificationRequests();

      for (final notification in pendingNotifications) {
        if (notification.payload?.contains('"${threadId.split('_')[1]}Id":"${threadId.split('_')[2]}"') == true) {
          await _localNotifications.cancel(notification.id);
        }
      }
    } catch (e) {
      debugPrint('❌ iOS 알림 정리 오류: $e');
    }
  }

  // 🔧 기존 API 함수들 (함수명 유지)
  Future<void> markNotificationAsReadFromPush(int notificationId) async {
    try {
      if (_pendingReadIds.contains(notificationId)) return;

      _pendingReadIds.add(notificationId);

      await serverManager.put('notification/read', data: {'notificationId': notificationId});

      if (_notifications != null) {
        final index = _notifications!.indexWhere((n) => n.notificationId == notificationId);
        if (index != -1) {
          _notifications![index].isRead = true;
          notifyListeners();
        }
      }

      _pendingReadIds.remove(notificationId);
      debugPrint('✅ 알림 읽음 처리 완료: $notificationId');
    } catch (e) {
      _pendingReadIds.remove(notificationId);
      debugPrint('❌ 알림 읽음 처리 오류: $e');
    }
  }

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

  // 🔧 알림 전송
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

  // 🔧 단일 알림 전송
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

  Future<void> refreshNotifications() async {
    await _loadNotificationsData();
  }

  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      NotificationTracker.clearAll();
      debugPrint('✅ 모든 알림 정리 완료');
    } catch (e) {
      debugPrint('❌ 모든 알림 정리 오류: $e');
    }
  }

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

  // 🔧 안전한 정리 (기존 함수명 유지)
  @override
  void dispose() {
    _pendingReadIds.clear();
    NotificationTracker.clearAll();

    // 🔧 앱 라이프사이클 관찰자 제거
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }
}