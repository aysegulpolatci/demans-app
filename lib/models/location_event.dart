import 'package:flutter/material.dart';

class LocationEvent {
  const LocationEvent({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    this.distanceLabel,
    this.type = EventType.info,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final String? distanceLabel;
  final EventType type;

  IconData get icon {
    switch (type) {
      case EventType.info:
        return Icons.location_searching_rounded;
      case EventType.update:
        return Icons.route_rounded;
      case EventType.alert:
        return Icons.error_outline_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case EventType.info:
        return const Color(0xFF4B7CFB);
      case EventType.update:
        return const Color(0xFF4BBE9E);
      case EventType.alert:
        return const Color(0xFFFB7C7C);
    }
  }
}

enum EventType { info, update, alert }

const mockLocationEvents = <LocationEvent>[
  LocationEvent(
    title: 'Konum güncellendi',
    subtitle: 'Ev – Oturma odası',
    timeLabel: 'Şimdi',
    distanceLabel: '+12 m',
    type: EventType.update,
  ),
  LocationEvent(
    title: 'Sınır noktasına yakın',
    subtitle: 'Bahçe çıkışı',
    timeLabel: '2 dk önce',
    distanceLabel: '35 m',
    type: EventType.alert,
  ),
  LocationEvent(
    title: 'Güvenli bölgede',
    subtitle: 'Ev – Mutfak',
    timeLabel: '10 dk önce',
    type: EventType.info,
  ),
];

