import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';

class CommentProvider extends ChangeNotifier{
  DateTime? _lastUpdate;
  int? _scheduleId;

  ///댓글 프로바이더 스케줄 아이디 지정
  initCommentProvider(int id){
    _scheduleId = id;
    notifyListeners();
    fetchComment();
  }

  /// 모든 댓글 데이터를 저장
  List<Map<String, dynamic>> _comments = [];

  /// 원댓글만 따로 필터
  List<Map<String, dynamic>> _topLevelComments = [];

  /// commentId → 대댓글 리스트
  Map<int, List<Map<String, dynamic>>> _replyMap = {};

  /// 모든 댓글 데이터를 저장
  List<Map<String, dynamic>> get comments => _comments;

  /// 원댓글만 따로 필터
  List<Map<String, dynamic>> get topLevelComments => _topLevelComments;

  /// commentId → 대댓글 리스트
  Map<int, List<Map<String, dynamic>>> get replyMap => _replyMap;

  int _offset = 0;

  Future<void> fetchComment() => _fetchComment();

  bool _hasMore = true;

  Future<void> _fetchComment() async {
    if (!_hasMore) return;

    final updateAt = (_lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0)).toIso8601String();

    final res = await serverManager.get(
      'comment/$_scheduleId',
      queryParams: {
        'updateAt': updateAt,
        'limit': 10,
        'offset': _offset,
      },
    );

    if (res.statusCode == 200) {
      final List<Map<String, dynamic>> newComments = List<Map<String, dynamic>>.from(res.data);

      for (final c in newComments) {
        final id = c['commentId'];
        final idx = _comments.indexWhere((e) => e['commentId'] == id);
        if (idx >= 0) {
          _comments[idx] = c;
        } else {
          _comments.add(c);
        }
      }

      if (newComments.length < 10) {
        _hasMore = false; // 다음 호출 막기
      } else {
        _offset++;
      }

      _lastUpdate = DateTime.now();
      _rebuildStructure();
      notifyListeners();
    }
  }


  void _rebuildStructure() {
    final top = <Map<String, dynamic>>[];
    final replies = <int, List<Map<String, dynamic>>>{};

    for (final comment in _comments) {
      final reply = comment['reply'];

      if (reply == null) {
        top.add(comment);
      } else {
        final parentId = reply is int ? reply : int.tryParse(reply.toString());
        if (parentId != null) {
          replies.putIfAbsent(parentId, () => []).add(comment);
        }
      }
    }

    // 정렬 후 기존 변수에 재할당 (clear 필요 없음)
    top.sort((a, b) => DateTime.parse(a['createAt']).compareTo(DateTime.parse(b['createAt'])));
    for (final list in replies.values) {
      list.sort((a, b) => DateTime.parse(a['createAt']).compareTo(DateTime.parse(b['createAt'])));
    }

    _topLevelComments = top;
    _replyMap = replies;

    notifyListeners();
  }

  //댓글 달기
  int? _replyId;
  int? get replyId => _replyId;

  setReply(int? commentId){
    if(_replyId != commentId){
      _replyId = commentId;
      if(_editComment != null){
        _editComment = null;
      }
      notifyListeners();
    }
  }

  Future<void> sendComment({required String text}) async {
    final body = {
      'scheduleId': _scheduleId,
      'text': text,
      'reply': _replyId,
    };

    final res = await serverManager.post('comment/write', data: body);

    if (res.statusCode == 200) {
      // 리셋 후 전체 댓글 다시 불러오기
      _offset = 0;
      _comments.clear();
      _lastUpdate = null;
      _hasMore = true;
      await _fetchComment();

      // 댓글 전송 후 상태 초기화
      _replyId = null;
    }
  }

  Future<void> deleteComment(int commentId) async {
    final res = await serverManager.delete('comment/$commentId');

    if (res.statusCode == 200) {
      final isDelete = res.data['isDelete'];
      if(isDelete){
        _comments.removeWhere((c) => c['commentId'] == commentId);
      }else{
        final idx = _comments.indexWhere((c) => c['commentId'] == commentId);
        if (idx >= 0) {
          // ✅ 그냥 텍스트를 "삭제된 댓글입니다."로 변경
          _comments[idx]['text'] = '삭제된 댓글입니다.';
        }
      }

      _rebuildStructure();
      notifyListeners();
    }
  }


  //댓글 수정
  int? _editComment;
  int? get editComment => _editComment;

  setEditComment(int? commentId){
      if(_editComment != commentId){
        _editComment = commentId;
        if(_replyId != null){
          _replyId = null;
        }
        notifyListeners();
      }
  }

  Future<void> editedComment(String newText) async {
    final res = await serverManager.put(
      'comment/$_editComment',
      data: {'text': newText},
    );

    if (res.statusCode == 200) {
      final idx = _comments.indexWhere((c) => c['commentId'] == _editComment);
      if (idx >= 0) {
        _comments[idx]['text'] = newText;
        _comments[idx]['updateAt'] = DateTime.now().toIso8601String();
        _rebuildStructure();
        _editComment = null;
        notifyListeners();
      }
    }
  }



}