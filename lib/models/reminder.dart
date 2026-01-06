import 'package:flutter/material.dart';

class Reminder {
  const Reminder({
    this.id,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.note,
    required this.dosage,
    required this.location,
    required this.category,
    this.isCompleted = false,
    this.completedAt,
    this.repeatType = ReminderRepeatType.none,
    this.nextRepeatDate,
  });

  final String? id;
  final String title;
  final String subtitle;
  final String timeLabel;
  final String note;
  final String dosage;
  final String location;
  final ReminderCategory category;
  final bool isCompleted;
  final DateTime? completedAt;
  final ReminderRepeatType repeatType;
  final DateTime? nextRepeatDate;

  factory Reminder.fromFirestore(Map<String, dynamic> data, {String? id}) {
    final categoryStr = (data['category'] as String?) ?? 'medication';
    final category = ReminderCategory.values.firstWhere(
      (c) => c.name == categoryStr,
      orElse: () => ReminderCategory.medication,
    );

    final repeatTypeStr = (data['repeatType'] as String?) ?? 'none';
    final repeatType = ReminderRepeatType.values.firstWhere(
      (r) => r.name == repeatTypeStr,
      orElse: () => ReminderRepeatType.none,
    );

    return Reminder(
      id: id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      timeLabel: data['timeLabel'] as String? ?? '',
      note: data['note'] as String? ?? '',
      dosage: data['dosage'] as String? ?? '',
      location: data['location'] as String? ?? '',
      category: category,
      isCompleted: data['isCompleted'] as bool? ?? false,
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'] as String)
          : null,
      repeatType: repeatType,
      nextRepeatDate: data['nextRepeatDate'] != null
          ? DateTime.parse(data['nextRepeatDate'] as String)
          : null,
    );
  }

  IconData get icon {
    switch (category) {
      case ReminderCategory.medication:
        return Icons.vaccines_rounded;
      case ReminderCategory.appointment:
        return Icons.local_hospital_rounded;
      case ReminderCategory.activity:
        return Icons.favorite_rounded;
    }
  }

  Color get categoryColor {
    switch (category) {
      case ReminderCategory.medication:
        return const Color(0xFF6C6EF5);
      case ReminderCategory.appointment:
        return const Color(0xFFFB7C7C);
      case ReminderCategory.activity:
        return const Color(0xFF4BBE9E);
    }
  }

  // Firestore'a kaydetmek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'timeLabel': timeLabel,
      'note': note,
      'dosage': dosage,
      'location': location,
      'category': category.name,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'repeatType': repeatType.name,
      'nextRepeatDate': nextRepeatDate?.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'userId': null, // Daha sonra kullanıcı ID'si eklenebilir
    };
  }

  // Tamamlanmış kopya oluştur
  Reminder copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? timeLabel,
    String? note,
    String? dosage,
    String? location,
    ReminderCategory? category,
    bool? isCompleted,
    DateTime? completedAt,
    ReminderRepeatType? repeatType,
    DateTime? nextRepeatDate,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      timeLabel: timeLabel ?? this.timeLabel,
      note: note ?? this.note,
      dosage: dosage ?? this.dosage,
      location: location ?? this.location,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      repeatType: repeatType ?? this.repeatType,
      nextRepeatDate: nextRepeatDate ?? this.nextRepeatDate,
    );
  }
}

enum ReminderCategory { medication, appointment, activity }

enum ReminderRepeatType { none, daily, weekly }

const mockReminders = <Reminder>[
  Reminder(
    title: 'D Vitamini',
    subtitle: 'Sabah ilacı',
    timeLabel: '11:30',
    note: 'Kahvaltıdan sonra bir bardak su ile alın.',
    dosage: '1 kapsül',
    location: 'Mutfak çekmecesi',
    category: ReminderCategory.medication,
  ),
  Reminder(
    title: 'Fizyoterapi seansı',
    subtitle: 'Dr. Yıldız',
    timeLabel: '14:00',
    note: 'Girişte refakatçi kartını göstermeyi unutmayın.',
    dosage: '30 dk',
    location: 'Medikal Park',
    category: ReminderCategory.appointment,
  ),
  Reminder(
    title: 'Hafıza egzersizi',
    subtitle: 'Mobil uygulama',
    timeLabel: '16:00',
    note: 'Bulmaca serisinin 3. bölümünü tamamlayın.',
    dosage: '15 dk',
    location: 'Salon koltuğu',
    category: ReminderCategory.activity,
  ),
  Reminder(
    title: 'Akşam ilaçları',
    subtitle: 'Donepezil',
    timeLabel: '20:30',
    note: 'Yemekten sonra yarım saat içerisinde alın.',
    dosage: '1 tablet',
    location: 'Yatak odası komodini',
    category: ReminderCategory.medication,
  ),
];

