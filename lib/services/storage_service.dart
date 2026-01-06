import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Fotoğraf yükle ve URL döndür
  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      // Dosya var mı kontrol et
      if (!await imageFile.exists()) {
        throw Exception('Fotoğraf dosyası bulunamadı');
      }

      // Benzersiz dosya adı oluştur
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${currentUser.uid}_$timestamp.jpg';
      final ref = _storage.ref().child('$folder/$fileName');

      print('📤 Fotoğraf yükleniyor: $folder/$fileName');

      // Fotoğrafı yükle (metadata ile)
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      print('📤 Upload başlatılıyor: $folder/$fileName');
      print('📁 Dosya boyutu: ${await imageFile.length()} bytes');
      print('📁 Dosya yolu: ${imageFile.path}');

      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Upload progress'i takip et
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        if (taskSnapshot.totalBytes > 0) {
          final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
          print('📤 Upload ilerleme: ${progress.toStringAsFixed(1)}%');
        }
      });

      // Upload'ı bekle
      final snapshot = await uploadTask;
      
      // Upload durumunu kontrol et
      print('📊 Upload durumu: ${snapshot.state}');
      print('📊 Yüklenen: ${snapshot.bytesTransferred} / ${snapshot.totalBytes} bytes');
      
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload başarısız: ${snapshot.state}. Lütfen Firebase Storage\'ı etkinleştirdiğinizden emin olun.');
      }
      
      print('✅ Fotoğraf yüklendi: ${snapshot.ref.fullPath}');
      
      // Dosyanın hazır olması için bekle
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Önce metadata kontrolü yap
      try {
        final metadata = await snapshot.ref.getMetadata();
        print('✅ Dosya metadata alındı: ${metadata.name} (${metadata.size} bytes)');
      } catch (metaError) {
        print('⚠️ Metadata alınamadı ama devam ediliyor: $metaError');
      }
      
      // Download URL'yi al - birkaç kez dene
      String? downloadUrl;
      for (int i = 0; i < 3; i++) {
        try {
          downloadUrl = await snapshot.ref.getDownloadURL();
          print('🔗 Download URL alındı (deneme ${i + 1}): $downloadUrl');
          break;
        } catch (e) {
          print('⚠️ Download URL alınamadı (deneme ${i + 1}): $e');
          if (i < 2) {
            await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
          }
        }
      }
      
      // Eğer getDownloadURL başarısız olduysa, manuel URL oluştur
      if (downloadUrl == null) {
        print('⚠️ getDownloadURL başarısız, manuel URL oluşturuluyor...');
        try {
          final bucket = _storage.ref().bucket;
          final fullPath = snapshot.ref.fullPath;
          final encodedPath = Uri.encodeComponent(fullPath);
          downloadUrl = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media';
          print('🔗 Manuel URL oluşturuldu: $downloadUrl');
        } catch (urlError) {
          print('❌ Manuel URL oluşturulamadı: $urlError');
          throw Exception('Firebase Storage hatası. Lütfen Firebase Console\'dan Storage\'ı etkinleştirdiğinizden ve güvenlik kurallarını ayarladığınızdan emin olun.');
        }
      }
      
      return downloadUrl!;
    } on FirebaseException catch (e) {
      print('❌ Firebase Storage hatası: ${e.code} - ${e.message}');
      throw Exception('Firebase Storage hatası: ${e.code} - ${e.message}');
    } catch (e) {
      print('❌ Fotoğraf yükleme hatası: $e');
      throw Exception('Fotoğraf yüklenirken hata oluştu: $e');
    }
  }

  /// Fotoğraf sil
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Fotoğraf silinirken hata oluştu: $e');
      // Fotoğraf silme hatası kritik değil, devam et
    }
  }
}

