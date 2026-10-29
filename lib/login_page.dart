import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'home_page.dart';

const _emergencyRed = Color(0xFFC62828);
const _trustBlue = Color(0xFF0D47A1);
const _emailPattern = r'^[\w.\-+]+@[\w\-]+\.[\w.\-]+$';

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email address';
  if (!RegExp(_emailPattern).hasMatch(email)) return 'Enter a valid email address';
  return null;
}

String? _validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Enter your password';
  if (password.length < 8) return 'Use at least 8 characters';
  return null;
}

class LoginPage extends StatefulWidget {
  final AuthService auth;

  const LoginPage({super.key, required this.auth});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openHome(LocalUser user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomePage(auth: widget.auth, user: user),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final result = await widget.auth.signIn(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      _openHome(result.user!);
    } else {
      setState(() => _formError = result.message);
    }
  }

  Future<void> _register() async {
    final user = await showDialog<LocalUser>(
      context: context,
      builder: (_) => _RegisterDialog(auth: widget.auth),
    );
    if (user != null && mounted) _openHome(user);
  }

  Future<void> _resetPassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ResetPasswordDialog(
        auth: widget.auth,
        initialEmail: _emailController.text,
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Header(),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Sign in',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your account is saved on this computer.',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isLoading,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                      onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: _validatePassword,
                                  onFieldSubmitted: (_) => _signIn(),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _resetPassword,
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                                if (_formError != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _emergencyRed.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _formError!,
                                      style: const TextStyle(color: _emergencyRed),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                SizedBox(
                                  height: 50,
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _signIn,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Sign In'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text('First time here?'),
                                    TextButton(
                                      onPressed: _isLoading ? null : _register,
                                      child: const Text('Create account'),
                                    ),
                                  ],
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
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _trustBlue.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/logo_ligtaslink.jpg', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'LIGTASLINK',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: _emergencyRed,
            letterSpacing: 1.4,
          ),
        ),
        const Text(
          'Connecting Help, Saving Lives.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _RegisterDialog extends StatefulWidget {
  final AuthService auth;

  const _RegisterDialog({required this.auth});

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _pin = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_key.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final result = await widget.auth.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      recoveryPin: _pin.text,
    );
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(result.user);
    } else {
      setState(() {
        _saving = false;
        _error = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create local account'),
      content: SizedBox(
        width: 390,
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Enter your full name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm password'),
                  validator: (value) => value != _password.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Recovery PIN',
                    helperText: 'Use 4 to 8 digits and remember it.',
                  ),
                  validator: (value) => !RegExp(r'^\d{4,8}$').hasMatch(value ?? '')
                      ? 'Enter 4 to 8 digits'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: _emergencyRed)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Creating...' : 'Create account'),
        ),
      ],
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  final AuthService auth;
  final String initialEmail;

  const _ResetPasswordDialog({required this.auth, required this.initialEmail});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _pin = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _email.dispose();
    _pin.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_key.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final result = await widget.auth.resetPassword(
      email: _email.text,
      recoveryPin: _pin.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset password'),
      content: SizedBox(
        width: 390,
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Recovery PIN'),
                validator: (value) => (value?.isEmpty ?? true) ? 'Enter your PIN' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: _validatePassword,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: _emergencyRed)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving...' : 'Save password'),
        ),
      ],
    );
  }
}
