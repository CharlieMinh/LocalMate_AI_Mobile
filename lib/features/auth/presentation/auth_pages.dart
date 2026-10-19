import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../shared/theme/app_theme.dart';
import '../application/auth_controller.dart';
import '../domain/auth_contracts.dart';

String authErrorMessage(ApiFailure error) => switch (error.code) {
  'invalid_credentials' => 'Email hoặc mật khẩu không đúng.',
  'account_locked' => 'Tài khoản đã bị khóa.',
  'account_not_found' => 'Tài khoản không còn tồn tại.',
  'account_link_required' =>
    'Email này cần liên kết tài khoản trước khi dùng Google.',
  'account_conflict' => 'Thông tin tài khoản Google không khớp.',
  'session_expired' => 'Phiên đã hết hạn. Vui lòng đăng nhập lại.',
  'session_storage_failed' =>
    'Không thể lưu hoặc xóa phiên an toàn. Hãy thử lại.',
  'invalid_auth_response' => 'Dữ liệu phiên không hợp lệ. Hãy đăng nhập lại.',
  _ => switch (error.kind) {
    FailureKind.validation => 'Kiểm tra lại thông tin đăng nhập.',
    FailureKind.unavailable => 'Không thể kết nối mô phỏng. Vui lòng thử lại.',
    FailureKind.unauthorized => 'Phiên không hợp lệ. Vui lòng đăng nhập lại.',
    FailureKind.forbidden => 'Tài khoản chưa được phép thực hiện thao tác này.',
    _ => 'Chưa thể đăng nhập. Vui lòng thử lại.',
  },
};

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late AuthController _controller;
  bool _obscured = true;
  @override
  void initState() {
    super.initState();
    _controller = ref.read(authProvider.notifier);
  }

  @override
  void dispose() {
    _controller.cancelPendingLogin();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      _controller.login(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final busy =
        auth.phase == AuthPhase.submitting || auth.phase == AuthPhase.restoring;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập offline'),
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _controller.cancelPendingLogin();
            context.go('/account');
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/brand/logo.jpg',
                          height: 64,
                          semanticLabel: 'Logo LocalMate AI',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Chào mừng bạn trở lại',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'M2 OFFLINE · Chỉ tài khoản mẫu. Không xác thực với Backend.',
                        style: TextStyle(color: Brand.navy),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('login-email'),
                        controller: _email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) => LoginRequest(
                          value ?? '',
                          'x',
                        ).validate()['email']?.first,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('login-password'),
                        controller: _password,
                        enabled: !busy,
                        obscureText: _obscured,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: busy ? null : (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscured
                                ? 'Hiện mật khẩu'
                                : 'Ẩn mật khẩu',
                            onPressed: busy
                                ? null
                                : () => setState(() => _obscured = !_obscured),
                            icon: Icon(
                              _obscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Nhập mật khẩu.'
                            : null,
                      ),
                      if (auth.error case final error?)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              authErrorMessage(error),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      if (auth.error?.fields.isNotEmpty ?? false)
                        for (final messages in auth.error!.fields.values)
                          for (final message in messages) Text(message),
                      if (auth.notice case final notice?)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(notice),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('login-submit'),
                        onPressed: busy ? null : _submit,
                        icon: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          busy
                              ? 'Đang xử lý…'
                              : auth.error == null
                              ? 'Đăng nhập mẫu'
                              : 'Thử đăng nhập lại',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () {
                                _email.text = 'traveler@localmate.invalid';
                                _password.text = 'offline-only';
                              },
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('Điền tài khoản mẫu'),
                      ),
                      const SizedBox(height: 20),
                      const Tooltip(
                        message:
                            'Google OAuth chưa được cấu hình hoặc xác minh',
                        child: OutlinedButton(
                          onPressed: null,
                          child: Text('Tiếp tục với Google'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Google chưa khả dụng trong bản offline.',
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class AuthAccountPage extends ConsumerWidget {
  const AuthAccountPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Một hành trình theo gu bạn',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const Text(
          'M2 OFFLINE · Phiên mô phỏng, không phải danh tính đã xác thực.',
        ),
        const SizedBox(height: 24),
        if (auth.phase == AuthPhase.restoring)
          const Center(child: CircularProgressIndicator())
        else if (auth.authenticated) ...[
          Text(
            auth.profile!.fullName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(auth.profile!.email),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Đổi tài khoản mẫu'),
          ),
        ] else ...[
          const Text(
            'Bạn chưa đăng nhập. Gói dịch vụ, quota và chuyến đi chưa được kết nối.',
          ),
          if (auth.notice case final notice?) Text(notice),
          if (auth.error case final error?) Text(authErrorMessage(error)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Đăng nhập offline'),
          ),
          if (auth.error != null)
            TextButton(
              onPressed: () => ref.read(authProvider.notifier).restore(),
              child: const Text('Thử khôi phục phiên'),
            ),
        ],
      ],
    );
  }
}
