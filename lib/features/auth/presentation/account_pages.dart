import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/api_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../trips/application/trips_providers.dart';
import '../../trips/domain/trip_models.dart';
import '../application/account_providers.dart';
import '../application/auth_controller.dart';
import '../data/account_repository.dart';
import '../domain/auth_contracts.dart';
import 'auth_pages.dart';

// Backend rules (PasswordRules, OTP): see LIVE_BACKEND.md.
String? _nameError(String? v) {
  final name = v?.trim() ?? '';
  if (name.isEmpty) return 'Nhập họ và tên.';
  if (name.length > 200) return 'Họ và tên tối đa 200 ký tự.';
  return null;
}

String? _emailError(String? v) =>
    LoginRequest(v ?? '', 'x').validate()['email']?.first;

String? _passwordError(String? v) {
  final p = v ?? '';
  if (p.trim().isEmpty) return 'Nhập mật khẩu.';
  if (p.length < 8) return 'Mật khẩu cần ít nhất 8 ký tự.';
  if (p.length > 128) return 'Mật khẩu tối đa 128 ký tự.';
  return null;
}

String? _codeError(String? v) => RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '')
    ? null
    : 'Nhập đủ 6 chữ số trong email.';

/// Centered single-column form page used by the account flows.
class _FormScaffold extends StatelessWidget {
  const _FormScaffold({
    required this.title,
    required this.heading,
    required this.message,
    required this.children,
    this.onBack,
  });
  final String title;
  final String heading;
  final String message;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Scaffold(
      appBar: AppTopBar(title: title, onBack: onBack, backTooltip: 'Quay lại'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(heading, style: text.headlineSmall),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Countdown for "Gửi lại mã".
class _ResendButton extends StatefulWidget {
  const _ResendButton({required this.seconds, required this.onResend});
  final int seconds;
  final Future<int?> Function() onResend;

  @override
  State<_ResendButton> createState() => _ResendButtonState();
}

class _ResendButtonState extends State<_ResendButton> {
  Timer? _timer;
  late int _left = widget.seconds;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      setState(() => _left = _left > 0 ? _left - 1 : 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    final next = await widget.onResend();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (next != null) _left = next;
    });
    if (next != null) _start();
  }

  @override
  Widget build(BuildContext context) => AppButton.ghost(
    label: _left > 0 ? 'Gửi lại mã sau $_left giây' : 'Gửi lại mã',
    icon: LucideIcons.refreshCw,
    expand: true,
    loading: _busy,
    onPressed: _left > 0 || _busy ? null : _resend,
  );
}

Widget _codeField(TextEditingController c, {required bool enabled}) =>
    AppTextField(
      fieldKey: const ValueKey('otp-code'),
      controller: c,
      label: 'Mã xác thực',
      hint: '6 chữ số',
      prefixIcon: LucideIcons.keyRound,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      maxLength: 6,
      enabled: enabled,
      autocorrect: false,
      enableSuggestions: false,
      validator: _codeError,
    );

/// `/register`: account details, then the 6-digit code from the email.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _code = TextEditingController();
  OtpDispatch? _sent;
  bool _busy = false;
  String? _error;

  AccountRepository get _repo => ref.read(accountRepositoryProvider);

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() => _run(() async {
    final sent = await _repo.register(
      fullName: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (mounted) setState(() => _sent = sent);
  });

  Future<void> _verify() => _run(() async {
    // Read before awaiting: the account exists once verified, so sign in
    // even if the user leaves this page meanwhile.
    final auth = ref.read(authProvider.notifier);
    final email = _sent!.email;
    final password = _password.text;
    await _repo.verifyRegistration(email, _code.text);
    await auth.login(email, password);
    if (!mounted) return;
    AppHaptics.success();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tạo tài khoản thành công. Chào mừng bạn!')),
    );
    context.go(ref.read(authProvider).authenticated ? '/account' : '/login');
  });

