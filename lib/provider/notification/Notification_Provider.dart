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
  // 백그라운드에서 필요한 초기화 작업이 있다면 여기서 수행
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

// 특정 채팅방 알림 제거
void removeNotificationForRoom(String roomId) async {
  try {
    int notificationId = roomId.hashCode;
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  } catch (e) {
    print('알림 제거 오류: $e');
  }
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel>? _notifications;
  List<NotificationModel>? get notifications => _notifications;

  int _offset = 0;
  bool _hasMore = true; // 초기값은 true로 설정 (더 불러올 데이터가 있다고 가정)
  bool get hasMore => _hasMore;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 생성자는 간단하게 유지
  NotificationProvider();

  // 초기화 메서드 - 외부에서 명시적으로 호출해야 함
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

  // 알림 목록 가져오기
  Future<void> fetchNotifications() async {
    if (_isLoading || !_hasMore) return;

    try {
      _isLoading = true;

      // 첫 로드가 아닌 경우에만 상태 업데이트
      if (_notifications != null) notifyListeners();

      final res = await serverManager.get('notification?offset=$_offset');

      // 첫 로드인 경우 목록 초기화
      _notifications ??= [];

      if (res.statusCode == 200) {
        final List<dynamic> newNotifications = List.from(res.data);
        // 새 알림을 목록에 추가
        _notifications!.addAll(
            newNotifications.map((e) => NotificationModel.fromJson(json: e))
        );

        // 페이지네이션 처리
        if (newNotifications.length < 20) {
          _hasMore = false; // 더 이상 불러올 데이터가 없음
        } else {
          _offset++; // 다음 페이지를 위해 오프셋 증가
        }
        notifyListeners();
      } else {
        // 오류 처리
        print('알림 데이터 가져오기 실패: ${res.statusCode}');
      }
    } catch (e) {
      print('알림 가져오기 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 알림 보내기
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

  // 알림 삭제
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

  // 알림 읽음 처리
  Future<bool> readNotification(int notificationId) async {
    // 이미 읽은 알림이면 API 호출 안함
    final notificationIndex = _notifications?.indexWhere(
            (e) => e.notificationId == notificationId
    );

    if (notificationIndex == null || notificationIndex == -1) {
      return false;
    }

    if (_notifications![notificationIndex].isRead) {
      return true; // 이미 읽은 알림
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

  // 모든 알림을 읽음으로 표시
  Future<bool> markAllAsRead() async {
    if (_notifications == null || _notifications!.isEmpty) {
      return true;
    }

    try {
      // 읽지 않은 알림만 필터링
      final unreadNotifications = _notifications!
          .where((notification) => !notification.isRead)
          .toList();

      if (unreadNotifications.isEmpty) {
        return true;
      }

      // 서버에 일괄 읽음 처리 요청 (API가 있다고 가정)
      final res = await serverManager.put(
          'notification/read-all',
          data: {}
      );

      if (res.statusCode == 200) {
        // 모든 알림을 읽음으로 표시
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
      // 로컬 알림 초기화
      await _initializeLocalNotifications();

      // FCM 권한 요청
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('알림 권한 승인됨');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('알림 권한 임시 승인됨');
      } else {
        print('알림 권한 거부됨');
        return; // 권한이 없으면 더 이상 진행하지 않음
      }

      // FCM 토큰 가져오기
      String? token = await _firebaseMessaging.getToken();
      if (token != null && token != _currentFcmToken) {
        _currentFcmToken = token;
        await _saveTokenToServer(token);
      }

      // 토큰 갱신 리스너
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        if (newToken != _currentFcmToken) {
          _currentFcmToken = newToken;
          await _saveTokenToServer(newToken);
        }
      });

      // 포그라운드 메시지 핸들러
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('포그라운드 메시지 수신: ${message.messageId}');
        if (message.notification != null) {
          // Firebase에서 제공하는 notification 객체 사용
          _showLocalNotification({
            'title': message.notification!.title,
            'body': message.notification!.body,
            'roomId': message.data['roomId'],
            'badge': message.data['badge'] ?? '0',
            'alarm': message.data['alarm'] ?? '1',
            'type': message.data['type'] ?? 'default',
            'routing': message.data['routing'],
          });
        } else if (message.data.isNotEmpty) {
          // 데이터 메시지만 있는 경우
          _showLocalNotification(message.data);
        }
      });

      // 백그라운드 메시지 클릭 리스너
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('백그라운드 메시지 클릭: ${message.messageId}');
        Future.microtask(() {
          _handleNotificationTap(message.data);
        });
      });

      // 백그라운드 메시지 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 종료 상태에서 앱이 시작된 경우 (앱이 완전히 종료된 상태에서 알림 클릭으로 열린 경우)
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('종료 상태 메시지 처리: ${initialMessage.messageId}');
        Future.microtask(() {
          _handleNotificationTap(initialMessage.data);
        });
      }
    } catch (e) {
      print('FCM 초기화 오류: $e');
    }
  }

  // 로컬 알림 초기화
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

      // iOS 권한 요청 (필요한 경우)
      await _requestIOSPermissions();
    } catch (e) {
      print('로컬 알림 초기화 오류: $e');
    }
  }

  // iOS 권한 요청 (Flutter Local Notifications)
  Future<void> _requestIOSPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // 서버에 FCM 토큰 저장
  Future<void> _saveTokenToServer(String token) async {
    try {
      await serverManager.post('notification/fcmToken', data: {'fcmToken': token});
      print('FCM 토큰 서버에 저장 성공');
    } catch (e) {
      print('FCM 토큰 서버 저장 오류: $e');
    }
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification(Map<String, dynamic> data) async {
    try {
      final String title = data['title'] ?? '알림';
      final String body = data['body'] ?? '';
      final String groupKey = data['roomId'] ?? data['scheduleId'] ?? 'default';
      final int badge = int.tryParse(data['badge'] ?? '0') ?? 0;
      final bool alarm = data['alarm'] == '0' ? false : true;

      // Android 알림 세부 설정
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
        // 추가 사용자 정의
        icon: _androidNotiIcon,
        color: const Color(0xFF00C4B4), // primaryColor
      );

      // iOS 알림 세부 설정
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: alarm,
        presentAlert: alarm,
        presentBadge: true,
        badgeNumber: badge,
        // 추가 사용자 정의
        interruptionLevel: InterruptionLevel.active,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        groupKey.hashCode, // 고유 ID
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );
    } catch (e) {
      print('로컬 알림 표시 오류: $e');
    }
  }
}

// 알림 클릭 핸들러
void _handleNotificationTap(Map<String, dynamic> data) {
  if (AppRoute.context != null) {
    if (data['routing'] != null) {
      try {
        final router = GoRouter.of(AppRoute.context!);
        router.go('/my'); // 홈으로 먼저 이동
        router.push(data['routing']); // 그 다음 지정된 라우트로 이동
      } catch (e) {
        print('알림 라우팅 오류: $e');
      }
    }
  }
}