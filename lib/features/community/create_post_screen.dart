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
    final plainText = _contentController.text.trim();
    if (plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content for your post.'))
      );
      return;
    }

    final content = _contentController.toHtml().trim();
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
    return ListenableBuilder(
      listenable: _contentController,
      builder: (context, _) {
        final activeStyles = _contentController.activeStyles;
        final isBold = activeStyles.contains(StyleType.bold);
        final isItalic = activeStyles.contains(StyleType.italic);
        final isUnderline = activeStyles.contains(StyleType.underline);
        
        final isCenter = _contentController.styleRanges.any((r) => 
            r.type == StyleType.center && 
            _isCursorOrSelectionInLineAlignmentRange(r));
        final isRight = _contentController.styleRanges.any((r) => 
            r.type == StyleType.right && 
            _isCursorOrSelectionInLineAlignmentRange(r));
        final isLeft = !isCenter && !isRight;

        final isLarge = activeStyles.contains(StyleType.large);
        final isSmall = activeStyles.contains(StyleType.small);

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
                  isActive: isBold,
                  onTap: () => _contentController.toggleStyle(StyleType.bold),
                ),
                _toolbarButton(
                  icon: Icons.format_italic_rounded,
                  tooltip: 'Italic',
                  isActive: isItalic,
                  onTap: () => _contentController.toggleStyle(StyleType.italic),
                ),
                _toolbarButton(
                  icon: Icons.format_underlined_rounded,
                  tooltip: 'Underline',
                  isActive: isUnderline,
                  onTap: () => _contentController.toggleStyle(StyleType.underline),
                ),
                _buildVerticalDivider(),
                _toolbarButton(
                  icon: Icons.format_size_rounded,
                  tooltip: 'Text Size (Cycle)',
                  isActive: isLarge || isSmall,
                  onTap: _contentController.cycleTextSize,
                ),
                _buildVerticalDivider(),
                _toolbarButton(
                  icon: Icons.format_align_left_rounded,
                  tooltip: 'Align Left',
                  isActive: isLeft,
                  onTap: () => _contentController.setLineAlignment('left'),
                ),
                _toolbarButton(
                  icon: Icons.format_align_center_rounded,
                  tooltip: 'Align Center',
                  isActive: isCenter,
                  onTap: () => _contentController.setLineAlignment('center'),
                ),
                _toolbarButton(
                  icon: Icons.format_align_right_rounded,
                  tooltip: 'Align Right',
                  isActive: isRight,
                  onTap: () => _contentController.setLineAlignment('right'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isCursorOrSelectionInLineAlignmentRange(StyleRange range) {
    final selection = _contentController.selection;
    if (selection.start < 0 || selection.end < 0) return false;
    
    final txt = _contentController.text;
    int lineStart = selection.start;
    while (lineStart > 0 && txt[lineStart - 1] != '\n') {
      lineStart--;
    }
    
    int lineEnd = selection.end;
    while (lineEnd < txt.length && txt[lineEnd] != '\n') {
      lineEnd++;
    }
    
    return !(range.end <= lineStart || range.start >= lineEnd);
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
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? FemFlowColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? FemFlowColors.primary : FemFlowColors.textSecondary,
            ),
          ),
        ),
      ),
    );
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

enum StyleType { bold, italic, underline, large, small, center, left, right }

class StyleRange {
  int start;
  int end;
  final StyleType type;

  StyleRange({required this.start, required this.end, required this.type});

  StyleRange copyWith({int? start, int? end}) {
    return StyleRange(
      start: start ?? this.start,
      end: end ?? this.end,
      type: type,
    );
  }

  @override
  String toString() => 'StyleRange($type, $start, $end)';
}

class RichTextEditingController extends TextEditingController {
  List<StyleRange> styleRanges = [];
  Set<StyleType> activeStyles = {};

  RichTextEditingController({super.text});

  RichTextEditingController.fromHtml(String html) {
    setHtml(html);
  }

