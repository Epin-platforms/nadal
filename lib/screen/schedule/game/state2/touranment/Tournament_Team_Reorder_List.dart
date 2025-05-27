import 'package:flutter/services.dart';

import '../../../../../manager/project/Import_Manager.dart';

class TournamentTeamReorderList extends StatefulWidget {
  const TournamentTeamReorderList({super.key,required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;
  @override
  State<TournamentTeamReorderList> createState() => _TournamentTeamReorderListState();
}

class _TournamentTeamReorderListState extends State<TournamentTeamReorderList> with SingleTickerProviderStateMixin {
  bool isOwner = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> teamsList = [];
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  bool _showTournamentView = false; // 토너먼트 보기 모드 토글

  @override
  void initState() {
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isOwner = widget.scheduleProvider.schedule?['uid'] == FirebaseAuth.instance.currentUser!.uid;
      initializeTeams();

      // 주기적으로 버튼 애니메이션 실행 (중요한 버튼임을 강조)
      if (isOwner) {
        Future.delayed(const Duration(seconds: 1), () {
          _startButtonPulse();
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void initializeTeams() {
    if (widget.scheduleProvider.teams == null) {
      return;
    }

    final Map<String, List<dynamic>> teamsData = widget.scheduleProvider.teams!;
    teamsList = [];

    // 각 팀 데이터 구성
    teamsData.forEach((teamName, members) {
      if (members.isNotEmpty) {
        // 첫 번째 멤버에서 인덱스 가져오기 (팀원들은 모두 같은 인덱스를 가짐)
        final firstMember = members[0];
        final memberIndex = firstMember['memberIndex'] ?? 0;

        teamsList.add({
          'teamName': teamName,
          'members': members,
          'memberIndex': memberIndex,
          'profileImage': firstMember['profileImage'] ?? '',
          'walkOver': false,
        });
      }
    });

    // 인덱스로 정렬
    teamsList.sort((a, b) => (a['memberIndex'] as int).compareTo(b['memberIndex'] as int));

    // 최대 인덱스 찾기
    int maxIndex = 0;
    for (var team in teamsList) {
      if (team['memberIndex'] > maxIndex) {
        maxIndex = team['memberIndex'];
      }
    }

    // 부전승 처리 - 빈 인덱스 채우기
    Set<int> usedIndices = teamsList.map((team) => team['memberIndex'] as int).toSet();

    for (int i = 1; i <= maxIndex; i++) {
      if (!usedIndices.contains(i)) {
        teamsList.add({
          'teamName': '부전승 $i',
          'members': <Map<String, dynamic>>[],
          'memberIndex': i,
          'walkOver': true,
        });
      }
    }

    // 인덱스로 다시 정렬
    teamsList.sort((a, b) => (a['memberIndex'] as int).compareTo(b['memberIndex'] as int));

    setState(() {});
  }

  void _startButtonPulse() {
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse().then((_) {
        if (mounted && _isChanged) {
          Future.delayed(const Duration(seconds: 2), () {
            _startButtonPulse();
          });
        }
      });
    });
  }

  bool _isChanged = false;

  _pointListener(event) {
    final pos = event.position;
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(pos);

    const threshold = 120; // 스크롤 영역 확장
    const speed = 15.0; // 스크롤 속도 증가
    if (local.dy < threshold) {
      final factor = 1.0 - (local.dy / threshold); // 위치에 따른 가속도
      _scrollController.jumpTo(_scrollController.offset - (speed * factor));
    } else if (local.dy > box.size.height - threshold) {
      final factor = (local.dy - (box.size.height - threshold)) / threshold;
      _scrollController.jumpTo(_scrollController.offset + (speed * factor));
    }
  }

  void _changedCheck() {
    bool changed = false;
    for (var i = 0; i < teamsList.length; i++) {
      if (teamsList[i]['memberIndex'] != (i + 1)) {
        changed = true;
        break;
      }
    }

    if (changed != _isChanged) {
      setState(() {
        _isChanged = changed;
      });

      if (_isChanged) {
        HapticFeedback.mediumImpact(); // 변경 감지 시 햅틱 피드백
        _startButtonPulse(); // 변경되었을 때 애니메이션 시작
      }
    }
  }

  // 토너먼트에서 매치업 계산
  List<List<int>> calculateTournamentMatchups() {
    List<List<int>> matchups = [];

    for (int i = 0; i < teamsList.length; i += 2) {
      if (i + 1 < teamsList.length) {
        matchups.add([i, i + 1]);
      } else {
        // 홀수인 경우 마지막 팀은 단독 배치
        matchups.add([i, -1]);
      }
    }

    return matchups;
  }

  // 부전승 자동 승리 체크
  bool isAutoWin(int team1Index, int team2Index) {
    // 두 번째 팀이 없는 경우 (홀수 인원)
    if (team2Index == -1) return true;

    bool team1IsWalkOver = teamsList[team1Index]['walkOver'] == true;
    bool team2IsWalkOver = teamsList[team2Index]['walkOver'] == true;

    // 부전승 vs 일반 팀
    if (team1IsWalkOver && !team2IsWalkOver) return false; // 2번 팀 승리
    if (!team1IsWalkOver && team2IsWalkOver) return true;  // 1번 팀 승리

    // 둘 다 부전승인 경우
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (teamsList.isEmpty) {
      return const Center(
        child: NadalCircular(),
      );
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
                    setState(() {
                      _showTournamentView = !_showTournamentView;
                    });
                    HapticFeedback.lightImpact();
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
            child: ScaleTransition(
              scale: _buttonScaleAnimation,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {

                    HapticFeedback.mediumImpact();
                    if (_isChanged) {
                      final sm = ScaffoldMessenger.of(context);
                      final res = await widget.scheduleProvider.updateTeamIndex(teamsList);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        initializeTeams();
                      });

                      if (res?.statusCode == 200) {
                        setState(() {
                          _isChanged = false;
                        });
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
                          onConfirm: (){
                            widget.scheduleProvider.createGameTable();
                          }
                      );
                    }
                  },
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
          ),
      ],
    );
  }

  // 팀 리스트 뷰 (드래그 앤 드롭 기능)
  Widget _buildListView(ThemeData theme) {
    return Listener(
      onPointerMove: (event) {
        if (isOwner) {
          _pointListener(event);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: teamsList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            return IgnorePointer(
              ignoring: !isOwner || widget.scheduleProvider.schedule!['state'] != 2,
              child: DragTarget<int>(
                onWillAcceptWithDetails: (details) => details.data != index,
                onAcceptWithDetails: (details) {
                  setState(() {
                    final fromIndex = details.data;
                    final fromItem = teamsList.removeAt(fromIndex);
                    teamsList.insert(index, fromItem);
                    _changedCheck();
                  });

                  // 드래그 완료 시 햅틱 피드백
                  HapticFeedback.lightImpact();
                },
                builder: (context, candidateData, rejectedData) {
                  final isDragTarget = candidateData.isNotEmpty;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isDragTarget
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                    ),
                    child: LongPressDraggable<int>(
                      data: index,
                      onDragStarted: () {
                        // 드래그 시작 시 햅틱 피드백
                        HapticFeedback.mediumImpact();
                      },
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
                          child: _buildTeamCard(
                            theme,
                            teamsList[index],
                            isDragging: true,
                          ),
                        ),
                      ),
                      childWhenDragging: Container(
                        height: 80, // 팀 카드는 좀 더 높게
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            width: 1,
                            style: BorderStyle.solid,
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
                          _buildTeamCard(theme, teamsList[index], isDragging: false),
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
                          : _buildTeamCard(theme, teamsList[index], isDragging: false),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // 팀 카드 위젯
  Widget _buildTeamCard(ThemeData theme, Map<String, dynamic> team, {bool isDragging = false}) {
    final bool isWalkOverTeam = team['walkOver'] == true;
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
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
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
            // 매치업의 두 팀 인덱스
            final team1Index = matchup[0];
            final team2Index = matchup[1];

            // 두 번째 팀이 없는 경우 (홀수일 때 마지막 팀)
            final hasBothTeams = team2Index != -1;

            // 부전승 승리 여부
            final team1WinsAuto = hasBothTeams && teamsList[team2Index]['walkOver'] == true;
            final team2WinsAuto = hasBothTeams && teamsList[team1Index]['walkOver'] == true;

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
                  // 첫 번째 팀
                  _buildTournamentTeamCard(
                    theme,
                    teamsList[team1Index],
                    isWinner: team1WinsAuto,
                    showMatchBorders: hasBothTeams,
                    isTop: true,
                  ),

                  // 구분선
                  if (hasBothTeams)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),

                  // 두 번째 팀 (있는 경우)
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
    final bool isWalkOverTeam = team['walkOver'] == true;
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