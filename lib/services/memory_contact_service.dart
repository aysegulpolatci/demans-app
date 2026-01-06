import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memory_contact.dart';
import '../models/app_user.dart';
import 'auth_service.dart';
import 'user_service.dart';

class MemoryContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'memory_contacts';
  final _userService = UserService();

  /// Hasta yakını için hasta ID'sini, hasta için kendi ID'sini döndürür
  Future<String> _getTargetUserId() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      throw Exception('Kullanıcı girişi gerekli');
    }

    final user = await _userService.getUser(currentUser.uid);
    if (user == null) {
      throw Exception('Kullanıcı bilgisi bulunamadı');
    }

    // Hasta yakını ise, bağlı olduğu hasta ID'sini kullan
    // Hasta ise, kendi ID'sini kullan
    if (user.role == UserRole.caregiver) {
      if (user.patientId == null) {
        print('⚠️ UYARI: Hasta yakını kullanıcısının patientId değeri null!');
        throw Exception('Kişi eklemek için önce profil ayarlarından hasta bilgilerini eklemeniz gerekiyor.');
      }
      print('🎯 _getTargetUserId - Hasta yakını, patientId: ${user.patientId}');
      return user.patientId!;
    } else {
      print('🎯 _getTargetUserId - Hasta, uid: ${user.uid}');
      return user.uid;
    }
  }

  /// Yeni kişi ekle
  Future<void> addMemoryContact(MemoryContact contact) async {
    try {
      final targetUserId = await _getTargetUserId();
      print('📝 Kişi ekleniyor - targetUserId: $targetUserId');

      await _firestore.collection(_collection).add({
        'name': contact.name,
        'relationship': contact.relationship,
        'description': contact.description,
        'imageUrl': contact.imageUrl,
        'lastSeen': contact.lastSeen.toIso8601String(),
        'ttsScript': contact.ttsScript,
        'isFavorite': contact.isFavorite,
        'userId': targetUserId, // Hasta yakını için hasta ID'si, hasta için kendi ID'si
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Kişi başarıyla eklendi - userId: $targetUserId');
    } catch (e) {
      print('❌ Kişi ekleme hatası: $e');
      throw Exception('Kişi eklenirken hata oluştu: $e');
    }
  }

  /// Kişi güncelle
  Future<void> updateMemoryContact(MemoryContact contact) async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      await _firestore.collection(_collection).doc(contact.id).update({
        'name': contact.name,
        'relationship': contact.relationship,
        'description': contact.description,
        'imageUrl': contact.imageUrl,
        'lastSeen': contact.lastSeen.toIso8601String(),
        'ttsScript': contact.ttsScript,
        'isFavorite': contact.isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Kişi güncellenirken hata oluştu: $e');
    }
  }

  /// Kişi sil
  Future<void> deleteMemoryContact(String contactId) async {
    try {
      await _firestore.collection(_collection).doc(contactId).delete();
    } catch (e) {
      throw Exception('Kişi silinirken hata oluştu: $e');
    }
  }

  /// Kullanıcının tüm kişilerini getir
  /// userId parametresi: Hasta yakını için hasta ID'si, hasta için kendi ID'si
  Stream<List<MemoryContact>> getMemoryContacts({String? userId}) {
    print('🔍 getMemoryContacts başlatılıyor - userId: $userId');

    Query query = _firestore.collection(_collection);
    
    // Eğer userId varsa, sadece o kullanıcının kişilerini getir
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    // Firestore sorgusunu optimize et - orderBy kaldırıldı (index gerektirmemesi için)
    // Sıralama client-side'da yapılacak
    return query.snapshots().map((snapshot) {
      try {
        print('📊 Firestore sorgusu sonucu - ${snapshot.docs.length} kişi bulundu (userId: $userId)');
        final contacts = snapshot.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                final docUserId = data['userId'] as String?;
                print('  - ${data['name']} (userId: $docUserId)');
                
                return MemoryContact.fromFirestore(data, doc.id);
              } catch (e) {
                print('❌ Kişi parse hatası (${doc.id}): $e');
                return null;
              }
            })
            .whereType<MemoryContact>()
            .toList();
        
        // Client-side'da createdAt'e göre sırala (en yeni önce)
        contacts.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
        
        print('✅ getMemoryContacts - ${contacts.length} kişi döndürülüyor');
        return contacts;
      } catch (e) {
        print('❌ Stream map hatası: $e');
        return <MemoryContact>[];
      }
    }).handleError((error) {
      print('❌ Memory contacts stream hatası: $error');
      return <MemoryContact>[];
    });
  }

  /// Birden fazla userId için kişiler (whereIn)
  /// Firestore whereIn limiti: max 10 eleman
  Stream<List<MemoryContact>> getMemoryContactsForUserIds(List<String> userIds) {
    final ids = userIds.toSet().where((e) => e.isNotEmpty).toList();
    print('🔍 getMemoryContactsForUserIds - ids: $ids');

    if (ids.isEmpty) {
      return const Stream.empty();
    }

    // whereIn en fazla 10 id destekliyor
    final limitedIds = ids.take(10).toList();

    return _firestore
        .collection(_collection)
        .where('userId', whereIn: limitedIds)
        .snapshots()
        .map((snapshot) {
      try {
        print('📊 Firestore (whereIn) sonucu - ${snapshot.docs.length} kişi');
        final contacts = snapshot.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                return MemoryContact.fromFirestore(data, doc.id);
              } catch (e) {
                print('❌ Kişi parse hatası (${doc.id}): $e');
                return null;
              }
            })
            .whereType<MemoryContact>()
            .toList();

        contacts.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
        return contacts;
      } catch (e) {
        print('❌ Stream map hatası (whereIn): $e');
        return <MemoryContact>[];
      }
    }).handleError((error) {
      print('❌ Memory contacts stream hatası (whereIn): $error');
      return <MemoryContact>[];
    });
  }

  /// Kişi getir (ID ile)
  Future<MemoryContact?> getMemoryContact(String contactId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(contactId).get();
      if (doc.exists && doc.data() != null) {
        return MemoryContact.fromFirestore(
            doc.data()! as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Kişi getirilirken hata oluştu: $e');
    }
  }
}

