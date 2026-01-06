import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryContact {
  const MemoryContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.description,
    required this.imageUrl,
    required this.lastSeen,
    required this.ttsScript,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String relationship;
  final String description;
  final String imageUrl;
  final DateTime lastSeen;
  final String ttsScript;
  final bool isFavorite;

  String get lastSeenLabel => '${lastSeen.day}.${lastSeen.month}.${lastSeen.year}';

  factory MemoryContact.fromFirestore(Map<String, dynamic> data, String id) {
    return MemoryContact(
      id: id,
      name: data['name'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      lastSeen: data['lastSeen'] != null
          ? DateTime.parse(data['lastSeen'] as String)
          : DateTime.now(),
      ttsScript: data['ttsScript'] as String? ?? '',
      isFavorite: data['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'description': description,
      'imageUrl': imageUrl,
      'lastSeen': lastSeen.toIso8601String(),
      'ttsScript': ttsScript,
      'isFavorite': isFavorite,
    };
  }
}

final mockMemoryContacts = <MemoryContact>[
  MemoryContact(
    id: '1',
    name: 'Ayşe Korkmaz',
    relationship: 'Kızı',
    description: 'Her sabah kahve içip günün planını birlikte yapıyorsunuz.',
    imageUrl: 'assets/images/family/ayse.jpg',
    lastSeen: DateTime(2025, 11, 26),
    ttsScript:
        'Bu Ayşe, senin kızın. Her sabah kahve içip gününü birlikte planlıyorsunuz.',
    isFavorite: true,
  ),
  MemoryContact(
    id: '2',
    name: 'Mehmet Korkmaz',
    relationship: 'Oğlu',
    description: 'Hafta sonları seni yürüyüşe çıkarıyor.',
    imageUrl: 'assets/images/family/mehmet.jpg',
    lastSeen: DateTime(2025, 11, 25),
    ttsScript:
        'Bu Mehmet, senin oğlun. Hafta sonları birlikte parkta yürüyüş yapıyorsunuz.',
    isFavorite: true,
  ),
  MemoryContact(
    id: '3',
    name: 'Elif Demir',
    relationship: 'Torunu',
    description: 'Okul projelerini büyükannesine ilk o gösteriyor.',
    imageUrl: 'assets/images/family/elif.jpg',
    lastSeen: DateTime(2025, 11, 20),
    ttsScript: 'Bu Elif, torunun. Her yeni projesini sana ilk o gösteriyor.',
  ),
  MemoryContact(
    id: '4',
    name: 'Kemal Demir',
    relationship: 'Eşi',
    description: 'Akşamları birlikte eski fotoğraflara bakmayı seviyorsunuz.',
    imageUrl: 'assets/images/family/kemal.jpg',
    lastSeen: DateTime(2025, 11, 24),
    ttsScript:
        'Bu Kemal, 40 yıllık hayat arkadaşın. Akşamları birlikte fotoğraflara bakıyorsunuz.',
  ),
  MemoryContact(
    id: '5',
    name: 'Dr. Selin Yıldız',
    relationship: 'Aile hekimi',
    description: 'Her ay düzenli kontrol için seni arıyor.',
    imageUrl: 'assets/images/family/selin.jpg',
    lastSeen: DateTime(2025, 11, 15),
    ttsScript:
        'Bu Selin doktorun. Sağlığını takip etmek için her ay seni arıyor.',
  ),
];

