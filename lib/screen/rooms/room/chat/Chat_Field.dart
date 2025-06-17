import 'package:animate_do/animate_do.dart';
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

  // 🔧 연결 상태 확인 타이머
  Timer? _connectionCheckTimer;

  @override
  void initState() {
    chatController = TextEditingController();
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    chatController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Chat _getReplyChat(int chatId){
    return context.read<ChatProvider>().chat[widget.roomProvider.room!['roomId']]!.where((e)=> e.chatId == chatId).first;
  }

  // 🔧 연결 상태 확인 (간단화)
  bool _isConnected() {
    final socketManager = SocketManager.instance;
    final chatProvider = context.read<ChatProvider>();
    final roomId = widget.roomProvider.room!['roomId'] as int;

    return socketManager.isReallyConnected &&
        chatProvider.isJoined(roomId);
  }

  // 🔧 안전한 메시지 전송 (간단화)
  Future<void> _sendMessage() async {
    if (_isSending || chatController.text.trim().isEmpty) return;

    final message = chatController.text.trim();
    final roomId = widget.roomProvider.room!['roomId'] as int;

    setState(() {
      _isSending = true;
    });

    try {
      // 🔧 연결 상태 확인
      if (!_isConnected()) {
        throw Exception('연결이 불안정합니다');
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

        if (e.toString().contains('연결')) {
          errorMessage = '연결이 불안정합니다. 잠시 후 다시 시도해주세요';
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

  // 🔧 안전한 이미지 전송 (간단화)
  Future<void> _sendImage({bool fromCamera = false}) async {
    if (widget.roomProvider.sendingImage.isNotEmpty) {
      SnackBarManager.showCleanSnackBar(context, '이미지 전송 중 입니다. 잠시만 기다려주세요');
      return;
    }

    try {
      // 🔧 연결 상태 확인
      if (!_isConnected()) {
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
                // 전송 중 로딩 표시
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