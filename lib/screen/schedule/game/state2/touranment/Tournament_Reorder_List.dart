import 'package:flutter/services.dart';
import '../../../../../manager/project/Import_Manager.dart';
import '../widget/Nadal_Solo_Card.dart';

class TournamentReorderList extends StatefulWidget {
  const TournamentReorderList({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;

  @override
  State<TournamentReorderList> createState() => _TournamentReorderListState();
}

class _TournamentReorderListState extends State<TournamentReorderList> {
  bool isOwner = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> slots = []; // 전체 슬롯 (멤버 + 부전승)
  bool _isChanged = false;
  bool _showTournamentView = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeData() {
    isOwner = widget.scheduleProvider.schedule?['uid'] ==
        FirebaseAuth.instance.currentUser!.uid;
    _loadSlots();
  }

  void _loadSlots() {
    final members = widget.scheduleProvider.scheduleMembers;
    if (members == null || members.isEmpty) return;

    final totalSlots = widget.scheduleProvider.totalSlots;
    if (totalSlots <= 0) return;

    // 인덱스별로 멤버 매핑
    final Map<int, Map<String, dynamic>> indexToMember = {};
    members.forEach((uid, memberData) {
      final index = memberData['memberIndex'] as int?;
      if (index != null && index > 0) {
        indexToMember[index] = Map<String, dynamic>.from(memberData);
      }
    });

    // 전체 슬롯 생성 (1부터 totalSlots까지)
    slots = List.generate(totalSlots, (i) {
      final index = i + 1;
      if (indexToMember.containsKey(index)) {
        // 실제 멤버가 있는 슬롯
        return indexToMember[index]!;
      } else {
        // 빈 슬롯 (부전승)
        return {
          'memberIndex': index,
          'isBye': true,
          'byeOpponent': _getByeOpponent(index, indexToMember),
        };
      }
    });

    if (mounted) setState(() {});
  }

  // 부전승 상대 계산 (1vs2, 3vs4, 5vs6...)
  Map<String, dynamic>? _getByeOpponent(int index, Map<int, Map<String, dynamic>> indexToMember) {
    int opponentIndex;
    if (index % 2 == 1) {
      // 홀수 인덱스의 상대는 +1
      opponentIndex = index + 1;
    } else {
      // 짝수 인덱스의 상대는 -1
      opponentIndex = index - 1;
    }

    return indexToMember[opponentIndex];
  }

  void _updateByeOpponents() {
    // 현재 슬롯 상태로 부전승 상대 업데이트
    final Map<int, Map<String, dynamic>> indexToMember = {};

    for (final slot in slots) {
      final index = slot['memberIndex'] as int;
      if (slot['isBye'] != true) {
        indexToMember[index] = slot;
      }
    }

    for (int i = 0; i < slots.length; i++) {
      if (slots[i]['isBye'] == true) {
        final index = slots[i]['memberIndex'] as int;
        slots[i]['byeOpponent'] = _getByeOpponent(index, indexToMember);
      }
    }
  }

  void _pointListener(PointerMoveEvent event) {
    if (!isOwner) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(event.position);
    const threshold = 120.0;
    const speed = 15.0;

    if (local.dy < threshold) {
      final factor = 1.0 - (local.dy / threshold);
      final newOffset = (_scrollController.offset - (speed * factor))
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(newOffset);
    } else if (local.dy > box.size.height - threshold) {
      final factor =
          (local.dy - (box.size.height - threshold)) / threshold;
      final newOffset = (_scrollController.offset + (speed * factor))
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(newOffset);
    }
  }

  void _checkChanges() {
    var changed = false;
    for (var i = 0; i < slots.length; i++) {
      // 원래 memberIndex와 현재 위치 비교
      if (slots[i]['originalIndex'] != (i + 1)) {
        changed = true;
        break;
      }
    }
    if (changed != _isChanged) {
      _isChanged = changed;
      if (mounted) setState(() {});
      if (_isChanged) HapticFeedback.mediumImpact();
    }
  }

  List<List<int>> calculateTournamentMatchups() {
    final matchups = <List<int>>[];
    for (var i = 0; i < slots.length; i += 2) {
      if (i + 1 < slots.length) {
        matchups.add([i, i + 1]);
      }
    }
    return matchups;
  }

  bool isAutoWin(int p1, int p2) {
    final slot1 = slots[p1];
    final slot2 = slots[p2];

    final p1IsBye = slot1['isBye'] == true;
    final p2IsBye = slot2['isBye'] == true;

    if (p1IsBye && !p2IsBye) return false; // 1번이 부전승이면 2번 승리
    if (!p1IsBye && p2IsBye) return true;  // 2번이 부전승이면 1번 승리
    return false;
  }

  bool _validateByeSlots() {
    // 토너먼트 대진에서 연속된 두 슬롯이 모두 부전승인지 확인 (1vs2, 3vs4, 5vs6...)
    for (int i = 0; i < slots.length; i += 2) {
      if (i + 1 < slots.length) {
        final slot1 = slots[i];
        final slot2 = slots[i + 1];

        final isBye1 = slot1['isBye'] == true;
        final isBye2 = slot2['isBye'] == true;

        // 연속된 두 슬롯이 모두 부전승이면 안됨
        if (isBye1 && isBye2) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _handleButtonPress() async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    if (!_validateByeSlots()) {
      DialogManager.showBasicDialog(
        title: '순서 조정이 필요해요',
        content: '연속된 두 슬롯이 모두 부전승일 수 없어요.\n순서를 다시 조정해주세요.',
        confirmText: '확인',
      );
      return;
    }


    if (_isChanged) {
      // 변경된 슬롯으로 멤버 인덱스 업데이트
      final memberSlots = slots.where((slot) => slot['isBye'] != true).toList();
      final res = await widget.scheduleProvider.updateMemberIndex(memberSlots);

      if (res?.statusCode == 200) {
        _isChanged = false;
        if (mounted) setState(() {});
        SnackBarManager.showCleanSnackBar(context, '성공적으로 순서공개가 되었어요');
      } else {
        SnackBarManager.showCleanSnackBar(context, '순서공개에 실패했어요', icon: Icons.warning_amber);
      }
    } else {
      DialogManager.showBasicDialog(
        title: '해당 순서로 게임을 만들게요',
        content: '게임을 만든 후에는 순서 변경이 불가해요',
        confirmText: '네! 진행해주세요',
        cancelText: '음.. 잠시만요',
        onConfirm: () => widget.scheduleProvider.createGameTable(),
      );
    }
  }

  void _onDragAccept(int from, int to) {
    if (from == to || !mounted) return;

    final item = slots.removeAt(from);
    slots.insert(to, item);

    // 모든 슬롯의 memberIndex를 새 위치에 맞게 업데이트
    for (int i = 0; i < slots.length; i++) {
      slots[i]['memberIndex'] = i + 1;
    }

    // 부전승 상대 업데이트
    _updateByeOpponents();

    _checkChanges();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (slots.isEmpty) {
      _loadSlots();
      if (slots.isEmpty) {
        return const Center(child: NadalCircular());
      }
    }

    return Column(
      children: [
        // 상태 안내
        if (isOwner && widget.scheduleProvider.schedule!['state'] == 2)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: _isChanged
                    ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _isChanged
                      ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                      : theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isChanged
                        ? Icons.swap_vert_rounded
                        : Icons.info_outline_rounded,
                    color: _isChanged
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary,
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _isChanged
                          ? '순서가 변경되었습니다.\n완료 후 "순서 공개" 버튼을 클릭해주세요.'
                          : '참가자 순서를 변경하려면 카드를 길게 누른 후 드래그하세요.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _isChanged
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 토글 버튼
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showTournamentView = !_showTournamentView;
                HapticFeedback.lightImpact();
                setState(() {});
              },
              icon: Icon(
                _showTournamentView ? Icons.list : Icons.account_tree,
                size: 18.r,
              ),
              label: Text(
                _showTournamentView ? '리스트 보기' : '토너먼트 대진표',
                style: theme.textTheme.bodyMedium,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
            ),
          ),
        ),

        SizedBox(height: 8.h),

        // 본문
        Expanded(
          child: _showTournamentView
              ? _buildTournamentView(theme)
              : _buildListView(theme),
        ),

        // 하단 버튼
        if (isOwner && widget.scheduleProvider.schedule!['state'] == 2)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _handleButtonPress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isChanged
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: (_isChanged
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isChanged
                          ? Icons.published_with_changes
                          : Icons.check_circle,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _isChanged ? '순서 공개하기' : '게임 진행',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListView(ThemeData theme) {
    return Listener(
      onPointerMove: _pointListener,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: slots.length,
        separatorBuilder: (_, __) => SizedBox(height: 4.h),
        itemBuilder: (context, idx) {
          final slot = slots[idx];
          final isBye = slot['isBye'] == true;

          return IgnorePointer(
            ignoring: !isOwner || widget.scheduleProvider.schedule!['state'] != 2,
            child: DragTarget<int>(
              onWillAcceptWithDetails: (d) => d.data != idx,
              onAcceptWithDetails: (d) => _onDragAccept(d.data, idx),
              builder: (ctx, candidate, __) {
                final highlighting = candidate.isNotEmpty;
                return Container(
                  color: highlighting
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : null,
                  child: LongPressDraggable<int>(
                    data: idx,
                    feedback: Material(
                      elevation: 8,
                      color: Colors.transparent,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 60.w,
                        child: isBye
                            ? _buildByeCard(theme, slot, isDragging: true)
                            : _buildMemberCard(slot, true),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: isBye
                          ? _buildByeCard(theme, slot)
                          : _buildMemberCard(slot, false),
                    ),
                    onDragStarted: () => HapticFeedback.mediumImpact(),
                    child: isBye
                        ? _buildByeCard(theme, slot)
                        : _buildMemberCard(slot, false),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTournamentView(ThemeData theme) {
    final matchups = calculateTournamentMatchups();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: matchups.map((pair) {
          final i1 = pair[0], i2 = pair[1];
          final win1 = isAutoWin(i1, i2);
          final win2 = isAutoWin(i2, i1);

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTournamentPlayerCard(
                  theme,
                  slots[i1],
                  isWinner: win1,
                  isTop: true,
                ),
                Divider(color: theme.dividerColor, height: 1),
                _buildTournamentPlayerCard(
                  theme,
                  slots[i2],
                  isWinner: win2,
                  isTop: false,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTournamentPlayerCard(
      ThemeData theme,
      Map<String, dynamic> slot, {
        required bool isWinner,
        required bool isTop,
      }) {
    final isBye = slot['isBye'] == true;
    final opponent = slot['byeOpponent'];

    return Container(
      height: 72.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isWinner
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : isBye
            ? theme.colorScheme.error.withValues(alpha: 0.05)
            : null,
        borderRadius: BorderRadius.vertical(
          top: isTop ? Radius.circular(16.r) : Radius.zero,
          bottom: isTop ? Radius.zero : Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15.r,
            backgroundColor: isBye
                ? theme.colorScheme.error.withValues(alpha: 0.2)
                : theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Text(
              '${slot['memberIndex']}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isBye ? theme.colorScheme.error : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isBye
                      ? (opponent != null
                      ? '${opponent['nickName'] ?? opponent['name'] ?? '알 수 없음'} 부전승'
                      : '부전승')
                      : (slot['name'] ?? slot['nickName'] ?? '알 수 없음'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isBye ? theme.colorScheme.error : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isBye && opponent != null)
                  Text(
                    '상대 없음으로 자동 승리',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          if (isWinner)
            Icon(Icons.emoji_events, color: theme.colorScheme.primary, size: 20.r),
          if (isBye)
            Icon(Icons.person_off, color: theme.colorScheme.error, size: 20.r),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, bool isDragging) {
    return NadalSoloCard(
      isDragging: isDragging,
      user: member,
      index: member['memberIndex'] ?? 0,
    );
  }

  Widget _buildByeCard(ThemeData theme, Map<String, dynamic> slot, {bool isDragging = false}) {
    final opponent = slot['byeOpponent'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
        boxShadow: isDragging ? [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.18),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 4),
          )
        ] : [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 6,
            spreadRadius: 0,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // 순서 번호
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${slot['memberIndex']}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
                fontSize: 14.sp,
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // 부전승 아이콘
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: CircleAvatar(
              radius: 20.r,
              backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
              child: Icon(
                Icons.person_off,
                color: theme.colorScheme.error,
                size: 20.r,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // 부전승 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  opponent != null
                      ? '${opponent['nickName'] ?? opponent['name'] ?? '알 수 없음'} 부전승'
                      : '부전승',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                    color: theme.colorScheme.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (opponent != null)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      '상대 없음으로 자동 승리',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}