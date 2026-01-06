import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';

/// Firebase Cloud Messaging servisi
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;

  /// FCM servisini başlat
  Future<void> initialize() async {
    // İzinleri iste
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('FCM: Kullanıcı bildirim izni verdi');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('FCM: Kullanıcı geçici bildirim izni verdi');
    } else {
      print('FCM: Kullanıcı bildirim izni vermedi');
      return;
    }

    // Token al ve kaydet
    await _saveTokenToFirestore();

    // Token yenilendiğinde güncelle
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveTokenToFirestore();
    });

    // Arka planda gelen bildirimleri işle
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground bildirimleri için handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Bildirime tıklandığında
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Uygulama kapalıyken bildirime tıklandıysa kontrol et
    RemoteMessage? initialMessage =
        await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// FCM token'ını Firestore'a kaydet
  Future<void> _saveTokenToFirestore() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        print('FCM: Token alınamadı');
        return;
      }

      _fcmToken = token;
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        print('FCM: Kullanıcı girişi yok, token kaydedilemedi');
        return;
      }

      // Firestore'a token'ı kaydet
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(currentUser.uid)
          .set({
        'token': token,
        'userId': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('FCM: Token Firestore\'a kaydedildi: $token');
    } catch (e) {
      print('FCM: Token kaydetme hatası: $e');
    }
  }

  /// Foreground bildirimlerini işle
  void _handleForegroundMessage(RemoteMessage message) {
    print('FCM: Foreground bildirim alındı: ${message.notification?.title}');

    // Local notification göster
    if (message.notification != null) {
      _showLocalNotification(message);
    }
  }

  /// Local notification göster
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Yüksek Öncelikli Bildirimler',
      description: 'Acil durum ve önemli bildirimler için kullanılır',
      importance: Importance.high,
    );

    final androidDetails = AndroidNotificationDetails(
      androidChannel.id,
      androidChannel.name,
      channelDescription: androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Bildirim',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }

  /// Bildirime tıklandığında işle
  void _handleNotificationTap(RemoteMessage message) {
    print('FCM: Bildirime tıklandı: ${message.notification?.title}');
    // Burada uygulama içi navigasyon yapılabilir
    // Örneğin: EmergencyPage'e yönlendirme
  }

  /// Belirli bir kullanıcıya push notification gönder
  /// Not: Bu işlem için Firebase Cloud Functions veya backend servisi gerekir
  /// Burada sadece Firestore'a bildirim isteği kaydediyoruz
  Future<void> sendNotificationToUser({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Firestore'a bildirim isteği kaydet
      // Cloud Function veya backend servisi bu isteği dinleyip bildirim gönderecek
      await FirebaseFirestore.instance.collection('notification_requests').add({
        'targetUserId': targetUserId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('FCM: Bildirim isteği Firestore\'a kaydedildi');
    } catch (e) {
      print('FCM: Bildirim gönderme hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcının FCM token'ını al
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    _fcmToken = await _messaging.getToken();
    return _fcmToken;
  }

  /// Token'ı sil (çıkış yapıldığında)
  Future<void> deleteToken() async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('fcm_tokens')
            .doc(currentUser.uid)
            .delete();
      }
      await _messaging.deleteToken();
      _fcmToken = null;
      print('FCM: Token silindi');
    } catch (e) {
      print('FCM: Token silme hatası: $e');
    }
  }
}

/// Arka planda gelen bildirimleri işle
/// Bu fonksiyon top-level olmalı
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('FCM: Arka plan bildirimi alındı: ${message.notification?.title}');
  // Burada gerekli işlemler yapılabilir
}

