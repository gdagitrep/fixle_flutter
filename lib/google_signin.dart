import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

/// main ->
/// if user is not null : Take to FixleDashBoardHomePage and show  UserInfoAppBarWidget as title.
/// else: SignInScreen -> initializeFirebase karenge -> SignInScreen (which has GoogleSignInButton) ->
///
class Authentication {
  static Future<FirebaseApp> initializeFirebase({
    required BuildContext context,
  }) async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();
    return firebaseApp;
  }

  static Future<User?> signInWithGoogle({required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;
    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();

      try {
        final UserCredential userCredential = await auth.signInWithPopup(authProvider);

        user = userCredential.user;
      } catch (e) {
        print(e);
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        try {
          final UserCredential userCredential = await auth.signInWithCredential(credential);

          user = userCredential.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            ScaffoldMessenger.of(context).showSnackBar(
              Authentication.customSnackBar(
                content: 'The account already exists with a different credential.',
              ),
            );
          } else if (e.code == 'invalid-credential') {
            ScaffoldMessenger.of(context).showSnackBar(
              Authentication.customSnackBar(
                content: 'Error occurred while accessing credentials. Try again.',
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            Authentication.customSnackBar(
              content: 'Error occurred using Google Sign-In. Try again.',
            ),
          );
        }
      }
    }

    return user;
  }

  static Future<void> signOut({required BuildContext context}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      if (!kIsWeb) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        Authentication.customSnackBar(
          content: 'Error signing out. Try again.',
        ),
      );
    }
  }

  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: const TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  final Function(BuildContext, User) actionAfterLogin;
  const SignInScreen(this.actionAfterLogin, {super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.firebaseNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          child: Center(
            child: FutureBuilder(
              future: Authentication.initializeFirebase(context: context),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error initializing Firebase');
                } else if (snapshot.connectionState == ConnectionState.done) {
                  return GoogleSignInButton(asyncActionAfterLogin: widget.actionAfterLogin);
                }
                return const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    CustomColors.firebaseOrange,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleSignInButton extends StatefulWidget {
  final Function(BuildContext, User) asyncActionAfterLogin;

  const GoogleSignInButton({super.key, required this.asyncActionAfterLogin});

  @override
  _GoogleSignInButtonState createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _isSigningIn
          ? const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      )
          : OutlinedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.white),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        onPressed: () async {
          if (this.mounted) {
            setState(() {
              _isSigningIn = true;
            });
          }

          User? user = await Authentication.signInWithGoogle(context: context);

          if (user != null) {
            _isSigningIn = false;
            widget.asyncActionAfterLogin(context, user);
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Image(
                image: AssetImage("assets/google_logo.png"),
                height: 35.0,
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class UserInfoAppBarWidget extends StatefulWidget {
  const UserInfoAppBarWidget(this.asyncActionAfterLogin, {Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;
  final Function(BuildContext, User) asyncActionAfterLogin;

  @override
  _UserInfoAppBarWidgetState createState() => _UserInfoAppBarWidgetState();
}

class _UserInfoAppBarWidgetState extends State<UserInfoAppBarWidget> {
  late User _user;
  bool _isSigningOut = false;

  Route _routeToSignInScreen() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SignInScreen(widget.asyncActionAfterLogin),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  void initState() {
    _user = widget._user;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/firebase_logo.png',
          height: 20,
        ),
        const SizedBox(width: 8),
        Text(
          _user.displayName!,
          style: const TextStyle(
            color: CustomColors.firebaseYellow,
            fontSize: 26,
          ),
        ),
        Text(
          '( ${_user.email!} )',
          style: const TextStyle(
            color: CustomColors.firebaseOrange,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        _isSigningOut
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        )
            : ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              Colors.redAccent,
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          onPressed: () async {
            setState(() {
              _isSigningOut = true;
            });
            await Authentication.signOut(context: context);
            setState(() {
              _isSigningOut = false;
            });
            // widget.asyncActionAfterLogin.value = null;
            Navigator.of(context).pushReplacement(_routeToSignInScreen());
          },
          child: const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomColors {
  static const Color firebaseNavy = Color(0xFF2C384A);
  static const Color firebaseLightNavy = Color(0xFF5B729B);
  static const Color firebaseOrange = Color(0xFFF57C00);
  static const Color firebaseAmber = Color(0xFFFFA000);
  static const Color firebaseYellow = Color(0xFFFFCA28);
  static const Color firebaseGrey = Color(0xFFECEFF1);
  static const Color googleBackground = Color(0xFF4285F4);
}
