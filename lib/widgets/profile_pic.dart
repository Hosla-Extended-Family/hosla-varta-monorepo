import 'package:flutter/material.dart';
import 'package:hosla/core/constants/api_constants.dart';

class ProfilePic extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final String? name;

  const ProfilePic({
    super.key,
    required this.imageUrl,
    this.radius = 40,
    this.name,
  });

  String _initials() {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConstants.resolveUrl(imageUrl);

    if (resolved == null || resolved.isEmpty) {
      final initials = _initials();
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.teal.shade300,
        child: initials == '?'
            ? Icon(Icons.person, size: radius, color: Colors.white)
            : Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(resolved),
      onBackgroundImageError: (_, __) {},
      backgroundColor: Colors.teal.shade300,
      child: null,
    );
  }
}
