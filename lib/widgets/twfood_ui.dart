import 'package:flutter/material.dart';

/// Komponen visual bersama TWFOOD dengan bentuk rounded dan warna adaptif tema.
class TwfoodIconBadge extends StatelessWidget {
  const TwfoodIconBadge({super.key, required this.icon, this.color, this.size = 46, this.iconSize = 22});
  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: tint),
    );
  }
}

class TwfoodSectionHeading extends StatelessWidget {
  const TwfoodSectionHeading({super.key, required this.title, this.subtitle, this.actionLabel, this.onAction});
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: theme.textTheme.bodySmall)],
      ])),
      if (actionLabel != null && onAction != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ]);
  }
}

class TwfoodSurface extends StatelessWidget {
  const TwfoodSurface({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 20});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.75)),
      boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.035), blurRadius: 16, offset: const Offset(0, 5))],
    ),
    child: child,
  );
}
