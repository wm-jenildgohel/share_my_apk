// ignore_for_file: avoid_print
import 'dart:io';

/// Utility for interactive CLI prompts
class PromptUtil {
  /// Asks a yes/no question and returns the user's response
  ///
  /// [question] - The question to ask
  /// [defaultValue] - The default value if user presses enter (optional)
  ///
  /// Returns true for yes, false for no
  static bool askYesNo(String question, {bool? defaultValue}) {
    final defaultText = defaultValue == null
        ? '(y/n)'
        : defaultValue
        ? '(Y/n)'
        : '(y/N)';

    while (true) {
      stdout.write('$question $defaultText: ');
      final input = stdin.readLineSync()?.trim().toLowerCase();

      if (input == null || input.isEmpty) {
        if (defaultValue != null) {
          return defaultValue;
        }
        continue;
      }

      if (input == 'y' || input == 'yes') {
        return true;
      } else if (input == 'n' || input == 'no') {
        return false;
      }

      print('Please answer with y (yes) or n (no)');
    }
  }

  /// Asks user to select from multiple choices
  ///
  /// [question] - The question to ask
  /// [choices] - List of choices
  /// [defaultIndex] - Default choice index (optional)
  ///
  /// Returns the index of the selected choice
  static int askChoice(
    String question,
    List<String> choices, {
    int? defaultIndex,
  }) {
    print('\n$question');
    for (int i = 0; i < choices.length; i++) {
      final isDefault = defaultIndex == i;
      final marker = isDefault ? '→' : ' ';
      print('  $marker ${i + 1}. ${choices[i]}');
    }

    while (true) {
      final defaultText = defaultIndex != null ? ' [${defaultIndex + 1}]' : '';
      stdout.write('\nSelect option (1-${choices.length})$defaultText: ');

      final input = stdin.readLineSync()?.trim();

      if (input == null || input.isEmpty) {
        if (defaultIndex != null) {
          return defaultIndex;
        }
        continue;
      }

      final choice = int.tryParse(input);
      if (choice != null && choice >= 1 && choice <= choices.length) {
        return choice - 1;
      }

      print(
        'Invalid choice. Please enter a number between 1 and ${choices.length}',
      );
    }
  }

  /// Prompts for text input
  ///
  /// [question] - The question to ask
  /// [defaultValue] - Default value if user presses enter (optional)
  /// [allowEmpty] - Whether empty input is allowed
  ///
  /// Returns the user's input
  static String askText(
    String question, {
    String? defaultValue,
    bool allowEmpty = false,
  }) {
    final defaultText = defaultValue != null ? ' [$defaultValue]' : '';

    while (true) {
      stdout.write('$question$defaultText: ');
      final input = stdin.readLineSync()?.trim();

      if (input == null || input.isEmpty) {
        if (defaultValue != null) {
          return defaultValue;
        }
        if (allowEmpty) {
          return '';
        }
        print('This field cannot be empty');
        continue;
      }

      return input;
    }
  }

  /// Prompts for Firebase configuration
  ///
  /// Returns a map with Firebase configuration details
  static Map<String, dynamic> promptForFirebaseConfig() {
    print('\n📱 Firebase App Distribution Setup');
    print('════════════════════════════════════════════════════════════');
    print('You\'ll need:');
    print('  • Firebase Project ID (from Firebase Console)');
    print('  • Android App ID (format: 1:123456789:android:abcdef)');
    print('═══════════════════════════════════════════════════════════\n');

    final projectId = askText('🔑 Firebase Project ID', allowEmpty: false);

    final appId = askText('📱 Firebase App ID', allowEmpty: false);

    final serviceAccountPath = askText(
      '🔐 Service Account JSON path (optional, press Enter to skip)',
      allowEmpty: true,
    );

    final releaseNotes = askText(
      '📝 Release notes (optional)',
      allowEmpty: true,
    );

    print('\n👥 Add testers (optional):');
    final testers = <String>[];
    while (true) {
      final email = askText(
        '  Email (or press Enter to finish)',
        allowEmpty: true,
      );
      if (email.isEmpty) break;
      testers.add(email);
      print('  ✓ Added: $email');
    }

    print('\n👥 Which groups should receive this release? (optional)');
    final groups = <String>[];
    while (true) {
      final group = askText(
        '  Enter group name (e.g. "qa-team" or press Enter to finish)',
        allowEmpty: true,
      );
      if (group.isEmpty) break;
      groups.add(group);
      print('  ✓ Will distribute to: $group');
    }

    final saveConfig = askYesNo(
      '\n💾 Save this configuration for future use?',
      defaultValue: true,
    );

    return {
      'projectId': projectId,
      'appId': appId,
      'serviceAccountPath': serviceAccountPath.isEmpty
          ? null
          : serviceAccountPath,
      'releaseNotes': releaseNotes.isEmpty ? null : releaseNotes,
      'testers': testers.isEmpty ? null : testers,
      'groups': groups.isEmpty ? null : groups,
      'saveConfig': saveConfig,
    };
  }
}