  Future<int?> _resend() async {
    try {
      final sent = await _repo.resendRegistration(_sent!.email);
      if (mounted) setState(() => _error = null);
      return sent.resendAfterSeconds;
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sent;
    final error = _error == null
        ? const <Widget>[]
        : [
            const SizedBox(height: AppSpacing.lg),
            AppBanner(kind: BannerKind.error, message: _error!),
          ];
    if (sent != null) {
      return _FormScaffold(
        title: 'Xác thực email',
        heading: 'Nhập mã xác thực',
        message:
            'Mã 6 chữ số đã được gửi tới ${sent.email}. Mã có hiệu lực trong ${sent.expiresInSeconds ~/ 60} phút.',
        onBack: () => setState(() {
          _sent = null;
          _error = null;
          _code.clear();
        }),
        children: [
          Form(
            key: _form,
            child: _codeField(_code, enabled: !_busy),
          ),
          ...error,
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            buttonKey: const ValueKey('register-verify'),
            label: 'Xác nhận và đăng nhập',
            icon: LucideIcons.circleCheck,
            expand: true,
            loading: _busy,
            onPressed: _busy ? null : _verify,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ResendButton(seconds: sent.resendAfterSeconds, onResend: _resend),
        ],
      );
    }
    return _FormScaffold(
      title: 'Tạo tài khoản',
      heading: 'Tạo tài khoản LocalMate',
      message: 'Lưu và chốt lịch trình, đồng bộ sở thích trên mọi thiết bị.',
      children: [
        AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  fieldKey: const ValueKey('register-name'),
                  controller: _name,
                  label: 'Họ và tên',
                  prefixIcon: LucideIcons.user,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  enabled: !_busy,
                  validator: _nameError,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  fieldKey: const ValueKey('register-email'),
                  controller: _email,
                  label: 'Email',
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  enabled: !_busy,
                  validator: _emailError,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  fieldKey: const ValueKey('register-password'),
                  controller: _password,
                  label: 'Mật khẩu',
                  helper: 'Ít nhất 8 ký tự.',
                  prefixIcon: LucideIcons.lock,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  autocorrect: false,
                  enableSuggestions: false,
                  enabled: !_busy,
                  validator: _passwordError,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  fieldKey: const ValueKey('register-confirm'),
                  controller: _confirm,
                  label: 'Nhập lại mật khẩu',
                  prefixIcon: LucideIcons.lock,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  enabled: !_busy,
                  validator: (v) => v == _password.text
                      ? null
                      : 'Mật khẩu nhập lại chưa khớp.',
                  onSubmitted: _busy ? null : (_) => _register(),
                ),
              ],
            ),
          ),
        ),
        ...error,
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          buttonKey: const ValueKey('register-submit'),
          label: 'Gửi mã xác thực',
          icon: LucideIcons.send,
          expand: true,
          loading: _busy,
          onPressed: _busy ? null : _register,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.ghost(
          label: 'Đã có tài khoản? Đăng nhập',
          expand: true,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}

/// `/forgot-password`: email, then code + new password.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  OtpDispatch? _sent;
  bool _busy = false;
  String? _error;

  AccountRepository get _repo => ref.read(accountRepositoryProvider);

  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request() => _run(() async {
    final sent = await _repo.requestPasswordReset(_email.text);
    if (mounted) setState(() => _sent = sent);
  });

  Future<void> _confirmReset() => _run(() async {
    await _repo.confirmPasswordReset(
      email: _sent!.email,
      code: _code.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    AppHaptics.success();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới.'),
      ),
    );
    context.go('/login');
  });

  Future<int?> _resend() async {
    try {
      final sent = await _repo.requestPasswordReset(_sent!.email);
      return sent.resendAfterSeconds;
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sent;
    final error = _error == null
        ? const <Widget>[]
        : [
            const SizedBox(height: AppSpacing.lg),
            AppBanner(kind: BannerKind.error, message: _error!),
          ];
    if (sent == null) {
      return _FormScaffold(
        title: 'Quên mật khẩu',
        heading: 'Đặt lại mật khẩu',
        message: 'Nhập email đã đăng ký, LocalMate sẽ gửi mã xác thực cho bạn.',
        children: [
          Form(
            key: _form,
            child: AppTextField(
              fieldKey: const ValueKey('reset-email'),
              controller: _email,
              label: 'Email',
              prefixIcon: LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              enabled: !_busy,
              validator: _emailError,
              onSubmitted: _busy ? null : (_) => _request(),
            ),
          ),
          ...error,
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            buttonKey: const ValueKey('reset-request'),
            label: 'Gửi mã xác thực',
            icon: LucideIcons.send,
            expand: true,
            loading: _busy,
            onPressed: _busy ? null : _request,
          ),
        ],
      );
    }
    return _FormScaffold(
      title: 'Quên mật khẩu',
      heading: 'Tạo mật khẩu mới',
      message: 'Nhập mã 6 chữ số đã gửi tới ${sent.email} và mật khẩu mới.',
      onBack: () => setState(() {
        _sent = null;
        _error = null;
      }),
      children: [
        AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _codeField(_code, enabled: !_busy),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  fieldKey: const ValueKey('reset-password'),
                  controller: _password,
                  label: 'Mật khẩu mới',
                  helper: 'Ít nhất 8 ký tự.',
                  prefixIcon: LucideIcons.lock,
                  obscure: true,
                  autofillHints: const [AutofillHints.newPassword],
                  autocorrect: false,
                  enableSuggestions: false,
                  enabled: !_busy,
                  validator: _passwordError,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  fieldKey: const ValueKey('reset-confirm'),
                  controller: _confirm,
                  label: 'Nhập lại mật khẩu mới',
                  prefixIcon: LucideIcons.lock,
                  obscure: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  enabled: !_busy,
                  validator: (v) => v == _password.text
                      ? null
                      : 'Mật khẩu nhập lại chưa khớp.',
                ),
              ],
            ),
          ),
        ),
        ...error,
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          buttonKey: const ValueKey('reset-confirm-submit'),
          label: 'Đặt lại mật khẩu',
          icon: LucideIcons.check,
          expand: true,
          loading: _busy,
          onPressed: _busy ? null : _confirmReset,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ResendButton(seconds: sent.resendAfterSeconds, onResend: _resend),
      ],
    );
  }
}

