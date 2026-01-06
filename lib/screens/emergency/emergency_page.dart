import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/fcm_service.dart';
import '../../services/patient_info_service.dart';
import '../../models/app_user.dart';
import '../../models/patient_info.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  bool _autoShareLocation = true;
  bool _notifyFamily = true;
  String _statusMessage = 'Hazır';
  bool _isProcessing = false;

  final _userService = UserService();
  final _locationService = LocationService();
  final _patientInfoService = PatientInfoService();
  final _firestore = FirebaseFirestore.instance;

  final _contacts = const [
    _EmergencyContact(
      name: 'Ayşe Korkmaz',
      relationship: 'Kızı',
      phone: '+90 555 123 45 67',
    ),
    _EmergencyContact(
      name: 'Mehmet Korkmaz',
      relationship: 'Oğlu',
      phone: '+90 555 987 65 43',
    ),
    _EmergencyContact(
      name: 'Dr. Selin Yıldız',
      relationship: 'Aile hekimi',
      phone: '+90 216 123 45 67',
    ),
  ];

  Future<void> _triggerEmergency() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Acil durum sinyali gönderiliyor...';
    });

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        setState(() {
          _statusMessage = 'Kullanıcı girişi gerekli';
          _isProcessing = false;
        });
        return;
      }

      // Hasta bilgilerini al
      final patientUser = await _userService.getUser(currentUser.uid);
      final patientName = patientUser?.name ?? 'Hasta';

      // Hasta yakınını bul (hem uid hem de uid_patient formatlarını kontrol et)
      final caregiver = await _userService.getCaregiverByPatientAnyId(currentUser.uid);
      
      if (caregiver == null) {
        setState(() {
          _statusMessage = 'Hasta yakını bulunamadı';
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasta yakını bulunamadı. Lütfen hasta yakını ile bağlantı kurulduğundan emin olun.'),
            backgroundColor: Color(0xFFFB7C7C),
          ),
        );
        return;
      }

      // Mevcut konumu al
      Position? currentPosition;
      if (_autoShareLocation) {
        try {
          currentPosition = await _locationService.getCurrentLocation();
        } catch (e) {
          print('Konum alınamadı: $e');
        }
      }

      // Firestore'a acil durum bildirimi kaydet
      await _firestore.collection('emergency_alerts').add({
        'patientId': currentUser.uid,
        'patientName': patientName,
        'caregiverId': caregiver.uid,
        'caregiverName': caregiver.name,
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': currentPosition?.latitude,
        'longitude': currentPosition?.longitude,
        'status': 'active',
      });

      // Hasta yakınına bildirim gönder
      if (_notifyFamily) {
        // Local notification göster
        await NotificationService().showEmergencyNotification(
          title: '🚨 Acil Durum!',
          body: '$patientName acil durum butonuna bastı!',
        );
        
        // FCM push notification gönder
        try {
          await FcmService().sendNotificationToUser(
            targetUserId: caregiver.uid,
            title: '🚨 Acil Durum!',
            body: '$patientName acil durum butonuna bastı!',
            data: {
              'type': 'emergency',
              'patientId': currentUser.uid,
              'patientName': patientName,
              'latitude': currentPosition?.latitude,
              'longitude': currentPosition?.longitude,
            },
          );
        } catch (e) {
          print('FCM bildirim gönderme hatası: $e');
        }
      }

      setState(() {
        _statusMessage = 'Hasta yakınına bildirim gönderildi...';
      });

      // Otomatik olarak hasta yakınına arama yapmayı dene
      if (_notifyFamily) {
        try {
          final caregiverInfo = await _patientInfoService.getPatientInfo(caregiver.uid);
          String? phoneNumber = caregiverInfo?.phone;

          if (phoneNumber == null || phoneNumber.isEmpty) {
            final patientInfo = await _patientInfoService.getPatientInfo(currentUser.uid);
            phoneNumber = patientInfo?.phone;
          }

          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
            final uri = Uri.parse('tel:$cleanPhone');
            if (await canLaunchUrl(uri)) {
              // Kısa bir gecikme sonra arama yap
              Future.delayed(const Duration(seconds: 1), () async {
                await launchUrl(uri);
              });
            }
          }
        } catch (e) {
          print('Otomatik arama hatası: $e');
        }
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Acil durum sinyali gönderildi. Hasta yakını bilgilendirildi.';
          _isProcessing = false;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Hata: ${e.toString()}';
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Acil durum gönderilirken hata oluştu: ${e.toString()}'),
          backgroundColor: const Color(0xFFFB7C7C),
        ),
      );
    }
  }

  /// Hasta yakınına telefon araması yap
  Future<void> _callCaregiver() async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) return;

      final caregiver = await _userService.getCaregiverByPatientAnyId(currentUser.uid);
      if (caregiver == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasta yakını bulunamadı'),
            backgroundColor: Color(0xFFFB7C7C),
          ),
        );
        return;
      }

      // Hasta yakınının telefon numarasını al
      // Önce hasta yakınının kendi PatientInfo'sunu kontrol et
      final caregiverInfo = await _patientInfoService.getPatientInfo(caregiver.uid);
      String? phoneNumber = caregiverInfo?.phone;

      // Eğer hasta yakınının telefon numarası yoksa, hasta bilgilerinden al
      if (phoneNumber == null || phoneNumber.isEmpty) {
        final patientInfo = await _patientInfoService.getPatientInfo(currentUser.uid);
        phoneNumber = patientInfo?.phone;
      }

      // Hala telefon numarası yoksa, acil durum kişilerinden ilkini dene
      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (_contacts.isNotEmpty) {
          phoneNumber = _contacts.first.phone;
        }
      }

      if (phoneNumber == null || phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telefon numarası bulunamadı. Lütfen hasta yakını bilgilerini güncelleyin.'),
            backgroundColor: Color(0xFFFB7C7C),
          ),
        );
        return;
      }

      // Telefon numarasını temizle (sadece rakamlar ve +)
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$cleanPhone');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arama yapılamadı'),
            backgroundColor: Color(0xFFFB7C7C),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arama hatası: ${e.toString()}'),
          backgroundColor: const Color(0xFFFB7C7C),
        ),
      );
    }
  }

  /// Hasta yakınına SMS gönder
  Future<void> _sendSmsToCaregiver() async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) return;

      final caregiver = await _userService.getCaregiverByPatientAnyId(currentUser.uid);
      if (caregiver == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasta yakını bulunamadı'),
            backgroundColor: Color(0xFFFB7C7C),
          ),
        );
        return;
      }

      // Telefon numarasını al
      final caregiverInfo = await _patientInfoService.getPatientInfo(caregiver.uid);
      String? phoneNumber = caregiverInfo?.phone;

      if (phoneNumber == null || phoneNumber.isEmpty) {
        final patientInfo = await _patientInfoService.getPatientInfo(currentUser.uid);
        phoneNumber = patientInfo?.phone;
      }

      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (_contacts.isNotEmpty) {
          phoneNumber = _contacts.first.phone;
        }
      }

      if (phoneNumber == null || phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telefon numarası bulunamadı'),
            backgroundColor: Color(0xFFFB7C7C),
          ),
        );
        return;
      }

      // Mevcut konumu al
      Position? currentPosition;
      try {
        currentPosition = await _locationService.getCurrentLocation();
      } catch (e) {
        print('Konum alınamadı: $e');
      }

      // SMS mesajı oluştur
      final patientUser = await _userService.getUser(currentUser.uid);
      final patientName = patientUser?.name ?? 'Hasta';
      String message = '🚨 ACİL DURUM: $patientName acil yardım istiyor!';
      
      if (currentPosition != null) {
        message += '\n\n📍 Konum: https://www.google.com/maps?q=${currentPosition.latitude},${currentPosition.longitude}';
      }

      // Telefon numarasını temizle
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(message)}');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS gönderilemedi'),
            backgroundColor: Color(0xFFFB7C7C),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SMS hatası: ${e.toString()}'),
          backgroundColor: const Color(0xFFFB7C7C),
        ),
      );
    }
  }

  /// Konum paylaş
  Future<void> _shareLocation() async {
    try {
      final currentPosition = await _locationService.getCurrentLocation();
      final currentUser = AuthService().currentUser;
      
      if (currentUser == null) return;

      final patientUser = await _userService.getUser(currentUser.uid);
      final patientName = patientUser?.name ?? 'Hasta';

      // Google Maps linki oluştur
      final mapsUrl = 'https://www.google.com/maps?q=${currentPosition.latitude},${currentPosition.longitude}';
      final shareText = '🚨 $patientName\'ın acil durum konumu:\n$mapsUrl';

      // Paylaşım intent'i oluştur
      final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}');
      
      // Önce WhatsApp'ı dene, yoksa genel paylaşım
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Genel paylaşım için
        final shareUri = Uri.parse('sms:?body=${Uri.encodeComponent(shareText)}');
        if (await canLaunchUrl(shareUri)) {
          await launchUrl(shareUri);
        } else {
          // Clipboard'a kopyala
          await Clipboard.setData(ClipboardData(text: mapsUrl));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Konum kopyalandı: $mapsUrl'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Tekrar Kopyala',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: mapsUrl));
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum paylaşımı hatası: ${e.toString()}'),
          backgroundColor: const Color(0xFFFB7C7C),
        ),
      );
    }
  }

  /// Push bildirim gönder
  Future<void> _sendPushNotification() async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) return;

      final caregiver = await _userService.getCaregiverByPatientAnyId(currentUser.uid);
      if (caregiver == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasta yakını bulunamadı'),
            backgroundColor: Color(0xFFFB7C7C),
          ),
        );
        return;
      }

      final patientUser = await _userService.getUser(currentUser.uid);
      final patientName = patientUser?.name ?? 'Hasta';

      // Mevcut konumu al
      Position? currentPosition;
      try {
        currentPosition = await _locationService.getCurrentLocation();
      } catch (e) {
        print('Konum alınamadı: $e');
      }

      // Local notification göster
      await NotificationService().showEmergencyNotification(
        title: '🚨 Acil Durum!',
        body: '$patientName acil yardım istiyor!',
      );

      // FCM push notification gönder
      await FcmService().sendNotificationToUser(
        targetUserId: caregiver.uid,
        title: '🚨 Acil Durum!',
        body: '$patientName acil yardım istiyor!',
        data: {
          'type': 'emergency',
          'patientId': currentUser.uid,
          'patientName': patientName,
          'latitude': currentPosition?.latitude,
          'longitude': currentPosition?.longitude,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim gönderildi'),
          backgroundColor: Color(0xFF4BBE9E),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bildirim hatası: ${e.toString()}'),
          backgroundColor: const Color(0xFFFB7C7C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _EmergencyHeader(),
              const SizedBox(height: 12),
              _StatusCard(
                statusMessage: _statusMessage,
                notifyFamily: _notifyFamily,
                autoShareLocation: _autoShareLocation,
              ),
              const SizedBox(height: 24),
              Center(
                child: _EmergencyButton(
                  onPressed: _isProcessing ? null : _triggerEmergency,
                  isProcessing: _isProcessing,
                ),
              ),
              const SizedBox(height: 24),
              _QuickActions(
                onCall: _callCaregiver,
                onSms: _sendSmsToCaregiver,
                onShareLocation: _shareLocation,
                onPushNotify: _sendPushNotification,
              ),
              const SizedBox(height: 24),
              _SafetySettings(
                autoShareLocation: _autoShareLocation,
                notifyFamily: _notifyFamily,
                onToggleLocation: (value) =>
                    setState(() => _autoShareLocation = value),
                onToggleNotify: (value) =>
                    setState(() => _notifyFamily = value),
              ),
              const SizedBox(height: 16),
              Text(
                'Acil durumda aranacak kişiler',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                _contacts.length,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _contacts.length - 1 ? 12 : 24,
                  ),
                  child: _ContactTile(contact: _contacts[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyHeader extends StatelessWidget {
  const _EmergencyHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acil durum butonu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tek dokunuşla yardım iste.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7B7C8D),
                  ),
            ),
          ],
        ),
        const Spacer(),
        IconButton.filled(
          onPressed: () {},
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.statusMessage,
    required this.notifyFamily,
    required this.autoShareLocation,
  });

  final String statusMessage;
  final bool notifyFamily;
  final bool autoShareLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Durum',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7B7C8D),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            statusMessage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                notifyFamily ? Icons.notifications_active : Icons.notifications,
                color: notifyFamily
                    ? const Color(0xFF4B7CFB)
                    : const Color(0xFF7B7C8D),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notifyFamily
                      ? 'Aile bireylerine push bildirimi gönderilecek.'
                      : 'Push bildirim kapalı.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5D5E73),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                autoShareLocation
                    ? Icons.location_on_rounded
                    : Icons.location_off_rounded,
                color: autoShareLocation
                    ? const Color(0xFF4BBE9E)
                    : const Color(0xFF7B7C8D),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  autoShareLocation
                      ? 'Konum SMS ve paylaşım linkiyle iletilecek.'
                      : 'Konum paylaşımı kapalı.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5D5E73),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({
    required this.onPressed,
    this.isProcessing = false,
  });

  final VoidCallback? onPressed;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (isProcessing || onPressed == null) ? null : onPressed,
      child: Opacity(
        opacity: isProcessing ? 0.6 : 1.0,
        child: Container(
        height: 180,
        width: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFB7C7C),
              Color(0xFFF64545),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF64545).withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProcessing)
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            else ...[
              const Icon(Icons.sos_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(
                'ACİL DURUM',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCall,
    required this.onSms,
    required this.onShareLocation,
    required this.onPushNotify,
  });

  final VoidCallback onCall;
  final VoidCallback onSms;
  final VoidCallback onShareLocation;
  final VoidCallback onPushNotify;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionChip(
          icon: Icons.call_rounded,
          label: 'Arama',
          onTap: onCall,
        ),
        _ActionChip(
          icon: Icons.sms_rounded,
          label: 'SMS',
          onTap: onSms,
        ),
        _ActionChip(
          icon: Icons.share_location_rounded,
          label: 'Konum',
          onTap: onShareLocation,
        ),
        _ActionChip(
          icon: Icons.notifications_active_rounded,
          label: 'Bildirim',
          onTap: onPushNotify,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4B7CFB)),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetySettings extends StatelessWidget {
  const _SafetySettings({
    required this.autoShareLocation,
    required this.notifyFamily,
    required this.onToggleLocation,
    required this.onToggleNotify,
  });

  final bool autoShareLocation;
  final bool notifyFamily;
  final ValueChanged<bool> onToggleLocation;
  final ValueChanged<bool> onToggleNotify;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingTile(
          title: 'Konum paylaşımı',
          subtitle: 'SMS ve uygulama üzerinden konum gönder.',
          value: autoShareLocation,
          onChanged: onToggleLocation,
        ),
        const SizedBox(height: 12),
        _SettingTile(
          title: 'Aile bildirimi',
          subtitle: 'Push notification ile aileyi bilgilendir.',
          value: notifyFamily,
          onChanged: onToggleNotify,
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            title.contains('Konum')
                ? Icons.location_on_rounded
                : Icons.notifications_active_rounded,
            color: const Color(0xFF4B7CFB),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7B7C8D),
                      ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4B7CFB),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final _EmergencyContact contact;

  Future<void> _callContact(BuildContext context) async {
    try {
      // Telefon numarasını temizle (sadece rakamlar ve +)
      final cleanPhone = contact.phone.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$cleanPhone');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arama yapılamadı'),
              backgroundColor: Color(0xFFFB7C7C),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arama hatası: ${e.toString()}'),
            backgroundColor: const Color(0xFFFB7C7C),
          ),
        );
      }
    }
  }

  Future<void> _sendSmsToContact(BuildContext context) async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) return;

      final userService = UserService();
      final patientUser = await userService.getUser(currentUser.uid);
      final patientName = patientUser?.name ?? 'Hasta';

      final locationService = LocationService();
      Position? currentPosition;
      try {
        currentPosition = await locationService.getCurrentLocation();
      } catch (e) {
        print('Konum alınamadı: $e');
      }

      String message = '🚨 ACİL DURUM: $patientName acil yardım istiyor!';
      if (currentPosition != null) {
        message += '\n\n📍 Konum: https://www.google.com/maps?q=${currentPosition.latitude},${currentPosition.longitude}';
      }

      final cleanPhone = contact.phone.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(message)}');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS gönderilemedi'),
              backgroundColor: Color(0xFFFB7C7C),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMS hatası: ${e.toString()}'),
            backgroundColor: const Color(0xFFFB7C7C),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              contact.name.substring(0, 1),
              style: const TextStyle(
                color: Color(0xFF4B7CFB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  contact.relationship,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7B7C8D),
                      ),
                ),
                Text(
                  contact.phone,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _callContact(context),
            icon: const Icon(Icons.call_rounded),
            tooltip: 'Ara',
            color: const Color(0xFF4BBE9E),
          ),
          IconButton(
            onPressed: () => _sendSmsToContact(context),
            icon: const Icon(Icons.sms_rounded),
            tooltip: 'SMS Gönder',
            color: const Color(0xFF4B7CFB),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContact {
  const _EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  final String name;
  final String relationship;
  final String phone;
}

