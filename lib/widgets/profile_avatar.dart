import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  final double iconSize;
  final Color backgroundColor;
  final Border? border;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.radius = 70,
    this.iconSize = 80,
    this.backgroundColor = Colors.black,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      if (photoUrl!.startsWith('http')) {
        image = Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            );
          },
        );
      } else if (photoUrl!.startsWith('assets/')) {
        image = Image.asset(
          photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading asset image: $photoUrl - $error');
            return _buildFallback();
          },
        );
      } else {
        image = _buildFallback();
      }
    } else {
      image = _buildFallback();
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: border,
      ),
      child: ClipOval(
        child: image,
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: backgroundColor,
      child: Icon(
        Icons.person_rounded,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

