import 'package:flutter/services.dart';

import '../../../../../manager/project/Import_Manager.dart';

class TournamentTeamReorderList extends StatefulWidget {
  const TournamentTeamReorderList({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;
  @override
  State<TournamentTeamReorderList> createState() => _TournamentTeamReorderListState();
}

class _TournamentTeamReorderListState extends State<TournamentTeamReorderList> {
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
    isOwner = widget.scheduleProvider.schedule?['uid'] == FirebaseAuth.instance.currentUser!.uid;
    _loadTeams();
  }

  void _loadTeams() {
    final allMembers = widget.scheduleProvider.getAllMembers();
    final teamsData = widget.scheduleProvider.teams;

    if (allMembers.isEmpty) return;

    // 모든 멤버가 memberIndex를 가지고 있는지 확인
    final hasAllIndexes = allMembers.values.every((member) =>
    member['memberIndex'] != null && member['memberIndex'] > 0);

    if (!hasAllIndexes) return;

    teamsList = [];

    if (teamsData != null && teamsData.isNotEmpty) {
      // 실제 팀 데이터에서 팀 리스트 구성
      teamsData.forEach((teamName, members) {
        if (members.isNotEmpty) {
          final firstMember = members[0];
          final memberIndex = firstMember['memberIndex'] ?? 0;
          final isWalkOverTeam = widget.scheduleProvider.isWalkOverMember(firstMember['uid']);

          teamsList.add({
            'teamName': teamName,
            'members': members,
            'memberIndex': memberIndex,
            'profileImage': firstMember['profileImage'] ?? '',
            'walkOver': isWalkOverTeam,
          });
        }
      });
    } else {
      // teams가 없는 경우 allMembers에서 팀 구성
      final Map<String, List<dynamic>> teamMap = {};

      allMembers.forEach((uid, memberData) {
        final String? teamName = memberData['teamName'];
        if (teamName != null && teamName.isNotEmpty) {
          teamMap.putIfAbsent(teamName, () => []).add(memberData);
        }
      });

      teamMap.forEach((teamName, members) {
        if (members.isNotEmpty) {
          final firstMember = members[0];
          final memberIndex = firstMember['memberIndex'] ?? 0;
          final isWalkOverTeam = widget.scheduleProvider.isWalkOverMember(firstMember['uid']);

          teamsList.add({
            'teamName': teamName,
            'members': members,
            'memberIndex': memberIndex,
            'profileImage': firstMember['profileImage'] ?? '',
            'walkOver': isWalkOverTeam,
          });
        }
      });
    }

    // 인덱스로 정렬
    teamsList.sort((a, b) => (a['memberIndex'] as int).compareTo(b['memberIndex'] as int));

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
    for (var i = 0; i < teamsList.length; i++) {
      if (teamsList[i]['memberIndex'] != (i + 1)) {
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

    for (int i = 0; i < teamsList.length; i += 2) {
      if (i + 1 < teamsList.length) {
        matchups.add([i, i + 1]);
      } else {
        matchups.add([i, -1]);
      }
    }

    return matchups;
  }

  bool isAutoWin(int team1Index, int team2Index) {
    if (team2Index == -1) return true;

    final team1IsWalkOver = teamsList[team1Index]['walkOver'] == true;
    final team2IsWalkOver = teamsList[team2Index]['walkOver'] == true;

    if (team1IsWalkOver && !team2IsWalkOver) return false;
    if (!team1IsWalkOver && team2IsWalkOver) return true;

    return false;
  }

  Future<void> _handleButtonPress() async {
    if (!mounted) return;

    HapticFeedback.mediumImpact();

    if (_isChanged) {
      final sm = ScaffoldMessenger.of(context);
      final res = await widget.scheduleProvider.updateTeamIndex(teamsList);

      // 팀 데이터 새로고침
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _loadTeams();
        }
      });

      if (res?.statusCode == 200) {
        _isChanged = false;
        if (mounted) {
          setState(() {});
        }
        sm.showSnackBar(
          const SnackBar(
            content: Text('성공적으로 팀 순서가 공개되었어요'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        sm.showSnackBar(
          SnackBar(
            content: const Text('팀 순서 공개에 실패했어요'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () {},
            ),
          ),
        );
      }
    } else {
      DialogManager.showBasicDialog(
          title: '해당 순서로 팀 게임을 만들게요',
          content: '게임을 만든 후에는 팀 순서 변경이 불가해요',
          confirmText: '네! 진행해주세요',
          cancelText: '음.. 잠시만요',
          onConfirm: () {
            widget.scheduleProvider.createGameTable();
          }
      );
    }
  }

  void _onDragAccept(int fromIndex, int toIndex) {
    if (fromIndex == toIndex || !mounted) return;

    final fromItem = teamsList.removeAt(fromIndex);
    teamsList.insert(toIndex, fromItem);
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
    if (teamsList.isEmpty) {
      _loadTeams();
      if (teamsList.isEmpty) {
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
                          ? '팀 순서가 변경되었습니다.\n완료 후 "순서 공개" 버튼을 클릭해주세요.'
                          : '팀 순서를 변경하려면 카드를 길게 누른 후 드래그하세요.',
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

  // 팀 리스트 뷰 (드래그 앤 드롭 기능)
  Widget _buildListView(ThemeData theme) {
    return Listener(
      onPointerMove: _pointListener,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: teamsList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          final team = teamsList[index];
          final isWalkOverTeam = team['walkOver'] == true;

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
                        child: _buildTeamCard(theme, team, isDragging: true),
                      ),
                    ),
                    childWhenDragging: Container(
                      height: 80,
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
                        _buildTeamCard(theme, team, isDragging: false),
                        if (!isWalkOverTeam)
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
                        : _buildTeamCard(theme, team, isDragging: false),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // 팀 카드 위젯
  Widget _buildTeamCard(ThemeData theme, Map<String, dynamic> team, {bool isDragging = false}) {
    final isWalkOverTeam = team['walkOver'] == true;
    final teamMembers = team['members'] as List<dynamic>;

    // 멤버 이름 목록 생성
    List<String> memberNames = [];
    if (!isWalkOverTeam && teamMembers.isNotEmpty) {
      for (var member in teamMembers) {
        final useNickname = member['birthYear'] == null;
        final displayName = useNickname ? member['nickName'] : member['name'];
        if (displayName != null) {
          memberNames.add(displayName);
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isWalkOverTeam
            ? theme.colorScheme.error.withValues(alpha: 0.1)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isWalkOverTeam
            ? Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3), width: 1)
            : null,
        boxShadow: isDragging
            ? [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ]
            : [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 시드 번호 또는 순서
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isWalkOverTeam
                    ? theme.colorScheme.error.withValues(alpha: 0.2)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                isWalkOverTeam ? '부' : '${team['memberIndex']}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isWalkOverTeam
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 프로필 이미지
            if (!isWalkOverTeam && team['profileImage'] != null && team['profileImage'] != '')
              NadalProfileFrame(imageUrl: team['profileImage'])
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWalkOverTeam
                      ? theme.colorScheme.error.withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Icon(
                    isWalkOverTeam ? Icons.person_off_rounded : Icons.groups_rounded,
                    color: isWalkOverTeam
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),

            const SizedBox(width: 12),

            // 팀 이름과 멤버 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 팀 이름
                  Text(
                    isWalkOverTeam ? '부전승' : team['teamName'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isWalkOverTeam ? theme.colorScheme.error : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 팀원 이름 (부전승이 아닌 경우)
                  if (!isWalkOverTeam && memberNames.isNotEmpty)
                    Text(
                      memberNames.join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 토너먼트 대진표 뷰
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
                    '이 대진표는 현재 설정된 팀 순서로 토너먼트가\n진행되면 생성될 예상 구도입니다.\n실제 대진표는 게임 시작 후 확인할 수 있습니다.',
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
            final team1Index = matchup[0];
            final team2Index = matchup[1];
            final hasBothTeams = team2Index != -1;
            final team1WinsAuto = hasBothTeams && isAutoWin(team1Index, team2Index);
            final team2WinsAuto = hasBothTeams && isAutoWin(team2Index, team1Index);

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
                  _buildTournamentTeamCard(
                    theme,
                    teamsList[team1Index],
                    isWinner: team1WinsAuto,
                    showMatchBorders: hasBothTeams,
                    isTop: true,
                  ),

                  if (hasBothTeams)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),

                  if (hasBothTeams)
                    _buildTournamentTeamCard(
                      theme,
                      teamsList[team2Index],
                      isWinner: team2WinsAuto,
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

  // 토너먼트 대진표의 팀 카드
  Widget _buildTournamentTeamCard(
      ThemeData theme,
      Map<String, dynamic> team,
      {bool isWinner = false,
        bool showMatchBorders = true,
        bool isTop = true}
      ) {
    final isWalkOverTeam = team['walkOver'] == true;
    final teamMembers = team['members'] as List<dynamic>;

    // 멤버 이름 목록 생성
    List<String> memberNames = [];
    if (!isWalkOverTeam && teamMembers.isNotEmpty) {
      for (var member in teamMembers) {
        final useNickname = member['birthYear'] == null;
        final displayName = useNickname ? member['nickName'] : member['name'];
        if (displayName != null) {
          memberNames.add(displayName);
        }
      }
    }

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isWinner
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : isWalkOverTeam
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
          // 시드 넘버 또는 부전승 표시
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isWalkOverTeam
                  ? theme.colorScheme.error.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              isWalkOverTeam ? '부' : '${team['memberIndex']}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isWalkOverTeam
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 팀 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isWalkOverTeam ? '부전승' : (team['teamName'] ?? '팀 ${team['memberIndex']}'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isWalkOverTeam
                        ? theme.colorScheme.error
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isWalkOverTeam && memberNames.isNotEmpty)
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

          // 승리 또는 부전승 아이콘
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
          else if (isWalkOverTeam)
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
}