/// Editable profile: name, interests and travel styles (`PATCH /users/me`).
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _form = GlobalKey<FormState>();
  late final AuthProfile _initial;
  late final TextEditingController _name;
  late final Set<String> _interests;
  late final Set<String> _styles;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initial = ref.read(authProvider).profile!;
    _name = TextEditingController(text: _initial.fullName)
      ..addListener(() => setState(() {}));
    _interests = {..._initial.interestTagIds};
    _styles = {..._initial.travelStyleTagIds};
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool _same(Set<String> a, List<String> b) =>
      a.length == b.length && a.containsAll(b);

  bool get _nameChanged => _name.text.trim() != _initial.fullName.trim();
  bool get _prefsChanged =>
      !_same(_interests, _initial.interestTagIds) ||
      !_same(_styles, _initial.travelStyleTagIds);

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Read before awaiting: the save still lands if the page is left.
    final auth = ref.read(authProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = await ref
          .read(accountRepositoryProvider)
          .updateProfile(
            fullName: _nameChanged ? _name.text : null,
            interestTagIds: _prefsChanged ? _interests.toList() : null,
            travelStyleTagIds: _prefsChanged ? _styles.toList() : null,
          );
      auth.profileUpdated(profile);
      AppHaptics.success();
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã lưu hồ sơ của bạn.')),
      );
      if (mounted && navigator.canPop()) navigator.pop();
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = apiErrorMessage(e);
        });
      }
    }
  }

  Widget _tagGroup(List<TagOption> tags, Set<String> selected, String type) =>
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final t in tags.where((t) => t.type == type))
            AppFilterChip(
              key: ValueKey('profile-tag-${t.id}'),
              label: t.name,
              selected: selected.contains(t.id),
              onSelected: _busy
                  ? null
                  : () => setState(
                      () => selected.contains(t.id)
                          ? selected.remove(t.id)
                          : selected.add(t.id),
                    ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagOptionsProvider);
    final changed = _nameChanged || _prefsChanged;
    return Scaffold(
      appBar: const AppTopBar(title: 'Hồ sơ & cá nhân hóa'),
      bottomNavigationBar: AppBottomActionBar(
        children: [
          AppButton(
            buttonKey: const ValueKey('profile-save'),
            label: 'Lưu thay đổi',
            icon: LucideIcons.check,
            loading: _busy,
            onPressed: changed && !_busy ? _save : null,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            Center(
              child: AppAvatar(
                name: _name.text.trim().isEmpty ? null : _name.text,
                size: AppSizes.avatar * 2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _initial.email,
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            Form(
              key: _form,
              child: AppTextField(
                fieldKey: const ValueKey('profile-name'),
                controller: _name,
                label: 'Họ và tên',
                prefixIcon: LucideIcons.user,
                enabled: !_busy,
                validator: _nameError,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(
              title: 'Sở thích',
              subtitle: 'Gợi ý sẵn khi bạn tạo lịch trình',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.md),
            ...tags.when(
              skipLoadingOnRefresh: false,
              loading: () => const [SkeletonBlock(height: AppSpacing.xxxl * 2)],
              error: (e, _) => [
                AppErrorState(
                  compact: true,
                  title: 'Chưa tải được danh sách sở thích',
                  message: e is ApiFailure
                      ? apiErrorMessage(e)
                      : 'Vui lòng thử lại.',
                  onRetry: () => ref.invalidate(tagOptionsProvider),
                ),
              ],
              data: (all) => [
                _tagGroup(all, _interests, 'Interest'),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(
                  title: 'Phong cách du lịch',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.md),
                if (all.any((t) => t.type == 'TravelStyle'))
                  _tagGroup(all, _styles, 'TravelStyle')
                else
                  Text(
                    'Chưa có phong cách du lịch để chọn.',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppBanner(kind: BannerKind.error, message: _error!),
            ],
          ],
        ),
      ),
    );
  }
}

String _ago(DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inMinutes < 1) return 'Vừa xong';
  if (d.inHours < 1) return '${d.inMinutes} phút trước';
  if (d.inDays < 1) return '${d.inHours} giờ trước';
  if (d.inDays < 7) return '${d.inDays} ngày trước';
  final local = at.toUtc().add(const Duration(hours: 7));
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}

/// `/notifications` (live, signed in).
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    if (!n.isRead) {
      final feed = ref.read(notificationFeedProvider.notifier);
      try {
        await ref.read(accountRepositoryProvider).markRead(n.id);
        feed.markedRead(n.id);
      } on ApiFailure catch (_) {
        // Reading the target still works; the badge refreshes later.
      }
      if (context.mounted) ref.invalidate(unreadCountProvider);
    }
    if (!context.mounted) return;
    switch (n.targetType) {
      case 'Trip' when n.targetId != null:
        await context.push('/trips/${Uri.encodeComponent(n.targetId!)}');
      case 'CreateTrip':
        await context.push('/planner');
      case 'Subscription':
        await Navigator.of(context)
            .push<void>(MaterialPageRoute(builder: (_) => const PlansPage()));
    }
  }

  Future<void> _readAll(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final feed = ref.read(notificationFeedProvider.notifier);
    try {
      await ref.read(accountRepositoryProvider).markAllRead();
      feed.markedAllRead();
      if (context.mounted) ref.invalidate(unreadCountProvider);
    } on ApiFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(notificationFeedProvider);
    final hasUnread = page.asData?.value.items.any((n) => !n.isRead) ?? false;
    final scheme = context.colors;
    final text = context.textStyles;
    final now = DateTime.now().toUtc();
    return Scaffold(
      appBar: AppTopBar(
        title: 'Thông báo',
        actions: [
          if (hasUnread)
            AppIconButton(
              icon: LucideIcons.checkCheck,
              tooltip: 'Đánh dấu đã đọc tất cả',
              onPressed: () => _readAll(context, ref),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () {
            ref.invalidate(unreadCountProvider);
            return ref.refresh(notificationFeedProvider.future);
          },
          child: page.when(
            skipLoadingOnRefresh: false,
            loading: () => ListView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              children: const [
                SkeletonBlock(height: AppSpacing.xxxl * 1.5),
                SizedBox(height: AppSpacing.md),
                SkeletonBlock(height: AppSpacing.xxxl * 1.5),
              ],
            ),
            error: (e, _) => ListView(
              children: [
                AppErrorState(
                  title: 'Chưa tải được thông báo',
                  message: e is ApiFailure
                      ? apiErrorMessage(e)
                      : 'Vui lòng thử lại.',
                  onRetry: () => ref.invalidate(notificationFeedProvider),
                ),
              ],
            ),
            data: (data) => data.items.isEmpty
                ? ListView(
                    children: const [
                      AppEmptyState(
                        title: 'Chưa có thông báo',
                        message: 'Thông báo về lịch trình đã chốt và thanh toán sẽ xuất hiện ở đây.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    itemCount:
                        data.items.length +
                        (data.hasMore || data.moreError != null ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const Divider(indent: AppSpacing.gutter),
                    itemBuilder: (context, i) {
                      if (i == data.items.length) {
                        return _LoadMoreNotifications(data);
                      }
                      final n = data.items[i];
                      return Pressable(
                        key: ValueKey('notification-${n.id}'),
                        onTap: () => _open(context, ref, n),
                        semanticLabel:
                            '${n.isRead ? '' : 'Chưa đọc. '}${n.title}. ${n.body}',
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.gutter,
                              vertical: AppSpacing.md,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  switch (n.targetType) {
                                    'Trip' => LucideIcons.route,
                                    'Subscription' => LucideIcons.crown,
                                    'CreateTrip' => LucideIcons.sparkles,
                                    _ => LucideIcons.bell,
                                  },
                                  color: n.isRead
                                      ? scheme.onSurfaceVariant
                                      : scheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.title,
                                        style: text.titleSmall?.copyWith(
                                          fontWeight: n.isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(n.body, style: text.bodyMedium),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        _ago(n.createdAt, now),
                                        style: text.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!n.isRead)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.xs,
                                      left: AppSpacing.sm,
                                    ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const SizedBox.square(
                                        dimension: AppSpacing.sm,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

/// Footer of the notification list: older pages on demand.
class _LoadMoreNotifications extends ConsumerWidget {
  const _LoadMoreNotifications(this.feed);
  final NotificationFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = feed.moreError;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            AppBanner(kind: BannerKind.error, message: apiErrorMessage(error)),
            const SizedBox(height: AppSpacing.md),
          ],
          AppButton.secondary(
            buttonKey: const ValueKey('notifications-more'),
            label: error != null
                ? 'Thử tải lại'
                : feed.loadingMore
                ? 'Đang tải…'
                : 'Xem thông báo cũ hơn',
            icon: LucideIcons.chevronsDown,
            loading: feed.loadingMore,
            onPressed: feed.loadingMore
                ? null
                : ref.read(notificationFeedProvider.notifier).loadMore,
          ),
        ],
      ),
    );
  }
}
