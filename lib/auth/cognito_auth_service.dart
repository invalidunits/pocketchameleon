import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CognitoAuthService {
  final _region = dotenv.env['COGNITO_REGION'] ?? String.fromEnvironment('COGNITO_REGION');
  final _userPoolId = dotenv.env['COGNITO_USER_POOL_ID'] ?? String.fromEnvironment('COGNITO_USER_POOL_ID');
  final _appClientId = dotenv.env['COGNITO_APP_CLIENT_ID'] ?? String.fromEnvironment('COGNITO_APP_CLIENT_ID');

  CognitoAuthService()
  {

  }

  bool get hasConfiguration =>
      _region.isNotEmpty && _userPoolId.isNotEmpty && _appClientId.isNotEmpty;

  bool get isConfigured => hasConfiguration && Amplify.isConfigured;

  Future<void> configure() async {
    if (!hasConfiguration) return;

    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(
      jsonEncode({
        'UserAgent': 'aws-amplify-cli/2.0',
        'Version': '1.0',
        'auth': {
          'plugins': {
            'awsCognitoAuthPlugin': {
              'IdentityManager': {'Default': <String, Object?>{}},
              'CognitoUserPool': {
                'Default': {
                  'PoolId': _userPoolId,
                  'AppClientId': _appClientId,
                  'Region': _region,
                },
              },
            },
          },
        },
      }),
    );
  }

  Future<bool> isSignedIn() async {
    final session = await Amplify.Auth.fetchAuthSession();
    return session.isSignedIn;
  }

  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) {
    return Amplify.Auth.signIn(username: email, password: password);
  }

  Future<SignInResult> confirmSignIn(String confirmationValue) {
    return Amplify.Auth.confirmSignIn(confirmationValue: confirmationValue);
  }

  Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }
}
