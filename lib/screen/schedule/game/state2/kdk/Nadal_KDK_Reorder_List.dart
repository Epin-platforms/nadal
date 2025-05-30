import 'package:flutter/services.dart';
import 'package:my_sports_calendar/screen/schedule/game/state2/widget/Nadal_Solo_Card.dart';

import '../../../../../manager/project/Import_Manager.dart';

class NadalKDKReorderList extends StatefulWidget {
  const NadalKDKReorderList({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;
  @override
  State<NadalKDKReorderList> createState() => _NadalKDKReorderListState();
}

class _NadalKDKReorderListState extends State<NadalKDKReorderList> {
  bool isOwner = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> members = [];
  bool _isChanged = false;

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
    isOwner = widget.scheduleProvider.schedule?['uid'] == FirebaseAuth.instance.currentUser!.uid;
    _loadMembers();
  }

  void _loadMembers() {
    final provider = widget.scheduleProvider;
    final map = provider.scheduleMembers;
    if (map == null || map.isEmpty) return;

    // 비-토너먼트 스케줄: 기존 로직 유지
    if (!provider.isGameSchedule ||
        (provider.gameType != GameType.tourSingle &&
            provider.gameType != GameType.tourDouble)) {

      // 모든 멤버에 memberIndex가 있는지 확인
      final allHaveIndex = map.values.every((m) =>
      m['memberIndex'] != null && m['memberIndex'] is int && m['memberIndex'] > 0);
      if (!allHaveIndex) return;

      // memberIndex 순으로 정렬
      members = map.values
          .map((m) => Map<String, dynamic>.from(m))
          .toList()
        ..sort((a, b) => (a['memberIndex'] as int)
            .compareTo(b['memberIndex'] as int));

    } else {
      // 토너먼트 스케줄: 슬롯 고정, 빈 슬롯엔 bye 표시
      final slots = provider.totalSlots;
      final byeSet = provider.byePlayers.toSet();

      // 인덱스 → member 매핑
      final idxToMember = <int, Map<String, dynamic>>{};
      for (var m in map.values) {
        final idx = m['memberIndex'] as int?;
        if (idx != null) idxToMember[idx] = Map.from(m);
      }

      members = List.generate(slots, (i) {
        final idx = i + 1;
        if (idxToMember.containsKey(idx)) {
          final member = idxToMember[idx]!;
          // bye 플레이어 표시용 플래그 추가
          member['isBye'] = byeSet.contains(member['uid']);
          return member;
        } else {
          // 빈 슬롯: 간단히 bye slot 표시
          return {
            'memberIndex': idx,
            'isBye': true,
          };
        }
      });
    }

    if (mounted) setState(() {});
  }
  void _pointListener(PointerMoveEvent event) {
    if (!isOwner) return;

    final pos = event.position;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = box.globalToLocal(pos);
    const threshold = 120.0;
    const speed = 15.0;

    if (local.dy < threshold) {
      final factor = 1.0 - (local.dy / threshold);
      final newOffset = (_scrollController.offset - (speed * factor)).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(newOffset);
    } else if (local.dy > box.size.height - threshold) {
      final factor = (local.dy - (box.size.height - threshold)) / threshold;
      final newOffset = (_scrollController.offset + (speed * factor)).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(newOffset);
    }
  }

  void _checkChanges() {
    bool changed = false;
    for (var i = 0; i < members.length; i++) {
      if (members[i]['memberIndex'] != (i + 1)) {
        changed = true;
        break;
      }
    }

    if (changed != _isChanged) {
      _isChanged = changed;
      if (mounted) {
        setState(() {});
      }

      if (_isChanged) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  Future<void> _handleButtonPress() async {
    if (!mounted) return;

    HapticFeedback.mediumImpact();

    if (_isChanged) {
      final res = await widget.scheduleProvider.updateMemberIndex(members);
      if (res?.statusCode == 200) {
        _isChanged = false;
        if (mounted) {
          setState(() {});
        }
        SnackBarManager.showCleanSnackBar(context, '성공적으로 순서공개가 되었어요');
      } else {
        SnackBarManager.showCleanSnackBar(context, '순서공개에 실패했어요', icon: Icons.warning_amber);
      }
    } else {
      DialogManager.showBasicDialog(
          title: '해당 순서로 게임을 만들게요',
          content: '게임을 만든 후에는 순서 변경이 불가해요',
          confirmText: '네! 진행해주세요',
          onConfirm: () => widget.scheduleProvider.createGameTable(),
          cancelText: '음.. 잠시만요'
      );
    }
  }

  void _onDragAccept(int fromIndex, int toIndex) {
    if (fromIndex == toIndex || !mounted) return;

    final fromItem = members.removeAt(fromIndex);
    members.insert(toIndex, fromItem);
    _checkChanges();
    HapticFeedback.lightImpact();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 데이터 로딩 확인
    if (members.isEmpty) {
      _loadMembers();
      if (members.isEmpty) {
        return const Center(child: NadalCircular());
      }
    }

    return Column(
      children: [
        // 상태 표시
        if (isOwner)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: _isChanged
                    ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isChanged
                      ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                      : theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
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
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      _isChanged
                          ? '순서가 변경되었습니다.\n완료 후 "순서 공개" 버튼을 클릭해주세요.'
                          : '참가자 순서를 변경하려면 카드를 길게 누른 후 드래그하세요.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _isChanged
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        SizedBox(height: 8.h),

        // 멤버 목록
        Expanded(
          child: Listener(
            onPointerMove: _pointListener,
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: members.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final member = members[index];

                return IgnorePointer(
                  ignoring: !isOwner || widget.scheduleProvider.schedule!['state'] != 2,
                  child: DragTarget<int>(
                    onWillAcceptWithDetails: (details) => details.data != index,
                    onAcceptWithDetails: (details) => _onDragAccept(details.data, index),
                    builder: (context, candidateData, rejectedData) {
                      final isDragTarget = candidateData.isNotEmpty;

                      return Container(
                        decoration: BoxDecoration(
                          color: isDragTarget
                              ? theme.colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                        ),
                        child: LongPressDraggable<int>(
                          data: index,
                          onDragStarted: () => HapticFeedback.mediumImpact(),
                          feedback: Material(
                            elevation: 8,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 60,
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: _buildMemberCard(member, index, true),
                            ),
                          ),
                          childWhenDragging: Container(
                            height: 70.h,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            child: Center(
                              child: Icon(
                                Icons.swap_vert_rounded,
                                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                size: 24.r,
                              ),
                            ),
                          ),
                          child: _buildMemberCard(member, index, false),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // 하단 버튼
        if (isOwner && widget.scheduleProvider.schedule?['state'] == 2)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                  shadowColor: _isChanged
                      ? theme.colorScheme.secondary.withValues(alpha: 0.4)
                      : theme.colorScheme.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isChanged
                          ? Icons.published_with_changes_rounded
                          : Icons.check_circle_rounded,
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

  Widget _buildMemberCard(Map<String, dynamic> member, int index, bool isDragging) {
    return NadalSoloCard(
      isDragging: isDragging,
      user: member,
      index: index,
    );
  }
}