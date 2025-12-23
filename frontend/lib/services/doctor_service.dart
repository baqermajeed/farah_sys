import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:farah_sys_final/services/api_service.dart';
import 'package:farah_sys_final/core/network/api_constants.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';
import 'package:farah_sys_final/models/patient_model.dart';
import 'package:farah_sys_final/models/appointment_model.dart';
import 'package:farah_sys_final/models/medical_record_model.dart';
import 'package:farah_sys_final/models/gallery_image_model.dart';

class DoctorService {
  final _api = ApiService();

  // جلب قائمة المرضى للطبيب
  Future<List<PatientModel>> getMyPatients({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      print('🏥 [DoctorService] Fetching patients for doctor...');
      print('   📋 Endpoint: ${ApiConstants.doctorPatients}');
      print('   📋 Skip: $skip, Limit: $limit');
      
      final response = await _api.get(
        ApiConstants.doctorPatients,
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      print('🏥 [DoctorService] Response status: ${response.statusCode}');
      print('🏥 [DoctorService] Response data type: ${response.data.runtimeType}');
      print('🏥 [DoctorService] Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        // Handle different response formats
        dynamic responseData = response.data;
        
        // Check if it's already a List
        if (responseData is! List) {
          print('⚠️ [DoctorService] Response is not a List, trying to parse...');
          // Maybe it's wrapped in a map?
          if (responseData is Map) {
            if (responseData.containsKey('data')) {
              responseData = responseData['data'];
            } else if (responseData.containsKey('patients')) {
              responseData = responseData['patients'];
            } else {
              print('❌ [DoctorService] Response is a Map but no data/patients key found');
              print('   Keys: ${responseData.keys}');
              throw ApiException('تنسيق استجابة غير متوقع من السيرفر');
            }
          } else {
            print('❌ [DoctorService] Response is neither List nor Map');
            throw ApiException('تنسيق استجابة غير متوقع من السيرفر');
          }
        }
        
        final data = responseData as List;
        print('🏥 [DoctorService] Found ${data.length} patients');
        
        if (data.isEmpty) {
          print('⚠️ [DoctorService] No patients found. Make sure patients are assigned to this doctor.');
          print('   💡 Patients need to have primary_doctor_id or secondary_doctor_id set.');
        } else {
          print('🏥 [DoctorService] First patient sample: ${data.isNotEmpty ? data.first : "N/A"}');
        }
        
        final patients = data
            .map((json) => _mapPatientOutToModel(json))
            .toList();
        
        print('✅ [DoctorService] Successfully mapped ${patients.length} patients');
        return patients;
      } else {
        print('❌ [DoctorService] Failed with status: ${response.statusCode}');
        print('❌ [DoctorService] Response: ${response.data}');
        throw ApiException('فشل جلب قائمة المرضى');
      }
    } catch (e) {
      print('❌ [DoctorService] Error: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل جلب قائمة المرضى: ${e.toString()}');
    }
  }

  // تحديد نوع العلاج للمريض
  Future<PatientModel> setTreatmentType({
    required String patientId,
    required String treatmentType,
  }) async {
    try {
      final response = await _api.post(
        '${ApiConstants.doctorPatientTreatment(patientId)}?treatment_type=$treatmentType',
      );

      if (response.statusCode == 200) {
        return _mapPatientOutToModel(response.data);
      } else {
        throw ApiException('فشل تحديث نوع العلاج');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل تحديث نوع العلاج: ${e.toString()}');
    }
  }

  // إضافة سجل (ملاحظة) للمريض
  Future<MedicalRecordModel> addNote({
    required String patientId,
    required String note,
    String? imagePath,
    List<int>? imageBytes,
    String? fileName,
  }) async {
    try {
      dio.Response response;
      
      if (imageBytes != null) {
        // رفع صورة مع الملاحظة
        response = await _api.uploadFileBytes(
          ApiConstants.doctorPatientNotes(patientId),
          imageBytes,
          fileName: fileName ?? 'note.jpg',
          fileKey: 'image',
          additionalData: {'note': note},
        );
      } else {
        // إضافة ملاحظة فقط
        response = await _api.post(
          ApiConstants.doctorPatientNotes(patientId),
          data: {'note': note},
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MedicalRecordModel.fromJson(response.data);
      } else {
        throw ApiException('فشل إضافة السجل');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل إضافة السجل: ${e.toString()}');
    }
  }

  // إضافة موعد جديد
  Future<AppointmentModel> addAppointment({
    required String patientId,
    required DateTime scheduledAt,
    String? note,
    List<int>? imageBytes,
    String? fileName,
  }) async {
    try {
      dio.Response response;
      
      if (imageBytes != null) {
        // رفع صورة مع الموعد
        response = await _api.uploadFileBytes(
          ApiConstants.doctorPatientAppointments(patientId),
          imageBytes,
          fileName: fileName ?? 'appointment.jpg',
          fileKey: 'image',
          additionalData: {
            'scheduled_at': scheduledAt.toIso8601String(),
            if (note != null) 'note': note,
          },
        );
      } else {
        // إضافة موعد فقط
        response = await _api.post(
          ApiConstants.doctorPatientAppointments(patientId),
          data: {
            'scheduled_at': scheduledAt.toIso8601String(),
            if (note != null) 'note': note,
          },
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AppointmentModel.fromJson(response.data);
      } else {
        throw ApiException('فشل إضافة الموعد');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل إضافة الموعد: ${e.toString()}');
    }
  }

  // إضافة صورة للمعرض
  Future<Map<String, dynamic>> addGalleryImage({
    required String patientId,
    required List<int> imageBytes,
    String? note,
    String? fileName,
  }) async {
    try {
      final response = await _api.uploadFileBytes(
        ApiConstants.doctorPatientGallery(patientId),
        imageBytes,
        fileName: fileName ?? 'gallery.jpg',
        fileKey: 'image',
        additionalData: note != null ? {'note': note} : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ApiException('فشل رفع الصورة');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل رفع الصورة: ${e.toString()}');
    }
  }

  // جلب مواعيد الطبيب
  Future<List<AppointmentModel>> getMyAppointments({
    String? day,
    String? dateFrom,
    String? dateTo,
    String? status,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      
      if (day != null) queryParams['day'] = day;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (status != null) queryParams['status'] = status;

      final response = await _api.get(
        ApiConstants.doctorAppointments,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((json) => AppointmentModel.fromJson(json))
            .toList();
      } else {
        throw ApiException('فشل جلب المواعيد');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل جلب المواعيد: ${e.toString()}');
    }
  }

  // جلب جميع مواعيد المرضى (للاستقبال)
  Future<List<AppointmentModel>> getAllAppointmentsForReception({
    String? day,
    String? dateFrom,
    String? dateTo,
    String? status,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };

      if (day != null) queryParams['day'] = day;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (status != null) queryParams['status'] = status;

      final response = await _api.get(
        ApiConstants.receptionAppointments,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) => AppointmentModel.fromJson(json)).toList();
      } else {
        throw ApiException('فشل جلب المواعيد');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل جلب المواعيد: ${e.toString()}');
    }
  }

  // جلب سجلات المريض
  Future<List<MedicalRecordModel>> getPatientNotes({
    required String patientId,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _api.get(
        ApiConstants.doctorPatientNotes(patientId),
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((json) => MedicalRecordModel.fromJson(json))
            .toList();
      } else {
        throw ApiException('فشل جلب السجلات');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل جلب السجلات: ${e.toString()}');
    }
  }

  // رفع صورة إلى معرض المريض
  Future<GalleryImageModel> uploadGalleryImage(
    String patientId,
    File imageFile,
    String? note,
  ) async {
    try {
      print('📸 [DoctorService] Uploading gallery image for patient: $patientId');
      
      final formData = dio.FormData.fromMap({
        'image': await dio.MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        if (note != null && note.isNotEmpty) 'note': note,
      });

      final response = await _api.post(
        ApiConstants.doctorPatientGallery(patientId),
        formData: formData,
      );

      if (response.statusCode == 200) {
        print('✅ [DoctorService] Image uploaded successfully');
        return GalleryImageModel.fromJson(response.data);
      } else {
        throw ApiException('فشل رفع الصورة');
      }
    } catch (e) {
      print('❌ [DoctorService] Error uploading image: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل رفع الصورة: ${e.toString()}');
    }
  }

  // جلب قائمة صور معرض المريض
  Future<List<GalleryImageModel>> getPatientGallery(
    String patientId, {
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      print('📸 [DoctorService] Fetching gallery for patient: $patientId');
      
      final response = await _api.get(
        ApiConstants.doctorPatientGallery(patientId),
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        print('✅ [DoctorService] Fetched ${data.length} gallery images');
        return data
            .map((json) => GalleryImageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException('فشل جلب صور المعرض');
      }
    } catch (e) {
      print('❌ [DoctorService] Error fetching gallery: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل جلب صور المعرض: ${e.toString()}');
    }
  }

  // تحويل PatientOut من Backend إلى PatientModel
  PatientModel _mapPatientOutToModel(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      age: json['age'] ?? 0,
      city: json['city'] ?? '',
      imageUrl: json['qr_image_path'],
      doctorId: json['primary_doctor_id']?.toString(),
      treatmentHistory: json['treatment_type'] != null
          ? [json['treatment_type']]
          : null,
    );
  }
}

