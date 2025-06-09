import 'dart:ui';
import 'dart:async';

import 'package:intl/intl.dart';
import 'package:my_sports_calendar/manager/server/Server_Manager.dart';
import 'package:my_sports_calendar/model/ad/Advertisement.dart';
import 'package:my_sports_calendar/model/league/League_Model.dart';
import 'package:my_sports_calendar/provider/app/Advertisement_Provider.dart';
import 'package:my_sports_calendar/provider/league/League_Provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../manager/project/Import_Manager.dart';

class LeaguePage extends StatefulWidget {
  const LeaguePage({super.key});

  @override
  State<LeaguePage> createState() => _LeaguePageState();
}

class _LeaguePageState extends State<LeaguePage> {
  late LeagueProvider provider;
  late AdvertisementProvider adProvider;
  late TextEditingController _controller;
  late ScrollController _scrollController;
  Timer? _debounceTimer;

  @override
  void initState() {
    _controller = TextEditingController();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_){
      _scrollController.addListener((){
        if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100){
          provider.loadMore();
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 검색 입력 처리 (debounce)
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      provider.setSearchQuery(query);
    });
  }

  // URL 열기 함수
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URL을 열 수 없습니다: $url')),
        );
      }
    }
  }

  void _onAdClick(Advertisement ad) async {
    // 광고 URL 열기
    await _launchUrl(ad.link);

    // 클릭수 증가 API 호출 && 출력 시 조회수 증가 API 호출
    /*try {
      await serverManager.put('/app/click/${ad.adId}');
    } catch (e) {
      print('광고 클릭 카운트 오류: $e');
    }*/
  }

  @override
  Widget build(BuildContext context) {
    adProvider = Provider.of<AdvertisementProvider>(context);
    return ChangeNotifierProvider(
        create: (_)=> LeagueProvider(),
        builder: (context, child) {
          provider = Provider.of<LeagueProvider>(context);

          return Scaffold(
            appBar: NadalAppbar(
              title: '대회',
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // 검색창
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: TextField(
                      controller: _controller,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: '대회명, 지역, 장소, 종목으로 검색',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade500,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20.r,
                          color: Colors.grey.shade500,
                        ),
                        suffixIcon: provider.searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 20.r,
                            color: Colors.grey.shade500,
                          ),
                          onPressed: () {
                            _controller.clear();
                            provider.clearSearch();
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.w,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),

                  // 검색 로딩 상태 표시 (서버 검색 모드일 때만)
                  if (provider.loading && provider.leagues == null)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            NadalCircular(),
                            SizedBox(height: 16.h),
                            Text(
                              '대회 정보를 불러오는 중...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (provider.leagues == null)
                    Expanded(
                      child: Center(
                        child: NadalCircular(),
                      ),
                    )
                  else if (provider.filteredLeagues.isEmpty)
                      Expanded(
                        child: NadalEmptyList(
                          title: provider.isSearchMode
                              ? '"${provider.searchQuery}"에 대한 검색 결과가 없어요'
                              : '대회 정보가 없어요',
                          subtitle: provider.isSearchMode
                              ? '다른 검색어로 시도해보세요'
                              : '대회 정보는 매달 월요일 업데이트 돼요',
                        ),
                      )
                    else
                    // 대회 목록
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          itemCount: _calculateItemCount(provider.filteredLeagues.length) + (provider.loading ? 1 : 0),
                          itemBuilder: (context, index) {
                            // 로딩 인디케이터 (마지막에 표시)
                            if (index == _calculateItemCount(provider.filteredLeagues.length) && provider.loading) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Center(
                                  child: SizedBox(
                                    width: 24.r,
                                    height: 24.r,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              );
                            }

                            // 광고 위치에 도달했을 때 (예: 3개 아이템마다)
                            if (index > 0 && index % 4 == 0) {
                              return FutureBuilder<Advertisement>(
                                // API 호출로 광고 가져오기
                                future: adProvider.fetchServerAd(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Container(); // 로딩 중 플레이스홀더 표시
                                  } else if (snapshot.hasData) {
                                    return _buildAdCard(snapshot.data!);
                                  } else {
                                    return const SizedBox.shrink(); // 광고가 없으면 공간 차지하지 않음
                                  }
                                },
                              );
                            }

                            // 실제 아이템 인덱스 계산 (광고 제외)
                            final tournamentIndex = index - (index ~/ 4);

                            if (tournamentIndex < provider.filteredLeagues.length) {
                              return _buildTournamentCard(provider.filteredLeagues[tournamentIndex]);
                            }

                            return null;
                          },
                        ),
                      ),
                ],
              ),
            ),
          );
        }
    );
  }

  // 총 아이템 수 계산 (광고 포함)
  int _calculateItemCount(int leagueLength) {
    final adCount = (leagueLength / 3).floor();
    return leagueLength + adCount;
  }

