import 'package:cached_network_image/cached_network_image.dart';

import '../manager/project/Import_Manager.dart';

class NadalRoomFrame extends StatelessWidget {
  const NadalRoomFrame({super.key, this.imageUrl, this.size,  this.isPlaceHolder = false});
  final String? imageUrl;
  final double? size;
  final bool isPlaceHolder;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
        clipper: SoftEdgeClipper(),
        child:
        isPlaceHolder ?
        //플레이스 홀더
        NadalProfilePlaceHolder(size: (size ?? 50.r)) :
        imageUrl == null ?
        // 기본이미지
        NadalEmptyRoomFrame(size: (size ?? 50.r),) :
        CachedNetworkImage(
          imageUrl: imageUrl!,
          cacheKey: imageUrl,
          imageBuilder: (context, imageProvider)=> Container(
            height: (size ?? 50.r), width: (size ?? 50.r),
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                image: DecorationImage(image: imageProvider,
                  fit: BoxFit.cover
                ),
            ),
          ),
          placeholder: (context, str)=> NadalEmptyProfile(size: (size ?? 50.r), useBackground: false,),
        )
    );
  }
}

class NadalEmptyRoomFrame extends StatelessWidget {
  const NadalEmptyRoomFrame({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size, width: size,
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage("assets/image/default/room_default.png"), fit: BoxFit.cover)
      ),
      alignment: Alignment.bottomCenter,
    );
  }
}