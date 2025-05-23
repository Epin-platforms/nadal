import '../../manager/dialog/widget/Update_Dialog.dart';
import '../../manager/project/Import_Manager.dart';
import '../../widget/Nadal_Announce_Widget.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});
  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: NadalAppbar(
        title: "더보기",
      ),
      body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NadalAnnounceWidget(), //배너
              SizedBox(height: 16,),
              // 주요 메뉴 그리드
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                child: Text(
                  '메뉴',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildGridItem(
                      context,
                      icon: Icons.announcement_rounded,
                      title: '공지사항',
                      color: ThemeManager.primaryColor,
                      onTap: () {
                        final url = dotenv.get('ANNOUNCE_URL');
                        context.push('/web?url=$url');
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.event_note_rounded,
                      title: '이벤트',
                      color: ThemeManager.freshBlue,
                      onTap: () {
                        final url = dotenv.get('EVENT_URL');
                        context.push('/web?url=$url');
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.support_agent_rounded,
                      title: '문의하기',
                      color: ThemeManager.violetAccent,
                      onTap: ()=> context.push('/qna'),
                    ),
                  /*  _buildGridItem(
                      context,
                      icon: Icons.favorite_rounded,
                      title: '즐겨찾기',
                      color: ThemeManager.errorColor,
                      onTap: () {},
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.history_rounded,
                      title: '이용내역',
                      color: ThemeManager.warmAccent,
                      onTap: () {

                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.card_giftcard_rounded,
                      title: '포인트',
                      color: ThemeManager.secondaryColor,
                      onTap: () {

                      },
                    ),*/
                  ],
                ),
              ),

              SizedBox(height: 24),

              // 서비스 정보 섹션
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                child: Text(
                  '서비스',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),

              // 서비스 정보 리스트
              _buildSettingsItem(
                context,
                Icons.description_outlined,
                '이용약관',
                onTap: () {
                  final url = dotenv.get('TERM_OF_USE');
                  context.push('/web?url=$url');
                },
              ),
              _buildSettingsItem(
                context,
                Icons.privacy_tip_outlined,
                '개인정보처리방침',
                onTap: () {
                  final url = dotenv.get('PRIVACY_POLICY');
                  context.push('/web?url=$url');
                },
              ),

              _buildSettingsItem(
                context,
                Icons.info_outline,
                '앱 정보',
                trailing: Text(
                  'v${context.read<AppProvider>().appVersion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: launchStore
              ),

              SizedBox(height: 16),
              Spacer(),
              // 하단 세션
              Container(
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
                padding: EdgeInsets.symmetric(vertical: 16.w),
                child: Column(
                  children: [
                    /*Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon(Icons.facebook, ThemeManager.freshBlue),
                        SizedBox(width: 24.w),
                        _buildSocialIcon(Icons.chat_bubble, Colors.yellow.shade700),
                        SizedBox(width: 24.w),
                        _buildSocialIcon(Icons.mail_outline, ThemeManager.accentColor),
                      ],
                    ),
                    SizedBox(height: 16),*/
                    Text(
                      '이메일 문의: nadal_official@gmail.com',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '평일 09:00 - 18:00 (주말, 공휴일 휴무)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '© ${DateTime.now().year} Nadal All Rights Reserved',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
      ),
    );
  }

  // 그리드 아이템 위젯
  Widget _buildGridItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 26.r,
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 설정 아이템 위젯
  Widget _buildSettingsItem(
      BuildContext context,
      IconData icon,
      String title, {
        Widget? trailing,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 12.0.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22.r,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            trailing ?? Icon(
              Icons.arrow_forward_ios,
              size: 16.r,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  // 소셜 아이콘 위젯
  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 24.r,
      ),
    );
  }
}



