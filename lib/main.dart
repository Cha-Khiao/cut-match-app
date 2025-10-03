import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/feed_provider.dart';
import 'package:cut_match_app/providers/hairstyle_provider.dart';
import 'package:cut_match_app/providers/notification_provider.dart';
import 'package:cut_match_app/screens/admin/admin_hub_screen.dart';
import 'package:cut_match_app/screens/admin/hairstyles/admin_hairstyle_list_screen.dart';
import 'package:cut_match_app/screens/admin/salon/admin_salon_form_screen.dart';
import 'package:cut_match_app/screens/admin/salon/admin_salon_list_screen.dart';
import 'package:cut_match_app/screens/admin/hairstyles/hairstyle_form_screen.dart';
import 'package:cut_match_app/screens/auth/login_screen.dart';
import 'package:cut_match_app/screens/auth/register_screen.dart';
import 'package:cut_match_app/screens/social/posts/create_post_screen.dart';
import 'package:cut_match_app/screens/profiles/edit_profile_screen.dart';
import 'package:cut_match_app/screens/favorites/favorites_screen.dart';
import 'package:cut_match_app/screens/baseapp/main_screen.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:cut_match_app/screens/save/saved_looks_screen.dart';
import 'package:cut_match_app/screens/startapp/onboarding_screen.dart';
import 'package:cut_match_app/screens/startapp/splash_screen.dart';
import 'package:cut_match_app/screens/social/search/user_search_screen.dart';
import 'package:cut_match_app/screens/face/virtual_try_on_screen.dart';
import 'package:cut_match_app/screens/startapp/welcome_screen.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:overlay_support/overlay_support.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HairstyleProvider()),
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
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Cut Match',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
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
