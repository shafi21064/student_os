import 'package:dio/dio.dart';
import 'package:studentos/core/config/env_config.dart';

// ---------------------------------------------------------------------------
// Usage examples
// ---------------------------------------------------------------------------
//
// 1. Initialization (call once in main.dart):
//
//    import 'package:studentos/core/api/api_client.dart';
//    void main() {
//      ApiClient.instance.init();
//      runApp(StudentOsApp());
//    }
//
// 2. Simple GET request:
//
//    final response = await ApiClient.instance.get<List<Course>>(
//      Api.courses,
//      fromJson: (data) => (data as List).map((e) => Course.fromJson(e)).toList(),
//    );
//    if (response.isSuccess) {
//      final courses = response.parsedData;
//    }
//
// 3. POST with body:
//
//    final response = await ApiClient.instance.post<Map<String, dynamic>>(
//      Api.loginWithEmail,
//      data: {'email': 'user@example.com', 'password': 'secret'},
//    );
//    if (response.isSuccess) {
//      final token = response.data['token'];
//    }
//
// 4. Authenticated request (set token once after login):
//
//    ApiClient.instance.setAuthToken('jwt-token-here');
//    final response = await ApiClient.instance.get(Api.userApi);
//
// 5. Upload file:
//
//    final response = await ApiClient.instance.uploadFile(
//      Api.profileUpdate,
//      filePath: '/path/to/avatar.jpg',
//      fieldName: 'avatar',
//    );
//
// 6. Generic usage without parsing:
//
//    final res = await ApiClient.instance.get<dynamic>(Api.blogs);
//    if (res.isSuccess) {
//      print(res.data); // raw JSON
//    }
// ---------------------------------------------------------------------------

/// Generic API client using Dio.
///
/// Provides common HTTP methods with consistent error handling,
/// header management, and base URL configuration.
class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio _dio;

  /// Initialize the Dio instance with default configuration.
  /// Call this once during app startup.
  void init({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    List<Interceptor>? interceptors,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? EnvConfig.baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (interceptors != null) {
      _dio.interceptors.addAll(interceptors);
    }

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  // ---------------------------------------------------------------
  // Auth token management
  // ---------------------------------------------------------------

  String? _authToken;

  String? get authToken => _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  void clearAuthToken() => setAuthToken(null);

  // ---------------------------------------------------------------
  // Generic HTTP methods
  // ---------------------------------------------------------------

  /// Perform a GET request.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) async {
    return _execute<T>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform a POST request.
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) async {
    return _execute<T>(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform a PUT request.
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) async {
    return _execute<T>(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform a PATCH request.
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) async {
    return _execute<T>(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform a DELETE request.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? fromJson,
  }) async {
    return _execute<T>(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      fromJson: fromJson,
    );
  }

  // ---------------------------------------------------------------
  // Upload helper
  // ---------------------------------------------------------------

  /// Upload a file via multipart/form-data POST.
  Future<ApiResponse<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? extraFields,
    T Function(dynamic json)? fromJson,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      ...?extraFields,
      fieldName: await MultipartFile.fromFile(filePath),
    });

    return _execute<T>(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      ),
      fromJson: fromJson,
    );
  }

  // ---------------------------------------------------------------
  // Internal execution
  // ---------------------------------------------------------------

  Future<ApiResponse<T>> _execute<T>(
    Future<Response<dynamic>> Function() request, {
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await request();
      return ApiResponse.success(
        statusCode: response.statusCode,
        data: response.data,
        fromJson: fromJson,
      );
    } on DioException catch (e) {
      return ApiResponse<T>.failure(
        statusCode: e.response?.statusCode,
        message: _extractErrorMessage(e),
        error: e,
      );
    } catch (e) {
      return ApiResponse<T>.failure(message: e.toString());
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return data['message'] as String? ??
          data['error'] as String? ??
          e.message ??
          'An unexpected error occurred';
    }
    return e.message ?? 'An unexpected error occurred';
  }
}

// ---------------------------------------------------------------
// Generic response wrapper
// ---------------------------------------------------------------

/// A generic wrapper for API responses.
class ApiResponse<T> {
  const ApiResponse._({
    this.statusCode,
    this.data,
    this.message,
    this.error,
    this.isSuccess = false,
    this.parsedData,
  });

  factory ApiResponse.success({
    int? statusCode,
    dynamic data,
    String? message,
    T Function(dynamic json)? fromJson,
  }) {
    return ApiResponse<T>._(
      statusCode: statusCode,
      data: data,
      message: message,
      isSuccess: true,
      parsedData: fromJson != null ? fromJson(data) : null,
    );
  }

  factory ApiResponse.failure({
    int? statusCode,
    String? message,
    Object? error,
  }) {
    return ApiResponse<T>._(
      statusCode: statusCode,
      message: message,
      error: error,
      isSuccess: false,
    );
  }

  final int? statusCode;
  final dynamic data;
  final String? message;
  final Object? error;
  final bool isSuccess;
  final T? parsedData;

  /// Returns the response data cast to [T] if possible.
  T? get asType => data is T ? data as T : null;
}
