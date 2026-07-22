import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/FemLyra_colors.dart';

class BasicInformationSection extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const BasicInformationSection({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<BasicInformationSection> createState() => _BasicInformationSectionState();
}

class _BasicInformationSectionState extends State<BasicInformationSection> {
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.initialData);
  }

  void _updateField(String key, dynamic value) {
    setState(() => _data[key] = value);
    widget.onChanged(_data);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField('Full Name', 'full_name', icon: Icons.person_outline),
        const SizedBox(height: 20),
        _buildInputField('Display Name (Optional)', 'display_name', icon: Icons.face_outlined),
        const SizedBox(height: 20),
        _buildDatePickerField('Date of Birth', 'dob'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildInputField('Country', 'country', icon: Icons.public)),
            const SizedBox(width: 16),
            Expanded(child: _buildInputField('City', 'city', icon: Icons.location_city)),
          ],
        ),
        const SizedBox(height: 20),
        _buildDropdownField('Preferred Language', 'preferred_language', ['English', 'Spanish', 'French', 'Hindi', 'Bengali']),
        const SizedBox(height: 20),
        _buildInputField('Profession', 'profession', icon: Icons.work_outline),
      ],
    );
  }

  Widget _buildInputField(String label, String key, {IconData? icon}) {
    return TextField(
      onChanged: (val) => _updateField(key, val),
      controller: TextEditingController.fromValue(
        TextEditingValue(
          text: _data[key]?.toString() ?? '',
          selection: TextSelection.collapsed(offset: (_data[key]?.toString() ?? '').length),
        ),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemLyraColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemLyraColors.border)),
      ),
    );
  }

  Widget _buildDatePickerField(String label, String key) {
    final dateStr = _data[key];
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14, color: FemLyraColors.textSecondary)),
      subtitle: Text(
        date != null ? DateFormat('MMMM d, yyyy').format(date) : 'Select date',
        style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
      ),
      trailing: const Icon(Icons.calendar_today, size: 20, color: FemLyraColors.primary),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: FemLyraColors.border)),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime(1995),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          _updateField(key, picked.toIso8601String().substring(0, 10));
        }
      },
    );
  }

  Widget _buildDropdownField(String label, String key, List<String> options) {
    return DropdownButtonFormField<String>(
      initialValue: _data[key],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemLyraColors.border)),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (val) => _updateField(key, val),
    );
  }
}
