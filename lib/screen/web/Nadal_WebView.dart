import 'package:webview_flutter/webview_flutter.dart';

import '../../manager/project/Import_Manager.dart';

class NadalWebView extends StatefulWidget {
  const NadalWebView({super.key, required this.url});
  final String? url;
  @override
  State<NadalWebView> createState() => _NadalWebViewState();
}

class _NadalWebViewState extends State<NadalWebView> {
  bool _isLoading = true;
  late WebViewController _controller;

  @override
  void initState() {
    if(widget.url == null){
      context.pop();
      DialogManager.showBasicDialog(title: '주소형식이 올바르지 않습니다', content: '잠시후 다시 시도해주세요', confirmText: '확인');
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
          NavigationDelegate(
              onPageFinished: (String url){
                setState(() {
                  _isLoading = false;
                });
              }
          )
      )..loadRequest(Uri.parse(widget.url!));
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IosPopGesture(
      child: Scaffold(
          appBar: NadalAppbar(),
          body: SafeArea(
            child: Stack(
              children: [
                WebViewWidget(
                  controller: _controller,
                ),
                if(_isLoading)
                  Positioned.fill(
                    child: const Center(
                      child: NadalCircular(),
                    ),
                  )
              ],
            ),
          )
      ),
    );
  }
}
