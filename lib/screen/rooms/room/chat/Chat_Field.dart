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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          color: theme.colorScheme.primary.withValues(alpha: 0.3)
        ),
        padding: EdgeInsets.all(6),
        child: Row(
          children: [
            FittedBox(
              fit: BoxFit.fitHeight,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary
                ),
                padding: EdgeInsets.all(10),
                child: FittedBox(child: Icon(BootstrapIcons.camera_fill, color: const Color(0xffffffff),)),
              ),
            ),
            SizedBox(width: 8,),
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
                  setState(() {
                    _visibleSend = false;
                  });
                },)
              )
            else
              Row(
                children: [
                  FittedBox(
                    fit: BoxFit.fitHeight,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Icon(BootstrapIcons.image, color: theme.colorScheme.onSurface, size: 24,)),
                    ),
                  ),
                  SizedBox(width: 4,)
                ],
              )
          ],
        ),
      ),
    );
  }
}
