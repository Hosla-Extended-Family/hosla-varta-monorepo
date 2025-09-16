import 'package:flutter/material.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/widgets/profile_pic.dart';

class PostWidget extends StatefulWidget {
  const PostWidget({super.key});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: Constants.defaultMargin.copyWith(bottom: 8, top: 8),
      padding: Constants.defaultPadding,
      decoration: BoxDecoration(
        color: ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.getOverlayColor(context, opacity: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: BoxConstraints(minWidth: double.infinity),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfilePic(
                radius: 25,
                imageUrl:
                    'https://static.vecteezy.com/system/resources/thumbnails/004/511/281/small/default-avatar-photo-placeholder-profile-picture-vector.jpg',
              ),
              Container(
                margin: const EdgeInsets.only(left: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hosla',
                      style: TextThemes.getBodyMediumStyle(context).copyWith(fontSize: 20),
                    ),
                    Text(
                      '2 hours ago',
                      style: TextThemes.getBodySmallStyle(context).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const text =
                  'This is a sample post content. It can be multiple lines long and should display properly within the post widget.';
              final span = TextSpan(text: text, style: TextThemes.getBodyMediumStyle(context));
              final tp = TextPainter(
                text: span,
                textDirection: TextDirection.ltr,
              );
              tp.layout(maxWidth: constraints.maxWidth);
              final exceedsMaxLines = tp.computeLineMetrics().length > 2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextThemes.getBodyMediumStyle(context),
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    maxLines: _isExpanded ? null : 2,
                  ),
                  if (exceedsMaxLines)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Text(
                        _isExpanded ? 'show less' : 'show more',
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          color: ThemeColors.getInfoColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: ['#Event']
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeColors.getInfoSurface(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ThemeColors.getInfoColor(context).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          color: ThemeColors.getInfoColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(
              minHeight: 200,
              maxHeight: 400,
              minWidth: double.infinity,
              maxWidth: double.infinity,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/Sample_image.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: ThemeColors.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ThemeColors.getBorderColor(context), width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: ThemeColors.getDisabledColor(context),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextThemes.getBodySmallStyle(context).copyWith(
                            color: ThemeColors.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.favorite_border,
                label: 'Like',
                onTap: () {
                  // TODO: Handle like action
                },
              ),
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: 'Comment',
                onTap: () {
                  // TODO: Handle comment action
                },
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () {
                  // TODO: Handle share action
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: ThemeColors.getSecondaryTextColor(context)),
          SizedBox(width: 4),
          Text(
            label,
            style: TextThemes.getBodySmallStyle(context).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
        ],
      ),
    );
  }
}
