import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_info.dart';

class PatientInfoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'patientInfo';

  // Hasta bilgilerini kaydet/güncelle
  Future<void> savePatientInfo(PatientInfo info) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(info.patientId)
          .set(info.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Hasta bilgileri kaydedilirken hata oluştu: $e');
    }
  }

  // Hasta bilgilerini getir
  Future<PatientInfo?> getPatientInfo(String patientId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(patientId).get();
      if (doc.exists && doc.data() != null) {
        return PatientInfo.fromFirestore(
            doc.data()! as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Hasta bilgileri getirilirken hata oluştu: $e');
    }
  }

  // Hasta bilgilerini güncelle
  Future<void> updatePatientInfo(PatientInfo info) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(info.patientId)
          .update(info.toMap());
    } catch (e) {
      throw Exception('Hasta bilgileri güncellenirken hata oluştu: $e');
    }
  }
}

