import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../project/Import_Manager.dart';

class PermissionManager {
  static const String _hasRequestedPermissions = 'epin_nadal_has_requested_permissions';
  static const String _permissionResultPrefix = 'epin_nadal_permission_result_';
  static const String _canRetryPrefix = 'epin_nadal_can_retry_';
  static const String _permissionRequestedDate = 'epin_nadal_permission_requested_date';
  // 권한 정보 클래스
  static final List<PermissionInfo> _allPermissions = [
    PermissionInfo(
      permission: Permission.camera,
      title: "카메라",
      description: "프로필 사진 촬영 및 문서 스캔을 위해 필요합니다",
      icon: Icons.camera_alt,
      isEssential: false,
    ),
    PermissionInfo(
      permission: Permission.notification,
      title: "알림",
      description: "중요한 업데이트와 일정 알림을 받기 위해 필요합니다",
      icon: Icons.notifications,
      isEssential: true,
    ),
    PermissionInfo(
      permission: Permission.contacts,
      title: "연락처",
      description: "친구 초대 및 연락처 동기화를 위해 필요합니다",
      icon: Icons.contacts,
      isEssential: false,
    ),
  ];

  // 홈 화면에서 호출할 권한 요청 함수
  static Future<void> checkAndShowPermissions(BuildContext context) async {
    print('퍼미션 실행');
    final prefs = await SharedPreferences.getInstance();
    final hasRequested = prefs.getBool(_hasRequestedPermissions) ?? false;

    if (hasRequested) return;
    // 현재 날짜 저장
    await prefs.setString(_permissionRequestedDate, DateTime.now().toLocal().toIso8601String());

    // Android 버전에 따른 권한 리스트 결정
    final permissions = await _getPermissionsForDevice();

    // 권한 요청 시트 표시
    _showPermissionSheet(context, permissions);
  }

  // 즉시 권한 요청 (다른 곳에서 사용할 경우)
  static Future<void> requestPermissionsImmediately(BuildContext context) async {
    final permissions = await _getPermissionsForDevice();
    _showPermissionSheet(context, permissions);
  }

  // 디바이스에 따른 권한 리스트 반환
  static Future<List<PermissionInfo>> _getPermissionsForDevice() async {
    List<PermissionInfo> devicePermissions = List.from(_allPermissions);

    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      final info = await deviceInfoPlugin.androidInfo;

      if (info.version.sdkInt < 33) {
        // Android 12 이하: storage 권한 사용
        devicePermissions.add(PermissionInfo(
          permission: Permission.storage,
          title: "저장소",
          description: "파일 저장 및 불러오기를 위해 필요합니다",
          icon: Icons.folder,
          isEssential: false,
        ));
      } else {
        // Android 13 이상: photos 권한 사용
        devicePermissions.add(PermissionInfo(
          permission: Permission.photos,
          title: "사진",
          description: "갤러리 접근 및 사진 저장을 위해 필요합니다",
          icon: Icons.photo_library,
          isEssential: false,
        ));
      }
    } else {
      // iOS의 경우 photos 권한 추가
      devicePermissions.add(PermissionInfo(
        permission: Permission.photos,
        title: "사진",
        description: "갤러리 접근 및 사진 저장을 위해 필요합니다",
        icon: Icons.photo_library,
        isEssential: false,
      ));
    }

