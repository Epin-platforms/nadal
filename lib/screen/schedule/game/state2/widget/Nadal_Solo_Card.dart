import '../../../../../manager/project/Import_Manager.dart';

class NadalSoloCard extends StatelessWidget {
  const NadalSoloCard({super.key, required this.user, required this.isDragging, required this.index});
  final bool isDragging;
  final Map user;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: MediaQuery.of(context).size.width,
      margin:  EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      padding:  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDragging ? 0.18 : 0.1),
            blurRadius: isDragging ? 8 : 6,
            spreadRadius: isDragging ? 1 : 0,
            offset: Offset(0, isDragging ? 4 : 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 순서 번호
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${
                  user['memberIndex'] ??
                  index + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14.sp,
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // 프로필
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: NadalProfileFrame(
              imageUrl: user['profileImage'],
              size: 40.r,
            ),
          ),

          SizedBox(width: 12.w),

          // 이름 or 닉네임
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TextFormManager.profileText(
                      user['nickName'],
                      user['name'],
                      user['birthYear'],
                      user['gender'],
                      useNickname: user['gender'] == null
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (user['teamName'] != null) // 팀명이 있다면
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user['teamName'],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}