import 'package:flutter/services.dart';
import 'package:my_sports_calendar/provider/game/Game_Provider.dart';

import '../../../../../manager/project/Import_Manager.dart';
import '../widget/Nadal_Solo_Card.dart';

class TournamentReorderList extends StatefulWidget {
  const TournamentReorderList({super.key, required this.gameProvider});
  final GameProvider gameProvider;

  @override
  State<TournamentReorderList> createState() => _TournamentReorderListState();
}

class _TournamentReorderListState extends State<TournamentReorderList> with SingleTickerProviderStateMixin{
  bool isOwner = false;
  final ScrollController _scrollController = ScrollController();
  List members = [];
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
      isOwner = widget.gameProvider.scheduleProvider.schedule?['uid'] == FirebaseAuth.instance.currentUser!.uid;
      initializeMembers();

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
    // TODO: implement dispose
    super.dispose();
  }

  void initializeMembers() {
    // 1. 원본 멤버 데이터 가져오기
    final originalMembers = widget.gameProvider.scheduleProvider.scheduleMembers!.entries
        .map((e) => e.value)
        .toList();

    // 2. 모든 memberIndex 값을 찾기
    final List<int> memberIndices = originalMembers
        .map<int>((member) => member['memberIndex'] as int)
        .toList();

    // 3. 최대 인덱스 찾기
    final int maxIndex = memberIndices.reduce((value, element) => value > element ? value : element);

    // 4. 빈 인덱스를 채운 새 리스트 생성 (크기는 최대 인덱스 + 1)
    final filledMembers = List<Map<String, dynamic>?>.filled(maxIndex + 1, null);

    // 5. 원본 멤버들을 해당 인덱스 위치에 배치
    for (var member in originalMembers) {
      final index = member['memberIndex'] as int;
      filledMembers[index] = member;
    }

    // 6. null 값을 가진 인덱스에 부전승 표시 멤버 생성
    // (인덱스 0은 일반적으로 사용하지 않는 경우 건너뛰기)
    for (int i = 1; i <= maxIndex; i++) {
      if (filledMembers[i] == null) {
        filledMembers[i] = {
          'memberIndex' : i,
          'uid' : 'walk_over_$i'
        };
      }
    }

    // 7. null 값 제거하고 최종 멤버 리스트 생성
    members = filledMembers.where((member) => member != null).toList().cast<Map<String, dynamic>>();

    // 멤버 인덱스로 정렬
    members.sort((a, b) => (a['memberIndex'] as int).compareTo(b['memberIndex'] as int));

    setState(() {}); // UI 업데이트
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
    for (var i = 0; i < members.length; i++) {
      if (members[i]['memberIndex'] != (i + 1)) {
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

  // 부전승 여부 확인
  bool isWalkOver(Map<String, dynamic> member) {
    return member['uid'].toString().startsWith('walk_over_');
  }

  // 토너먼트에서 매치업 계산
  List<List<int>> calculateTournamentMatchups() {
    List<List<int>> matchups = [];

    for (int i = 0; i < members.length; i += 2) {
      if (i + 1 < members.length) {
        matchups.add([i, i + 1]);
      } else {
        // 홀수인 경우 마지막 선수는 단독 배치
        matchups.add([i, -1]);
      }
    }

    return matchups;
  }

  // 부전승 자동 승리 체크
  bool isAutoWin(int player1Index, int player2Index) {
    // 두 번째 선수가 없는 경우 (홀수 인원)
    if (player2Index == -1) return true;

    bool player1IsWalkOver = isWalkOver(members[player1Index]);
    bool player2IsWalkOver = isWalkOver(members[player2Index]);

    // 부전승 vs 일반 선수
    if (player1IsWalkOver && !player2IsWalkOver) return false; // 2번 선수 승리
    if (!player1IsWalkOver && player2IsWalkOver) return true;  // 1번 선수 승리

    // 둘 다 부전승인 경우 (이런 경우는 피해야 함)
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.gameProvider.scheduleProvider.scheduleMembers!.values.where((e) => e['memberIndex'] == null).isNotEmpty) {
      return const Center(
        child: NadalCircular(),
      );
    }

    return Column(
      children: [
        // 상태 표시
        if (isOwner && widget.gameProvider.scheduleProvider.schedule!['state'] == 2)
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
        if (isOwner && widget.gameProvider.scheduleProvider.schedule!['state'] == 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ScaleTransition(
              scale: _buttonScaleAnimation,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async{
                    HapticFeedback.mediumImpact();
                    if (_isChanged) {
                      final res = await widget.gameProvider.updateMemberIndex(members);
                      if(res.statusCode == 200){
                        setState(() {
                          _isChanged = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('성공적으로 순서공개가 되었어요'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }else{
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('순서공개에 실패했어요'),
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
                          title: Text('해당 순서로 게임을 만들게요'),
                          content: Text('게임을 만든 후에는 순서 변경이 불가해요'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('음.. 잠시만요'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.gameProvider.createGameTable();
                              },
                              child: Text('네! 진행해주세요'),
                            ),
                          ],
                        ),
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
          ),
      ],
    );
  }

  // 원래 리스트 뷰 (드래그 앤 드롭 기능을 가진)
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
          itemCount: members.length,
          separatorBuilder: (context, index) => SizedBox(height: 2,),
          itemBuilder: (context, index) {
            return IgnorePointer(
              ignoring: !isOwner || widget.gameProvider.scheduleProvider.schedule!['state'] != 2,
              child: DragTarget<int>(
                onWillAcceptWithDetails: (details) => details.data != index,
                onAcceptWithDetails: (details) {
                  setState(() {
                    final fromIndex = details.data;
                    final fromItem = members.removeAt(fromIndex);
                    members.insert(index, fromItem);
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
                          child: NadalSoloCard(
                            isDragging: true,
                            user: members[index],
                            index: index,
                          ),
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
                          NadalSoloCard(
                            isDragging: false,
                            user: members[index],
                            index: index,
                          ),
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
                          : NadalSoloCard(
                        isDragging: false,
                        user: members[index],
                        index: index,
                      ),
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
            // 매치업의 두 선수 인덱스
            final player1Index = matchup[0];
            final player2Index = matchup[1];

            // 두 번째 선수가 없는 경우 (홀수일 때 마지막 선수)
            final hasBothPlayers = player2Index != -1;

            // 부전승 승리 여부
            final player1WinsAuto = hasBothPlayers && isWalkOver(members[player2Index]);
            final player2WinsAuto = hasBothPlayers && isWalkOver(members[player1Index]);

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
                  // 첫 번째 선수
                  _buildTournamentPlayerCard(
                    theme,
                    members[player1Index],
                    isWinner: player1WinsAuto,
                    showMatchBorders: hasBothPlayers,
                    isTop: true,
                  ),

                  // 구분선
                  if (hasBothPlayers)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),

                  // 두 번째 선수 (있는 경우)
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
    final bool isWalkOverPlayer = isWalkOver(player);

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
          top: isTop ? Radius.circular(16) : Radius.zero,
          bottom: isTop ? Radius.zero : Radius.circular(16),
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

          // 선수 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isWalkOverPlayer ? '부전승' : (player['name'] ?? player['nickName'] ?? '선수 ${player['memberIndex']}'),
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
}