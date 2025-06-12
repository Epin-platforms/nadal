import '../../manager/project/Import_Manager.dart';
import '../../provider/app/Advertisement_Provider.dart';
import '../../widget/Nadal_Room_Frame.dart';
import '../../widget/Nadal_Room_NotRead_Tag.dart';

class MyQuickChat extends StatefulWidget {
  const MyQuickChat({super.key, required this.homeProvider, required this.roomsProvider, required this.chatProvider});
  final HomeProvider homeProvider;
  final RoomsProvider roomsProvider;
  final ChatProvider chatProvider;
  @override
  State<MyQuickChat> createState() => _MyQuickChatState();
}

class _MyQuickChatState extends State<MyQuickChat> {
  late ScrollController _scrollController;
  static const String _pageKey = 'quick_chat_main';
  bool _isAdsInitialized = false;

  // 🔧 상태 관리 개선
  bool _hasCheckedInitialState = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  @override
  void initState() {
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _safeInitialize());
    super.initState();
  }

  /// 안전한 초기화 프로세스
  Future<void> _safeInitialize() async {
    try {
      if (!mounted) return;
      await _initializeAds();
      if (!mounted) return;
      _setupScrollListener();
      _checkInitialState(); // 🔧 초기 상태 확인 추가
    } catch (e) {
      print('MyQuickChat 초기화 오류: $e');
    }
  }

  // 🔧 초기 상태 확인
  void _checkInitialState() {
    if (!mounted) return;

    if (_isQuickRoomsDataReady(widget.roomsProvider.quickRooms, widget.chatProvider)) {
      setState(() => _hasCheckedInitialState = true);
    } else {
      _scheduleRetry();
    }
  }

  // 🔧 재시도 스케줄링
  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) {
      print('❌ 최대 재시도 횟수 초과 - 강제로 로딩 완료 처리');
      setState(() => _hasCheckedInitialState = true);
      return;
    }

    _retryTimer?.cancel();
    _retryCount++;

    final delay = Duration(milliseconds: 500 * _retryCount);
    print('🔄 ${delay.inMilliseconds}ms 후 퀵챗 데이터 준비 상태 재확인 ($_retryCount/$_maxRetries)');

    _retryTimer = Timer(delay, () {
      if (mounted) {
        _checkInitialState();
      }
    });
  }

  /// 광고 초기화 (에러 처리 강화)
  Future<void> _initializeAds() async {
    if (_isAdsInitialized || !mounted) return;

    try {
      final adProvider = context.read<AdvertisementProvider>();

      // 배너 광고 로드
      await adProvider.loadBannerAd('${_pageKey}_banner');

      // 네이티브 ListTile형 광고 로드 (순차적으로)
      for (int i = 0; i < 3; i++) {
        if (!mounted) break;
        await adProvider.loadNativeListTileAd('${_pageKey}_nativeListTile_$i');
      }

      _isAdsInitialized = true;
    } catch (e) {
      print('광고 초기화 오류: $e');
    }
  }

  /// 스크롤 리스너 설정 (안전성 강화)
  void _setupScrollListener() {
    if (!mounted) return;

    _scrollController.addListener(() {
      if (!mounted || !_scrollController.hasClients) return;

      try {
        final position = _scrollController.position;
        if (position.pixels >= position.maxScrollExtent - 200.h) {
          widget.homeProvider.fetchMyLocalQuickChatRooms();
        }
      } catch (e) {
        print('스크롤 리스너 오류: $e');
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _scrollController.dispose();
    AdManager.disposePageAds(_pageKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 상단 배너 광고
        if (_isAdsInitialized)
          SliverToBoxAdapter(
            child: SimpleBannerAdWidget(
              adKey: '${_pageKey}_banner',
              height: 50.h,
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
          ),

        // 참가중인 번개챗 섹션
        _buildParticipatingRoomsSection(),

        // 구분선
        SliverToBoxAdapter(child: Divider()),

        // 내 지역 번개챗 섹션 헤더
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
            child: Text(
              '내 지역 번개챗',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),

        // 내 지역 번개챗 리스트
        _buildLocalQuickChatSection(),
      ],
    );
  }

  /// 참가중인 번개챗 섹션 (안전성 강화)
  Widget _buildParticipatingRoomsSection() {
    final quickRooms = widget.roomsProvider.quickRooms;
    final chatProvider = widget.chatProvider;

    // 🔧 로딩 상태 확인 개선
    if (!_hasCheckedInitialState || !_isQuickRoomsDataReady(quickRooms, chatProvider)) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 150.h,
          child: Center(child: NadalCircular()),
        ),
      );
    }

    if (quickRooms == null || quickRooms.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300.h,
          child: NadalEmptyList(
            title: '아직 참가중인 번개챗이 없어요',
            subtitle: '번개챗은 누구나 빠르게 경기 전용 채팅방 운영할 수 있어요\n7일간 미활동 시 자동 삭제돼요',
            onAction: () => context.push('/createRoom?isOpen=TRUE'),
            actionText: '번개챗 만들기',
          ),
        ),
      );
    }

    final quickList = _getSafeQuickList();
    return SliverList.builder(
      itemCount: quickList.length,
      itemBuilder: (context, index) => _buildQuickRoomItem(quickList[index]),
    );
  }

  /// 안전한 QuickList 가져오기
  List<MapEntry<int, Map>> _getSafeQuickList() {
    try {
      return widget.roomsProvider.getQuickList(context);
    } catch (e) {
      print('QuickList 가져오기 오류: $e');
      final quickRooms = widget.roomsProvider.quickRooms;
      if (quickRooms != null) {
        return quickRooms.entries.toList();
      }
      return [];
    }
  }

  /// QuickRoom 아이템 빌드
  Widget _buildQuickRoomItem(MapEntry<int, Map> roomEntry) {
    final roomData = roomEntry.value;
    final roomId = roomData['roomId'] as int;

    final unread = _getUnreadCountSafely(roomId);
    final lastChatText = _getLastChatSafely(roomId);

    return ListTile(
      onTap: () => context.push('/room/$roomId'),
      leading: NadalRoomFrame(imageUrl: roomData['roomImage']),
      title: Row(
        children: [
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: roomData['roomName']?.toString() ?? '알 수 없는 방',
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  TextSpan(
                    text: '(${roomData['memberCount'] ?? 0})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      subtitle: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 24.h),
        child: Text(
          lastChatText,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
      trailing: _buildTrailing(roomId, unread),
    );
  }

  // 🔧 trailing 위젯 분리
  Widget? _buildTrailing(int roomId, int unread) {
    if (unread > 0) {
      return NadalRoomNotReadTag(number: unread);
    }

    // 재연결 중인 방 표시
    if (widget.chatProvider.socketLoading && !widget.chatProvider.isRoomDataReady(roomId)) {
      return SizedBox(
        width: 16.w,
        height: 16.h,
        child: CircularProgressIndicator(
          strokeWidth: 2.w,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return null;
  }

  /// 🔧 개선된 데이터 준비 상태 체크
  bool _isQuickRoomsDataReady(Map<int, Map>? quickRooms, ChatProvider chatProvider) {
    // 초기 상태 확인이 완료되지 않았으면 false
    if (!_hasCheckedInitialState) return false;

    // 기본 초기화 확인
    if (!chatProvider.isInitialized) {
      print('🔄 ChatProvider 초기화 중...');
      return false;
    }

    // quickRooms가 null이면 false
    if (quickRooms == null) {
      print('⚠️ quickRooms가 null');
      return false;
    }

    // quickRooms가 비어있으면 true (정상)
    if (quickRooms.isEmpty) {
      print('✅ quickRooms가 비어있음 (정상)');
      return true;
    }

    // 재연결 중이면서 기존 데이터가 있으면 true (UI 업데이트 방지)
    if (chatProvider.socketLoading && quickRooms.isNotEmpty) {
      print('🔄 재연결 중이지만 기존 데이터 사용');
      return true;
    }

    // 소켓 로딩 중이면 false
    if (chatProvider.socketLoading) {
      print('🔄 소켓 로딩 중...');
      return false;
    }

    // quickRooms의 데이터 준비 상태 확인
    final readyRooms = quickRooms.keys.where((roomId) {
      return chatProvider.isRoomDataReady(roomId);
    }).length;

    final totalRooms = quickRooms.length;
    final readyPercentage = readyRooms / totalRooms;

    print('📊 퀵챗 방 준비 상태: $readyRooms/$totalRooms (${(readyPercentage * 100).toInt()}%)');

    // 70% 이상 또는 최소 2개 방이 준비되면 OK
    if (readyPercentage >= 0.7 || (readyRooms >= 2 && totalRooms > 2)) {
      return true;
    }

    // 5초 이상 기다렸다면 강제로 완료 처리
    if (_retryCount >= 10) {
      print('⏰ 타임아웃 - 현재 상태로 진행');
      return true;
    }

    print('⚠️ 퀵챗 방 데이터가 충분히 준비되지 않음');
    return false;
  }

  /// 안전한 unread 카운트 가져오기
  int _getUnreadCountSafely(int roomId) {
    try {
      final myData = widget.chatProvider.my[roomId];
      return myData?['unreadCount'] as int? ?? 0;
    } catch (e) {
      print('getUnreadCount 오류 (roomId: $roomId): $e');
      return 0;
    }
  }

  /// 안전한 마지막 채팅 가져오기
  String _getLastChatSafely(int roomId) {
    try {
      final chats = widget.chatProvider.chat[roomId];
      if (chats == null || chats.isEmpty) {
        return '아직 채팅이 없어요';
      }
      return widget.chatProvider.getLastChat(roomId);
    } catch (e) {
      print('getLastChat 오류 (roomId: $roomId): $e');
      return '채팅을 불러오는 중...';
    }
  }

  /// 내 지역 번개챗 섹션 (경량화)
  Widget _buildLocalQuickChatSection() {
    final myLocalRooms = widget.homeProvider.myLocalQuickChatRooms;

    if (myLocalRooms == null) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300.h,
          child: Center(child: NadalCircular()),
        ),
      );
    }

    if (myLocalRooms.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300.h,
          child: NadalEmptyList(
            title: '아직 주변에 번개방이 없어요',
            subtitle: '번개방을 만들고 친구들과 게임을 진행해보세요',
            actionText: '방 만들기',
            onAction: () => context.push('/createRoom?isOpen=TRUE'),
          ),
        ),
      );
    }

    final totalItemCount = _calculateTotalItemCount(myLocalRooms.length);
    return SliverList.builder(
      itemCount: totalItemCount,
      itemBuilder: (context, index) => _buildLocalChatItem(context, index, myLocalRooms),
    );
  }

  /// 전체 아이템 개수 계산 (동일)
  int _calculateTotalItemCount(int originalCount) {
    if (originalCount <= 3) return originalCount;
    final adCount = (originalCount / 5).floor().clamp(0, 3);
    return originalCount + adCount;
  }

  /// 광고 위치 결정 (동일)
  bool _isAdPosition(int totalIndex, int originalCount) {
    if (originalCount <= 3) return false;

    final positions = <int>[];
    if (originalCount >= 4) positions.add(3);
    if (originalCount >= 8) positions.add(7);
    if (originalCount >= 12) positions.add(11);

    return positions.contains(totalIndex);
  }

  /// 실제 아이템 인덱스 계산 (동일)
  int _getActualItemIndex(int totalIndex, int originalCount) {
    if (originalCount <= 3) return totalIndex;

    int actualIndex = totalIndex;
    if (totalIndex > 3) actualIndex--;
    if (totalIndex > 7) actualIndex--;
    if (totalIndex > 11) actualIndex--;

    return actualIndex.clamp(0, originalCount - 1);
  }

  /// 광고 키 생성 (동일)
  String _getAdKey(int adPosition) {
    final adIndex = adPosition <= 3 ? 0 : adPosition <= 7 ? 1 : 2;
    return '${_pageKey}_nativeListTile_$adIndex';
  }

  /// 로컬 챗 아이템 빌드 (안전성 강화)
  Widget _buildLocalChatItem(BuildContext context, int index, List<dynamic> items) {
    final originalCount = items.length;

    // 광고 위치인지 확인
    if (_isAdPosition(index, originalCount) && _isAdsInitialized) {
      return NativeListTileAdWidget(
        adKey: _getAdKey(index),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
      );
    }

    // 실제 아이템 표시
    final actualIndex = _getActualItemIndex(index, originalCount);
    if (actualIndex >= items.length) {
      return SizedBox.shrink();
    }

    final item = items[actualIndex];
    if (item == null) {
      return SizedBox.shrink();
    }

    return ListTile(
      onTap: () {
        final roomId = item['roomId'];
        if (roomId != null) {
          context.push('/previewRoom/$roomId');
        }
      },
      leading: NadalRoomFrame(imageUrl: item['roomImage']),
      title: Text(
        item['roomName']?.toString() ?? '알 수 없는 방',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 36.h),
              child: Text(
                _getItemDescription(item),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Text(
              '${item['memberCount'] ?? 0}/200',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          )
        ],
      ),
    );
  }

  /// 아이템 설명 생성 (안전성 강화)
  String _getItemDescription(dynamic item) {
    if (item == null) return '정보없음';

    try {
      final description = item['description']?.toString() ?? '';
      final tag = item['tag']?.toString() ?? '';

      if (description.isNotEmpty) {
        return description;
      } else if (tag.isNotEmpty) {
        return tag;
      } else {
        return '정보없음';
      }
    } catch (e) {
      print('아이템 설명 생성 오류: $e');
      return '정보없음';
    }
  }
}