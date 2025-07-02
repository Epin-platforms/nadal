// Advertisement_Provider.dart - ATT 권한 처리 추가

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // 🔧 추가
import 'package:device_info_plus/device_info_plus.dart'; // 🔧 추가
import 'package:shared_preferences/shared_preferences.dart'; // 🔧 추가
import 'package:my_sports_calendar/manager/server/Server_Manager.dart'; // 🔧 추가
import 'package:my_sports_calendar/model/ad/Advertisement.dart';

enum AdType {
  banner,
  medium,
  nativeListTile
}

class AdvertisementProvider extends ChangeNotifier {
  // === Core State ===
  final Map<String, BannerAd?> _bannerAds = {};
  final Map<String, NativeAd?> _nativeAds = {};
  final Map<String, bool> _loadingStates = {};
  final Map<String, bool> _loadedStates = {};
  final Map<String, Timer?> _timeouts = {};

  bool _isDisposed = false;
  static const int _maxRetries = 2;
  static const int _timeoutSeconds = 10;

  // 🔧 ATT 권한 관련 상태
  bool _isATTInitialized = false;
  bool _isATTGranted = false;
  static const String _attRequestedKey = 'advertisement_att_requested';
  static const String _attGrantedKey = 'advertisement_att_granted';

  // 🔧 ATT 권한 상태 getter
  bool get isATTGranted => _isATTGranted;
  bool get isATTInitialized => _isATTInitialized;

  // === Ad Unit IDs === (기존과 동일)
  static String get _bannerAdUnitId {
    if (Platform.isIOS) {
      if(kDebugMode){
        return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner
      }else{
        return 'ca-app-pub-8848225479931343/1639526864';
      }
    }
    if(kDebugMode){
      return 'ca-app-pub-3940256099942544/6300978111'; // Android Test Banner
    }else{
      return 'ca-app-pub-8848225479931343/1620195622';
    }
  }

  static String get _nativeAdUnitId {
    if (Platform.isIOS) {
      if(kDebugMode){
        return 'ca-app-pub-3940256099942544/3986624511'; // iOS Test Native
      }
      return 'ca-app-pub-8848225479931343/7626350713';
    }
    if(kDebugMode){
      return 'ca-app-pub-3940256099942544/2247696110'; // Android Test Native
    }else{
      return 'ca-app-pub-8848225479931343/6185615842';
    }
  }

  Future<void> initializeWithoutATT() async {
    if (_isATTInitialized) {
      debugPrint('✅ ATT 이미 초기화됨 - 스킵');
      return;
    }

    try {
      debugPrint('🔧 Advertisement Provider - ATT 없이 초기화 시작');

      // ATT 권한 거부 상태로 설정
      _isATTGranted = false;

      // SharedPreferences에 거부 상태 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_attRequestedKey, true);
      await prefs.setBool(_attGrantedKey, false);

      // AdMob 초기화 (비개인화 광고용)
      await _initializeAdMob();

      _isATTInitialized = true;
      debugPrint('✅ Advertisement Provider ATT 없이 초기화 완료');

    } catch (e) {
      debugPrint('❌ Advertisement Provider ATT 없이 초기화 실패: $e');
      _isATTInitialized = true; // 실패해도 마크하여 재시도 방지
    }
  }

// 🔧 **기존 _requestAppTrackingTransparency() 메서드 수정**
  Future<bool> _requestAppTrackingTransparency() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 이미 요청했는지 확인
      final alreadyRequested = prefs.getBool(_attRequestedKey) ?? false;
      if (alreadyRequested) {
        final isGranted = prefs.getBool(_attGrantedKey) ?? false;
        debugPrint('🍎 ATT 권한 이미 요청됨 - 결과: $isGranted');
        return isGranted;
      }

      // iOS 버전 확인 (14.5+ 필요)
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      final version = iosInfo.systemVersion.split('.');
      final majorVersion = int.tryParse(version[0]) ?? 0;
      final minorVersion = version.length > 1 ? int.tryParse(version[1]) ?? 0 : 0;

      // iOS 14.5 미만은 권한 요청 불필요
      if (majorVersion < 14 || (majorVersion == 14 && minorVersion < 5)) {
        debugPrint('🍎 iOS 14.5 미만 - ATT 권한 불필요');
        await prefs.setBool(_attRequestedKey, true);
        await prefs.setBool(_attGrantedKey, true);
        return true;
      }

