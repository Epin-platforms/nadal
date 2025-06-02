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
  List<Map<String, dynamic>> teamSlots = []; // 전체 팀 슬롯 (팀 + 부전승)
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
    _loadTeamSlots();
  }

  void _loadTeamSlots() {
    final teamsData = widget.scheduleProvider.teams;
    if (teamsData == null || teamsData.isEmpty) return;

    // 실제 팀 수에 맞는 2의 제곱수 계산
    final teamCount = teamsData.length;
    final totalSlots = _getNextPowerOfTwo(teamCount);

    // 팀 인덱스별로 매핑 (첫 번째 멤버의 인덱스 사용)
    final Map<int, Map<String, dynamic>> indexToTeam = {};

    teamsData.forEach((teamName, members) {
      if (members.isNotEmpty) {
        final memberIndex = members.first['memberIndex'] as int? ?? 0;
        if (memberIndex > 0) {
          indexToTeam[memberIndex] = {
            'teamName': teamName,
            'members': members,
            'memberIndex': memberIndex,
            'profileImage': members.first['profileImage'] ?? '',
          };
        }
      }
    });

    // 전체 슬롯 생성 (1부터 totalSlots까지)
// 팀 슬롯 생성 시
    teamSlots = List.generate(totalSlots, (i) {
      final index = i + 1;
      if (indexToTeam.containsKey(index)) {
        // 실제 팀이 있는 슬롯
        return {
          ...indexToTeam[index]!,
          'originalIndex': index, // 원래 위치 저장
        };
      } else {
        // 빈 슬롯 (부전승)
        return {
          'memberIndex': index,
          'originalIndex': index, // 원래 위치 저장
          'isBye': true,
          'byeOpponent': _getByeOpponentTeam(index, indexToTeam),
        };
      }
    });

    if (mounted) setState(() {});
  }

  int _getNextPowerOfTwo(int number) {
    int power = 1;
    while (power < number) power <<= 1;
    return power;
  }

  // 부전승 상대 팀 계산 (1vs2, 3vs4, 5vs6...)
  Map<String, dynamic>? _getByeOpponentTeam(int index, Map<int, Map<String, dynamic>> indexToTeam) {
    int opponentIndex;
    if (index % 2 == 1) {
      // 홀수 인덱스의 상대는 +1
      opponentIndex = index + 1;
    } else {
      // 짝수 인덱스의 상대는 -1
      opponentIndex = index - 1;
    }

    return indexToTeam[opponentIndex];
  }

  void _updateByeOpponents() {
    // 현재 슬롯 상태로 부전승 상대 업데이트
    final Map<int, Map<String, dynamic>> indexToTeam = {};

    for (final slot in teamSlots) {
      final index = slot['memberIndex'] as int;
      if (slot['isBye'] != true) {
        indexToTeam[index] = slot;
      }
    }

    for (int i = 0; i < teamSlots.length; i++) {
      if (teamSlots[i]['isBye'] == true) {
        final index = teamSlots[i]['memberIndex'] as int;
        teamSlots[i]['byeOpponent'] = _getByeOpponentTeam(index, indexToTeam);
      }
    }
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
    for (var i = 0; i < teamSlots.length; i++) {  // teamSlots 사용
      // 원래 memberIndex와 현재 위치 비교
      if (teamSlots[i]['originalIndex'] != (i + 1)) {
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
    for (var i = 0; i < teamSlots.length; i += 2) {
      if (i + 1 < teamSlots.length) {
        matchups.add([i, i + 1]);
      }
    }
    return matchups;
  }

  bool isAutoWin(int t1, int t2) {
    final team1 = teamSlots[t1];
    final team2 = teamSlots[t2];

    final t1IsBye = team1['isBye'] == true;
    final t2IsBye = team2['isBye'] == true;

    if (t1IsBye && !t2IsBye) return false; // 1팀이 부전승이면 2팀 승리
    if (!t1IsBye && t2IsBye) return true;  // 2팀이 부전승이면 1팀 승리
    return false;
  }

  bool _validateByeTeamSlots() {
    // 토너먼트 대진에서 연속된 두 팀이 모두 부전승인지 확인 (1vs2, 3vs4, 5vs6...)
    for (int i = 0; i < teamSlots.length; i += 2) {
      if (i + 1 < teamSlots.length) {
        final team1 = teamSlots[i];
        final team2 = teamSlots[i + 1];

        final isBye1 = team1['isBye'] == true;
        final isBye2 = team2['isBye'] == true;

        // 연속된 두 팀이 모두 부전승이면 안됨
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

    if (!_validateByeTeamSlots()) {
      DialogManager.showBasicDialog(
        title: '팀 순서 조정이 필요해요',
        content: '연속된 두 팀이 모두 부전승일 수 없어요.\n팀 순서를 다시 조정해주세요.',
        confirmText: '확인',
      );
      return;
    }


    if (_isChanged) {
      final res = await widget.scheduleProvider.updateTeamIndex(teamSlots);

      if (res?.statusCode == 200) {
        _isChanged = false;
        if (mounted) setState(() {});
        SnackBarManager.showCleanSnackBar(context, '성공적으로 팀 순서가 공개되었어요');
      } else {
        SnackBarManager.showCleanSnackBar(context, '팀 순서 공개에 실패했어요', icon: Icons.warning_amber);
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

    final item = teamSlots.removeAt(from);
    teamSlots.insert(to, item);

    // 모든 슬롯의 memberIndex를 새 위치에 맞게 업데이트
    for (int i = 0; i < teamSlots.length; i++) {
      teamSlots[i]['memberIndex'] = i + 1;
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

    if (teamSlots.isEmpty) {
      _loadTeamSlots();
      if (teamSlots.isEmpty) {
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
                  SizedBox(width: 10.w),
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

        SizedBox(height: 8.h),

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
                _showTournamentView ? Icons.list : Icons.account_tree_rounded,
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
                          ? Icons.published_with_changes_rounded
                          : Icons.check_circle_rounded,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _isChanged ? '팀 순서 공개하기' : '게임 진행',
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
        itemCount: teamSlots.length,
        separatorBuilder: (_, __) => SizedBox(height: 4.h),
        itemBuilder: (context, idx) {
          final teamSlot = teamSlots[idx];
          final isBye = teamSlot['isBye'] == true;

          return IgnorePointer(
            ignoring: !isOwner || widget.scheduleProvider.schedule!['state'] != 2,
            child: DragTarget<int>(
              onWillAcceptWithDetails: (d) => d.data != idx,
              onAcceptWithDetails: (d) => _onDragAccept(d.data, idx),
              builder: (ctx, candidate, __) {
                final highlight = candidate.isNotEmpty;
                return Container(
                  color: highlight
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : null,
                  child: LongPressDraggable<int>(
                    data: idx,
                    onDragStarted: () => HapticFeedback.mediumImpact(),
                    feedback: Material(
                      elevation: 8,
                      color: Colors.transparent,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 60.w,
                        child: isBye
                            ? _buildByeTeamCard(theme, teamSlot, isDragging: true)
                            : _buildTeamCard(theme, teamSlot, isDragging: true),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: isBye
                          ? _buildByeTeamCard(theme, teamSlot)
                          : _buildTeamCard(theme, teamSlot),
                    ),
                    child: isBye
                        ? _buildByeTeamCard(theme, teamSlot)
                        : _buildTeamCard(theme, teamSlot),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamCard(ThemeData theme, Map<String, dynamic> team, {bool isDragging = false}) {
    final members = team['members'] as List<dynamic>;
    final memberNames = <String>[
      for (var m in members) m['nickName'] ?? m['name'] ?? ''
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: isDragging
            ? [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.2),
            blurRadius: 8,
          )
        ]
            : [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            // 시드 번호
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${team['memberIndex']}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // 프로필
            if (team['profileImage'] != null && team['profileImage'] != '')
              NadalProfileFrame(imageUrl: team['profileImage'], size: 44.r)
            else
              CircleAvatar(
                radius: 22.r,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.groups_rounded,
                  color: theme.colorScheme.primary,
                  size: 24.r,
                ),
              ),

            SizedBox(width: 12.w),

            // 팀 이름 & 멤버
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team['teamName'] ?? '알 수 없는 팀',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
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

  Widget _buildByeTeamCard(ThemeData theme, Map<String, dynamic> teamSlot, {bool isDragging = false}) {
    final opponent = teamSlot['byeOpponent'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
        boxShadow: isDragging
            ? [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.2),
            blurRadius: 8,
          )
        ]
            : [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            // 시드 번호
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${teamSlot['memberIndex']}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // 부전승 아이콘
            CircleAvatar(
              radius: 22.r,
              backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
              child: Icon(
                Icons.person_off_rounded,
                color: theme.colorScheme.error,
                size: 24.r,
              ),
            ),

            SizedBox(width: 12.w),

            // 부전승 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opponent != null
                        ? '${opponent['teamName'] ?? '알 수 없는 팀'} 부전승'
                        : '부전승',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (opponent != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      '상대 없음으로 자동 승리',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: matchups.map((pair) {
          final t1 = pair[0], t2 = pair[1];
          final win1 = isAutoWin(t1, t2);
          final win2 = isAutoWin(t2, t1);

          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
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
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildTournamentTeamCard(
                  theme,
                  teamSlots[t1],
                  isWinner: win1,
                  isTop: true,
                ),
                Divider(color: theme.dividerColor.withValues(alpha: 0.5), height: 1),
                _buildTournamentTeamCard(
                  theme,
                  teamSlots[t2],
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

  Widget _buildTournamentTeamCard(
      ThemeData theme,
      Map<String, dynamic> team, {
        required bool isWinner,
        required bool isTop,
      }) {
    final isBye = team['isBye'] == true;
    final opponent = team['byeOpponent'];

    return Container(
      height: 76.h,
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
          // 시드 번호
          Container(
            width: 30.r,
            height: 30.r,
            decoration: BoxDecoration(
              color: isBye
                  ? theme.colorScheme.error.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${team['memberIndex']}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isBye ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // 팀 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isBye
                      ? (opponent != null
                      ? '${opponent['teamName'] ?? '알 수 없는 팀'} 부전승'
                      : '부전승')
                      : (team['teamName'] ?? '알 수 없는 팀'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isBye ? theme.colorScheme.error : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isBye && opponent != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    '상대 없음으로 자동 승리',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                    ),
                  ),
                ] else if (!isBye && team['members'] != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    (team['members'] as List)
                        .map((m) => m['nickName'] ?? m['name'] ?? '')
                        .join(', '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          if (isWinner)
            Icon(Icons.emoji_events_rounded, color: theme.colorScheme.primary, size: 20.r),
          if (isBye)
            Icon(Icons.person_off_rounded, color: theme.colorScheme.error, size: 20.r),
        ],
      ),
    );
  }
}