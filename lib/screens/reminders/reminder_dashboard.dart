import 'package:flutter/material.dart';

import '../../models/reminder.dart';
import '../../services/reminder_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../models/app_user.dart';
import '../../services/tts_service.dart';
import 'add_reminder_page.dart';
import '../profile/profile_settings_page.dart';

class ReminderDashboard extends StatelessWidget {
  const ReminderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Kullanıcı girişi gerekli')),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: UserService().getUserStream(currentUser.uid),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final isCaregiver = user?.role == UserRole.caregiver;

        return _ReminderDashboardContent(isCaregiver: isCaregiver);
      },
    );
  }
}

class _ReminderDashboardContent extends StatefulWidget {
  const _ReminderDashboardContent({required this.isCaregiver});

  final bool isCaregiver;

  @override
  State<_ReminderDashboardContent> createState() => _ReminderDashboardContentState();
}

class _ReminderDashboardContentState extends State<_ReminderDashboardContent> {
  final NotificationService _notificationService = NotificationService();
  final ReminderService _reminderService = ReminderService();
  final TtsService _ttsService = TtsService();
  List<Reminder> _previousReminders = [];
  ReminderCategory? _selectedFilter; // null = Tümü
  bool _showCompleted = false; // Tamamlanmış hatırlatıcıları göster
  late final Stream<List<Reminder>> _remindersStream;
  late final Stream<List<Reminder>> _completedRemindersStream;

  @override
  void initState() {
    super.initState();
    // Bildirim servisini başlat
    _notificationService.initialize();
    // Stream'leri oluştur
    _remindersStream = _reminderService.getActiveReminders();
    _completedRemindersStream = _reminderService.getCompletedReminders();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _speakReminder(Reminder reminder) {
    final text = StringBuffer()
      ..write('${reminder.title}. ')
      ..write(reminder.subtitle.isNotEmpty ? '${reminder.subtitle}. ' : '')
      ..write(reminder.note.isNotEmpty ? '${reminder.note}. ' : '')
      ..write('Zaman: ${reminder.timeLabel}. ')
      ..write(reminder.dosage.isNotEmpty ? 'Doz: ${reminder.dosage}. ' : '')
      ..write(reminder.location.isNotEmpty ? 'Konum: ${reminder.location}. ' : '');

    _ttsService.speak(text.toString()).catchError((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hatırlatıcı seslendirme hatası: $e'),
          backgroundColor: const Color(0xFFFB7C7C),
        ),
      );
    });
  }

  Future<void> _handleComplete(Reminder reminder) async {
    if (reminder.id == null) return;

    try {
      await _reminderService.completeReminder(reminder.id!, complete: true);
      
      // Eğer tekrarlayan hatırlatıcı ise, yeni hatırlatıcı oluştur
      if (reminder.repeatType != ReminderRepeatType.none) {
        await _reminderService.createNextRepeat(reminder);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hatırlatıcı tamamlandı'),
          backgroundColor: Color(0xFF4BBE9E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: const Color(0xFFFB7C7C),
        ),
      );
    }
  }

  Future<void> _handleEdit(Reminder reminder) async {
    if (reminder.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderPage(initialReminder: reminder),
      ),
    );
  }

  Future<void> _handleDelete(Reminder reminder) async {
    if (reminder.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hatırlatıcıyı Sil'),
        content: Text('${reminder.title} hatırlatıcısını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFB7C7C),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _reminderService.deleteReminder(reminder.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hatırlatıcı silindi'),
          backgroundColor: Color(0xFF4BBE9E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: const Color(0xFFFB7C7C),
        ),
      );
    }
  }

  Future<void> _scheduleNotificationsIfNeeded(List<Reminder> reminders) async {
    // Eğer hatırlatıcılar değiştiyse bildirimleri güncelle
    if (_remindersChanged(_previousReminders, reminders)) {
      try {
        print('📅 ${reminders.length} hatırlatıcı için bildirimler zamanlanıyor...');
        await _notificationService.scheduleAllReminders(reminders);
        _previousReminders = List.from(reminders);
        print('✅ Bildirimler başarıyla zamanlandı');
        
        // Debug: Bekleyen bildirimleri kontrol et
        final pending = await _notificationService.getPendingNotifications();
        print('🔔 Bekleyen bildirim sayısı: ${pending.length}');
        for (final notif in pending) {
          print('  - ${notif.title} (${notif.body})');
        }
      } catch (e) {
        print('❌ Bildirim zamanlama hatası: $e');
      }
    }
  }

  bool _remindersChanged(List<Reminder> oldList, List<Reminder> newList) {
    if (oldList.length != newList.length) return true;
    
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i].id != newList[i].id ||
          oldList[i].timeLabel != newList[i].timeLabel) {
        return true;
      }
    }
    
    return false;
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
              const _HeaderSection(),
              const SizedBox(height: 20),
              const _TodayCard(),
              const SizedBox(height: 24),
              _FilterChips(
                selectedFilter: _selectedFilter,
                onFilterChanged: (category) {
                  setState(() {
                    _selectedFilter = category;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Aktif/Tamamlanmış sekmeleri
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: !_showCompleted,
                      onSelected: (selected) {
                        setState(() {
                          _showCompleted = false;
                        });
                      },
                      label: const Text('Aktif'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      selected: _showCompleted,
                      onSelected: (selected) {
                        setState(() {
                          _showCompleted = true;
                        });
                      },
                      label: const Text('Tamamlanan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Reminder>>(
                stream: _showCompleted ? _completedRemindersStream : _remindersStream,
                  builder: (context, snapshot) {
                  // Hatırlatıcılar yüklendiğinde bildirimleri zamanla
                  if (snapshot.hasData && snapshot.data != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scheduleNotificationsIfNeeded(snapshot.data!);
                    });
                  }
                  
                  // Filtreleme uygula
                  List<Reminder> filteredReminders = snapshot.data ?? [];
                  if (_selectedFilter != null) {
                    filteredReminders = filteredReminders
                        .where((r) => r.category == _selectedFilter)
                        .toList();
                  }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                      );
                    }
                    if (snapshot.hasError) {
                    final error = snapshot.error.toString();
                    final isNetworkError = error.contains('network') ||
                        error.contains('timeout') ||
                        error.contains('unreachable') ||
                        error.contains('connection');
                    
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isNetworkError
                                ? Icons.wifi_off_rounded
                                : Icons.error_outline_rounded,
                            size: 64,
                            color: const Color(0xFF7B7C8D),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isNetworkError
                                ? 'Bağlantı Hatası'
                                : 'Veri Yükleme Hatası',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isNetworkError
                                ? 'İnternet bağlantınızı kontrol edin veya Firestore veritabanının oluşturulduğundan emin olun.'
                                : 'Veriler yüklenirken bir hata oluştu.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: const Color(0xFF7B7C8D),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              // StreamBuilder otomatik olarak yenilenecek
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const ReminderDashboard(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Yeniden Dene'),
                          ),
                        ],
                        ),
                      );
                    }
                  if (filteredReminders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: _EmptyReminders(isCaregiver: widget.isCaregiver),
                    );
                  }
                  return Column(
                    children: List.generate(
                      filteredReminders.length,
                      (index) {
                        final reminder = filteredReminders[index];
                        final bool isNext = index == 0;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < filteredReminders.length - 1 ? 12 : 24,
                          ),
                          child: _TimelineReminderTile(
                          reminder: reminder,
                          isNext: isNext,
                          isFirst: index == 0,
                            isLast: index == filteredReminders.length - 1,
                            isCaregiver: widget.isCaregiver,
                            onSpeak: () => _speakReminder(reminder),
                            onComplete: () => _handleComplete(reminder),
                            onEdit: () => _handleEdit(reminder),
                            onDelete: () => _handleDelete(reminder),
                          ),
                        );
                      },
                    ),
                    );
                  },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.isCaregiver
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddReminderPage(),
                  ),
                );
              },
        backgroundColor: const Color(0xFF4B7CFB),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Yeni hatırlatıcı',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
            )
          : null,
    );
  }
}

