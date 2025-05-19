import '../../manager/project/Import_Manager.dart';

class CommentField extends StatefulWidget {
  const CommentField({super.key, required this.provider, required this.scrollController});
  final CommentProvider provider;
  final ScrollController scrollController;
  @override
  State<CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends State<CommentField> {
  final TextEditingController _commentController = TextEditingController();


  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(widget.provider.replyId != null || widget.provider.editComment != null)
          ...[
            Builder(
                builder: (context) {
                  final replyData = widget.provider.comments.where((e)=> e['commentId'] == widget.provider.replyId).firstOrNull;
                  return SizedBox(
                    height: 30,
                    child: Center(
                      child: Row(
                        children: [
                          Expanded(child:
                          widget.provider.replyId != null ?
                          Text(
                            '${replyData?['displayName'] ?? '(알수없음)'}님에 대한 답글', style: theme.textTheme.labelSmall, overflow: TextOverflow.ellipsis,) :
                          Text(
                            '댓글수정', style: theme.textTheme.labelSmall, overflow: TextOverflow.ellipsis,),),
                          InkWell(
                            customBorder: CircleBorder(),
                            onTap: (){
                              if(widget.provider.replyId != null){
                                widget.provider.setReply(null);
                              }else{
                                widget.provider.setEditComment(null);
                              }
                            },
                            child: Container(
                                height: 24, width: 24,
                                padding: EdgeInsets.all(5),
                                child: FittedBox(child: Icon(BootstrapIcons.x_circle, )),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }
            ),
            SizedBox(height: 5,),
            Divider(height: 0.5,),
          ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                onTap: (){
                  Future.delayed(const Duration(milliseconds: 300), ()=> widget.scrollController.animateTo(
                    widget.scrollController.position.maxScrollExtent, // 가장 아래 위치
                    duration: Duration(milliseconds: 300), // 애니메이션 지속 시간
                    curve: Curves.easeOut, // 부드러운 감속 효과
                  ));
                },
                decoration: InputDecoration(
                  hintText: widget.provider.editComment != null ? widget.provider.comments.where((e)=> e['commentId'] == widget.provider.editComment).first['text'] ?? '수정문구 입력' : '댓글 입력...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  border: InputBorder.none,
                ),
                style: theme.textTheme.bodyMedium,
                minLines: 1,
                maxLines: 5,
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
              onPressed: () {
                // 댓글 보내기 로직
                if(_commentController.text.trim().replaceAll(' ', '') == "삭제된댓글입니다."){
                  DialogManager.warningHandler("‘삭제된 댓글입니다’는 시스템 예약 문구로 사용할 수 없습니다.");
                }else if(widget.provider.editComment != null){
                  if(_commentController.text.trim().replaceAll(' ', '').isNotEmpty){
                    widget.provider.editedComment(_commentController.text);
                    //코멘트 필드 초기화
                    _commentController.clear();
                  }else{
                    DialogManager.warningHandler('흠.. 공백으로 수정할 수 없어요');
                  }
                }else if(_commentController.text.trim().isNotEmpty){
                  widget.provider.sendComment(text: _commentController.text);
                  //코멘트 필드 초기화
                  _commentController.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
