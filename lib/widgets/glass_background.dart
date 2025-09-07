import '../theme/glass_theme.dart';

/// Background gradient widget
class GlassBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? gradient;

  const GlassBackground({
    super.key,
    required this.child,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient ?? GlassTheme.backgroundGradient,
        ),
      ),
      child: child,
    );
  }
}
