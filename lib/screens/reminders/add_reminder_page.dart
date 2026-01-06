import 'package:flutter/material.dart';
import '../../models/reminder.dart';
import '../../services/reminder_service.dart';

class AddReminderPage extends StatefulWidget {
  const AddReminderPage({super.key, this.initialReminder});

  final Reminder? initialReminder;

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _timeController = TextEditingController();
  final _noteController = TextEditingController();
  final _dosageController = TextEditingController();
  final _locationController = TextEditingController();
  
  ReminderCategory _selectedCategory = ReminderCategory.medication;
  ReminderRepeatType _selectedRepeat = ReminderRepeatType.none;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialReminder != null) {
      final reminder = widget.initialReminder!;
      _titleController.text = reminder.title;
      _subtitleController.text = reminder.subtitle;
      _timeController.text = reminder.timeLabel;
      _noteController.text = reminder.note;
      _dosageController.text = reminder.dosage;
      _locationController.text = reminder.location;
      _selectedCategory = reminder.category;
      _selectedRepeat = reminder.repeatType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _timeController.dispose();
    _noteController.dispose();
    _dosageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final reminder = Reminder(
        id: widget.initialReminder?.id,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        timeLabel: _timeController.text.trim(),
        note: _noteController.text.trim(),
        dosage: _dosageController.text.trim(),
        location: _locationController.text.trim(),
        category: _selectedCategory,
        repeatType: _selectedRepeat,
        nextRepeatDate: _selectedRepeat != ReminderRepeatType.none
            ? DateTime.now().add(
                _selectedRepeat == ReminderRepeatType.daily
                    ? const Duration(days: 1)
                    : const Duration(days: 7),
              )
            : null,
      );

      if (widget.initialReminder != null) {
        await ReminderService().updateReminder(reminder);
      } else {
        await ReminderService().addReminder(reminder);
      }
      
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialReminder != null
              ? 'Hatırlatıcı güncellendi'
              : 'Hatırlatıcı başarıyla eklendi'),
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialReminder != null
            ? 'Hatırlatıcı Düzenle'
            : 'Yeni Hatırlatıcı'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _handleSave,
              child: const Text('Kaydet'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kategori Seçimi
                Text(
                  'Kategori',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CategoryChip(
                        category: ReminderCategory.medication,
                        label: 'İlaç',
                        icon: Icons.vaccines_rounded,
                        isSelected: _selectedCategory == ReminderCategory.medication,
                        onTap: () {
                          setState(() {
                            _selectedCategory = ReminderCategory.medication;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CategoryChip(
                        category: ReminderCategory.appointment,
                        label: 'Randevu',
                        icon: Icons.local_hospital_rounded,
                        isSelected: _selectedCategory == ReminderCategory.appointment,
                        onTap: () {
                          setState(() {
                            _selectedCategory = ReminderCategory.appointment;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CategoryChip(
                        category: ReminderCategory.activity,
                        label: 'Görev',
                        icon: Icons.favorite_rounded,
                        isSelected: _selectedCategory == ReminderCategory.activity,
                        onTap: () {
                          setState(() {
                            _selectedCategory = ReminderCategory.activity;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Başlık girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Alt Başlık',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: 'Saat *',
                    hintText: 'Örn: 11:30',
                    prefixIcon: Icon(Icons.access_time_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Saat girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Not',
                    prefixIcon: Icon(Icons.note_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Doz/Miktar',
                    hintText: 'Örn: 1 kapsül, 30 dk',
                    prefixIcon: Icon(Icons.medication_liquid_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Konum',
                    hintText: 'Örn: Mutfak çekmecesi',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSave(),
                ),
                const SizedBox(height: 24),
                // Tekrarlama Seçimi
                Text(
                  'Tekrarlama',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RepeatChip(
                        repeatType: ReminderRepeatType.none,
                        label: 'Yok',
                        isSelected: _selectedRepeat == ReminderRepeatType.none,
                        onTap: () {
                          setState(() {
                            _selectedRepeat = ReminderRepeatType.none;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RepeatChip(
                        repeatType: ReminderRepeatType.daily,
                        label: 'Günlük',
                        isSelected: _selectedRepeat == ReminderRepeatType.daily,
                        onTap: () {
                          setState(() {
                            _selectedRepeat = ReminderRepeatType.daily;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RepeatChip(
                        repeatType: ReminderRepeatType.weekly,
                        label: 'Haftalık',
                        isSelected: _selectedRepeat == ReminderRepeatType.weekly,
                        onTap: () {
                          setState(() {
                            _selectedRepeat = ReminderRepeatType.weekly;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final ReminderCategory category;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _color {
    switch (category) {
      case ReminderCategory.medication:
        return const Color(0xFF6C6EF5);
      case ReminderCategory.appointment:
        return const Color(0xFFFB7C7C);
      case ReminderCategory.activity:
        return const Color(0xFF4BBE9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? _color : const Color(0xFFE1E2EC),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? _color : const Color(0xFF7B7C8D)),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? _color : const Color(0xFF7B7C8D),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatChip extends StatelessWidget {
  const _RepeatChip({
    required this.repeatType,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final ReminderRepeatType repeatType;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4BBE9E).withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4BBE9E)
                : const Color(0xFFE1E2EC),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF4BBE9E)
                      : const Color(0xFF7B7C8D),
                ),
          ),
        ),
      ),
    );
  }
}

