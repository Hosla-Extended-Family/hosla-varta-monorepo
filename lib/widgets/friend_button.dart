import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/providers/friendship_status_provider.dart';

/// Relationship status between the current user and another user.
enum FriendshipState { self, friend, outgoing, incoming, none, loading }

/// A reusable, state-driven Add Friend button inspired by Instagram's Follow
/// button. It shows the correct label & style based on the current friendship
/// status and handles optimistic UI updates.
///
/// Button states:
///  - `Add Friend`   → default (no relationship)
///  - `Request Sent` → after sending a request (outgoing pending)
///  - `Friends`      → after acceptance
///  - accept/reject  → when the current user received a pending request
///  - hidden         → when viewing own profile
class FriendButton extends ConsumerWidget {
  /// The user ID of the profile being viewed (NOT the current user).
  final String targetUserId;

  /// Compact mode – used inside the post header for a smaller footprint.
  final bool compact;

  const FriendButton({
    super.key,
    required this.targetUserId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(friendshipStatusProvider(targetUserId));

    return statusAsync.when(
      data: (status) => _buildButton(context, ref, status),
      loading: () => _loadingPill(context),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── Builders ──────────────────────────────────────────────────────

  Widget _buildButton(
    BuildContext context,
    WidgetRef ref,
    FriendshipStatusState status,
  ) {
    switch (status.state) {
      case FriendshipState.self:
        return const SizedBox.shrink();

      case FriendshipState.loading:
        return _loadingPill(context);

      case FriendshipState.none:
        return _AddFriendPill(
          compact: compact,
          onTap: () => ref
              .read(friendshipStatusProvider(targetUserId).notifier)
              .sendRequest(),
        );

      case FriendshipState.outgoing:
        // TODO: Integrate remove friend request API in future build
        // Once the cancel/remove request endpoint is available, re-enable
        // the onTap to call cancelRequest(). For now, disable to prevent
        // duplicate requests and clearly indicate the pending state.
        return _RequestSentPill(
          compact: compact,
          onTap: null, // Disabled until remove request API is integrated
        );

      case FriendshipState.incoming:
        if (compact) {
          return _AcceptPill(
            compact: true,
            onTap: () => ref
                .read(friendshipStatusProvider(targetUserId).notifier)
                .acceptRequest(),
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AcceptPill(
              compact: compact,
              onTap: () => ref
                  .read(friendshipStatusProvider(targetUserId).notifier)
                  .acceptRequest(),
            ),
            const SizedBox(width: 8),
            _RejectPill(
              compact: compact,
              onTap: () => ref
                  .read(friendshipStatusProvider(targetUserId).notifier)
                  .rejectRequest(),
            ),
          ],
        );

      case FriendshipState.friend:
        return _FriendsPill(
          compact: compact,
          onTap: () => _showUnfriendSheet(context, ref),
        );
    }
  }

  Widget _loadingPill(BuildContext context) {
    final h = compact ? 30.0 : 38.0;
    final w = compact ? 80.0 : 110.0;
    return SizedBox(
      height: h,
      width: w,
      child: Center(
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ThemeColors.primaryColor,
          ),
        ),
      ),
    );
  }

  void _showUnfriendSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getSurfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ThemeColors.getBorderColor(
                  context,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person_remove, color: ThemeColors.errorColor),
              title: Text(
                'Remove Friend',
                style: TextThemes.getBodyMediumStyle(
                  context,
                ).copyWith(color: ThemeColors.errorColor),
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(friendshipStatusProvider(targetUserId).notifier)
                    .removeFriend();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Private pill widgets ──────────────────────────────────────────

class _AddFriendPill extends StatelessWidget {
  final bool compact;
  final VoidCallback onTap;
  const _AddFriendPill({required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PillButton(
      label: compact ? 'Add' : 'Add Friend',
      icon: Icons.person_add_alt,
      filled: true,
      compact: compact,
      onTap: onTap,
    );
  }
}

class _RequestSentPill extends StatelessWidget {
  final bool compact;
  final VoidCallback? onTap;
  const _RequestSentPill({required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PillButton(
      label: compact ? 'Sent' : 'Request Sent',
      icon: Icons.hourglass_top_rounded,
      filled: false,
      compact: compact,
      onTap: onTap,
      muted: true,
    );
  }
}

class _AcceptPill extends StatelessWidget {
  final bool compact;
  final VoidCallback onTap;
  const _AcceptPill({required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PillButton(
      label: 'Accept',
      icon: Icons.check_rounded,
      filled: true,
      compact: compact,
      onTap: onTap,
    );
  }
}

class _RejectPill extends StatelessWidget {
  final bool compact;
  final VoidCallback onTap;
  const _RejectPill({required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PillButton(
      label: 'Reject',
      icon: Icons.close_rounded,
      filled: false,
      compact: compact,
      onTap: onTap,
    );
  }
}

class _FriendsPill extends StatelessWidget {
  final bool compact;
  final VoidCallback onTap;
  const _FriendsPill({required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PillButton(
      label: 'Friends',
      icon: Icons.check_circle_outline_rounded,
      filled: false,
      compact: compact,
      onTap: onTap,
      accentColor: ThemeColors.successColor,
    );
  }
}

// ── Generic pill ────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool compact;
  final bool muted;
  final VoidCallback? onTap;
  final Color? accentColor;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.compact,
    required this.onTap,
    this.muted = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = accentColor ?? ThemeColors.primaryColor;
    final isDisabled = onTap == null;

    final bgColor = isDisabled
        ? ThemeColors.getSurfaceColor(context)
        : filled
        ? primary
        : (muted ? ThemeColors.getSurfaceColor(context) : Colors.transparent);
    final fgColor = isDisabled
        ? ThemeColors.getSecondaryTextColor(context).withValues(alpha: 0.6)
        : filled
        ? Colors.black
        : (muted ? ThemeColors.getSecondaryTextColor(context) : primary);
    final borderColor = isDisabled
        ? ThemeColors.getBorderColor(context).withValues(alpha: 0.3)
        : filled
        ? Colors.transparent
        : (muted
              ? ThemeColors.getBorderColor(context).withValues(alpha: 0.4)
              : primary.withValues(alpha: 0.6));

    final vPad = compact ? 6.0 : 10.0;
    final hPad = compact ? 12.0 : 18.0;
    final fontSize = compact ? 12.0 : 14.0;
    final iconSize = compact ? 14.0 : 18.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: filled && !isDisabled
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: fgColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
