import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? color;
  final BorderSide? border;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 16.0),
        border: border != null ? Border.fromBorderSide(border!) : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = backgroundColor ?? Theme.of(context).primaryColor;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: themeColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? borderColor;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = borderColor ?? Theme.of(context).primaryColor;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: primary),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final String type; // 'success', 'warning', 'info', 'danger'

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (type) {
      case 'success':
        bg = const Color(0xfff0fdf4);
        text = const Color(0xff16a34a);
        break;
      case 'warning':
        bg = const Color(0xfffffbeb);
        text = const Color(0xffd97706);
        break;
      case 'danger':
        bg = const Color(0xfffef2f2);
        text = const Color(0xffdc2626);
        break;
      case 'info':
      default:
        bg = const Color(0xffeff6ff);
        text = const Color(0xff2563eb);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.12), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xff1e293b)),
          ),
        ],
      ),
    );
  }
}
