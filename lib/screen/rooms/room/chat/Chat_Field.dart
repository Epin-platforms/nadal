import 'package:animate_do/animate_do.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:my_sports_calendar/animation/Send_Button.dart';
import 'package:my_sports_calendar/provider/room/Room_Provider.dart';

import '../../../../manager/project/Import_Manager.dart';

class ChatField extends StatefulWidget {
  const ChatField({super.key, required this.roomProvider});
  final RoomProvider roomProvider;

  @override
  State<ChatField> createState() => _ChatFieldState();
}

class _ChatFieldState extends State<ChatField> {
  late final TextEditingController chatController;
  late final FocusNode focusNode;

  bool _visibleSend = false;

  @override
  void initState() {
    chatController = TextEditingController();
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    chatController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Chat _getReplyChat(int chatId){
    return context.read<ChatProvider>().chat[widget.roomProvider.room!['roomId']]!.where((e)=> e.chatId == chatId).first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, Platform.isAndroid ? 15.h : 0),
      child: Column(
        children: [
          if(widget.roomProvider.reply != null)...[
            Builder(
              builder: (context) {
                final chat = _getReplyChat(widget.roomProvider.reply!);
                return FadeInUp(
                  child: Container(
                    width: ScreenUtil.defaultSize.width,
                    height: 54.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: theme.highlightColor,
                    ),
                    padding: EdgeInsets.fromLTRB(12.w, 8.h, 0, 8.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${chat.name}님에게 답장', style: theme.textTheme.labelSmall,),
                              FittedBox(
                                child: Text('${chat.type == ChatType.schedule ? '${chat.title}' : chat.type == ChatType.image ? '사진' :
                                chat.type == ChatType.removed ? '삭제된 메시지' : chat.contents}', style: theme.textTheme.labelMedium,),
                              )
                            ],
                          ),
                        ),
                        IconButton(onPressed: (){
                          widget.roomProvider.setReply(null);
                        }, icon: Icon(BootstrapIcons.x_circle, size: 18.r,))
                      ],
                    )
                  ),
                );
              }
            ),
            SizedBox(height: 4.h,)
          ],
          Container(
            height: 50.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35.r),
              color: theme.colorScheme.primary.withValues(alpha: 0.3)
            ),
            padding: EdgeInsets.all(6.r),
            child: Row(
              children: [
                FittedBox(
                  fit: BoxFit.fitHeight,
                  child: InkWell(
                    customBorder: CircleBorder(),
                    onTap: (){
                      if(widget.roomProvider.sendingImage.isEmpty){
                        widget.roomProvider.sentImageByCamera();
                      }else{
                        SnackBarManager.showCleanSnackBar(context, '이미지 전송 중 입니다. 잠시만 기다려주세요');
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.secondary
                      ),
                      padding: EdgeInsets.all(10.r),
                      child: FittedBox(child: Icon(BootstrapIcons.camera_fill, color: theme.colorScheme.onPrimary,)),
                    ),
                  ),
                ),
                SizedBox(width: 8.w,),
                Expanded(
                    child: TextField(
                      style: theme.textTheme.bodyLarge,
                      controller: chatController,
                      focusNode: focusNode,
                      onChanged: (text){
                        final value = text.trim();
                        if(value.isNotEmpty && !_visibleSend){
                          setState(() {
                            _visibleSend = true;
                          });
                        }else if(value.isEmpty && _visibleSend){
                          setState(() {
                            _visibleSend = false;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        filled: false,
                        hintText: '메시지 입력',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
                        counterText: null,
                        counter: null,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none
                        )
                      ),
                    )
                ),
                if(_visibleSend)
                  FittedBox(
                    fit: BoxFit.fitHeight,
                    child: SendButton(
                        isEnabled: _visibleSend, onPressed: (){
                      widget.roomProvider.sendText(chatController.text);
                      chatController.clear();
                      if(widget.roomProvider.reply != null){
                        widget.roomProvider.setReply(null);
                      }
                      setState(() {
                        _visibleSend = false;
                      });
                    },)
                  )
                else
                  Row(
                    children: [
                      InkWell(
                        customBorder: CircleBorder(),
                        onTap: (){
                          if(widget.roomProvider.sendingImage.isEmpty){
                            widget.roomProvider.sendImage();
                          }else{
                            SnackBarManager.showCleanSnackBar(context, '이미지 전송 중 입니다. 잠시만 기다려주세요');
                          }
                        },
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Container(
                            padding: EdgeInsets.all(10.r),
                            child: FittedBox(
                                fit: BoxFit.fitHeight,
                                child: Icon(BootstrapIcons.image, color: theme.colorScheme.onSurface, size: 24.r,)),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w,)
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
