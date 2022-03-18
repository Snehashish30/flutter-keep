import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flt_keep/page/fingerprint_page.dart';


import 'models.dart' show CurrentUser;
import 'screens.dart' show HomeScreen, LoginScreen, NoteEditor, SettingsScreen;

import 'styles.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('A bg message just showed up :  ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(NotesApp());
}

class NotesApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => StreamProvider.value(
    value: FirebaseAuth.instance.authStateChanges().map((user) => CurrentUser.create(user)),
    initialData: CurrentUser.initial,
    child: Consumer<CurrentUser>(
      builder: (context, user, _) => MaterialApp(
        title: 'Flutter Keep',
        theme: Theme.of(context).copyWith(
          brightness: Brightness.light,
          primaryColor: Colors.white,
          accentColor: kAccentColorLight,
          appBarTheme: AppBarTheme.of(context).copyWith(
            elevation: 0,
            brightness: Brightness.light,
            iconTheme: IconThemeData(
              color: kIconTintLight,
            ),
          ),
          scaffoldBackgroundColor: Colors.white,
          bottomAppBarColor: kBottomAppBarColorLight,
          primaryTextTheme: Theme.of(context).primaryTextTheme.copyWith(
            // title
            headline6: const TextStyle(
              color: kIconTintLight,
            ),
          ),
        ),
        home: user.isInitialValue
          ? Scaffold(body: const SizedBox())
          : user.data != null ? FingerprintPage() : LoginScreen(),
        routes: {
          '/settings': (_) => SettingsScreen(),
          '/login': (context) => LoginScreen(),
        },
        onGenerateRoute: _generateRoute,
      ),
    ),
  );

  /// Handle named route
  Route _generateRoute(RouteSettings settings) {
    try {
      return _doGenerateRoute(settings);
    } catch (e, s) {
      debugPrint("failed to generate route for $settings: $e $s");
      return null;
    }
  }

  Route _doGenerateRoute(RouteSettings settings) {
    if (settings.name?.isNotEmpty != true) return null;

    final uri = Uri.parse(settings.name);
    final path = uri.path ?? '';
    // final q = uri.queryParameters ?? <String, String>{};
    switch (path) {
      case '/note': {
        final note = (settings.arguments as Map ?? {})['note'];
        return _buildRoute(settings, (_) => NoteEditor(note: note));
      }
      default:
        return null;
    }
  }

  /// Create a [Route].
  Route _buildRoute(RouteSettings settings, WidgetBuilder builder) =>
    MaterialPageRoute<void>(
      settings: settings,
      builder: builder,
    );
}
