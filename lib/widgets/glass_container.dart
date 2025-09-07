import 'dart:ui';
import '../theme/glass_theme.dart';
import '../utils/responsive.dart';

/// Glass Container Widget with blur effect and responsive sizing
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double? blurSigma;
  final List<BoxShadow>? boxShadow;
  final bool isResponsive;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor = GlassTheme.glassBackground,
    this.borderColor = GlassTheme.glassBorder,
    this.borderWidth = 1,
    this.blurSigma,
    this.boxShadow,
    this.isResponsive = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveBorderRadius = isResponsive 
        ? Responsive.borderRadius(context, mobile: borderRadius ?? 17, tablet: (borderRadius ?? 17) * 1.2, desktop: (borderRadius ?? 17) * 1.4)
        : borderRadius ?? 17;
    
    final responsiveBlurSigma = isResponsive
        ? Responsive.width(context, mobile: blurSigma ?? 8.5, tablet: (blurSigma ?? 8.5) * 1.2, desktop: (blurSigma ?? 8.5) * 1.4)
        : blurSigma ?? 8.5;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: responsiveBlurSigma, sigmaY: responsiveBlurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(responsiveBorderRadius),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: boxShadow ?? [
                BoxShadow(
                  color: GlassTheme.glassShadow,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
