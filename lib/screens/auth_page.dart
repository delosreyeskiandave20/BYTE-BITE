import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/owner_auth.dart';
import '../theme/app_theme.dart';

const _authErrorMessages = <String, String>{
  'invalid-email': 'Enter a valid email address.',
  'wrong-password': 'Email or password is incorrect.',
  'user-not-found': 'Email or password is incorrect.',
  'invalid-credential': 'Email or password is incorrect.',
  'invalid-login-credentials': 'Email or password is incorrect.',
  'email-already-in-use': 'An owner account already exists for this email.',
  'weak-password':
      'Choose a stronger password (at least $ownerPasswordMinLength characters).',
  'too-many-requests': 'Too many attempts. Wait a moment and try again.',
  'network-request-failed': 'Check your connection and try again.',
  'operation-not-allowed': 'Email sign-in is disabled for this project.',
  'user-disabled': 'This account has been disabled.',
};

class MotoScanAuthPage extends StatefulWidget {
  const MotoScanAuthPage({
    super.key,
    this.onLogin,
    this.onCreateAccount,
    this.onForgotPassword,
    this.onAuthenticated,
  });

  final Future<void> Function(String email, String password)? onLogin;
  final Future<void> Function(String name, String email, String password)?
  onCreateAccount;
  final Future<void> Function(String email)? onForgotPassword;
  final Future<void> Function(String email)? onAuthenticated;

  @override
  State<MotoScanAuthPage> createState() => _MotoScanAuthPageState();
}

class _MotoScanAuthPageState extends State<MotoScanAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _confirmPasswordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(bool login) {
    if (_isLogin == login) return;
    setState(() {
      _isLogin = login;
      _formKey.currentState?.reset();
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final loginHandler = _isLogin ? widget.onLogin : null;
    final accountHandler = _isLogin ? null : widget.onCreateAccount;
    if (loginHandler == null && accountHandler == null) {
      setState(() {
        _error = _isLogin
            ? 'Owner sign-in is not connected yet.'
            : 'Owner account creation is not connected yet.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (loginHandler != null) {
        await loginHandler(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await accountHandler!(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Check your inbox to verify your email.',
              ),
            ),
          );
        }
      }
      await widget.onAuthenticated?.call(_emailController.text.trim());
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFor(Object error) {
    if (error is OwnerAuthUnavailableException) {
      return OwnerAuthUnavailableException.message;
    }
    if (error is FirebaseAuthException) {
      return _authErrorMessages[error.code] ?? _fallbackAuthMessage(error);
    }
    if (error is StateError) {
      return error.message.toString();
    }
    return 'Unable to continue: $error';
  }

  String _fallbackAuthMessage(FirebaseAuthException error) {
    final message = error.message?.trim() ?? '';
    return message.isEmpty ? 'Unable to complete sign-in. Try again.' : message;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !isValidOwnerEmail(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < ownerPasswordMinLength) {
      return 'Use at least $ownerPasswordMinLength characters.';
    }
    return null;
  }

  Future<void> _forgotPassword() async {
    final handler = widget.onForgotPassword;
    if (handler == null) return;
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'you@example.com',
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Send reset email'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!mounted || email == null) return;
    if (!isValidOwnerEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await handler(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(21),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.surface,
                              size: 33,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'MotoScan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Shop owner access',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 20),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: true, label: Text('Log in')),
                              ButtonSegment(
                                value: false,
                                label: Text('Create owner account'),
                              ),
                            ],
                            selected: {_isLogin},
                            onSelectionChanged: _loading
                                ? null
                                : (selection) => _switchMode(selection.first),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isLogin
                                ? 'Shop owner sign in'
                                : 'Create owner account',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Form(
                            key: _formKey,
                            child: AutofillGroup(
                              child: Column(
                                children: [
                                  if (!_isLogin) ...[
                                    TextFormField(
                                      controller: _nameController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.name],
                                      decoration: const InputDecoration(
                                        labelText: 'Full name',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? 'Name is required.'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: const InputDecoration(
                                      labelText: 'Email address',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    textInputAction: _isLogin
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    autofillHints: [
                                      _isLogin
                                          ? AutofillHints.password
                                          : AutofillHints.newPassword,
                                    ],
                                    onFieldSubmitted: _isLogin
                                        ? (_) => _submit()
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: _validatePassword,
                                  ),
                                  if (!_isLogin) ...[
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: InputDecoration(
                                        labelText: 'Confirm password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _obscureConfirmPassword
                                              ? 'Show confirm password'
                                              : 'Hide confirm password',
                                          onPressed: () => setState(
                                            () => _obscureConfirmPassword =
                                                !_obscureConfirmPassword,
                                          ),
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Confirm password is required.';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match.';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : widget.onForgotPassword == null
                                    ? null
                                    : _forgotPassword,
                                child: const Text('Forgot password?'),
                              ),
                            ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  9,
                                  12,
                                  9,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerSoft,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.danger,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: AppColors.danger,
                                          fontSize: AppType.caption,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_loading) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                          ],
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: AppColors.surface,
                            ),
                            child: Text(
                              _isLogin ? 'Log in' : 'Create owner account',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isLogin
                                ? 'Accounts are secured by Firebase Authentication and shop listings are saved to Cloud Firestore.'
                                : 'We will email a verification link to confirm your address. Your shop stays manageable from this account.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: AppType.caption,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
