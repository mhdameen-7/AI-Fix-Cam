    import 'package:aifixcam/screens/home_screen.dart';
    import 'package:flutter/material.dart';
    import 'package:google_fonts/google_fonts.dart'; // Import the package

    void main() {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const MyApp());
    }

    class MyApp extends StatelessWidget {
      const MyApp({super.key});

      @override
      Widget build(BuildContext context) {
        // Define our custom theme
        final theme = ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212), // A deep, rich black
          primaryColor: const Color(0xFF00BFA5), // A vibrant Teal
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00BFA5),   // Main interactive color
            secondary: Color(0xFFE0F2F1), // A very light teal for accents
            surface: Color(0xFF1E1E1E),   // Color for cards and surfaces
            onPrimary: Colors.black,      // Text on primary color
            onSurface: Colors.white,      // Main text color
          ),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme), // Use Poppins font
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5), // Button color
              foregroundColor: Colors.black,           // Button text color
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent, // Make AppBar transparent
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        );

        return MaterialApp(
          title: 'AI Fix Cam',
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
        );
      }
    }
    
