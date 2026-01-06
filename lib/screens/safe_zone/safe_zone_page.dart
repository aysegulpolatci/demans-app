import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/location_event.dart';
import '../../models/app_user.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class SafeZonePage extends StatelessWidget {
  const SafeZonePage({super.key});

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

        return _SafeZonePageContent(
          isCaregiver: isCaregiver,
          patientId: user?.patientId,
        );
      },
    );
  }
}

class _SafeZonePageContent extends StatefulWidget {
  const _SafeZonePageContent({
    required this.isCaregiver,
    this.patientId,
  });

  final bool isCaregiver;
  final String? patientId;

  @override
  State<_SafeZonePageContent> createState() => _SafeZonePageContentState();
}

class _SafeZonePageContentState extends State<_SafeZonePageContent> {
  final LocationService _locationService = LocationService();
  double _radius = 250;
  bool _alertsEnabled = true;
  bool _isLoading = false;
  bool _isTracking = false;
  Position? _currentPosition; // Hasta yakını için: hasta konumu, Hasta için: kendi konumu
  Position? _safeZoneCenter;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isCaregiver) {
      // Hasta yakını: Güvenli bölge ayarlarını yükle ve hasta konumunu dinle
      _loadSafeZone();
      _startPatientLocationTracking();
    } else {
      // Hasta: Kendi konumunu al ve otomatik takibi başlat
      _loadCurrentLocation();
      _startOwnLocationTracking();
    }
  }

  /// Hasta için: Kendi konum takibini başlat
  Future<void> _startOwnLocationTracking() async {
    if (widget.isCaregiver) return;

    try {
      // Önce mevcut konumu al
      final position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }

      // Sürekli konum takibini başlat
      await _locationService.startTracking(
        safeZoneLatitude: 0, // Hasta için güvenli bölge kontrolü yok
        safeZoneLongitude: 0,
        safeZoneRadius: 0,
        onLocationUpdate: (position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });
          }
        },
        onLeftSafeZone: () {}, // Hasta için bu callback kullanılmaz
      );
      
      if (mounted) {
        setState(() {
          _isTracking = true;
        });
      }
    } catch (e) {
      print('Hasta konum takibi başlatma hatası: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Hasta yakını için: Güvenli bölge ayarlarını yükle
  Future<void> _loadSafeZone() async {
    if (!widget.isCaregiver) return;
    
    try {
      // Hasta yakını için hasta ID'si ile güvenli bölge yükle
      final safeZone = await _locationService.getSafeZone(userId: widget.patientId);
      if (safeZone != null && mounted) {
        setState(() {
          _radius = (safeZone['radius'] as num?)?.toDouble() ?? 250;
          if (safeZone['latitude'] != null && safeZone['longitude'] != null) {
            _safeZoneCenter = Position(
              latitude: safeZone['latitude'] as double,
              longitude: safeZone['longitude'] as double,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          }
        });
      } else if (widget.patientId != null && mounted) {
        // Güvenli bölge yoksa, hasta konumunu al ve güvenli bölge merkezi yap
        _locationService.getLatestLocation(widget.patientId!).listen((locationData) {
          if (locationData != null && _safeZoneCenter == null && mounted) {
            final lat = locationData['latitude'] as double?;
            final lon = locationData['longitude'] as double?;
            if (lat != null && lon != null) {
              setState(() {
                _safeZoneCenter = Position(
                  latitude: lat,
                  longitude: lon,
                  timestamp: DateTime.now(),
                  accuracy: 0,
                  altitude: 0,
                  altitudeAccuracy: 0,
                  heading: 0,
                  headingAccuracy: 0,
                  speed: 0,
                  speedAccuracy: 0,
                );
                _saveSafeZone();
              });
            }
          }
        });
      }
    } catch (e) {
      print('Güvenli bölge yükleme hatası: $e');
    }
  }

  /// Hasta yakını için: Hasta konumunu real-time dinle
  void _startPatientLocationTracking() {
    if (!widget.isCaregiver || widget.patientId == null) return;

    // Hasta konumunu real-time dinle
    _locationService.getLatestLocation(widget.patientId!).listen((locationData) {
      if (locationData != null && mounted) {
        final lat = locationData['latitude'] as double?;
        final lon = locationData['longitude'] as double?;
        if (lat != null && lon != null) {
          setState(() {
            _currentPosition = Position(
              latitude: lat,
              longitude: lon,
              timestamp: (locationData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              accuracy: (locationData['accuracy'] as num?)?.toDouble() ?? 0,
              altitude: (locationData['altitude'] as num?)?.toDouble() ?? 0,
              altitudeAccuracy: 0,
              heading: (locationData['heading'] as num?)?.toDouble() ?? 0,
              headingAccuracy: 0,
              speed: (locationData['speed'] as num?)?.toDouble() ?? 0,
              speedAccuracy: 0,
            );

            // Güvenli bölge kontrolü
            if (_safeZoneCenter != null && _alertsEnabled) {
              final distance = _locationService.calculateDistance(
                _safeZoneCenter!.latitude,
                _safeZoneCenter!.longitude,
                lat,
                lon,
              );

              if (distance > _radius) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Hasta güvenli bölge dışına çıktı!'),
                    backgroundColor: Color(0xFFFB7C7C),
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            }
          });
        }
      }
    });
  }

  /// Hasta için: Kendi konumunu al
  Future<void> _loadCurrentLocation() async {
    if (widget.isCaregiver) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Hasta yakını için: Güvenli bölge kaydet (hasta ID'si ile)
  Future<void> _saveSafeZone() async {
    if (!widget.isCaregiver || _safeZoneCenter == null || widget.patientId == null) return;

    try {
      await _locationService.saveSafeZone(
        latitude: _safeZoneCenter!.latitude,
        longitude: _safeZoneCenter!.longitude,
        radius: _radius,
        userId: widget.patientId, // Hasta ID'si ile kaydet
      );
    } catch (e) {
      print('Güvenli bölge kayıt hatası: $e');
    }
  }

  /// Hasta yakını için: Konum takibini başlat/durdur (hasta için değil)
  Future<void> _toggleTracking() async {
    if (!widget.isCaregiver) return; // Hasta için bu buton görünmez

    if (_safeZoneCenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce güvenli bölge merkezini ayarlayın'),
        ),
      );
      return;
    }

    if (_isTracking) {
      _locationService.stopTracking();
      setState(() {
        _isTracking = false;
      });
    } else {
      try {
        // Hasta yakını için hasta konumunu takip et
        if (widget.patientId != null) {
          await _locationService.startTracking(
            safeZoneLatitude: _safeZoneCenter!.latitude,
            safeZoneLongitude: _safeZoneCenter!.longitude,
            safeZoneRadius: _radius,
            onLocationUpdate: (position) {
              // Bu callback hasta yakını için kullanılmaz, hasta konumu zaten stream'den geliyor
            },
            onLeftSafeZone: () {
              if (mounted && _alertsEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Hasta güvenli bölge dışına çıktı!'),
                    backgroundColor: Color(0xFFFB7C7C),
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            },
          );
        }
        setState(() {
          _isTracking = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Konum takibi başlatılamadı: ${e.toString().replaceAll('Exception: ', '')}'),
            ),
          );
        }
      }
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
              _SafeHeader(
                radius: _radius,
                alertsEnabled: _alertsEnabled,
                isTracking: _isTracking,
                onToggleTracking: widget.isCaregiver ? _toggleTracking : null,
                isCaregiver: widget.isCaregiver,
                currentPosition: _currentPosition,
              ),
              const SizedBox(height: 20),
              // Hasta yakını için daha büyük harita
              _LiveMap(
                radius: _radius,
                currentPosition: _currentPosition,
                safeZoneCenter: _safeZoneCenter,
                isCaregiver: widget.isCaregiver,
                onSetSafeZoneCenter: widget.isCaregiver
                    ? (position) {
                        setState(() {
                          _safeZoneCenter = position;
                        });
                        _saveSafeZone();
                      }
                    : null,
                mapHeight: widget.isCaregiver ? 400 : 320,
              ),
              // Hasta yakını için anlık konum bilgisi kartı
              if (widget.isCaregiver && _currentPosition != null) ...[
                const SizedBox(height: 20),
                _LiveLocationCard(position: _currentPosition!),
              ],
              if (widget.isCaregiver) ...[
                // Güvenli bölge oluştur/güncelle butonu
                if (_safeZoneCenter == null && _currentPosition != null) ...[
                  const SizedBox(height: 20),
                  _CreateSafeZoneButton(
                    onPressed: () {
                      setState(() {
                        _safeZoneCenter = _currentPosition;
                      });
                      _saveSafeZone();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Güvenli bölge oluşturuldu'),
                          backgroundColor: Color(0xFF4BBE9E),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ] else if (_safeZoneCenter != null) ...[
                  const SizedBox(height: 20),
                  _UpdateSafeZoneButton(
                    onUpdateFromCurrent: _currentPosition != null
                        ? () {
                            setState(() {
                              _safeZoneCenter = _currentPosition;
                            });
                            _saveSafeZone();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Güvenli bölge merkezi güncellendi'),
                                backgroundColor: Color(0xFF4BBE9E),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : null,
                    onClear: () async {
                      if (widget.patientId != null) {
                        try {
                          await _locationService.deleteSafeZone(userId: widget.patientId);
                        } catch (e) {
                          print('Güvenli bölge silme hatası: $e');
                        }
                      }
                      setState(() {
                        _safeZoneCenter = null;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Güvenli bölge kaldırıldı'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
                const SizedBox(height: 24),
                _RadiusControl(
                  radius: _radius,
                  onChanged: (value) {
                    setState(() => _radius = value);
                    _saveSafeZone();
                  },
                ),
                const SizedBox(height: 16),
                _AlertToggle(
                  enabled: _alertsEnabled,
                  onChanged: (value) => setState(() => _alertsEnabled = value),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isCaregiver ? 'Hasta konum geçmişi' : 'Konum geçmişi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFB7C7C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFB7C7C).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFFB7C7C),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFB7C7C)),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadCurrentLocation,
                        child: const Text('Yeniden Dene'),
                      ),
                    ],
                  ),
                )
              else
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: widget.isCaregiver && widget.patientId != null
                      ? _locationService.getLocationHistory(userId: widget.patientId)
                      : _locationService.getLocationHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final locationData = snapshot.data ?? [];
                    if (locationData.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.location_off_rounded,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Henüz konum verisi yok',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: List.generate(
                        locationData.length,
                        (index) {
                          final data = locationData[index];
                          final timestamp = data['timestamp'] as Timestamp?;
                          final lat = data['latitude'] as double?;
                          final lon = data['longitude'] as double?;
                          
                          // Mesafe hesapla (eğer güvenli bölge merkezi varsa)
                          String? distanceLabel;
                          if (_safeZoneCenter != null && lat != null && lon != null) {
                            final distance = _locationService.calculateDistance(
                              _safeZoneCenter!.latitude,
                              _safeZoneCenter!.longitude,
                              lat,
                              lon,
                            );
                            distanceLabel = '${distance.toStringAsFixed(0)} m';
                          }
                          
                          final event = LocationEvent(
                            title: 'Konum güncellendi',
                            subtitle: lat != null && lon != null
                                ? '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}'
                                : 'Konum bilgisi yok',
                            timeLabel: timestamp != null
                                ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                : '--:--',
                            distanceLabel: distanceLabel,
                            type: index == 0 ? EventType.update : EventType.info,
                          );
                          
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < locationData.length - 1 ? 12 : 24,
                            ),
                            child: _LocationEventTile(event: event),
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
              onPressed: () {},
              backgroundColor: const Color(0xFFFB7C7C),
              icon: const Icon(Icons.sos_rounded, color: Colors.white),
              label: const Text(
                'Acil durum gönder',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }
}

class _SafeHeader extends StatelessWidget {
  const _SafeHeader({
    required this.radius,
    required this.alertsEnabled,
    this.isTracking,
    this.onToggleTracking,
    required this.isCaregiver,
    this.currentPosition,
  });

  final double radius;
  final bool alertsEnabled;
  final bool? isTracking;
  final VoidCallback? onToggleTracking;
  final bool isCaregiver;
  final Position? currentPosition;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCaregiver ? 'Hasta Konumu' : 'Konumum',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF7B7C8D),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: currentPosition != null
                          ? const Color(0xFF4BBE9E)
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentPosition != null
                        ? 'Sinyal güçlü'
                        : 'Konum bekleniyor',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (isCaregiver)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Güvenli alan yarıçapı',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF7B7C8D),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${radius.toStringAsFixed(0)} m',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        alertsEnabled
                            ? Icons.sensors_rounded
                            : Icons.notifications_off_rounded,
                        color: alertsEnabled
                            ? const Color(0xFF4B7CFB)
                            : const Color(0xFF7B7C8D),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        alertsEnabled ? 'Uyarılar aktif' : 'Uyarılar kapalı',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF7B7C8D),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          const Spacer(),
        if (isCaregiver && onToggleTracking != null) ...[
          const SizedBox(width: 16),
          IconButton(
            onPressed: onToggleTracking,
            icon: Icon(
              isTracking == true ? Icons.location_on_rounded : Icons.location_off_rounded,
              color: isTracking == true ? const Color(0xFF4BBE9E) : const Color(0xFF7B7C8D),
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 2,
            ),
            tooltip: isTracking == true ? 'Takibi durdur' : 'Takibi başlat',
          ),
        ],
      ],
    );
  }
}

class _LiveMap extends StatefulWidget {
  const _LiveMap({
    required this.radius,
    this.currentPosition,
    this.safeZoneCenter,
    required this.isCaregiver,
    this.onSetSafeZoneCenter,
    this.mapHeight = 320,
  });

  final double radius;
  final Position? currentPosition;
  final Position? safeZoneCenter;
  final bool isCaregiver;
  final ValueChanged<Position>? onSetSafeZoneCenter;
  final double mapHeight;

  @override
  State<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<_LiveMap> {
  GoogleMapController? _mapController;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateMap();
  }

  @override
  void didUpdateWidget(_LiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition != widget.currentPosition ||
        oldWidget.safeZoneCenter != widget.safeZoneCenter ||
        oldWidget.radius != widget.radius) {
      _updateMap();
    }
  }

  void _updateMap() {
    final circles = <Circle>{};
    final markers = <Marker>{};

    // Güvenli bölge çemberi
    if (widget.safeZoneCenter != null) {
      circles.add(
        Circle(
          circleId: const CircleId('safe_zone'),
          center: LatLng(
            widget.safeZoneCenter!.latitude,
            widget.safeZoneCenter!.longitude,
          ),
          radius: widget.radius,
          strokeColor: const Color(0xFF4B7CFB),
          strokeWidth: 3,
          fillColor: const Color(0xFF4B7CFB).withOpacity(0.15),
        ),
      );

      // Güvenli bölge merkezi marker
      markers.add(
        Marker(
          markerId: const MarkerId('safe_zone_center'),
          position: LatLng(
            widget.safeZoneCenter!.latitude,
            widget.safeZoneCenter!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Güvenli Bölge Merkezi',
          ),
        ),
      );
    }

    // Hasta/mevcut konum marker
    if (widget.currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.isCaregiver ? 'Hasta Konumu' : 'Mevcut Konum',
            snippet: '${widget.currentPosition!.latitude.toStringAsFixed(6)}, ${widget.currentPosition!.longitude.toStringAsFixed(6)}',
          ),
        ),
      );
    }

    setState(() {
      _circles = circles;
      _markers = markers;
    });

    // Haritayı güncelle
    if (_mapController != null && widget.currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          15.0,
        ),
      );
    }
  }

  LatLng _getInitialCameraPosition() {
    if (widget.currentPosition != null) {
      return LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
    }
    if (widget.safeZoneCenter != null) {
      return LatLng(
        widget.safeZoneCenter!.latitude,
        widget.safeZoneCenter!.longitude,
      );
    }
    // Varsayılan: İstanbul
    return const LatLng(41.0082, 28.9784);
  }

  void _goToMyLocation() {
    if (_mapController != null && widget.currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          16.0,
        ),
      );
    }
  }

  Future<void> _openNavigation() async {
    if (widget.currentPosition == null) return;

    final lat = widget.currentPosition!.latitude;
    final lon = widget.currentPosition!.longitude;
    
    // Google Maps ile navigasyon aç
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigasyon açılamadı'),
            backgroundColor: Color(0xFFFB7C7C),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: widget.mapHeight,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _getInitialCameraPosition(),
                zoom: widget.currentPosition != null ? 15.0 : 13.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _updateMap();
              },
              onTap: widget.isCaregiver && widget.onSetSafeZoneCenter != null
                  ? (LatLng position) {
                      final newPosition = Position(
                        latitude: position.latitude,
                        longitude: position.longitude,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        altitudeAccuracy: 0,
                        heading: 0,
                        headingAccuracy: 0,
                        speed: 0,
                        speedAccuracy: 0,
                      );
                      widget.onSetSafeZoneCenter!(newPosition);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Güvenli bölge merkezi güncellendi'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              circles: _circles,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              compassEnabled: true,
            ),
            // Harita üzerindeki butonlar
            Positioned(
              right: 16,
              top: 16,
              child: Column(
                children: [
                  if (widget.isCaregiver && widget.onSetSafeZoneCenter != null && widget.currentPosition != null) ...[
                    _MapActionButton(
                      icon: Icons.edit_location_alt_rounded,
                      onPressed: () {
                        widget.onSetSafeZoneCenter!(widget.currentPosition!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Güvenli bölge merkezi güncellendi'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Güvenli bölge merkezini hasta konumuna ayarla',
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MapActionButton(
                    icon: Icons.my_location_rounded,
                    onPressed: _goToMyLocation,
                    tooltip: 'Konumuma git',
                  ),
                  const SizedBox(height: 12),
                  if (widget.currentPosition != null)
                    _MapActionButton(
                      icon: Icons.navigation_rounded,
                      onPressed: _openNavigation,
                      tooltip: 'Navigasyon başlat',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.2),
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}

class _RadiusControl extends StatelessWidget {
  const _RadiusControl({
    required this.radius,
    required this.onChanged,
  });

  final double radius;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Güvenli bölge yarıçapı',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${radius.toStringAsFixed(0)} m',
                  style: const TextStyle(
                    color: Color(0xFF4B7CFB),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: radius,
            onChanged: onChanged,
            min: 100,
            max: 500,
            activeColor: const Color(0xFF4B7CFB),
            thumbColor: const Color(0xFF4B7CFB),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('100 m', style: TextStyle(color: Color(0xFF7B7C8D))),
              Text('500 m', style: TextStyle(color: Color(0xFF7B7C8D))),
            ],
          )
        ],
      ),
    );
  }
}

class _AlertToggle extends StatelessWidget {
  const _AlertToggle({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFB7C7C).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFFB7C7C),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bölge dışına çıkınca bildir',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Hasta güvenli alanı terk ettiğinde refakatçilere acil durum sinyali gider.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7B7C8D),
                      ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeColor: const Color(0xFF4B7CFB),
          ),
        ],
      ),
    );
  }
}

