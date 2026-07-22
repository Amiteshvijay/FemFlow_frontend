import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';

class PostContentWidget extends StatelessWidget {
  final String content;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const PostContentWidget({
    super.key,
    required this.content,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle(
      fontSize: 14,
      color: FemLyraColors.textPrimary,
      height: 1.5,
    );

    final lines = content.split('\n');
    final children = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        // Render a blank line
        children.add(const SizedBox(height: 8));
        continue;
      }

      TextAlign align = TextAlign.left;
      String cleanLine = line;

      final trimmed = line.trim();
      if (trimmed.startsWith('<center>') && trimmed.endsWith('</center>')) {
        align = TextAlign.center;
        final idxStart = line.indexOf('<center>');
        final idxEnd = line.lastIndexOf('</center>');
        cleanLine = line.substring(idxStart + 8, idxEnd);
      } else if (trimmed.startsWith('<right>') && trimmed.endsWith('</right>')) {
        align = TextAlign.right;
        final idxStart = line.indexOf('<right>');
        final idxEnd = line.lastIndexOf('</right>');
        cleanLine = line.substring(idxStart + 7, idxEnd);
      } else if (trimmed.startsWith('<left>') && trimmed.endsWith('</left>')) {
        align = TextAlign.left;
        final idxStart = line.indexOf('<left>');
        final idxEnd = line.lastIndexOf('</left>');
        cleanLine = line.substring(idxStart + 6, idxEnd);
      }

      children.add(
        Align(
          alignment: align == TextAlign.center
              ? Alignment.center
              : align == TextAlign.right
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
          child: RichText(
            textAlign: align,
            maxLines: maxLines,
            overflow: overflow ?? TextOverflow.clip,
            text: TextSpan(
              children: _parseInlineText(cleanLine, baseStyle),
            ),
          ),
        ),
      );

      if (i < lines.length - 1) {
        children.add(const SizedBox(height: 4));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  List<InlineSpan> _parseInlineText(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    
    // Pattern to split tags and non-tags safely and support nesting
    final RegExp exp = RegExp(
      r'(<b>(.*?)</b>|<i>(.*?)</i>|<u>(.*?)</u>|<large>(.*?)</large>|<small>(.*?)</small>|[^<]+|<)',
      dotAll: true,
    );

    final matches = exp.allMatches(text);
    for (final match in matches) {
      final full = match.group(0)!;

      if (full.startsWith('<b>') && full.endsWith('</b>')) {
        final inner = match.group(2) ?? '';
        spans.addAll(_parseInlineText(inner, baseStyle.copyWith(fontWeight: FontWeight.bold)));
      } else if (full.startsWith('<i>') && full.endsWith('</i>')) {
        final inner = match.group(3) ?? '';
        spans.addAll(_parseInlineText(inner, baseStyle.copyWith(fontStyle: FontStyle.italic)));
      } else if (full.startsWith('<u>') && full.endsWith('</u>')) {
        final inner = match.group(4) ?? '';
        spans.addAll(_parseInlineText(inner, baseStyle.copyWith(decoration: TextDecoration.underline)));
      } else if (full.startsWith('<large>') && full.endsWith('</large>')) {
        final inner = match.group(5) ?? '';
        spans.addAll(_parseInlineText(inner, baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) * 1.3)));
      } else if (full.startsWith('<small>') && full.endsWith('</small>')) {
        final inner = match.group(6) ?? '';
        spans.addAll(_parseInlineText(inner, baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) * 0.85)));
      } else {
        // Plain text or unclosed tag fragment
        spans.add(TextSpan(text: full, style: baseStyle));
      }
    }

    if (spans.isEmpty && text.isNotEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }
    return spans;
  }
}
