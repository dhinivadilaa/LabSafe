import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _npmController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _accessCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureAccessCode = true;
  String _selectedRole = 'mahasiswa';
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _npmController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == 'asisten') {
      if (_accessCodeController.text.trim() != 'LABSAFE2026') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kode akses asisten tidak valid!'),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      npm: _npmController.text.trim(),
      role: _selectedRole,
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryMid],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.app_registration_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Registrasi Akun Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.grey50,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buat Akun Baru',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryMid,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Silakan isi data diri Anda untuk membuat akun baru.',
                            style: TextStyle(fontSize: 14, color: AppTheme.grey600),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              hintText: 'Pilih Role',
                              prefixIcon: Icon(Icons.people_outline,
                                  color: AppTheme.grey600),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'mahasiswa',
                                child: Text('Mahasiswa'),
                              ),
                              DropdownMenuItem(
                                value: 'asisten',
                                child: Text('Asisten Laboratorium'),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedRole = val ?? 'mahasiswa';
                              });
                            },
                          ),
                          if (_selectedRole == 'asisten') ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _accessCodeController,
                              obscureText: _obscureAccessCode,
                              decoration: InputDecoration(
                                hintText: 'Kode Akses Asisten (Rahasia)',
                                prefixIcon: const Icon(Icons.key_outlined,
                                    color: AppTheme.grey600),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureAccessCode
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.grey600,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureAccessCode = !_obscureAccessCode),
                                ),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? 'Kode akses tidak boleh kosong'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Nama lengkap',
                              prefixIcon: Icon(Icons.person_outline,
                                  color: AppTheme.grey600),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: AppTheme.grey600),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!value.contains('@')) {
                                return 'Masukkan email yang valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _npmController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'NPM',
                              prefixIcon: Icon(Icons.credit_card_outlined,
                                  color: AppTheme.grey600),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'NPM tidak boleh kosong' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outlined,
                                  color: AppTheme.grey600),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.grey600,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            decoration: const InputDecoration(
                              hintText: 'Konfirmasi password',
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: AppTheme.grey600),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi password tidak boleh kosong';
                              }
                              if (value != _passwordController.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return ElevatedButton(
                                onPressed: auth.isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text('DAFTAR'),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Text(
                                'Sudah punya akun? Masuk',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