  @override
  set value(TextEditingValue newValue) {
    final oldValue = value;
    
    if (oldValue.text != newValue.text) {
      _updateStyleRanges(oldValue, newValue);
      
      // If typing insertion (1 character added), propagate activeStyles
      if (newValue.text.length == oldValue.text.length + 1 &&
          newValue.selection.isCollapsed &&
          oldValue.selection.isCollapsed) {
        final insertedIndex = oldValue.selection.start;
        for (final type in activeStyles) {
          _addStyleToRange(insertedIndex, insertedIndex + 1, type);
        }
      }
    }
    
    super.value = newValue;
    
    if (newValue.selection.isCollapsed) {
      _updateActiveStylesForCursor(newValue.selection.start);
    }
  }

  void _updateStyleRanges(TextEditingValue oldValue, TextEditingValue newValue) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    
    if (oldText == newText) return;
    
    // Find common prefix
    int prefixLen = 0;
    while (prefixLen < oldText.length && 
           prefixLen < newText.length && 
           oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }
    
    // Find common suffix
    int suffixLen = 0;
    while (suffixLen < oldText.length - prefixLen && 
           suffixLen < newText.length - prefixLen && 
           oldText[oldText.length - 1 - suffixLen] == newText[newText.length - 1 - suffixLen]) {
      suffixLen++;
    }
    
    final int replacedStart = prefixLen;
    final int replacedEnd = oldText.length - suffixLen;
    final int replacedLen = replacedEnd - replacedStart;
    final int insertedLen = newText.length - prefixLen - suffixLen;
    