class _LocationEventTile extends StatelessWidget {
  const _LocationEventTile({required this.event});

  final LocationEvent event;

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
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: event.type == EventType.alert
            ? Border.all(color: const Color(0xFFFB7C7C).withOpacity(0.4))
            : null,
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: event.iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(event.icon, color: event.iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  event.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7B7C8D),
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                event.timeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF5F6074),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (event.distanceLabel != null)
                Text(
                  event.distanceLabel!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF4B7CFB),
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hasta yakını için anlık konum bilgisi kartı
class _LiveLocationCard extends StatelessWidget {
  const _LiveLocationCard({required this.position});

  final Position position;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4BBE9E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFF4BBE9E),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anlık Konum',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF7B7C8D),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Canlı takip aktif',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4BBE9E),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4BBE9E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 8,
                      width: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4BBE9E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Canlı',
                      style: TextStyle(
                        color: Color(0xFF4BBE9E),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LocationInfoItem(
                  label: 'Enlem',
                  value: position.latitude.toStringAsFixed(6),
                  icon: Icons.north_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LocationInfoItem(
                  label: 'Boylam',
                  value: position.longitude.toStringAsFixed(6),
                  icon: Icons.east_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LocationInfoItem(
                  label: 'Doğruluk',
                  value: '${position.accuracy.toStringAsFixed(0)} m',
                  icon: Icons.gps_fixed_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LocationInfoItem(
                  label: 'Hız',
                  value: position.speed > 0
                      ? '${(position.speed * 3.6).toStringAsFixed(1)} km/h'
                      : 'Durmakta',
                  icon: Icons.speed_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationInfoItem extends StatelessWidget {
  const _LocationInfoItem({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF7B7C8D)),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7B7C8D),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Güvenli bölge oluştur butonu
class _CreateSafeZoneButton extends StatelessWidget {
  const _CreateSafeZoneButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4BBE9E), Color(0xFF3A9B7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4BBE9E).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_location_alt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Güvenli Bölge Oluştur',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hastanın mevcut konumunu güvenli bölge merkezi yap',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Güvenli bölge güncelle butonu
class _UpdateSafeZoneButton extends StatelessWidget {
  const _UpdateSafeZoneButton({
    this.onUpdateFromCurrent,
    required this.onClear,
  });

  final VoidCallback? onUpdateFromCurrent;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onUpdateFromCurrent != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4BBE9E).withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onUpdateFromCurrent,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4BBE9E).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF4BBE9E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mevcut Konumu Merkez Yap',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Hastanın şu anki konumunu güvenli bölge merkezi olarak ayarla',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7B7C8D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF7B7C8D),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (onUpdateFromCurrent != null) const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFB7C7C).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB7C7C).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFFB7C7C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Güvenli Bölgeyi Kaldır',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Güvenli bölge ayarlarını sıfırla',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7B7C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF7B7C8D),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
