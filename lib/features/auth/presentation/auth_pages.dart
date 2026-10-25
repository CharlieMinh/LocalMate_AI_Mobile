import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/content_container.dart';
import '../../../shared/widgets/feedback_banner.dart';
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
        title: const Text('Đăng nhập'),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
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
                      Semantics(
                        label: 'LocalMate AI',
                        excludeSemantics: true,
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.3,
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/brand/logo.jpg',
                                width: 48,
                                height: 48,
                              ),
                              const SizedBox(width: 12),
                              const Flexible(
                                child: Text(
                                  'LocalMate',
                                  style: TextStyle(
                                    fontSize: 24,
                                    height: 1.3,
                                    fontWeight: FontWeight.w700,
                                    color: Brand.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Brand.navy,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Text(
                                    'AI',
                                    style: BrandTypography.brandBadge,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Chào mừng bạn trở lại',
                        style: BrandTypography.screenTitle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tiếp tục hành trình cùng LocalMate AI.',
                        style: BrandTypography.body,
                      ),
                      const SizedBox(height: 28),
                      const _AuthFieldLabel('Email'),
                      TextFormField(
                        key: const Key('login-email'),
                        controller: _email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'ban@example.invalid',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                        validator: (value) => LoginRequest(
                          value ?? '',
                          'x',
                        ).validate()['email']?.first,
                      ),
                      const SizedBox(height: 20),
                      const _AuthFieldLabel('Mật khẩu'),
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
                          floatingLabelBehavior: FloatingLabelBehavior.never,
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
                      const Text(
                        'hoặc dùng thông tin mẫu',
                        textAlign: TextAlign.center,
                        style: BrandTypography.metadata,
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
                      const FeedbackBanner(
                        kind: FeedbackBannerKind.warning,
                        message: 'M2 OFFLINE · Chỉ tài khoản mẫu. Không xác thực với Backend.',
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
                        style: BrandTypography.metadata,
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
    final profile = auth.profile;
    final name = auth.authenticated && profile!.fullName.trim().isNotEmpty
        ? profile.fullName
        : 'Bạn đồng hành';
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ColoredBox(
          color: Brand.surface,
          child: ContentContainer(
            verticalPadding: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Brand.infoSurface,
                      foregroundColor: Brand.navy,
                      child: Icon(Icons.person_outline, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: BrandTypography.screenTitle),
                          const SizedBox(height: 4),
                          Text(
                            auth.authenticated
                                ? profile!.email
                                : 'Bạn chưa đăng nhập',
                            style: BrandTypography.metadata,
                          ),
                          const SizedBox(height: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Brand.infoSurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                auth.authenticated
                                    ? 'Tài khoản mẫu · Offline'
                                    : 'Trải nghiệm offline',
                                style: BrandTypography.metadata.copyWith(
                                  color: Brand.navy,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (auth.phase == AuthPhase.restoring) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(
                    semanticsLabel: 'Đang khôi phục phiên mẫu',
                  ),
                ],
                const SizedBox(height: 24),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _AccountStat('Lịch trình đã lưu')),
                    SizedBox(width: 16),
                    Expanded(child: _AccountStat('Lịch trình đã chốt')),
                  ],
                ),
                const SizedBox(height: 16),
                const FeedbackBanner(
                  message: 'M2 OFFLINE · Phiên mô phỏng, không phải danh tính đã xác thực.',
                ),
                if (!auth.authenticated &&
                    auth.phase != AuthPhase.restoring) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.login),
                    label: const Text('Đăng nhập offline'),
                  ),
                ],
              ],
            ),
          ),
        ),
        ContentContainer(
          verticalPadding: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccountSectionTitle(
                title: 'Sở thích của bạn',
                action: 'Xem',
                onAction: () => _showAccountPage(
                  context,
                  title: 'Hồ sơ & cá nhân hóa',
                  children: [
                    const _AuthFieldLabel('Họ và tên'),
                    InputDecorator(
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.lock_outline, size: 18),
                      ),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final session = ref.watch(authProvider);
                          final fullName = session.profile?.fullName.trim();
                          return Text(
                            session.authenticated &&
                                    (fullName?.isNotEmpty ?? false)
                                ? fullName!
                                : 'Chưa có thông tin tài khoản',
                            style: BrandTypography.body,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Sở thích', style: BrandTypography.sectionTitle),
                    const SizedBox(height: 12),
                    const FeedbackBanner(
                      message: 'Chưa có dữ liệu sở thích tài khoản. Bạn vẫn có thể chọn sở thích riêng khi tạo lịch trình mẫu.',
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Phong cách du lịch',
                      style: BrandTypography.sectionTitle,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chưa được kết nối · Không lưu thay đổi hồ sơ trong bản offline.',
                      style: BrandTypography.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Chưa có sở thích tài khoản được đồng bộ.',
                style: BrandTypography.body,
              ),
              const SizedBox(height: 28),
              _AccountSectionTitle(
                title: 'Gói & quyền sử dụng',
                action: 'Xem',
                onAction: () => _showAccountPage(
                  context,
                  title: 'Gói & quyền sử dụng',
                  children: const [
                    Text('Gói hiện tại', style: BrandTypography.sectionTitle),
                    SizedBox(height: 12),
                    FeedbackBanner(
                      kind: FeedbackBannerKind.warning,
                      message: 'Chưa tải được thông tin gói. Không thể xác nhận gói, hạn mức hoặc quyền sử dụng.',
                    ),
                    SizedBox(height: 28),
                    Text(
                      'Các gói dịch vụ',
                      style: BrandTypography.sectionTitle,
                    ),
                    SizedBox(height: 12),
                    _UnavailablePlanRow('Trip Pass'),
                    _UnavailablePlanRow('Membership'),
                    SizedBox(height: 24),
                    Text(
                      'Quyền chốt một lịch trình',
                      style: BrandTypography.sectionTitle,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Chưa có dữ liệu quyền mua lẻ. Bản offline không báo giá, mua gói hoặc xác nhận thanh toán.',
                      style: BrandTypography.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Brand.navy, width: 3)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 14, top: 4, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chưa xác minh',
                        style: BrandTypography.sectionTitle,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Gói dịch vụ và hạn mức chưa được kết nối.',
                        style: BrandTypography.metadata,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _AccountMenuRow(
                icon: Icons.wallet_outlined,
                label: 'Lịch trình cá nhân',
                onTap: () => context.go('/trips'),
              ),
              _AccountMenuRow(
                icon: Icons.notifications_none,
                label: 'Thông báo',
                onTap: () => _showAccountSheet(
                  context,
                  title: 'Thông báo',
                  children: const [
                    FeedbackBanner(
                      message: 'Thông báo chưa được kết nối trong bản offline. Ứng dụng không yêu cầu quyền thông báo.',
                    ),
                  ],
                ),
              ),
              _AccountMenuRow(
                icon: Icons.info_outline,
                label: 'Về LocalMate AI',
                onTap: () => _showAccountSheet(
                  context,
                  title: 'Về LocalMate AI',
                  children: const [
                    Text(
                      'Một hành trình theo gu bạn',
                      style: BrandTypography.screenTitle,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Khám phá địa điểm quanh ga, tham khảo Metro và thử xây dựng lịch trình mẫu.',
                      style: BrandTypography.body,
                    ),
                    SizedBox(height: 16),
                    FeedbackBanner(
                      message: 'Bản trải nghiệm offline · Không gọi Backend hoặc AI, không lưu Trip hay thực hiện thanh toán.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (auth.notice case final notice?) ...[
                FeedbackBanner(message: notice),
                const SizedBox(height: 12),
              ],
              if (auth.error case final error?) ...[
                FeedbackBanner(
                  kind: FeedbackBannerKind.error,
                  message: authErrorMessage(error),
                ),
                const SizedBox(height: 12),
              ],
              if (auth.phase != AuthPhase.restoring)
                if (auth.authenticated) ...[
                  OutlinedButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                  ),
                  const SizedBox(height: 8),
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
                    style: BrandTypography.metadata,
                  ),
                  const SizedBox(height: 16),
                  if (auth.error != null)
                    TextButton(
                      onPressed: () =>
                          ref.read(authProvider.notifier).restore(),
                      child: const Text('Thử khôi phục phiên'),
                    ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountStat extends StatelessWidget {
  const _AccountStat(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: chưa có dữ liệu',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Brand.line, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('—', style: BrandTypography.screenTitle),
          const SizedBox(height: 4),
          Text(label, style: BrandTypography.metadata),
          const Text('Chưa đồng bộ', style: BrandTypography.metadata),
        ],
      ),
    ),
  );
}

void _showAccountPage(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: ListView(
            children: [
              ContentContainer(
                verticalPadding: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AuthFieldLabel extends StatelessWidget {
  const _AuthFieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: BrandTypography.choice),
  );
}

class _AccountSectionTitle extends StatelessWidget {
  const _AccountSectionTitle({
    required this.title,
    required this.action,
    required this.onAction,
  });
  final String title, action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: BrandTypography.sectionTitle)),
      const SizedBox(width: 8),
      TextButton.icon(
        key: ValueKey('account-section-$title'),
        onPressed: onAction,
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.chevron_right, size: 16),
        label: Text(
          action,
          style: BrandTypography.choice.copyWith(color: Brand.navy),
        ),
      ),
    ],
  );
}

class _AccountMenuRow extends StatelessWidget {
  const _AccountMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Brand.canvas,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      tileColor: Brand.canvas,
      shape: const Border(bottom: BorderSide(color: Brand.line)),
      leading: Icon(icon, size: 22, color: Brand.navy),
      title: Text(label, style: BrandTypography.body),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Brand.navy),
      onTap: onTap,
    ),
  );
}

class _UnavailablePlanRow extends StatelessWidget {
  const _UnavailablePlanRow(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Brand.line)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (MediaQuery.textScalerOf(context).scale(12) > 18) ...[
            Text(title, style: BrandTypography.sectionTitle),
            const SizedBox(height: 8),
            const Text('Chưa tải giá', style: BrandTypography.metadata),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(title, style: BrandTypography.sectionTitle),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('—', style: BrandTypography.sectionTitle),
                    Text('Chưa tải giá', style: BrandTypography.metadata),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 6),
          const Text(
            'Chưa tải giá và quyền lợi. Không có thao tác mua trong bản offline.',
            style: BrandTypography.metadata,
          ),
        ],
      ),
    ),
  );
}

void _showAccountSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Brand.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      minChildSize: .45,
      maxChildSize: .95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        children: [
          ColoredBox(
            color: Brand.surface,
            child: ContentContainer(
              verticalPadding: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: BrandTypography.sectionTitle),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
          ContentContainer(
            verticalPadding: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    ),
  );
}
