import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_sports_calendar/widget/Nadal_Badge.dart';
import 'package:my_sports_calendar/widget/Nadal_Dot.dart';
import '../manager/project/Import_Manager.dart';

class CarouselOverlap extends StatefulWidget {
  const CarouselOverlap({
    super.key,
    required this.items,
    required this.onChanged,
    this.affiliationRoom
  });

  final List<Map> items;
  final int? affiliationRoom;
  final ValueChanged<int>? onChanged;

  @override
  State<CarouselOverlap> createState() => _CarouselOverlapState();
}

class _CarouselOverlapState extends State<CarouselOverlap> {
  late PageController _pageController;
  late ValueNotifier<double> _pageNotifier;
  late List<Map> _items;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    _pageNotifier = ValueNotifier(0.0);
    _items = List.from(widget.items);

    _pageController.addListener(_handlePageChange);
  }

  void _handlePageChange() {
    if (!_pageController.hasClients) return;

    final currentPage = _pageController.page ?? 0.0;
    final newIndex = currentPage.round();

    // 페이지 값 업데이트 (애니메이션용)
    _pageNotifier.value = currentPage;

    // 인덱스가 실제로 변경된 경우에만 콜백 호출
    if (newIndex != _currentIndex && newIndex >= 0 && newIndex < _items.length) {
      _currentIndex = newIndex;
      widget.onChanged?.call(_currentIndex);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageChange);
    _pageController.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return SizedBox(height: 300.h);
    }

    return SizedBox(
      height: 300.h,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return ValueListenableBuilder<double>(
            valueListenable: _pageNotifier,
            builder: (context, pageValue, child) {
              return _CarouselItem(
                key: ValueKey('carousel_${_items[index]['roomId']}_$index'),
                itemData: _items[index],
                index: index,
                pageValue: pageValue,
                affiliationRoom: widget.affiliationRoom,
              );
            },
          );
        },
      ),
    );
  }
}

class _CarouselItem extends StatelessWidget {
  const _CarouselItem({
    super.key,
    required this.itemData,
    required this.index,
    required this.pageValue,
    this.affiliationRoom,
  });

  final Map itemData;
  final int index;
  final double pageValue;
  final int? affiliationRoom;

  @override
  Widget build(BuildContext context) {
    final delta = index - pageValue;
    final isActive = delta.abs() < 0.5;

    // 애니메이션 계산
    final scale = (1.0 - delta.abs() * 0.3).clamp(0.8, 1.0);
    final translateX = -delta * 62.w;
    final opacity = isActive ? 1.0 : (1.0 - delta.abs()).clamp(0.3, 1.0);

    return Center(
      child: Transform.translate(
        offset: Offset(translateX, 0),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              child: Stack(
                children: [
                  _buildImageContainer(context, isActive),
                  if (isActive) _buildOverlay(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContainer(BuildContext context, bool isActive) {
    return Container(
      height: 300.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: isActive ? [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: Offset(0, 10.h),
          )
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = itemData['roomImage'];

    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl.toString(),
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade300,
          child: Center(
            child: Icon(
              Icons.image,
              size: 50.w,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/image/default/room_default.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/image/default/room_default.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.transparent,
            ],
            stops: const [0.15, 0.9],
          ),
        ),
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isAffiliationRoom()) ...[
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: const NadalBadge(label: '대표클럽'),
              ),
            ],
            Text(
              _getRoomName(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xfff1f1f1),
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(
                    color: theme.highlightColor,
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            _buildInfoRow(theme),
            SizedBox(height: 8.h),
            SizedBox(
              height: 18.h,
              child: Text(
                _getTag(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12.sp,
                  color: const Color(0xfff1f1f1),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme) {
    return Row(
      children: [
        const NadalDot(),
        Text(
          '개설일 ${_getFormattedDate()}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 12.sp,
            color: const Color(0xfff1f1f1),
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: theme.highlightColor,
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const NadalDot(),
        Text(
          '${_getMemberCount()}/200',
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 12.sp,
            color: const Color(0xfff1f1f1),
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: theme.highlightColor,
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 데이터 추출 메서드들
  bool _isAffiliationRoom() {
    return affiliationRoom != null &&
        itemData['roomId'] != null &&
        affiliationRoom == itemData['roomId'];
  }

  String _getRoomName() {
    return itemData['roomName']?.toString() ?? '';
  }

  String _getTag() {
    return itemData['tag']?.toString() ?? '';
  }

  int _getMemberCount() {
    final count = itemData['memberCount'];
    if (count is int) return count;
    if (count is String) return int.tryParse(count) ?? 0;
    return 0;
  }

  String _getFormattedDate() {
    try {
      final createAt = itemData['createAt'];
      if (createAt == null) return '';

      DateTime date;
      if (createAt is DateTime) {
        date = createAt;
      } else {
        date = DateTimeManager.parseUtcToLocal(createAt);
      }

      return DateFormat('yyyy.MM.dd', 'ko_KR').format(date);
    } catch (e) {
      return '';
    }
  }
}