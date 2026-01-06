import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/album/album_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/emergency/emergency_page.dart';
import 'screens/home_guide/home_guide_page.dart';
import 'screens/reminders/reminder_dashboard.dart';
import 'screens/safe_zone/safe_zone_page.dart';
import 'screens/profile/profile_settings_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'models/app_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Bildirim servisini başlat
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  
  // FCM servisini başlat
  final fcmService = FcmService();
  await fcmService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Demans Asistanı',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F5FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B7CFB),
          brightness: Brightness.light,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'SF Pro Display',
          bodyColor: const Color(0xFF1F1F28),
          displayColor: const Color(0xFF1F1F28),
        ),
      ),
      home: const AuthShell(),
    );
  }
}

class AuthShell extends StatefulWidget {
  const AuthShell({super.key});

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return _RoleBasedHome(userId: snapshot.data!.uid);
        }

        return LoginPage(
          onLogin: () {
            // StreamBuilder otomatik olarak yönlendireceği için
            // burada manuel bir şey yapmamıza gerek kalmayabilir
            // ama LoginPage'in callback yapısını koruyabiliriz.
          },
        );
      },
    );
  }
}

// Kullanıcı verisi yüklenirken gösterilecek widget
class _UserDataLoader extends StatefulWidget {
  const _UserDataLoader({
    required this.userId,
    required this.userEmail,
    required this.userName,
  });

  final String userId;
  final String userEmail;
  final String userName;

  @override
  State<_UserDataLoader> createState() => _UserDataLoaderState();
}

class _UserDataLoaderState extends State<_UserDataLoader> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _trySaveUser();
  }

  Future<void> _trySaveUser() async {
    try {
      // Varsayılan olarak hasta rolü ver
      final appUser = AppUser(
        uid: widget.userId,
        name: widget.userName,
        email: widget.userEmail,
        role: UserRole.patient,
      );

      await UserService().saveUser(appUser);
      
      if (mounted) {
        // Başarılı, widget yenilenecek ve kullanıcı bilgisi görünecek
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Kullanıcı bilgileri kaydediliyor...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7B7C8D),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Color(0xFF7B7C8D),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kullanıcı Bilgisi Kaydedilemedi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Firestore veritabanının oluşturulduğundan ve güvenlik kurallarının ayarlandığından emin olun.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF7B7C8D),
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        await AuthService().signOut();
                      },
                      child: const Text('Çıkış Yap'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        // Hata olsa bile devam et (test için)
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => _RoleBasedHome(userId: widget.userId),
                          ),
                        );
                      },
                      child: const Text('Devam Et'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Başarılı, kullanıcı bilgisi yüklendi, normal akışa dön
    return _RoleBasedHome(userId: widget.userId);
  }
}

// Kullanıcı rolüne göre farklı HomeShell göster
class _RoleBasedHome extends StatelessWidget {
  const _RoleBasedHome({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: UserService().getUserStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Hata kontrolü
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          final isNetworkError = error.contains('network') ||
              error.contains('timeout') ||
              error.contains('unreachable') ||
              error.contains('connection') ||
              error.contains('PERMISSION_DENIED') ||
              error.contains('NOT_FOUND');

          return Scaffold(
            body: Center(
              child: Padding(
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
                          ? 'Firestore Bağlantı Hatası'
                          : 'Kullanıcı Bilgisi Hatası',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isNetworkError
                          ? 'Firestore veritabanının oluşturulduğundan ve güvenlik kurallarının ayarlandığından emin olun.'
                          : 'Kullanıcı bilgileri yüklenemedi. Lütfen tekrar giriş yapın.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF7B7C8D),
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        // Sayfayı yenile
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const AuthShell(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Yeniden Dene'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final user = snapshot.data;
        final currentAuthUser = AuthService().currentUser;
        
        // Kullanıcı yoksa ama Authentication'da kullanıcı varsa, Firestore'a kaydetmeyi dene
        if (user == null && currentAuthUser != null) {
          return _UserDataLoader(
            userId: userId,
            userEmail: currentAuthUser.email ?? '',
            userName: currentAuthUser.displayName ?? 'Kullanıcı',
          );
        }
        
        // Kullanıcı yoksa ve Authentication'da da yoksa
        if (user == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 64,
                      color: Color(0xFF7B7C8D),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kullanıcı Bilgisi Bulunamadı',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lütfen çıkış yapıp tekrar kayıt olun.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        await AuthService().signOut();
                        // AuthShell otomatik olarak login sayfasına yönlendirecek
                      },
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Hasta yakını ise tam özellikli arayüz
        if (user.role == UserRole.caregiver) {
          return const CaregiverHomeShell();
        }

        // Hasta ise basit bildirim arayüzü
        return const PatientHomeShell();
      },
    );
  }
}

// Hasta Yakını Arayüzü (Tam Özellikli)
class CaregiverHomeShell extends StatefulWidget {
  const CaregiverHomeShell({super.key});

  @override
  State<CaregiverHomeShell> createState() => _CaregiverHomeShellState();
}

class _CaregiverHomeShellState extends State<CaregiverHomeShell> {
  int _index = 0;

  static final _pages = [
    const ReminderDashboard(),
    const SafeZonePage(),
    const AlbumPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsPage(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService().signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Çıkış Yap'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        height: 82,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'Hatırlatıcılar',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded),
            label: 'Konum Takibi',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library_rounded),
            label: 'Kişi Albümü',
          ),
        ],
      ),
    );
  }
}

// Hasta Arayüzü (Basit Bildirim Görünümü)
class PatientHomeShell extends StatefulWidget {
  const PatientHomeShell({super.key});

  @override
  State<PatientHomeShell> createState() => _PatientHomeShellState();
}

class _PatientHomeShellState extends State<PatientHomeShell> {
  int _index = 0;

  static final _pages = [
    const ReminderDashboard(), // Sadece görüntüleme için
    const AlbumPage(), // Sadece görüntüleme için
    const HomeGuidePage(),
    const EmergencyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService().signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Çıkış Yap'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        height: 82,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Hatırlatıcılar',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library_rounded),
            label: 'Kişiler',
          ),
          NavigationDestination(
            icon: Icon(Icons.assistant_direction_outlined),
            selectedIcon: Icon(Icons.assistant_direction_rounded),
            label: 'Eve Dön',
          ),
          NavigationDestination(
            icon: Icon(Icons.emergency_outlined),
            selectedIcon: Icon(Icons.emergency_rounded),
            label: 'Acil',
          ),
        ],
      ),
    );
  }
}
