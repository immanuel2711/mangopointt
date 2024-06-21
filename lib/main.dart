import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:bun/pages/home_page.dart';
import 'package:bun/pages/auth/signup.dart';
import 'package:bun/pages/auth/signin.dart';
import 'package:bun/pages/inward/inward.dart';
import 'package:bun/providers/user_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bun/pages/inward/addinginward.dart';
//import 'package:begin_app/user_provider.dart';
//import 'package:begin_app/inward.dart';
//import 'package:begin_app/signin.dart';
//import 'package:begin_app/signup.dart';
//import 'package:begin_app/addinginward.dart';
//import 'package:begin_app/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyBTdxpn7S9TwukMP-pu1OgN7JsF8GklEdk",
            authDomain: "maag-47a0b.firebaseapp.com",
            projectId: "maag-47a0b",
            storageBucket: "maag-47a0b.appspot.com",
            messagingSenderId: "1017295654876",
            appId: "1:1017295654876:web:aecd979cf155f6f08ac919"));
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mango App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthGate(),
        '/inward': (context) => HomePage(),
        '/signup': (context) => SignUpPage(),
        '/addinginward': (context) =>AddingInwardPage()
      },
    );
  }
}

// class AuthGate extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         } else if (snapshot.hasData) {
//           // Set the user in the UserProvider
//           Provider.of<UserProvider>(context, listen: false).updateUser(snapshot.data!);
//           
//           return InwardPage();
//         } else {
//           return SignInPage();

//         }

//       },
//     );
//   }
// }
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          
          return HomePage();
        } else {
          
          return SignInPage();
        }
      },
    );
  }
}
