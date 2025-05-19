import 'package:cloud_firestore/cloud_firestore.dart';

class AppVersionInfo {
  final int buildCode;
  final bool forceUpdate;
  final DateTime inspectionDate;
  final String inspectionComment;

  AppVersionInfo({
    required this.buildCode,
    required this.inspectionDate,
    required this.inspectionComment,
    required this.forceUpdate,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json, {required bool isIOS}) {
    return AppVersionInfo(
        buildCode: isIOS ? (json['iOSBuildCode'])?.toInt() ?? 0 : (json['androidBuildCode']?.toInt() ?? 0),
        inspectionDate: (json['inspectionDate'] as Timestamp).toDate(),
        inspectionComment: json['inspectionComment'],
        forceUpdate: json['forceUpdate']
    );
  }

  static Future<AppVersionInfo?> fetchAppVersion({required bool isIOS}) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('app').doc('state').get();
      final data = doc.data();
      if (data == null) return null;

      return AppVersionInfo.fromJson(data, isIOS: isIOS);
    } catch (e) {
      return null;
    }
  }
}
