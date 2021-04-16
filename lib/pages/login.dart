import 'package:auth_buttons/auth_buttons.dart';
import 'package:easacc_task/pages/secondScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FacebookLogin facebookLogin = FacebookLogin();
  User _user;
  bool showSpinner = false;
  bool isSignIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GoogleAuthButton(
              isLoading: showSpinner,
              onPressed: signInWithGoogle,
              style: AuthButtonStyle(
                iconType: AuthIconType.outlined,
              ),
            ),
            SizedBox(
              height: 25,
            ),
            FacebookAuthButton(
              onPressed: () async {
                await handleLogin();
              },
              style: AuthButtonStyle(
                iconType: AuthIconType.outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final User user =
        (await FirebaseAuth.instance.signInWithCredential(credential)).user;
    if (user != null && user.isAnonymous == false) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('email', user.email);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Screen2();
          },
        ),
      );
    } else {}
    setState(() {
      showSpinner = false;
    });
    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> handleLogin() async {
    facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
    final FacebookLoginResult result = await facebookLogin.logIn(['email']);
    switch (result.status) {
      case FacebookLoginStatus.cancelledByUser:
        break;
      case FacebookLoginStatus.error:
        break;
      case FacebookLoginStatus.loggedIn:
        try {
          await loginWithFacebook(result);
        } catch (e) {
          print(e);
        }
        break;
    }
  }

  Future loginWithFacebook(FacebookLoginResult result) async {
    final FacebookAccessToken accessToken = result.accessToken;
    AuthCredential credential =
        FacebookAuthProvider.credential(accessToken.token);
    var a = await _auth.signInWithCredential(credential);
    setState(() {
      isSignIn = true;
      _user = a.user;
    });
    if (_user != null && _user.isAnonymous == false) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('email', _user.email);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Screen2();
          },
        ),
      );
    } else {}
  }
}