    final newRanges = <StyleRange>[];
    for (final range in styleRanges) {
      int start = range.start;
      int end = range.end;
      
      if (end <= replacedStart) {
        newRanges.add(range);
      } else if (start >= replacedEnd) {
        newRanges.add(range.copyWith(
          start: start - replacedLen + insertedLen,
          end: end - replacedLen + insertedLen,
        ));
      } else {
        if (start > replacedStart) {
          start = replacedStart + insertedLen;
        }
        if (end >= replacedEnd) {
          end = end - replacedLen + insertedLen;
        } else if (end > replacedStart) {
          end = replacedStart;
        }
        if (start < end) {
          newRanges.add(range.copyWith(start: start, end: end));
        }
      }
    }
    styleRanges = newRanges;
  }

  void _addStyleToRange(int start, int end, StyleType type) {
    final newRange = StyleRange(start: start, end: end, type: type);
    styleRanges.add(newRange);
    _mergeRanges(type);
  }

  void _mergeRanges(StyleType type) {
    final typeRanges = styleRanges.where((r) => r.type == type).toList();
    if (typeRanges.length <= 1) return;
    
    typeRanges.sort((a, b) => a.start.compareTo(b.start));
    
    final merged = <StyleRange>[];
    StyleRange current = typeRanges[0];
    
    for (int i = 1; i < typeRanges.length; i++) {
      final next = typeRanges[i];
      if (next.start <= current.end) {
        if (next.end > current.end) {
          current.end = next.end;
        }
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    
    styleRanges.removeWhere((r) => r.type == type);
    styleRanges.addAll(merged);
  }

  void _updateActiveStylesForCursor(int cursorIndex) {
    activeStyles.clear();
    for (final range in styleRanges) {
      if (cursorIndex > range.start && cursorIndex <= range.end) {
        activeStyles.add(range.type);
      }
    }
  }

  void toggleStyle(StyleType type) {
    final selection = this.selection;
    if (selection.start < 0 || selection.end < 0) return;
    
    if (selection.isCollapsed) {
      if (activeStyles.contains(type)) {
        activeStyles.remove(type);
      } else {
        activeStyles.add(type);
      }
      notifyListeners();
    } else {
      _toggleStyleForRange(selection.start, selection.end, type);
    }
  }

  void _toggleStyleForRange(int selStart, int selEnd, StyleType type) {
    bool isFullyApplied = false;
    for (final range in styleRanges) {
      if (range.type == type && range.start <= selStart && range.end >= selEnd) {
        isFullyApplied = true;
        break;
      }
    }
    
    if (isFullyApplied) {
      final newRanges = <StyleRange>[];
      for (final range in styleRanges) {
        if (range.type != type) {
          newRanges.add(range);
          continue;
        }
        
        if (range.end <= selStart || range.start >= selEnd) {
          newRanges.add(range);
        } else if (range.start < selStart && range.end > selEnd) {
          newRanges.add(StyleRange(start: range.start, end: selStart, type: type));
          newRanges.add(StyleRange(start: selEnd, end: range.end, type: type));
        } else if (range.start < selStart && range.end <= selEnd) {
          newRanges.add(StyleRange(start: range.start, end: selStart, type: type));
        } else if (range.start >= selStart && range.end > selEnd) {
          newRanges.add(StyleRange(start: selEnd, end: range.end, type: type));
        }
      }
      styleRanges = newRanges;
    } else {
      _addStyleToRange(selStart, selEnd, type);
    }
    notifyListeners();
  }

  void setLineAlignment(String align) {
    final selection = this.selection;
    if (selection.start < 0 || selection.end < 0) return;
    
    final txt = text;
    int lineStart = selection.start;
    while (lineStart > 0 && txt[lineStart - 1] != '\n') {
      lineStart--;
    }
    
    int lineEnd = selection.end;
    while (lineEnd < txt.length && txt[lineEnd] != '\n') {
      lineEnd++;
    }
    
    final alignments = {StyleType.left, StyleType.center, StyleType.right};
    styleRanges.removeWhere((r) => alignments.contains(r.type) && 
        !(r.end <= lineStart || r.start >= lineEnd));
        
    if (align == 'center') {
      _addStyleToRange(lineStart, lineEnd, StyleType.center);
    } else if (align == 'right') {
      _addStyleToRange(lineStart, lineEnd, StyleType.right);
    }
    
    notifyListeners();
  }

  void cycleTextSize() {
    final selection = this.selection;
    if (selection.start < 0 || selection.end < 0) return;
    
    if (selection.isCollapsed) {
      if (activeStyles.contains(StyleType.large)) {
        activeStyles.remove(StyleType.large);
        activeStyles.add(StyleType.small);
      } else if (activeStyles.contains(StyleType.small)) {
        activeStyles.remove(StyleType.small);
      } else {
        activeStyles.add(StyleType.large);
      }
      notifyListeners();
    } else {
      final start = selection.start;
      final end = selection.end;
      
      bool isLarge = false;
      bool isSmall = false;
      for (final range in styleRanges) {
        if (range.start <= start && range.end >= end) {
          if (range.type == StyleType.large) isLarge = true;
          if (range.type == StyleType.small) isSmall = true;
        }
      }
      
      final sizes = {StyleType.large, StyleType.small};
      styleRanges.removeWhere((r) => sizes.contains(r.type) && 
          !(r.end <= start || r.start >= end));
          
      if (isLarge) {
        _addStyleToRange(start, end, StyleType.small);
      } else if (isSmall) {
        // regular
      } else {
        _addStyleToRange(start, end, StyleType.large);
      }
      notifyListeners();
    }
  }

  void setHtml(String html) {
    final cleanText = StringBuffer();
    final ranges = <StyleRange>[];
    final activeStack = <Map<String, dynamic>>[];
    
    final tagExp = RegExp(r'<(/?[a-zA-Z]+)>');
    int lastMatchEnd = 0;
    
    for (final match in tagExp.allMatches(html)) {
      if (match.start > lastMatchEnd) {
        cleanText.write(html.substring(lastMatchEnd, match.start));
      }
      
      final tag = match.group(1)!.toLowerCase();
      if (tag.startsWith('/')) {
        final typeStr = tag.substring(1);
        final type = _getStyleType(typeStr);
        if (type != null) {
          int matchIdx = -1;
          for (int i = activeStack.length - 1; i >= 0; i--) {
            if (activeStack[i]['type'] == type) {
              matchIdx = i;
              break;
            }
          }
          if (matchIdx != -1) {
            final openTag = activeStack.removeAt(matchIdx);
            ranges.add(StyleRange(
              start: openTag['start'],
              end: cleanText.length,
              type: type,
            ));
          }
        }
      } else {
        final type = _getStyleType(tag);
        if (type != null) {
          activeStack.add({
            'type': type,
            'start': cleanText.length,
          });
        }
      }
      
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < html.length) {
      cleanText.write(html.substring(lastMatchEnd));
    }
    
    for (final openTag in activeStack) {
      ranges.add(StyleRange(
        start: openTag['start'],
        end: cleanText.length,
        type: openTag['type'],
      ));
    }
    
    value = TextEditingValue(
      text: cleanText.toString(),
      selection: TextSelection.collapsed(offset: cleanText.length),
    );
    styleRanges = ranges;
  }

  StyleType? _getStyleType(String tag) {
    switch (tag) {
      case 'b': return StyleType.bold;
      case 'i': return StyleType.italic;
      case 'u': return StyleType.underline;
      case 'large': return StyleType.large;
      case 'small': return StyleType.small;
      case 'center': return StyleType.center;
      case 'left': return StyleType.left;
      case 'right': return StyleType.right;
      default: return null;
    }
  }

  String toHtml() {
    final buffer = StringBuffer();
    final openRanges = <StyleRange>[];
    
    final sortedRanges = List<StyleRange>.from(styleRanges);
    
    for (int i = 0; i <= text.length; i++) {
      final ending = openRanges.where((r) => r.end == i).toList();
      if (ending.isNotEmpty) {
        final toReopen = <StyleRange>[];
        while (openRanges.isNotEmpty) {
          final r = openRanges.removeLast();
          buffer.write(_closeTag(r.type));
          if (r.end == i) {
            // ends here
          } else {
            toReopen.add(r);
          }
        }
        for (final r in toReopen.reversed) {
          buffer.write(_openTag(r.type));
          openRanges.add(r);
        }
      }
      
      final starting = sortedRanges.where((r) => r.start == i).toList();
      starting.sort((a, b) => _typePriority(a.type).compareTo(_typePriority(b.type)));
      for (final r in starting) {
        buffer.write(_openTag(r.type));
        openRanges.add(r);
      }
      
      if (i < text.length) {
        buffer.write(text[i]);
      }
    }
    
    return buffer.toString();
  }

  String _openTag(StyleType type) {
    switch (type) {
      case StyleType.bold: return '<b>';
      case StyleType.italic: return '<i>';
      case StyleType.underline: return '<u>';
      case StyleType.large: return '<large>';
      case StyleType.small: return '<small>';
      case StyleType.center: return '<center>';
      case StyleType.left: return '<left>';
      case StyleType.right: return '<right>';
    }
  }

  String _closeTag(StyleType type) {
    switch (type) {
      case StyleType.bold: return '</b>';
      case StyleType.italic: return '</i>';
      case StyleType.underline: return '</u>';
      case StyleType.large: return '</large>';
      case StyleType.small: return '</small>';
      case StyleType.center: return '</center>';
      case StyleType.left: return '</left>';
      case StyleType.right: return '</right>';
    }
  }

  int _typePriority(StyleType type) {
    if (type == StyleType.center || type == StyleType.left || type == StyleType.right) return 0;
    if (type == StyleType.large || type == StyleType.small) return 1;
    return 2;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    if (styleRanges.isEmpty || text.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }
    
    final List<TextSpan> children = [];
    final boundaries = <int>{0, text.length};
    for (final range in styleRanges) {
      if (range.start >= 0 && range.start <= text.length) {
        boundaries.add(range.start);
      }
      if (range.end >= 0 && range.end <= text.length) {
        boundaries.add(range.end);
      }
    }
    
    final sortedBoundaries = boundaries.toList()..sort();
    
    for (int i = 0; i < sortedBoundaries.length - 1; i++) {
      final start = sortedBoundaries[i];
      final end = sortedBoundaries[i + 1];
      if (start == end) continue;
      
      final segmentText = text.substring(start, end);
      TextStyle segmentStyle = baseStyle;
      
      for (final range in styleRanges) {
        if (range.start <= start && range.end >= end) {
          switch (range.type) {
            case StyleType.bold:
              segmentStyle = segmentStyle.copyWith(fontWeight: FontWeight.bold);
              break;
            case StyleType.italic:
              segmentStyle = segmentStyle.copyWith(fontStyle: FontStyle.italic);
              break;
            case StyleType.underline:
              segmentStyle = segmentStyle.copyWith(decoration: TextDecoration.underline);
              break;
            case StyleType.large:
              segmentStyle = segmentStyle.copyWith(fontSize: (segmentStyle.fontSize ?? 14) * 1.3);
              break;
            case StyleType.small:
              segmentStyle = segmentStyle.copyWith(fontSize: (segmentStyle.fontSize ?? 14) * 0.85);
              break;
            default:
              break;
          }
        }
      }
      
      children.add(TextSpan(text: segmentText, style: segmentStyle));
    }
    
    return TextSpan(children: children, style: baseStyle);
  }
}

