import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Bildirim servisini başlat
  Future<void> initialize() async {
    if (_initialized) return;

    // Timezone verilerini yükle
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    // Android yapılandırması
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS yapılandırması
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android için kanal oluştur
    await _createNotificationChannel();

    _initialized = true;
  }

  /// Android bildirim kanalı oluştur
  Future<void> _createNotificationChannel() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Hatırlatıcı kanalı
    const reminderChannel = AndroidNotificationChannel(
      'reminder_channel',
      'Hatırlatıcı Bildirimleri',
      description: 'İlaç saatleri ve görev hatırlatıcıları için bildirimler',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Acil durum kanalı
    const emergencyChannel = AndroidNotificationChannel(
      'emergency_channel',
      'Acil Durum Bildirimleri',
      description: 'Hasta acil durum bildirimleri',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(emergencyChannel);
  }

  /// Hatırlatıcı için bildirim zamanla
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!_initialized) await initialize();

    if (reminder.id == null) {
      print('⚠️ Hatırlatıcı ID yok, bildirim zamanlanamıyor');
      return;
    }

    // timeLabel'dan saat ve dakikayı parse et (örn: "11:30")
    final timeParts = reminder.timeLabel.split(':');
    if (timeParts.length != 2) {
      print('⚠️ Geçersiz zaman formatı: ${reminder.timeLabel}');
      return;
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (hour == null || minute == null) {
      print('⚠️ Saat/dakika parse edilemedi: ${reminder.timeLabel}');
      return;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      print('⚠️ Geçersiz saat/dakika: $hour:$minute');
      return;
    }

    // Bugünün tarihini al ve belirtilen saat/dakikaya ayarla
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Eğer zaman geçmişse, yarın için zamanla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('⏰ Zaman geçmiş, yarın için zamanlandı: ${scheduledDate.toString()}');
    } else {
      print('⏰ Bugün için zamanlandı: ${scheduledDate.toString()}');
    }

    // Bildirim başlığı ve içeriği
    String title = reminder.title;
    String body = reminder.subtitle.isNotEmpty
        ? reminder.subtitle
        : reminder.note.isNotEmpty
            ? reminder.note
            : 'Hatırlatıcı zamanı geldi!';

    // Kategoriye göre emoji ekle
    String emoji = '';
    switch (reminder.category) {
      case ReminderCategory.medication:
        emoji = '💊';
        break;
      case ReminderCategory.appointment:
        emoji = '🏥';
        break;
      case ReminderCategory.activity:
        emoji = '✅';
        break;
    }

    title = '$emoji $title';

    // Android bildirim detayları
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Hatırlatıcı Bildirimleri',
      channelDescription: 'İlaç saatleri ve görev hatırlatıcıları için bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    // iOS bildirim detayları
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Bildirimi zamanla
    try {
      await _notifications.zonedSchedule(
        reminder.id!.hashCode, // Unique ID
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrarla
      );
      print('✅ Bildirim zamanlandı: $title - $scheduledDate');
    } catch (e) {
      print('❌ Bildirim zamanlama hatası: $e');
      rethrow;
    }
  }

  /// Tüm hatırlatıcıları zamanla
  Future<void> scheduleAllReminders(List<Reminder> reminders) async {
    // Önce tüm mevcut bildirimleri iptal et
    await cancelAllNotifications();

    // Her hatırlatıcı için bildirim zamanla
    for (final reminder in reminders) {
      if (reminder.id != null) {
        await scheduleReminderNotification(reminder);
      }
    }
  }

  /// Belirli bir hatırlatıcının bildirimini iptal et
  Future<void> cancelReminderNotification(String reminderId) async {
    await _notifications.cancel(reminderId.hashCode);
  }

  /// Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Bildirim tıklandığında çağrılır
  void _onNotificationTapped(NotificationResponse response) {
    // Burada bildirime tıklandığında yapılacak işlemler
    // Örneğin: Hatırlatıcılar sayfasına yönlendirme
    print('Bildirim tıklandı: ${response.payload}');
  }

  /// Bildirim izinlerini kontrol et (iOS için)
  Future<bool> requestPermissions() async {
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final result = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    // Android için izin gerekmez (manifest'te tanımlı)
    return true;
  }

  /// Mevcut bildirimleri listele (test için)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Test bildirimi gönder (hemen)
  /// Acil durum bildirimi göster
  Future<void> showEmergencyNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Acil Durum Bildirimleri',
      channelDescription: 'Hasta acil durum bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      9999, // Acil durum için özel ID
      title,
      body,
      details,
    );
  }

  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Hatırlatıcı Bildirimleri',
      channelDescription: 'İlaç saatleri ve görev hatırlatıcıları için bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999999, // Test ID
      '💊 Test Bildirimi',
      'Bildirim sistemi çalışıyor!',
      notificationDetails,
    );
  }
}

