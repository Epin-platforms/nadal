import 'package:flutter/services.dart';
import 'package:my_sports_calendar/manager/game/Game_Manager.dart';
import 'package:my_sports_calendar/widget/Nadal_Dot.dart';
import '../../manager/project/Import_Manager.dart';

class ScheduleMain extends StatefulWidget {
  const ScheduleMain({
    super.key,
    required this.commentProvider,
    required this.provider,
    required this.userProvider
  });

  final CommentProvider commentProvider;
  final ScheduleProvider provider;
  final UserProvider userProvider;

  @override
  State<ScheduleMain> createState() => _ScheduleMainState();
}

class _ScheduleMainState extends State<ScheduleMain> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.provider.schedule;

    // 안전성 체크
    if (post == null) {
      return const Center(
        child: Text('스케줄 정보를 불러올 수 없습니다.'),
      );
    }

    final bool hasAddress = post['address'] != null && post['address'].toString().isNotEmpty;
    final bool hasAccount = post['accountId'] != null;
    final bool hasParticipation = post['useParticipation'] == 1;
    final primaryColor = theme.colorScheme.primary;
    final currentUserId = widget.userProvider.user?['uid'];

    // 내 참가 상태 확인
    String myParticipationStatus = '불참';
    Color participationColor = theme.hintColor;

    if (currentUserId != null && widget.provider.scheduleMembers != null) {
      final memberData = widget.provider.scheduleMembers![currentUserId];
      if (memberData != null) {
        if (memberData['approval'] == 1) {
          myParticipationStatus = '참가중';
          participationColor = ThemeManager.successColor;
        } else {
          myParticipationStatus = '거절됨';
          participationColor = ThemeManager.warningColor;
        }
      }
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 섹션
                _buildHeaderSection(theme, post, primaryColor),

                const SizedBox(height: 8),

                // 일정 정보 카드
                _buildScheduleInfoCard(theme, post, primaryColor),

                // 계좌 정보 카드
                if (hasAccount) ...[
                  const SizedBox(height: 8),
                  _buildAccountInfoCard(theme, post),
                ],

                // 참가자 정보 카드
                if (hasParticipation) ...[
                  const SizedBox(height: 8),
                  _buildParticipantsCard(theme, myParticipationStatus, participationColor),
                ],

                const SizedBox(height: 16),
                _buildCommentSection(theme),
              ],
            ),
          ),
        ),

        // 댓글 입력창
        _buildCommentInputCard(theme),
      ],
    );
  }

  Widget _buildHeaderSection(ThemeData theme, Map<String, dynamic> post, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 작성자 정보 행
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 프로필 및 이름
                  GestureDetector(
                    onTap: ()=> context.push('/user/${post['uid']}'),
                    child: Row(
                      children: [
                        NadalProfileFrame(
                          imageUrl: post['profileImage'],
                          size: 42.r,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TextFormManager.profileText(
                                post['nickName'],
                                post['name'],
                                post['birthYear'],
                                post['gender'],
                                useNickname: post['name'] == null,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15.sp,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              TextFormManager.timeAgo(item: post['createAt']),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.hintColor,
                                height: 1,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 태그
                  if (post['tag'] != null)
                    NadalScheduleTag(
                      tag: post['tag'],
                      fontSize: 13.r,
                    ),
                ],
              ),

              SizedBox(height: 16.h),
              // 제목
              Text(
                post['title'] ?? '제목 없음',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              // 방 이름 정보 (제목 바로 아래에 위치)
              if (post['roomName'] != null && post['roomName'].toString().isNotEmpty) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.meeting_room_rounded,
                        size: 16.r,
                        color: theme.colorScheme.secondary.withValues(alpha: 0.8),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${post['roomName']} 방',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 설명
              if (post['description'] != null && post['description'].toString().isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  post['description'],
                  style: TextStyle(
                    fontSize: 15.5.sp,
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleInfoCard(ThemeData theme, Map<String, dynamic> post, Color primaryColor) {
    return _buildInfoCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Text(
            '일정 정보',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          // 일정 시간
          _buildInfoRow(
            icon: Icons.watch_later_rounded,
            iconColor: primaryColor,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TextFormManager.fromToDate(
                    post['startDate'],
                    post['endDate'],
                    isAllDay: post['isAllDay'] == 1,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (post['isAllDay'] == 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    '하루 종일',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: primaryColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 게임 진행 정보 (게임 태그인 경우)
          if (post['tag'] == "게임") ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: BootstrapIcons.trophy_fill,
              iconColor: theme.colorScheme.secondary,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '게임 진행',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        post['isKDK'] == 1 ? '대진' : '토너먼트',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      NadalDot(color: theme.hintColor),
                      Text(
                        post['isSingle'] == 1 ? '단식' : '복식',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],

          // 장소 정보
          if (post['address'] != null && post['address'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.location_on_rounded,
              iconColor: Colors.redAccent,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post['address'].toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          _copyText(post['address'].toString());
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            BootstrapIcons.copy,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (post['addressDetail'] != null &&
                      post['addressDetail'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      post['addressDetail'].toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(ThemeData theme, Map<String, dynamic> post) {
    return _buildInfoCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '참가비 계좌',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        ListPackage.banks[post['bank']]!['logo'],
                        height: 30,
                        width: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '(${ListPackage.banks[post['bank']]!['type'] == 1 ? '증권사' : '은행'})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post['bank'].toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              post['account'].toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                _copyText(post['account'].toString());
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  BootstrapIcons.copy,
                                  size: 13,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '예금주',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post['accountName'].toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(ThemeData theme, String myParticipationStatus, Color participationColor) {
    final approvedCount = widget.provider.scheduleMembers?.values
        .where((member) => member['approval'] == 1).length ?? 0;
    final teamCount = widget.provider.teams?.entries.where((entry) {
      // 팀에서 승인된 멤버가 있는지 확인
      return entry.value.any((member) => member['approval'] == 1);
    }).length ?? 0;
    final isTeamGame = widget.provider.isTeamGame;

    return _buildInfoCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '참가자',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: participationColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        color: participationColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      myParticipationStatus,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: participationColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Flexible(
                flex: 3,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/schedule/${widget.provider.schedule!['scheduleId']}/participation');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 46.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 18.r,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          isTeamGame
                              ? '참가팀($teamCount) 보기'
                              : '참가자($approvedCount) 보기',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 게임 모집 종료 버튼 (게임 소유자이고 모집 중일 때만)
              if (widget.provider.schedule!['tag'] == "게임" &&
                  widget.provider.schedule!['state'] == 0 &&
                  widget.provider.isOwner) ...[
                    SizedBox(width: 10.w),
                Flexible(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _showEndRecruitmentDialog(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 46.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 18.r,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '모집 종료',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showEndRecruitmentDialog() {
    HapticFeedback.mediumImpact();

    DialogManager.showBasicDialog(
      title: '모집을 종료하시겠어요?',
      content: '모집을 종료하면 이후에는\n참가 신청을 받을 수 없어요.',
      confirmText: '모집 종료',
      onConfirm: () async{
        await widget.provider.updateMembers();
        final gameType = widget.provider.gameType;
        final memberCount = widget.provider.scheduleMembers?.entries.where((e)=> e.value['approval'] == 1).length ?? 0;
        final teamCount = widget.provider.teams?.entries.where((entry) {
          // 팀에서 승인된 멤버가 있는지 확인
          return entry.value.any((member) => member['approval'] == 1);
        }).length ?? 0;

        // 게임 타입에 따른 인원 검증
        String? errorMessage;
        switch (gameType) {
          case GameType.kdkSingle:
            if (memberCount < GameManager.min_kdk_single_member ||
                memberCount > GameManager.max_kdk_single_member) {
              errorMessage = '게임은 ${GameManager.min_kdk_single_member}~${GameManager.max_kdk_single_member}명\n사이에서만 시작할 수 있어요.';
            }
            break;
          case GameType.kdkDouble:
            if (memberCount < GameManager.min_kdk_double_member ||
                memberCount > GameManager.max_kdk_double_member) {
              errorMessage = '게임은 ${GameManager.min_kdk_double_member}~${GameManager.max_kdk_double_member}명\n사이에서만 시작할 수 있어요.';
            }
            break;
          case GameType.tourSingle:
            if (memberCount < GameManager.min_tour_single_member ||
                memberCount > GameManager.max_tour_single_member) {
              errorMessage = '게임은 ${GameManager.min_tour_single_member}~${GameManager.max_tour_single_member}명\n사이에서만 시작할 수 있어요.';
            }
            break;
          case GameType.tourDouble:
            if (teamCount < GameManager.min_tour_double_member ||
                teamCount > GameManager.max_tour_double_member) {
              errorMessage = '게임은 ${GameManager.min_tour_double_member}~${GameManager.max_tour_double_member}팀\n사이에서만 시작할 수 있어요.';
            }
            break;
          default:
            break;
        }

        if (errorMessage != null) {
          DialogManager.showBasicDialog(
            title: '참가 인원이 부족하거나 많아요',
            content: errorMessage,
            confirmText: '알겠어요',
          );
          return;
        }

        // 모집 종료 (상태를 1로 변경)
        widget.provider.changeGameState(1);
      },
      cancelText: '아직 더 모집할래요',
    );
  }

  // 댓글 섹션 위젯
  Widget _buildCommentSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '댓글',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.commentProvider.topLevelComments.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.commentProvider.topLevelComments.length >= 3)
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                        if (_isExpanded) {
                          _animationController.forward();
                        } else {
                          _animationController.reverse();
                        }
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Text(
                            _isExpanded ? '접기' : '모두 보기',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          RotationTransition(
                            turns: Tween(begin: 0.0, end: 0.5).animate(_animationController),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 댓글 목록
          widget.commentProvider.topLevelComments.isNotEmpty
              ? AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _isExpanded
                        ? widget.commentProvider.topLevelComments.length
                        : widget.commentProvider.topLevelComments.length > 2
                        ? 2
                        : widget.commentProvider.topLevelComments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.commentProvider.topLevelComments[index];
                      final commentId = comment['commentId'];
                      final replies = widget.commentProvider.replyMap[commentId] ?? [];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 원댓글
                            NadalCommentTile(
                              comment: comment,
                              isReply: false,
                              provider: widget.commentProvider,
                            ),

                            // 대댓글
                            if (replies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 36),
                                child: Column(
                                  children: replies.map((reply) {
                                    return NadalCommentTile(
                                      comment: reply,
                                      isReply: true,
                                      provider: widget.commentProvider,
                                    );
                                  }).toList(),
                                ),
                              ),

                            if (index < widget.commentProvider.topLevelComments.length - 1)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // 더보기 버튼 (댓글이 2개 이상이고 전체 표시가 아닐 때만)
                  if (!_isExpanded && widget.commentProvider.topLevelComments.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = true;
                            _animationController.forward();
                          });
                          HapticFeedback.lightImpact();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '댓글 더보기',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
              : SizedBox(
            height: 180,
            child: NadalEmptyList(
              title: '아직 댓글이 없어요',
              subtitle: '가장 먼저 이 일정에 응답해보세요',
            ),
          ),
        ],
      ),
    );
  }

  // 댓글 입력 카드
  Widget _buildCommentInputCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: CommentField(
          provider: widget.commentProvider,
          scrollController: _scrollController,
        ),
      ),
    );
  }

  // 정보 카드 위젯
  Widget _buildInfoCard({required ThemeData theme, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // 정보 행 위젯 (아이콘 + 내용)
  Widget _buildInfoRow({
    required IconData icon,
    required Widget content,
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: content),
      ],
    );
  }
}