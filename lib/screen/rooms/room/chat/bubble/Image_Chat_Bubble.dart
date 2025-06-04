import '../../../../../manager/project/Import_Manager.dart';

class ImageChatBubble extends StatelessWidget {
  const ImageChatBubble({super.key, required this.chat, required this.isMe});
  final Chat chat;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final images = chat.images!;
    return Padding(
      padding: isMe? EdgeInsets.only(right: 8.w, left: 4.w) : EdgeInsets.only(left: 8.w, right: 4.w),
      child: Builder(
          builder: (context) {
            if(images.length == 1){
              return GestureDetector(
                  onTap: (){
                    context.push('/image?url=${images.first}');
                  },
                  child: ImageBubbleOne(imageUrl: images.first, maxWidth: ScreenUtil().screenWidth * 0.51,));
            }else if(images.length == 2){
              final height = ScreenUtil().screenWidth * 0.25;
              final width = ScreenUtil().screenWidth * 0.25;
              return Row(
                children: [
                  _buildCachedImage(images[0], height, width),
                  const SizedBox(width: 2,),
                  _buildCachedImage(images[1], height, width),
                ],
              );
            }else if(chat.images!.length == 3){
              final height = ScreenUtil().screenWidth * 0.25;
              final width = ScreenUtil().screenWidth * 0.25;
              return Column(
                children: [
                  Row(
                    children: [
                      _buildCachedImage(images[0], height, width),
                      const SizedBox(width: 2,),
                      _buildCachedImage(images[1], height, width),
                    ],
                  ),
                  const SizedBox(height: 2,),
                  _buildCachedImage(images[2], height, ScreenUtil().screenWidth * 0.5  + 2),
                ],
              );
            }else if(chat.images!.length == 4){
              final height = ScreenUtil().screenWidth * 0.25;
              final width = ScreenUtil().screenWidth * 0.25;
              return Column(
                children: [
                  Row(
                    children: [
                      _buildCachedImage(images[0], height, width),
                      const SizedBox(width: 2,),
                      _buildCachedImage(images[1], height, width),
                    ],
                  ),
                  const SizedBox(height: 2,),
                  Row(
                    children: [
                      _buildCachedImage(images[2], height, width),
                      const SizedBox(width: 2,),
                      _buildCachedImage(images[3], height, width),
                    ],
                  )
                ],
              );
            }else if(chat.images!.length == 5){
              final height = ScreenUtil().screenWidth * 0.25;
              final width = ScreenUtil().screenWidth * 0.25;
              return Column(
                children: [
                  SizedBox(
                    height: ScreenUtil().screenWidth * 0.25,
                    width: ScreenUtil().screenWidth * 0.5  + 2,
                    child: Row(
                      children: [
                        Flexible(child: _buildCachedImage(images[0], height, width)),
                        const SizedBox(width: 2,),
                        Flexible(child: _buildCachedImage(images[1], height, width)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2,),
                  SizedBox(
                    width: ScreenUtil().screenWidth * 0.5  + 2,
                    height: ScreenUtil().screenWidth * 0.25,
                    child: Row(
                      children: [
                        Flexible(
                          child:  _buildCachedImage(images[2], height, width),
                        ),
                        const SizedBox(width: 2,),
                        Flexible(
                          child:  _buildCachedImage(images[3], height, width),
                        ),
                        const SizedBox(width: 2,),
                        Flexible(
                          child:  _buildCachedImage(images[4], height, width),
                        ),
                      ],
                    ),
                  )
                ],
              );
            }
            return Container();
          }),
    );
  }

  Widget _buildCachedImage(String url, double height, double? width){
    return  CachedNetworkImage(
      cacheKey:  url,
      imageUrl: url,
      imageBuilder: (context, imageProvider) => GestureDetector(
        onTap: (){
          context.push('/image?url=$url');
        },
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover)
          ),
        ),
      ),
      placeholder: (context, url) => Container(),
    );
  }
}

// 개선된 ImageBubbleOne - setState 제거 및 안전성 강화
class ImageBubbleOne extends StatefulWidget {
  final String? imageUrl;
  final double maxWidth;

  const ImageBubbleOne({required this.imageUrl, required this.maxWidth, super.key});

  @override
  State<ImageBubbleOne> createState() => _ImageBubbleOneState();
}

