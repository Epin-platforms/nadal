import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/provider/room/Room_Preview_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal.dart';
import 'package:my_sports_calendar/widget/Nadal_Circular.dart';
import 'package:my_sports_calendar/widget/Nadal_Dot.dart';

import '../../../manager/project/Import_Manager.dart';

class RoomPreview extends StatelessWidget {
  const RoomPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoomPreviewProvider>(context);
    final theme = Theme.of(context);

    if(provider.room == null){
      return Material(
        child: Center(
          child: NadalCircular(),
        ),
      );
    }

    final isOpen = provider.room!['isOpen'] == 1;
    return IosPopGesture(
        child: Scaffold(
          appBar: NadalAppbar(
            backgroundColor: Colors.transparent,
            actions: [
              NadalReportIcon(
                onTap: (){
                  context.push('/report?targetId=${provider.room!['roomId']}&type=room');
                },
              )
            ],
          ),
          extendBodyBehindAppBar: true,
          body:
          provider.room != null ?
              Builder(
                builder: (context) {
                  if(provider.room!['roomImage'] != null){
                    precacheImage(NetworkImage(provider.room!['roomImage']), context);
                  }
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: ()=> context.push('/image?url=${provider.room!['roomImage']  ?? 'roomImage'}'),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                              image: DecorationImage(image:  provider.room!['roomImage'] == null ? AssetImage('assets/image/default/room_default.png') : NetworkImage(provider.room!['roomImage']), fit: BoxFit.cover)
                          ),
                        ),
                      ),
                      // 드래그 가능한 바텀시트
                      DraggableScrollableSheet(
                        initialChildSize: 0.6, // 시작 높이 (10%)
                        minChildSize: 0.6,     // 최소 높이
                        maxChildSize: 0.8,     // 최대 확장 높이
                        builder: (context, scrollController) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: ListView(
                              padding: EdgeInsets.only(top: 24.h, bottom: 100),
                              controller: scrollController,
                              shrinkWrap: true,
                              children: [
                                // 핸들
                                Center(
                                  child: Container(
                                    width: 40.w,
                                    height: 4.h,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).highlightColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 60.h,),
                                Text(provider.room!['roomName'], style: theme.textTheme.titleLarge,),
                                SizedBox(height: 6,),
                                Text('개설 ${DateFormat('yyyy.MM.dd').format(
                                    DateTimeManager.parseUtcToLocal(provider.room!['createAt']))}', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),),
                                SizedBox(height: 12,),
                                DefaultTextStyle(
                                  style: theme.textTheme.labelMedium!,
                                  child: Row(
                                    children: [
                                      Text('활동지역'),
                                      SizedBox(width: 4.w,),
                                      Text(TextFormManager.formToLocal(provider.room!['local'])),
                                      SizedBox(width: 4.w,),
                                      Text(provider.room!['city']),
                                      NadalDot(color: theme.highlightColor,),
                                      Text('멤버'),
                                      SizedBox(width: 4.w),
                                      Text('${provider.room!['memberCount']} /200')
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24.h,),
                                Row(
                                  children: [
                                    NadalProfileFrame(imageUrl: provider.room!['creatorProfile'], size: 40.r,),
                                    SizedBox(width: 8,),
                                    Text('${provider.room!['creatorNickName'] ?? '(알수없음)'}', style: theme.textTheme.bodyMedium,)
                                  ],
                                ),
                                SizedBox(height: 12,),
                                Text(provider.room!['description'], style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),),
                                SizedBox(height: 12,),
                                Text(provider.room!['tag'], style: theme.textTheme.labelMedium?.copyWith(color: ThemeManager.infoColor),),
                              ],
                            ),
                          );
                        },
                      ),
                      Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: SafeArea(
                              child: NadalButton(isActive: true, title: '${isOpen ? '번개방' : '클럽'} 가입하기', onPressed: (){
                                DialogManager.showBasicDialog(title: '${isOpen ? '번개방' : '클럽'}에 가입해볼까요?', content: '${isOpen ? '번개방' : '클럽'} 일정과 소식이 바로 공유돼요', confirmText: '	지금 입장하기', cancelText: '조금 있다가요',
                                  onConfirm: () async{
                                  await showDialog(context: context,
                                      builder: (context) => UGCTermsDialog(onAccepted: ()async{
                                        provider.registerStart("");
                                      })
                                    );
                                  }
                                );
                              },)
                          )
                      )
                    ],
                  );
                }
              ) :
          SafeArea(
              child: Center(
                child: NadalCircular()
              )
          )
        )
    );
  }
}

// 🔧 UGC 약관 동의 다이얼로그
class UGCTermsDialog extends StatelessWidget {
  final VoidCallback onAccepted;
  final VoidCallback? onDeclined;

  const UGCTermsDialog({
    super.key,
    required this.onAccepted,
    this.onDeclined,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(Icons.security, color: Colors.red, size: 24.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '커뮤니티 가이드라인',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ 중요: 안전한 커뮤니티를 위한 필수 약관',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '이 앱에서는 불쾌감을 주는 콘텐츠나 학대적인 사용자에 대해 절대 관용하지 않습니다.',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            Text(
              '커뮤니티 규칙',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.h),

            _buildRuleItem('🚫 금지 행위', [
              '욕설, 비방, 모욕적인 언어 사용',
              '괴롭힘, 따돌림, 협박',
              '스팸, 광고, 허위정보 게시',
              '개인정보 무단 공유',
              '불법적이거나 위험한 활동 조장',
              '선정적이거나 폭력적인 콘텐츠',
            ]),

            SizedBox(height: 12.h),

            _buildRuleItem('⚡ 즉시 조치', [
              '부적절한 콘텐츠 즉시 삭제',
              '위반 사용자 채팅 정지/추방',
              '신고 접수 후 24시간 내 검토',
              '반복 위반 시 영구 계정 차단',
            ]),

            SizedBox(height: 12.h),

            _buildRuleItem('🛡️ 안전장치', [
              '모든 메시지에 신고 기능 제공',
              '방장 판단 추방시 2달간 입장 불가',
              '사용자 차단 기능 제공',
              '정기적 운영진 대응',
            ]),

            SizedBox(height: 16.h),

            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '위 규칙을 위반할 경우 경고 없이 계정이 정지되거나 영구 추방될 수 있습니다. 안전하고 건전한 커뮤니티 환경 조성에 협조해 주세요.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.blue.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDeclined ?? () => Navigator.of(context).pop(),
          child: Text(
            '거부',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onAccepted();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            '동의하고 계속하기',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            color: Colors.orange,
          ),
        ),
        SizedBox(height: 4.h),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 2.h),
          child: Text(
            '• $item',
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.3,
              color: Colors.grey[700],
            ),
          ),
        )),
      ],
    );
  }
}
