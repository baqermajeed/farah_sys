class ApiConstants {
  // Base URL - يمكن تغييره حسب البيئة
  // تأكد من أن الباكند يعمل على 0.0.0.0:8000 وليس localhost فقط
  // للتأكد: py -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

  // اختر الـ URL المناسب حسب نوع الجهاز:
  // - Android Emulator: http://10.0.2.2:8000
  // - iOS Simulator: http://localhost:8000
  // - Physical Device: http://[IP_الجهاز_الذي_يعمل_عليه_الباكند]:8000
  //   مثال: http://192.168.0.112:8000 (استبدل بالـ IP الخاص بك)
  //
  // كيفية الحصول على IP جهاز الكمبيوتر:
  // Windows: ipconfig (ابحث عن IPv4 Address)
  // Linux/Mac: ifconfig أو ip addr

  // للـ Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000';

  // للـ Physical Device (استبدل بالـ IP الخاص بجهازك):
  static const String baseUrl = 'http://192.168.0.104:8000';

  // للـ iOS Simulator (على نفس الجهاز):
  // static const String baseUrl = 'http://localhost:8000';

  // API Endpoints
  static const String authRequestOtp = '/auth/request-otp';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authCreatePatientAccount = '/auth/create-patient-account';
  static const String authStaffLogin = '/auth/staff-login';
  static const String authMe = '/auth/me';
  static const String authUpdateProfile = '/auth/me';
  static const String authUploadImage = '/auth/me/upload-image';

  // Patient Endpoints
  static const String patientMe = '/patient/me';
  static const String patientUpdateMe = '/patient/me';
  static const String patientDoctor = '/patient/doctor';
  static const String patientAppointments = '/patient/appointments';
  static const String patientNotes = '/patient/notes';
  static const String patientGallery = '/patient/gallery';

  // Reception Endpoints
  static const String receptionPatients = '/reception/patients';
  static const String receptionCreatePatient = '/reception/patients';
  static const String receptionAppointments = '/reception/appointments';
  static const String receptionDoctors = '/reception/doctors';
  static String receptionPatientDoctors(String patientId) =>
      '/reception/patients/$patientId/doctors';
  static const String receptionAssignPatient = '/reception/assign';

  // Doctor Endpoints
  static const String doctorPatients = '/doctor/patients';
  static const String doctorAddPatient = '/doctor/patients';
  static String doctorPatientTreatment(String patientId) =>
      '/doctor/patients/$patientId/treatment';
  static String doctorPatientNotes(String patientId) =>
      '/doctor/patients/$patientId/notes';
  static String doctorUpdateNote(String patientId, String noteId) =>
      '/doctor/patients/$patientId/notes/$noteId';
  static String doctorDeleteNote(String patientId, String noteId) =>
      '/doctor/patients/$patientId/notes/$noteId';
  static String doctorPatientAppointments(String patientId) =>
      '/doctor/patients/$patientId/appointments';
  static String doctorDeleteAppointment(
    String patientId,
    String appointmentId,
  ) => '/doctor/patients/$patientId/appointments/$appointmentId';
  static String doctorUpdateAppointmentStatus(
    String patientId,
    String appointmentId,
  ) => '/doctor/patients/$patientId/appointments/$appointmentId/status';
  static String doctorWorkingHours = '/doctor/working-hours';
  static String doctorAvailableSlots(String date) =>
      '/doctor/available-slots/$date';
  static String doctorPatientGallery(String patientId) =>
      '/doctor/patients/$patientId/gallery';
  static String doctorDeleteGalleryImage(String patientId, String imageId) =>
      '/doctor/patients/$patientId/gallery/$imageId';
  static const String doctorAppointments = '/doctor/appointments';

  // Chat Endpoints
  static const String chatList = '/chat/list';
  static String chatMessages(String patientId) => '/chat/$patientId/messages';
  static String chatSendMessage(String patientId) => '/chat/$patientId/messages';
  static String chatMarkRead(String patientId, String messageId) => '/chat/$patientId/messages/$messageId/read';

  // Socket.IO
  static String get socketUrl => baseUrl.replaceFirst('http://', '').replaceFirst('https://', '');
  static const String socketNamespace = '/socket.io';

  // Timeout
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
}