class _ImageBubbleOneState extends State<ImageBubbleOne> {
  double? _imageHeight;
  ImageStreamListener? _listener;
  ImageStream? _stream;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null) {
      _fetchImageSize();
    }
  }

  @override
  void dispose() {
    // 안전하게 listener 제거
    _cleanupImageStream();
    super.dispose();
  }

  void _cleanupImageStream() {
    if (_stream != null && _listener != null) {
      try {
        _stream!.removeListener(_listener!);
      } catch (e) {
        // 이미 제거된 경우 무시
      }
    }
    _stream = null;
    _listener = null;
  }

  void _fetchImageSize() {
    if (widget.imageUrl == null || !mounted) return;

    try {
      final ImageProvider imageProvider = CachedNetworkImageProvider(widget.imageUrl!);
      _stream = imageProvider.resolve(const ImageConfiguration());

      _listener = ImageStreamListener((ImageInfo info, bool _) {
        // mounted 체크로 안전성 확보
        if (!mounted) {
          _cleanupImageStream();
          return;
        }

        try {
          final double imageAspectRatio = info.image.width / info.image.height;
          final double newHeight = widget.maxWidth / imageAspectRatio;

          // setState 대신 더 안전한 방식 사용
          if (mounted && _imageHeight != newHeight) {
            setState(() {
              _imageHeight = newHeight;
            });
          }
        } catch (e) {
          // 에러 발생 시 기본 정사각형으로 설정
          if (mounted && _imageHeight == null) {
            setState(() {
              _imageHeight = widget.maxWidth;
            });
          }
        }

        // 완료 후 listener 정리
        _cleanupImageStream();
      }, onError: (exception, stackTrace) {
        // 에러 발생 시 기본값 설정 및 정리
        if (mounted && _imageHeight == null) {
          setState(() {
            _imageHeight = widget.maxWidth;
          });
        }
        _cleanupImageStream();
      });

      if (mounted) {
        _stream!.addListener(_listener!);
      }
    } catch (e) {
      // 초기화 실패 시 기본값 설정
      if (mounted && _imageHeight == null) {
        setState(() {
          _imageHeight = widget.maxWidth;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 이미지 URL이 없는 경우
    if (widget.imageUrl == null) {
      return Container(
        width: widget.maxWidth,
        height: widget.maxWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: Theme.of(context).highlightColor,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: widget.maxWidth * 0.6,
          color: Theme.of(context).hintColor,
        ),
      );
    }

    // 이미지 높이가 아직 계산되지 않은 경우 (로딩 상태)
    if (_imageHeight == null) {
      return Container(
        width: widget.maxWidth,
        height: widget.maxWidth, // 초기 정사각형 placeholder
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: Theme.of(context).highlightColor,
        ),
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Theme.of(context).highlightColor,
          ),
          errorWidget: (context, url, error) => Icon(
            Icons.image_not_supported_outlined,
            size: widget.maxWidth * 0.6,
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }

    // 정상적인 이미지 표시
    return Container(
      width: widget.maxWidth,
      height: _imageHeight!,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        image: DecorationImage(
          image: CachedNetworkImageProvider(widget.imageUrl!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class SendingImagesPlaceHolder extends StatelessWidget {
  const SendingImagesPlaceHolder({super.key, required this.images});
  final List<File> images;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w, left: 4.w),
      child: Builder(
          builder: (context) {
            final height = ScreenUtil().screenWidth * 0.4;
            final width = ScreenUtil().screenWidth * 0.4;
            if(images.length == 1){
              return  _buildImageCache(images.first, height, width);
            }else if(images.length == 2){
              final height = ScreenUtil().screenWidth * 0.25;
              final width = ScreenUtil().screenWidth * 0.25;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildImageCache(images.first, height, width),
                  const SizedBox(width: 2,),
                  _buildImageCache(images.last, height, width),
                ],
              );
            }else if(images.length == 3){
              final height = ScreenUtil().screenWidth * 0.25;
              final width = ScreenUtil().screenWidth * 0.25;
              return Column(
                children: [
                  Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildImageCache(images[0], height, width),
                        const SizedBox(width: 2,),
                        _buildImageCache(images[1], height, width),
                        const SizedBox(height: 2,),
                        _buildImageCache(images[2], height, width),
                      ])
                ],
              );
            }else if(images.length == 4){
              final height = ScreenUtil().screenWidth * 0.25;
              final width = ScreenUtil().screenWidth * 0.25;
              return Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildImageCache(images[0], height, width),
                      const SizedBox(width: 2,),
                      _buildImageCache(images[1], height, width),
                    ],
                  ),
                  const SizedBox(height: 2,),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildImageCache(images[2], height, width),
                      const SizedBox(width: 2,),
                      _buildImageCache(images[3], height, width),
                    ],
                  )
                ],
              );
            }else if(images.length == 5){
              final height = ScreenUtil().screenWidth * 0.25;
              final width = null;
              return Column(
                children: [
                  SizedBox(
                    width: ScreenUtil().screenWidth * 0.5  + 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: _buildImageCache(images[0], height, width)),
                        const SizedBox(width: 2,),
                        Flexible(child: _buildImageCache(images[1], height, width)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2,),
                  SizedBox(
                    width: ScreenUtil().screenWidth * 0.5  + 2,
                    height: ScreenUtil().screenWidth * 0.25,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child:  _buildImageCache(images[2], height, width),
                        ),
                        const SizedBox(width: 2,),
                        Flexible(
                            child: _buildImageCache(images[3], height, width)
                        ),
                        const SizedBox(width: 2,),
                        Flexible(
                            child: _buildImageCache(images[4], height, width)
                        ),
                      ],
                    ),
                  )
                ],
              );
            }
            return Container();
          }),
    );
  }

  Widget _buildImageCache(File image, double height, double? width){
    return Stack(
      children: [
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r),
              image: DecorationImage(
                  image: FileImage(image),
                  fit: BoxFit.cover
              )
          ),
        ),
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: Colors.black.withValues(alpha: 0.5),
          ),
          alignment: Alignment.center,
          child: NadalCircular(size: 24.r,),
        ),
      ],
    );
  }
}