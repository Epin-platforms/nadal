import 'package:flutter/material.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/ad/Advertisement.dart';

class AdvertisementProvider extends ChangeNotifier{
  Future<Advertisement> fetchAd() async {
    final response = await serverManager.get('app/ad');
    if (response.statusCode == 200) {
      return Advertisement.fromJson(response.data);
    } else {
      throw Exception('광고를 불러오지 못했습니다');
    }
  }

}