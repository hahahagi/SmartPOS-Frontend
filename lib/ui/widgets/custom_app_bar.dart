import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.showLogoutButton = true,
    this.actions,
    this.showUserInfo = true,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final bool showLogoutButton;
  final List<Widget>? actions;
  final bool showUserInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isOnline = ref
        .watch(connectivityStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          if (showUserInfo && subtitle == null)
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${authState.roleLabel}: ${authState.user?.name ?? '-'}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
        ],
      ),
      actions: [
        Center(child: _ConnectionIndicator(isOnline: isOnline)),
        const SizedBox(width: 8),
        if (actions != null) ...actions!,
        if (showLogoutButton)
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _showLogoutConfirmation(context, ref),
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(authNotifierProvider.notifier).logout();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
