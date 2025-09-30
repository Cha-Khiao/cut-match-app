import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/providers/notification_provider.dart';
import 'package:cut_match_app/screens/admin/admin_hub_screen.dart';
import 'package:cut_match_app/screens/admin/admin_hairstyle_list_screen.dart';
import 'package:cut_match_app/screens/admin/admin_salon_form_screen.dart';
import 'package:cut_match_app/screens/admin/admin_salon_list_screen.dart';
import 'package:cut_match_app/screens/admin/hairstyle_form_screen.dart';
import 'package:cut_match_app/screens/auth_screen.dart';
import 'package:cut_match_app/screens/create_post_screen.dart';
import 'package:cut_match_app/screens/edit_profile_screen.dart';
import 'package:cut_match_app/screens/favorites_screen.dart';
import 'package:cut_match_app/screens/main_screen.dart';
import 'package:cut_match_app/screens/profile_screen.dart';
import 'package:cut_match_app/screens/saved_looks_screen.dart';
import 'package:cut_match_app/screens/splash_screen.dart';
import 'package:cut_match_app/screens/user_search_screen.dart';
import 'package:cut_match_app/screens/virtual_try_on_screen.dart';
import 'package:cut_match_app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:overlay_support/overlay_support.dart'; // ✨ เพิ่มเพื่อรองรับแบนเนอร์แจ้งเตือน

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FeedProvider>(
          create: (_) => FeedProvider(),
          update: (_, auth, previous) => previous!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, previous) => previous!..updateToken(auth.token),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✨ ห่อ MaterialApp ด้วย OverlaySupport เพื่อให้แสดงแบนเนอร์แจ้งเตือนได้
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Cut Match',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          textTheme: GoogleFonts.kanitTextTheme(Theme.of(context).textTheme),
          appBarTheme: AppBarTheme(
            titleTextStyle: GoogleFonts.kanit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/auth': (context) => const AuthScreen(),
          '/main': (context) => const MainScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit_profile': (context) => const EditProfileScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/saved_looks': (context) => const SavedLooksScreen(),
          '/admin_hub': (context) => const AdminHubScreen(),
          '/admin_hairstyle_list': (context) =>
              const AdminHairstyleListScreen(),
          '/admin_salon_list': (context) => const AdminSalonListScreen(),
          '/hairstyle_form': (context) => const HairstyleFormScreen(),
          '/salon_form': (context) => const AdminSalonFormScreen(),
          '/create_post': (context) => const CreatePostScreen(),
          '/user_search': (context) => const UserSearchScreen(),
          '/tryon': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return VirtualTryOnScreen(
              userImageFile: args['userImageFile'],
              hairstyleOverlayUrl: args['hairstyleOverlayUrl'],
            );
          },
        },
      ),
    );
  }
}
