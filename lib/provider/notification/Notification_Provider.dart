import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_sports_calendar/manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/app/Notifications_Model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 알림 채널 ID와 이름을 상수로 정의
const String _channelId = 'epin.nadal.chat.channel';
const String _channelName = 'Nadal_Chat_ver1.0.0';
const String _channelDesc = '나달 알림';
const String _androidNotiIcon = '@drawable/android_noti_icon';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('백그라운드 메시지 수신: ${message.messageId}');
}

// 알림 클릭 백그라운드 핸들러
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

  int _offset = 0;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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
    if (_isLoading || !_hasMore) return;

    try {
      _isLoading = true;

      if (_notifications != null) notifyListeners();

      final res = await serverManager.get('notification?offset=$_offset');

      _notifications ??= [];

      if (res.statusCode == 200) {
        final List<dynamic> newNotifications = List.from(res.data);
        _notifications!.addAll(
            newNotifications.map((e) => NotificationModel.fromJson(json: e))
        );

        if (newNotifications.length < 20) {
          _hasMore = false;
        } else {
          _offset++;
        }
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
      await Future.wait(
          receivers.map((receiver) async {
            try {
              final model = {
                'uid': receiver,
                'title': title,
                'subTitle': subTitle,
                'routing': routing,
              };

              final res = await serverManager.post('notification/create', data: model);
              if (res.statusCode != 200) {
                failed.add(receiver);
              }
            } catch (e) {
              print('알림 전송 오류 (수신자: $receiver): $e');
              failed.add(receiver);
            }
          })
      );
    } catch (e) {
      print('알림 전송 중 오류 발생: $e');
    }

    return failed;
  }

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
      print('알림 삭제 오류: $e');
      return false;
    }
  }

  Future<bool> readNotification(int notificationId) async {
    final notificationIndex = _notifications?.indexWhere(
            (e) => e.notificationId == notificationId
    );

    if (notificationIndex == null || notificationIndex == -1) {
      return false;
    }

    if (_notifications![notificationIndex].isRead) {
      return true;
    }

    try {
      final code = await serverManager.put(
          'notification/read',
          data: {'notificationId': notificationId}
      );

      if (code.statusCode == 200) {
        _notifications![notificationIndex].isRead = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('알림 읽음 처리 오류: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    if (_notifications == null || _notifications!.isEmpty) {
      return true;
    }

    try {
      final unreadNotifications = _notifications!
          .where((notification) => !notification.isRead)
          .toList();

      if (unreadNotifications.isEmpty) {
        return true;
      }

      final res = await serverManager.put(
          'notification/read-all',
          data: {}
      );

      if (res.statusCode == 200) {
        for (var notification in _notifications!) {
          notification.isRead = true;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('모든 알림 읽음 처리 오류: $e');
      return false;
    }
  }

  // FCM 관련 코드
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _currentFcmToken;

  Future<void> initializeFCM() async {
    try {
      await _initializeLocalNotifications();

      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        String? token = await _firebaseMessaging.getToken();
        if (token != null && token != _currentFcmToken) {
          _currentFcmToken = token;
          await _saveTokenToServer(token);
        }

        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          if (newToken != _currentFcmToken) {
            _currentFcmToken = newToken;
            await _saveTokenToServer(newToken);
          }
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('포그라운드 메시지 수신: ${message.messageId}');

          // 현재 페이지가 알림 관련된 페이지인지 확인
          if (_shouldShowNotification(message.data)) {
            if (message.notification != null) {
              _showLocalNotification({
                'title': message.notification!.title,
                'body': message.notification!.body,
                'roomId': message.data['roomId'],
                'scheduleId': message.data['scheduleId'],
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

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('백그라운드 메시지 클릭: ${message.messageId}');
          _handleNotificationTapWithRefresh(message.data);
        });

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          print('종료 상태 메시지 처리: ${initialMessage.messageId}');
          _handleNotificationTapWithRefresh(initialMessage.data);
        }
      } else {
        print('알림 권한 거부됨');
      }
    } catch (e) {
      print('FCM 초기화 오류: $e');
    }
  }

  // 개선된 알림 표시 여부 판단 로직
  bool _shouldShowNotification(Map<String, dynamic> data) {
    if (AppRoute.context == null) return true;

    try {
      final router = GoRouter.of(AppRoute.context!);
      final state = router.state;

      // 현재 라우트의 실제 URI 가져오기
      final currentUri = state.uri.toString();
      final routing = data['routing'] as String?;

      if (routing == null || currentUri.isEmpty) return true;

      // 채팅방 알림인 경우 상세 확인
      if (routing.contains('/room/')) {
        return _shouldShowRoomNotification(currentUri, routing, data);
      }

      // 스케줄 알림인 경우 상세 확인
      if (routing.contains('/schedule/')) {
        return _shouldShowScheduleNotification(currentUri, routing, data);
      }

      // 기타 알림의 경우 정확히 같은 페이지인지 확인
      return !currentUri.contains(routing);

    } catch (e) {
      print('알림 표시 여부 판단 오류: $e');
      return true; // 에러 시에는 알림을 표시
    }
  }

  // 채팅방 알림 표시 여부 판단
  bool _shouldShowRoomNotification(String currentUri, String routing, Map<String, dynamic> data) {
    try {
      // 현재 채팅방 페이지에 있지 않으면 알림 표시
      if (!currentUri.contains('/room/')) return true;

      // 라우팅에서 roomId 추출
      final routingRoomIdMatch = RegExp(r'/room/(\d+)').firstMatch(routing);
      final currentRoomIdMatch = RegExp(r'/room/(\d+)').firstMatch(currentUri);

      if (routingRoomIdMatch == null || currentRoomIdMatch == null) return true;

      final routingRoomId = routingRoomIdMatch.group(1);
      final currentRoomId = currentRoomIdMatch.group(1);

      // 같은 채팅방이면 알림을 표시하지 않음
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

  // 스케줄 알림 표시 여부 판단
  bool _shouldShowScheduleNotification(String currentUri, String routing, Map<String, dynamic> data) {
    try {
      // 현재 스케줄 페이지에 있지 않으면 알림 표시
      if (!currentUri.contains('/schedule/')) return true;

      // 라우팅에서 scheduleId 추출
      final routingScheduleIdMatch = RegExp(r'/schedule/(\d+)').firstMatch(routing);
      final currentScheduleIdMatch = RegExp(r'/schedule/(\d+)').firstMatch(currentUri);

      if (routingScheduleIdMatch == null || currentScheduleIdMatch == null) return true;

      final routingScheduleId = routingScheduleIdMatch.group(1);
      final currentScheduleId = currentScheduleIdMatch.group(1);

      // 같은 스케줄이면 알림을 표시하지 않음
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

      const DarwinInitializationSettings iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: true,
        requestBadgePermission: true,
        notificationCategories: <DarwinNotificationCategory>[],
      );

      const InitializationSettings initializationSettings = InitializationSettings(
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
        onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler,
      );

      await _requestIOSPermissions();
    } catch (e) {
      print('로컬 알림 초기화 오류: $e');
    }
  }

  Future<void> _requestIOSPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _saveTokenToServer(String token) async {
    try {
      await serverManager.post('notification/fcmToken', data: {'fcmToken': token});
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

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: alarm,
        presentAlert: alarm,
        badgeNumber: badge,
        interruptionLevel: InterruptionLevel.active,
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
    } catch (e) {
      print('로컬 알림 표시 오류: $e');
    }
  }

  // 백그라운드에서 알림 클릭 시 데이터 새로고침
  void _handleNotificationTapWithRefresh(Map<String, dynamic> data) async {
    if (AppRoute.context != null) {
      if (data['routing'] != null) {
        try {
          final routing = data['routing'] as String;

          // 채팅방 알림인 경우
          if (routing.contains('/room/')) {
            final roomIdMatch = RegExp(r'/room/(\d+)').firstMatch(routing);
            if (roomIdMatch != null) {
              final roomId = int.parse(roomIdMatch.group(1)!);
              await _refreshRoomDataSafely(roomId);
            }
          }
          // 스케줄 알림인 경우
          else if (routing.contains('/schedule/')) {
            final scheduleIdMatch = RegExp(r'/schedule/(\d+)').firstMatch(routing);
            if (scheduleIdMatch != null) {
              final scheduleId = int.parse(scheduleIdMatch.group(1)!);
              await _refreshScheduleDataSafely(scheduleId);
            }
          }

          await _navigateToRoute(routing);

        } catch (e) {
          print('알림 라우팅 오류: $e');
        }
      }
    }
  }

  // 안전한 라우팅 처리
  Future<void> _navigateToRoute(String routing) async {
    try {
      final router = GoRouter.of(AppRoute.context!);

      // 현재 라우트와 다른 경우에만 네비게이션
      final currentUri = router.state.uri.toString();
      if (currentUri != routing) {
        router.go('/my');
        await Future.delayed(const Duration(milliseconds: 100));
        router.push(routing);
      }

    } catch (e) {
      print('라우팅 처리 오류: $e');
    }
  }

  // 안전한 방 데이터 새로고침
  Future<void> _refreshRoomDataSafely(int roomId) async {
    try {
      final chatProvider = AppRoute.context?.read<ChatProvider>();
      final roomsProvider = AppRoute.context?.read<RoomsProvider>();

      if (chatProvider != null && roomsProvider != null) {
        // 방 정보 업데이트
        await roomsProvider.updateRoom(roomId);

        // 채팅 데이터 새로고침
        if (!chatProvider.isJoined(roomId)) {
          await chatProvider.joinRoom(roomId);
        } else {
          await chatProvider.onReconnectChat(roomId);
          await chatProvider.setMyRoom(roomId);
        }
      }
    } catch (e) {
      print('방 데이터 새로고침 오류 (roomId: $roomId): $e');
    }
  }

  // 안전한 스케줄 데이터 새로고침
  Future<void> _refreshScheduleDataSafely(int scheduleId) async {
    try {
      // 필요시 스케줄 관련 프로바이더 새로고침 로직 추가
      print('스케줄 데이터 새로고침 (scheduleId: $scheduleId)');
    } catch (e) {
      print('스케줄 데이터 새로고침 오류 (scheduleId: $scheduleId): $e');
    }
  }
}

// 일반 알림 클릭 핸들러
void _handleNotificationTap(Map<String, dynamic> data) {
  if (AppRoute.context != null) {
    if (data['routing'] != null) {
      try {
        final router = GoRouter.of(AppRoute.context!);
        final routing = data['routing'] as String;

        // 현재 라우트와 다른 경우에만 네비게이션
        final currentUri = router.state.uri.toString();
        if (currentUri != routing) {
          router.go('/my');
          router.push(routing);
        }

      } catch (e) {
        print('알림 라우팅 오류: $e');
      }
    }
  }
}