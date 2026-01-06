import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../models/memory_contact.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/memory_contact_service.dart';
import '../../services/storage_service.dart';
import '../../models/app_user.dart';
import '../../services/tts_service.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  String _query = '';
  bool _favoritesOnly = false;
  final _ttsService = TtsService();

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

        return _AlbumPageContent(isCaregiver: isCaregiver);
      },
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }
}

class _AlbumPageContent extends StatefulWidget {
  const _AlbumPageContent({required this.isCaregiver});

  final bool isCaregiver;

  @override
  State<_AlbumPageContent> createState() => _AlbumPageContentState();
}

class _AlbumPageContentState extends State<_AlbumPageContent> {
  String _query = '';
  bool _favoritesOnly = false;
  final _memoryContactService = MemoryContactService();
  final _storageService = StorageService();
  final _userService = UserService();
  final _ttsService = TtsService();

  Future<Set<String>> _resolveTargetUserIds(AppUser user) async {
    final ids = <String>{};

    String? baseIdFrom(String value) {
      const suffix = '_patient';
      if (value.endsWith(suffix)) {
        return value.substring(0, value.length - suffix.length);
      }
      return null;
    }

    // Hasta için kendi UID'si
    ids.add(user.uid);
    final baseFromUid = baseIdFrom(user.uid);
    if (baseFromUid != null) ids.add(baseFromUid);

    // Eğer hasta yakını ise patientId'yi ekle
    if (user.role == UserRole.caregiver && user.patientId != null) {
      ids.add(user.patientId!);
      final baseFromPatientId = baseIdFrom(user.patientId!);
      if (baseFromPatientId != null) ids.add(baseFromPatientId);
    }

    // Hasta rolü için: bağlı hasta yakını varsa, eski kayıtları da kapsa
    if (user.role == UserRole.patient) {
      // Önce genişletilmiş arama (uid ve uid+"_patient")
      final caregiver = await _userService.getCaregiverByPatientAnyId(user.uid);
      if (caregiver != null) {
        if (caregiver.patientId != null) {
          ids.add(caregiver.patientId!);
          final baseFromCaregiverPatient =
              baseIdFrom(caregiver.patientId!);
          if (baseFromCaregiverPatient != null) {
            ids.add(baseFromCaregiverPatient);
          }
        }
        ids.add(caregiver.uid); // olası eski kayıtlar için geri dönüş
      }
      // Eğer hasta kaydında patientId alanı varsa onu da ekle
      if (user.patientId != null) {
        ids.add(user.patientId!);
        final baseFromPatientId = baseIdFrom(user.patientId!);
        if (baseFromPatientId != null) ids.add(baseFromPatientId);
      }
      // Eski pattern: uid + "_patient" (geçmiş kayıtlar için)
      ids.add('${user.uid}_patient');
    }

    print('🎯 Album targetUserIds: $ids');
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Kullanıcı girişi gerekli')),
      );
    }

    // Kullanıcı bilgisini al ve targetUserId'yi hesapla
    return StreamBuilder<AppUser?>(
      stream: _userService.getUserStream(currentUser.uid),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return FutureBuilder<Set<String>>(
          future: _resolveTargetUserIds(user),
          builder: (context, idsSnapshot) {
            if (!idsSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final targetIds = idsSnapshot.data!.toList();
            print('📋 AlbumPage - user.role: ${user.role}, ids: $targetIds');

            return StreamBuilder<List<MemoryContact>>(
          stream: _memoryContactService.getMemoryContactsForUserIds(targetIds),
          builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFFFB7C7C)),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Yeniden Dene'),
                ),
              ],
            ),
          );
        }

        final allContacts = snapshot.data ?? [];
        
        // Sadece Firestore'dan gelen verileri kullan
        final combinedContacts = allContacts;
        
        final contacts = combinedContacts.where((contact) {
          final queryMatch = _query.isEmpty ||
              contact.name.toLowerCase().contains(_query.toLowerCase()) ||
              contact.relationship.toLowerCase().contains(_query.toLowerCase());
          final favoriteMatch = !_favoritesOnly || contact.isFavorite;
          return queryMatch && favoriteMatch;
        }).toList();

        final uniqueRelationships = {
          for (final contact in combinedContacts) contact.relationship
        }.toList();

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AlbumHeader(
                    contactsCount: combinedContacts.length,
                    favoriteCount: combinedContacts.where((c) => c.isFavorite).length,
                  ),
                  const SizedBox(height: 20),
                  _SearchBar(
                    initialValue: _query,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  _RelationshipFilters(
                    relationships: uniqueRelationships,
                    favoritesOnly: _favoritesOnly,
                    onToggleFavorites: (value) => setState(() {
                      _favoritesOnly = value;
                    }),
                  ),
                  const SizedBox(height: 16),
                  contacts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48.0),
                          child: _EmptyState(isCaregiver: widget.isCaregiver),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            return _MemoryCard(
                              contact: contact,
                              isCaregiver: widget.isCaregiver,
                              onPlayTts: () => _handlePlayTts(contact),
                              onOpen: () => _openDetails(contact),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          floatingActionButton: widget.isCaregiver
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddContactDialog(context),
                  backgroundColor: const Color(0xFF4BBE9E),
                  icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                  label: const Text(
                    'Fotoğraf yükle',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                )
              : null,
        );
          },
        );
          },
        );
      },
    );
  }

  Future<void> _showAddContactDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddContactDialog(
          storageService: _storageService,
          memoryContactService: _memoryContactService,
          isCaregiver: widget.isCaregiver,
        ),
      ),
    );
  }

  void _handlePlayTts(MemoryContact contact) {
    _ttsService.speak(contact.ttsScript).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('TTS çalışırken hata: $e'),
          backgroundColor: const Color(0xFFFB7C7C),
        ),
      );
    });
  }

  void _openDetails(MemoryContact contact) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _ContactDetailSheet(
        contact: contact,
        isCaregiver: widget.isCaregiver,
        onPlayTts: () => _handlePlayTts(contact),
        onEdit: () => _editContact(contact),
        onDelete: () => _deleteContact(contact),
      ),
    );
  }

  Future<void> _editContact(MemoryContact contact) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddContactDialog(
          storageService: _storageService,
          memoryContactService: _memoryContactService,
          isCaregiver: widget.isCaregiver,
          initialContact: contact,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _deleteContact(MemoryContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kişiyi sil'),
        content: Text('${contact.name} kaydını silmek istiyor musun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Fotoğrafı da sil (Storage URL ise)
      if (contact.imageUrl.isNotEmpty &&
          contact.imageUrl.startsWith('http')) {
        await _storageService.deleteImage(contact.imageUrl);
      }
      await _memoryContactService.deleteMemoryContact(contact.id);
      if (mounted) {
        Navigator.of(context).maybePop(); // detay sheet açıksa kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kişi silindi'),
            backgroundColor: Color(0xFF4BBE9E),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silinirken hata: $e'),
            backgroundColor: const Color(0xFFFB7C7C),
          ),
        );
      }
    }
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({
    required this.contactsCount,
    this.favoriteCount = 0,
  });

  final int contactsCount;
  final int favoriteCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kişi albümü',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hatırlamak istediğin  anılar burada.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7B7C8D),
                  ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              Text(
                '$contactsCount kişi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '$favoriteCount favori',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7B7C8D),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController(text: initialValue),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: 'İsim, ilişki veya not ara',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _RelationshipFilters extends StatelessWidget {
  const _RelationshipFilters({
    required this.relationships,
    required this.favoritesOnly,
    required this.onToggleFavorites,
  });

  final List<String> relationships;
  final bool favoritesOnly;
  final ValueChanged<bool> onToggleFavorites;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            selected: favoritesOnly,
            onSelected: onToggleFavorites,
            avatar: Icon(
              Icons.star_rounded,
              size: 18,
              color: favoritesOnly ? Colors.white : const Color(0xFF7B7C8D),
            ),
            label: const Text('Favoriler'),
            showCheckmark: false,
            selectedColor: const Color(0xFFFFC857),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: favoritesOnly ? Colors.white : const Color(0xFF7B7C8D),
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide.none,
          ),
          const SizedBox(width: 12),
          ...relationships.map(
            (relationship) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                backgroundColor: const Color(0xFFF1F2F8),
                label: Text(
                  relationship,
                  style: const TextStyle(
                    color: Color(0xFF5D5E73),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.contact,
    required this.isCaregiver,
    required this.onPlayTts,
    required this.onOpen,
  });

  final MemoryContact contact;
  final bool isCaregiver;
  final VoidCallback onPlayTts;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    // Hasta için: direkt seslendirme, Hasta yakını için: detay sayfası
    final onCardTap = isCaregiver ? onOpen : onPlayTts;
    
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: contact.imageUrl.isNotEmpty && 
                             !contact.imageUrl.startsWith('assets/')
                          ? Image.network(
                              contact.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFE1E2EC),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: Color(0xFF7B7C8D),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: const Color(0xFFE1E2EC),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: const Color(0xFFE1E2EC),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: Color(0xFF7B7C8D),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(
                        contact.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: contact.isFavorite
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.relationship,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7B7C8D),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Son görüşme: ${contact.lastSeenLabel}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF5D5E73),
                                  ),
                        ),
                      ),
                      // Hasta yakını için ses butonu göster, hasta için gösterme (zaten tıklanınca ses çalıyor)
                      if (isCaregiver)
                        IconButton(
                          onPressed: onPlayTts,
                          icon: const Icon(Icons.volume_up_rounded),
                          tooltip: 'Sesli anlat',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactDetailSheet extends StatelessWidget {
  const _ContactDetailSheet({
    required this.contact,
    required this.isCaregiver,
    required this.onPlayTts,
    required this.onEdit,
    required this.onDelete,
  });

  final MemoryContact contact;
  final bool isCaregiver;
  final VoidCallback onPlayTts;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE1E2EC),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFE1E2EC),
                backgroundImage: contact.imageUrl.isNotEmpty && 
                                !contact.imageUrl.startsWith('assets/')
                    ? NetworkImage(contact.imageUrl)
                    : null,
                child: contact.imageUrl.isEmpty || 
                       contact.imageUrl.startsWith('assets/')
                    ? const Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: Color(0xFF7B7C8D),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    Text(
                      contact.relationship,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF7B7C8D),
                              ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: onPlayTts,
                icon: const Icon(Icons.volume_up_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF4B7CFB),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            contact.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF4F5063),
                ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.notes_rounded, color: Color(0xFF4B7CFB)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    contact.ttsScript,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5D5E73),
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (isCaregiver) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Düzenle'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Sil'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: const Color(0xFFFB7C7C),
                      side: const BorderSide(color: Color(0xFFFB7C7C)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isCaregiver});

  final bool isCaregiver;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FE),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: Color(0xFF4B7CFB),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz kişi eklenmemiş',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isCaregiver
                ? 'Yakınlarının fotoğraflarını yükleyerek albümü doldurabilirsin.'
                : 'Yakınların tarafından eklenen kişiler burada görünecek.',
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

