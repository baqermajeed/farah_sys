import 'package:dio/dio.dart' as dio;
import 'package:farah_sys_final/services/api_service.dart';
import 'package:farah_sys_final/core/network/api_constants.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';
import 'package:farah_sys_final/models/patient_model.dart';
import 'package:farah_sys_final/models/appointment_model.dart';
import 'package:farah_sys_final/models/medical_record_model.dart';

class DoctorService {
  final _api = ApiService();

  // جلب قائمة المرضى للطبيب
  Future<List<PatientModel>> getMyPatients({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _api.get(
        ApiConstants.doctorPatients,
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((json) => _mapPatientOutToModel(json))
            .toList();
      } else {
        throw ApiException('فشل جلب قائمة المرضى');
      }
    } catch (e) {
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

  // جلب معرض صور المريض
  Future<List<Map<String, dynamic>>> getPatientGallery({
    required String patientId,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _api.get(
        ApiConstants.doctorPatientGallery(patientId),
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw ApiException('فشل جلب المعرض');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل جلب المعرض: ${e.toString()}');
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