      // 🔧 **ATT 권한 실제 요청 (더 명확한 로깅)**
      debugPrint('🍎 iOS 시스템 ATT 권한 다이얼로그 표시');

      // 잠시 대기 (사용자가 우리 다이얼로그를 충분히 읽을 시간)
      await Future.delayed(const Duration(milliseconds: 500));

      final status = await Permission.appTrackingTransparency.request();
      final isGranted = status == PermissionStatus.granted;

      // 결과 저장
      await prefs.setBool(_attRequestedKey, true);
      await prefs.setBool(_attGrantedKey, isGranted);

      debugPrint('🍎 ATT 권한 요청 완료 - 결과: $isGranted');
      debugPrint('🍎 사용자 선택: ${isGranted ? "허용" : "거부"}');

      return isGranted;

    } catch (e) {
      debugPrint('❌ ATT 권한 요청 실패: $e');

      // 실패 시에도 요청했다고 기록
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_attRequestedKey, true);
      await prefs.setBool(_attGrantedKey, false);

      return false;
    }
  }

// 🔧 **기존 _createAdRequest() 메서드 개선**
  AdRequest _createAdRequest() {
    return AdRequest(
      // ATT 권한이 없으면 비개인화 광고 요청
      nonPersonalizedAds: !_isATTGranted,
      keywords: _isATTGranted ? null : ['general'], // 비개인화 광고용 키워드
    );
  }

// 🔧 **ATT 권한 상태 확인 메서드 개선**
  Future<String> getATTStatusForDebug() async {
    if (!Platform.isIOS) return 'Android - ATT 불필요';

    try {
      final prefs = await SharedPreferences.getInstance();
      final requested = prefs.getBool(_attRequestedKey) ?? false;
      final granted = prefs.getBool(_attGrantedKey) ?? false;

      if (!requested) return 'ATT 권한 미요청';
      return granted ? 'ATT 권한 허용됨' : 'ATT 권한 거부됨';
    } catch (e) {
      return 'ATT 상태 확인 실패';
    }
  }

