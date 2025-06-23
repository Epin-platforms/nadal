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
      _showBackgroundNotificationSafely(data)
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
        if(context != null){ //백그라운드라면 null로 무시
          context.read<NotificationProvider>().initialize(); //아니라면 상태 업데이트
        }
      }catch(e){
        //노티피케이션 에러나도 뱃지는 업데이트 가능하게
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

// 🔧 안전한 백그라운드 알림 표시
Future<void> _showBackgroundNotificationSafely(Map<String, dynamic> data) async {
  try {
    final routing = data['routing'];

    // 🔥 백그라운드에서 안전하게 라우팅 체크
    if (routing != null) {
      try {
        // 🔥 GoRouter에 안전하게 접근 시도
        final router = AppRoute.router;
        if (router.canPop() || router.state != null) {
          final currentUri = router.state.uri.toString();
          if (routing == currentUri) {
            debugPrint('🚫 백그라운드 - 현재 화면과 동일한 알림이므로 숨김: $routing');
            return;
          }
        }
      } catch (e) {
        // 🔥 백그라운드에서 router 접근 실패 시 무시하고 계속 진행
        debugPrint('⚠️ 백그라운드에서 라우터 접근 실패 (정상적): $e');
        debugPrint('✅ 백그라운드 상태로 판단하여 알림 표시 진행');
      }
    }

    final bool alarm = data['alarm'] == '1';
    final int? badge = data['badge'] == null ? null : (data['badge'] is String) ? int.parse(data['badge']) : null;

    //묶이는 단위 지정
    final type = data['type'];
    final thread = type == 'chat' ? 'nadal_room_${data['roomId'] ?? ''}' : type == 'general' ? 'nadal_general' : 'nadal_schedule_${data['scheduleId'] ?? ''}';

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
      tag: thread
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: alarm,
      presentBadge: true,
      presentSound: alarm,
      badgeNumber: badge,
      interruptionLevel: InterruptionLevel.active,
      categoryIdentifier: 'nadal_notification',
      threadIdentifier: thread,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if(data['title'] != null){
      await _localNotifications.show(
        id,
        data['title'],
        data['body'],
        details,
        payload: jsonEncode(data),
      );
    }
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
    final router = GoRouter.of(context);
    final current = router.state.uri.toString();

    if (current == routing) return;

    // 안전한 라우팅
    if (context.mounted) {
      router.go('/my');
      context.read<HomeProvider>().setMenu(0);
      router.push(routing);
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

// 🔧 메인 알림 프로바이더 (백그라운드 상태 감지 추가)
class NotificationProvider extends ChangeNotifier {
  // 🔧 상태 변수 (최소화)
  List<NotificationModel>? _notifications;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _fcmToken;

  // 🔧 대기열 (메모리 효율적)
  final Set<int> _pendingReadIds = <int>{};

  // 🔧 Room별 알림 ID 관리를 위한 Map
  final Map<String, Set<int>> _roomNotificationIds = {};

  // 🔧 Firebase 인스턴스 (지연 초기화)
  FirebaseMessaging? _messaging;

  // Getters
  List<NotificationModel>? get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // 🔧 앱 백그라운드/포그라운드 상태 체크
  bool get _isAppInBackground {
    try {
      // SocketManager의 연결 상태로 앱 상태 판단
      // true = 포그라운드 (소켓 연결됨), false = 백그라운드 (소켓 연결 끊김)
      return !SocketManager.instance.isConnected;
    } catch (e) {
      debugPrint('❌ 앱 상태 체크 오류: $e');
      return false; // 오류 시 포그라운드로 간주
    }
  }

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

  // 🔧 FCM 초기화 (간소화된 안정적 버전)
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

      // 🔥 간소화된 iOS 설정 (모든 상태에서 FCM 시스템 알림 사용)
      if (Platform.isIOS) {
        await _messaging!.setForegroundNotificationPresentationOptions(
          alert: true,    // ✅ 모든 상태에서 알림 표시
          badge: true,    // 배지 활성화
          sound: true,    // 소리 활성화
        );
        debugPrint('✅ iOS FCM 설정 완료 (모든 상태에서 시스템 알림 사용)');
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

  // 🔧 메시지 리스너 설정 (간소화)
  Future<void> _setupMessageListeners() async {
    try {
      // 포그라운드 메시지 처리 (백그라운드 상태 고려)
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
        debugPrint('📱 초기 메시지 (앱 종료 상태에서 알림 탭): ${initialMessage.messageId}');
        Future.microtask(() => _handleNotificationTapSafely(initialMessage.data));
      }
    } catch (e) {
      debugPrint('❌ 메시지 리스너 설정 오류: $e');
    }
  }

  // 🔧 포그라운드 메시지 처리 (백그라운드 상태 고려 수정) : 안드로이드에서 출력
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.isEmpty) return;

      debugPrint('📱 포그라운드 메시지 수신');

      _updateBadgeSafely(data);

      // 🔧 Room 알림 추적 (FCM 알림이지만 추적은 필요)
      _trackRoomNotificationIfNeeded(data);

      // 🔥 핵심 수정: 백그라운드 상태 체크
      final isBackground = _isAppInBackground;
      debugPrint('📱 앱 상태: ${isBackground ? "백그라운드" : "포그라운드"}');

      if (isBackground) {
        // 🔥 백그라운드 상태면 무조건 알림 표시
        debugPrint('🌙 백그라운드 상태 - 무조건 FCM 시스템 알림 표시');
        _showBackgroundNotificationSafely(data);
        return; // FCM이 자동으로 시스템 알림을 표시함
      }

      // 🔥 포그라운드 상태에서만 중복 체크
      if (!_shouldShowForegroundNotification(data)) {
        debugPrint('🚫 포그라운드 상태 - 현재 화면과 동일한 알림이므로 표시하지 않음');
        return;
      }

      _showBackgroundNotificationSafely(data);
    } catch (e) {
      debugPrint('❌ 포그라운드 메시지 처리 오류: $e');
    }
  }

  // 🔧 Room 알림 추적 (FCM 알림도 추적)
  void _trackRoomNotificationIfNeeded(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;
      final routing = data['routing'] as String?;

      if (type == 'chat' && routing != null) {
        final roomId = _extractIdSafely(routing, r'/room/(\d+)');
        if (roomId != null) {
          final roomKey = 'room_$roomId';
          _roomNotificationIds[roomKey] ??= <int>{};

          // FCM 알림은 고유 ID를 생성해서 추적
          final notificationId = data['notificationId'] != null
              ? int.tryParse(data['notificationId']) ?? DateTime.now().millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch;

          _roomNotificationIds[roomKey]!.add(notificationId);
          debugPrint('🏠 Room $roomId FCM 알림 추적: $notificationId');
        }
      }
    } catch (e) {
      debugPrint('❌ Room 알림 추적 오류: $e');
    }
  }

  // 🔧 포그라운드에서만 사용되는 중복 방지 체크 (백그라운드는 항상 true)
  bool _shouldShowForegroundNotification(Map<String, dynamic> data) {
    try {
      final context = AppRoute.context;
      if (context == null) return true;

      final router = GoRouter.of(context);
      final currentUri = router.state.uri.toString();
      final routing = data['routing'] as String?;

      if (routing?.isEmpty != false) return true;

      // 채팅방 체크 (같은 방에 있으면 알림 숨김)
      if (routing!.contains('/room/') && currentUri.contains('/room/')) {
        final routingRoomId = _extractIdSafely(routing, r'/room/(\d+)');
        final currentRoomId = _extractIdSafely(currentUri, r'/room/(\d+)');
        if (routingRoomId == currentRoomId) {
          debugPrint('🏠 동일한 방($routingRoomId)에 있음 - 포그라운드에서 알림 숨김');
          return false; // 같은 방이면 알림 숨김
        }
      }

      // 스케줄 체크 (같은 스케줄에 있으면 알림 숨김)
      if (routing.contains('/schedule/') && currentUri.contains('/schedule/')) {
        final routingScheduleId = _extractIdSafely(routing, r'/schedule/(\d+)');
        final currentScheduleId = _extractIdSafely(currentUri, r'/schedule/(\d+)');
        if (routingScheduleId == currentScheduleId) {
          debugPrint('📅 동일한 스케줄($routingScheduleId)에 있음 - 포그라운드에서 알림 숨김');
          return false; // 같은 스케줄이면 알림 숨김
        }
      }

      return true; // 다른 화면이면 알림 표시
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

  // 🔧 특정 Room의 모든 알림 삭제 (FCM 알림은 시스템에서 자동 관리)
  // NotificationProvider에 추가
  Future<void> clearRoomNotifications(int roomId) async {
    try {
      final roomTag = 'room_$roomId';

      // 🔥 Android: tag 기반으로 알림 정리
      if (Platform.isAndroid) {
        // Android는 tag로 특정 알림만 제거 가능
        await _clearAndroidNotificationsByTag(roomTag);
      }

      // 🔥 iOS: thread-id 기반으로 정리 (iOS는 개별 제거가 어려워서 전체 정리)
      if (Platform.isIOS) {
        await _clearIOSNotificationsByThread(roomTag);
      }

      // 앱 내 추적 데이터 정리
      _roomNotificationIds.remove('room_$roomId');

      debugPrint('✅ Room $roomId 알림 정리 완료');
    } catch (e) {
      debugPrint('❌ Room 알림 정리 오류: $e');
    }
  }

  Future<void> _clearAndroidNotificationsByTag(String tag) async {
    try {
      // Android에서는 tag를 사용해 특정 알림만 제거
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
      // iOS는 thread-id로 그룹화된 알림을 정리하기 어려우므로
      // 필요시 전체 정리하거나 다른 방법 사용
      final pendingNotifications = await _localNotifications.pendingNotificationRequests();

      // 특정 조건의 알림만 찾아서 제거 (payload 확인)
      for (final notification in pendingNotifications) {
        if (notification.payload?.contains('"roomId":"${threadId.split('_')[1]}"') == true) {
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
    _roomNotificationIds.clear();
    super.dispose();
  }
}