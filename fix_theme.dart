import 'dart:io';

void main() {
  final replacements = {
    '.body1': '.bodyLarge',
    '.body2': '.bodyMedium',
    '.caption': '.bodySmall',
    '.title': '.titleLarge',
    '.subhead': '.titleMedium',
    '.button': '.labelLarge',
    'accentColor': 'colorScheme.secondary',
    'accentIconTheme': 'iconTheme',
    'buttonColor': 'colorScheme.primary',
    'bottomAppBarColor': 'colorScheme.surface',
    'textSelectionHandleColor': 'colorScheme.primary',
    'FlatButton': 'TextButton',
    'RaisedButton': 'ElevatedButton',
    'resizeToAvoidBottomPadding': 'resizeToAvoidBottomInset',
  };

  final libDir = Directory('lib');
  if (libDir.existsSync()) {
    libDir.listSync(recursive: true).forEach((file) {
      if (file is File && file.path.endsWith('.dart')) {
        String content = file.readAsStringSync();
        bool changed = false;

        replacements.forEach((old, newStr) {
          if (content.contains(old)) {
            content = content.replaceAll(old, newStr);
            changed = true;
          }
        });

        if (changed) {
          file.writeAsStringSync(content);
          print('Updated: ${file.path}');
        }
      }
    });
  }
}
