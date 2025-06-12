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
                  SizedBox(width: 2.w),
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
                      SizedBox(width: 2.w),
                      _buildCachedImage(images[1], height, width),
                    ],
                  ),
                  SizedBox(height: 2.h),
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
                      SizedBox(width: 2.w),
                      _buildCachedImage(images[1], height, width),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      _buildCachedImage(images[2], height, width),
                      SizedBox(width: 2.w),
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
                        SizedBox(width: 2.w),
                        Flexible(child: _buildCachedImage(images[1], height, width)),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: ScreenUtil().screenWidth * 0.5  + 2,
                    height: ScreenUtil().screenWidth * 0.25,
                    child: Row(
                      children: [
                        Flexible(
                          child:  _buildCachedImage(images[2], height, width),
                        ),
                        SizedBox(width: 2.w),
                        Flexible(
                          child:  _buildCachedImage(images[3], height, width),
                        ),
                        SizedBox(width: 2.w),
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
      cacheKey: url,
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
      placeholder: (context, url) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: Theme.of(context).highlightColor,
        ),
        child: Center(
          child: SizedBox(
            width: 16.w,
            height: 16.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildErrorWidget(context, height, width, error),
    );
  }

  // 🔧 개선된 에러 위젯
  Widget _buildErrorWidget(BuildContext context, double height, double? width, dynamic error) {
    final theme = Theme.of(context);

    // 403 에러 체크
    bool isExpired = false;
    String errorMessage = '이미지 로드 실패';
    IconData errorIcon = Icons.broken_image_outlined;

    if (error != null) {
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('403') || errorString.contains('forbidden')) {
        isExpired = true;
        errorMessage = '유효기간 만료';
        errorIcon = Icons.access_time_outlined;
      } else if (errorString.contains('404') || errorString.contains('not found')) {
        errorMessage = '이미지 없음';
        errorIcon = Icons.image_not_supported_outlined;
      } else if (errorString.contains('network') || errorString.contains('timeout')) {
        errorMessage = '네트워크 오류';
        errorIcon = Icons.wifi_off_outlined;
      }
    }

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        color: isExpired
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.1)
            : theme.highlightColor,
        border: Border.all(
          color: isExpired
              ? theme.colorScheme.error.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            errorIcon,
            size: (height * 0.3).clamp(16.0, 24.0),
            color: isExpired
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          SizedBox(height: 4.h),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 10.sp,
              color: isExpired
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// 🔧 개선된 ImageBubbleOne
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
        if (!mounted) {
          _cleanupImageStream();
          return;
        }

        try {
          final double imageAspectRatio = info.image.width / info.image.height;
          final double newHeight = widget.maxWidth / imageAspectRatio;

          if (mounted && _imageHeight != newHeight) {
            setState(() {
              _imageHeight = newHeight;
            });
          }
        } catch (e) {
          if (mounted && _imageHeight == null) {
            setState(() {
              _imageHeight = widget.maxWidth;
            });
          }
        }

        _cleanupImageStream();
      }, onError: (exception, stackTrace) {
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
      if (mounted && _imageHeight == null) {
        setState(() {
          _imageHeight = widget.maxWidth;
        });
      }
    }
  }

  // 🔧 개선된 에러 위젯 (ImageBubbleOne용)
  Widget _buildErrorWidget(BuildContext context, dynamic error) {
    final theme = Theme.of(context);

    bool isExpired = false;
    String errorMessage = '이미지 로드 실패';
    IconData errorIcon = Icons.broken_image_outlined;

    if (error != null) {
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('403') || errorString.contains('forbidden')) {
        isExpired = true;
        errorMessage = '유효기간 만료';
        errorIcon = Icons.access_time_outlined;
      } else if (errorString.contains('404') || errorString.contains('not found')) {
        errorMessage = '이미지 없음';
        errorIcon = Icons.image_not_supported_outlined;
      } else if (errorString.contains('network') || errorString.contains('timeout')) {
        errorMessage = '네트워크 오류';
        errorIcon = Icons.wifi_off_outlined;
      }
    }

    return Container(
      width: widget.maxWidth,
      height: _imageHeight ?? widget.maxWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        color: isExpired
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.1)
            : theme.highlightColor,
        border: Border.all(
          color: isExpired
              ? theme.colorScheme.error.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            errorIcon,
            size: widget.maxWidth * 0.2,
            color: isExpired
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          SizedBox(height: 8.h),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 12.sp,
              color: isExpired
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null) {
      return _buildErrorWidget(context, null);
    }

    if (_imageHeight == null) {
      return Container(
        width: widget.maxWidth,
        height: widget.maxWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: Theme.of(context).highlightColor,
        ),
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: 24.w,
              height: 24.h,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildErrorWidget(context, error),
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/image?url=${widget.imageUrl}'),
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        imageBuilder: (context, imageProvider) => Container(
          width: widget.maxWidth,
          height: _imageHeight!,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => Container(
          width: widget.maxWidth,
          height: _imageHeight!,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: Theme.of(context).highlightColor,
          ),
          child: Center(
            child: SizedBox(
              width: 24.w,
              height: 24.h,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildErrorWidget(context, error),
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
                  SizedBox(width: 2.w),
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
                        SizedBox(width: 2.w),
                        _buildImageCache(images[1], height, width),
                        SizedBox(height: 2.h),
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
                      SizedBox(width: 2.w),
                      _buildImageCache(images[1], height, width),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildImageCache(images[2], height, width),
                      SizedBox(width: 2.w),
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
                        SizedBox(width: 2.w),
                        Flexible(child: _buildImageCache(images[1], height, width)),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: ScreenUtil().screenWidth * 0.5  + 2,
                    height: ScreenUtil().screenWidth * 0.25,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child:  _buildImageCache(images[2], height, width),
                        ),
                        SizedBox(width: 2.w),
                        Flexible(
                            child: _buildImageCache(images[3], height, width)
                        ),
                        SizedBox(width: 2.w),
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