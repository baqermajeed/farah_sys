import 'package:farah_sys_final/services/api_service.dart';
import 'package:farah_sys_final/core/network/api_constants.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';
import 'package:farah_sys_final/models/patient_model.dart';
import 'package:farah_sys_final/models/appointment_model.dart';
import 'package:farah_sys_final/models/medical_record_model.dart';

class PatientService {
  final _api = ApiService();

  // جلب بيانات المريض الحالي
  Future<PatientModel> getMyProfile() async {
    try {
      final response = await _api.get(ApiConstants.patientMe);

      if (response.statusCode == 200) {
        final data = response.data;
        return _mapPatientOutToModel(data);
      } else {
        throw ApiException('فشل جلب بيانات المريض');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل جلب بيانات المريض: ${e.toString()}');
    }
  }

  // جلب جميع المرضى (للاستقبال)
  Future<List<PatientModel>> getAllPatients({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _api.get(
        ApiConstants.receptionPatients,
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) => _mapPatientOutToModel(json)).toList();
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

  // جلب مواعيد المريض
  Future<Map<String, List<AppointmentModel>>> getMyAppointments() async {
    try {
      final response = await _api.get(ApiConstants.patientAppointments);

      if (response.statusCode == 200) {
        final data = response.data;
        final primary = (data['primary'] as List? ?? [])
            .map((json) => AppointmentModel.fromJson(json))
            .toList();
        final secondary = (data['secondary'] as List? ?? [])
            .map((json) => AppointmentModel.fromJson(json))
            .toList();

        return {
          'primary': primary,
          'secondary': secondary,
        };
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

  // جلب سجلات المريض (Notes)
  Future<List<MedicalRecordModel>> getMyNotes() async {
    try {
      final response = await _api.get(ApiConstants.patientNotes);

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

  // جلب معرض الصور
  Future<List<Map<String, dynamic>>> getMyGallery() async {
    try {
      final response = await _api.get(ApiConstants.patientGallery);

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

