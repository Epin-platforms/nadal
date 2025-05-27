

import '../../../../../manager/project/Import_Manager.dart';

class MyResult extends StatelessWidget {
  const MyResult({super.key, required this.scheduleProvider});
  final ScheduleProvider scheduleProvider;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final me = scheduleProvider.scheduleMembers![uid]!;
    final level = (context.read<UserProvider>().user!['level'] as num).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        children: [
          Container(
            height: 200.h,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              children: [
                // 프로필 헤더 - 그라데이션 배경
                Container(
                  height: 60.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C4B4), Color(0xFF27B3A0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius:  BorderRadius.only(
                        topLeft: Radius.circular(12.0.r),
                        topRight: Radius.circular(12.0.r),
                        bottomRight: Radius.circular(12.r)
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 프로필 사진
                      NadalProfileFrame(imageUrl: me['profileImage'],
                        size: 66.r,
                        useBackground: true,),
                      SizedBox(width: 12.w),
                      // 사용자 정보
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TextFormManager.profileText(
                                  me['nickName'], me['name'], me['birthYear'],
                                  me['gender'], useNickname: me['gender'] ==
                                  null),
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                // 레벨 태그
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F7F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('Lv. ${level.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF00C4B4),
                                    ),
                                  ),
                                ),

                                SizedBox(width: 8.w),

                                // 몇 게임 진행
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '총 ${scheduleProvider.getMyGames().length} 게임 진행',
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w700
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12,),
                  // 구분선
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.0),
                    child: Divider(height: 1),
                  ),

                  // 프로필 상세 정보
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 테니스 경력
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children:  [
                              Text(
                               scheduleProvider.schedule!['isKDK'] == 1 ? '승점' : '승리횟수',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${me['winPoint'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeManager.infoColor
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // 선호 포지션
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                scheduleProvider.schedule!['isKDK'] == 1 ? '득점' : '누적점수',
                                style: TextStyle(
                                  fontSize: 14,
                                ), 
                              ),
                              Text(
                                '${me['score'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                    color: ThemeManager.infoColor
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if(me['ranking'] != null && me['ranking'] < 4)
          Positioned(
              top: 0, right: 10.w,
              child: Image.asset(
                me['ranking'] == 1 ?
                'assets/image/icon/gold.png' :
                me['ranking'] == 2 ?
                'assets/image/icon/silver.png' :
                'assets/image/icon/bronze.png' 
                , height: 70.r, width: 70.r,)
          )
        ],
      ),
    );
  }
}
