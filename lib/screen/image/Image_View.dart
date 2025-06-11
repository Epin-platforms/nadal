import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:my_sports_calendar/manager/permission/Permission_Manager.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../../manager/project/Import_Manager.dart';
import 'package:http/http.dart' as http;

class ImageView extends StatefulWidget {
  const ImageView({super.key, required this.imageUrl});
  final String imageUrl;
  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  bool _downLoading = false;

  void _download() async{
    if(Platform.isIOS){
      var status =  await Permission.photosAddOnly.request();

      if(!status.isGranted){
        final res = await PermissionManager.ensurePermission(Permission.photosAddOnly, context);

        if(res){
          _download();
        }
      }else{
        _downloadImage();
      }
    }else{
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      if(sdkVersion >= 13){
        var status = await Permission.photos.request();

        if (!status.isGranted) {
          final res = await PermissionManager.ensurePermission(Permission.photos, context);

          if(res){
            _download();
          }
        }else{
          _downloadImage();
        }
      }else{
        var status = await Permission.storage.request();

        if (!status.isGranted) {
          final res = await PermissionManager.ensurePermission(Permission.storage, context);

          if(res){
            _download();
          }
        }else{
          _downloadImage();
        }
      }
    }

  }

  Future<void> _downloadImage() async {
    try {
      setState(() {
        _downLoading = true;
      });
      // Firebase Storage의 경로를 설정합니다.
      final storageRef = FirebaseStorage.instance.ref().child(extractFilePath(widget.imageUrl));

      // Firebase Storage에서 다운로드 URL 가져오기
      final downloadUrl = await storageRef.getDownloadURL();

      // 이미지 다운로드
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        try {
          // 앱의 로컬 디렉토리 경로 가져오기
          final directory = await getApplicationDocumentsDirectory();

          // 파일 저장 경로 설정
          final filePath = '${directory.path}/Nadal${DateTime.now().toIso8601String()}.jpg';
          final file = File(filePath);

          // 파일에 이미지 데이터 쓰기
          await file.writeAsBytes(response.bodyBytes);

          // 갤러리에 저장 (Uint8List 직접 사용)
          final saved = await ImageGallerySaverPlus.saveImage(
            response.bodyBytes, // ✅ 직접 Uint8List 사용
            quality: 100,
            name: "nadal_${DateTime.now().millisecondsSinceEpoch}",
          );

          if (saved == true) {
            SnackBarManager.showCleanSnackBar(context, "이미지가 갤러리에 성공적으로 저장되었습니다: $filePath");
          } else {
            SnackBarManager.showCleanSnackBar(context, "갤러리에 이미지 저장에 실패했습니다");
          }
        } catch (e) {
          SnackBarManager.showCleanSnackBar(context, "갤러리에 이미지 저장에 실패했습니다");
        }
      }
    } catch (e) {
      print(e);
      SnackBarManager.showCleanSnackBar(context, "갤러리에 이미지 저장에 실패했습니다");
    }finally{
      setState(() {
        _downLoading = false;
      });
    }
  }


  String extractFilePath(String url){
    // Firebase Storage URL에서 파일 경로만 추출
    final baseUrl = dotenv.get('STORAGE_URL');
    if (url.startsWith(baseUrl)) {
      return url.replaceFirst(baseUrl, "");
    } else {
      throw Exception("올바른 Firebase Storage URL이 아닙니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          actions: [
            if(widget.imageUrl.startsWith('http'))
            NadalIconButton(
                onTap: () async{
                  _download();
                },
                icon: CupertinoIcons.square_arrow_down,
            ),
          ],
        ),
        body: Stack(
          children: [
            InteractiveViewer(
                maxScale: 5.0,
                minScale: 0.5,
                child: CachedNetworkImage(
                    width: ScreenUtil().screenWidth,
                    fit: BoxFit.fitWidth,
                    cacheKey: widget.imageUrl,
                    imageUrl: widget.imageUrl,
                    imageBuilder: (context, imageProvider){
                      return Container(
                        width: ScreenUtil().screenWidth,
                        decoration: BoxDecoration(
                          image: DecorationImage(image: imageProvider, fit: BoxFit.fitWidth),
                        ),
                      );
                    },
                    placeholder: (context, url)=> Center(
                      child: NadalCircular(),
                    ),
                    errorWidget: (context, url, error){
                      return Padding(
                        padding: EdgeInsetsGeometry.only(bottom: 60.h),
                        child: Center(
                          child: Container(
                            width: 200.w,
                            height: 200.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Theme.of(context).hintColor,
                                  size: 48.sp,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  '이미지를 불러올 수 없습니다',
                                  style: Theme.of(context).textTheme.labelMedium
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                )
            ),
            if(_downLoading)
              Positioned.fill(
                 child: Container(
                   color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                   alignment: Alignment.center,
                   child: NadalCircular()
                 )
              )
          ],
        ),
      ),
    );
  }
}