// 🔧 **ATT 권한 재요청 다이얼로그 개선**
  Future<void> showATTSettingsDialog(BuildContext context) async {
    final status = await getATTStatusForDebug();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).primaryColor),
            SizedBox(width: 8.w),
            Text('추적 권한 설정'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 상태: $status'),
            SizedBox(height: 12.h),
            Text(
              '맞춤형 광고를 위한 추적 권한은 iOS 설정에서 변경할 수 있습니다.\n\n'
                  '설정 경로:\n'
                  '설정 → 개인 정보 보호 및 보안 → 추적 → 나스달',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('설정 열기'),
          ),
        ],
      ),
    );
  }


  // 🔧 AdMob 초기화 with ATT 권한 처리
  Future<void> initializeWithATT() async {
    if (_isATTInitialized) {
      debugPrint('✅ ATT 이미 초기화됨 - 스킵');
      return;
    }

    try {
      debugPrint('🔧 Advertisement Provider - ATT 권한 처리 시작');

      // 1. ATT 권한 요청 (iOS만)
      if (Platform.isIOS) {
        _isATTGranted = await _requestAppTrackingTransparency();
      } else {
        _isATTGranted = true; // Android는 항상 true
      }

      // 2. AdMob 초기화
      await _initializeAdMob();

      _isATTInitialized = true;
      debugPrint('✅ Advertisement Provider 초기화 완료 - ATT: $_isATTGranted');

    } catch (e) {
      debugPrint('❌ Advertisement Provider 초기화 실패: $e');
      _isATTInitialized = true; // 실패해도 마크하여 재시도 방지
    }
  }


  // 🔧 AdMob 초기화 (ATT 권한 결과 반영)
  Future<void> _initializeAdMob() async {
    try {
      // ATT 권한에 따른 AdMob 설정
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        maxAdContentRating: MaxAdContentRating.g,
        testDeviceIds: kDebugMode ? ['test-device-id'] : [], // 테스트 모드에서만
      );

      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      await MobileAds.instance.initialize();

      debugPrint('📱 AdMob 초기화 완료 - 추적 권한: $_isATTGranted');

    } catch (e) {
      debugPrint('❌ AdMob 초기화 실패: $e');
      rethrow;
    }
  }


  // === 기존 광고 로드 메서드들 수정 ===

  // 배너 광고 로드 (ATT 권한 확인 추가)
  Future<void> loadBannerAd(String key) async {
    if (_isDisposed) return;

    // ATT 초기화 확인
    if (!_isATTInitialized) {
      await initializeWithATT();
    }

    if (_loadingStates[key] == true || _loadedStates[key] == true) return;

    _setLoadingState(key, true);
    _startTimeout(key);

    try {
      final bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: _createAdRequest(), // 🔧 ATT 권한 반영
        listener: BannerAdListener(
          onAdLoaded: (ad) => _onAdLoaded(key, ad),
          onAdFailedToLoad: (ad, error) => _onAdFailedToLoad(key, ad, error),
        ),
      );

      await bannerAd.load();
      _bannerAds[key] = bannerAd;

    } catch (e) {
      _onLoadError(key, e);
    }
  }

  // 미디엄 광고 로드 (ATT 권한 확인 추가)
  Future<void> loadMediumAd(String key) async {
    if (_isDisposed) return;

    // ATT 초기화 확인
    if (!_isATTInitialized) {
      await initializeWithATT();
    }

    if (_loadingStates[key] == true || _loadedStates[key] == true) return;

    _setLoadingState(key, true);
    _startTimeout(key);

    try {
      final bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.mediumRectangle,
        request: _createAdRequest(), // 🔧 ATT 권한 반영
        listener: BannerAdListener(
          onAdLoaded: (ad) => _onAdLoaded(key, ad),
          onAdFailedToLoad: (ad, error) => _onAdFailedToLoad(key, ad, error),
        ),
      );

      await bannerAd.load();
      _bannerAds[key] = bannerAd;

    } catch (e) {
      _onLoadError(key, e);
    }
  }

  // 네이티브 광고 로드 (ATT 권한 확인 추가)
  Future<void> loadNativeListTileAd(String key) async {
    if (_isDisposed) return;

    // ATT 초기화 확인
    if (!_isATTInitialized) {
      await initializeWithATT();
    }

    if (_loadingStates[key] == true || _loadedStates[key] == true) return;

    _setLoadingState(key, true);
    _startTimeout(key);

    try {
      final nativeAd = NativeAd(
        adUnitId: _nativeAdUnitId,
        request: _createAdRequest(), // 🔧 ATT 권한 반영
        factoryId: 'listTile',
        listener: NativeAdListener(
          onAdLoaded: (ad) => _onAdLoaded(key, ad),
          onAdFailedToLoad: (ad, error) => _onAdFailedToLoad(key, ad, error),
        ),
      );

      await nativeAd.load();
      _nativeAds[key] = nativeAd;

    } catch (e) {
      _onLoadError(key, e);
    }
  }

  // 🔧 ATT 권한 상태 확인 메서드
  Future<bool> checkATTPermissionStatus() async {
    if (!Platform.isIOS) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_attGrantedKey) ?? false;
    } catch (e) {
      debugPrint('ATT 권한 상태 확인 실패: $e');
      return false;
    }
  }

  // === 기존 메서드들 (수정 없음) ===
  bool isLoading(String key) => _loadingStates[key] ?? false;
  bool isLoaded(String key) => _loadedStates[key] ?? false;
  BannerAd? getBannerAd(String key) => _bannerAds[key];
  NativeAd? getNativeAd(String key) => _nativeAds[key];

  bool hasValidBannerAd(String key) {
    final ad = _bannerAds[key];
    return ad != null && _loadedStates[key] == true;
  }

  bool hasValidNativeAd(String key) {
    final ad = _nativeAds[key];
    return ad != null && _loadedStates[key] == true;
  }

  void _setLoadingState(String key, bool loading) {
    _loadingStates[key] = loading;
    if (!_isDisposed) notifyListeners();
  }

  void _setLoadedState(String key, bool loaded) {
    _loadedStates[key] = loaded;
    if (!_isDisposed) notifyListeners();
  }

  void _startTimeout(String key) {
    _timeouts[key]?.cancel();
    _timeouts[key] = Timer(Duration(seconds: _timeoutSeconds), () {
      if (_loadingStates[key] == true) {
        _onLoadError(key, Exception('광고 로드 타임아웃'));
      }
    });
  }

  void _onAdLoaded(String key, Ad ad) {
    _timeouts[key]?.cancel();
    _setLoadingState(key, false);
    _setLoadedState(key, true);
    debugPrint('✅ 광고 로드 성공: $key');
  }

  void _onAdFailedToLoad(String key, Ad ad, LoadAdError error) {
    _timeouts[key]?.cancel();
    _setLoadingState(key, false);
    _setLoadedState(key, false);
    debugPrint('❌ 광고 로드 실패: $key - $error');
    ad.dispose();
  }

  void _onLoadError(String key, dynamic error) {
    _timeouts[key]?.cancel();
    _setLoadingState(key, false);
    _setLoadedState(key, false);
    debugPrint('❌ 광고 로드 에러: $key - $error');
  }

  // === 다중 광고 로드 ===
  Future<void> loadMultipleAds(Map<String, AdType> adConfigs) async {
    final futures = adConfigs.entries.map((entry) {
      final key = entry.key;
      final type = entry.value;

      switch (type) {
        case AdType.banner:
          return loadBannerAd(key);
        case AdType.medium:
          return loadMediumAd(key);
        case AdType.nativeListTile:
          return loadNativeListTileAd(key);
      }
    });

    await Future.wait(futures);
  }

  // === 정리 메서드들 ===
  void disposeAd(String key) {
    _timeouts[key]?.cancel();
    _timeouts.remove(key);

    _bannerAds[key]?.dispose();
    _bannerAds.remove(key);

    _nativeAds[key]?.dispose();
    _nativeAds.remove(key);

    _loadingStates.remove(key);
    _loadedStates.remove(key);

    if (!_isDisposed) notifyListeners();
  }

  void disposePageAds(String pageKey) {
    final keysToRemove = <String>[];

    for (final key in _bannerAds.keys) {
      if (key.startsWith(pageKey)) {
        keysToRemove.add(key);
      }
    }

    for (final key in _nativeAds.keys) {
      if (key.startsWith(pageKey)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      disposeAd(key);
    }

    debugPrint('🗑️ 페이지 광고 정리 완료: $pageKey (${keysToRemove.length}개)');
  }

  @override
  void dispose() {
    _isDisposed = true;

    for (final timer in _timeouts.values) {
      timer?.cancel();
    }
    _timeouts.clear();

    for (final ad in _bannerAds.values) {
      ad?.dispose();
    }
    _bannerAds.clear();

    for (final ad in _nativeAds.values) {
      ad?.dispose();
    }
    _nativeAds.clear();

    _loadingStates.clear();
    _loadedStates.clear();

    super.dispose();
  }

  // === 서버 광고 관련 (기존과 동일하게 유지) ===
  Future<Advertisement> fetchServerAd() async {
    try {
      final response = await serverManager.get('app/ad');
      if (response.statusCode == 200) {
        return Advertisement.fromJson(response.data);
      }
      throw Exception('Server ad fetch failed');
    } catch (e) {
      throw Exception('광고 로드 실패: $e');
    }
  }
}

