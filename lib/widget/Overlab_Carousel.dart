import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:my_sports_calendar/widget/Nadal_Badge.dart';
import 'package:my_sports_calendar/widget/Nadal_Dot.dart';

import '../manager/project/Import_Manager.dart';

class CarouselOverlap extends StatefulWidget {
  const CarouselOverlap({super.key, required this.items, required this.onChanged, this.affiliationRoom});
  final List<Map> items;
  final int? affiliationRoom;
  final ValueChanged<int>? onChanged;

  @override
  State<CarouselOverlap> createState() => _CarouselOverlapState();
}

class _CarouselOverlapState extends State<CarouselOverlap> {
  late PageController _controller;
  double _page = 0;
  late final List<Map> items;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.8);
    items = widget.items;
    _controller.addListener(() {
      setState(() {
        _page = _controller.page!;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageView.builder(
      controller: _controller,
      itemCount: items.length,
      onPageChanged: widget.onChanged,
      itemBuilder: (context, index) {
        final item = items[index];
        final delta = index - _page;
        final isOnTop = delta.abs() < 0.5;

        // ✅ 중심에 가까울수록 커지고 앞으로 나옴
        final scale = 1 - delta.abs() * 0.3;
        final translateX = -delta * 62;

        return Center(
          child: Transform.translate(
            offset: Offset(translateX, 0),
            child: Transform.scale(
              scale: scale.clamp(0.8, 1.0),
              child: Opacity(
                opacity: delta.abs() < 0.01 ? 1.0 : (1 - delta.abs()).clamp(0.3, 1.0),
                child: Stack(
                  children: [
                    CarouselOverlapItem(
                        roomData: widget.items[index],
                        opacity: delta.abs() < 0.01 ? 1.0 : (1 - delta.abs()).clamp(0.3, 1.0),
                        isOnTop: isOnTop),
                    if(isOnTop)
                      Positioned(
                          bottom: 0, top: 0, left: 16.w, right: 16.w,
                          child: FadeIn(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.9),   // 아래는 어둡고
                                    Colors.transparent, // 위로 갈수록 투명
                                  ],
                                  stops: [0.15, 0.9],
                                ),
                                borderRadius: BorderRadius.circular(20.r)
                              ),
                              padding: EdgeInsets.all(16.r),
                              child: FadeInUp(
                                from: 8,
                                animate: isOnTop,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if(widget.affiliationRoom == items[index]['roomId'])
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: NadalBadge(
                                          label: '대표클럽',
                                      ),
                                    ),
                                    Text(item['roomName'], style: theme.textTheme.titleLarge?.copyWith(color: const Color(0xfff1f1f1), fontWeight: FontWeight.w800,
                                        shadows: [
                                        Shadow(
                                          color: Theme.of(context).highlightColor,
                                          blurRadius: 3,
                                        )]),),
                                    SizedBox(height: 8,),
                                    Row(
                                      children: [
                                        NadalDot(),
                                        Text('개설일 ${DateFormat('yyyy.MM.dd', 'ko_KR').format(DateTimeManager.parseUtcToLocal(item['createAt']))}', style: theme.textTheme.labelMedium?.copyWith(fontSize: 12.sp ,color: const Color(0xfff1f1f1), fontWeight: FontWeight.w500, shadows: [
                                          Shadow(
                                            color: Theme.of(context).highlightColor,
                                            blurRadius: 3,
                                          )])),
                                        NadalDot(),
                                        Text('${item['memberCount']}/200', style: theme.textTheme.labelMedium?.copyWith(fontSize: 12.sp,color: const Color(0xfff1f1f1), fontWeight: FontWeight.w500, shadows: [
                                          Shadow(
                                            color: Theme.of(context).highlightColor,
                                            blurRadius: 3,
                                          )])),
                                      ],
                                    ),
                                    SizedBox(height: 8,),
                                    SizedBox(
                                        height: 18.h,
                                        child: Text(item['tag'], style: theme.textTheme.labelMedium?.copyWith(fontSize: 12.sp,color: const Color(0xfff1f1f1), fontWeight: FontWeight.w500),overflow: TextOverflow.ellipsis,)),
                                  ],
                                ),
                              ),
                            ),
                          )
                      )
                  ],
                )
              ),
            ),
          ),
        );
      },
    );
  }
}

class CarouselOverlapItem extends StatefulWidget {
  const CarouselOverlapItem({super.key, this.height, required this.roomData, required this.opacity, required this.isOnTop, });
  final double? height;
  final Map roomData;
  final double opacity;
  final bool isOnTop;

  @override
  State<CarouselOverlapItem> createState() => _CarouselOverlapItemState();
}

class _CarouselOverlapItemState extends State<CarouselOverlapItem> {

  @override
  void initState() {
    super.initState();
    if(widget.roomData['roomImage'] != null){
      precacheImage(
        NetworkImage(widget.roomData['roomImage']),
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 300.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        image: widget.roomData['roomImage'] != null ? DecorationImage(
            image: NetworkImage(widget.roomData['roomImage']),
            fit: BoxFit.cover
        ) : DecorationImage(image: AssetImage('assets/image/default/room_default.png',), fit: BoxFit.cover),
        boxShadow: [
          if (widget.isOnTop)
            BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 20,
              spreadRadius: 10,
              offset: Offset(0, 10),
            )
        ],
      ),
    );
  }
}

