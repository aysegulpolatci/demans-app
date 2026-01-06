import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Kullanıcı durumu değişikliğini dinlemek için stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Giriş yap
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Kayıt ol (rol ve isim ile)
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? patientId, // Hasta yakını ise, bağlı olduğu hasta ID'si
  }) async {
    // Önce Authentication ile kullanıcı oluştur
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Kullanıcı bilgilerini Firestore'a kaydet (hataya rağmen devam et)
    try {
      final appUser = AppUser(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        role: role,
        patientId: patientId,
      );

      await _userService.saveUser(appUser);
    } catch (firestoreError) {
      // Firestore hatası olsa bile Authentication başarılı
      // Kullanıcı giriş yapmış sayılır, Firestore'a sonra yazılabilir
      print('Firestore kayıt hatası (kullanıcı yine de giriş yaptı): $firestoreError');
      // Hata mesajını throw et ki kullanıcı bilgilendirilsin
      // Ama userCredential'ı döndür ki kullanıcı giriş yapmış olsun
      throw Exception(
        'Hesap oluşturuldu ve giriş yaptınız, ancak kullanıcı bilgileri kaydedilemedi. '
        'Lütfen Firestore veritabanının oluşturulduğundan ve güvenlik kurallarının ayarlandığından emin olun. '
        'Uygulamayı kapatıp tekrar açtığınızda bilgileriniz kaydedilecektir.'
      );
    }

    return userCredential;
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

