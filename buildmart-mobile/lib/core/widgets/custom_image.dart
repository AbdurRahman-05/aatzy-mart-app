import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class BuildMartImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const BuildMartImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty) {
      return _buildPlaceholder();
    }

    if (cleanUrl.startsWith('data:image')) {
      try {
        final base64String = cleanUrl.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }

    if (cleanUrl.startsWith('assets/')) {
      return Image.asset(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    // Try local file path
    try {
      final file = File(cleanUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    } catch (_) {}

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return placeholder ?? Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
}
