import 'package:flutter/material.dart';
import 'package:inventory_bkm_desktop/services/api_service.dart';
import 'package:inventory_bkm_desktop/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onAuthenticated;

  const LoginScreen({
    super.key,
    required this.apiService,
    required this.onAuthenticated,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@company.local');
  final _passwordController = TextEditingController(text: 'Admin123!');
  bool _isSubmitting = false;
  bool _rememberPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.apiService
          .login(_emailController.text.trim(), _passwordController.text);
      widget.onAuthenticated();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAFBF7), Color(0xFFF5F7EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: -160,
              top: 240,
              child: _SoftShape(
                color: Color(0x668CC63F),
                width: 620,
                height: 260,
                angle: -0.18,
              ),
            ),
            const Positioned(
              right: -120,
              top: -80,
              child: _SoftShape(
                color: Color(0x55FFB74D),
                width: 640,
                height: 360,
                angle: 0.18,
              ),
            ),
            const Positioned(
              right: 260,
              bottom: -220,
              child: _SoftShape(
                color: Color(0x66F5F7EF),
                width: 520,
                height: 300,
                angle: 0.24,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          MediaQuery.of(context).size.width < 700 ? 32 : 72,
                      vertical:
                          MediaQuery.of(context).size.height < 820 ? 44 : 72,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Login to Account',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontSize: 30),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Please enter your email and password to continue',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: const Color(0xFF68777A),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 46),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email address:',
                            hintText: 'admin@company.local',
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Text(
                                'Password',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFF68777A),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                'Forget Password?',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFF68777A),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan password',
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Password wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberPassword,
                                onChanged: (value) => setState(() {
                                  _rememberPassword = value ?? true;
                                }),
                              ),
                              Text(
                                'Remember Password',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFF68777A),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 44),
                          SizedBox(
                            height: 64,
                            child: PrimaryButton(
                              label: 'Sign In',
                              isLoading: _isSubmitting,
                              onPressed: _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF68777A),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(hintText: hintText),
          validator: (value) =>
              value == null || value.isEmpty ? '$label wajib diisi' : null,
        ),
      ],
    );
  }
}

class _SoftShape extends StatelessWidget {
  const _SoftShape({
    required this.color,
    required this.width,
    required this.height,
    required this.angle,
  });

  final Color color;
  final double width;
  final double height;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}
