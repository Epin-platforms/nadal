import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../project/Import_Manager.dart';

class PermissionManager {
  static const String _hasRequestedPermissions = 'epin_nadal_has_requested_permissions';
  static const String _permissionResultPrefix = 'epin_nadal_permission_result_';
  static const String _canRetryPrefix = 'epin_nadal_can_retry_';
  static const String _permissionRequestedDate = 'epin_nadal_permission_requested_date';
  static const String _permissionSkippedPrefix = 'epin_nadal_permission_skipped_';
  static const String _permissionProcessCompleted = 'epin_nadal_permission_process_completed';

  // 권한 정보 클래스
  static final List<PermissionInfo> _basePermissions = [
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

  // 🔧 홈 화면에서 호출할 권한 요청 함수 (최초 1회만)
  static Future<void> checkAndShowPermissions(BuildContext context) async {
    print('퍼미션 실행');

    final prefs = await SharedPreferences.getInstance();

    // 권한 프로세스가 완료되었는지 확인
    final isProcessCompleted = prefs.getBool(_permissionProcessCompleted) ?? false;

    if (isProcessCompleted) {
      print('권한 프로세스가 이미 완료됨 - 시트 표시하지 않음');
      return;
    }

    // 플랫폼별 권한 리스트 결정
    final allPermissions = await _getPermissionsForDevice();

    // Skip되지 않고 아직 허용되지 않은 권한들만 필터링
    final filteredPermissions = await _filterNonSkippedAndNonGrantedPermissions(allPermissions);

    // 요청할 권한이 없으면 프로세스 완료 처리
    if (filteredPermissions.isEmpty) {
      print('요청할 권한이 없음 - 프로세스 완료 처리');
      await prefs.setBool(_permissionProcessCompleted, true);
      return;
    }

    // 🔧 가이드라인 준수: 권한 요청 전 설명 시트 표시
    _showPermissionExplanationSheet(context, filteredPermissions);
  }

  // 🔧 권한 설명 시트 (App Store 가이드라인 준수)
  static void _showPermissionExplanationSheet(BuildContext context, List<PermissionInfo> permissions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // 🔧 자유롭게 닫기 가능
      enableDrag: true,    // 🔧 드래그 가능
      builder: (context) => PermissionExplanationSheet(permissions: permissions),
    );
  }

  // Skip되지 않고 허용되지 않은 권한들만 필터링하는 함수
  static Future<List<PermissionInfo>> _filterNonSkippedAndNonGrantedPermissions(List<PermissionInfo> permissions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PermissionInfo> filteredPermissions = [];

    for (final permission in permissions) {
      final status = await permission.permission.status;

      // 이미 허용된 권한은 제외
      if (status.isGranted) continue;

      // 필수 권한은 항상 포함 (허용되지 않은 경우)
      if (permission.isEssential) {
        filteredPermissions.add(permission);
        continue;
      }

      // 선택 권한은 Skip 상태 확인
      final isSkipped = prefs.getBool('$_permissionSkippedPrefix${permission.permission.toString()}') ?? false;

      // Skip되지 않은 선택 권한만 포함
      if (!isSkipped) {
        filteredPermissions.add(permission);
      }
    }

    return filteredPermissions;
  }

  // 설정 페이지에서 호출할 권한 관리 함수
  static Future<void> showPermissionSettingsSheet(BuildContext context) async {
    final allPermissions = await _getPermissionsForDevice();
    _showPermissionSettingsSheet(context, allPermissions);
  }

  // 즉시 권한 요청 (다른 곳에서 사용할 경우)
  static Future<void> requestPermissionsImmediately(BuildContext context) async {
    final permissions = await _getPermissionsForDevice();
    _showPermissionExplanationSheet(context, permissions);
  }

  // 디바이스에 따른 권한 리스트 반환
  static Future<List<PermissionInfo>> _getPermissionsForDevice() async {
    List<PermissionInfo> devicePermissions = List.from(_basePermissions);

    if (Platform.isAndroid) {
      await _addAndroidPermissions(devicePermissions);
    } else if (Platform.isIOS) {
      await _addIOSPermissions(devicePermissions);
    }

    return devicePermissions;
  }

