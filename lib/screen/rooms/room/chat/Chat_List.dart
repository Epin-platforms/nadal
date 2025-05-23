import 'package:my_sports_calendar/provider/room/Room_Provider.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/bubble/Image_Chat_Bubble.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/widget/Chat_Frame.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/widget/Date_Divider.dart';
import 'package:my_sports_calendar/screen/rooms/room/chat/widget/Log_Frame.dart';

import '../../../../manager/project/Import_Manager.dart';
import '../../../../model/room/Room_Log.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key,required this.roomProvider});
  final RoomProvider roomProvider;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late ChatProvider chatProvider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    if(mounted){
      _scrollController.addListener(() {
        if(!chatProvider.socketLoading && _hasMore){
          final position = _scrollController.position;
          if(position.pixels >= position.maxScrollExtent - 50){
            _loadMoreChats();
          }
        }
      });
    }
    super.initState();
  }

  bool _hasMore = false;

  Future<void> _loadMoreChats() async {
    final roomId = widget.roomProvider.room!['roomId'];
    final result = await chatProvider.setChats(roomId);

    if(_hasMore != result){
      setState(() {
        _hasMore = result;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Selector2<ChatProvider, RoomProvider, List<dynamic>>(
            selector: (context, chatProvider, roomProvider) {
              final roomId = roomProvider.room!['roomId'];
              var combinedList = [
                ...chatProvider.chat[roomId] ?? [],
                ...roomProvider.roomLog
              ];
          
              combinedList.sort((a, b) {
                final aDate = a.runtimeType == Chat ? (a as Chat).createAt : (a as RoomLog).createAt;
                final bDate = b.runtimeType == Chat ? (b as Chat).createAt : (b as RoomLog).createAt;
                return bDate.compareTo(aDate);
              });
          
          
              return combinedList;
            },
            builder: (context, chatList, child) {
              return ListView.separated(
                controller: _scrollController,
                shrinkWrap: true,
                reverse: true,
                itemCount: chatList.length,
                itemBuilder: (context, index) {
                  final currentData = chatList[index];
          
                  // 로그 데이터 처리
                  if (currentData is RoomLog) {
                    return LogFrame(roomLog: currentData);
                  }
          
                  // 채팅 데이터 처리
                  final chat = currentData as Chat;
          
                  // 이전 및 다음 데이터 참조
                  final previousData = (index < chatList.length - 1 && chatList.isNotEmpty && chatList[index + 1] is Chat)
                      ? chatList[index + 1] as Chat
                      : null;
          
                  final nextData = (index > 0 && chatList.isNotEmpty && chatList[index - 1] is Chat)
                      ? chatList[index - 1] as Chat
                      : null;
          
                  // 날짜 출력 여부 결정
                  final cDate = DateTime(chat.createAt.year, chat.createAt.month, chat.createAt.day);
                  final pDate = previousData != null
                      ? DateTime(previousData.createAt.year, previousData.createAt.month, previousData.createAt.day)
                      : null;
          
                  final showDate = (index == chatList.length - 1) || (cDate != pDate);
          
                  // 시간, 꼬리 출력 여부 결정
                  bool timeVisible = nextData == null ||
                      nextData.uid != chat.uid ||
                      nextData.createAt.difference(chat.createAt).inMinutes > 5;
          
                  bool tail = previousData == null ||
                      previousData.uid != chat.uid ||
                      chat.createAt.difference(previousData.createAt).inMinutes > 5;
          
                  // 읽음 표시 계산
                  int read = (widget.roomProvider.roomMembers.keys.length -
                      widget.roomProvider.roomMembers.values.where((e) =>
                          DateTime.parse(e['lastRead']).toLocal().isAfter(chat.createAt)).length);

                  return Column(
                    children: [
                      // 날짜 구분선 표시
                      if (showDate)
                        DateDivider(
                          key: ValueKey('date-${cDate.toIso8601String()}'),
                          date: cDate,
                        ),
          
                      // 채팅 메시지 표시
                      ChatFrame(
                        key: ValueKey(chat.chatId),
                        chat: chat,
                        timeVisible: timeVisible,
                        tail: tail,
                        read: read,
                        index: index,
                        roomProvider: widget.roomProvider,
                      ),
                    ],
                  );
                },
                separatorBuilder: (BuildContext context, int index) => SizedBox(height: 8,),
              );
            },
          ),
        ),
        if(widget.roomProvider.sendingImage.isNotEmpty)...[
          SizedBox(height: 8,),
          SendingImagesPlaceHolder(images: widget.roomProvider.sendingImage)
        ]
      ],
    );
  }
}
