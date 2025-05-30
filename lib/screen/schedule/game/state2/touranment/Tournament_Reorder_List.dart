import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    isOwner = widget.scheduleProvider.schedule?['uid'] ==
        FirebaseAuth.instance.currentUser!.uid;
    _loadMembers();
  }

  void _loadMembers() {
    final map = widget.scheduleProvider.scheduleMembers;
    if (map == null || map.isEmpty) return;

    // 모든 멤버가 memberIndex를 가지고 있는지 확인
    final hasAllIndexes = map.values.every((m) =>
    m['memberIndex'] != null &&
        m['memberIndex'] is int &&
        (m['memberIndex'] as int) > 0);
    if (!hasAllIndexes) return;

    // 토너먼트 여부에 따라 리스트 생성
    if (!widget.scheduleProvider.isGameSchedule ||
        (widget.scheduleProvider.gameType != GameType.tourSingle &&
            widget.scheduleProvider.gameType != GameType.tourDouble)) {
      // 일반 스케줄: memberIndex 순서대로만 정렬
      members = map.values
          .map((m) => Map<String, dynamic>.from(m))
          .toList()
        ..sort((a, b) => (a['memberIndex'] as int)
            .compareTo(b['memberIndex'] as int));
    } else {
      // 토너먼트: totalSlots 길이만큼 고정, 빈 슬롯엔 bye slot
      final slots = widget.scheduleProvider.totalSlots;
      final byeSet = widget.scheduleProvider.byePlayers.toSet();

      // index → member 매핑
      final idxToMember = <int, Map<String, dynamic>>{};
      for (var m in map.values) {
        final idx = m['memberIndex'] as int;
        idxToMember[idx] = Map<String, dynamic>.from(m);
      }

      members = List.generate(slots, (i) {
        final idx = i + 1;
        if (idxToMember.containsKey(idx)) {
          final member = idxToMember[idx]!;
          member['isBye'] = byeSet.contains(member['uid']);
          return member;
        } else {
          return {
            'memberIndex': idx,
            'isBye': true,
            // uid/name 등은 없으므로 화면에서 빈 슬롯으로 처리하세요
          };
        }
      });
    }

    if (mounted) setState(() {});
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
    for (var i = 0; i < members.length; i++) {
      if (members[i]['memberIndex'] != (i + 1)) {
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
    for (var i = 0; i < members.length; i += 2) {
      if (i + 1 < members.length) {
        matchups.add([i, i + 1]);
      } else {
        matchups.add([i, -1]);
      }
    }
    return matchups;
  }

  bool isAutoWin(int p1, int p2) {
    if (p2 == -1) return true;
    final bye = widget.scheduleProvider.byePlayers.toSet();
    final p1Bye = bye.contains(members[p1]['uid']);
    final p2Bye = bye.contains(members[p2]['uid']);
    if (p1Bye && !p2Bye) return false;
    if (!p1Bye && p2Bye) return true;
    return false;
  }

  Future<void> _handleButtonPress() async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    if (_isChanged) {
      final res =
      await widget.scheduleProvider.updateMemberIndex(members);
      if (res?.statusCode == 200) {
        _isChanged = false;
        if (mounted) setState(() {});
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
              onPressed: _handleButtonPress,
            ),
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
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

  void _onDragAccept(int from, int to) {
    if (from == to || !mounted) return;
    final item = members.removeAt(from);
    members.insert(to, item);
    _checkChanges();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 데이터 준비
    if (members.isEmpty) {
      _loadMembers();
      if (members.isEmpty) {
        return const Center(child: NadalCircular());
      }
    }

    return Column(
      children: [
        // 상태 안내
        if (isOwner && widget.scheduleProvider.schedule!['state'] == 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isChanged
                    ? theme.colorScheme.secondary.withValues(alpha:0.1)
                    : theme.colorScheme.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isChanged
                      ? theme.colorScheme.secondary.withValues(alpha:0.3)
                      : theme.colorScheme.primary.withValues(alpha:0.3),
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
                  ),
                  const SizedBox(width: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: () {
              _showTournamentView = !_showTournamentView;
              HapticFeedback.lightImpact();
              setState(() {});
            },
            icon: Icon(
              _showTournamentView ? Icons.list : Icons.account_tree,
            ),
            label: Text(
              _showTournamentView ? '리스트 보기' : '토너먼트 대진표',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              theme.colorScheme.primary.withValues(alpha:0.1),
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 본문
        Expanded(
          child: _showTournamentView
              ? _buildTournamentView(theme)
              : _buildListView(theme),
        ),

        // 하단 버튼
        if (isOwner && widget.scheduleProvider.schedule!['state'] == 2)
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleButtonPress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isChanged
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isChanged
                          ? Icons.published_with_changes
                          : Icons.check_circle,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isChanged ? '순서 공개하기' : '게임 진행',
                      style: const TextStyle(color: Colors.white),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, idx) {
          final m = members[idx];
          final isBye = m['isBye'] == true;

          return IgnorePointer(
            ignoring: !isOwner ||
                widget.scheduleProvider.schedule!['state'] != 2,
            child: DragTarget<int>(
              onWillAcceptWithDetails: (d) => d.data != idx,
              onAcceptWithDetails: (d) => _onDragAccept(d.data, idx),
              builder: (ctx, candidate, __) {
                final highlighting = candidate.isNotEmpty;
                return Container(
                  color: highlighting
                      ? theme.colorScheme.primary.withValues(alpha:0.08)
                      : null,
                  child: LongPressDraggable<int>(
                    data: idx,
                    feedback: Material(
                      elevation: 8,
                      color: Colors.transparent,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 60,
                        child: _buildMemberCard(m, true, isBye),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: _buildMemberCard(m, false, isBye),
                    ),
                    onDragStarted: () =>
                        HapticFeedback.mediumImpact(),
                    child: _buildMemberCard(m, false, isBye),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: matchups.map((pair) {
          final i1 = pair[0], i2 = pair[1];
          final hasBoth = i2 != -1;
          final win1 = hasBoth && isAutoWin(i1, i2);
          final win2 = hasBoth && isAutoWin(i2, i1);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha:0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTournamentPlayerCard(
                  theme,
                  members[i1],
                  isWinner: win1,
                  isTop: true,
                  showMatchBorders: hasBoth,
                ),
                if (hasBoth)
                  Divider(color: theme.dividerColor),
                if (hasBoth)
                  _buildTournamentPlayerCard(
                    theme,
                    members[i2],
                    isWinner: win2,
                    isTop: false,
                    showMatchBorders: true,
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
      Map<String, dynamic> player, {
        required bool isWinner,
        required bool isTop,
        required bool showMatchBorders,
      }) {
    final isBye = player['isBye'] == true;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isWinner
            ? theme.colorScheme.primary.withValues(alpha:0.05)
            : isBye
            ? theme.colorScheme.error.withValues(alpha:0.05)
            : null,
        borderRadius: !showMatchBorders
            ? BorderRadius.circular(16)
            : BorderRadius.vertical(
          top: isTop ? const Radius.circular(16) : Radius.zero,
          bottom: isTop ? Radius.zero : const Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: isBye
                ? theme.colorScheme.error.withValues(alpha:0.2)
                : theme.colorScheme.primary.withValues(alpha:0.2),
            child: Text(
              isBye ? '부' : '${player['memberIndex']}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                isBye ? theme.colorScheme.error : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isBye
                  ? '부전승'
                  : (player['name'] ?? player['nickName'] ?? ''),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isBye ? theme.colorScheme.error : null,
              ),
            ),
          ),
          if (isWinner)
            Icon(Icons.emoji_events, color: theme.colorScheme.primary),
          if (!isWinner && isBye)
            Icon(Icons.person_off, color: theme.colorScheme.error),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
      Map<String, dynamic> member, bool isDragging, bool isBye) {
    final theme = Theme.of(context);
    if (isBye) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha:0.3),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: theme.colorScheme.error.withValues(alpha:0.2),
              child: Text(
                '${member['memberIndex']}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.person_off, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Text(
              '부전승',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return NadalSoloCard(
      isDragging: isDragging,
      user: member,
      index: member['memberIndex'],
    );
  }
}
