import 'package:dio/dio.dart' hide Response, FormData, MultipartFile;
import 'package:dio/dio.dart'
    as dio
    show Response, FormData, MultipartFile, Options;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/network/api_constants.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectionTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to headers
          try {
            final token = await _storage.read(key: ApiConstants.tokenKey);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            // إذا فشل قراءة الـ token (مثل MissingPluginException)، تجاهل
            // هذا يحدث عادة عند أول تشغيل قبل ربط الـ plugin بشكل صحيح
            print('Warning: Could not read token from storage: $e');
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle errors globally
          if (error.response?.statusCode == 401) {
            // Token expired - logout
            // في وضع العرض، لا نتعامل مع 401
            try {
              await _handleUnauthorized();
            } catch (e) {
              // تجاهل الأخطاء في وضع العرض
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _handleUnauthorized() async {
    try {
      await _storage.delete(key: ApiConstants.tokenKey);
      await _storage.delete(key: ApiConstants.userKey);
    } catch (e) {
      // تجاهل الأخطاء في وضع العرض أو إذا كان flutter_secure_storage غير متاح
      print('Warning: Could not clear storage: $e');
    }
    // في وضع العرض، لا نعيد التوجيه تلقائياً
    // Get.offAllNamed(AppRoutes.userSelection);
  }

  // GET Request
  Future<dio.Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // POST Request
  Future<dio.Response> post(
    String endpoint, {
    Map<String, dynamic>? data,
    dio.FormData? formData,
    dio.Options? options,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: formData ?? data,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // PUT Request
  Future<dio.Response> put(
    String endpoint, {
    Map<String, dynamic>? data,
    dio.Options? options,
  }) async {
    try {
      final response = await _dio.put(endpoint, data: data, options: options);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // PATCH Request
  Future<dio.Response> patch(
    String endpoint, {
    Map<String, dynamic>? data,
    dio.Options? options,
  }) async {
    try {
      final response = await _dio.patch(endpoint, data: data, options: options);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // DELETE Request
  Future<dio.Response> delete(
    String endpoint, {
    Map<String, dynamic>? data,
    dio.Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // Upload File
  Future<dio.Response> uploadFile(
    String endpoint,
    String filePath, {
    String fileKey = 'image',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        fileKey: await dio.MultipartFile.fromFile(filePath),
        ...?additionalData,
      });

      final response = await _dio.post(endpoint, data: formData);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // Upload File from bytes
  Future<dio.Response> uploadFileBytes(
    String endpoint,
    List<int> fileBytes, {
    String fileName = 'image.jpg',
    String fileKey = 'image',
    String contentType = 'image/jpeg',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        fileKey: dio.MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: DioMediaType.parse(contentType),
        ),
        ...?additionalData,
      });

      final response = await _dio.post(endpoint, data: formData);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message =
            error.response?.data?['detail'] ??
            error.response?.data?['message'] ??
            'حدث خطأ في الخادم';

        if (statusCode == 401) {
          return UnauthorizedException(message);
        } else if (statusCode == 404) {
          return NotFoundException(message);
        } else {
          return ServerException(message, statusCode: statusCode);
        }
      case DioExceptionType.cancel:
        return NetworkException('تم إلغاء الطلب');
      case DioExceptionType.unknown:
      default:
        return NetworkException('خطأ في الاتصال. تأكد من اتصالك بالإنترنت.');
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: ApiConstants.tokenKey);
  }

  // Save token
  Future<void> saveToken(String token) async {
    await _storage.write(key: ApiConstants.tokenKey, value: token);
  }

  // Clear token
  Future<void> clearToken() async {
    await _storage.delete(key: ApiConstants.tokenKey);
    await _storage.delete(key: ApiConstants.userKey);
  }
}
