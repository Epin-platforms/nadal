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

// 알림 상수
class NotificationConstants {
  static const String channelId = 'epin.nadal.chat.channel';
  static const String channelName = 'Nadal_Chat_ver1.0.0';
  static const String channelDesc = '나스달 알림';
  static const String androidIcon = '@drawable/android_noti_icon';
}

// 글로벌 로컬 알림 플러그인
final FlutterLocalNotificationsPlugin _localNotifications =
FlutterLocalNotificationsPlugin();

// 🔥 백그라운드 메시지 핸들러 (최상위 함수)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 백그라운드 메시지: ${message.messageId}');

  // 배지 업데이트
  await _updateBadge(message.data);

  // 백그라운드에서는 항상 알림 표시
  await _showBackgroundNotification(message.data);
}

// 🔥 백그라운드 알림 표시
Future<void> _showBackgroundNotification(Map<String, dynamic> data) async {
  try {
    const androidDetails = AndroidNotificationDetails(
      NotificationConstants.channelId,
      NotificationConstants.channelName,
      channelDescription: NotificationConstants.channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: NotificationConstants.androidIcon,
      color: Color(0xFF00C4B4),
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

    debugPrint('✅ 백그라운드 알림 표시 완료');
  } catch (e) {
    debugPrint('❌ 백그라운드 알림 오류: $e');
  }
}

// 🔥 배지 업데이트
Future<void> _updateBadge(Map<String, dynamic> data) async {
  final badgeStr = data['badge'] as String?;
  if (badgeStr?.isNotEmpty == true) {
    final count = int.tryParse(badgeStr!) ?? 0;
    try {
      await AppBadgePlus.updateBadge(count);
      debugPrint('배지 업데이트: $count');
    } catch (e) {
      debugPrint('배지 업데이트 오류: $e');
    }
  }
}

// 🔥 백그라운드 알림 터치 핸들러
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  if (response.payload?.isNotEmpty == true) {
    try {
      final data = jsonDecode(response.payload!);
      _handleNotificationTap(data);
    } catch (e) {
      debugPrint('백그라운드 알림 터치 오류: $e');
    }
  }
}

// 🔥 알림 터치 처리
void _handleNotificationTap(Map<String, dynamic> data) {
  final context = AppRoute.context;
  if (context?.mounted != true) return;

  try {
    debugPrint('🔔 알림 터치: ${data['routing']}');

    // 알림 읽음 처리
    final notificationIdStr = data['notificationId'] as String?;
    if (notificationIdStr != null) {
      final id = int.tryParse(notificationIdStr);
      if (id != null && context!.mounted) {
        final provider = context.read<NotificationProvider>();
        provider.markNotificationAsReadFromPush(id);
      }
    }

    // 라우팅 처리
    final routing = data['routing'] as String?;
    if (routing?.isNotEmpty == true && context!.mounted) {
      Future.microtask(() => _navigateToRoute(context, routing!));
    }
  } catch (e) {
    debugPrint('알림 터치 처리 오류: $e');
  }
}

// 🔥 라우팅 처리
Future<void> _navigateToRoute(BuildContext context, String routing) async {
  try {
    if (!context.mounted) return;

    final router = GoRouter.of(context);
    final current = router.state.uri.toString();

    if (current == routing) return;

    // 홈으로 이동 후 타겟 라우팅
    router.go('/my');
    await Future.delayed(Duration(milliseconds: 200));

    if (context.mounted) {
      router.push(routing);
      debugPrint('✅ 라우팅 완료: $routing');
    }
  } catch (e) {
    debugPrint('라우팅 오류: $e');
  }
}

// 🔥 메인 알림 프로바이더
class NotificationProvider extends ChangeNotifier {
  // 상태 변수
  List<NotificationModel>? _notifications;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _fcmToken;

  // 대기열
  final Set<int> _pendingReadIds = <int>{};

  // Firebase 인스턴스
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Getters
  List<NotificationModel>? get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // 🔥 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 알림 시스템 초기화 시작');

      await _initializeLocalNotifications();
      await _initializeFCM();
      await fetchNotifications();

