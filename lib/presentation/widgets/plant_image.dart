import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PlantImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? height;
  final double? width;

  const PlantImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null) return _placeholder();

    if (!url!.startsWith('http')) {
      return Image.file(
        File(url!),
        fit: fit,
        height: height,
        width: width,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      height: height,
      width: width,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    height: height,
    width: width,
    color: AppColors.accent,
    child: const Icon(Icons.eco, size: 48, color: AppColors.primary),
  );
}
