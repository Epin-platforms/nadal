import 'package:flutter/services.dart';
import 'package:my_sports_calendar/provider/game/Game_Provider.dart';
import 'package:my_sports_calendar/screen/schedule/game/state2/widget/Nadal_Solo_Card.dart';

import '../../../../../manager/project/Import_Manager.dart';

class NadalKDKReorderList extends StatefulWidget {
  const NadalKDKReorderList({super.key, required this.gameProvider});
  final GameProvider gameProvider;
  @override
  State<NadalKDKReorderList> createState() => _NadalKDKReorderListState();
}

class _NadalKDKReorderListState extends State<NadalKDKReorderList> with SingleTickerProviderStateMixin {
  bool isOwner = false;
  final ScrollController _scrollController = ScrollController();
  List members = [];
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

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
      members = widget.gameProvider.scheduleProvider.scheduleMembers!.entries.map((e) => e.value).toList();
      members.sort((a, b) => a['memberIndex'].compareTo(b['memberIndex']));
      setState(() {});

      // 주기적으로 버튼 애니메이션 실행 (중요한 버튼임을 강조)
      if (isOwner) {
        Future.delayed(const Duration(seconds: 1), () {
          _startButtonPulse();
        });
      }
    });
    super.initState();
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

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
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
        if (isOwner)
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

        // 멤버 목록
        Expanded(
          child: Listener(
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
                    ignoring: !isOwner && widget.gameProvider.scheduleProvider.schedule!['state'] != 2,
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
          ),
        ),

        const SizedBox(height: 16),

        // 하단 버튼
        if (isOwner)
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
                        SnackBarManager.showCleanSnackBar(context, '성공적으로 순서공개가 되었어요');
                      }else{
                        SnackBarManager.showCleanSnackBar(context, '순서공개에 실패했어요', icon: Icons.warning_amber);
                      }
                    } else {
                      DialogManager.showBasicDialog(title: '해당 순서로 게임을 만들게요', content: '게임을 만든 후에는 순서 변경이 불가해요',
                          confirmText: '네! 진행해주세요', onConfirm: ()=> widget.gameProvider.createGameTable(), cancelText: '음.. 잠시만요');
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
}