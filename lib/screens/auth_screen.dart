import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_surfaces.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isSubmitting = false;
  String? _authInfoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate() || _isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _authInfoMessage = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      var successMessage = _isLogin ? 'Вход выполнен' : 'Аккаунт создан';

      if (_isLogin) {
        await auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        final response = await auth.signUp(
          email: email,
          password: password,
        );

        if (!mounted) {
          return;
        }

        if (response.session == null) {
          setState(() {
            _isLogin = true;
            _authInfoMessage =
                'Аккаунт создан, но вход пока не выполнен: в Supabase включено подтверждение email. Подтверди почту и затем войди.';
          });
          successMessage = 'Аккаунт создан. Подтверди email, чтобы войти.';
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось выполнить авторизацию. Повтори попытку.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppScreenBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF111827), Color(0xFF283548)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33111827),
                            blurRadius: 30,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35)
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'SUPABASE CONNECTED',
                              style: TextStyle(
                                color: Color(0xFFFFB089),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            _isLogin
                                ? 'Вход в TrainingApp'
                                : 'Создание аккаунта',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isLogin
                                ? 'Войди через Supabase, чтобы хранить прогресс, историю тренировок и данные профиля в облаке.'
                                : 'Создай аккаунт, чтобы позже синхронизировать тренировки, избранное и статистику между устройствами.',
                            style: const TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: appPanelDecoration(
                        context,
                        accent: const Color(0xFFFF6B35),
                        radius: 28,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _ModeButton(
                                    label: 'Вход',
                                    selected: _isLogin,
                                    onTap: () {
                                      setState(() {
                                        _isLogin = true;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ModeButton(
                                    label: 'Регистрация',
                                    selected: !_isLogin,
                                    onTap: () {
                                      setState(() {
                                        _isLogin = false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty || !email.contains('@')) {
                                  return 'Введи корректный email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              decoration: const InputDecoration(
                                labelText: 'Пароль',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final password = value?.trim() ?? '';
                                if (password.length < 6) {
                                  return 'Пароль должен быть не короче 6 символов';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                child: Text(
                                  _isSubmitting
                                      ? 'Подождите...'
                                      : (_isLogin
                                          ? 'Войти'
                                          : 'Создать аккаунт'),
                                ),
                              ),
                            ),
                            if (_authInfoMessage != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4EC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFF6B35)
                                        .withValues(alpha: 0.24),
                                  ),
                                ),
                                child: Text(
                                  _authInfoMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFF9A3412),
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Text(
                              _isLogin
                                  ? 'После входа откроется текущий сценарий onboarding или основное приложение.'
                                  : 'Если в проекте включено email confirmation, после регистрации понадобится подтвердить адрес почты.',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF6B7280),
                                fontSize: 13,
                                height: 1.45,
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
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF111827)
              : const Color(0xFFFF6B35).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF111827)
                : const Color(0xFFFF6B35).withValues(alpha: 0.18),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
