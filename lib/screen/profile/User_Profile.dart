import 'package:animate_do/animate_do.dart';
import 'package:my_sports_calendar/provider/profile/User_Profile_Provider.dart';

import '../../manager/project/Import_Manager.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> with SingleTickerProviderStateMixin{
  late UserProfileProvider provider;
  late ScrollController _scrollController;
  
  @override
  void initState() {
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _scrollController.addListener((){
        if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100){
          provider.fetchGames();
        }
      });
    });
    super.initState();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    provider = Provider.of<UserProfileProvider>(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    if(provider.user == null){
      return GestureDetector(
        onTap: ()=> context.pop(),
        child: Material(
          child: Center(
            child: NadalCircular(),
          ),
        ),
      );
    }

    if (provider.user!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pop();
        DialogManager.showBasicDialog(
          title: '올바르지 않은 사용자입니다',
          content: '확인 후 다시 시도해주세요',
          confirmText: '확인',
        );
      });
      return const Material(); // 빈 위젯 반환
    }

    final bool isMe = provider.uid == FirebaseAuth.instance.currentUser!.uid;

    return IosPopGesture(
        child: Scaffold(
          body: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled){
                return [
                  SliverAppBar(
                    expandedHeight: 320.h,
                    floating: false,
                    pinned: true,
                    backgroundColor: theme.cardColor,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    actions: [
                      if(!isMe)...[
                        NadalReportIcon(
                          onTap: (){
                            context.push('/report?targetId=${provider.user!['uid']}&type=user');
                          },
                        ),
                        SizedBox(width: 4.w,)
                      ]
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildProfileHeader(theme, textTheme, isMe),
                    ),
                  ),
                ];
              },

              body: _buildPostsTab(),
          ),
        )
    );
  }

  Widget _buildProfileHeader(ThemeData theme, TextTheme textTheme, bool isMe) {
    return Container(
      height: 300.h,
      decoration: BoxDecoration(
        gradient: ThemeManager.violetGradient,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 15.h),
            // 프로필 이미지
            FadeInDown(
              duration: Duration(milliseconds: 500),
              child: Hero(
                tag: 'profile-${provider.user!['uid']}',
                child: NadalProfileFrame(
                  size: 80.r,
                  imageUrl: provider.user!['profileImage'],
                )
              ),
            ),

            SizedBox(height: 10.h),

            // 사용자 이름
            FadeInUp(
              duration: Duration(milliseconds: 500),
              delay: Duration(milliseconds: 100),
              child: Text(
                provider.user!['nickName'],
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 사용자 아이디
            FadeInUp(
              duration: Duration(milliseconds: 500),
              delay: Duration(milliseconds: 150),
              child: Text(
                provider.user!['affiliationName'] ?? '무소속',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),

            SizedBox(height: 5.h),

            _buildProfileStatsRow(theme, textTheme),

            if(!isMe)...[
              SizedBox(height: 16.h),
              _buildActionButtonsRow(theme, textTheme)
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStatsRow(ThemeData theme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem('경기수', provider.user!['gameCount'].toString(), theme, textTheme),
        SizedBox(width: 15.w),
        _buildStatItem('팔로워', provider.user!['follower'].toString(), theme, textTheme),
        SizedBox(width: 15.w),
        _buildStatItem('팔로잉', provider.user!['following'].toString(), theme, textTheme),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsRow(ThemeData theme, TextTheme textTheme) {
    final isFollowing = provider.isFollow;

    if(isFollowing == null){
      return Container();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            provider.onChangedFollow(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:  isFollowing ? theme.primaryColor : theme.colorScheme.tertiary,
            foregroundColor: isFollowing ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surfaceContainerLowest,
            minimumSize: Size(ScreenUtil.defaultSize.width, 43.h),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child:
          provider.followLoading ?
              NadalCircular(
                size: 18.r,
              ) :
          Text(
            isFollowing ? '팔로잉 취소하기' : '팔로우',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab() {
    if(provider.games == null){
      return SizedBox(
        height: 300.h,
        child: Center(child: NadalCircular()),
      );
    }

    if(provider.games!.isEmpty){
      return SizedBox(
        height: 300.h,
        child: NadalEmptyList(
            title: '진행한 게임 기록이 없습니다'
        ),
      );
    }
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GridView.builder(
      padding: EdgeInsets.all(8.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4.w,
        mainAxisSpacing: 4.h,
      ),
      itemCount: provider.games!.length, // 예시로 15개의 게시물을 표시
      itemBuilder: (context, index) {
        final match = provider.games![index];
        final isWin = match['result'] == 'win';
        final isDraw = match['result'] == 'draw';
        return InkWell(
          onTap: (){
            context.push('/schedule/${match['scheduleId']}');
          },
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  match['opponentNames'],
                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${match['score1']} : ${match['score2']}',
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isWin
                        ? Colors.green
                        : isDraw
                        ? Colors.grey
                        : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    match['result'].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ),
        );
      },
    );
  }
}
