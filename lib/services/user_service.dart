import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Kullanıcı bilgilerini Firestore'a kaydet
  Future<void> saveUser(AppUser user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Firestore güvenlik kuralları hatası. Lütfen Firebase Console\'da Rules sekmesinden güvenlik kurallarını kontrol edin.'
        );
      } else if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw Exception(
          'Firestore bağlantı hatası. İnternet bağlantınızı kontrol edin veya Firestore veritabanının oluşturulduğundan emin olun.'
        );
      }
      throw Exception('Kullanıcı kaydedilirken hata oluştu: ${e.message}');
    } catch (e) {
      throw Exception('Kullanıcı kaydedilirken hata oluştu: $e');
    }
  }

  // Email'e göre kullanıcı getir
  Future<AppUser?> getUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty && query.docs.first.data() != null) {
        return AppUser.fromFirestore(
            query.docs.first.data()! as Map<String, dynamic>,
            query.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı e-posta ile getirilirken hata oluştu: $e');
    }
  }

  // Kullanıcı bilgilerini getir
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromFirestore(
            doc.data()! as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı getirilirken hata oluştu: $e');
    }
  }

  // Kullanıcı bilgilerini dinle (Stream)
  Stream<AppUser?> getUserStream(String uid) {
    return _firestore
        .collection(_collection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromFirestore(
            doc.data()! as Map<String, dynamic>, doc.id);
      }
      return null;
    }).handleError((error) {
      // Firestore hatalarını yakala ve logla
      print('Firestore getUserStream hatası: $error');
      return null;
    });
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUser(AppUser user) async {
    try {
      final userMap = user.toMap();
      userMap['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection(_collection)
          .doc(user.uid)
          .update(userMap);
    } catch (e) {
      throw Exception('Kullanıcı güncellenirken hata oluştu: $e');
    }
  }

  // Hasta yakını için: Bağlı olduğu hastayı ayarla
  Future<void> linkPatientToCaregiver(
      String caregiverId, String patientId) async {
    try {
      await _firestore.collection(_collection).doc(caregiverId).update({
        'patientId': patientId,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Hasta bağlantısı yapılırken hata oluştu: $e');
    }
  }

  // Hasta için: Bağlı olduğu hasta yakınını bul
  Future<AppUser?> getCaregiverByPatientId(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('patientId', isEqualTo: patientId)
          .where('role', isEqualTo: 'caregiver')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        if (doc.data() != null) {
          return AppUser.fromFirestore(
              doc.data()! as Map<String, dynamic>, doc.id);
        }
      }
      return null;
    } catch (e) {
      print('Hasta yakını bulunurken hata oluştu: $e');
      return null;
    }
  }

  /// Hasta için: patientId ya da patientId+"_patient" değerlerinden birine bağlı
  /// hasta yakınını bul (eski ve hatalı kayıtlarla uyum için, role filtresi YOK)
  Future<AppUser?> getCaregiverByPatientAnyId(String patientUid) async {
    final candidates = <String>{
      patientUid,
      '${patientUid}_patient',
    }.toList();

    print('🔍 Hasta yakını aranıyor - Patient UID: $patientUid');
    print('🔍 Kontrol edilen patientId değerleri: $candidates');

    try {
      // 1) Önce tam eşleşmeyi dene (role filtresi yok)
      var querySnapshot = await _firestore
          .collection(_collection)
          .where('patientId', isEqualTo: patientUid)
          .limit(1)
          .get();

      // 2) Bulunamazsa uid_patient formatını dene
      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await _firestore
            .collection(_collection)
            .where('patientId', isEqualTo: '${patientUid}_patient')
            .limit(1)
            .get();
      }

      // 3) Hâlâ bulunamazsa, whereIn ile daha geniş arama yap
      if (querySnapshot.docs.isEmpty && candidates.length > 1) {
        querySnapshot = await _firestore
            .collection(_collection)
            .where('patientId', whereIn: candidates)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        if (doc.data() != null) {
          final caregiver = AppUser.fromFirestore(
              doc.data()! as Map<String, dynamic>, doc.id);
          print(
              '✅ Hasta yakını bulundu (anyId): ${caregiver.name} (${caregiver.uid}), patientId: ${caregiver.patientId}, role: ${caregiver.role}');
          return caregiver;
        }
      }

      print('❌ Hasta yakını bulunamadı - Patient UID: $patientUid');
      return null;
    } catch (e) {
      print('❌ Hasta yakını bulunurken hata oluştu (anyId): $e');
      return null;
    }
  }
}

