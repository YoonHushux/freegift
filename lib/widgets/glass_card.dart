import '../theme/glass_theme.dart';
import '../widgets/glass_container.dart';
import '../utils/responsive.dart';

/// Glass Card Widget with responsive sizing
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool isResponsive;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.isResponsive = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = isResponsive
        ? Responsive.padding(
            context,
            mobile: padding ?? const EdgeInsets.all(17),
            tablet: padding ?? const EdgeInsets.all(20),
            desktop: padding ?? const EdgeInsets.all(24),
          )
        : padding ?? const EdgeInsets.all(17);
    
    final responsiveBorderRadius = isResponsive
        ? Responsive.borderRadius(context, mobile: borderRadius ?? 20, tablet: (borderRadius ?? 20) * 1.2, desktop: (borderRadius ?? 20) * 1.4)
        : borderRadius ?? 20;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: responsivePadding,
        margin: margin,
        borderRadius: responsiveBorderRadius,
        isResponsive: isResponsive,
        child: child,
      ),
    );
  }
}
