import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum PageTransitionType {
  fade,
  slideFromRight,
  slideFromBottom,
  scale,
  fadeScale
}

class NadalTransitionPage<T> extends CustomTransitionPage<T> {
  NadalTransitionPage({
    required super.child,
    PageTransitionType transitionType = PageTransitionType.fadeScale, // ✅ 기본값 설정
    super.key,
    super.opaque = false,
    super.fullscreenDialog = true,
    Color super.barrierColor = const Color(0x66000000),
    super.barrierDismissible,
  }) : super(
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (transitionType) {
        case PageTransitionType.fade:
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        case PageTransitionType.slideFromRight:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        case PageTransitionType.slideFromBottom:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        case PageTransitionType.scale:
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).animate(animation),
            child: child,
          );
        case PageTransitionType.fadeScale:
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
      }
    },
  );
}
