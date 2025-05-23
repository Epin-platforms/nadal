import 'package:flutter/services.dart';
import 'package:my_sports_calendar/manager/dialog/widget/Basic_Dialog.dart';
import 'package:my_sports_calendar/manager/dialog/widget/Error_Dialog.dart';
import 'package:my_sports_calendar/manager/dialog/widget/Inspection_Dialog.dart';
import 'package:my_sports_calendar/manager/dialog/widget/Update_Dialog.dart';

import '../project/Import_Manager.dart';

class DialogManager{

  static Future showBasicDialog({required String title, required String content, required String confirmText, Widget? icon, String? cancelText, VoidCallback? onConfirm, VoidCallback? onCancel}) async{
    final context = AppRoute.navigatorKey.currentState?.overlay?.context;
    var res;
    if(context != null){
      res = await showDialog(context: context, builder: (_)=> BasicDialog(title: title, content: content, confirmText: confirmText, icon: icon, onConfirm: onConfirm, onCancel: onCancel, cancelText: cancelText,));
    }
    return res;
  }

  static void warningHandler(String title){
    DialogManager.showBasicDialog(title: title, content: '확인하고 다시 입력해 주세요!', confirmText: '확인');
  }


  static updateHandler(){
    final context = AppRoute.navigatorKey.currentState?.overlay?.context;
    if(context != null){
      showDialog(context: context, builder: (_)=> UpdateDialog(), barrierDismissible: false);
    }
  }

  static inspectionHandler(){
    final context = AppRoute.navigatorKey.currentState?.overlay?.context;
    if(context != null){
      showDialog(context: context, builder: (_)=> InspectionDialog(), barrierDismissible: false);
    }
  }

  static errorHandler(String? error, {bool systemOff = false}) async{
    final context = AppRoute.navigatorKey.currentState?.overlay?.context;

    if(context != null){
      await showDialog(context: context, builder: (_)=> ErrorDialog(content: error));
      if(systemOff){
        if(Platform.isIOS){
          exit(0);
        }else{
          SystemNavigator.pop();
        }
      }
    }
  }



  static Future<void> showInputDialog({
    required BuildContext context,
    required String title,
    String? content,
    String? hintText,
    required String confirmText,
    String? cancelText,
    Widget? icon,
    Function(String text)? onConfirm,
    VoidCallback? onCancel,
    String? helper,
    TextInputType? keyType,
    int? maxLength
  }) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 내용 영역
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 12.h),
                child: Column(
                  children: [
                    if (icon != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: icon,
                      )
                    else
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Icon(BootstrapIcons.lock_fill, size: 30, color: Theme.of(context).colorScheme.primary),
                      ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    if (content != null) ...[
                      SizedBox(height: 12.h),
                      Text(
                        content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    NadalTextField(
                      controller: controller,
                      keyboardType: keyType ?? TextInputType.number,
                      maxLength: maxLength ?? 10,
                      helper: helper ?? '4-10자리 숫자 입력',)
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1),

              // 버튼 영역
              if (cancelText != null)
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onCancel?.call();
                        },
                        child: Text(cancelText),
                      ),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: const Color(0xFF3CB8C5),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm?.call(controller.text);
                        },
                        child: Text(confirmText),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: const Color(0xFF3CB8C5),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call(controller.text);
                    },
                    child: Text(confirmText),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

}