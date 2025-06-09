// === Enhanced Advertisement Provider ===
// 기존 Advertisement_Provider에 Google Ads 기능 추가
// 복잡한 네이티브 광고 대신 안전하고 간단한 배너 광고 사용

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/ad/Advertisement.dart';

enum NativeAdType {
  banner,    // 배너형 네이티브 광고
  listItem   // 리스트 아이템형 네이티브 광고
}

class AdvertisementProvider extends ChangeNotifier {
  // === Core Ad Data ===
  Map<String, NativeAd?> _nativeAds = {};
  Map<String, BannerAd?> _bannerAds = {};
  Map<String, bool> _adLoadingStates = {};
  Map<String, bool> _adLoadedStates = {};

  // === Ad Configuration ===
  static const String _nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110'; // Test Native ID
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test Banner ID

  // === Getters ===
  Map<String, NativeAd?> get nativeAds => Map.unmodifiable(_nativeAds);
  Map<String, BannerAd?> get bannerAds => Map.unmodifiable(_bannerAds);
  bool isAdLoading(String adKey) => _adLoadingStates[adKey] ?? false;
  bool isAdLoaded(String adKey) => _adLoadedStates[adKey] ?? false;
  NativeAd? getNativeAd(String adKey) => _nativeAds[adKey];
  BannerAd? getBannerAd(String adKey) => _bannerAds[adKey];

  // === Original Server Ad Method ===
  Future<Advertisement> fetchAd() async {
    final response = await serverManager.get('app/ad');
    if (response.statusCode == 200) {
      return Advertisement.fromJson(response.data);
    } else {
      throw Exception('광고를 불러오지 못했습니다');
    }
  }

  // === Native Ad Management ===

  /// 네이티브 광고 로드 (배너형) - 간단한 배너 광고 사용
  Future<void> loadBannerNativeAd(String adKey) async {
    if (_adLoadingStates[adKey] == true || _adLoadedStates[adKey] == true) {
      return; // 이미 로딩 중이거나 로드됨
    }

    _adLoadingStates[adKey] = true;
    notifyListeners();

    try {
      final bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => _onBannerAdLoaded(adKey, ad as BannerAd),
          onAdFailedToLoad: (ad, error) => _onBannerAdFailedToLoad(adKey, ad, error),
          onAdClicked: (ad) => _onAdClicked(adKey),
          onAdImpression: (ad) => _onAdImpression(adKey),
        ),
      );

      await bannerAd.load();
      _bannerAds[adKey] = bannerAd;
    } catch (e) {
      _onBannerAdFailedToLoad(adKey, null, LoadAdError(0, 'domain', 'Load failed: $e', null));
    }
  }

  /// 네이티브 광고 로드 (리스트 아이템형) - 더 큰 배너 사용
  Future<void> loadListItemNativeAd(String adKey) async {
    if (_adLoadingStates[adKey] == true || _adLoadedStates[adKey] == true) {
      return; // 이미 로딩 중이거나 로드됨
    }

    _adLoadingStates[adKey] = true;
    notifyListeners();

    try {
      final bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.mediumRectangle,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => _onBannerAdLoaded(adKey, ad as BannerAd),
          onAdFailedToLoad: (ad, error) => _onBannerAdFailedToLoad(adKey, ad, error),
          onAdClicked: (ad) => _onAdClicked(adKey),
          onAdImpression: (ad) => _onAdImpression(adKey),
        ),
      );

      await bannerAd.load();
      _bannerAds[adKey] = bannerAd;
    } catch (e) {
      _onBannerAdFailedToLoad(adKey, null, LoadAdError(0, 'domain', 'Load failed: $e', null));
    }
  }

  /// 다중 광고 배치 로드
  Future<void> loadMultipleAds(Map<String, NativeAdType> adConfigs) async {
    final loadFutures = <Future<void>>[];

    for (final entry in adConfigs.entries) {
      final adKey = entry.key;
      final adType = entry.value;

      switch (adType) {
        case NativeAdType.banner:
          loadFutures.add(loadBannerNativeAd(adKey));
          break;
        case NativeAdType.listItem:
          loadFutures.add(loadListItemNativeAd(adKey));
          break;
      }
    }

    await Future.wait(loadFutures);
  }

  // === Event Handlers ===

  void _onBannerAdLoaded(String adKey, BannerAd ad) {
    _adLoadingStates[adKey] = false;
    _adLoadedStates[adKey] = true;
    notifyListeners();
  }

  void _onBannerAdFailedToLoad(String adKey, Ad? ad, LoadAdError error) {
    _adLoadingStates[adKey] = false;
    _adLoadedStates[adKey] = false;
    ad?.dispose();
    _bannerAds.remove(adKey);
    notifyListeners();
  }

  void _onAdClicked(String adKey) {
    // 광고 클릭 이벤트 처리 (필요시 분석 데이터 전송)
  }

  void _onAdImpression(String adKey) {
    // 광고 노출 이벤트 처리 (필요시 분석 데이터 전송)
  }

  // === Ad Disposal ===

  /// 특정 광고 해제
  void disposeAd(String adKey) {
    final nativeAd = _nativeAds[adKey];
    final bannerAd = _bannerAds[adKey];

    if (nativeAd != null) {
      nativeAd.dispose();
      _nativeAds.remove(adKey);
    }

    if (bannerAd != null) {
      bannerAd.dispose();
      _bannerAds.remove(adKey);
    }

    _adLoadingStates.remove(adKey);
    _adLoadedStates.remove(adKey);
    notifyListeners();
  }

  /// 모든 광고 해제
  void disposeAllAds() {
    for (final ad in _nativeAds.values) {
      ad?.dispose();
    }
    for (final ad in _bannerAds.values) {
      ad?.dispose();
    }
    _nativeAds.clear();
    _bannerAds.clear();
    _adLoadingStates.clear();
    _adLoadedStates.clear();
    notifyListeners();
  }

  // === Utility Methods ===

  /// 광고 새로고침
  Future<void> refreshAd(String adKey, NativeAdType adType) async {
    disposeAd(adKey);

    switch (adType) {
      case NativeAdType.banner:
        await loadBannerNativeAd(adKey);
        break;
      case NativeAdType.listItem:
        await loadListItemNativeAd(adKey);
        break;
    }
  }

  /// 광고 가용성 체크
  bool hasValidAd(String adKey) {
    return _adLoadedStates[adKey] == true &&
        (_nativeAds[adKey] != null || _bannerAds[adKey] != null);
  }

  @override
  void dispose() {
    disposeAllAds();
    super.dispose();
  }
}