/// Kişi ekleme dialog'u
class _AddContactDialog extends StatefulWidget {
  const _AddContactDialog({
    required this.storageService,
    required this.memoryContactService,
    required this.isCaregiver,
    this.initialContact,
  });

  final StorageService storageService;
  final MemoryContactService memoryContactService;
  final bool isCaregiver;
  final MemoryContact? initialContact;

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ttsScriptController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _descriptionController.dispose();
    _ttsScriptController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialContact != null) {
      _nameController.text = widget.initialContact!.name;
      _relationshipController.text = widget.initialContact!.relationship;
      _descriptionController.text = widget.initialContact!.description;
      _ttsScriptController.text = widget.initialContact!.ttsScript;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilirken hata oluştu: ${e.toString()}'),
            backgroundColor: const Color(0xFFFB7C7C),
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf çekilirken hata oluştu: ${e.toString()}'),
            backgroundColor: const Color(0xFFFB7C7C),
          ),
        );
      }
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir fotoğraf seçin'),
          backgroundColor: Color(0xFFFB7C7C),
        ),
      );
      return;
    }

    final isEdit = widget.initialContact != null;

    // Hasta yakını ise, patientId kontrolü yap
    if (widget.isCaregiver) {
      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        final user = await UserService().getUser(currentUser.uid);
        if (user != null && user.role == UserRole.caregiver && user.patientId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Kişi eklemek için önce profil ayarlarından hasta bilgilerini eklemeniz gerekiyor.',
                ),
                backgroundColor: const Color(0xFFFB7C7C),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Tamam',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
          return;
        }
      }
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Fotoğrafı Firebase Storage'a yükle (yeni seçildiyse)
      String imageUrl = widget.initialContact?.imageUrl ?? '';
      if (_selectedImage != null) {
        imageUrl = await widget.storageService.uploadImage(
          _selectedImage!,
          'memory_contacts',
        );
      }

      // Kişiyi Firestore'a kaydet
      final contact = MemoryContact(
        id: widget.initialContact?.id ?? '', // add için boş, edit için mevcut ID
        name: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        lastSeen: widget.initialContact?.lastSeen ?? DateTime.now(),
        ttsScript: _ttsScriptController.text.trim().isEmpty
            ? 'Bu ${_nameController.text.trim()}, ${_relationshipController.text.trim()}.'
            : _ttsScriptController.text.trim(),
        isFavorite: widget.initialContact?.isFavorite ?? false,
      );

      if (isEdit) {
        await widget.memoryContactService.updateMemoryContact(contact);
      } else {
        await widget.memoryContactService.addMemoryContact(contact);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kişi başarıyla kaydedildi'),
            backgroundColor: Color(0xFF4BBE9E),
          ),
        );
      }
    } catch (e) {
      print('❌ Kişi ekleme hatası: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        
        // Daha detaylı hata mesajı göster
        String errorMessage = 'Kişi eklenirken hata oluştu';
        final errorString = e.toString();
        
        if (errorString.contains('profil ayarlarından hasta bilgilerini')) {
          errorMessage = 'Kişi eklemek için önce profil ayarlarından hasta bilgilerini eklemeniz gerekiyor.';
        } else if (errorString.contains('permission-denied')) {
          errorMessage = 'Firebase Storage izin hatası. Lütfen Firebase Console\'dan Storage güvenlik kurallarını kontrol edin.';
        } else if (errorString.contains('network')) {
          errorMessage = 'Ağ hatası. İnternet bağlantınızı kontrol edin.';
        } else if (errorString.contains('storage')) {
          errorMessage = 'Firebase Storage hatası. Lütfen Firebase Console\'dan Storage\'ı etkinleştirdiğinizden emin olun.';
        } else {
          errorMessage = 'Hata: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFFB7C7C),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Yeni Kişi Ekle',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fotoğraf seçimi
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.photo_library_rounded),
                                        title: const Text('Galeriden Seç'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage();
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt_rounded),
                                        title: const Text('Fotoğraf Çek'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _takePhoto();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F5FB),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF4BBE9E),
                                  width: 2,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : (widget.initialContact != null &&
                                          widget.initialContact!.imageUrl.isNotEmpty &&
                                          !widget.initialContact!.imageUrl.startsWith('assets/'))
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: Image.network(
                                            widget.initialContact!.imageUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate_rounded,
                                              size: 48,
                                              color: Color(0xFF4BBE9E),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Fotoğraf Seç',
                                              style: TextStyle(
                                                color: Color(0xFF4BBE9E),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // İsim
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.name,
                          decoration: const InputDecoration(
                            labelText: 'İsim *',
                            hintText: 'Örn: Ahmet Yılmaz',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'İsim gereklidir';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Yakınlık
                        TextFormField(
                          controller: _relationshipController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'Yakınlık *',
                            hintText: 'Örn: Oğul, Kız, Torun',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                            prefixIcon: Icon(Icons.family_restroom_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Yakınlık gereklidir';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Açıklama
                        TextFormField(
                          controller: _descriptionController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            labelText: 'Açıklama',
                            hintText: 'Bu kişi hakkında kısa bir açıklama',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                            prefixIcon: Icon(Icons.description_rounded),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        // TTS Script
                        TextFormField(
                          controller: _ttsScriptController,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            labelText: 'Sesli Açıklama (TTS)',
                            hintText: 'Bu kişi için sesli açıklama metni',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                            prefixIcon: Icon(Icons.record_voice_over_rounded),
                            helperText: 'Boş bırakılırsa otomatik oluşturulur',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 32),
                        // Kaydet butonu
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isUploading ? null : _saveContact,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4BBE9E),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Kaydet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

