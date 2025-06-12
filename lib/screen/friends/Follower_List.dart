import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:my_sports_calendar/provider/friends/Friend_Provider.dart';
import '../../manager/project/Import_Manager.dart';
import '../../provider/app/Advertisement_Provider.dart';

class FollowerList extends StatefulWidget {
  const FollowerList({
    super.key,
    required this.provider,
    required this.selectable
  });

  final FriendsProvider provider;
  final bool selectable;

  @override
  State<FollowerList> createState() => _FollowerListState();
}

class _FollowerListState extends State<FollowerList> {
  static const String _pageKey = 'follower_page';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  /// 초기 데이터 및 광고 로드
  Future<void> _initializeData() async {
    try {
      // 팔로워 데이터 가져오기
      await widget.provider.fetchFollower();

      if (mounted) {
        // 광고 초기화 (데이터 개수에 따라)
        final followerList = widget.provider.followerList;
        if (followerList != null && followerList.isNotEmpty) {
          await _loadAdvertisements(followerList.length);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  /// 광고 로드 처리
  Future<void> _loadAdvertisements(int dataLength) async {
    final adProvider = context.read<AdvertisementProvider>();
    final adCount = dataLength ~/ 4;

    for (int i = 0; i < adCount; i++) {
      try {
        await adProvider.loadNativeListTileAd('${_pageKey}_nativeListTile_$i');
      } catch (e) {
        print('광고 로드 실패 (인덱스: $i): $e');
      }
    }
  }

  /// 광고 개수 계산
  int _calculateAdCount(List<Map<String, dynamic>> followerList) {
    if (followerList.isEmpty) return 0;
    return followerList.length ~/ 4;
  }

  /// 총 아이템 개수 계산 (데이터 + 광고)
  int _calculateTotalItemCount(List<Map<String, dynamic>> followerList) {
    return followerList.length + _calculateAdCount(followerList);
  }

  /// 현재 인덱스가 광고 위치인지 확인
  bool _isAdPosition(int index) {
    return (index + 1) % 5 == 0; // 매 5번째 위치에 광고
  }

  /// 광고를 제외한 실제 데이터 인덱스 계산
  int _getDataIndex(int listIndex) {
    final adsBefore = listIndex ~/ 5;
    return listIndex - adsBefore;
  }

  @override
  void dispose() {
    AdManager.disposePageAds(_pageKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followerList = widget.provider.followerList;

    // 로딩 상태
    if (followerList == null) {
      return Center(
        child: NadalCircular(),
      );
    }

    // 빈 리스트 상태
    if (followerList.isEmpty) {
      return Center(
        child: NadalEmptyList(
          title: '팔로우를 기다리는 사용자가 없어요',
          subtitle: '해당 사용자가 있다면 알림으로 알려드릴게요',
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverList.builder(
          itemCount: _calculateTotalItemCount(followerList),
          itemBuilder: (context, index) {
            // 광고 위치 체크
            if (_isAdPosition(index)) {
              return _buildNativeAd(index);
            }

            // 일반 데이터 아이템
            final dataIndex = _getDataIndex(index);
            if (dataIndex < followerList.length) {
              return _buildUserItem(followerList[dataIndex]);
            }

            return const SizedBox.shrink();
          },
        )
      ],
    );
  }

  /// 네이티브 광고 위젯 생성
  Widget _buildNativeAd(int index) {
    try {
      final adIndex = index ~/ 5;
      final adProvider = Provider.of<AdvertisementProvider>(context);
      final ad = adProvider.getNativeAd('${_pageKey}_nativeListTile_$adIndex');

      if (ad == null || !adProvider.hasValidNativeAd('${_pageKey}_nativeListTile_$adIndex')) {
        return const SizedBox.shrink();
      }

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
    } catch (e) {
      print('광고 렌더링 실패: $e');
      return const SizedBox.shrink();
    }
  }

  /// 사용자 아이템 위젯 생성
  Widget _buildUserItem(Map<String, dynamic> item) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 8.h
      ),
      leading: NadalProfileFrame(
        imageUrl: item['profileImage'],
        size: 48.r,
      ),
      title: Text(
        item['nickName'] ?? '알 수 없음',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        item['roomName'] ?? '소속 없음',
        style: TextStyle(
          fontSize: 14.sp,
          color: Theme.of(context).hintColor,
        ),
      ),
      trailing: SizedBox(
        width: 80.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '마지막 활동',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).hintColor,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              TextFormManager.timeAgo(item: item['lastLogin']),
              style: TextStyle(
                fontSize: 11.sp,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
      onTap: ()=> context.push('/user/${item['uid']}')
    );
  }
}