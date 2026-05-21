import 'package:flutter/material.dart';

class NoteCategory {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final String hint;

  NoteCategory({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.hint,
  });

  static List<NoteCategory> all = [
    NoteCategory(
      value: 'period',
      label: 'Period',
      icon: Icons.water_drop_outlined,
      color: const Color(0xFFE5486D),
      background: const Color(0xFFFCE8F0),
      hint: 'Write about your flow, cramps, comfort, or energy today...',
    ),
    NoteCategory(
      value: 'symptoms',
      label: 'Symptoms',
      icon: Icons.healing_outlined,
      color: const Color(0xFFF4A261),
      background: const Color(0xFFFFF1E6),
      hint: 'What symptoms did you notice today?',
    ),
    NoteCategory(
      value: 'mood',
      label: 'Mood',
      icon: Icons.sentiment_satisfied_outlined,
      color: const Color(0xFFA78BFA),
      background: const Color(0xFFF3EEFF),
      hint: 'How are you feeling emotionally today?',
    ),
    NoteCategory(
      value: 'medicine',
      label: 'Medicine',
      icon: Icons.medication_outlined,
      color: const Color(0xFF1F9A8A),
      background: const Color(0xFFE7F8F5),
      hint: 'Add medicine, dosage, or timing notes...',
    ),
    NoteCategory(
      value: 'doctor',
      label: 'Doctor',
      icon: Icons.medical_services_outlined,
      color: const Color(0xFF5B8DEF),
      background: const Color(0xFFEAF2FF),
      hint: 'Add doctor advice, prescription, or questions...',
    ),
    NoteCategory(
      value: 'fertility',
      label: 'Fertility',
      icon: Icons.eco_outlined,
      color: const Color(0xFF7BCFA6),
      background: const Color(0xFFEAFBF3),
      hint: 'Write anything you noticed around ovulation or fertile window...',
    ),
    NoteCategory(
      value: 'personal',
      label: 'Personal',
      icon: Icons.favorite_border,
      color: const Color(0xFFB83F68),
      background: const Color(0xFFFBEAF1),
      hint: 'This is your private space. Write freely...',
    ),
    NoteCategory(
      value: 'femai_question',
      label: 'FemAI Question',
      icon: Icons.auto_awesome_outlined,
      color: const Color(0xFFA78BFA),
      background: const Color(0xFFF5F0FF),
      hint: 'What would you like FemAI to help you understand?',
    ),
    NoteCategory(
      value: 'other',
      label: 'Other',
      icon: Icons.notes,
      color: Colors.grey,
      background: const Color(0xFFF7F4F6),
      hint: 'Write your notes here...',
    ),
  ];

  static NoteCategory fromValue(String value) {
    return all.firstWhere((c) => c.value == value, orElse: () => all.last);
  }
}
