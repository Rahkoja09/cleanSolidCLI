import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

class AddWidgetCommand extends Command {
  static const _templates = [
    'loading',
    'app-bar',
    'error-view',
    'empty-state',
    'text-field',
    'button',
    'card',
    'dialog',
    'image',
  ];

  @override
  String name = 'add:widget';

  @override
  String description =
      'Génère un widget partagé réutilisable dans lib/shared/widgets/';

  AddWidgetCommand() {
    argParser.addOption(
      'type',
      abbr: 't',
      help: 'Template prédéfini (${_templates.join(", ")})',
    );
  }

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? [];
    final widgetName = rest.isNotEmpty ? rest.first : null;
    final type = argResults?['type'] as String?;

    if (widgetName == null) {
      print('  Usage: cscm add:widget <nom> [--type <template>]');
      print('');
      print('  Templates disponibles :');
      for (final t in _templates) {
        print('    $t');
      }
      print('');
      print('  Exemples :');
      print('    cscm add:widget loading');
      print('    cscm add:widget mon-champ --type text-field');
      print('    cscm add:widget confirm-dialog --type dialog');
      return;
    }
    // Validation anti path traversal
    if (widgetName.contains('..') ||
        widgetName.contains('/') ||
        widgetName.contains('\\')) {
      print('  Erreur : Le nom du widget contient des caractères interdits.');
      return;
    }

    final className = _toPascalCase(widgetName);
    final fileName = _toSnakeCase(widgetName);
    final dir = Directory('lib/shared/widgets');

    if (!dir.existsSync()) dir.createSync(recursive: true);

    final filePath = p.join(dir.path, '$fileName.dart');
    if (File(filePath).existsSync()) {
      print('  Widget "$fileName" existe déjà.');
      return;
    }

    final templateKey = type ?? _autoDetect(widgetName);
    final content = _render(templateKey, className);

    File(filePath).writeAsStringSync(content);
    _updateBarrel(fileName);

    print('  Widget généré : $fileName.dart (template: $templateKey)');
  }

  // ═══════════════════════════════════════════════════
  // AUTO-DETECT
  // ═══════════════════════════════════════════════════

  String _autoDetect(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('loading') ||
        lower.contains('spinner') ||
        lower.contains('progress'))
      return 'loading';
    if (lower.contains('app') && lower.contains('bar')) return 'app-bar';
    if (lower.contains('error')) return 'error-view';
    if (lower.contains('empty')) return 'empty-state';
    if (lower.contains('text') && lower.contains('field')) return 'text-field';
    if (lower.contains('button') || lower.contains('btn')) return 'button';
    if (lower.contains('card')) return 'card';
    if (lower.contains('dialog') || lower.contains('alert')) return 'dialog';
    if (lower.contains('image') || lower.contains('avatar')) return 'image';
    return 'skeleton';
  }

  // ═══════════════════════════════════════════════════
  // BARREL EXPORT
  // ═══════════════════════════════════════════════════

  void _updateBarrel(String fileName) {
    final barrelPath = 'lib/shared/widgets/widgets.dart';
    final barrel = File(barrelPath);
    if (!barrel.existsSync()) {
      barrel.createSync(recursive: true);
      barrel.writeAsStringSync('// Shared widgets barrel export\n');
    }
    final content = barrel.readAsStringSync();
    final exportLine = "export '$fileName.dart';";
    if (!content.contains(exportLine)) {
      barrel.writeAsStringSync('$content\n$exportLine');
    }
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════

  String _toPascalCase(String input) {
    return input
        .split(RegExp(r'[_\-\s]+'))
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join();
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')
        .replaceAll(RegExp(r'[-\s]+'), '_')
        .replaceAll(RegExp(r'^_+'), '');
  }

  String _render(String template, String className) {
    switch (template) {
      case 'loading':
        return _loading(className);
      case 'app-bar':
        return _appBar(className);
      case 'error-view':
        return _errorView(className);
      case 'empty-state':
        return _emptyState(className);
      case 'text-field':
        return _textField(className);
      case 'button':
        return _button(className);
      case 'card':
        return _card(className);
      case 'dialog':
        return _dialog(className);
      case 'image':
        return _image(className);
      default:
        return _skeleton(className);
    }
  }

  // ═══════════════════════════════════════════════════
  // TEMPLATES
  // ═══════════════════════════════════════════════════

  String _loading(String c) => '''import 'package:flutter/material.dart';

class $c extends StatelessWidget {
  final double? size;
  final Color? color;

  const $c({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size ?? 24,
        height: size ?? 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}''';

  String _appBar(String c) => '''import 'package:flutter/material.dart';

class $c extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBackPressed;

  const $c({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: showBack,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}''';

  String _errorView(String c) => '''import 'package:flutter/material.dart';

class $c extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const $c({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}''';

  String _emptyState(String c) => '''import 'package:flutter/material.dart';

class $c extends StatelessWidget {
  final String? message;
  final IconData? icon;
  final Widget? action;

  const $c({super.key, this.message, this.icon, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message ?? 'Aucune donnée disponible',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}''';

  String _textField(String c) => '''import 'package:flutter/material.dart';

class $c extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;

  const $c({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }
}''';

  String _button(String c) => '''import 'package:flutter/material.dart';

class $c extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;

  const $c({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final loader = const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon != null ? (isLoading ? loader : Icon(icon)) : null,
        label: isLoading ? loader : Text(label),
      );
    }

    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: icon != null ? (isLoading ? loader : Icon(icon)) : null,
      label: isLoading ? loader : Text(label),
    );
  }
}''';

  String _card(String c) => '''import 'package:flutter/material.dart';

class $c extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;

  const $c({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation,
      color: color,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}''';

  String _dialog(String c) => '''import 'package:flutter/material.dart';

class $c extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool destructive;

  const $c({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirmer',
    this.cancelLabel = 'Annuler',
    this.onConfirm,
    this.onCancel,
    this.destructive = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => $c(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      content: message != null ? Text(message!) : null,
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: theme.colorScheme.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}''';

  String _image(String c) => '''import 'package:flutter/material.dart';

class $c extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const $c({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      ),
    );
  }
}''';

  String _skeleton(String c) => '''import 'package:flutter/material.dart';

class $c extends StatelessWidget {
  const $c({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}''';
}
