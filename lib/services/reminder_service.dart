import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reminders';

  // Kullanıcı ID'si ile hatırlatıcıları getir (şimdilik tümünü getir)
  Stream<List<Reminder>> getReminders({String? userId}) {
    Query query = _firestore.collection(_collection);
    
    // Eğer userId varsa, sadece o kullanıcının hatırlatıcılarını getir
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    
    return query
        .orderBy('timeLabel')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reminder.fromFirestore(
                doc.data() as Map<String, dynamic>, id: doc.id))
            .toList())
        .handleError((error) {
      // Firestore hatalarını yakala
      print('Firestore getReminders hatası: $error');
      return <Reminder>[]; // Boş liste döndür
    });
  }

  // Tek bir hatırlatıcı getir
  Future<Reminder?> getReminderById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Reminder.fromFirestore(
            doc.data()! as Map<String, dynamic>, id: doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Hatırlatıcı getirilirken hata oluştu: $e');
    }
  }

  // Yeni hatırlatıcı ekle
  Future<String> addReminder(Reminder reminder, {String? userId}) async {
    try {
      final reminderMap = reminder.toMap();
      
      // Kullanıcı ID'si varsa ekle
      if (userId != null) {
        reminderMap['userId'] = userId;
      }
      
      final docRef = await _firestore.collection(_collection).add(reminderMap);
      return docRef.id;
    } catch (e) {
      throw Exception('Hatırlatıcı eklenirken hata oluştu: $e');
    }
  }

  // Hatırlatıcı güncelle
  Future<void> updateReminder(Reminder reminder) async {
    try {
      if (reminder.id == null) {
        throw Exception('Güncellenecek hatırlatıcının ID\'si yok');
      }
      
      final reminderMap = reminder.toMap();
      reminderMap['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection(_collection)
          .doc(reminder.id)
          .update(reminderMap);
    } catch (e) {
      throw Exception('Hatırlatıcı güncellenirken hata oluştu: $e');
    }
  }

  // Hatırlatıcı sil
  Future<void> deleteReminder(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Hatırlatıcı silinirken hata oluştu: $e');
    }
  }

  // Kategoriye göre hatırlatıcıları getir
  Stream<List<Reminder>> getRemindersByCategory(
    ReminderCategory category, {
    String? userId,
  }) {
    Query query = _firestore.collection(_collection);
    
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    
    return query
        .where('category', isEqualTo: category.name)
        .orderBy('timeLabel')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reminder.fromFirestore(
                doc.data() as Map<String, dynamic>, id: doc.id))
            .toList())
        .handleError((error) {
      // Firestore hatalarını yakala
      print('Firestore getRemindersByCategory hatası: $error');
      return <Reminder>[]; // Boş liste döndür
    });
  }

  // Aktif (tamamlanmamış) hatırlatıcıları getir
  Stream<List<Reminder>> getActiveReminders({String? userId}) {
    Query query = _firestore.collection(_collection);
    
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    
    return query
        .where('isCompleted', isEqualTo: false)
        .orderBy('timeLabel')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reminder.fromFirestore(
                doc.data() as Map<String, dynamic>, id: doc.id))
            .toList())
        .handleError((error) {
      print('Firestore getActiveReminders hatası: $error');
      return <Reminder>[];
    });
  }

  // Tamamlanmış hatırlatıcıları getir
  Stream<List<Reminder>> getCompletedReminders({String? userId}) {
    Query query = _firestore.collection(_collection);
    
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    
    return query
        .where('isCompleted', isEqualTo: true)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reminder.fromFirestore(
                doc.data() as Map<String, dynamic>, id: doc.id))
            .toList())
        .handleError((error) {
      print('Firestore getCompletedReminders hatası: $error');
      return <Reminder>[];
    });
  }

  // Hatırlatıcıyı tamamla
  Future<void> completeReminder(String id, {bool complete = true}) async {
    try {
      final updateData = <String, dynamic>{
        'isCompleted': complete,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (complete) {
        updateData['completedAt'] = DateTime.now().toIso8601String();
      } else {
        updateData['completedAt'] = FieldValue.delete();
      }

      await _firestore.collection(_collection).doc(id).update(updateData);
    } catch (e) {
      throw Exception('Hatırlatıcı tamamlanırken hata oluştu: $e');
    }
  }

  // Tekrarlayan hatırlatıcı için yeni hatırlatıcı oluştur
  Future<String?> createNextRepeat(Reminder reminder) async {
    if (reminder.repeatType == ReminderRepeatType.none || reminder.id == null) {
      return null;
    }

    try {
      DateTime nextDate;
      if (reminder.nextRepeatDate != null) {
        nextDate = reminder.nextRepeatDate!;
      } else {
        // İlk tekrarlama için bugünden itibaren hesapla
        final now = DateTime.now();
        if (reminder.repeatType == ReminderRepeatType.daily) {
          nextDate = now.add(const Duration(days: 1));
        } else if (reminder.repeatType == ReminderRepeatType.weekly) {
          nextDate = now.add(const Duration(days: 7));
        } else {
          return null;
        }
      }

      // Yeni hatırlatıcı oluştur
      final newReminder = reminder.copyWith(
        id: null, // Yeni ID oluşturulacak
        isCompleted: false,
        completedAt: null,
        nextRepeatDate: reminder.repeatType == ReminderRepeatType.daily
            ? nextDate.add(const Duration(days: 1))
            : nextDate.add(const Duration(days: 7)),
      );

      final reminderMap = newReminder.toMap();
      final docRef = await _firestore.collection(_collection).add(reminderMap);
      return docRef.id;
    } catch (e) {
      print('Tekrarlayan hatırlatıcı oluşturulurken hata: $e');
      return null;
    }
  }
}