  // Android 전용 권한 추가
  static Future<void> _addAndroidPermissions(List<PermissionInfo> permissions) async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final info = await deviceInfoPlugin.androidInfo;

    if (info.version.sdkInt < 33) {
      permissions.add(PermissionInfo(
        permission: Permission.storage,
        title: "저장소",
        description: "파일 저장 및 불러오기를 위해 필요합니다",
        icon: Icons.folder,
        isEssential: false,
      ));
    } else {
      permissions.add(PermissionInfo(
        permission: Permission.photos,
        title: "사진",
        description: "갤러리 접근 및 사진 저장을 위해 필요합니다",
        icon: Icons.photo_library,
        isEssential: false,
      ));
    }
  }

  // iOS 전용 권한 추가
  static Future<void> _addIOSPermissions(List<PermissionInfo> permissions) async {
    permissions.add(PermissionInfo(
      permission: Permission.photos,
      title: "사진",
      description: "갤러리 접근 및 사진 저장을 위해 필요합니다",
      icon: Icons.photo_library,
      isEssential: false,
    ));
  }

  // 설정용 권한 관리 시트 표시
  static void _showPermissionSettingsSheet(BuildContext context, List<PermissionInfo> permissions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => PermissionSettingsSheet(permissions: permissions),
    );
  }

  // 개별 권한 Skip 상태 저장
  static Future<void> _savePermissionSkipped(Permission permission, bool skipped) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_permissionSkippedPrefix${permission.toString()}', skipped);
    print('권한 Skip 상태 저장: ${permission.toString()} = $skipped');
  }

  // 권한 프로세스 완료 처리
  static Future<void> _markPermissionProcessCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionProcessCompleted, true);
    print('권한 프로세스 완료로 표시');
  }

  // 🔧 개별 권한 확인 및 재요청 (설정 페이지 링크 포함)
  static Future<bool> ensurePermission(Permission permission, BuildContext context) async {
    final status = await permission.status;

    if (status.isGranted) return true;

    final prefs = await SharedPreferences.getInstance();
    final canRetry = prefs.getBool('$_canRetryPrefix${permission.toString()}') ?? true;

    if (canRetry && status.isDenied) {
      final shouldRequest = await _showPermissionRationalDialog(context, permission);
      if (shouldRequest) {
        final result = await permission.request();
        if (result.isGranted) {
          await _savePermissionResult(permission, true);
          return true;
        } else if (result.isPermanentlyDenied) {
          await prefs.setBool('$_canRetryPrefix${permission.toString()}', false);
          // 🔧 영구 거부 시 설정 페이지로 안내
          _showSettingsDialog(context, permission);
        }
      }
    } else if (status.isPermanentlyDenied) {
      // 🔧 영구 거부된 권한은 설정으로 안내
      _showSettingsDialog(context, permission);
    }

    return false;
  }

  // 🔧 권한 설명 다이얼로그 (가이드라인 준수)
  static Future<bool> _showPermissionRationalDialog(BuildContext context, Permission permission) async {
    final permissionInfo = await _findPermissionInfo(permission);

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(permissionInfo.icon, color: Theme.of(context).primaryColor),
            SizedBox(width: 8.w),
            Text('${permissionInfo.title} 권한'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(permissionInfo.description),
            SizedBox(height: 16.h),
            Text(
              '이 권한을 허용하시겠습니까?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('허용'),
          ),
        ],
      ),
    ) ?? false;
  }

  // 🔧 설정으로 이동 다이얼로그 (가이드라인 5.1.1 준수)
  static void _showSettingsDialog(BuildContext context, Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('권한 설정이 필요합니다'),
        content: Text(
          '${_getPermissionName(permission)} 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // 🔧 설정 페이지로 이동
            },
            child: Text('설정'),
          ),
        ],
      ),
    );
  }

  // 권한 정보 찾기
  static Future<PermissionInfo> _findPermissionInfo(Permission permission) async {
    final allPermissions = await _getPermissionsForDevice();
    return allPermissions.firstWhere(
          (p) => p.permission == permission,
      orElse: () => PermissionInfo(
        permission: permission,
        title: _getPermissionName(permission),
        description: '이 기능을 사용하기 위해 필요합니다',
        icon: Icons.security,
        isEssential: false,
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
      case Permission.locationWhenInUse: return '위치 (앱 사용 중)';
      case Permission.contacts: return '연락처';
      case Permission.storage: return '저장소';
      case Permission.photos: return '사진';
      case Permission.phone: return '전화';
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

  // Skip된 선택 권한들을 다시 요청할 수 있도록 리셋하는 함수
  static Future<void> resetSkippedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final allPermissions = await _getPermissionsForDevice();

    for (final permission in allPermissions) {
      if (!permission.isEssential) {
        await prefs.remove('$_permissionSkippedPrefix${permission.permission.toString()}');
      }
    }

    // 프로세스 완료 상태도 리셋
    await prefs.remove(_permissionProcessCompleted);
    print('Skip된 선택 권한들과 프로세스 완료 상태가 리셋되었습니다');
  }

  // 권한 프로세스 완료 여부 확인
  static Future<bool> isPermissionProcessCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionProcessCompleted) ?? false;
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

// 🔧 권한 설명 시트 위젯 (App Store 가이드라인 5.1.1 준수)
class PermissionExplanationSheet extends StatefulWidget {
  final List<PermissionInfo> permissions;

  const PermissionExplanationSheet({
    super.key,
    required this.permissions,
  });

  @override
  State<PermissionExplanationSheet> createState() => _PermissionExplanationSheetState();
}

class _PermissionExplanationSheetState extends State<PermissionExplanationSheet> {
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
                  "앱 권한 안내",
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  "다음 권한들이 더 나은 서비스 제공을 위해 필요합니다.\n모든 권한은 선택사항이며, 언제든지 설정에서 변경할 수 있습니다.",
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

          // 🔧 가이드라인 준수 버튼들
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                // 🔧 "계속" 버튼 (기존 "모든 권한 허용" 대신)
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _continueWithPermissions,
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
                      "계속", // 🔧 "모든 권한 허용" → "계속"
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                // 🔧 나중에 설정 버튼 수정
                TextButton(
                  onPressed: _isRequesting ? null : _skipForNow,
                  child: Text(
                    "나중에 하기",
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
                SizedBox(height: 8.h),
                // 🔧 설정 페이지 안내 추가
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Text(
                    "앱 설정에서 직접 관리",
                    style: TextStyle(fontSize: 12.sp),
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

  // 🔧 "계속" 버튼 - 바로 권한 요청으로 진행
  Future<void> _continueWithPermissions() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    final results = <Permission, PermissionStatus>{};

    // 모든 권한 순차 요청
    for (final permissionInfo in widget.permissions) {
      try {
        final status = await permissionInfo.permission.request();
        results[permissionInfo.permission] = status;
        await PermissionManager._savePermissionResult(permissionInfo.permission, status.isGranted);
      } catch (e) {
        print('권한 요청 실패: ${permissionInfo.permission} - $e');
        results[permissionInfo.permission] = PermissionStatus.denied;
      }
    }

    // 권한 프로세스 완료 처리
    await PermissionManager._markPermissionProcessCompleted();

    setState(() {
      _isRequesting = false;
    });

    if (mounted) {
      Navigator.pop(context);
      _showPermissionResult(results);
    }
  }

  // 🔧 나중에 하기 - 선택 권한만 Skip 처리
  Future<void> _skipForNow() async {
    if (_isRequesting) return;

    // 선택 권한들만 Skip 상태로 저장
    for (final permissionInfo in widget.permissions) {
      if (!permissionInfo.isEssential) {
        await PermissionManager._savePermissionSkipped(permissionInfo.permission, true);
      }
    }

    // 권한 프로세스 완료 처리
    await PermissionManager._markPermissionProcessCompleted();

    if (mounted) {
      Navigator.pop(context);

      final skippedCount = widget.permissions.where((p) => !p.isEssential).length;
      if (skippedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('권한은 설정에서 언제든지 변경할 수 있습니다'),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: '설정',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  void _showPermissionResult(Map<Permission, PermissionStatus> results) {
    if (!mounted) return;

    final granted = results.values.where((status) => status.isGranted).length;
    final total = results.length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$granted/$total 개의 권한이 허용되었습니다'),
        duration: Duration(seconds: 2),
        action: granted < total ? SnackBarAction(
          label: '설정',
          onPressed: () => openAppSettings(),
        ) : null,
      ),
    );
  }
}

// 🔧 설정용 권한 시트 위젯
class PermissionSettingsSheet extends StatefulWidget {
  final List<PermissionInfo> permissions;

  const PermissionSettingsSheet({
    super.key,
    required this.permissions,
  });

  @override
  State<PermissionSettingsSheet> createState() => _PermissionSettingsSheetState();
}

class _PermissionSettingsSheetState extends State<PermissionSettingsSheet> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatuses();
  }

  Future<void> _loadPermissionStatuses() async {
    final Map<Permission, PermissionStatus> statuses = {};

    for (final permission in widget.permissions) {
      try {
        final status = await permission.permission.status;
        statuses[permission.permission] = status;
      } catch (e) {
        print('권한 상태 로드 실패: ${permission.permission} - $e');
        statuses[permission.permission] = PermissionStatus.denied;
      }
    }

    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePermissionStatus(Permission permission) async {
    try {
      final status = await permission.status;
      if (mounted) {
        setState(() {
          _permissionStatuses[permission] = status;
        });
      }
    } catch (e) {
      print('권한 상태 업데이트 실패: $permission - $e');
    }
  }

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
                Row(
                  children: [
                    Icon(
                      Icons.settings,
                      size: 32.r,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      "권한 관리",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  "각 권한의 현재 상태를 확인하고 앱 설정에서 변경할 수 있습니다",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // 권한 리스트
          Expanded(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  Text('권한 상태를 확인하는 중...'),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: widget.permissions.length,
              itemBuilder: (context, index) {
                return _buildPermissionSettingsCard(widget.permissions[index]);
              },
            ),
          ),

          // 하단 버튼들
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      openAppSettings();
                    },
                    child: Text(
                      "앱 설정으로 이동",
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Skip된 권한들 리셋
                      await PermissionManager.resetSkippedPermissions();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('권한 설정이 초기화되었습니다. 앱 재시작 시 다시 요청됩니다.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Text(
                      "권한 요청 초기화",
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSettingsCard(PermissionInfo info) {
    final currentStatus = _permissionStatuses[info.permission] ?? PermissionStatus.denied;

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
                  SizedBox(height: 8.h),
                  // 실시간 상태 표시
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: currentStatus.isGranted ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _getStatusText(currentStatus),
                        style: TextStyle(
                          color: currentStatus.isGranted ? Colors.green : Colors.red,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 실시간 업데이트되는 개별 권한 요청 버튼
            if (!currentStatus.isGranted)
              TextButton(
                onPressed: () async {
                  try {
                    final result = await info.permission.request();

                    // 상태 즉시 업데이트
                    await _updatePermissionStatus(info.permission);

                    // 사용자에게 결과 알림
                    if (mounted) {
                      final message = result.isGranted
                          ? '${info.title} 권한이 허용되었습니다'
                          : result.isPermanentlyDenied
                          ? '설정에서 ${info.title} 권한을 허용해주세요'
                          : '${info.title} 권한이 거부되었습니다';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: Duration(seconds: 2),
                          action: result.isPermanentlyDenied
                              ? SnackBarAction(
                            label: '설정',
                            onPressed: () => openAppSettings(),
                          )
                              : null,
                        ),
                      );
                    }
                  } catch (e) {
                    print('권한 요청 실패: ${info.permission} - $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('권한 요청 중 오류가 발생했습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  '요청',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '허용됨';
      case PermissionStatus.denied:
        return '거부됨';
      case PermissionStatus.restricted:
        return '제한됨';
      case PermissionStatus.limited:
        return '제한적 허용';
      case PermissionStatus.permanentlyDenied:
        return '영구 거부됨';
      default:
        return '알 수 없음';
    }
  }
}