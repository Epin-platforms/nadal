class QnaModel{
  final int qid;
  final String uid;
  final bool isFaq;
  final String title;
  final String question;
  final DateTime createAt;
  final String? answerMid;
  final String? answer;
  final DateTime? answerAt;

  final String? managerName;
  final String? managerProfileImage;

  QnaModel({
    required this.qid,
    required this.uid,
    required this.title,
    required this.question,
    required this.createAt,
    required this.answerMid,
    required this.answer,
    required this.answerAt,
    required this.isFaq,
    required this.managerName,
    required this.managerProfileImage
  });

  factory QnaModel.fromJson(Map map){
    return QnaModel(
        qid: map['qid'],
        uid: map['uid'],
        title: map['title'],
        question: map['question'],
        createAt: DateTime.parse(map['createAt']).toLocal(),
        answerMid: map['answerMid'],
        answer: map['answer'],
        answerAt: map['answerAt'] != null ? DateTime.parse(map['answerAt']).toLocal() : null,
        isFaq: map['isFaq'] == 1,
        managerName: map['managerName'],
        managerProfileImage: map['managerProfileImage']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'isFaq': isFaq,
      'title': title,
      'question': question,
      'createAt': createAt.toIso8601String(),
      'answerMid': answerMid,
      'answer': answer,
      'answerAt': answerAt?.toIso8601String(),
    };
  }
}