// === 기존 위젯들 그대로 유지 ===

// === Simple Banner Widget ===
class SimpleBannerAdWidget extends StatelessWidget {
  final String adKey;
  final double? height;
  final EdgeInsets? margin;

  const SimpleBannerAdWidget({
    super.key,
    required this.adKey,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvertisementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading(adKey)) {
          return _buildLoadingWidget();
        }

        if (!provider.hasValidBannerAd(adKey)) {
          return const SizedBox.shrink();
        }

        return _buildAdWidget(provider.getBannerAd(adKey)!);
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: height ?? 50.h,
      margin: margin ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: SizedBox(
          width: 16.w,
          height: 16.h,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  Widget _buildAdWidget(BannerAd ad) {
    return Container(
      height: height ?? 50.h,
      margin: margin ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!, width: 1.w),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: AdWidget(ad: ad),
      ),
    );
  }
}

// === Medium Ad Widget ===
class MediumAdWidget extends StatelessWidget {
  final String adKey;
  final double? height;
  final EdgeInsets? margin;
  final bool showLabel;

  const MediumAdWidget({
    super.key,
    required this.adKey,
    this.height,
    this.margin,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvertisementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading(adKey)) {
          return _buildLoadingWidget();
        }

        if (!provider.hasValidBannerAd(adKey)) {
          return const SizedBox.shrink();
        }

        return _buildAdWidget(provider.getBannerAd(adKey)!);
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: height ?? 250.h,
      margin: margin ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!, width: 1.w),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '광고 로딩 중...',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdWidget(BannerAd ad) {
    return Container(
      height: height ?? 250.h,
      margin: margin ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          if (showLabel) _buildAdLabel(),
          Expanded(
            child: ClipRRect(
              borderRadius: showLabel
                  ? BorderRadius.only(
                bottomLeft: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
              )
                  : BorderRadius.circular(12.r),
              child: AdWidget(ad: ad),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdLabel() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 12.sp,
            color: Colors.orange[600],
          ),
          SizedBox(width: 4.w),
          Text(
            '광고',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.orange[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'AD',
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// === Native ListTile Ad Widget ===
class NativeListTileAdWidget extends StatelessWidget {
  final String adKey;
  final EdgeInsets? padding;

  const NativeListTileAdWidget({
    super.key,
    required this.adKey,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvertisementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading(adKey)) {
          return _buildLoadingListTile();
        }

        if (!provider.hasValidNativeAd(adKey)) {
          return const SizedBox.shrink();
        }

        return _buildNativeAdListTile(provider.getNativeAd(adKey)!);
      },
    );
  }

  Widget _buildLoadingListTile() {
    return Container(
      margin: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: ListTile(
        leading: Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        title: Container(
          height: 12.h,
          width: double.infinity,
          color: Colors.grey[200],
        ),
        subtitle: Container(
          height: 10.h,
          width: 150.w,
          color: Colors.grey[200],
          margin: EdgeInsets.only(top: 4.h),
        ),
        trailing: SizedBox(
          width: 16.w,
          height: 16.h,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  Widget _buildNativeAdListTile(NativeAd ad) {
    return Container(
      margin: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!, width: 1.w),
      ),
      child: Column(
        children: [
          // 광고 라벨
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 10.sp,
                  color: Colors.orange[600],
                ),
                SizedBox(width: 4.w),
                Text(
                  '광고',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.orange[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'AD',
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 네이티브 광고 콘텐츠
          Container(
            height: 80.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: AdWidget(ad: ad),
            ),
          ),
        ],
      ),
    );
  }
}

// === AdManager 클래스 수정 ===
class AdManager {
  static final AdvertisementProvider _instance = AdvertisementProvider();

  static AdvertisementProvider get instance => _instance;

  // 🔧 초기화 메서드 추가
  static Future<void> initialize() async {
    await _instance.initializeWithATT();
  }

  // 기존 메서드들 유지...
  static Future<void> loadPageAds({
    required String pageKey,
    bool includeBanner = true,
    int mediumAdCount = 0,
    int nativeListTileAdCount = 0,
  }) async {
    final configs = <String, AdType>{};

    if (includeBanner) {
      configs['${pageKey}_banner'] = AdType.banner;
    }

    for (int i = 0; i < mediumAdCount; i++) {
      configs['${pageKey}_medium_$i'] = AdType.medium;
    }

    for (int i = 0; i < nativeListTileAdCount; i++) {
      configs['${pageKey}_nativeListTile_$i'] = AdType.nativeListTile;
    }

    if (configs.isNotEmpty) {
      await _instance.loadMultipleAds(configs);
    }
  }

  static void disposePageAds(String pageKey) {
    _instance.disposePageAds(pageKey);
  }

  static void refreshPageAds({
    required String pageKey,
    bool includeBanner = true,
    int mediumAdCount = 0,
    int nativeListTileAdCount = 0,
  }) {
    disposePageAds(pageKey);
    loadPageAds(
      pageKey: pageKey,
      includeBanner: includeBanner,
      mediumAdCount: mediumAdCount,
      nativeListTileAdCount: nativeListTileAdCount,
    );
  }
}