import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_constants.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // Helper to decode response body
  Map<String, dynamic> _decodeBody(List<int> bodyBytes) {
    try {
      return jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': utf8.decode(bodyBytes)};
    }
  }

  // Helper to get full URL
  String _getFullUrl(String endpoint) {
    final url = '${ApiConstants.baseUrl}$endpoint';
    print(
      '🔗 [URL Builder] Base: ${ApiConstants.baseUrl}, Endpoint: $endpoint, Full: $url',
    );
    return url;
  }

  // Helper to get stored token
  Future<String?> _getToken() async {
    try {
      return await _storage.read(key: ApiConstants.tokenKey);
    } catch (e) {
      print('⚠️ Warning: Could not read token from storage: $e');
      return null;
    }
  }

  // Helper to save token
  Future<void> _saveToken(String token) async {
    try {
      await _storage.write(key: ApiConstants.tokenKey, value: token);
    } catch (e) {
      print('⚠️ Warning: Could not save token to storage: $e');
    }
  }

  // Helper to clear token
  Future<void> _clearToken() async {
    try {
      await _storage.delete(key: ApiConstants.tokenKey);
      await _storage.delete(key: ApiConstants.userKey);
    } catch (e) {
      print('⚠️ Warning: Could not clear storage: $e');
    }
  }

  // Helper to get headers with token
  Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // طلب إرسال OTP
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    try {
      print('🔐 ========== API REQUEST OTP ==========');
      final uri = Uri.parse(_getFullUrl(ApiConstants.authRequestOtp));
      print('🔐 URL: $uri');
      print('🔐 Phone: $phone');
      print('🔐 =====================================');

      final response = await http
          .post(
            uri,
            headers: await _getHeaders(),
            body: jsonEncode({'phone': phone}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('❌ REQUEST OTP TIMEOUT');
              throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
            },
          );

      print('🔐 ========== API REQUEST OTP RESPONSE ==========');
      print('🔐 Status Code: ${response.statusCode}');
      print('🔐 Response Body: ${response.body}');
      print('🔐 ==============================================');

      if (response.statusCode == 204 ||
          (response.statusCode >= 200 && response.statusCode < 300)) {
        print('✅ REQUEST OTP SUCCESS');
        return {'ok': true, 'data': {}};
      }

      final decoded = _decodeBody(response.bodyBytes);
      print('❌ REQUEST OTP FAILED: ${decoded['detail'] ?? 'Unknown error'}');
      return {
        'ok': false,
        'error': decoded['detail'] ?? 'فشل إرسال رمز التحقق',
        'data': decoded,
      };
    } catch (e) {
      print('❌ REQUEST OTP ERROR: $e');
      return {
        'ok': false,
        'error': e.toString().contains('timeout')
            ? 'انتهت مهلة الاتصال. يرجى التحقق من الاتصال بالإنترنت'
            : 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى',
        'data': {'error': e.toString()},
      };
    }
  }

  // التحقق من OTP وتسجيل الدخول
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    String? name,
    String? gender,
    int? age,
    String? city,
  }) async {
    try {
      print('🔐 ========== API VERIFY OTP ==========');
      final uri = Uri.parse(_getFullUrl(ApiConstants.authVerifyOtp));
      print('🔐 URL: $uri');
      print('🔐 Phone: $phone');
      print('🔐 Code: $code');
      print('🔐 Name: $name');
      print('🔐 Gender: $gender');
      print('🔐 Age: $age');
      print('🔐 City: $city');
      print('🔐 ===================================');

      final payload = {
        'phone': phone,
        'code': code,
        if (name != null) 'name': name,
        if (gender != null) 'gender': gender,
        if (age != null) 'age': age,
        if (city != null) 'city': city,
      };

      final response = await http
          .post(uri, headers: await _getHeaders(), body: jsonEncode(payload))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('❌ VERIFY OTP TIMEOUT');
              throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
            },
          );

      print('🔐 ========== API VERIFY OTP RESPONSE ==========');
      print('🔐 Status Code: ${response.statusCode}');
      print('🔐 Response Body: ${response.body}');
      print('🔐 =============================================');

      final decoded = _decodeBody(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ VERIFY OTP SUCCESS');
        final token = decoded['access_token'] as String?;
        if (token != null) {
          await _saveToken(token);
          print('✅ Token saved successfully');
        }
        return {'ok': true, 'data': decoded};
      }

      print('❌ VERIFY OTP FAILED: ${decoded['detail'] ?? 'Unknown error'}');
      return {
        'ok': false,
        'error': decoded['detail'] ?? 'فشل التحقق من رمز OTP',
        'data': decoded,
      };
    } catch (e) {
      print('❌ VERIFY OTP ERROR: $e');
      return {
        'ok': false,
        'error': e.toString().contains('timeout')
            ? 'انتهت مهلة الاتصال. يرجى التحقق من الاتصال بالإنترنت'
            : 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى',
        'data': {'error': e.toString()},
      };
    }
  }

  // تسجيل دخول الطاقم (طبيب/موظف/مصور/مدير)
  Future<Map<String, dynamic>> staffLogin({
    required String username,
    required String password,
  }) async {
    try {
      print('🔐 ========== API STAFF LOGIN ==========');
      final uri = Uri.parse(_getFullUrl(ApiConstants.authStaffLogin));
      print('🔐 URL: $uri');
      print('🔐 Username: $username');
      print('🔐 Password: ${'*' * password.length}');
      print('🔐 ====================================');

      // استخدام application/x-www-form-urlencoded للـ staff login
      // نفس التنسيق المستخدم في Swagger
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };

      // URL encode البيانات لتجنب مشاكل الأحرف الخاصة
      // ترتيب الـ parameters: grant_type أولاً ثم username ثم password (مثل Swagger)
      final encodedUsername = Uri.encodeComponent(username);
      final encodedPassword = Uri.encodeComponent(password);
      final body =
          'grant_type=password&username=$encodedUsername&password=$encodedPassword';

      print('🔐 Body format: grant_type=password&username=***&password=***');
      print('🔐 Full URL: $uri');
      print('🔐 Headers: $headers');
      print(
        '🔐 Body preview: grant_type=password&username=$encodedUsername&password=***',
      );

      print('🔐 Sending POST request...');
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(
            const Duration(seconds: 30), // زيادة الـ timeout إلى 30 ثانية
            onTimeout: () {
              print('❌ STAFF LOGIN TIMEOUT after 30 seconds');
              print('❌ Check if backend is running on 0.0.0.0:8000');
              throw Exception('انتهت مهلة الاتصال. تأكد من أن الباكند يعمل');
            },
          );
      print('🔐 Response received!');

      print('🔐 ========== API STAFF LOGIN RESPONSE ==========');
      print('🔐 Status Code: ${response.statusCode}');
      print('🔐 Response Body: ${response.body}');
      print('🔐 ==============================================');

      final decoded = _decodeBody(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ STAFF LOGIN SUCCESS');
        final token = decoded['access_token'] as String?;
        if (token != null) {
          await _saveToken(token);
          print('✅ Token saved successfully');
        }
        return {'ok': true, 'data': decoded};
      }

      print('❌ STAFF LOGIN FAILED: ${decoded['detail'] ?? 'Unknown error'}');
      return {
        'ok': false,
        'error': decoded['detail'] ?? 'فشل تسجيل الدخول',
        'data': decoded,
      };
    } catch (e) {
      print('❌ STAFF LOGIN ERROR: $e');
      return {
        'ok': false,
        'error': e.toString().contains('timeout')
            ? 'انتهت مهلة الاتصال. يرجى التحقق من الاتصال بالإنترنت'
            : 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى',
        'data': {'error': e.toString()},
      };
    }
  }

  // جلب معلومات المستخدم الحالي
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      print('👤 ========== API GET CURRENT USER ==========');
      final uri = Uri.parse(_getFullUrl(ApiConstants.authMe));
      print('👤 URL: $uri');
      print('👤 ==========================================');

      final response = await http
          .get(uri, headers: await _getHeaders(includeAuth: true))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('❌ GET CURRENT USER TIMEOUT');
              throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
            },
          );

      print('👤 ========== API GET CURRENT USER RESPONSE ==========');
      print('👤 Status Code: ${response.statusCode}');
      print('👤 Response Body: ${response.body}');
      print('👤 ===================================================');

      final decoded = _decodeBody(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ GET CURRENT USER SUCCESS');
        return {'ok': true, 'data': decoded};
      }

      print(
        '❌ GET CURRENT USER FAILED: ${decoded['detail'] ?? 'Unknown error'}',
      );
      return {
        'ok': false,
        'error': decoded['detail'] ?? 'فشل جلب معلومات المستخدم',
        'data': decoded,
      };
    } catch (e) {
      print('❌ GET CURRENT USER ERROR: $e');
      return {
        'ok': false,
        'error': e.toString().contains('timeout')
            ? 'انتهت مهلة الاتصال. يرجى التحقق من الاتصال بالإنترنت'
            : 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى',
        'data': {'error': e.toString()},
      };
    }
  }

  // التحقق من تسجيل الدخول
  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await _clearToken();
    print('✅ Logged out successfully');
  }
}
