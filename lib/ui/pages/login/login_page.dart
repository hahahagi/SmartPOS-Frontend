import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/colors.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/auto_logout_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const String routeName = 'login';
  static const String routePath = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late int _lastAutoLogoutSignal;
  ProviderSubscription<AuthState>? _authSubscription;
  ProviderSubscription<int>? _autoLogoutSubscription;
  List<String> _emailHistory = [];
  List<String> _filteredEmails = [];
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _loadEmailHistory();
    _emailController.addListener(_onEmailChanged);
    _emailFocusNode.addListener(_onEmailFocusChanged);
    _authSubscription = ref.listenManual<AuthState>(authNotifierProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        _showSnackBar(next.errorMessage!);
      }
    });

    _lastAutoLogoutSignal = ref.read(autoLogoutSignalProvider);
    if (_lastAutoLogoutSignal > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showSnackBar('Sesi login berakhir, silakan login ulang.');
      });
    }

    _autoLogoutSubscription = ref.listenManual<int>(autoLogoutSignalProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      if (next == _lastAutoLogoutSignal) return;
      _lastAutoLogoutSignal = next;
      if (next > 0) {
        _showSnackBar('Sesi login berakhir, silakan login ulang.');
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _authSubscription?.close();
    _autoLogoutSubscription?.close();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _emailFocusNode.removeListener(_onEmailFocusChanged);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadEmailHistory() {
    final storage = ref.read(localStorageServiceProvider);
    setState(() {
      _emailHistory = storage.readEmailHistory();
    });
  }

  void _onEmailChanged() {
    final query = _emailController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmails = _emailHistory;
      } else {
        _filteredEmails = _emailHistory
            .where((email) => email.toLowerCase().contains(query))
            .toList();
      }
    });
    if (_filteredEmails.isNotEmpty && _emailFocusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onEmailFocusChanged() {
    if (_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
      _onEmailChanged();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 48,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredEmails.length,
                itemBuilder: (context, index) {
                  final email = _filteredEmails[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 20),
                    title: Text(email, style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      _emailController.text = email;
                      _emailController.selection = TextSelection.fromPosition(
                        TextPosition(offset: email.length),
                      );
                      _removeOverlay();
                      _passwordFocusNode.requestFocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.store_mall_directory_rounded,
                                  size: 60,
                                  color: AppColors.primaryBlue,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'SmartPOS',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Solusi Kasir Pintar Anda',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Masuk',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan masuk untuk melanjutkan',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Masukkan email Anda',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!value.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password Anda',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (value.length < 6) {
                        return 'Minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aman & Terenkripsi',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }
}
