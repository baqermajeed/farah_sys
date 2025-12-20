import 'package:dio/dio.dart' as dio;
import 'package:farah_sys_final/services/api_service.dart';
import 'package:farah_sys_final/core/network/api_constants.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';
import 'package:farah_sys_final/models/user_model.dart';

class AuthService {
  final _api = ApiService();

  // طلب إرسال OTP
  Future<void> requestOtp(String phone) async {
    try {
      await _api.post(
        ApiConstants.authRequestOtp,
        data: {'phone': phone},
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل إرسال رمز التحقق');
    }
  }

  // التحقق من OTP وتسجيل الدخول
  Future<UserModel> verifyOtp({
    required String phone,
    required String code,
    String? name,
    String? gender,
    int? age,
    String? city,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.authVerifyOtp,
        data: {
          'phone': phone,
          'code': code,
          if (name != null) 'name': name,
          if (gender != null) 'gender': gender,
          if (age != null) 'age': age,
          if (city != null) 'city': city,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['access_token'] as String;
        
        // حفظ الـ Token
        await _api.saveToken(token);
        
        // جلب معلومات المستخدم
        final user = await getCurrentUser();
        
        return user;
      } else {
        throw ApiException('فشل التحقق من رمز OTP');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل التحقق من رمز OTP: ${e.toString()}');
    }
  }

  // تسجيل دخول الطاقم (طبيب/موظف)
  Future<UserModel> staffLogin({
    required String username,
    required String password,
  }) async {
    try {
      // استخدام FormData لإرسال البيانات بشكل صحيح
      final formData = dio.FormData.fromMap({
        'username': username,
        'password': password,
      });

      final response = await _api.post(
        ApiConstants.authStaffLogin,
        formData: formData,
        options: dio.Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['access_token'] as String;
        
        // حفظ الـ Token
        await _api.saveToken(token);
        
        // جلب معلومات المستخدم
        final user = await getCurrentUser();
        
        return user;
      } else {
        throw ApiException('فشل تسجيل الدخول');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل تسجيل الدخول: ${e.toString()}');
    }
  }

  // جلب معلومات المستخدم الحالي
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _api.get(ApiConstants.authMe);

      if (response.statusCode == 200) {
        final data = response.data;
        
        // تحويل من Backend schema إلى UserModel
        return UserModel(
          id: data['id'] ?? '',
          name: data['name'] ?? '',
          phoneNumber: data['phone'] ?? '',
          userType: _mapRoleToUserType(data['role'] ?? ''),
          gender: data['gender'],
          age: data['age'],
          city: data['city'],
        );
      } else {
        throw ApiException('فشل جلب معلومات المستخدم');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل جلب معلومات المستخدم: ${e.toString()}');
    }
  }

  // تحويل Role من Backend إلى userType
  String _mapRoleToUserType(String role) {
    switch (role.toLowerCase()) {
      case 'patient':
        return 'patient';
      case 'doctor':
        return 'doctor';
      case 'receptionist':
        return 'receptionist';
      case 'photographer':
        return 'photographer';
      case 'admin':
        return 'admin';
      default:
        return 'patient';
    }
  }

  // التحقق من تسجيل الدخول
  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null && token.isNotEmpty;
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await _api.clearToken();
  }
}

