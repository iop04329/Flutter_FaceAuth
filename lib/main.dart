import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/home.dart';
import 'package:face_net_authentication/pages/sign-in dlib.dart';
import 'package:flutter/material.dart';
import 'package:face_net_authentication/pages/sign-up.dart';
import 'package:face_net_authentication/pages/sign-in.dart';
import 'package:face_net_authentication/pages/sign-up manual.dart';
import 'package:face_net_authentication/pages/sign-up dlib.dart';
import 'package:face_net_authentication/pages/database_ring.dart';
import 'package:face_net_authentication/pages/database_user.dart';
import 'package:face_net_authentication/pages/database_data.dart';
import 'package:face_net_authentication/pages/dlib.dart';
import 'package:face_net_authentication/pages/database_music.dart';

void main() {
  setupServices();
  // WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/home',
      onGenerateRoute: (setting){
        switch (setting.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => MyHomePage(), settings: RouteSettings(name: '/home'));
          case '/signup':
            return MaterialPageRoute(builder: (_) => SignUp(), settings: RouteSettings(name: '/signup'));
          case '/signupManual':
            return MaterialPageRoute(builder: (_) => SignUpManual(), settings: RouteSettings(name: '/signupManual'));
          case '/signupDlib':
            return MaterialPageRoute(builder: (_) => SignUpDlib(), settings: RouteSettings(name: '/signupDlib'));
          case '/signinDlib':
            return MaterialPageRoute(builder: (_) => SignInDlib(), settings: RouteSettings(name: '/signinDlib'));
          case '/signin':
            return MaterialPageRoute(builder: (_) => SignIn(), settings: RouteSettings(name: '/signin'));
          case '/ring':
            return MaterialPageRoute(builder: (_) => databaseRingpage(), settings: RouteSettings(name: '/ring'));
          case '/database':
            return MaterialPageRoute(builder: (_) => databaseUserpage(), settings: RouteSettings(name: '/database'));
          case '/data':
            return MaterialPageRoute(builder: (_) => databaseDatapage(), settings: RouteSettings(name: '/data'));
          case '/dlib':
            return MaterialPageRoute(builder: (_) => DlibPage(), settings: RouteSettings(name: '/dlib'));
          case '/music':
            return MaterialPageRoute(builder: (_) => databaseMusicpage(), settings: RouteSettings(name: '/music'));
          default:
          return null;
        }
      },
    );
  }
}
