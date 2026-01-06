import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_user.dart';
import '../../models/patient_info.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/patient_info_service.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  AppUser? _currentUser;
  AppUser? _patientUser;

  // Hasta bilgileri için form controller'ları
  final _patientNameController = TextEditingController();
  final _patientEmailController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _patientAddressController = TextEditingController();
  final _patientBirthDateController = TextEditingController();
  final _patientNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    final user = await UserService().getUser(currentUser.uid);
    if (user != null) {
      setState(() {
        _currentUser = user;
        _nameController.text = user.name;
        _emailController.text = user.email;
      });

      // Eğer hasta yakını ise ve hasta ID'si varsa, hasta bilgilerini yükle
      if (user.role == UserRole.caregiver && user.patientId != null) {
        final patient = await UserService().getUser(user.patientId!);
        if (patient != null) {
          setState(() {
            _patientUser = patient;
            _patientNameController.text = patient.name;
            _patientEmailController.text = patient.email;
          });

          // Hasta için ekstra bilgileri yükle
          final patientInfo = await PatientInfoService().getPatientInfo(user.patientId!);
          if (patientInfo != null) {
            setState(() {
              _patientPhoneController.text = patientInfo.phone ?? '';
              _patientAddressController.text = patientInfo.address ?? '';
              _patientBirthDateController.text = patientInfo.birthDate ?? '';
              _patientNotesController.text = patientInfo.notes ?? '';
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _patientNameController.dispose();
    _patientEmailController.dispose();
    _patientPhoneController.dispose();
    _patientAddressController.dispose();
    _patientBirthDateController.dispose();
    _patientNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveCaregiverInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_currentUser != null) {
        final updatedUser = AppUser(
          uid: _currentUser!.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _currentUser!.role,
          patientId: _currentUser!.patientId,
        );

        await UserService().updateUser(updatedUser);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilgileriniz güncellendi')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePatientInfo() async {
    if (_currentUser?.role != UserRole.caregiver) return;

    if (_patientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasta adı soyadı gerekli')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String patientId;
      AppUser? existingPatient;
      final enteredEmail = _patientEmailController.text.trim();

      // Girilen e-posta ile kayıtlı bir hasta varsa onu kullan
      if (enteredEmail.isNotEmpty) {
        try {
          final foundUser = await UserService().getUserByEmail(enteredEmail);
          if (foundUser != null && foundUser.role == UserRole.patient) {
            existingPatient = foundUser;
            print('✅ Hasta bulundu: ${foundUser.name} (${foundUser.uid})');
          } else {
            print('⚠️ E-posta ile hasta bulunamadı veya hasta rolü değil: $enteredEmail');
          }
        } catch (e) {
          print('❌ E-posta ile hasta arama hatası: $e');
          // sessiz geç; aşağıda yeni hasta oluşturulacak
        }
      }
      
      // Eğer hasta kullanıcısı yoksa, yeni bir hasta oluştur
      if (_patientUser == null) {
        if (existingPatient != null) {
          // Mevcut hasta kullanıcısını bağla
          patientId = existingPatient.uid;
          print('🔗 Hasta yakını ile hasta eşleştiriliyor:');
          print('   Hasta Yakını UID: ${_currentUser!.uid}');
          print('   Hasta UID (patientId): $patientId');
          await UserService().linkPatientToCaregiver(_currentUser!.uid, patientId);
          print('✅ Eşleştirme tamamlandı');

          setState(() {
            _patientUser = existingPatient;
            _patientNameController.text = existingPatient!.name;
            _patientEmailController.text = existingPatient!.email;
            _currentUser = AppUser(
              uid: _currentUser!.uid,
              name: _currentUser!.name,
              email: _currentUser!.email,
              role: _currentUser!.role,
              patientId: patientId,
            );
          });
        } else {
          // Yeni hasta kullanıcısı oluştur (sadece Firestore'da, Authentication'da değil)
          // Geçici bir ID oluştur veya mevcut hasta yakını ID'sini kullan
          patientId = _currentUser!.uid + '_patient';
          
          print('🆕 Yeni hasta oluşturuluyor:');
          print('   Hasta Yakını UID: ${_currentUser!.uid}');
          print('   Hasta UID (patientId): $patientId');
          
          final newPatient = AppUser(
            uid: patientId,
            name: _patientNameController.text.trim(),
            email: enteredEmail.isEmpty 
                ? 'patient_${_currentUser!.uid}@demansapp.local'
                : enteredEmail,
            role: UserRole.patient,
          );

          await UserService().saveUser(newPatient);
          
          // Hasta yakını ile hasta arasında bağlantı kur
          await UserService().linkPatientToCaregiver(_currentUser!.uid, patientId);
          print('✅ Yeni hasta oluşturuldu ve eşleştirildi');
          
          setState(() {
            _patientUser = newPatient;
            _currentUser = AppUser(
              uid: _currentUser!.uid,
              name: _currentUser!.name,
              email: _currentUser!.email,
              role: _currentUser!.role,
              patientId: patientId,
            );
          });
        }
      } else {
        // Mevcut hasta bilgilerini güncelle
        patientId = _patientUser!.uid;
        
        final updatedPatient = AppUser(
          uid: _patientUser!.uid,
          name: _patientNameController.text.trim(),
          email: _patientEmailController.text.trim().isEmpty 
              ? _patientUser!.email
              : _patientEmailController.text.trim(),
          role: UserRole.patient,
        );

        await UserService().updateUser(updatedPatient);
        setState(() {
          _patientUser = updatedPatient;
        });
      }

      // Hasta ekstra bilgilerini kaydet
      final patientInfo = PatientInfo(
        patientId: patientId,
        phone: _patientPhoneController.text.trim().isEmpty 
            ? null 
            : _patientPhoneController.text.trim(),
        address: _patientAddressController.text.trim().isEmpty 
            ? null 
            : _patientAddressController.text.trim(),
        birthDate: _patientBirthDateController.text.trim().isEmpty 
            ? null 
            : _patientBirthDateController.text.trim(),
        notes: _patientNotesController.text.trim().isEmpty 
            ? null 
            : _patientNotesController.text.trim(),
      );

      await PatientInfoService().savePatientInfo(patientInfo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasta bilgileri kaydedildi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isCaregiver = _currentUser!.role == UserRole.caregiver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil ve Ayarlar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hasta Yakını Bilgileri
                _SectionHeader(
                  title: 'Kişisel Bilgilerim',
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  enableSuggestions: false,
                  autocorrect: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ\s]'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ad Soyad girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enabled: false, // E-posta değiştirilemez
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _saveCaregiverInfo,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Bilgilerimi Kaydet'),
                ),
                
                // Hasta Bilgileri (Sadece Hasta Yakını için)
                if (isCaregiver) ...[
                  const SizedBox(height: 40),
                  _SectionHeader(
                    title: 'Hasta Bilgileri',
                    icon: Icons.medical_services_rounded,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _patientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Hasta Ad Soyad',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    enableSuggestions: false,
                    autocorrect: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ\s]'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _patientEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Hasta E-posta (Opsiyonel)',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _patientPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _patientAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Adres',
                      prefixIcon: Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _patientBirthDateController,
                    decoration: const InputDecoration(
                      labelText: 'Doğum Tarihi',
                      hintText: 'GG.AA.YYYY',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _patientNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Notlar',
                      hintText: 'Önemli notlar, alerjiler, kullanılan ilaçlar vb.',
                      prefixIcon: Icon(Icons.note_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _savePatientInfo,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Hasta Bilgilerini Kaydet'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4B7CFB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF4B7CFB)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

