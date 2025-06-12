import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../project/Import_Manager.dart';

class InspectionDialog extends StatelessWidget {
  const InspectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 48.r, color: Color(0xFFFF8800)),
            const SizedBox(height: 16),
            Text(
              '서버 점검 안내',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '현재 나스달 서비스는 시스템 점검 중입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp),
            ),
            Text(
                '불편을 드려 죄송합니다.',
                textAlign: TextAlign.center,
                style:  TextStyle(fontSize: 14.sp),
            ),



            // ⏰ 종료 시간 강조 박스
            Padding(
              padding: EdgeInsets.only(top: 15.h, bottom: 10.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAFBFD),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, size: 20.r, color: Color(0xFF3CB8C5)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final until = DateFormat('MM월 dd일 hh:mm').format(appProvider.inspectionDate ?? DateTime.now().add(const Duration(hours: 30)));
                          return FittedBox(
                            child: Text(
                              '$until 까지 점검 예정',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: ThemeManager.infoColor)
                            ),
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: (){
                  if(Platform.isIOS){
                    exit(0);
                  }else{
                    SystemNavigator.pop();
                  }
                }, // 앱 종료
                child: const Text('앱 종료', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
