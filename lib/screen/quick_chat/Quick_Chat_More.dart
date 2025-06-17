import 'package:my_sports_calendar/screen/league/League_Widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../manager/project/Import_Manager.dart';
import '../../widget/Nadal_Room_Frame.dart';
import '../../provider/app/Advertisement_Provider.dart';
import '../../model/ad/Advertisement.dart';

class QuickChatMore extends StatefulWidget {
  const QuickChatMore({super.key, required this.homeProvider});
  final HomeProvider homeProvider;

  @override
  State<QuickChatMore> createState() => _QuickChatMoreState();
}

class _QuickChatMoreState extends State<QuickChatMore> {
  late AdvertisementProvider _adProvider;
  Advertisement? _serverAd;
  bool _isLoadingServerAd = false;
  bool _serverAdLoadFailed = false;
  bool _shouldShowServerAd = false; // 확률로 결정된 광고 타입

  static const String _pageKey = 'quick_chat_more';
  static const double _serverAdProbability = 0.6; // 60% 확률

  @override
  void initState() {
    super.initState();
    _adProvider = context.read<AdvertisementProvider>();
    widget.homeProvider.fetchHotQuickChatRooms();
    widget.homeProvider.fetchRanking();
    _initializeAds();
  }

  /// 광고 초기화
  Future<void> _initializeAds() async {
    // 확률로 광고 타입 결정 (60% 서버, 40% 구글)
    _shouldShowServerAd = _generateRandomProbability() < _serverAdProbability;

    // 네이티브 광고는 항상 미리 로드 (대체용)
    await _adProvider.loadBannerAd('${_pageKey}_more_banner');
    await _adProvider.loadMediumAd('${_pageKey}_medium');

    // 서버 광고 표시 확률이면 서버 광고 로드 시도
    if (_shouldShowServerAd) {
      _loadServerAd();
    }
  }

  /// 0.0~1.0 랜덤 확률 생성
  double _generateRandomProbability() {
    final now = DateTime.now();
    final seed = now.microsecondsSinceEpoch % 1000000;
    final random = (seed * 9301 + 49297) % 233280;
    return random / 233280.0;
  }

  /// 서버 광고 로드
  Future<void> _loadServerAd() async {
    if (_isLoadingServerAd) return;

    _isLoadingServerAd = true;
    _serverAdLoadFailed = false;

    try {
      final serverAd = await _adProvider.fetchServerAd();
      if (mounted) {
        _serverAd = serverAd;
        _isLoadingServerAd = false;
        _serverAdLoadFailed = false;
      }
    } catch (e) {
      if (mounted) {
        _serverAd = null;
        _isLoadingServerAd = false;
        _serverAdLoadFailed = true;
        debugPrint('서버 광고 로드 실패: $e');
      }
    }
  }

