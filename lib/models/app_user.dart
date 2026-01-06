enum UserRole {
  patient, // Hasta
  caregiver, // Hasta yakını
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.patientId, // Hasta yakını ise, bağlı olduğu hasta ID'si
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? patientId; // Hasta yakını için: bağlı olduğu hasta ID'si

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    final roleStr = (data['role'] as String?) ?? 'patient';
    final role = roleStr == 'caregiver' ? UserRole.caregiver : UserRole.patient;

    return AppUser(
      uid: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: role,
      patientId: data['patientId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role == UserRole.caregiver ? 'caregiver' : 'patient',
      'patientId': patientId,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

