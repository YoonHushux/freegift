import '../theme/glass_theme.dart';
import '../widgets/glass_container.dart';
import '../utils/responsive.dart';

/// Glass Button Widget with responsive sizing
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final double? borderRadius;
  final EdgeInsets? padding;
  final IconData? icon;
  final bool isResponsive;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.borderRadius,
    this.padding,
    this.icon,
    this.isResponsive = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveBorderRadius = isResponsive
        ? Responsive.borderRadius(context, mobile: borderRadius ?? 17, tablet: (borderRadius ?? 17) * 1.2, desktop: (borderRadius ?? 17) * 1.4)
        : borderRadius ?? 17;
    
    final responsivePadding = isResponsive
        ? Responsive.padding(
            context,
            mobile: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            tablet: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            desktop: padding ?? const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          )
        : padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        borderRadius: responsiveBorderRadius,
        padding: responsivePadding,
        backgroundColor: (color ?? GlassTheme.primary).withValues(alpha: 0.2),
        borderColor: (color ?? GlassTheme.primary).withValues(alpha: 0.4),
        isResponsive: isResponsive,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: textColor ?? GlassTheme.textPrimary,
                size: isResponsive 
                    ? Responsive.iconSize(context, mobile: 17, tablet: 20, desktop: 24)
                    : 17,
              ),
              SizedBox(
                width: isResponsive 
                    ? Responsive.spacing(context, mobile: 7, tablet: 8, desktop: 10)
                    : 7,
              ),
            ],
            Text(
              text,
              style: TextStyle(
                color: textColor ?? GlassTheme.textPrimary,
                fontSize: isResponsive 
                    ? Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18)
                    : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