class _HeaderSection extends StatefulWidget {
  const _HeaderSection();

  @override
  State<_HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<_HeaderSection> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: const Color(0xFFEFF2FE),
              child: const Icon(Icons.person_rounded, size: 28, color: Color(0xFF4B7CFB)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba, Zeynep Hanım',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                'Bugün 3 ilaç ve 2 görev sizi bekliyor.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7B7C8D),
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            // Test bildirimi gönder
            try {
              await _notificationService.showTestNotification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test bildirimi gönderildi!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bildirim hatası: $e'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.notifications_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 2,
            shadowColor: Colors.black12,
          ),
          tooltip: 'Test bildirimi',
        ),
        const SizedBox(width: 8),
        Builder(
          builder: (context) => IconButton(
            onPressed: () {
              print('Ayarlar butonuna tıklandı');
              Navigator.of(context, rootNavigator: false).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsPage(),
                ),
              ).then((_) {
                print('Profil sayfasından dönüldü');
              }).catchError((error) {
                print('Navigator hatası: $error');
              });
            },
            icon: const Icon(Icons.settings_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black12,
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4B7CFB),
            Color(0xFF6ED1F8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B7CFB).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bugünkü Plan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TodayStat(
                  label: 'İlaç',
                  value: '3/4',
                  icon: Icons.medication_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TodayStat(
                  label: 'Görev',
                  value: '2/3',
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TodayStat(
                  label: 'Randevu',
                  value: '1',
                  icon: Icons.calendar_today_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.alarm_rounded,
                    color: Color(0xFF4B7CFB),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sıradaki hatırlatma',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                      ),
                      Text(
                        'D Vitamini Kapsülü',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '11:30',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  const _TodayStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final ReminderCategory? selectedFilter;
  final ValueChanged<ReminderCategory?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('Tümü', Icons.inbox_rounded, null),
      ('İlaç', Icons.medication_liquid_rounded, ReminderCategory.medication),
      ('Görev', Icons.checklist_rounded, ReminderCategory.activity),
      ('Randevu', Icons.event_available_rounded, ReminderCategory.appointment),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final category = filter.$3;
          final isSelected = selectedFilter == category;
          return FilterChip(
            selected: isSelected,
            onSelected: (_) {
              onFilterChanged(category);
            },
            avatar: Icon(
              filter.$2,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF7B7C8D),
            ),
            label: Text(filter.$1),
            showCheckmark: false,
            selectedColor: const Color(0xFF4B7CFB),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF7B7C8D),
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide.none,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: filters.length,
      ),
    );
  }
}