    return devicePermissions;
  }

  // 권한 요청 바텀시트 표시
  static void _showPermissionSheet(BuildContext context, List<PermissionInfo> permissions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PermissionBottomSheet(permissions: permissions),
    );
  }

  // 개별 권한 확인 및 재요청
  static Future<bool> ensurePermission(Permission permission, BuildContext context) async {
    final status = await permission.status;

    // 이미 허용됨
    if (status.isGranted) return true;

    // 재요청 가능한지 확인
    final prefs = await SharedPreferences.getInstance();
    final canRetry = prefs.getBool('$_canRetryPrefix${permission.toString()}') ?? true;

    if (canRetry && status.isDenied) {
      // 재요청 다이얼로그 표시
      final shouldRequest = await _showPermissionRationalDialog(context, permission);
      if (shouldRequest) {
        final result = await permission.request();
        if (result.isGranted) {
          await _savePermissionResult(permission, true);
          return true;
        } else if (result.isPermanentlyDenied) {
          await prefs.setBool('$_canRetryPrefix${permission.toString()}', false);
        }
      }
    } else if (status.isPermanentlyDenied) {
      // 설정으로 이동 안내
      _showSettingsDialog(context, permission);
    }

    return false;
  }

  // 권한 설명 다이얼로그
  static Future<bool> _showPermissionRationalDialog(BuildContext context, Permission permission) async {
    final permissionInfo = _allPermissions.firstWhere(
          (p) => p.permission == permission,
      orElse: () => PermissionInfo(
        permission: permission,
        title: _getPermissionName(permission),
        description: '이 기능을 사용하기 위해 필요합니다',
        icon: Icons.security,
        isEssential: false,
      ),
    );

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(permissionInfo.icon, color: Theme.of(context).primaryColor),
            SizedBox(width: 8.w),
            Text('${permissionInfo.title} 권한 필요'),
          ],
        ),
        content: Text(
          permissionInfo.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('권한 허용'),
          ),
        ],
      ),
    ) ?? false;
  }

  // 설정으로 이동 다이얼로그
  static void _showSettingsDialog(BuildContext context, Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('권한 설정 필요'),
        content: Text('설정에서 ${_getPermissionName(permission)} 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  // 권한 결과 저장
  static Future<void> _savePermissionResult(Permission permission, bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_permissionResultPrefix${permission.toString()}', granted);

    if (granted) {
      await prefs.remove('$_canRetryPrefix${permission.toString()}');
    }
  }

  // 권한 이름 반환
  static String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera: return '카메라';
      case Permission.notification: return '알림';
      case Permission.location: return '위치';
      case Permission.contacts: return '연락처';
      case Permission.storage: return '저장소';
      case Permission.photos: return '사진';
      default: return '권한';
    }
  }

  // 모든 권한 상태 확인
  static Future<Map<Permission, bool>> getAllPermissionStatus() async {
    final permissions = await _getPermissionsForDevice();
    final Map<Permission, bool> statusMap = {};

    for (final permInfo in permissions) {
      final status = await permInfo.permission.status;
      statusMap[permInfo.permission] = status.isGranted;
    }

    return statusMap;
  }
}

// 권한 정보 클래스
class PermissionInfo {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;
  final bool isEssential;

  PermissionInfo({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    required this.isEssential,
  });
}

// 권한 요청 바텀시트 위젯
class PermissionBottomSheet extends StatefulWidget {
  final List<PermissionInfo> permissions;

  const PermissionBottomSheet({
    super.key,
    required this.permissions,
  });

  @override
  State<PermissionBottomSheet> createState() => _PermissionBottomSheetState();
}

class _PermissionBottomSheetState extends State<PermissionBottomSheet> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // 헤더
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                Icon(
                  Icons.security,
                  size: 60.r,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 16.h),
                Text(
                  "더 나은 서비스를 위해\n권한이 필요합니다",
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  "알림 외 모든 권한은 선택사항이며\n거부하셔도 기본 기능은 이용 가능합니다",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // 권한 리스트
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: widget.permissions.length,
              itemBuilder: (context, index) {
                return _buildPermissionCard(widget.permissions[index]);
              },
            ),
          ),

          // 버튼들
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _requestAllPermissions,
                    child: _isRequesting
                        ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      "모든 권한 허용",
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: _isRequesting ? null : _skipPermissions,
                  child: Text(
                    "나중에 설정하기",
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(PermissionInfo info) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                info.icon,
                color: Theme.of(context).primaryColor,
                size: 24.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        info.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (info.isEssential) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '필수',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    info.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isRequesting = true);

    final prefs = await SharedPreferences.getInstance();
    final results = <Permission, PermissionStatus>{};

    // 모든 권한 요청
    for (final permissionInfo in widget.permissions) {
      final status = await permissionInfo.permission.request();
      results[permissionInfo.permission] = status;
      await PermissionManager._savePermissionResult(permissionInfo.permission, status.isGranted);
    }

    // 요청 완료 플래그 설정
    await prefs.setBool(PermissionManager._hasRequestedPermissions, true);

    setState(() => _isRequesting = false);
    Navigator.pop(context);

    // 결과에 따른 추가 처리 (예: 성공 메시지 표시)
    _showPermissionResult(results);
  }

  Future<void> _skipPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PermissionManager._hasRequestedPermissions, true);

    // 모든 권한을 추후 요청 가능하도록 설정
    for (final permissionInfo in widget.permissions) {
      await prefs.setBool('${PermissionManager._canRetryPrefix}${permissionInfo.permission.toString()}', true);
    }

    Navigator.pop(context);
  }

  void _showPermissionResult(Map<Permission, PermissionStatus> results) {
    final granted = results.values.where((status) => status.isGranted).length;
    final total = results.length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$granted/$total 개의 권한이 허용되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}