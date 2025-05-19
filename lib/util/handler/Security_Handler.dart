import 'dart:io';

import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';

class SecurityHandler{

  static Future<Map<String, String>> getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'deviceHash': SecurityHandler.stringToHash(androidInfo.id),
        'deviceName': '${androidInfo.brand} ${androidInfo.model}',
        'platform': 'android',
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'deviceHash': iosInfo.identifierForVendor == null ? 'unknown_ios' : SecurityHandler.stringToHash(iosInfo.identifierForVendor!),
        'deviceName': iosInfo.utsname.machine,
        'platform': 'ios',
      };
    } else {
      return {
        'deviceId': 'unsupported',
        'deviceName': 'unsupported',
        'platform': 'unknown',
      };
    }
  }


  static String stringToHash(String item) {
    final bytes = utf8.encode(item);
    final digest = sha256.convert(bytes);
    return digest.toString(); // 해시된 ID
  }

}