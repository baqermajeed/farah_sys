class ApiConstants {
  // Base URL - يمكن تغييره حسب البيئة
  // للـ iPhone Simulator استخدم IP الجهاز بدلاً من localhost
  // مثال: 'http://192.168.0.105:8000' (استبدل بالـ IP الخاص بك)
  static const String baseUrl = 'http://localhost:8000';
  
  // API Endpoints
  static const String authRequestOtp = '/auth/request-otp';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authStaffLogin = '/auth/staff-login';
  static const String authMe = '/auth/me';
  
  // Patient Endpoints
  static const String patientMe = '/patient/me';
  static const String patientAppointments = '/patient/appointments';
  static const String patientNotes = '/patient/notes';
  static const String patientGallery = '/patient/gallery';

  // Reception Endpoints
  static const String receptionPatients = '/reception/patients';
  static const String receptionAppointments = '/reception/appointments';
  
  // Doctor Endpoints
  static const String doctorPatients = '/doctor/patients';
  static String doctorPatientTreatment(String patientId) => '/doctor/patients/$patientId/treatment';
  static String doctorPatientNotes(String patientId) => '/doctor/patients/$patientId/notes';
  static String doctorPatientAppointments(String patientId) => '/doctor/patients/$patientId/appointments';
  static String doctorPatientGallery(String patientId) => '/doctor/patients/$patientId/gallery';
  static const String doctorAppointments = '/doctor/appointments';
  
  // Chat Endpoints
  static String chatMessages(String patientId) => '/chat/$patientId/messages';
  
  // WebSocket
  static const String wsBaseUrl = 'ws://localhost:8000';
  static String wsChat(String patientId) => '$wsBaseUrl/ws/chat/$patientId';
  
  // Timeout
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
}

