import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import '../constants.dart';

class SignIn extends StatelessWidget {
  const SignIn({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    void navigateHome(AuthResponse response) {
      Navigator.of(context).pushReplacementNamed('/main');
    }

    void navigateSignIn(AuthResponse response) {
      Navigator.of(context).pushReplacementNamed('/');
    }

    final buttonTheme = ThemeData(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 22, 135, 188),
          foregroundColor: Colors.white,
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 80),
            SizedBox(
              width: double.infinity,
              child: Text(
                'Smart Water Bottle',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Theme(
                    data: buttonTheme,
                    child: SupaEmailAuth(
                      redirectTo: kIsWeb
                          ? null
                          : 'smart-water-bottle://login-callback',
                      onSignInComplete: navigateHome,
                      onSignUpComplete: navigateSignIn,
                      showConfirmPasswordField: true,

                      metadataFields: [
                        MetaDataField(
                          prefixIcon: const Icon(Icons.person),
                          label: 'Username',
                          key: 'username',
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter something';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  spacer,
                  SupaSocialsAuth(
                    colored: true,
                    redirectUrl: kIsWeb
                        ? null
                        : 'smart-water-bottle://login-callback',
                    enableNativeAppleAuth: false,
                    socialProviders: [OAuthProvider.github],
                    onSuccess: (session) {
                      Navigator.of(context).pushReplacementNamed('/main');
                    },
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${error.toString()}')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
