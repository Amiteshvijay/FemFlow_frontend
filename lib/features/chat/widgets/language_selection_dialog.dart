import 'package:flutter/material.dart';
import '../models/conversation_language.dart';
import '../../../core/theme/FemLyra_colors.dart';

class LanguageSelectionResult {
  final ConversationLanguage selectedLanguage;
  final bool autoDetect;

  LanguageSelectionResult({
    required this.selectedLanguage,
    required this.autoDetect,
  });
}

class LanguageSelectionDialog extends StatefulWidget {
  final ConversationLanguage initialLanguage;
  final bool initialAutoDetect;

  const LanguageSelectionDialog({
    super.key,
    required this.initialLanguage,
    this.initialAutoDetect = false,
  });

  @override
  State<LanguageSelectionDialog> createState() => _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState extends State<LanguageSelectionDialog> {
  late ConversationLanguage _selectedLanguage;
  late bool _autoDetect;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
    _autoDetect = widget.initialAutoDetect;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language_rounded, color: FemLyraColors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Choose your conversation language",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FemLyraColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: FemLyraColors.softBlush,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: CheckboxListTile(
                value: _autoDetect,
                onChanged: (val) {
                  setState(() {
                    _autoDetect = val ?? false;
                  });
                },
                title: const Text(
                  "Automatically detect my language",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                activeColor: FemLyraColors.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: ConversationLanguage.supportedLanguages.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) {
                  final lang = ConversationLanguage.supportedLanguages[index];
                  final isSelected = _selectedLanguage.code == lang.code;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    title: Text(
                      lang.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? FemLyraColors.primary : FemLyraColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      lang.nativeName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? FemLyraColors.primary.withOpacity(0.8) : Colors.grey[600],
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: FemLyraColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLanguage = lang;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        LanguageSelectionResult(
                          selectedLanguage: _selectedLanguage,
                          autoDetect: _autoDetect,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FemLyraColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