  @override
  void dispose() {
    // 페이지 광고 정리
    AdManager.disposePageAds(_pageKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SimpleBannerAdWidget(adKey: '${_pageKey}_more_banner'),
        ),
        widget.homeProvider.hotQuickChatRooms == null ?
        SliverToBoxAdapter(
          child: SizedBox(
            height: 300.h,
            child: Center(
              child: NadalCircular(),
            ),
          ),
        ) :
        SliverToBoxAdapter(
          child: Padding(
              padding: EdgeInsetsGeometry.only(left: 16.w, top: 14.h, bottom: 12.h),
              child: Text('요즘 핫한 나스달 인기방🔥', style: Theme.of(context).textTheme.titleMedium,)),
        ),
        if(widget.homeProvider.hotQuickChatRooms != null && widget.homeProvider.hotQuickChatRooms!.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: NadalEmptyList(title: '아직 인기방이 없어요',
                  subtitle: '지금 바로 방을 만들고 사람을 모아 인기방을 운영해보세요',
                  actionText: '번개방 만들기',
                  onAction: ()=> context.push('/createRoom?isOpen=TRUE')),
            ),
          )
        else if(widget.homeProvider.hotQuickChatRooms != null && widget.homeProvider.hotQuickChatRooms!.isNotEmpty)
          SliverList.builder(
              itemCount: widget.homeProvider.hotQuickChatRooms!.length,
              itemBuilder: (context, index){
                final item = widget.homeProvider.hotQuickChatRooms![index];
                return ListTile(
                  onTap: ()=> context.push('/previewRoom/${item['roomId']}'),
                  leading: NadalRoomFrame(imageUrl: item['roomImage']),
                  title: Text(
                    item['roomName'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 36.h),
                          child: Text(
                            _getItemDescription(item),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: Text(
                          '${item['memberCount']}/200',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }
          ),
        if(widget.homeProvider.hotQuickChatRooms != null && widget.homeProvider.hotQuickChatRooms!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 16.w, vertical: 8.h),
              child: InkWell(
                onTap: ()=> widget.homeProvider.fetchHotQuickChatRooms(),
                child: NadalSolidContainer(
                  height: 32.h,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 16.r, color: Theme.of(context).secondaryHeaderColor,),
                      SizedBox(width: 4.w,),
                      Text('다른 인기방 보기', style: Theme.of(context).textTheme.labelMedium,),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 광고 섹션 - 서버 광고 우선, 없으면 네이티브 광고
        _buildAdSection(),

        if(widget.homeProvider.ranking.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
                padding: EdgeInsetsGeometry.only(left: 16.w, top: 14.h, bottom: 12.h),
                child: Text('🏆실시간 나스달 랭킹', style: Theme.of(context).textTheme.titleMedium,)),
          ),
        if(widget.homeProvider.ranking.isNotEmpty)
          SliverList.builder(
              itemCount: widget.homeProvider.ranking.length,
              itemBuilder: (context, index){
                final member = widget.homeProvider.ranking[index];
                return ListTile(
                  onTap: ()=> context.push('/user/${member['uid']}'),
                  leading: NadalProfileFrame(
                    imageUrl: member['profileImage'],
                    size: 46.r,
                  ),
                  title: Text('${_getRankingBadge(index)}${member['nickName']}', style: Theme.of(context).textTheme.titleMedium,),
                  subtitle: Text(member['roomName'] ?? '소속 없음', style: Theme.of(context).textTheme.bodySmall,),
                  trailing: Text('${(member['totalFluctuation'] as num) >= 0 ? '+' : ''}${(member['totalFluctuation'] as num).toDouble().toStringAsFixed(2)}', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: (member['totalFluctuation'] as num) >= 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error
                  ),),
                );
              }
          )
      ],
    );
  }

  /// 광고 섹션 빌드
  Widget _buildAdSection() {
    // 서버 광고가 선택되고 성공적으로 로드된 경우만 서버 광고 표시
    if (_shouldShowServerAd &&
        !_isLoadingServerAd &&
        !_serverAdLoadFailed &&
        _serverAd != null) {
      return _buildServerAdWidget(_serverAd!);
    }

    // 다른 모든 경우에는 구글 네이티브 광고 표시
    // 1. 구글 광고가 확률적으로 선택된 경우 (40%)
    // 2. 서버 광고가 선택되었지만 로딩 중인 경우
    // 3. 서버 광고가 선택되었지만 로드 실패한 경우
    return SliverToBoxAdapter(
      child: Consumer<AdvertisementProvider>(
        builder: (context, provider, child) {
          return MediumAdWidget(
            adKey: '${_pageKey}_medium',
            height: 250.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            showLabel: true,
          );
        },
      ),
    );
  }

  /// 서버 광고 위젯 빌드
  Widget _buildServerAdWidget(Advertisement serverAd) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
            ),
            // 서버 광고 콘텐츠
            InkWell(
              onTap: () async{
                if (serverAd.link.isNotEmpty == true) {
                  final url = serverAd.link;
                  final Uri uri = Uri.parse(url);
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('URL을 열 수 없습니다: $url')),
                      );
                    }
                  }
                }
              },
              child: Container(
                width: double.infinity,
                height: 200.h,
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 광고 이미지 영역
                    if (serverAd.imageUrl.isNotEmpty == true)
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            image: DecorationImage(
                              image: NetworkImage(serverAd.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: 12.h),

                    // 광고 제목
                    if (serverAd.title.isNotEmpty == true)
                      Text(
                        serverAd.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    SizedBox(height: 4.h),

                    // 광고 설명
                    if (serverAd.advertiser.isNotEmpty == true)
                      Expanded(
                        flex: 1,
                        child: Text(
                          serverAd.advertiser,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRankingBadge(int rank){
    switch(rank){
      case 0 : return '🥇';
      case 1 : return '🥈';
      case 2 : return '🥉';
      default : return '';
    }
  }

  /// 아이템 설명 생성
  String _getItemDescription(dynamic item) {
    final description = item['description'] as String;
    final tag = item['tag'] as String;

    if (description.isNotEmpty) {
      return description;
    } else if (tag.isNotEmpty) {
      return tag;
    } else {
      return '정보없음';
    }
  }
}