import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'locations';
  
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  /// Mevcut konumu al
  Position? get currentPosition => _currentPosition;

  /// Konum takibi aktif mi?
  bool get isTracking => _isTracking;

  /// Konum izinlerini kontrol et ve iste
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Konum servisleri kapalı. Lütfen ayarlardan açın.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Konum izni reddedildi.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan manuel olarak açın.'
      );
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Mevcut konumu bir kez al
  Future<Position> getCurrentLocation() async {
    await checkAndRequestPermissions();

    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return _currentPosition!;
  }

  /// Konum takibini başlat
  Future<void> startTracking({
    required double safeZoneLatitude,
    required double safeZoneLongitude,
    required double safeZoneRadius,
    Function(Position)? onLocationUpdate,
    Function()? onLeftSafeZone,
  }) async {
    if (_isTracking) {
      print('⚠️ Konum takibi zaten aktif');
      return;
    }

    await checkAndRequestPermissions();

    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10 metre değişiklikte güncelle
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentPosition = position;
        
        // Firestore'a kaydet
        _saveLocationToFirestore(position);
        
        // Callback çağır
        onLocationUpdate?.call(position);
        
        // Güvenli bölge kontrolü
        final distance = Geolocator.distanceBetween(
          safeZoneLatitude,
          safeZoneLongitude,
          position.latitude,
          position.longitude,
        );

        if (distance > safeZoneRadius) {
          onLeftSafeZone?.call();
        }
      },
      onError: (error) {
        print('❌ Konum takibi hatası: $error');
      },
    );
  }

  /// Konum takibini durdur
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
  }

  /// Konumu Firestore'a kaydet
  Future<void> _saveLocationToFirestore(Position position) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection(_collection).add({
        'userId': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Firestore konum kaydetme hatası: $e');
    }
  }

  /// Kullanıcının konum geçmişini getir
  Stream<List<Map<String, dynamic>>> getLocationHistory({int limit = 50, String? userId}) {
    final targetUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (targetUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: targetUserId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                ...data,
              };
            })
            .toList());
  }

  /// Belirli bir kullanıcının son konumunu getir (real-time)
  Stream<Map<String, dynamic>?> getLatestLocation(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        });
  }

  /// İki nokta arasındaki mesafeyi hesapla (metre)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Konum servislerinin açık olup olmadığını kontrol et
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Ayarlar sayfasına yönlendir (Android için)
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Uygulama ayarlarına yönlendir (iOS için)
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Güvenli bölge bilgilerini Firestore'dan getir
  Future<Map<String, dynamic>?> getSafeZone({String? userId}) async {
    try {
      final targetUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (targetUserId == null) return null;

      final doc = await _firestore
          .collection('safe_zones')
          .doc(targetUserId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Güvenli bölge getirme hatası: $e');
      return null;
    }
  }

  /// Güvenli bölge bilgilerini Firestore'a kaydet
  Future<void> saveSafeZone({
    required double latitude,
    required double longitude,
    required double radius,
    String? userId,
  }) async {
    try {
      final targetUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (targetUserId == null) return;

      await _firestore.collection('safe_zones').doc(targetUserId).set({
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Güvenli bölge kaydetme hatası: $e');
      rethrow;
    }
  }

  /// Güvenli bölge bilgilerini Firestore'dan sil
  Future<void> deleteSafeZone({String? userId}) async {
    try {
      final targetUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (targetUserId == null) return;

      await _firestore.collection('safe_zones').doc(targetUserId).delete();
    } catch (e) {
      print('❌ Güvenli bölge silme hatası: $e');
      rethrow;
    }
  }

  void dispose() {
    stopTracking();
  }
}
