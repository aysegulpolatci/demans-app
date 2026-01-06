import 'package:cloud_firestore/cloud_firestore.dart';

class PatientInfo {
  const PatientInfo({
    required this.patientId,
    this.phone,
    this.address,
    this.birthDate,
    this.notes,
  });

  final String patientId;
  final String? phone;
  final String? address;
  final String? birthDate;
  final String? notes;

  factory PatientInfo.fromFirestore(Map<String, dynamic> data, String id) {
    return PatientInfo(
      patientId: id,
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      birthDate: data['birthDate'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'address': address,
      'birthDate': birthDate,
      'notes': notes,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}