class _TimelineReminderTile extends StatelessWidget {
  const _TimelineReminderTile({
    required this.reminder,
    required this.isNext,
    required this.isFirst,
    required this.isLast,
    required this.isCaregiver,
    required this.onSpeak,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final Reminder reminder;
  final bool isNext;
  final bool isFirst;
  final bool isLast;
  final bool isCaregiver;
  final VoidCallback onSpeak;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final categoryColor = reminder.categoryColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                height: 16,
                width: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: categoryColor,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 2,
                  height: 80,
                  color: const Color(0xFFE1E2EC),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: isNext
                  ? Border.all(color: categoryColor.withOpacity(0.4), width: 1)
                  : null,
            ),
            child: Opacity(
              opacity: reminder.isCompleted ? 0.6 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          reminder.icon,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reminder.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          decoration: reminder.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                  ),
                                ),
                                if (reminder.isCompleted)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF4BBE9E),
                                    size: 20,
                                  ),
                              ],
                            ),
                            Text(
                              reminder.subtitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF7B7C8D),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reminder.timeLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F1F28),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reminder.note,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF4F5063),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (reminder.dosage.isNotEmpty) ...[
                        _TagChip(text: reminder.dosage),
                        const SizedBox(width: 8),
                      ],
                      if (reminder.location.isNotEmpty) ...[
                        _TagChip(text: reminder.location),
                        const SizedBox(width: 8),
                      ],
                      if (reminder.repeatType != ReminderRepeatType.none)
                        _TagChip(
                          text: reminder.repeatType == ReminderRepeatType.daily
                              ? 'Günlük'
                              : 'Haftalık',
                          color: categoryColor,
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: onSpeak,
                        icon: const Icon(Icons.volume_up_rounded),
                        tooltip: 'Sesli oku',
                      ),
                      if (isCaregiver) ...[
                        if (!reminder.isCompleted && isNext)
                          FilledButton.tonalIcon(
                            onPressed: onComplete,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Tamamla'),
                            style: FilledButton.styleFrom(
                              backgroundColor: categoryColor.withOpacity(0.15),
                              foregroundColor: categoryColor,
                            ),
                          ),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert_rounded),
                          itemBuilder: (context) => [
                            if (!reminder.isCompleted)
                              PopupMenuItem(
                                onTap: () => Future.delayed(
                                  const Duration(milliseconds: 100),
                                  onEdit,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text('Düzenle'),
                                  ],
                                ),
                              ),
                            if (reminder.isCompleted)
                              PopupMenuItem(
                                onTap: () => Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () async {
                                    // Tamamlanmayı geri al
                                    if (reminder.id != null) {
                                      await ReminderService()
                                          .completeReminder(reminder.id!, complete: false);
                                    }
                                  },
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.undo_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text('Geri Al'),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              onTap: () => Future.delayed(
                                const Duration(milliseconds: 100),
                                onDelete,
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.delete_rounded,
                                      size: 20, color: Color(0xFFFB7C7C)),
                                  SizedBox(width: 8),
                                  Text('Sil',
                                      style: TextStyle(color: Color(0xFFFB7C7C))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.text,
    this.color,
  });

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color?.withOpacity(0.1) ?? const Color(0xFFF1F2F8);
    final textColor = color ?? const Color(0xFF5D5E73);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders({required this.isCaregiver});

  final bool isCaregiver;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FE),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: Color(0xFF4B7CFB),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bugün için hatırlatıcı yok',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isCaregiver
                ? 'Sağ alttaki butondan yeni hatırlatıcı ekleyebilirsin.'
                : 'Yakınların tarafından eklenen hatırlatıcılar burada görünecek.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7B7C8D),
                ),
          ),
        ],
      ),
    );
  }
}

