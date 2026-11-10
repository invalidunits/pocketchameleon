import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'app.dart';
import 'auth/cognito_auth_service.dart';

Future<void> main() async {
  await dotenv.load(fileName: "assets/.env"); 

  WidgetsFlutterBinding.ensureInitialized();

  final authService = CognitoAuthService();
  String? configurationError;
  try {
    await authService.configure();
  } on Exception catch (error) {
    configurationError = error.toString();
  }

  runApp(
    MyApp(
      authService: authService,
      configurationError: configurationError,
    ),
  );
}
