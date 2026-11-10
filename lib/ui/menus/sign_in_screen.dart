import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import '../../auth/cognito_auth_service.dart';

class SignInScreen extends StatefulWidget {
  final CognitoAuthService authService;
  final String? configurationError;
  final VoidCallback onSignedIn;

  const SignInScreen({
    super.key,
    required this.authService,
    required this.configurationError,
    required this.onSignedIn,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _challengeController = TextEditingController();

  AuthSignInStep? _challengeStep;
  bool _isSubmitting = false;
  bool _obscurePasswordText = true;
  String? _errorMessage;

  bool get _hasChallenge =>
      _challengeStep != null && _challengeStep != AuthSignInStep.done;

  bool get _isNewPasswordChallenge =>
      _challengeStep == AuthSignInStep.confirmSignInWithNewPassword;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _challengeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.authService.isConfigured) return;
    if (!_hasChallenge && !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_hasChallenge) {
        final result = await widget.authService.confirmSignIn(
          _challengeController.text.trim(),
        );
        if (result.isSignedIn) {
          widget.onSignedIn();
        } else {
          _showNextStep(result.nextStep.signInStep);
        }
      } else {
        final result = await widget.authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (result.isSignedIn) {
          widget.onSignedIn();
        } else {
          _showNextStep(result.nextStep.signInStep);
        }
      }
    } 
    on Exception catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFriendlyErrorMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getFriendlyErrorMessage(Object error) {
    final errorText = error.toString();
    final normalized = errorText
        .replaceAll('AuthException: ', '')
        .replaceAll('Exception: ', '')
        .replaceAll('AmplifyException: ', '')
        .trim();
    final lower = normalized.toLowerCase();

    if (lower.contains('notauthorizedexception') ||
        lower.contains('incorrect username or password') ||
        lower.contains('incorrect email or password')) {
      return 'Incorrect email or password. Please try again.';
    }

    if (lower.contains('usernotfoundexception') ||
        lower.contains('user does not exist') ||
        lower.contains('username not found')) {
      return 'We could not find an account with that email.';
    }

    if (lower.contains('usernotconfirmedexception') ||
        lower.contains('user is not confirmed')) {
      return 'Your account has not been confirmed yet. Check your email for a confirmation link.';
    }

    if (lower.contains('toomanyfailedattemptsexception') ||
        lower.contains('too many failed attempts')) {
      return 'Too many unsuccessful sign-in attempts. Please wait a moment and try again.';
    }

    if (lower.contains('passwordresetrequiredexception') ||
        lower.contains('password reset required')) {
      return 'This account requires a password reset before continuing.';
    }

    if (lower.contains('codemismatchexception') ||
        lower.contains('code mismatch') ||
        lower.contains('invalid verification code')) {
      return 'The verification code is incorrect. Please try again.';
    }

    if (lower.contains('expiredcodeexception') ||
        lower.contains('expired code')) {
      return 'The verification code has expired. Please request a new one and try again.';
    }

    if (lower.contains('limitexceededexception') ||
        lower.contains('too many requests')) {
      return 'Too many requests were sent. Please wait a moment and try again.';
    }

    if (lower.contains('invalidpasswordexception') ||
        lower.contains('password did not conform') ||
        lower.contains('password requirements')) {
      return 'The password does not meet the required format. Please use a stronger password.';
    }

    if (lower.contains('invalidparameterexception') ||
        lower.contains('invalid email')) {
      return 'Please check the details you entered and try again.';
    }

    if (lower.contains('socketexception') ||
        lower.contains('timeout') ||
        lower.contains('failed host lookup') ||
        lower.contains('network')) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }

    if (normalized.isNotEmpty && normalized != 'Exception') {
      return normalized;
    }

    return 'Something went wrong while signing in. Please try again.';
  }

  void _showNextStep(AuthSignInStep step) {
    if (!mounted) return;

    const supportedChallenges = {
      AuthSignInStep.confirmSignInWithOtpCode,
      AuthSignInStep.confirmSignInWithSmsMfaCode,
      AuthSignInStep.confirmSignInWithTotpMfaCode,
      AuthSignInStep.confirmSignInWithCustomChallenge,
      AuthSignInStep.confirmSignInWithNewPassword,
      AuthSignInStep.confirmSignInWithPassword,
    };

    if (supportedChallenges.contains(step)) {
      setState(() {
        _challengeStep = step;
        _challengeController.clear();
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _errorMessage =
          'Your account requires an additional step ($step) that this sign-in screen does not support.';
    });
  }

  void _backToPassword() {
    setState(() {
      _challengeStep = null;
      _challengeController.clear();
      _errorMessage = null;
    });
  }

  String? _passwordValidator(String? password) {
    if (password == null || password.isEmpty) return 'Enter your password.';
    if (_isNewPasswordChallenge) {
      final errorList = <String>[];
      if (password.length < 8) {
        errorList.add('Password must be at least 8 characters');
      }
      if (!password.contains(RegExp(r'[A-Z]'))) {
        errorList.add('Password must contain at least one uppercase letter');
      }
      if (!password.contains(RegExp(r'[a-z]'))) {
        errorList.add('Password must contain at least one lowercase letter');
      }
      if (!password.contains(RegExp(r'\d'))) {
        errorList.add('Password must contain at least one number');
      }
      return errorList.isEmpty ? null : errorList.join('\n');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final configured = widget.authService.isConfigured;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF193B35), Color(0xFF356E52), Color(0xFF829E67)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  color: const Color(0xFFF3F5EF),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            color: Color(0xFF276B50),
                            size: 52,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _hasChallenge
                                ? (_isNewPasswordChallenge? 'RESET YOUR PASSWORD' : 'VERIFY YOUR SIGN IN')
                                : 'WELCOME BACK',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF193B35),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _hasChallenge
                                ? 'Enter the requested verification value for ${_emailController.text.trim()}.'
                                : 'Sign in with your account email and password.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (!_hasChallenge) ...[
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) return 'Enter your email.';
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email)) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePasswordText,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                                suffixIcon: IconButton(onPressed: () => setState(() => _obscurePasswordText = !_obscurePasswordText), icon: Icon(_obscurePasswordText? Icons.visibility_off : Icons.visibility)),
                                border: OutlineInputBorder(),
                              ),
                              validator: _passwordValidator,
                            ),
                          ] else
                            TextFormField(
                              controller: _challengeController,
                              obscureText: _isNewPasswordChallenge,
                              autofocus: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: _isNewPasswordChallenge
                                    ? 'New password'
                                    : 'Verification code',
                                prefixIcon: Icon(
                                  _isNewPasswordChallenge
                                      ? Icons.lock_outline
                                      : Icons.password,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          if (widget.configurationError != null ||
                              !widget.authService.hasConfiguration) ...[
                            const SizedBox(height: 16),
                            Text(
                              widget.configurationError ?? 'Cognito is not configured. Add the AWS region, User Pool ID, and App Client ID according to the README.md.',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: configured && !_isSubmitting
                                ? _submit
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF276B50),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_hasChallenge ? 'CONTINUE' : 'SIGN IN'),
                          ),
                          if (_hasChallenge) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _isSubmitting ? null : _backToPassword,
                              child: const Text('Back to email and password'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
