import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import '../constants.dart';

class SignIn extends StatelessWidget {
  const SignIn({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    void navigateHome(AuthResponse response) {
      Navigator.of(context).pushReplacementNamed('/home');
    }

    void navigateSignIn(AuthResponse response) {
      Navigator.of(context).pushReplacementNamed('/');
    }

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
            SizedBox(height: 40), // Abstand zum Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  SupaEmailAuth(
                    redirectTo: kIsWeb
                        ? null
                        : 'smart-water-bottle://login-callback',
                    onSignInComplete: navigateHome,
                    onSignUpComplete: navigateSignIn,
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
                      BooleanMetaDataField(
                        label:
                            'Keep me up to date with the latest news and updates.',
                        key: 'marketing_consent',
                        checkboxPosition: ListTileControlAffinity.leading,
                      ),
                      BooleanMetaDataField(
                        key: 'terms_agreement',
                        isRequired: true,
                        checkboxPosition: ListTileControlAffinity.leading,
                        richLabelSpans: [
                          const TextSpan(text: 'I have read and agree to the '),
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: const TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Handle tap on Terms and Conditions
                              },
                          ),
                        ],
                      ),
                    ],
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
                      Navigator.of(context).pushReplacementNamed('/home');
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
