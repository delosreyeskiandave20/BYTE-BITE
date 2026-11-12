import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Demo credentials shown in the owner sign-in screen while Firebase is not
/// connected. Kept in one place so the note and the autofill button agree.
const _demoEmail = 'demo@motoscan.test';
const _demoPassword = 'demo1234';
const _demoPin = '123456';

class MotoScanAuthPage extends StatefulWidget {
  const MotoScanAuthPage({
    super.key,
    this.onLogin,
    this.onCreateAccount,
    this.onForgotPassword,
    this.onAuthenticated,
    this.isDemoMode = true,
  });

  final Future<void> Function(String email, String password, String pin)?
  onLogin;
  final Future<void> Function(
    String name,
    String email,
    String password,
    String pin,
  )?
  onCreateAccount;
  final Future<void> Function(String email)? onForgotPassword;
  final Future<void> Function(String email)? onAuthenticated;
  final bool isDemoMode;

  @override
  State<MotoScanAuthPage> createState() => _MotoScanAuthPageState();
}

class _MotoScanAuthPageState extends State<MotoScanAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
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

  void _fillDemoCredentials() {
    _emailController.text = _demoEmail;
    _passwordController.text = _demoPassword;
    _pinController.text = _demoPin;
    _emailController.selection = TextSelection.collapsed(
      offset: _demoEmail.length,
    );
    _passwordController.selection = TextSelection.collapsed(
      offset: _demoPassword.length,
    );
    _pinController.selection = TextSelection.collapsed(offset: _demoPin.length);
    setState(() => _error = null);
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
          _pinController.text.trim(),
        );
      } else {
        await accountHandler!(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          _pinController.text.trim(),
        );
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
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'An owner account already exists for this email.';
        case 'weak-password':
          return 'Choose a stronger password (at least 8 characters).';
        case 'too-many-requests':
          return 'Too many attempts. Wait a moment and try again.';
        case 'network-request-failed':
          return 'Check your connection and try again.';
        case 'operation-not-allowed':
          return 'Email sign-in is disabled for this project.';
        case 'user-disabled':
          return 'This account has been disabled.';
      }
      final authMessage = error.message;
      if (authMessage != null && authMessage.trim().isNotEmpty) {
        return authMessage;
      }
    }
    final message = error.toString();
    if (message.contains('invalid-email')) {
      return 'Enter a valid email address.';
    }
    if (message.contains('wrong-password') ||
        message.contains('user-not-found') ||
        message.contains('invalid-credential')) {
      return 'Email or password is incorrect.';
    }
    if (message.contains('email-already-in-use')) {
      return 'An owner account already exists for this email.';
    }
    if (message.contains('weak-password')) {
      return 'Choose a stronger password (at least 8 characters).';
    }
    if (message.contains('already exists')) {
      return 'An owner account already exists for this email.';
    }
    if (message.contains('incorrect')) {
      return 'Email or password is incorrect.';
    }
    return 'Unable to continue: $message';
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Use at least 8 characters.';
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
    if (_validateEmail(email) != null) {
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
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _pinController,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    textInputAction: _isLogin
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    maxLength: 6,
                                    decoration: const InputDecoration(
                                      labelText: '6-digit PIN',
                                      prefixIcon: Icon(Icons.dialpad),
                                      counterText: '',
                                    ),
                                    validator: (value) {
                                      final pin = value?.trim() ?? '';
                                      if (pin.length != 6 ||
                                          int.tryParse(pin) == null) {
                                        return 'Enter a 6-digit PIN.';
                                      }
                                      return null;
                                    },
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
                          if (widget.isDemoMode) ...[
                            _DemoCredentialsCard(
                              onUseDemo: _loading ? null : _fillDemoCredentials,
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            widget.isDemoMode
                                ? 'Temporary demo only — accounts and shop listings reset when the app restarts. Demo login: $_demoEmail / $_demoPassword. Do not use a real password.'
                                : 'Accounts are secured by Firebase Authentication and shop listings are saved to Cloud Firestore. Email verification and one-time codes are not required.',
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

/// Compact demo-only helper that fills the login form. It deliberately avoids
/// the person icon used by the header so the account-entry-point icon test
/// keeps a single match.
class _DemoCredentialsCard extends StatelessWidget {
  const _DemoCredentialsCard({required this.onUseDemo});

  final VoidCallback? onUseDemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.tealBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_outlined, size: 16, color: AppColors.teal),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Demo shop owner',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: AppType.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '$_demoEmail · $_demoPassword',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w600,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onUseDemo,
              icon: const Icon(Icons.arrow_downward_rounded, size: 16),
              label: const Text('Use demo login'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.teal,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
