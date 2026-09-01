import 'package:flutter/material.dart';

class DesktopActionDialog extends StatelessWidget {
  const DesktopActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.success,
  });

  final String title;
  final String message;
  final bool success;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    bool success = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: const Color(0xFF17212B).withOpacity(0.46),
      builder: (context) => DesktopActionDialog(
        title: title,
        message: message,
        success: success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = success ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final icon = success ? Icons.check_circle_outline : Icons.error_outline;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 20,
          shadowColor: Colors.black.withOpacity(0.14),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF7A8494),
                    splashRadius: 20,
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 32),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1D2B38),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF68777A),
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
