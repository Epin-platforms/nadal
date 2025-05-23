import 'dart:convert';

import '../../../../../manager/project/Import_Manager.dart';

class ReplyBubble extends StatelessWidget {
  const ReplyBubble({super.key, required this.isMe, required this.chat});
  final bool isMe;
  final Chat chat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Builder(
        builder: (context) {
          return Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text('${chat.replyName ?? '알수없음'}님에게 답장', style: theme.textTheme.labelSmall),
              SizedBox(height: 4.h,),
              if(chat.replyType == 1 && chat.replyContents != null)
                Builder(
                    builder: (context) {
                      final url = jsonDecode(chat.replyContents!)[0] ?? '';
                      return CachedNetworkImage(
                        cacheKey: url,
                        imageUrl: url,
                        height: 50.h,
                        width: 50.h,
                        errorWidget: (context, err, str)=> Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).splashColor,
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.image_not_supported_outlined, size: 24.r, color: Theme.of(context).hintColor),
                        ),
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).splashColor,
                        ),
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover
                              )
                          ),
                        ),
                      );
                    }
                )
              else
                Text(chat.replyContents ?? '(알수없음)', style: theme.textTheme.labelSmall,overflow: TextOverflow.ellipsis,)
            ],
          );
        }
    );
  }
}
