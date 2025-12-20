import 'package:hive/hive.dart';

part 'patient_model.g.dart';

@HiveType(typeId: 1)
class PatientModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String gender;

  @HiveField(4)
  final int age;

  @HiveField(5)
  final String city;

  @HiveField(6)
  final String? imageUrl;

  @HiveField(7)
  final String? doctorId;

  @HiveField(8)
  final List<String>? treatmentHistory;

  PatientModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.gender,
    required this.age,
    required this.city,
    this.imageUrl,
    this.doctorId,
    this.treatmentHistory,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      gender: json['gender'] ?? '',
      age: json['age'] ?? 0,
      city: json['city'] ?? '',
      imageUrl: json['imageUrl'],
      doctorId: json['doctorId'],
      treatmentHistory: json['treatmentHistory'] != null
          ? List<String>.from(json['treatmentHistory'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'age': age,
      'city': city,
      'imageUrl': imageUrl,
      'doctorId': doctorId,
      'treatmentHistory': treatmentHistory,
    };
  }
}
