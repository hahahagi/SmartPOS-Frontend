import 'package:flutter/material.dart';

import '../../config/colors.dart';

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.lightGray,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.primaryBlue,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
