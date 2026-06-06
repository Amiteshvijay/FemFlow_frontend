import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import '../../core/security/app_lock_service.dart';
import 'data/community_service.dart';
import 'my_posts_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final String roomSlug;
  final String roomName;

  const CreatePostScreen({
    super.key,
    required this.roomSlug,
    required this.roomName,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final CommunityService _service = CommunityService();
  final RichTextEditingController _contentController = RichTextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnonymous = true;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final appLock = context.read<AppLockService>();
    try {
      appLock.setTrustedExternalFlowActive(true);
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      appLock.setTrustedExternalFlowActive(false);
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content for your post.'))
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'content': content,
        'is_anonymous': _isAnonymous,
      };

      await _service.createPost(
        widget.roomSlug,
        data,
        imageFile: _selectedImage,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSubmittedBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share post. Please try again.'))
        );
      }
    }
  }

  void _showSubmittedBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PostSubmittedSheet(
        onViewMyPosts: () {
          final navigator = Navigator.of(context);
          Navigator.pop(ctx); // close sheet
          navigator.pop(true); // back to room
          navigator.push(
            MaterialPageRoute(builder: (_) => const MyPostsScreen()),
          );
        },
        onDone: () {
          Navigator.pop(ctx);
          Navigator.pop(context, true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post to ${widget.roomName}',
          style: const TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: FemFlowColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Posting as', style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
                      Text(
                        'Community Member', 
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Anonymous', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
                    const SizedBox(width: 4),
                    Switch(
                      value: _isAnonymous,
                      onChanged: (val) => setState(() => _isAnonymous = val),
                      activeTrackColor: FemFlowColors.primary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildFormattingToolbar(),
                  Container(
                    height: 1,
                    color: Colors.grey[200] ?? const Color(0xFFEEEEEE),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _contentController,
                      maxLines: 8,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts, questions, or experiences...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildImagePickerSection(),
            const SizedBox(height: 12),
            Text(
              'Your post will be visible to all FemFlow Premium members.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Share Post',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolbarButton(
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              onTap: () => _wrapSelection('<b>', '</b>'),
            ),
            _toolbarButton(
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              onTap: () => _wrapSelection('<i>', '</i>'),
            ),
            _toolbarButton(
              icon: Icons.format_underlined_rounded,
              tooltip: 'Underline',
              onTap: () => _wrapSelection('<u>', '</u>'),
            ),
            _buildVerticalDivider(),
            _toolbarButton(
              icon: Icons.format_size_rounded,
              tooltip: 'Text Size (Cycle)',
              onTap: _cycleTextSize,
            ),
            _buildVerticalDivider(),
            _toolbarButton(
              icon: Icons.format_align_left_rounded,
              tooltip: 'Align Left',
              onTap: () => _toggleLineAlignment('left'),
            ),
            _toolbarButton(
              icon: Icons.format_align_center_rounded,
              tooltip: 'Align Center',
              onTap: () => _toggleLineAlignment('center'),
            ),
            _toolbarButton(
              icon: Icons.format_align_right_rounded,
              tooltip: 'Align Right',
              onTap: () => _toggleLineAlignment('right'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.grey[200],
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 20,
              color: FemFlowColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _wrapSelection(String openTag, String closeTag) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    if (selection.start < 0 || selection.end < 0) {
      final cursorPosition = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
      final newText = '${text.substring(0, cursorPosition)}$openTag$closeTag${text.substring(cursorPosition)}';
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: cursorPosition + openTag.length);
      return;
    }
    
    final selectedText = text.substring(selection.start, selection.end);
    final newText = '${text.substring(0, selection.start)}$openTag$selectedText$closeTag${text.substring(selection.end)}';
    
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start + openTag.length,
        extentOffset: selection.end + openTag.length,
      ),
    );
  }

  void _cycleTextSize() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final cursorPosition = selection.baseOffset >= 0 ? selection.baseOffset : text.length;

    if (selection.start < 0 || selection.end < 0 || selection.start == selection.end) {
      final newText = '${text.substring(0, cursorPosition)}<large></large>${text.substring(cursorPosition)}';
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: cursorPosition + 7);
      return;
    }
    
    final selectedText = text.substring(selection.start, selection.end);
    
    if (selectedText.startsWith('<large>') && selectedText.endsWith('</large>')) {
      final inner = selectedText.substring(7, selectedText.length - 8);
      final newSelected = '<small>$inner</small>';
      final newText = '${text.substring(0, selection.start)}$newSelected${text.substring(selection.end)}';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + newSelected.length,
        ),
      );
    } else if (selectedText.startsWith('<small>') && selectedText.endsWith('</small>')) {
      final inner = selectedText.substring(7, selectedText.length - 8);
      final newText = '${text.substring(0, selection.start)}$inner${text.substring(selection.end)}';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + inner.length,
        ),
      );
    } else {
      final newSelected = '<large>$selectedText</large>';
      final newText = '${text.substring(0, selection.start)}$newSelected${text.substring(selection.end)}';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + newSelected.length,
        ),
      );
    }
  }

  void _toggleLineAlignment(String tag) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    final cursorPosition = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
    
    int lineStart = cursorPosition;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    
    int lineEnd = cursorPosition;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }
    
    final currentLine = text.substring(lineStart, lineEnd);
    
    String cleanedLine = currentLine;
    final alignmentRegex = RegExp(r'^<(center|left|right)>(.*?)</\1>$');
    final match = alignmentRegex.firstMatch(currentLine.trim());
    if (match != null) {
      cleanedLine = match.group(2) ?? '';
    }
    
    String newLine = cleanedLine;
    if (tag != 'left') {
      newLine = '<$tag>$cleanedLine</$tag>';
    }
    
    final newText = '${text.substring(0, lineStart)}$newLine${text.substring(lineEnd)}';
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(offset: lineStart + newLine.length);
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: FemFlowColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FemFlowColors.primary.withValues(alpha: 0.1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, color: FemFlowColors.primary),
                  SizedBox(width: 12),
                  Text(
                    'Add Image',
                    style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PostSubmittedSheet extends StatelessWidget {
  final VoidCallback onViewMyPosts;
  final VoidCallback onDone;

  const _PostSubmittedSheet({
    required this.onViewMyPosts,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FemFlowColors.fertileWindow.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: FemFlowColors.fertileWindow,
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Post Under Review',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: FemFlowColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'To keep our community safe, supportive, and respectful, all posts go through a quick review process. You can track the status of your post in your history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: FemFlowColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Track Approval Status',
            onPressed: onViewMyPosts,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onDone,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Back to Community',
              style: TextStyle(
                color: FemFlowColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RichTextEditingController extends TextEditingController {
  @override
  set value(TextEditingValue newValue) {
    // Clean the new text
    final cleanText = _cleanHtml(newValue.text, newValue.selection);
    
    // Adjust selection if the text length changed
    TextSelection newSelection = newValue.selection;
    if (cleanText.length != newValue.text.length) {
      int newStart = newValue.selection.start;
      int newEnd = newValue.selection.end;
      
      if (newStart > cleanText.length) newStart = cleanText.length;
      if (newEnd > cleanText.length) newEnd = cleanText.length;
      
      newSelection = TextSelection(
        baseOffset: newStart,
        extentOffset: newEnd,
      );
    }

    super.value = TextEditingValue(
      text: cleanText,
      selection: newSelection,
      composing: newValue.composing,
    );
  }

  String _cleanHtml(String text, TextSelection selection) {
    String cleaned = text;

    final emptyTags = [
      ['<b>', '</b>'],
      ['<i>', '</i>'],
      ['<u>', '</u>'],
      ['<large>', '</large>'],
      ['<small>', '</small>'],
      ['<center>', '</center>'],
      ['<left>', '</left>'],
      ['<right>', '</right>']
    ];

    // 1. Remove empty tags recursively, keeping the one containing the cursor
    bool changed = true;
    while (changed) {
      changed = false;
      for (final pair in emptyTags) {
        final open = pair[0];
        final close = pair[1];
        final fullTag = '$open$close';
        
        int index = cleaned.indexOf(fullTag);
        while (index != -1) {
          if (selection.isCollapsed && selection.start == index + open.length) {
            index = cleaned.indexOf(fullTag, index + 1);
          } else {
            cleaned = cleaned.replaceRange(index, index + fullTag.length, '');
            int start = selection.start;
            int end = selection.end;
            if (start > index) {
              start -= fullTag.length;
              if (start < index) start = index;
            }
            if (end > index) {
              end -= fullTag.length;
              if (end < index) end = index;
            }
            selection = TextSelection(baseOffset: start, extentOffset: end);
            changed = true;
            index = cleaned.indexOf(fullTag);
          }
        }
      }
    }

    // 2. Remove broken/partial tags (must start with '<' followed by valid starting tag characters)
    final RegExp tagRegExp = RegExp(r'</?[biulsc/][a-zA-Z]*>?|<>|</>');
    final validTags = {
      '<b>', '</b>', '<i>', '</i>', '<u>', '</u>', 
      '<large>', '</large>', '<small>', '</small>', 
      '<center>', '</center>', '<left>', '</left>', '<right>', '</right>'
    };

    cleaned = cleaned.replaceAllMapped(tagRegExp, (match) {
      final matchedStr = match.group(0)!;
      if (validTags.contains(matchedStr.toLowerCase())) {
        return matchedStr;
      }
      return '';
    });

    // 3. Remove lonely/unpaired tags
    cleaned = _removeLonelyTags(cleaned);

    // 4. Run empty tag check again
    changed = true;
    while (changed) {
      changed = false;
      for (final pair in emptyTags) {
        final open = pair[0];
        final close = pair[1];
        final fullTag = '$open$close';
        
        int index = cleaned.indexOf(fullTag);
        while (index != -1) {
          if (selection.isCollapsed && selection.start == index + open.length) {
            index = cleaned.indexOf(fullTag, index + 1);
          } else {
            cleaned = cleaned.replaceRange(index, index + fullTag.length, '');
            int start = selection.start;
            int end = selection.end;
            if (start > index) {
              start -= fullTag.length;
              if (start < index) start = index;
            }
            if (end > index) {
              end -= fullTag.length;
              if (end < index) end = index;
            }
            selection = TextSelection(baseOffset: start, extentOffset: end);
            changed = true;
            index = cleaned.indexOf(fullTag);
          }
        }
      }
    }

    return cleaned;
  }

  String _removeLonelyTags(String text) {
    final RegExp tagRegExp = RegExp(r'</?(?:b|i|u|large|small|center|left|right)>');
    final matches = tagRegExp.allMatches(text).toList();
    
    List<Map<String, dynamic>> stack = [];
    List<bool> keep = List.filled(matches.length, false);
    
    for (int idx = 0; idx < matches.length; idx++) {
      final match = matches[idx];
      final tagText = match.group(0)!.toLowerCase();
      
      if (!tagText.startsWith('</')) {
        final tagName = tagText.substring(1, tagText.length - 1);
        stack.add({'name': tagName, 'index': idx});
      } else {
        final tagName = tagText.substring(2, tagText.length - 1);
        int matchIdx = -1;
        for (int sIdx = stack.length - 1; sIdx >= 0; sIdx--) {
          if (stack[sIdx]['name'] == tagName) {
            matchIdx = sIdx;
            break;
          }
        }
        if (matchIdx != -1) {
          keep[stack[matchIdx]['index']] = true;
          keep[idx] = true;
          stack.removeAt(matchIdx);
        }
      }
    }
    
    StringBuffer sb = StringBuffer();
    int lastOffset = 0;
    for (int idx = 0; idx < matches.length; idx++) {
      final match = matches[idx];
      if (!keep[idx]) {
        sb.write(text.substring(lastOffset, match.start));
        lastOffset = match.end;
      }
    }
    sb.write(text.substring(lastOffset));
    return sb.toString();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final List<TextSpan> children = [];
    final textVal = text;

    final RegExp tagExp = RegExp(
      r'(</?(?:b|i|u|large|small|center|left|right)>|[^<]+|<)',
      caseSensitive: false,
    );

    final matches = tagExp.allMatches(textVal);
    TextStyle currentStyle = baseStyle;
    final List<TextStyle> styleStack = [baseStyle];

    for (final match in matches) {
      final token = match.group(0)!;
      final lowerToken = token.toLowerCase();

      if (lowerToken == '<b>') {
        currentStyle = currentStyle.copyWith(fontWeight: FontWeight.bold);
        styleStack.add(currentStyle);
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '</b>') {
        if (styleStack.length > 1) styleStack.removeLast();
        currentStyle = styleStack.last;
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '<i>') {
        currentStyle = currentStyle.copyWith(fontStyle: FontStyle.italic);
        styleStack.add(currentStyle);
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '</i>') {
        if (styleStack.length > 1) styleStack.removeLast();
        currentStyle = styleStack.last;
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '<u>') {
        currentStyle = currentStyle.copyWith(decoration: TextDecoration.underline);
        styleStack.add(currentStyle);
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '</u>') {
        if (styleStack.length > 1) styleStack.removeLast();
        currentStyle = styleStack.last;
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '<large>') {
        currentStyle = currentStyle.copyWith(fontSize: (currentStyle.fontSize ?? 14) * 1.3);
        styleStack.add(currentStyle);
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '</large>') {
        if (styleStack.length > 1) styleStack.removeLast();
        currentStyle = styleStack.last;
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '<small>') {
        currentStyle = currentStyle.copyWith(fontSize: (currentStyle.fontSize ?? 14) * 0.85);
        styleStack.add(currentStyle);
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '</small>') {
        if (styleStack.length > 1) styleStack.removeLast();
        currentStyle = styleStack.last;
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '<center>' || lowerToken == '<right>' || lowerToken == '<left>') {
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else if (lowerToken == '</center>' || lowerToken == '</right>' || lowerToken == '</left>') {
        children.add(TextSpan(text: token, style: const TextStyle(color: Colors.transparent, fontSize: 0)));
      } else {
        children.add(TextSpan(text: token, style: currentStyle));
      }
    }

    return TextSpan(children: children, style: baseStyle);
  }
}

