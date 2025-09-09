import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'theme/glass_theme.dart';
import 'theme/responsive_glass_theme.dart';
import 'widgets/glass_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Free Gift',
      theme: GlassTheme.theme,
      builder: (context, child) {
        // Create responsive theme based on screen size
        final responsiveTheme = GlassTheme.theme.copyWith(
          textTheme: ResponsiveGlassTheme.getResponsiveTextTheme(context),
          elevatedButtonTheme: ResponsiveGlassTheme.getResponsiveButtonTheme(context),
          inputDecorationTheme: ResponsiveGlassTheme.getResponsiveInputTheme(context),
          cardTheme: ResponsiveGlassTheme.getResponsiveCardTheme(context),
          appBarTheme: ResponsiveGlassTheme.getResponsiveAppBarTheme(context),
        );
        
        return Theme(
          data: responsiveTheme,
          child: child!,
        );
      },
      debugShowCheckedModeBanner: false,
      home: const GlassBackground(
        child: HomeScreen(),
      ),
    );
  }
}
