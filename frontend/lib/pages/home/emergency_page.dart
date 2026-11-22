import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/providers/feed_provider.dart';
import 'package:hosla/services/emergency_service.dart';
import 'package:hosla/widgets/glass_app_bar.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

class EmergencyPage extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const EmergencyPage({super.key, this.onSuccess});

  @override
  ConsumerState<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends ConsumerState<EmergencyPage> {
  bool _isLoading = false;

  Future<void> _handleContactHosla() async {
    if (_isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ConfirmationDialog(),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final result = await EmergencyService.instance.logEmergency(
      EmergencyType.hosla,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      SnackBarWidget.success(context, 'Emergency request sent successfully');
      ref.read(feedPostsProvider.notifier).refreshPosts();
      widget.onSuccess?.call();
    } else {
      SnackBarWidget.error(
        context,
        result.errorMessage ??
            'Unable to send emergency request. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        titleText: 'Emergency',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: Constants.defaultPadding.left,
          right: Constants.defaultPadding.right,
          bottom: Constants.defaultPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Need help?', style: TextThemes.getBodyLargeStyle(context)),
            const SizedBox(height: 10),
            Text(
              'If you\'re feeling unsafe or need immediate assistance, contact Hosla and our team will reach out to you.',
              style: TextThemes.getBodyMediumStyle(context),
            ),
            const SizedBox(height: 30),
            _ContactHoslaButton(
              isLoading: _isLoading,
              onPressed: _handleContactHosla,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactHoslaButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ContactHoslaButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeColors.primaryColor,
          foregroundColor: Colors.black,
          disabledBackgroundColor: ThemeColors.primaryColor.withValues(
            alpha: 0.5,
          ),
          disabledForegroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.support_agent_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Contact Hosla',
                    style: TextThemes.getButtonStyle(context),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ThemeColors.getSurfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: ThemeColors.errorColor,
        size: 40,
      ),
      title: Text(
        'Contact Hosla',
        textAlign: TextAlign.center,
        style: TextThemes.getBodyLargeStyle(context).copyWith(fontSize: 18),
      ),
      content: Text(
        'Are you sure you want to contact Hosla for emergency assistance?\n\nOnly use this for genuine emergencies.',
        textAlign: TextAlign.center,
        style: TextThemes.getBodyMediumStyle(
          context,
        ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: ThemeColors.getSecondaryTextColor(context),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Cancel',
            style: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeColors.errorColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Send',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
