import 'package:animate_do/animate_do.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:my_sports_calendar/animation/Send_Button.dart';
import 'package:my_sports_calendar/provider/room/Room_Provider.dart';

import '../../../../manager/project/Import_Manager.dart';
import '../../../../manager/server/Socket_Manager.dart';

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
  bool _isSending = false;

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

  // 🔧 안전한 메시지 전송
  Future<void> _sendMessage() async {
    if (_isSending || chatController.text.trim().isEmpty) return;

    final message = chatController.text.trim();
    final roomId = widget.roomProvider.room!['roomId'] as int;

    setState(() {
      _isSending = true;
    });

    try {
      // 🔧 소켓 연결 상태 확인
      final socketManager = SocketManager.instance;
      if (!socketManager.isReallyConnected) {
        // 소켓 재연결 시도
        debugPrint("🔌 메시지 전송 전 소켓 재연결 시도");
        await socketManager.connect();

        // 연결 확인 대기 (최대 3초)
        int waitCount = 0;
        while (!socketManager.isReallyConnected && waitCount < 6) {
          await Future.delayed(const Duration(milliseconds: 500));
          waitCount++;
        }

        if (!socketManager.isReallyConnected) {
          throw Exception('소켓 연결에 실패했습니다');
        }
      }

      // 🔧 ChatProvider 조인 상태 확인
      final chatProvider = context.read<ChatProvider>();
      if (!chatProvider.isJoined(roomId)) {
        debugPrint("🔗 메시지 전송 전 방 재조인 시도");
        await chatProvider.joinRoom(roomId);

        // 조인 확인 대기
        await Future.delayed(const Duration(milliseconds: 500));

        if (!chatProvider.isJoined(roomId)) {
          throw Exception('채팅방 연결에 실패했습니다');
        }
      }

      // 메시지 전송
      await widget.roomProvider.sendText(message);

      // 전송 성공 시 입력창 정리
      chatController.clear();
      if (widget.roomProvider.reply != null) {
        widget.roomProvider.setReply(null);
      }

      setState(() {
        _visibleSend = false;
      });

      debugPrint("✅ 메시지 전송 성공");

    } catch (e) {
      debugPrint("❌ 메시지 전송 실패: $e");

      // 오류 시 사용자에게 알림
      if (mounted) {
        String errorMessage = '메시지 전송에 실패했습니다';

        if (e.toString().contains('소켓')) {
          errorMessage = '연결이 불안정합니다. 잠시 후 다시 시도해주세요';
        } else if (e.toString().contains('채팅방')) {
          errorMessage = '채팅방 연결에 문제가 있습니다';
        }

        SnackBarManager.showCleanSnackBar(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // 🔧 안전한 이미지 전송
  Future<void> _sendImage({bool fromCamera = false}) async {
    if (widget.roomProvider.sendingImage.isNotEmpty) {
      SnackBarManager.showCleanSnackBar(context, '이미지 전송 중 입니다. 잠시만 기다려주세요');
      return;
    }

    try {
      // 🔧 소켓 연결 상태 확인
      final socketManager = SocketManager.instance;
      if (!socketManager.isReallyConnected) {
        SnackBarManager.showCleanSnackBar(context, '연결 상태를 확인하고 다시 시도해주세요');
        return;
      }

      if (fromCamera) {
        await widget.roomProvider.sentImageByCamera();
      } else {
        await widget.roomProvider.sendImage();
      }

    } catch (e) {
      debugPrint("❌ 이미지 전송 실패: $e");

      if (mounted) {
        SnackBarManager.showCleanSnackBar(context, '이미지 전송에 실패했습니다');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 15.h),
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
                    onTap: _isSending ? null : () => _sendImage(fromCamera: true),
                    child: Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isSending
                              ? theme.colorScheme.secondary.withValues(alpha:0.5)
                              : theme.colorScheme.secondary
                      ),
                      padding: EdgeInsets.all(10.r),
                      child: FittedBox(
                        child: Icon(
                          BootstrapIcons.camera_fill,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w,),
                Expanded(
                    child: TextField(
                      style: theme.textTheme.bodyLarge,
                      controller: chatController,
                      focusNode: focusNode,
                      enabled: !_isSending,
                      onChanged: (text){
                        final value = text.trim();
                        if(value.isNotEmpty && !_visibleSend && !_isSending){
                          setState(() {
                            _visibleSend = true;
                          });
                        }else if(value.isEmpty && _visibleSend){
                          setState(() {
                            _visibleSend = false;
                          });
                        }
                      },
                      onSubmitted: _isSending ? null : (_) => _sendMessage(),
                      decoration: InputDecoration(
                          filled: false,
                          hintText: _isSending ? '전송 중...' : '메시지 입력',
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              color: _isSending
                                  ? theme.hintColor.withValues(alpha:0.5)
                                  : theme.hintColor
                          ),
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
                if(_visibleSend && !_isSending)
                  FittedBox(
                    fit: BoxFit.fitHeight,
                    child: SendButton(
                      isEnabled: _visibleSend && !_isSending,
                      onPressed: _sendMessage,
                    ),
                  )
                else if (_isSending)
                // 🔧 전송 중 로딩 표시
                  Container(
                    width: 38.w,
                    height: 38.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha:0.7),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 18.w,
                        height: 18.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      InkWell(
                        customBorder: CircleBorder(),
                        onTap: _isSending ? null : () => _sendImage(fromCamera: false),
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Container(
                            padding: EdgeInsets.all(10.r),
                            child: FittedBox(
                              fit: BoxFit.fitHeight,
                              child: Icon(
                                BootstrapIcons.image,
                                color: _isSending
                                    ? theme.colorScheme.onSurface.withValues(alpha:0.5)
                                    : theme.colorScheme.onSurface,
                                size: 24.r,
                              ),
                            ),
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