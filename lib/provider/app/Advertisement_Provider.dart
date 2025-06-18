// === Clean Advertisement Provider with Native Ad Support ===
// 네이티브 광고 ID를 사용하는 깔끔한 버전

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
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

  // === Ad Unit IDs ===
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

  // === Getters ===
  bool isLoading(String key) => _loadingStates[key] ?? false;
  bool isLoaded(String key) => _loadedStates[key] ?? false;
  BannerAd? getBannerAd(String key) => _bannerAds[key];
  NativeAd? getNativeAd(String key) => _nativeAds[key];
  bool hasValidBannerAd(String key) => isLoaded(key) && getBannerAd(key) != null;
  bool hasValidNativeAd(String key) => isLoaded(key) && getNativeAd(key) != null;

  // === Server Ad (Original) ===
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

  // === Ad Loading Methods ===
  Future<void> loadBannerAd(String key) async {
    if (_isDisposed || _loadingStates[key] == true || _loadedStates[key] == true) {
      return;
    }
    await _loadBannerAdInternal(key, AdSize.banner);
  }

  Future<void> loadMediumAd(String key) async {
    if (_isDisposed || _loadingStates[key] == true || _loadedStates[key] == true) {
      return;
    }
    await _loadBannerAdInternal(key, AdSize.mediumRectangle);
  }

  Future<void> loadNativeListTileAd(String key) async {
    if (_isDisposed || _loadingStates[key] == true || _loadedStates[key] == true) {
      return;
    }
    await _loadNativeAdInternal(key);
  }

  // === Internal Loading Methods ===
  Future<void> _loadBannerAdInternal(String key, AdSize size) async {
    _setLoadingState(key, true);
    _startTimeout(key);

    int retryCount = 0;
    while (retryCount <= _maxRetries && !_isDisposed) {
      try {
        final ad = BannerAd(
          adUnitId: _bannerAdUnitId,
          size: size,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (ad) => _onBannerAdLoaded(key, ad as BannerAd),
            onAdFailedToLoad: (ad, error) => _onBannerAdFailed(key, ad, error),
          ),
        );

        await ad.load();
        _bannerAds[key] = ad;
        return;

      } catch (e) {
        retryCount++;
        if (retryCount > _maxRetries) {
          _onLoadError(key, 'Banner ad max retries exceeded: $e');
          return;
        }
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  Future<void> _loadNativeAdInternal(String key) async {
    _setLoadingState(key, true);
    _startTimeout(key);

    int retryCount = 0;
    while (retryCount <= _maxRetries && !_isDisposed) {
      try {
        final nativeAd = NativeAd(
          adUnitId: _nativeAdUnitId,
          request: const AdRequest(),
          listener: NativeAdListener(
            onAdLoaded: (ad) => _onNativeAdLoaded(key, ad as NativeAd),
            onAdFailedToLoad: (ad, error) => _onNativeAdFailed(key, ad, error),
          ),
          nativeTemplateStyle: NativeTemplateStyle(
            templateType: TemplateType.small,
            mainBackgroundColor: Colors.white,
            cornerRadius: 8.0,
            callToActionTextStyle: NativeTemplateTextStyle(
              textColor: Colors.white,
              backgroundColor: Colors.blue,
              style: NativeTemplateFontStyle.bold,
              size: 14.0,
            ),
            primaryTextStyle: NativeTemplateTextStyle(
              textColor: Colors.black,
              style: NativeTemplateFontStyle.bold,
              size: 16.0,
            ),
            secondaryTextStyle: NativeTemplateTextStyle(
              textColor: Colors.grey,
              style: NativeTemplateFontStyle.normal,
              size: 14.0,
            ),
          ),
        );

        await nativeAd.load();
        _nativeAds[key] = nativeAd;
        return;

      } catch (e) {
        retryCount++;
        if (retryCount > _maxRetries) {
          _onLoadError(key, 'Native ad max retries exceeded: $e');
          return;
        }
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  // === Batch Loading ===
  Future<void> loadMultipleAds(Map<String, AdType> configs) async {
    if (_isDisposed) return;

    final futures = <Future<void>>[];

    for (final entry in configs.entries) {
      final key = entry.key;
      final type = entry.value;

      switch (type) {
        case AdType.banner:
          futures.add(loadBannerAd(key));
          break;
        case AdType.medium:
          futures.add(loadMediumAd(key));
          break;
        case AdType.nativeListTile:
          futures.add(loadNativeListTileAd(key));
          break;
      }
    }

    await Future.wait(futures, eagerError: false);
  }

  // === Event Handlers ===
  void _onBannerAdLoaded(String key, BannerAd ad) {
    if (_isDisposed) {
      ad.dispose();
      return;
    }
    _cancelTimeout(key);
    _setLoadingState(key, false);
    _setLoadedState(key, true);
  }

  void _onBannerAdFailed(String key, Ad ad, LoadAdError error) {
    if (_isDisposed) return;
    _cancelTimeout(key);
    ad.dispose();
    _cleanupBannerAd(key);
    _onLoadError(key, 'Banner ad failed: ${error.message}');
  }

  void _onNativeAdLoaded(String key, NativeAd ad) {
    if (_isDisposed) {
      ad.dispose();
      return;
    }
    _cancelTimeout(key);
    _setLoadingState(key, false);
    _setLoadedState(key, true);
  }

  void _onNativeAdFailed(String key, Ad ad, LoadAdError error) {
    if (_isDisposed) return;
    _cancelTimeout(key);
    ad.dispose();
    _cleanupNativeAd(key);
    _onLoadError(key, 'Native ad failed: ${error.message}');
  }

  void _onLoadError(String key, String error) {
    if (_isDisposed) return;
    _setLoadingState(key, false);
    _setLoadedState(key, false);
    debugPrint('광고 로드 실패 [$key]: $error');
  }

  // === State Management ===
  void _setLoadingState(String key, bool loading) {
    if (_isDisposed) return;
    _loadingStates[key] = loading;
    notifyListeners();
  }

  void _setLoadedState(String key, bool loaded) {
    if (_isDisposed) return;
    _loadedStates[key] = loaded;
    notifyListeners();
  }

  void _startTimeout(String key) {
    _timeouts[key] = Timer(Duration(seconds: _timeoutSeconds), () {
      if (!_isDisposed) {
        _handleTimeout(key);
      }
    });
  }

  void _cancelTimeout(String key) {
    _timeouts[key]?.cancel();
    _timeouts.remove(key);
  }

  void _handleTimeout(String key) {
    if (_isDisposed) return;
    _cleanupAllForKey(key);
    _onLoadError(key, 'Ad load timeout');
  }

  // === Cleanup Methods ===
  void _cleanupBannerAd(String key) {
    final ad = _bannerAds[key];
    if (ad != null) {
      ad.dispose();
      _bannerAds.remove(key);
    }
  }

  void _cleanupNativeAd(String key) {
    final ad = _nativeAds[key];
    if (ad != null) {
      ad.dispose();
      _nativeAds.remove(key);
    }
  }

  void _cleanupAllForKey(String key) {
    _cleanupBannerAd(key);
    _cleanupNativeAd(key);
    _loadingStates.remove(key);
    _loadedStates.remove(key);
    _cancelTimeout(key);
  }

  // === Public Cleanup Methods ===
  void disposeAd(String key) {
    if (_isDisposed) return;
    _cleanupAllForKey(key);
    notifyListeners();
  }

  void disposePageAds(String pagePrefix) {
    if (_isDisposed) return;

    final allKeys = {..._bannerAds.keys, ..._nativeAds.keys};
    final keysToDispose = allKeys.where((key) => key.startsWith(pagePrefix)).toList();

    for (final key in keysToDispose) {
      _cleanupAllForKey(key);
    }

    //notifyListeners();
  }

  void refreshAd(String key, AdType type) {
    if (_isDisposed) return;
    disposeAd(key);

    switch (type) {
      case AdType.banner:
        loadBannerAd(key);
        break;
      case AdType.medium:
        loadMediumAd(key);
        break;
      case AdType.nativeListTile:
        loadNativeListTileAd(key);
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // 모든 타이머 취소
    for (final timer in _timeouts.values) {
      timer?.cancel();
    }
    _timeouts.clear();

    // 모든 광고 해제
    for (final ad in _bannerAds.values) {
      ad?.dispose();
    }
    for (final ad in _nativeAds.values) {
      ad?.dispose();
    }
    _bannerAds.clear();
    _nativeAds.clear();
    _loadingStates.clear();
    _loadedStates.clear();

    super.dispose();
  }
}

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
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          left: BorderSide(
            color: Colors.grey[300]!,
            width: 3.w,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          width: 40.w,
          height: 40.h,
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
        ),
        title: Container(
          height: 16.h,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        subtitle: Container(
          height: 12.h,
          margin: EdgeInsets.only(top: 4.h),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
    );
  }

  Widget _buildNativeAdListTile(NativeAd ad) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.orange[25],
        border: Border(
          left: BorderSide(
            color: Colors.orange[300]!,
            width: 3.w,
          ),
        ),
      ),
      child: Column(
        children: [
          // 광고 라벨
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
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

// === Ad Manager Helper ===
class AdManager {
  static final AdvertisementProvider _instance = AdvertisementProvider();

  static AdvertisementProvider get instance => _instance;

  // 페이지별 광고 로드
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

  // 페이지 광고 정리
  static void disposePageAds(String pageKey) {
    _instance.disposePageAds(pageKey);
  }

  // 광고 새로고침
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