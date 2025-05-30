import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../manager/project/Import_Manager.dart';

class TournamentTeamReorderList extends StatefulWidget {
  const TournamentTeamReorderList({
    super.key,
    required this.scheduleProvider,
  });

  final ScheduleProvider scheduleProvider;

  @override
  State<TournamentTeamReorderList> createState() =>
      _TournamentTeamReorderListState();
}

class _TournamentTeamReorderListState
    extends State<TournamentTeamReorderList> {
  bool isOwner = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> teamsList = [];
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
    _loadTeams();
  }

  void _loadTeams() {
    final teamsData = widget.scheduleProvider.teams;
    if (teamsData == null || teamsData.isEmpty) return;

    final byeSet = widget.scheduleProvider.byePlayers.toSet();

    teamsList = teamsData.entries.map((entry) {
      final teamName = entry.key;
      final members = entry.value;
      // 팀의 시드 → 첫 번째 멤버 인덱스로 결정
      final memberIndex = members.first['memberIndex'] as int? ?? 0;
      // 팀 내 누구라도 byePlayers 에 속하면 팀 부전승
      final walkOver = members.any((m) => byeSet.contains(m['uid']));
      final profileImage = members.first['profileImage'] ?? '';
      return {
        'teamName': teamName,
        'members': members,
        'memberIndex': memberIndex,
        'profileImage': profileImage,
        'walkOver': walkOver,
      };
    }).toList();

    teamsList.sort((a, b) =>
        (a['memberIndex'] as int).compareTo(b['memberIndex'] as int));

    if (mounted) setState(() {});
  }

  void _pointListener(PointerMoveEvent event) {
    if (!isOwner) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = box.globalToLocal(event.position);
    const threshold = 120.0, speed = 15.0;

    if (local.dy < threshold) {
      final factor = 1 - local.dy / threshold;
      final newOffset = (_scrollController.offset - speed * factor)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(newOffset);
    } else if (local.dy > box.size.height - threshold) {
      final factor = (local.dy - (box.size.height - threshold)) / threshold;
      final newOffset = (_scrollController.offset + speed * factor)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(newOffset);
    }
  }

  void _checkChanges() {
    var changed = false;
    for (var i = 0; i < teamsList.length; i++) {
      if (teamsList[i]['memberIndex'] != i + 1) {
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
    for (var i = 0; i < teamsList.length; i += 2) {
      matchups.add([i, i + 1 < teamsList.length ? i + 1 : -1]);
    }
    return matchups;
  }

  bool isAutoWin(int t1, int t2) {
    if (t2 == -1) return true;
    final bye = widget.scheduleProvider.byePlayers.toSet();
    final t1Bye = (teamsList[t1]['members'] as List)
        .any((m) => bye.contains(m['uid']));
    final t2Bye = (teamsList[t2]['members'] as List)
        .any((m) => bye.contains(m['uid']));
    if (t1Bye && !t2Bye) return false;
    if (!t1Bye && t2Bye) return true;
    return false;
  }

  Future<void> _handleButtonPress() async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    if (_isChanged) {
      final sm = ScaffoldMessenger.of(context);
      final res =
      await widget.scheduleProvider.updateTeamIndex(teamsList);

      // 새로고침
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _loadTeams();
      });

      if (res?.statusCode == 200) {
        _isChanged = false;
        if (mounted) setState(() {});
        sm.showSnackBar(const SnackBar(
          content: Text('성공적으로 팀 순서가 공개되었어요'),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        sm.showSnackBar(SnackBar(
          content: const Text('팀 순서 공개에 실패했어요'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '다시 시도',
            onPressed: _handleButtonPress,
          ),
        ));
      }
    } else {
      DialogManager.showBasicDialog(
        title: '해당 순서로 팀 게임을 만들게요',
        content: '게임을 만든 후에는 팀 순서 변경이 불가해요',
        confirmText: '네! 진행해주세요',
        cancelText: '음.. 잠시만요',
        onConfirm: () {
          widget.scheduleProvider.createGameTable();
        },
      );
    }
  }

  void _onDragAccept(int from, int to) {
    if (from == to || !mounted) return;
    final item = teamsList.removeAt(from);
    teamsList.insert(to, item);
    _checkChanges();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (teamsList.isEmpty) {
      _loadTeams();
      if (teamsList.isEmpty) {
        return const Center(child: NadalCircular());
      }
    }

    return Column(
      children: [
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isChanged
                          ? '팀 순서가 변경되었습니다.\n완료 후 "순서 공개" 버튼을 클릭해주세요.'
                          : '팀 순서를 변경하려면 카드를 길게 누른 후 드래그하세요.',
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

        const SizedBox(height: 8),

        // 토글
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: () {
              _showTournamentView = !_showTournamentView;
              HapticFeedback.lightImpact();
              setState(() {});
            },
            icon: Icon(
              _showTournamentView ? Icons.list : Icons.account_tree_rounded,
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

        Expanded(
          child: _showTournamentView
              ? _buildTournamentView(theme)
              : _buildListView(theme),
        ),

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
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isChanged
                          ? Icons.published_with_changes_rounded
                          : Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isChanged ? '팀 순서 공개하기' : '게임 진행',
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
        itemCount: teamsList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, idx) {
          final team = teamsList[idx];
          final isBye = team['walkOver'] == true;

          return IgnorePointer(
            ignoring: !isOwner ||
                widget.scheduleProvider.schedule!['state'] != 2,
            child: DragTarget<int>(
              onWillAcceptWithDetails: (d) => d.data != idx,
              onAcceptWithDetails: (d) => _onDragAccept(d.data, idx),
              builder: (ctx, candidate, __) {
                final highlight = candidate.isNotEmpty;
                return Container(
                  color: highlight
                      ? theme.colorScheme.primary.withValues(alpha:0.08)
                      : null,
                  child: LongPressDraggable<int>(
                    data: idx,
                    onDragStarted: () => HapticFeedback.mediumImpact(),
                    feedback: Material(
                      elevation: 8,
                      color: Colors.transparent,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 60,
                        child: _buildTeamCard(theme, team,
                            isDragging: true),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: _buildTeamCard(theme, team),
                    ),
                    child: _buildTeamCard(theme, team),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamCard(
      ThemeData theme, Map<String, dynamic> team,
      {bool isDragging = false}) {
    final isBye = team['walkOver'] == true;
    final members = team['members'] as List<dynamic>;
    final memberNames = <String>[
      for (var m in members)
        m['nickName'] ?? m['name'] ?? ''
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isBye
            ? theme.colorScheme.error.withValues(alpha:0.1)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isBye
            ? Border.all(
          color: theme.colorScheme.error.withValues(alpha:0.3),
        )
            : null,
        boxShadow: isDragging
            ? [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha:0.2),
            blurRadius: 8,
          )
        ]
            : [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha:0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 시드 번호 or 부전승
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isBye
                    ? theme.colorScheme.error.withValues(alpha:0.2)
                    : theme.colorScheme.primary.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                isBye ? '부' : '${team['memberIndex']}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                  isBye ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 프로필 or 아이콘
            if (!isBye && team['profileImage'] != null && team['profileImage'] != '')
              NadalProfileFrame(imageUrl: team['profileImage'])
            else
              CircleAvatar(
                radius: 22,
                backgroundColor: isBye
                    ? theme.colorScheme.error.withValues(alpha:0.1)
                    : theme.colorScheme.primary.withValues(alpha:0.1),
                child: Icon(
                  isBye ? Icons.person_off_rounded : Icons.groups_rounded,
                  color:
                  isBye ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
              ),

            const SizedBox(width: 12),

            // 팀 이름 & 멤버
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBye ? '부전승' : team['teamName'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isBye ? theme.colorScheme.error : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isBye)
                    Text(
                      memberNames.join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentView(ThemeData theme) {
    final matchups = calculateTournamentMatchups();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: matchups.map((pair) {
          final t1 = pair[0], t2 = pair[1];
          final both = t2 != -1;
          final win1 = both && isAutoWin(t1, t2);
          final win2 = both && isAutoWin(t2, t1);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildTournamentTeamCard(
                  theme,
                  teamsList[t1],
                  isWinner: win1,
                  isTop: true,
                  showMatchBorders: both,
                ),
                if (both)
                  Divider(color: theme.dividerColor.withValues(alpha:0.5)),
                if (both)
                  _buildTournamentTeamCard(
                    theme,
                    teamsList[t2],
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

  Widget _buildTournamentTeamCard(
      ThemeData theme,
      Map<String, dynamic> team, {
        required bool isWinner,
        required bool isTop,
        required bool showMatchBorders,
      }) {
    final isBye = team['walkOver'] == true;
    final members = team['members'] as List<dynamic>;
    final names = members
        .map((m) => m['nickName'] ?? m['name'] ?? '')
        .toList();

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
          // 부전승 or seed
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isBye
                  ? theme.colorScheme.error.withValues(alpha:0.1)
                  : theme.colorScheme.primary.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              isBye ? '부' : '${team['memberIndex']}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color:
                isBye ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 팀 이름 & 멤버
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBye ? '부전승' : team['teamName'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isBye ? theme.colorScheme.error : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isBye)
                  Text(
                    names.join(', '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          if (isWinner)
            Icon(Icons.emoji_events_rounded,
                color: theme.colorScheme.primary),
          if (!isWinner && isBye)
            Icon(Icons.person_off_rounded, color: theme.colorScheme.error),
        ],
      ),
    );
  }
}
