import 'package:flutter/material.dart';

/// 외부에서 MaterialApp에 넣어야 함
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class FocusGuard extends StatefulWidget {
  const FocusGuard({super.key, required this.child});

  final Widget child;

  @override
  State<FocusGuard> createState() => _FocusGuardState();
}

class _FocusGuardState extends State<FocusGuard> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // 다른 페이지에서 pop되어 돌아올 때 포커스 제거
    Future.microtask(() {
      if (mounted) FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
