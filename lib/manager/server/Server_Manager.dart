import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../project/Import_Manager.dart';

class ServerManager {
  final Dio _dio;
  final String baseUrl;
  final String defaultHeaders;
  final int duration;

  // 에러 처리 상태 관리
  bool _isHandlingError = false;
  DateTime? _lastErrorTime;
  static const int _errorCooldownMs = 1000; // 1초 쿨다운

  ServerManager({
    required this.baseUrl,
    required this.defaultHeaders,
    this.duration = 15
  }) : _dio = Dio(
      BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(seconds: duration),
          receiveTimeout: Duration(seconds: duration),
          headers: {
            'Content-Type': defaultHeaders,
            'Accept': defaultHeaders,
          }
      )
  ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // 로그 인터셉터 (개발 환경에서만)
    if (kDebugMode) {
      _dio.interceptors.add(
          LogInterceptor(
            request: true,
            requestBody: true,
            error: true,
            responseBody: false, // 응답 바디는 보안상 제외
          )
      );
    }

    // 인증 및 에러 처리 인터셉터
    _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: _onRequest,
          onError: _onError,
          onResponse: _onResponse,
        )
    );
  }

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final requiresToken = options.headers['requiresToken'] == true;

    // 헤더 클린업
    options.headers.remove('requiresToken');

    if (requiresToken) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
      } catch (e) {
        print('토큰 획득 실패: $e');
        // 토큰 획득 실패 시에도 요청을 계속 진행
        // 서버에서 401 응답을 받으면 재시도
      }
    }

    handler.next(options);
  }

  Future<void> _onResponse(Response response, ResponseInterceptorHandler handler) async {
    // 성공적인 응답에 대한 추가 처리가 필요한 경우
    handler.next(response);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    final originalRequest = error.requestOptions;
    final requiresToken = originalRequest.headers.containsKey('Authorization');

    // 401 에러이고 토큰이 필요한 요청인 경우 재시도
    if (requiresToken && error.response?.statusCode == 401) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 토큰 강제 갱신
          final newToken = await user.getIdToken(true);
          if (newToken != null) {
            originalRequest.headers['Authorization'] = 'Bearer $newToken';

            // 재시도
            final retryResponse = await _dio.request(
              originalRequest.path,
              options: Options(
                method: originalRequest.method,
                headers: originalRequest.headers,
              ),
              data: originalRequest.data,
              queryParameters: originalRequest.queryParameters,
            );

            return handler.resolve(retryResponse);
          }
        }
      } catch (retryError) {
        print('토큰 갱신 재시도 실패: $retryError');
        // 재시도 실패 시 원래 에러를 그대로 전달
      }
    }

    handler.next(error);
  }

  // GET 요청
  Future<Response> get(String path, {
    Map<String, dynamic>? queryParams,
    bool requiredToken = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final options = requiredToken
          ? Options(headers: {'requiresToken': true})
          : null;

      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: options,
        cancelToken: cancelToken,
      );

      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  // POST 요청
  Future<Response> post(String path, {
    dynamic data,
    bool requiredToken = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final options = requiredToken
          ? Options(
        headers: {
          'requiresToken': true,
          if (data is FormData) 'Content-Type': 'multipart/form-data',
        },
        sendTimeout: data is FormData
            ? const Duration(seconds: 60)
            : const Duration(seconds: 15),
        receiveTimeout: data is FormData
            ? const Duration(seconds: 60)
            : const Duration(seconds: 15),
      )
          : null;

      final response = await _dio.post(
        path,
        data: data,
        options: options,
        cancelToken: cancelToken,
      );

      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  // PUT 요청
  Future<Response> put(String path, {
    dynamic data,
    bool requiredToken = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final options = requiredToken
          ? Options(
        headers: {
          'requiresToken': true,
          if (data is FormData) 'Content-Type': 'multipart/form-data',
        },
      )
          : null;

      final response = await _dio.put(
        path,
        data: data,
        options: options,
        cancelToken: cancelToken,
      );

      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  // DELETE 요청
  Future<Response> delete(String path, {
    Map<String, dynamic>? data,
    bool requiredToken = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final options = requiredToken
          ? Options(headers: {'requiresToken': true})
          : null;

      final response = await _dio.delete(
        path,
        data: data,
        options: options,
        cancelToken: cancelToken,
      );

      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 에러 처리 (개선됨)
  Response _handleError(dynamic error) {
    // 에러 처리 쿨다운 체크
    final now = DateTime.now();
    if (_lastErrorTime != null &&
        now.difference(_lastErrorTime!).inMilliseconds < _errorCooldownMs) {
      // 쿨다운 기간 내의 에러는 UI 알림 없이 처리
      return _createErrorResponse(error, showDialog: false);
    }

    _lastErrorTime = now;
    return _createErrorResponse(error, showDialog: true);
  }

  Response _createErrorResponse(dynamic error, {bool showDialog = true}) {
    bool systemOff = false;
    String message = '알 수 없는 오류가 발생하였습니다';
    int? statusCode;

    if (error is DioException) {
      statusCode = error.response?.statusCode;

      // 에러 타입별 메시지 설정
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          systemOff = true;
          message = '서버 연결에 실패했습니다.';
          break;
        case DioExceptionType.sendTimeout:
          message = '서버 요청 시간이 초과되었습니다.';
          break;
        case DioExceptionType.receiveTimeout:
          message = '서버 응답 시간이 초과되었습니다.';
          break;
        case DioExceptionType.badCertificate:
          systemOff = true;
          message = '보안 인증서에 문제가 있습니다.';
          break;
        case DioExceptionType.badResponse:
          message = '서버에서 올바르지 않은 응답을 받았습니다.';
          break;
        case DioExceptionType.cancel:
          message = '요청이 취소되었습니다.';
          break;
        case DioExceptionType.connectionError:
          systemOff = true;
          message = '네트워크 연결 오류입니다.';
          break;
        case DioExceptionType.unknown:
          message = '예상치 못한 오류가 발생했습니다.';
          break;
      }

      // HTTP 상태 코드별 처리
      switch (statusCode) {
        case 401:
          message = "사용자 인증에 실패했습니다";
          break;
        case 403:
          message = "접근 권한이 없습니다";
          break;
        case 404:
          message = "요청한 데이터를 찾을 수 없습니다";
          break;
        case 409:
          message = "수정불가한 옵션이 존재합니다";
        case 429:
          message = "요청이 너무 많습니다. 잠시 후 다시 시도해주세요";
          break;
        case 500:
          message = "서버 내부 오류가 발생했습니다";
          systemOff = true;
          break;
        case 502:
        case 503:
        case 504:
          message = "서버가 일시적으로 사용할 수 없습니다";
          systemOff = true;
          break;
      }

      // 서버에서 제공하는 에러 메시지 우선 사용
      if (error.response?.data != null && error.response!.data is Map) {
        final errorData = error.response!.data as Map;
        if (errorData["error"] != null && errorData["error"] is String) {
          message = errorData["error"];
        }
      }

      // 로딩 화면 제거 (안전하게)
      _safePopLoading();

      // 에러 다이얼로그 표시 (쿨다운 및 중복 방지)
      if (showDialog && !_isHandlingError) {
        _showErrorDialog(message, systemOff: systemOff);
      }

      return Response(
        requestOptions: error.requestOptions,
        statusCode: statusCode,
        data: {
          'error': message,
          'systemOff': systemOff,
          'originalError': error.message,
          ...?error.response?.data as Map<String, dynamic>?,
        },
      );
    } else {
      // Dio 외 다른 에러
      print('예상치 못한 에러 타입: $error');
      _safePopLoading();

      if (showDialog && !_isHandlingError) {
        _showErrorDialog("예상치 못한 오류가 발생했습니다");
      }

      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 500,
        data: {
          'error': '예상치 못한 오류가 발생했습니다',
          'systemOff': false,
        },
      );
    }
  }

  void _safePopLoading() {
    try {
      // 여러 번 호출되어도 안전하도록 체크
      if (AppRoute.context != null) {
        AppRoute.popLoading();
      }
    } catch (e) {
      print('로딩 팝업 제거 중 오류: $e');
    }
  }

  void _showErrorDialog(String message, {bool systemOff = false}) {
    if (_isHandlingError) return;

    _isHandlingError = true;

    try {
      // 포스트 프레임 콜백으로 안전하게 다이얼로그 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (AppRoute.context != null) {
            DialogManager.errorHandler(message, systemOff: systemOff);
          }
        } catch (e) {
          print('에러 다이얼로그 표시 중 오류: $e');
        } finally {
          // 쿨다운 후 플래그 리셋
          Future.delayed(Duration(milliseconds: _errorCooldownMs), () {
            _isHandlingError = false;
          });
        }
      });
    } catch (e) {
      print('에러 처리 중 오류: $e');
      _isHandlingError = false;
    }
  }

  // 인스턴스 정리
  void dispose() {
    try {
      _dio.close();
    } catch (e) {
      print('ServerManager 정리 중 오류: $e');
    }
  }
}

// 전역 서버 매니저 인스턴스
final ServerManager serverManager = ServerManager(
    baseUrl: dotenv.get('SERVER_URL'),
    defaultHeaders: 'application/json; charset=UTF-8',
    duration: 15
);