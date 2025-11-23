import 'package:flutter/material.dart';

class AdminFeaturePlaceholder extends StatelessWidget {
  const AdminFeaturePlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(.1),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fitur admin dalam tahap implementasi',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey.shade600,
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