// === Banner Native Ad Widget ===
class BannerNativeAdWidget extends StatelessWidget {
  final String adKey;
  final double? height;
  final EdgeInsets? margin;

  const BannerNativeAdWidget({
    Key? key,
    required this.adKey,
    this.height,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvertisementProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isAdLoading(adKey);
        final isLoaded = provider.isAdLoaded(adKey);
        final ad = provider.getBannerAd(adKey);

        if (isLoading) {
          return Container(
            height: height ?? 80.h,
            margin: margin ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                ),
              ),
            ),
          );
        }

        if (!isLoaded || ad == null) {
          return SizedBox.shrink();
        }

        return Container(
          height: height ?? 80.h,
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
      },
    );
  }
}

// === List Item Native Ad Widget ===
class ListItemNativeAdWidget extends StatelessWidget {
  final String adKey;
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const ListItemNativeAdWidget({
    Key? key,
    required this.adKey,
    this.height,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvertisementProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isAdLoading(adKey);
        final isLoaded = provider.isAdLoaded(adKey);
        final ad = provider.getBannerAd(adKey);

        if (isLoading) {
          return Container(
            height: height ?? 120.h,
            margin: margin ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            padding: padding ?? EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[200]!, width: 1.w),
            ),
            child: Center(
              child: SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                ),
              ),
            ),
          );
        }

        if (!isLoaded || ad == null) {
          return SizedBox.shrink();
        }

        return Container(
          height: height ?? 120.h,
          margin: margin ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
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
              // 광고 라벨
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
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
                      '스폰서',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'AD',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 광고 콘텐츠
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                  child: AdWidget(ad: ad),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// === Ad Manager Helper ===
class AdManager {
  static final AdvertisementProvider _provider = AdvertisementProvider();

  /// 싱글톤 인스턴스
  static AdvertisementProvider get instance => _provider;

  /// 페이지별 광고 로드 헬퍼
  static Future<void> loadPageAds(String pageKey, {
    bool includeBanner = true,
    int listItemCount = 0,
  }) async {
    final adConfigs = <String, NativeAdType>{};

    if (includeBanner) {
      adConfigs['${pageKey}_banner'] = NativeAdType.banner;
    }

    for (int i = 0; i < listItemCount; i++) {
      adConfigs['${pageKey}_list_$i'] = NativeAdType.listItem;
    }

    await _provider.loadMultipleAds(adConfigs);
  }

  /// 페이지 광고 해제 헬퍼
  static void disposePageAds(String pageKey) {
    final keysToDispose = _provider.nativeAds.keys
        .where((key) => key.startsWith(pageKey))
        .toList();

    for (final key in keysToDispose) {
      _provider.disposeAd(key);
    }
  }
}