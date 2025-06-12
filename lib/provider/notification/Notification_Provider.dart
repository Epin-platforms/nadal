import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/app/Notifications_Model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';

const String _channelId = 'epin.nadal.chat.channel';
const String _channelName = 'Nadal_Chat_ver1.0.0';
const String _channelDesc = '나스달 알림';
const String _androidNotiIcon = '@drawable/android_noti_icon';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('백그라운드 메시지 수신: ${message.messageId}');

  // 백그라운드에서 배지 업데이트
  if (message.data['badge'] != null) {
    final badgeCount = int.tryParse(message.data['badge']) ?? 0;
    try {
      await AppBadgePlus.updateBadge(badgeCount);
      print('백그라운드 배지 업데이트: $badgeCount');
    } catch (e) {
      print('백그라운드 배지 업데이트 오류: $e');
    }
  }

  // 백그라운드에서도 로컬 알림 표시
  try {
    await _showBackgroundLocalNotification(message.data);
  } catch (e) {
    print('백그라운드 로컬 알림 오류: $e');
  }
}

// 백그라운드용 로컬 알림 표시 함수
Future<void> _showBackgroundLocalNotification(Map<String, dynamic> data) async {
  const androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
    icon: _androidNotiIcon,
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.active,
    categoryIdentifier: 'nadal_notification',
  );

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  await flutterLocalNotificationsPlugin.show(
    id,
    data['title'] ?? '새로운 알림',
    data['body'] ?? data['subTitle'] ?? '확인해보세요',
    notificationDetails,
    payload: jsonEncode(data),
  );
}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  if (response.payload != null) {
    try {
      final data = jsonDecode(response.payload!);
      _handleNotificationTap(data);
    } catch (e) {
      print('알림 페이로드 디코딩 오류: $e');
    }
  }
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel>? _notifications;
  List<NotificationModel>? get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final Set<int> _pendingReadNotifications = <int>{};
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _currentFcmToken;

  NotificationProvider();

  Future<void> initialize() async {
    await initNotification();
  }

  Future<void> initNotification() async {
    try {
      await fetchNotifications();
      try {
        await initializeFCM();
      } catch (e) {
        print('initializeFCM 실패: $e');
      }
    } catch (e) {
      print('알림 초기화 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() async {
    if (_isLoading) return;

    try {
      _isLoading = true;

      if (_notifications != null) notifyListeners();

      final res = await serverManager.get('notification');

      _notifications ??= [];

      if (res.statusCode == 200) {
        final List<dynamic> newNotifications = List.from(res.data);
        _notifications = newNotifications
            .map((e) => NotificationModel.fromJson(json: e))
            .toList();

        await _processPendingReadNotifications();

        notifyListeners();
      } else {
        print('알림 데이터 가져오기 실패: ${res.statusCode}');
      }
    } catch (e) {
      print('알림 가져오기 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _processPendingReadNotifications() async {
    if (_pendingReadNotifications.isEmpty) return;

    final pendingIds = List<int>.from(_pendingReadNotifications);
    _pendingReadNotifications.clear();

    for (final notificationId in pendingIds) {
      try {
        await _markNotificationAsReadSafely(notificationId);
      } catch (e) {
        print('대기 중인 알림 읽음 처리 오류 (ID: $notificationId): $e');
      }
    }
  }

  Future<void> _markNotificationAsReadSafely(int notificationId) async {
    if (_notifications == null) return;

    final notificationIndex =
    _notifications!.indexWhere((e) => e.notificationId == notificationId);
    if (notificationIndex != -1 && !_notifications![notificationIndex].isRead) {
      _notifications![notificationIndex].isRead = true;
      _sendReadNotificationToServer(notificationId);
    }
  }

  void _sendReadNotificationToServer(int notificationId) async {
    try {
      await serverManager.put('notification/read',
          data: {'notificationId': notificationId});
      print('알림 읽음 처리 서버 전송 완료: $notificationId');
    } catch (e) {
      print('알림 읽음 처리 서버 전송 실패: $e');
    }
  }

  Future<void> markNotificationAsReadFromPush(int notificationId) async {
    if (_notifications != null) {
      await _markNotificationAsReadSafely(notificationId);
      notifyListeners();
    } else {
      _pendingReadNotifications.add(notificationId);
    }
  }

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
      await Future.wait(receivers.map((receiver) async {
        try {
          final model = {
            'uid': receiver,
            'title': title,
            'subTitle': subTitle,
            'routing': routing,
          };

          final res =
          await serverManager.post('notification/create', data: model);
          if (res.statusCode != 200) {
            failed.add(receiver);
          }
        } catch (e) {
          print('알림 전송 오류 (수신자: $receiver): $e');
          failed.add(receiver);
        }
      }));
    } catch (e) {
      print('알림 전송 중 오류 발생: $e');
    }

    return failed;
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final res =
      await serverManager.delete('notification/remove/$notificationId');

      if (res.statusCode == 200) {
        _notifications?.removeWhere((e) => e.notificationId == notificationId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('알림 삭제 오류: $e');
      return false;
    }
  }

  Future<bool> readNotification(int notificationId) async {
    final notificationIndex = _notifications
        ?.indexWhere((e) => e.notificationId == notificationId);

    if (notificationIndex == null || notificationIndex == -1) {
      return false;
    }

    if (_notifications![notificationIndex].isRead) {
      return true;
    }

    _notifications![notificationIndex].isRead = true;
    notifyListeners();

    try {
      final code = await serverManager.put('notification/read',
          data: {'notificationId': notificationId});

      if (code.statusCode != 200) {
        _notifications![notificationIndex].isRead = false;
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      print('알림 읽음 처리 오류: $e');
      _notifications![notificationIndex].isRead = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> initializeFCM() async {
    try {
      // 로컬 알림 먼저 초기화
      await _initializeLocalNotifications();

      // iOS 추가 권한 요청
      if (Platform.isIOS) {
        await _requestIOSPermissions();
      }

      // FCM 권한 요청
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        // 토큰 처리
        String? token = await _firebaseMessaging.getToken();
        if (token != null && token != _currentFcmToken) {
          _currentFcmToken = token;
          await _saveTokenToServer(token);
        }

        // 토큰 새로고침 리스너
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          if (newToken != _currentFcmToken) {
            _currentFcmToken = newToken;
            await _saveTokenToServer(newToken);
          }
        });

        // 포그라운드 메시지 처리
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('포그라운드 메시지 수신: ${message.messageId}');
          _updateBadgeFromMessage(message);

          if (_shouldShowNotification(message.data)) {
            if (message.notification != null) {
              _showLocalNotification({
                'title': message.notification!.title,
                'body': message.notification!.body,
                'roomId': message.data['roomId'],
                'scheduleId': message.data['scheduleId'],
                'notificationId': message.data['notificationId'],
                'badge': message.data['badge'] ?? '0',
                'alarm': message.data['alarm'] ?? '1',
                'type': message.data['type'] ?? 'default',
                'routing': message.data['routing'],
              });
            } else if (message.data.isNotEmpty) {
              _showLocalNotification(message.data);
            }
          }
        });

        // 백그라운드에서 앱 열기
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('백그라운드 메시지 클릭: ${message.messageId}');
          _handleNotificationTapWithRefresh(message.data);
        });

        // 백그라운드 메시지 핸들러 등록
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // 앱이 종료된 상태에서 알림으로 실행
        RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          print('종료 상태 메시지 처리: ${initialMessage.messageId}');
          _handleNotificationTapWithRefresh(initialMessage.data);
        }
      } else {
        print('알림 권한 거부됨: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('FCM 초기화 오류: $e');
    }
  }

  void _updateBadgeFromMessage(RemoteMessage message) {
    try {
      final badgeStr = message.data['badge'] as String?;
      if (badgeStr != null) {
        final badgeCount = int.tryParse(badgeStr) ?? 0;
        AppBadgePlus.updateBadge(badgeCount);
        print('FCM 메시지로부터 배지 업데이트: $badgeCount');
      }
    } catch (e) {
      print('FCM 배지 업데이트 오류: $e');
    }
  }

  bool _shouldShowNotification(Map<String, dynamic> data) {
    if (AppRoute.context == null) return true;

    try {
      final router = GoRouter.of(AppRoute.context!);
      final state = router.state;

      final currentUri = state.uri.toString();
      final routing = data['routing'] as String?;

      if (routing == null || currentUri.isEmpty) return true;

      if (routing.contains('/room/')) {
        return _shouldShowRoomNotification(currentUri, routing, data);
      }

      if (routing.contains('/schedule/')) {
        return _shouldShowScheduleNotification(currentUri, routing, data);
      }

      return !currentUri.contains(routing);
    } catch (e) {
      print('알림 표시 여부 판단 오류: $e');
      return true;
    }
  }

  bool _shouldShowRoomNotification(
      String currentUri, String routing, Map<String, dynamic> data) {
    try {
      if (!currentUri.contains('/room/')) return true;

      final routingRoomIdMatch = RegExp(r'/room/(\d+)').firstMatch(routing);
      final currentRoomIdMatch = RegExp(r'/room/(\d+)').firstMatch(currentUri);

      if (routingRoomIdMatch == null || currentRoomIdMatch == null) return true;

      final routingRoomId = routingRoomIdMatch.group(1);
      final currentRoomId = currentRoomIdMatch.group(1);

      if (routingRoomId == currentRoomId) {
        print('현재 채팅방($currentRoomId)과 알림 채팅방($routingRoomId)이 같아서 알림 숨김');
        return false;
      }

      return true;
    } catch (e) {
      print('채팅방 알림 판단 오류: $e');
      return true;
    }
  }

  bool _shouldShowScheduleNotification(
      String currentUri, String routing, Map<String, dynamic> data) {
    try {
      if (!currentUri.contains('/schedule/')) return true;

      final routingScheduleIdMatch =
      RegExp(r'/schedule/(\d+)').firstMatch(routing);
      final currentScheduleIdMatch =
      RegExp(r'/schedule/(\d+)').firstMatch(currentUri);

      if (routingScheduleIdMatch == null || currentScheduleIdMatch == null) {
        return true;
      }

      final routingScheduleId = routingScheduleIdMatch.group(1);
      final currentScheduleId = currentScheduleIdMatch.group(1);

      if (routingScheduleId == currentScheduleId) {
        print('현재 스케줄($currentScheduleId)과 알림 스케줄($routingScheduleId)이 같아서 알림 숨김');
        return false;
      }

      return true;
    } catch (e) {
      print('스케줄 알림 판단 오류: $e');
      return true;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings(_androidNotiIcon);

      DarwinInitializationSettings iosInitializationSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: true,
        requestBadgePermission: true,
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            'nadal_notification',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                'open',
                '열기',
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
          ),
        ],
      );

      InitializationSettings initializationSettings =
      InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            try {
              final data = jsonDecode(response.payload!);
              _handleNotificationTap(data);
            } catch (e) {
              print('알림 응답 처리 오류: $e');
            }
          }
        },
        onDidReceiveBackgroundNotificationResponse:
        notificationTapBackgroundHandler,
      );

      // Android 알림 채널 생성
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      await _requestIOSPermissions();
    } catch (e) {
      print('로컬 알림 초기화 오류: $e');
    }
  }

  // Android 알림 채널 생성
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestIOSPermissions() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: false,
      );
    }
  }

  Future<void> _saveTokenToServer(String token) async {
    try {
      await serverManager
          .post('notification/fcmToken', data: {'fcmToken': token});
      print('FCM 토큰 서버에 저장 성공');
    } catch (e) {
      print('FCM 토큰 서버 저장 오류: $e');
    }
  }

  Future<void> _showLocalNotification(Map<String, dynamic> data) async {
    try {
      final String title = data['title'] ?? '알림';
      final String body = data['body'] ?? '';
      final String groupKey = data['roomId'] ?? data['scheduleId'] ?? 'default';
      final int badge = int.tryParse(data['badge'] ?? '0') ?? 0;
      final bool alarm = data['alarm'] == '0' ? false : true;

      final AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        groupKey: groupKey,
        setAsGroupSummary: false,
        showWhen: alarm,
        number: badge,
        playSound: alarm,
        enableVibration: alarm,
        icon: _androidNotiIcon,
        color: const Color(0xFF00C4B4),
        autoCancel: true,
        showProgress: false,
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: alarm,
        presentAlert: alarm,
        presentBadge: alarm,
        badgeNumber: badge > 0 ? badge : null,
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: 'nadal_notification',
        threadIdentifier: groupKey,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        groupKey.hashCode,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );

      // 배지 업데이트
      if (badge > 0) {
        await Future.delayed(Duration(milliseconds: 100));
        await AppBadgePlus.updateBadge(badge);
      }
    } catch (e) {
      print('로컬 알림 표시 오류: $e');
    }
  }

  void _handleNotificationTapWithRefresh(Map<String, dynamic> data) async {
    if (AppRoute.context == null) return;

    try {
      final notificationIdStr = data['notificationId'] as String?;
      if (notificationIdStr != null) {
        final notificationId = int.tryParse(notificationIdStr);
        if (notificationId != null) {
          await markNotificationAsReadFromPush(notificationId);
        }
      }

      if (data['routing'] != null) {
        final routing = data['routing'] as String;

        if (routing.contains('/room/')) {
          final roomIdMatch = RegExp(r'/room/(\d+)').firstMatch(routing);
          if (roomIdMatch != null) {
            final roomId = int.parse(roomIdMatch.group(1)!);
            await _refreshRoomDataSafely(roomId);
          }
        } else if (routing.contains('/schedule/')) {
          final scheduleIdMatch =
          RegExp(r'/schedule/(\d+)').firstMatch(routing);
          if (scheduleIdMatch != null) {
            final scheduleId = int.parse(scheduleIdMatch.group(1)!);
            await _refreshScheduleDataSafely(scheduleId);
          }
        }

        await _navigateToRoute(routing);
      }
    } catch (e) {
      print('알림 라우팅 오류: $e');
    }
  }

  Future<void> _navigateToRoute(String routing) async {
    try {
      final context = AppRoute.context;
      if (context?.mounted != true) return;

      final router = GoRouter.of(context!);
      final currentUri = router.state.uri.toString();

      if (currentUri != routing) {
        router.go('/my');
        await Future.delayed(Duration(milliseconds: 100));
        router.push(routing);
      }
    } catch (e) {
      print('라우팅 처리 오류: $e');
    }
  }

  Future<void> _refreshRoomDataSafely(int roomId) async {
    try {
      final context = AppRoute.context;
      if (context?.mounted != true) return;

      final chatProvider = context!.read<ChatProvider>();
      final roomsProvider = context.read<RoomsProvider>();

      // 방 정보 업데이트
      await roomsProvider.updateRoom(roomId);

      // 채팅 데이터 새로고침
      if (!chatProvider.isJoined(roomId)) {
        await chatProvider.joinRoom(roomId);
      } else {
        await chatProvider.refreshRoomData(roomId);
      }

      print('✅ 방 데이터 새로고침 완료: $roomId');
    } catch (e) {
      print('❌ 방 데이터 새로고침 오류 (roomId: $roomId): $e');
    }
  }

  Future<void> _refreshScheduleDataSafely(int scheduleId) async {
    try {
      print('📅 스케줄 데이터 새로고침: $scheduleId');
      // 스케줄 관련 새로고침 로직 필요시 구현
    } catch (e) {
      print('❌ 스케줄 데이터 새로고침 오류 (scheduleId: $scheduleId): $e');
    }
  }
}

void _handleNotificationTap(Map<String, dynamic> data) {
  final context = AppRoute.context;
  if (context?.mounted != true) return;

  try {
    final notificationIdStr = data['notificationId'] as String?;
    if (notificationIdStr != null) {
      final notificationId = int.tryParse(notificationIdStr);
      if (notificationId != null) {
        final notificationProvider = context!.read<NotificationProvider>();
        notificationProvider.markNotificationAsReadFromPush(notificationId);
      }
    }

    if (data['routing'] != null) {
      final router = GoRouter.of(context!);
      final routing = data['routing'] as String;
      final currentUri = router.state.uri.toString();

      if (currentUri != routing) {
        router.go('/my');
        router.push(routing);
      }
    }
  } catch (e) {
    print('알림 탭 처리 오류: $e');
  }
}