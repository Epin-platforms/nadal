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
  List<Map<String, dynamic>> members = [];
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
    isOwner = widget.scheduleProvider.schedule?['uid'] == FirebaseAuth.instance.currentUser!.uid;
    _loadMembers();
  }

  void _loadMembers() {
    final allMembers = widget.scheduleProvider.getAllMembers();

    if (allMembers.isEmpty) return;

    // 모든 멤버가 memberIndex를 가지고 있는지 확인
    final hasAllIndexes = allMembers.values.every((member) =>
    member['memberIndex'] != null && member['memberIndex'] > 0);

    if (!hasAllIndexes) return;

    members = allMembers.entries
        .map((e) => Map<String, dynamic>.from(e.value))
        .toList();

    members.sort((a, b) => (a['memberIndex'] as int).compareTo(b['memberIndex'] as int));

    if (mounted) {
      setState(() {});
    }
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

  List<List<int>> calculateTournamentMatchups() {
    List<List<int>> matchups = [];

    for (int i = 0; i < members.length; i += 2) {
      if (i + 1 < members.length) {
        matchups.add([i, i + 1]);
      } else {
        matchups.add([i, -1]);
      }
    }

    return matchups;
  }

  bool isAutoWin(int player1Index, int player2Index) {
    if (player2Index == -1) return true;

    final player1IsWalkOver = widget.scheduleProvider.isWalkOverMember(members[player1Index]['uid']);
    final player2IsWalkOver = widget.scheduleProvider.isWalkOverMember(members[player2Index]['uid']);

    if (player1IsWalkOver && !player2IsWalkOver) return false;
    if (!player1IsWalkOver && player2IsWalkOver) return true;

    return false;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('성공적으로 순서공개가 되었어요'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('순서공개에 실패했어요'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () {},
            ),
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('해당 순서로 게임을 만들게요'),
          content: const Text('게임을 만든 후에는 순서 변경이 불가해요'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('음.. 잠시만요'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.scheduleProvider.createGameTable();
              },
              child: const Text('네! 진행해주세요'),
            ),
          ],
        ),
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
        if (isOwner && widget.scheduleProvider.schedule!['state'] == 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    size: 20,
                  ),
                  const SizedBox(width: 10),
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

        const SizedBox(height: 8),

        // 토글 버튼: 일반 목록 <-> 토너먼트 대진표
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showTournamentView = !_showTournamentView;
                    HapticFeedback.lightImpact();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  icon: Icon(_showTournamentView ? Icons.list : Icons.account_tree_rounded),
                  label: Text(_showTournamentView ? '리스트 보기' : '토너먼트 대진표'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 토너먼트 대진표 또는 일반 목록
        Expanded(
          child: _showTournamentView
              ? _buildTournamentView(theme)
              : _buildListView(theme),
        ),

        const SizedBox(height: 16),

        // 하단 버튼
        if (isOwner && widget.scheduleProvider.schedule!['state'] == 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 52,
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
                      size: 20,
                    ),
                    const SizedBox(width: 8),
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

  // 원래 리스트 뷰 (드래그 앤 드롭 기능을 가진)
  Widget _buildListView(ThemeData theme) {
    return Listener(
      onPointerMove: _pointListener,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: members.length,
        separatorBuilder: (context, index) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          final member = members[index];
          final isWalkOver = widget.scheduleProvider.isWalkOverMember(member['uid']);

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
                        child: _buildMemberCard(member, index, true, isWalkOver),
                      ),
                    ),
                    childWhenDragging: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Center(
                        child: Icon(
                          Icons.swap_vert_rounded,
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          size: 24,
                        ),
                      ),
                    ),
                    child: isOwner
                        ? Stack(
                      children: [
                        _buildMemberCard(member, index, false, isWalkOver),
                        if (!isWalkOver)
                          Positioned(
                            right: 20,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Icon(
                                Icons.drag_handle_rounded,
                                color: theme.hintColor.withValues(alpha: 0.5),
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    )
                        : _buildMemberCard(member, index, false, isWalkOver),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // 새로운 토너먼트 대진표 뷰
  Widget _buildTournamentView(ThemeData theme) {
    final matchups = calculateTournamentMatchups();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 토너먼트 설명
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '이 대진표는 현재 설정된 순서로 토너먼트가\n진행되면 생성될 예상 구도입니다.\n실제 대진표는 게임 시작 후 확인할 수 있습니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 토너먼트 대진표
          ...matchups.map((matchup) {
            final player1Index = matchup[0];
            final player2Index = matchup[1];
            final hasBothPlayers = player2Index != -1;
            final player1WinsAuto = hasBothPlayers && isAutoWin(player1Index, player2Index);
            final player2WinsAuto = hasBothPlayers && isAutoWin(player2Index, player1Index);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildTournamentPlayerCard(
                    theme,
                    members[player1Index],
                    isWinner: player1WinsAuto,
                    showMatchBorders: hasBothPlayers,
                    isTop: true,
                  ),

                  if (hasBothPlayers)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),

                  if (hasBothPlayers)
                    _buildTournamentPlayerCard(
                      theme,
                      members[player2Index],
                      isWinner: player2WinsAuto,
                      showMatchBorders: true,
                      isTop: false,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 토너먼트 대진표의 선수 카드
  Widget _buildTournamentPlayerCard(
      ThemeData theme,
      Map<String, dynamic> player,
      {bool isWinner = false,
        bool showMatchBorders = true,
        bool isTop = true}
      ) {
    final isWalkOverPlayer = widget.scheduleProvider.isWalkOverMember(player['uid']);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isWinner
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : isWalkOverPlayer
            ? theme.colorScheme.error.withValues(alpha: 0.05)
            : null,
        borderRadius: !showMatchBorders
            ? BorderRadius.circular(16)
            : BorderRadius.vertical(
          top: isTop ? const Radius.circular(16) : Radius.zero,
          bottom: isTop ? Radius.zero : const Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isWalkOverPlayer
                  ? theme.colorScheme.error.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              isWalkOverPlayer ? '부' : '${player['memberIndex']}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isWalkOverPlayer
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isWalkOverPlayer
                      ? '부전승'
                      : (player['name'] ?? player['nickName'] ?? '선수 ${player['memberIndex']}'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isWalkOverPlayer
                        ? theme.colorScheme.error
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (player['team'] != null && !isWalkOverPlayer)
                  Text(
                    player['team'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          if (isWinner)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            )
          else if (isWalkOverPlayer)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_rounded,
                color: theme.colorScheme.error,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, int index, bool isDragging, bool isWalkOver) {
    final theme = Theme.of(context);

    if (isWalkOver) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.person_off_rounded,
              color: theme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '부전승',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return NadalSoloCard(
      isDragging: isDragging,
      user: member,
      index: index,
    );
  }
}