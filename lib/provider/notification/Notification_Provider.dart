import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/app/Notifications_Model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';

import '../../manager/server/Socket_Manager.dart';

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

// 🔧 알림 추적 관리 클래스
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

  // 그룹 알림 정리
  static void clearGroup(String groupTag) {
    final removed = _groupNotifications.remove(groupTag);
    if (removed != null) {
      debugPrint('🗑️ 알림 추적 그룹 제거: $groupTag (${removed.length}개)');
    }
  }

  // 전체 정리
  static void clearAll() {
    _groupNotifications.clear();
    debugPrint('🗑️ 모든 알림 추적 정리');
  }
}

// 🔧 글로벌 인스턴스 (메모리 효율성)
final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

// 🔧 백그라운드 메시지 핸들러 (일관성 개선)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('🔔 백그라운드 메시지: ${message.messageId}');

    final data = message.data;
    if (data.isEmpty) return;

    await Future.wait([
      _updateBadgeSafely(data),
      _showConsistentNotification(data, isBackground: true)
    ]);

  } catch (e) {
    debugPrint('❌ 백그라운드 핸들러 오류: $e');
  }
}

// 🔧 안전한 배지 업데이트
Future<void> _updateBadgeSafely(Map<String, dynamic> data) async {
  try {
    final badgeStr = data['badge'] as String?;

    if(data['type'] != 'chat'){
      try{
        final context = AppRoute.context;
        if(context != null){
          context.read<NotificationProvider>().initialize();
        }
      }catch(e){
        debugPrint('노티피케이션 리셋 실패:$e');
      }
    }

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

// 🔧 일관된 알림 표시 함수 (FCM과 로컬 알림 통합)
Future<void> _showConsistentNotification(Map<String, dynamic> data, {bool isBackground = false}) async {
  try {
    final routing = data['routing'];

    // 🔧 라우팅 중복 체크 (백그라운드에서만)
    if (isBackground && routing != null) {
      try {
        final router = AppRoute.router;
        if (router.canPop() || router.state != null) {
          final currentUri = router.state.uri.toString();
          if (routing == currentUri) {
            debugPrint('🚫 현재 화면과 동일한 알림이므로 숨김: $routing');
            return;
          }
        }
      } catch (e) {
        debugPrint('⚠️ 라우터 접근 실패 (정상적): $e');
      }
    }

    final bool alarm = data['alarm'] == '1';
    final int? badge = data['badge'] == null ? null : (data['badge'] is String) ? int.parse(data['badge']) : null;

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

      debugPrint('✅ 일관된 알림 표시 완료: ID=$notificationId, Tag=${groupInfo['tag']}');
    }
  } catch (e) {
    debugPrint('❌ 일관된 알림 표시 오류: $e');
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

// 🔧 메인 알림 프로바이더 (일관성 개선)
class NotificationProvider extends ChangeNotifier {
  List<NotificationModel>? _notifications;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _fcmToken;

  final Set<int> _pendingReadIds = <int>{};

  FirebaseMessaging? _messaging;

  // Getters
  List<NotificationModel>? get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  bool get _isAppInBackground {
    try {
      return !SocketManager.instance.isConnected;
    } catch (e) {
      debugPrint('❌ 앱 상태 체크 오류: $e');
      return false;
    }
  }

  // 🔧 안전한 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 일관된 알림 시스템 초기화 시작');

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

  // 🔧 로컬 알림 초기화
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

  // 🔧 Android 채널 생성
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

  // 🔧 iOS 권한 요청
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

  // 🔧 FCM 초기화
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
        await _messaging!.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: false,
        );
        debugPrint('✅ iOS FCM 설정 완료 (포그라운드 중복 알림 방지)');
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

  // 🔧 FCM 토큰 설정
  Future<void> _setupFCMToken() async {
    try {
      final token = await _messaging?.getToken();
      if (token?.isNotEmpty == true && token != _fcmToken) {
        _fcmToken = token;
        await _saveTokenToServerSafely(token!);
      }

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

  // 🔧 메시지 리스너 설정
  Future<void> _setupMessageListeners() async {
    try {
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('📱 포그라운드 메시지: ${message.messageId}');
        _handleForegroundMessage(message);
      }).onError((error) {
        debugPrint('❌ 포그라운드 메시지 오류: $error');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('📱 앱 실행 중 알림 탭: ${message.messageId}');
        _handleNotificationTapSafely(message.data);
      }).onError((error) {
        debugPrint('❌ 알림 탭 처리 오류: $error');
      });

      final initialMessage = await _messaging?.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📱 초기 메시지: ${initialMessage.messageId}');
        Future.microtask(() => _handleNotificationTapSafely(initialMessage.data));
      }
    } catch (e) {
      debugPrint('❌ 메시지 리스너 설정 오류: $e');
    }
  }

  // 🔧 포그라운드 메시지 처리 (일관성 개선)
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.isEmpty) return;

      debugPrint('📱 포그라운드 메시지 수신');

      _updateBadgeSafely(data);

      final isBackground = _isAppInBackground;
      debugPrint('📱 앱 상태: ${isBackground ? "백그라운드" : "포그라운드"}');

      if (isBackground) {
        debugPrint('🌙 백그라운드 상태 - 알림 표시');
        _showConsistentNotification(data, isBackground: true);
        return;
      }

      if (!_shouldShowForegroundNotification(data)) {
        debugPrint('🚫 포그라운드 상태 - 현재 화면과 동일한 알림이므로 표시하지 않음');
        return;
      }

      debugPrint('✅ 포그라운드 상태 - 다른 화면이므로 알림 표시');
      _showConsistentNotification(data, isBackground: false);
    } catch (e) {
      debugPrint('❌ 포그라운드 메시지 처리 오류: $e');
    }
  }

  // 🔧 포그라운드 알림 표시 여부 판단
  bool _shouldShowForegroundNotification(Map<String, dynamic> data) {
    try {
      final context = AppRoute.context;
      if (context == null) {
        debugPrint('⚠️ Context가 null - 알림 표시');
        return true;
      }

      final router = GoRouter.of(context);
      final currentUri = router.state.uri.toString();
      final routing = data['routing'] as String?;

      debugPrint('📍 현재 경로: $currentUri');
      debugPrint('📍 알림 경로: $routing');

      if (routing?.isEmpty != false) {
        debugPrint('✅ 라우팅 정보 없음 - 알림 표시');
        return true;
      }

      if (currentUri == routing) {
        debugPrint('🚫 완전히 동일한 경로 - 알림 숨김');
        return false;
      }

      // 채팅방 체크
      if (routing!.contains('/room/') && currentUri.contains('/room/')) {
        final routingRoomId = _extractIdSafely(routing, r'/room/(\d+)');
        final currentRoomId = _extractIdSafely(currentUri, r'/room/(\d+)');

        if (routingRoomId != null && currentRoomId != null && routingRoomId == currentRoomId) {
          debugPrint('🚫 동일한 방($routingRoomId)에 있음 - 알림 숨김');
          return false;
        }
      }

      // 스케줄 체크
      if (routing.contains('/schedule/') && currentUri.contains('/schedule/')) {
        final routingScheduleId = _extractIdSafely(routing, r'/schedule/(\d+)');
        final currentScheduleId = _extractIdSafely(currentUri, r'/schedule/(\d+)');

        if (routingScheduleId != null && currentScheduleId != null && routingScheduleId == currentScheduleId) {
          debugPrint('🚫 동일한 스케줄($routingScheduleId)에 있음 - 알림 숨김');
          return false;
        }
      }

      debugPrint('✅ 다른 화면이므로 알림 표시');
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

  // 🔧 알림 데이터 로드
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

  // 🔧 대기 중인 읽음 처리
  Future<void> _processPendingReads() async {
    if (_pendingReadIds.isEmpty) return;

    final pendingIds = List<int>.from(_pendingReadIds);
    _pendingReadIds.clear();

    for (final id in pendingIds) {
      await _markAsReadSafely(id);
    }
  }

  // 🔧 Push에서 읽음 처리
  Future<void> markNotificationAsReadFromPush(int notificationId) async {
    if (_notifications != null) {
      await _markAsReadSafely(notificationId);
      notifyListeners();
    } else {
      _pendingReadIds.add(notificationId);
    }
  }

  // 🔧 안전한 읽음 처리
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

  // 🔧 UI에서 읽음 처리
  Future<bool> readNotification(int notificationId) async {
    final index = _notifications?.indexWhere((e) => e.notificationId == notificationId);
    if (index == null || index == -1) return false;
    if (_notifications![index].isRead) return true;

    _notifications![index].isRead = true;
    notifyListeners();

    try {
      final res = await serverManager.put('notification/read', data: {'notificationId': notificationId});
      return res.statusCode == 204;
    } catch (e) {
      debugPrint('❌ 읽음 처리 오류: $e');
      _notifications![index].isRead = false;
      notifyListeners();
      return false;
    }
  }

  // 🔧 알림 삭제
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final res = await serverManager.delete('notification/remove/$notificationId');

      if (res.statusCode == 204) {
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

  // 🔧 알림 새로고침
  Future<void> refreshNotifications() async {
    await _loadNotificationsData();
  }

  // 🔧 완전히 일관된 그룹 알림 제거
  Future<void> clearGroupNotifications(String groupType, String id) async {
    try {
      // 🔧 일관된 그룹 태그 생성
      final data = {
        'type': groupType,
        if (groupType == 'chat') 'roomId': id,
        if (groupType == 'schedule') 'scheduleId': id,
      };

      final groupInfo = NotificationGroupManager.getGroupInfo(groupType, data);
      final groupTag = groupInfo['tag']!;

      // 🔧 추적된 모든 알림 ID 가져오기
      final notificationIds = NotificationTracker.getGroupNotifications(groupTag);

      debugPrint('🗑️ 그룹 알림 제거 시작: $groupTag (${notificationIds.length}개)');

      // 🔧 개별 알림 제거 (더 정확함)
      for (final notificationId in notificationIds) {
        await _localNotifications.cancel(notificationId);
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

  // 🔧 특정 Room의 모든 알림 삭제 (호환성)
  Future<void> clearRoomNotifications(int roomId) async {
    await clearGroupNotifications('chat', roomId.toString());
  }

  // 🔧 특정 Schedule의 모든 알림 삭제
  Future<void> clearScheduleNotifications(int scheduleId) async {
    await clearGroupNotifications('schedule', scheduleId.toString());
  }

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

  // 🔧 안전한 정리
  @override
  void dispose() {
    _pendingReadIds.clear();
    NotificationTracker.clearAll();
    super.dispose();
  }
}