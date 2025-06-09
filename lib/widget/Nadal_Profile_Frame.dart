import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SoftEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final radius = (size.shortestSide) * 0.43; // 적당한 둥근 정도
    final path = Path();

    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class NadalProfileFrame extends StatelessWidget {
  const NadalProfileFrame({super.key, this.imageUrl, this.size = 50,  this.isPlaceHolder = false,  this.useBackground = false});
  final String? imageUrl;
  final double size;
  final bool isPlaceHolder;
  final bool useBackground;
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: SoftEdgeClipper(),
      child:
        isPlaceHolder ?
            //플레이스 홀더
        NadalProfilePlaceHolder(size: size) :
        imageUrl == null ?
          // 기본이미지
        NadalEmptyProfile(size: size, useBackground: useBackground,) :
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.transparent,
            BlendMode.dst,
          ),
          child: CachedNetworkImage(
              imageUrl: imageUrl!,
              cacheKey: imageUrl,
              imageBuilder: (context, imageProvider)=> Container(
                height: size, width: size,
                decoration: BoxDecoration(
                  color: useBackground ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade200,
                  image: DecorationImage(image: imageProvider,
                    fit: BoxFit.cover
                  ),
                ),
              ),
              placeholder: (context, str)=> Container(
                height: size,
                width: size,
                color: Theme.of(context).highlightColor,)
          ),
        )
    );
  }
}

class NadalEmptyProfile extends StatelessWidget {
  const NadalEmptyProfile({super.key, required this.size, required this.useBackground});
  final double size;
  final bool useBackground;
  
  @override
  Widget build(BuildContext context) {
    final pallet = Theme.of(context).colorScheme;
    return Stack(
      children: [
        if(useBackground)
        Container(
          height: size, width: size,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        Container(
          height: size, width: size,
          decoration: BoxDecoration(
            color: pallet.primary.withValues(alpha: 0.3),
          ),
          alignment: Alignment.bottomCenter,
          child: Icon(CupertinoIcons.person_fill, size: size * 0.8, color: pallet.primary,),
        ),
      ],
    );
  }
}

class NadalProfilePlaceHolder extends StatelessWidget {
  const NadalProfilePlaceHolder({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size, width: size,
      decoration: BoxDecoration(
        color: Theme.of(context).highlightColor,
      ),
    );
  }
}