      _isInitialized = true;
      debugPrint('✅ 알림 시스템 초기화 완료');
    } catch (e) {
      debugPrint('❌ 알림 초기화 오류: $e');
      _isInitialized = true; // 에러가 있어도 계속 진행
    }
  }

  // 🔥 로컬 알림 초기화
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
        onDidReceiveNotificationResponse: (response) {
          if (response.payload?.isNotEmpty == true) {
            final data = jsonDecode(response.payload!);
            _handleNotificationTap(data);
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler,
      );

      // Android 알림 채널 생성
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      // iOS 권한 요청
      if (Platform.isIOS) {
        await _requestIOSPermissions();
      }

      debugPrint('✅ 로컬 알림 초기화 완료');
    } catch (e) {
      debugPrint('❌ 로컬 알림 초기화 오류: $e');
    }
  }

  // 🔥 Android 알림 채널 생성
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      NotificationConstants.channelId,
      NotificationConstants.channelName,
      description: NotificationConstants.channelDesc,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 🔥 iOS 권한 요청
  Future<void> _requestIOSPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // 🔥 FCM 초기화
  Future<void> _initializeFCM() async {
    try {
      // 권한 요청
      final settings = await _messaging.requestPermission(
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

      // 토큰 관리
      await _setupFCMToken();

      // 메시지 리스너 설정
      _setupMessageListeners();

      // 백그라운드 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      debugPrint('✅ FCM 초기화 완료');
    } catch (e) {
      debugPrint('❌ FCM 초기화 오류: $e');
    }
  }

  // 🔥 FCM 토큰 설정
  Future<void> _setupFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token != _fcmToken) {
        _fcmToken = token;
        await _saveTokenToServer(token);
      }

      // 토큰 새로고침 리스너
      _messaging.onTokenRefresh.listen((newToken) async {
        if (newToken != _fcmToken) {
          _fcmToken = newToken;
          await _saveTokenToServer(newToken);
        }
      });
    } catch (e) {
      debugPrint('FCM 토큰 설정 오류: $e');
    }
  }

  // 🔥 메시지 리스너 설정
  void _setupMessageListeners() {
    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📱 포그라운드 메시지: ${message.messageId}');

      _updateBadge(message.data);

      // 현재 화면에 따라 알림 표시 여부 결정
      if (_shouldShowNotification(message.data)) {
        _showLocalNotification(message.data);
      }
    });
  }

  // 🔥 알림 표시 여부 판단
  bool _shouldShowNotification(Map<String, dynamic> data) {
    final context = AppRoute.context;
    if (context == null) return true;

    try {
      final router = GoRouter.of(context);
      final currentUri = router.state.uri.toString();
      final routing = data['routing'] as String?;

      if (routing == null || routing.isEmpty) return true;

      // 채팅방 알림 체크
      if (routing.contains('/room/') && currentUri.contains('/room/')) {
        final routingRoomId = _extractId(routing, r'/room/(\d+)');
        final currentRoomId = _extractId(currentUri, r'/room/(\d+)');

        if (routingRoomId == currentRoomId) {
          debugPrint('같은 채팅방이므로 알림 숨김: $routingRoomId');
          return false;
        }
      }

      // 스케줄 알림 체크
      if (routing.contains('/schedule/') && currentUri.contains('/schedule/')) {
        final routingScheduleId = _extractId(routing, r'/schedule/(\d+)');
        final currentScheduleId = _extractId(currentUri, r'/schedule/(\d+)');

        if (routingScheduleId == currentScheduleId) {
          debugPrint('같은 스케줄이므로 알림 숨김: $routingScheduleId');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('알림 표시 여부 판단 오류: $e');
      return true;
    }
  }

  // 🔥 ID 추출 헬퍼
  String? _extractId(String path, String pattern) {
    final match = RegExp(pattern).firstMatch(path);
    return match?.group(1);
  }

  // 🔥 로컬 알림 표시
  Future<void> _showLocalNotification(Map<String, dynamic> data) async {
    try {
      final title = data['title'] ?? '알림';
      final body = data['body'] ?? '';
      final groupKey = data['roomId'] ?? data['scheduleId'] ?? 'default';
      final badge = int.tryParse(data['badge'] ?? '0') ?? 0;
      final alarm = data['alarm'] != '0';

      final androidDetails = AndroidNotificationDetails(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        channelDescription: NotificationConstants.channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        groupKey: groupKey,
        number: badge,
        playSound: alarm,
        enableVibration: alarm,
        icon: NotificationConstants.androidIcon,
        color: const Color(0xFF00C4B4),
        autoCancel: true,
      );

      final iosDetails = DarwinNotificationDetails(
        presentSound: alarm,
        presentAlert: alarm,
        presentBadge: alarm,
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

  // 🔥 서버에 토큰 저장
  Future<void> _saveTokenToServer(String token) async {
    try {
      await serverManager.post('notification/fcmToken', data: {'fcmToken': token});
      debugPrint('✅ FCM 토큰 저장 완료');
    } catch (e) {
      debugPrint('❌ FCM 토큰 저장 오류: $e');
    }
  }

  // 🔥 알림 목록 가져오기
  Future<void> fetchNotifications() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      final res = await serverManager.get('notification');

      if (res.statusCode == 200) {
        final List<dynamic> data = List.from(res.data);
        _notifications = data.map((e) => NotificationModel.fromJson(json: e)).toList();

        await _processPendingReads();
      }
    } catch (e) {
      debugPrint('알림 가져오기 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔥 대기 중인 읽음 처리
  Future<void> _processPendingReads() async {
    if (_pendingReadIds.isEmpty) return;

    final pendingIds = List<int>.from(_pendingReadIds);
    _pendingReadIds.clear();

    for (final id in pendingIds) {
      await _markAsReadSafely(id);
    }
  }

  // 🔥 알림 읽음 처리 (Push에서 호출)
  Future<void> markNotificationAsReadFromPush(int notificationId) async {
    if (_notifications != null) {
      await _markAsReadSafely(notificationId);
      notifyListeners();
    } else {
      _pendingReadIds.add(notificationId);
    }
  }

  // 🔥 안전한 읽음 처리
  Future<void> _markAsReadSafely(int notificationId) async {
    if (_notifications == null) return;

    final index = _notifications!.indexWhere((e) => e.notificationId == notificationId);
    if (index != -1 && !_notifications![index].isRead) {
      _notifications![index].isRead = true;
      _sendReadToServer(notificationId);
    }
  }

  // 🔥 서버에 읽음 상태 전송
  void _sendReadToServer(int notificationId) async {
    try {
      await serverManager.put('notification/read', data: {'notificationId': notificationId});
      debugPrint('✅ 알림 읽음 처리 완료: $notificationId');
    } catch (e) {
      debugPrint('❌ 알림 읽음 처리 오류: $e');
    }
  }

  // 🔥 알림 읽음 처리 (UI에서 호출)
  Future<bool> readNotification(int notificationId) async {
    final index = _notifications?.indexWhere((e) => e.notificationId == notificationId);

    if (index == null || index == -1) return false;
    if (_notifications![index].isRead) return true;

    _notifications![index].isRead = true;
    notifyListeners();

    try {
      final res = await serverManager.put('notification/read', data: {'notificationId': notificationId});

      if (res.statusCode != 200) {
        _notifications![index].isRead = false;
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('알림 읽음 처리 오류: $e');
      _notifications![index].isRead = false;
      notifyListeners();
      return false;
    }
  }

  // 🔥 알림 삭제
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
      debugPrint('알림 삭제 오류: $e');
      return false;
    }
  }

  // 🔥 알림 전송
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

          final res = await serverManager.post('notification/create', data: model);
          if (res.statusCode != 200) {
            failed.add(receiver);
          }
        } catch (e) {
          debugPrint('알림 전송 오류 (수신자: $receiver): $e');
          failed.add(receiver);
        }
      }));
    } catch (e) {
      debugPrint('알림 전송 중 오류: $e');
    }

    return failed;
  }
}