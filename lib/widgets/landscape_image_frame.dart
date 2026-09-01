import 'dart:io';

import 'package:flutter/material.dart';

class LandscapeImageFrame extends StatelessWidget {
  const LandscapeImageFrame({
    super.key,
    this.imageUrl,
    this.filePath,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.quarterTurns = 0,
    this.onTap,
    this.placeholder,
  }) : assert(imageUrl != null || filePath != null || placeholder != null);

  final String? imageUrl;
  final String? filePath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final int quarterTurns;
  final VoidCallback? onTap;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5EBDD)),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: RotatedBox(
            quarterTurns: quarterTurns,
            child: _buildImage(),
          ),
        ),
      ),
    );

    final framed = SizedBox(width: width, height: height, child: content);
    if (onTap == null) return framed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: framed,
      ),
    );
  }

  Widget _buildImage() {
    if (filePath != null && filePath!.isNotEmpty) {
      return Image.file(File(filePath!), fit: fit);
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_outlined,
                color: Color(0xFF98A2B3), size: 34),
          );
        },
      );
    }

    return placeholder ??
        const Center(
          child: Icon(Icons.image_outlined, color: Color(0xFF98A2B3), size: 42),
        );
  }
}
