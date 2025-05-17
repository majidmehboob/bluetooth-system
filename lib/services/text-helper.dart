import 'package:flutter/material.dart';

class TextFormatHelper {
  static Color getStatusClass(String status) {
    print(status);
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'upcoming':
        return Colors.orange;
      case 'ongoing':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static String getStatusText(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'pending':
        return 'Pending';
      default:
        return 'No Marking';
    }
  }

  static Color getAvatarColor(int index) {
    return index % 2 == 0 ? const Color(0xFF6A7D94) : const Color(0xFF293646);
  }

  static Widget formatCourseNameWithBreaks(
    String courseName, {
    TextStyle? style,
    TextAlign textAlign = TextAlign.start,
    double letterSpacing = 2,
    // Default letter spacing for second word
  }) {
    final words = courseName.split(' ');
    final hasSpace = words.length > 1;

    if (hasSpace) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            words.asMap().entries.map((entry) {
              final index = entry.key;
              final word = entry.value;

              // Apply letter spacing only to the second word (index 1)
              final wordStyle =
                  index == 1
                      ? style?.copyWith(
                            letterSpacing: letterSpacing,
                            fontSize: 20,
                          ) ??
                          TextStyle(letterSpacing: letterSpacing)
                      : style;

              return Text(word, style: wordStyle, textAlign: textAlign);
            }).toList(),
      );
    } else {
      return Text(courseName, style: style, textAlign: textAlign);
    }
  }
}
