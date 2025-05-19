import 'package:dio/dio.dart';

import '../project/Import_Manager.dart';


class ServerManager{
  final Dio _dio;
  final String baseUrl;
  final String defaultHeaders;

  ServerManager({required this.baseUrl, required this.defaultHeaders}) :
        _dio = Dio(
            BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: Duration(seconds: 15),
                receiveTimeout: Duration(seconds: 15),
                headers: {
                  'Content-Type': defaultHeaders,
                  'Accept': defaultHeaders,
                }
            )) {
    _dio.interceptors.add(LogInterceptor(
        request: true,
        requestBody: true,
        error: true
    ));

    _dio.interceptors.add(
        InterceptorsWrapper(
            onRequest: (options, handler) async{
              final requiresToken = options.headers['requiresToken'] == true;

              // 헤더 클린업
              options.headers.remove('requiresToken');

              if (requiresToken) {
                final token = await FirebaseAuth.instance.currentUser?.getIdToken();
                if (token != null) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
              }

              handler.next(options);
            },
            onError: (error, handler) async{
              final originalRequest = error.requestOptions;
              final requiresToken = originalRequest.headers['requiresToken'] == true;

              if (requiresToken && error.response?.statusCode == 401) {
                try {
                  final newToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
                  if (newToken != null) {
                    originalRequest.headers['Authorization'] = 'Bearer $newToken';

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
                } catch (e) {
                  _handleError(e);
                }
              }

              handler.next(error);
            }
        )
    );
  }

  // ✅ GET 요청
  Future<Response> get(String path, {Map<String, dynamic>? queryParams, bool requiredToken = true} ) async {
    try {
      final Options? options = requiredToken ?  Options(headers: {'requiresToken': true}): null;
      final response = await _dio.get(path, queryParameters: queryParams, options: options);
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ✅ POST 요청
  Future<Response> post(String path, {dynamic data, bool requiredToken = true}) async {
    try {
      final Options? options = requiredToken
          ?  Options(
        headers: {
          'requiresToken': true,
          if (data is FormData) 'Content-Type': 'multipart/form-data',
        },
      ) : null;

      final response = await _dio.post(path, data: data, options: options);
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ✅ PUT 요청
  Future<Response> put(String path, {dynamic data, bool requiredToken = true}) async {
    try {
      final Options? options = requiredToken
          ? Options(
        headers: {
          'requiresToken': true,
          if (data is FormData) 'Content-Type': 'multipart/form-data',
        },
      ) : null;

      final response = await _dio.put(path, data: data, options: options);

      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ✅ DELETE 요청
  Future<Response> delete(String path, {Map<String, dynamic>? data, bool requiredToken = true}) async {
    try {
      final Options? options = requiredToken ?  Options(headers: {'requiresToken': true}): null;
      final response = await _dio.delete(path, data: data, options: options);
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }


  // 🚩 에러 처리
  Response _handleError(dynamic error) {
    bool systemOff = false;
    String message =  '알수 없는 오류가 발생하였습니다';
    if (error is DioException) {
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
          message = '잘못된 보안 인증서 입니다.';
          break;
        case DioExceptionType.badResponse:
          message = '옳바르지 않은 응답입니다.';
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

      if(error.response?.statusCode == 401){
        message = "사용자 인증에 실패했습니다";
      }else if(error.response?.statusCode == 403){
        message = "사용자 인증에 실패했습니다";
      }

      if(error.response?.data["error"] != null){
        message = error.response?.data["error"];
      }

      //로딩페이지라면 무조건 팝 시킴
      AppRoute.popLoading();
      DialogManager.errorHandler(message, systemOff: systemOff);


      return Response(
        requestOptions: error.requestOptions,
        statusCode: error.response?.statusCode,
        data: {
          'error': error.message,
          'systemOff' : systemOff,
          ...?error.response?.data as Map<String, dynamic>?,
        },
      );
    } else {
      print('here');
      AppRoute.popLoading();
      DialogManager.errorHandler("");

      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 507,
        data: {'error': '알 수 없는 에러 발생'},
      );
    }
  }
}


final ServerManager serverManager = ServerManager(
  baseUrl: dotenv.get('SERVER_URL'),
  defaultHeaders: 'application/json; charset=UTF-8',
);