// 광고 카드 위젯 - 최신 트렌드에 맞게 업데이트
  Widget _buildAdCard(Advertisement adBanner) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            spreadRadius: 0,
            blurRadius: 6.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias, // 이미지가 컨테이너를 벗어나지 않도록
      child: InkWell(
        onTap: () => _onAdClick(adBanner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 광고 이미지 - 풀 와이드에 배너 형태로 제공
            Stack(
              children: [
                SizedBox(
                  height: 120.h,
                  width: double.infinity,
                  child: _buildImage(adBanner.imageUrl, '광고: ${adBanner.advertiser}'),
                ),

                // 광고 라벨 - 더 모던한 디자인
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.ads_click,
                            size: 10.r,
                            color: Colors.white,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            '광고',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 광고주 정보 - 더 간결하게
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      adBanner.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    child: Text(
                      '자세히 보기',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// 대회 카드 위젯 - 더 컴팩트하고 깔끔한 디자인
  Widget _buildTournamentCard(LeagueModel league) {
    final dateFormat = DateFormat('yyyy.MM.dd', 'ko_KR');

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            spreadRadius: 0,
            blurRadius: 6.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 정보 행 - 스포츠 종목과 인증 배지
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
            child: Row(
              children: [
                // 스포츠 종목 태그
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    league.sports,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                // 프리미엄 배지 (있을 경우)
                if (league.title.contains("챔피언"))
                  Padding(
                    padding: EdgeInsets.only(left: 6.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 12.r,
                            color: Colors.amber.shade700,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // 테니스 대회 유형 배지
                _buildTournamentTypeBadge(league),
              ],
            ),
          ),

          // 타이틀 및 날짜 행
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  league.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 4.h),

                // 날짜 및 장소 - 한 줄에 깔끔하게
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14.r,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      dateFormat.format(league.date),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.location_on_outlined,
                      size: 14.r,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        league.location,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 이미지 영역
          SizedBox(
            height: 120.h,
            width: double.infinity,
            child: _buildImage(league.imageUrl, league.title),
          ),

          // 하단 버튼 영역
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 자세히보기 버튼
                ElevatedButton(
                  onPressed: () => _launchUrl(league.link),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    minimumSize: Size(100.w, 36.h),
                  ),
                  child: Text(
                    '자세히보기',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 이미지 로딩 위젯 - 개선된 버전
  Widget _buildImage(String? url, String alt) {
    if (url == null || url.isEmpty) {
      return _buildImagePlaceholder(alt);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildImagePlaceholder(alt, isLoading: true),
      errorWidget: (context, url, error) => _buildImagePlaceholder(alt),
    );
  }

  Widget _buildImagePlaceholder(String alt, {bool isLoading = false}) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: isLoading
            ? SizedBox(
          width: 24.r,
          height: 24.r,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            color: Colors.grey.shade400,
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getIconForText(alt),
              size: 32.r,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                alt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 텍스트에서 적절한 아이콘 선택
  IconData getIconForText(String text) {
    final lowercaseText = text.toLowerCase();

    if (lowercaseText.contains('테니스')) {
      return Icons.sports_tennis;
    } else if (lowercaseText.contains('배드민턴')) {
      return Icons.sports_cricket;
    } else if (lowercaseText.contains('탁구')) {
      return Icons.table_bar;
    } else if (lowercaseText.contains('스쿼시') || lowercaseText.contains('라켓')) {
      return Icons.sports_handball;
    } else if (lowercaseText.contains('광고')) {
      return Icons.campaign;
    }

    return Icons.sports;
  }

  // 테니스 대회 유형 배지 생성
  Widget _buildTournamentTypeBadge(LeagueModel league) {
    final title = league.title.toLowerCase();

    // Grand Slam 대회 (실제 대회명으로 판단)
    if (title.contains('윔블던') || title.contains('wimbledon') ||
        title.contains('us오픈') || title.contains('us open') ||
        title.contains('프랑스오픈') || title.contains('french open') || title.contains('롤랑가로스') ||
        title.contains('호주오픈') || title.contains('australian open') ||
        title.contains('그랜드슬램') || title.contains('grand slam')) {
      return _buildBadge('GRAND SLAM', Icons.emoji_events, Colors.amber.shade700);
    }

    // Masters 급 대회 (마스터스, 주요 오픈 대회)
    if (title.contains('마스터스') || title.contains('masters') ||
        title.contains('코리아오픈') || title.contains('korea open') ||
        title.contains('부산오픈') || title.contains('서울오픈') ||
        (title.contains('오픈') && (title.contains('인터내셔널') || title.contains('international')))) {
      return _buildBadge('MASTERS', Icons.star_border, Colors.blue.shade700);
    }

    // 프로 대회 (챔피언십, 주요 오픈)
    if (title.contains('챔피언십') || title.contains('championship') ||
        title.contains('프로') || title.contains('pro') ||
        (title.contains('오픈') && !title.contains('동호인') && !title.contains('아마추어'))) {
      return _buildBadge('PRO', Icons.sports_tennis, Colors.blue.shade600);
    }

    // Challenger/Futures 급 (지역 대회, 세미프로)
    if (title.contains('챌린저') || title.contains('challenger') ||
        title.contains('퓨처스') || title.contains('futures') ||
        title.contains('세미프로') || title.contains('신인') ||
        (title.contains('컵') && !title.contains('동호인'))) {
      return _buildBadge('SEMI-PRO', Icons.trending_up, Colors.purple.shade600);
    }

    // 주니어 대회
    if (title.contains('주니어') || title.contains('junior') ||
        title.contains('유소년') || title.contains('청소년') ||
        title.contains('중학') || title.contains('고등학') || title.contains('초등학')) {
      return _buildBadge('JUNIOR', Icons.child_care, Colors.orange.shade600);
    }

    // 시니어/베테랑 대회
    if (title.contains('시니어') || title.contains('senior') ||
        title.contains('베테랑') || title.contains('veteran') ||
        title.contains('40+') || title.contains('50+') || title.contains('60+')) {
      return _buildBadge('SENIOR', Icons.elderly, Colors.indigo.shade600);
    }

    // 대학 대회
    if (title.contains('대학') || title.contains('university') ||
        title.contains('college') || title.contains('대학생')) {
      return _buildBadge('COLLEGE', Icons.school, Colors.teal.shade600);
    }

    // 동호인/아마추어 대회
    if (title.contains('동호인') || title.contains('아마추어') || title.contains('amateur') ||
        title.contains('클럽') || title.contains('club') ||
        title.contains('레크리에이션') || title.contains('recreation') ||
        title.contains('생활체육') || title.contains('취미')) {
      return _buildBadge('AMATEUR', Icons.groups, Colors.brown.shade600);
    }

    // 기업/직장인 대회
    if (title.contains('기업') || title.contains('직장인') ||
        title.contains('회사') || title.contains('기관')) {
      return _buildBadge('CORPORATE', Icons.business, Colors.grey.shade600);
    }

    // 레벨별 대회
    if (title.contains('초급') || title.contains('beginner') ||
        title.contains('중급') || title.contains('intermediate') ||
        title.contains('고급') || title.contains('advanced')) {
      return _buildBadge('LEVEL', Icons.signal_cellular_alt, Colors.green.shade600);
    }

    return const SizedBox.shrink(); // 해당하는 유형이 없으면 배지 표시 안함
  }

  // 배지 위젯 생성 헬퍼
  Widget _buildBadge(String text, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14.r,
          color: color,
        ),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}