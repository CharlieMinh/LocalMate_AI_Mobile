import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/providers.dart';
import '../../../app/ui_providers.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/network/api_messages.dart';
import '../../../shared/formatters.dart';
import '../../trips/application/trips_providers.dart';
import '../../trips/domain/trip_models.dart';
import '../application/account_providers.dart';
import '../application/auth_controller.dart';
import '../domain/auth_contracts.dart';
import '../../payments/presentation/payment_pages.dart';
import 'account_pages.dart';

String authErrorMessage(ApiFailure error) => switch (error.code) {
  'invalid_credentials' => 'Email hoặc mật khẩu không đúng.',
  'account_locked' => 'Tài khoản đã bị khóa.',
  'account_not_found' => 'Tài khoản không còn tồn tại.',
  'account_link_required' =>
    'Email này đã đăng ký bằng mật khẩu. Hãy đăng nhập bằng email và mật khẩu.',
  'invalid_google_token' =>
    'Không xác thực được tài khoản Google. Vui lòng thử lại.',
  'google_sign_in_failed' =>
    'Chưa đăng nhập được bằng Google. Vui lòng thử lại.',
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

/// Centers page content and caps its width (forms read best narrow).
class _Narrow extends StatelessWidget {
  const _Narrow({required this.child, this.maxWidth = 480});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

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
    final live = ref.watch(liveBackendProvider);
    final google = ref.watch(configProvider).googleSignInEnabled;
    final text = context.textStyles;
    final scheme = context.colors;
    return Scaffold(
      appBar: AppTopBar(
        title: 'Đăng nhập',
        backTooltip: 'Quay lại',
        onBack: () {
          _controller.cancelPendingLogin();
          context.go('/account');
        },
      ),
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
          child: _Narrow(
            child: AutofillGroup(
              onDisposeAction: AutofillContextAction.cancel,
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BrandLockup(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Semantics(
                      header: true,
                      child: Text(
                        'Chào mừng bạn trở lại',
                        style: text.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tiếp tục hành trình cùng LocalMate AI.',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      fieldKey: const Key('login-email'),
                      label: 'Email',
                      hint: 'ban@example.invalid',
                      controller: _email,
                      enabled: !busy,
                      prefixIcon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      validator: (value) => LoginRequest(
                        value ?? '',
                        'x',
                      ).validate()['email']?.first,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      fieldKey: const Key('login-password'),
                      label: 'Mật khẩu',
                      controller: _password,
                      enabled: !busy,
                      obscure: true,
                      prefixIcon: LucideIcons.lock,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: busy ? null : (_) => _submit(),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nhập mật khẩu.'
                          : null,
                    ),
                    if (auth.error case final error?) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppBanner(
                        kind: BannerKind.error,
                        message: authErrorMessage(error),
                      ),
                    ],
                    if (auth.error?.fields.isNotEmpty ?? false)
                      for (final messages in auth.error!.fields.values)
                        for (final message in messages)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              message,
                              style: text.bodySmall?.copyWith(
                                color: scheme.error,
                              ),
                            ),
                          ),
                    if (auth.notice case final notice?) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppBanner(message: notice),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      buttonKey: const Key('login-submit'),
                      label: busy
                          ? 'Đang xử lý…'
                          : auth.error != null
                          ? 'Thử đăng nhập lại'
                          : live
                          ? 'Đăng nhập'
                          : 'Đăng nhập mẫu',
                      icon: LucideIcons.logIn,
                      loading: busy,
                      expand: true,
                      haptic: true,
                      onPressed: busy ? null : _submit,
                    ),
                    if (live) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          AppButton.ghost(
                            buttonKey: const Key('login-forgot'),
                            label: 'Quên mật khẩu?',
                            compact: true,
                            onPressed: busy
                                ? null
                                : () => context.push('/forgot-password'),
                          ),
                          AppButton.ghost(
                            buttonKey: const Key('login-register'),
                            label: 'Tạo tài khoản',
                            compact: true,
                            trailingIcon: LucideIcons.arrowRight,
                            onPressed: busy
                                ? null
                                : () => context.push('/register'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (!live) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Flexible(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text(
                                'hoặc dùng thông tin mẫu',
                                textAlign: TextAlign.center,
                                style: text.bodySmall,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton.tonal(
                        label: 'Điền tài khoản mẫu',
                        icon: LucideIcons.flaskConical,
                        expand: true,
                        onPressed: busy
                            ? null
                            : () {
                                _email.text = 'traveler@localmate.invalid';
                                _password.text = 'offline-only';
                              },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    if (google)
                      AppButton.secondary(
                        buttonKey: const Key('login-google'),
                        label: 'Tiếp tục với Google',
                        icon: LucideIcons.globe,
                        expand: true,
                        onPressed: busy ? null : _controller.loginWithGoogle,
                      )
                    else ...[
                      const Tooltip(
                        message:
                            'Google OAuth chưa được cấu hình hoặc xác minh',
                        child: AppButton.secondary(
                          label: 'Tiếp tục với Google',
                          icon: LucideIcons.globe,
                          expand: true,
                          onPressed: null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        live
                            ? 'Đăng nhập Google chưa được cấu hình cho bản này.'
                            : 'Google chưa khả dụng trong bản offline.',
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                    ],
                    if (!live) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const AppBanner(
                        kind: BannerKind.warning,
                        icon: LucideIcons.flaskConical,
                        message:
                            'Chỉ tài khoản mẫu. Không xác thực với Backend.',
                      ),
                    ],
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

class AuthAccountPage extends ConsumerWidget {
  const AuthAccountPage({super.key, this.showHeader = true});

  /// False when embedded under another app bar (the `/private` route).
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
    final name = auth.authenticated && profile!.fullName.trim().isNotEmpty
        ? profile.fullName
        : 'Bạn đồng hành';
    final text = context.textStyles;
    final scheme = context.colors;
    final restoring = auth.phase == AuthPhase.restoring;
    final live = ref.watch(liveBackendProvider);
    final sub = live ? ref.watch(subscriptionProvider).asData?.value : null;
    String quota(int used, int? limit) =>
        '$used / ${limit ?? 'không giới hạn'}';

    final body = _Narrow(
      maxWidth: AppSpacing.maxContentWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        name: auth.authenticated ? profile!.fullName : null,
                        size: AppSizes.avatar + AppSpacing.md,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: text.titleLarge),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              auth.authenticated
                                  ? profile!.email
                                  : 'Bạn chưa đăng nhập',
                              style: text.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            StatusChip(
                              label: live
                                  ? (auth.authenticated
                                        ? 'Đã đăng nhập'
                                        : 'Chưa đăng nhập')
                                  : auth.authenticated
                                  ? 'Tài khoản mẫu · Offline'
                                  : 'Trải nghiệm offline',
                              icon: live
                                  ? LucideIcons.user
                                  : LucideIcons.flaskConical,
                              kind: StatusKind.info,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (restoring) ...[
                    const SizedBox(height: AppSpacing.lg),
                    LinearProgressIndicator(
                      semanticsLabel: live
                          ? 'Đang khôi phục phiên đăng nhập'
                          : 'Đang khôi phục phiên mẫu',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _AccountStat(
                          icon: LucideIcons.bookmark,
                          label: 'Lịch trình đã lưu',
                          value: sub == null
                              ? null
                              : quota(sub.savedUsed, sub.savedLimit),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _AccountStat(
                          icon: sub == null
                              ? LucideIcons.circleCheck
                              : LucideIcons.sparkles,
                          label: sub == null
                              ? 'Lịch trình đã chốt'
                              : 'Lượt tạo tháng này',
                          value: sub == null
                              ? null
                              : quota(sub.generateUsed, sub.generateLimit),
                        ),
                      ),
                    ],
                  ),
                  if (!auth.authenticated && !restoring) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: live ? 'Đăng nhập' : 'Đăng nhập offline',
                      icon: LucideIcons.logIn,
                      expand: true,
                      onPressed: () => context.go('/login'),
                    ),
                  ],
                ],
              ),
            ),
            if (!live) ...[
              const SizedBox(height: AppSpacing.md),
              const AppBanner(
                icon: LucideIcons.flaskConical,
                message: 'Phiên mô phỏng, không phải danh tính đã xác thực.',
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _SectionCard(
              title: 'Sở thích của bạn',
              icon: LucideIcons.heart,
              onOpen: () => _push(context, const PersonalizationPage()),
              child: Text(
                live && auth.authenticated
                    ? '${profile!.interestTagIds.length} sở thích · '
                          '${profile.travelStyleTagIds.length} phong cách đã lưu'
                    : 'Chưa có sở thích tài khoản được đồng bộ.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Gói & quyền sử dụng',
              icon: LucideIcons.crown,
              onOpen: () => _push(context, const PlansPage()),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (sub != null) ...[
                    StatusChip(
                      label: sub.planName,
                      kind: StatusKind.info,
                      icon: LucideIcons.crown,
                    ),
                    Text(
                      'Đã tạo ${quota(sub.generateUsed, sub.generateLimit)} lịch trình tháng này',
                      style: text.bodySmall,
                    ),
                  ] else ...[
                    StatusChip(
                      label: live && !auth.authenticated
                          ? 'Cần đăng nhập'
                          : 'Chưa xác minh',
                      kind: StatusKind.draft,
                    ),
                    Text(
                      live
                          ? 'Đăng nhập để xem gói và hạn mức.'
                          : 'Gói dịch vụ và hạn mức chưa được kết nối.',
                      style: text.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Card(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuRow(
                    icon: LucideIcons.route,
                    label: 'Lịch trình của tôi',
                    onTap: () => context.go('/trips'),
                  ),
                  _MenuRow(
                    icon: LucideIcons.bell,
                    label: 'Thông báo',
                    trailing: switch (ref.watch(unreadCountProvider).value) {
                      final n? when n > 0 => '$n chưa đọc',
                      _ => null,
                    },
                    onTap: live && auth.authenticated
                        ? () => context.push('/notifications')
                        : () => showAppBottomSheet<void>(
                            context: context,
                            title: 'Thông báo',
                            builder: (_) => AppEmptyState(
                              compact: true,
                              title: live
                                  ? 'Đăng nhập để xem thông báo'
                                  : 'Chưa có thông báo',
                              message: live
                                  ? 'Thông báo về lịch trình đã chốt và thanh toán được lưu theo tài khoản.'
                                  : 'Thông báo chưa được kết nối trong bản offline. Ứng dụng không yêu cầu quyền thông báo.',
                            ),
                          ),
                  ),
                  _MenuRow(
                    icon: LucideIcons.sunMoon,
                    label: 'Giao diện',
                    trailing: switch (ref.watch(themeModeProvider)) {
                      ThemeMode.light => 'Sáng',
                      ThemeMode.dark => 'Tối',
                      ThemeMode.system => 'Theo hệ thống',
                    },
                    onTap: () => _showAppearanceSheet(context),
                  ),
                  _MenuRow(
                    icon: LucideIcons.info,
                    label: 'Về LocalMate AI',
                    last: true,
                    onTap: () => showAppBottomSheet<void>(
                      context: context,
                      title: 'Về LocalMate AI',
                      builder: (context) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Một hành trình theo gu bạn',
                            style: context.textStyles.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            live
                                ? 'Khám phá địa điểm quanh ga Metro số 1, tạo lịch trình theo sở thích và lưu lại để đi.'
                                : 'Khám phá địa điểm quanh ga, tham khảo Metro và thử xây dựng lịch trình mẫu.',
                            style: context.textStyles.bodyMedium,
                          ),
                          if (!live) ...[
                            const SizedBox(height: AppSpacing.lg),
                            const AppBanner(
                              message: 'Bản trải nghiệm offline · Không gọi Backend hoặc AI, không lưu Trip hay thực hiện thanh toán.',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (auth.notice case final notice?) ...[
              AppBanner(message: notice),
              const SizedBox(height: AppSpacing.md),
            ],
            if (auth.error case final error?) ...[
              AppBanner(
                kind: BannerKind.error,
                message: authErrorMessage(error),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!restoring)
              if (auth.authenticated) ...[
                AppButton.secondary(
                  label: 'Đăng xuất',
                  icon: LucideIcons.logOut,
                  expand: true,
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.ghost(
                  label: live
                      ? 'Đăng nhập tài khoản khác'
                      : 'Đổi tài khoản mẫu',
                  expand: true,
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ] else ...[
                Text(
                  live
                      ? 'Đăng nhập để lưu và chốt lịch trình, xem gói và hạn mức của bạn.'
                      : 'Bạn chưa đăng nhập. Gói dịch vụ, quota và chuyến đi chưa được kết nối.',
                  style: text.bodySmall,
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton.ghost(
                    label: 'Thử khôi phục phiên',
                    icon: LucideIcons.refreshCw,
                    onPressed: () => ref.read(authProvider.notifier).restore(),
                  ),
                ],
              ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );

    return CustomScrollView(
      slivers: [
        if (showHeader)
          const AppLargeTitleBar(title: 'Tài khoản', showBack: false)
        else
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverToBoxAdapter(child: body),
      ],
    );
  }
}

Future<void> _push(BuildContext context, Widget page) => Navigator.of(
  context,
  rootNavigator: true,
).push<void>(MaterialPageRoute(builder: (_) => page));

Future<void> _showAppearanceSheet(BuildContext context) =>
    showAppBottomSheet<void>(
      context: context,
      title: 'Giao diện',
      subtitle: 'Áp dụng cho toàn bộ ứng dụng',
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final mode = ref.watch(themeModeProvider);
          return RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (value) {
              if (value == null) return;
              AppHaptics.selection();
              ref.read(themeModeProvider.notifier).set(value);
            },
            child: const Column(
              children: [
                RadioListTile(
                  value: ThemeMode.system,
                  title: Text('Theo hệ thống'),
                  secondary: Icon(LucideIcons.smartphone),
                ),
                RadioListTile(
                  value: ThemeMode.light,
                  title: Text('Sáng'),
                  secondary: Icon(LucideIcons.sun),
                ),
                RadioListTile(
                  value: ThemeMode.dark,
                  title: Text('Tối'),
                  secondary: Icon(LucideIcons.moon),
                ),
              ],
            ),
          );
        },
      ),
    );

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.highlighted = false,
  });
  final Widget child;
  final EdgeInsets padding;

  /// Primary 2px outline (e.g. the user's current plan).
  final bool highlighted;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadius.card,
      border: Border.all(
        color: highlighted ? context.colors.primary : context.colors.outline,
        width: highlighted ? AppSizes.focusRing : AppSizes.hairline,
      ),
    ),
    child: ClipRRect(
      borderRadius: AppRadius.card,
      // Ink (ListTile ripples) must paint above the card colour.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class _AccountStat extends StatelessWidget {
  const _AccountStat({required this.icon, required this.label, this.value});
  final IconData icon;
  final String label;

  /// Null when the backend has not provided the number (mock / signed out).
  final String? value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: ${value ?? 'chưa có dữ liệu'}',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: AppRadius.control,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.icon, color: context.colors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: context.textStyles.labelMedium),
          Text(
            value ?? 'Chưa đồng bộ',
            style: value == null
                ? context.textStyles.bodySmall
                : context.textStyles.titleSmall,
          ),
        ],
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.onOpen,
    required this.child,
  });
  final String title;
  final IconData icon;
  final VoidCallback onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: AppSizes.icon, color: context.colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: context.textStyles.titleSmall),
              ),
            ),
            TextButton(
              key: ValueKey('account-section-$title'),
              onPressed: onOpen,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Xem'),
                  SizedBox(width: AppSpacing.xs),
                  Icon(LucideIcons.chevronRight, size: AppSizes.iconSm),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    ),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.last = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: ListTile(
        shape: const RoundedRectangleBorder(),
        leading: Container(
          width: AppSpacing.xxl + AppSpacing.xs,
          height: AppSpacing.xxl + AppSpacing.xs,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
          child: Icon(icon, size: AppSizes.icon, color: scheme.primary),
        ),
        title: Text(label),
        subtitle: trailing == null ? null : Text(trailing!),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: AppSizes.icon,
          color: scheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// "Hồ sơ & cá nhân hóa": profile fields and preferences. Read-only until
/// `PATCH /api/users/me` is wired (Phase 4).
class PersonalizationPage extends ConsumerWidget {
  const PersonalizationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider);
    if (ref.watch(liveBackendProvider) && session.authenticated) {
      return const ProfileEditPage();
    }
    final fullName = session.profile?.fullName.trim();
    final text = context.textStyles;
    return Scaffold(
      appBar: const AppTopBar(title: 'Hồ sơ & cá nhân hóa'),
      bottomNavigationBar: const AppBottomActionBar(
        children: [
          AppButton(
            label: 'Lưu thay đổi',
            icon: LucideIcons.check,
            onPressed: null,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            _Narrow(
              maxWidth: AppSpacing.maxContentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: AppAvatar(
                      name: session.authenticated ? fullName : null,
                      size: AppSizes.avatar * 2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Họ và tên', style: text.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  InputDecorator(
                    decoration: const InputDecoration(
                      enabled: false,
                      prefixIcon: Icon(LucideIcons.user, size: AppSizes.icon),
                      suffixIcon: Icon(LucideIcons.lock, size: AppSizes.iconSm),
                    ),
                    child: Text(
                      session.authenticated && (fullName?.isNotEmpty ?? false)
                          ? fullName!
                          : 'Chưa có thông tin tài khoản',
                      style: text.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(
                    title: 'Sở thích',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (ref.watch(liveBackendProvider) && session.authenticated)
                    _SavedTags(
                      ids: [
                        ...session.profile!.interestTagIds,
                        ...session.profile!.travelStyleTagIds,
                      ],
                    )
                  else
                    AppBanner(
                      message: ref.watch(liveBackendProvider)
                          ? 'Đăng nhập để lưu sở thích. Bạn vẫn có thể chọn sở thích riêng khi tạo lịch trình.'
                          : 'Chưa có dữ liệu sở thích tài khoản. Bạn vẫn có thể chọn sở thích riêng khi tạo lịch trình mẫu.',
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(
                    title: 'Phong cách du lịch',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ref.watch(liveBackendProvider)
                        ? 'Đăng nhập để chọn phong cách du lịch.'
                        : 'Chưa được kết nối · Không lưu thay đổi hồ sơ trong bản offline.',
                    style: text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Gói & quyền sử dụng": honest unavailable state until the subscription
/// endpoints are wired (Phase 4). Never shows invented prices.
class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(liveBackendProvider) ? const _LivePlansPage() : _mock(context);

  Widget _mock(BuildContext context) => Scaffold(
    appBar: const AppTopBar(title: 'Gói & quyền sử dụng'),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          _Narrow(
            maxWidth: AppSpacing.maxContentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'Gói hiện tại',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.md),
                const AppBanner(
                  kind: BannerKind.warning,
                  message: 'Chưa tải được thông tin gói. Không thể xác nhận gói, hạn mức hoặc quyền sử dụng.',
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(
                  title: 'Các gói dịch vụ',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.md),
                const _PlanCard(title: 'Trip Pass', icon: LucideIcons.ticket),
                const SizedBox(height: AppSpacing.md),
                const _PlanCard(title: 'Membership', icon: LucideIcons.crown),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(
                  title: 'Quyền chốt một lịch trình',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Chưa có dữ liệu quyền mua lẻ. Bản offline không báo giá, mua gói hoặc xác nhận thanh toán.',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final text = context.textStyles;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.avatar,
                height: AppSizes.avatar,
                decoration: BoxDecoration(
                  color: app.warningContainer,
                  borderRadius: AppRadius.control,
                ),
                child: Icon(icon, color: app.onWarningContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: text.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Chưa tải giá', style: text.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Chưa tải giá và quyền lợi. Không có thao tác mua trong bản offline.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Saved preference tags rendered by name (`GET /api/tags`).
class _SavedTags extends ConsumerWidget {
  const _SavedTags({required this.ids});
  final List<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ids.isEmpty) {
      return const AppBanner(
        message: 'Bạn chưa lưu sở thích nào. Bạn vẫn có thể chọn sở thích riêng khi tạo lịch trình.',
      );
    }
    final tags = ref.watch(tagOptionsProvider).asData?.value ?? const [];
    final names = {for (final t in tags) t.id: t.name};
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final id in ids)
          StatusChip(
            label: names[id] ?? 'Đang tải…',
            kind: StatusKind.info,
            icon: LucideIcons.heart,
          ),
      ],
    );
  }
}

/// Plans and the signed-in user's usage from the backend.
class _LivePlansPage extends ConsumerWidget {
  const _LivePlansPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    final sub = ref.watch(subscriptionProvider).asData?.value;
    final text = context.textStyles;
    return Scaffold(
      appBar: const AppTopBar(title: 'Gói & quyền sử dụng'),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(plansProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              _Narrow(
                maxWidth: AppSpacing.maxContentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      title: 'Gói hiện tại',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (sub == null)
                      const AppBanner(
                        kind: BannerKind.warning,
                        message: 'Đăng nhập để xem gói và hạn mức của bạn.',
                      )
                    else
                      _UsageCard(sub: sub),
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(
                      title: 'Các gói dịch vụ',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    plans.when(
                      skipLoadingOnRefresh: false,
                      loading: () => const Column(
                        children: [
                          SkeletonBlock(
                            height: AppSpacing.xxxl * 2,
                            radius: AppRadius.lg,
                          ),
                          SizedBox(height: AppSpacing.md),
                          SkeletonBlock(
                            height: AppSpacing.xxxl * 2,
                            radius: AppRadius.lg,
                          ),
                        ],
                      ),
                      error: (error, _) => AppErrorState(
                        compact: true,
                        title: 'Chưa tải được bảng giá',
                        message: error is ApiFailure
                            ? apiErrorMessage(error)
                            : 'Vui lòng thử lại.',
                        onRetry: () => ref.invalidate(plansProvider),
                      ),
                      data: (items) => Column(
                        children: [
                          for (final plan in items)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: _LivePlanCard(
                                plan: plan,
                                current: sub?.plan == plan.code,
                                onBuy:
                                    sub != null &&
                                        plan.price > 0 &&
                                        sub.plan != plan.code
                                    ? () => startPlanCheckout(context, plan)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Thanh toán qua PayOS. Quyền lợi được kích hoạt ngay sau khi giao dịch được xác nhận.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.sub});
  final SubscriptionStatus sub;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    Widget bar(String label, int used, int? limit) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: text.bodySmall)),
              Text(
                '$used / ${limit ?? 'không giới hạn'}',
                style: text.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: limit == null || limit == 0
                ? 0
                : (used / limit).clamp(0, 1).toDouble(),
            semanticsLabel: label,
          ),
        ],
      ),
    );
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.crown, color: context.appColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(sub.planName, style: text.titleMedium)),
              if (sub.isTrial)
                const StatusChip(label: 'Dùng thử', kind: StatusKind.draft),
            ],
          ),
          bar(
            'Lượt tạo lịch trình tháng này',
            sub.generateUsed,
            sub.generateLimit,
          ),
          bar('Lịch trình đã lưu', sub.savedUsed, sub.savedLimit),
          bar('Lượt AI hôm nay', sub.aiDailyUsed, sub.aiDailyLimit),
        ],
      ),
    );
  }
}

class _LivePlanCard extends StatelessWidget {
  const _LivePlanCard({required this.plan, required this.current, this.onBuy});
  final SubscriptionPlan plan;
  final bool current;

  /// Null when the plan cannot be bought (free, current, signed out).
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final text = context.textStyles;
    String limit(int? v, String unit) =>
        v == null ? 'Không giới hạn $unit' : '$v $unit';
    return _Card(
      highlighted: current,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.avatar,
                height: AppSizes.avatar,
                decoration: BoxDecoration(
                  color: app.warningContainer,
                  borderRadius: AppRadius.control,
                ),
                child: Icon(
                  plan.price == 0 ? LucideIcons.leaf : LucideIcons.crown,
                  color: app.onWarningContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(plan.name, style: text.titleMedium)),
              if (current)
                const StatusChip(
                  label: 'Đang dùng',
                  kind: StatusKind.finalized,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            plan.price == 0
                ? 'Miễn phí'
                : '${formatVnd(plan.price)}đ'
                      '${plan.durationDays == null ? '' : ' / ${plan.durationDays} ngày'}',
            style: text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final line in [
            limit(plan.generateLimit, 'lượt tạo / tháng'),
            limit(plan.savedTripLimit, 'lịch trình được lưu'),
            if (plan.aiDailyCallLimit != null)
              '${plan.aiDailyCallLimit} lượt AI / ngày',
            ...plan.features,
          ])
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.check,
                    size: AppSizes.iconSm,
                    color: app.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(line, style: text.bodySmall)),
                ],
              ),
            ),
          if (onBuy != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              buttonKey: ValueKey('plan-buy-${plan.code}'),
              label: 'Chọn ${plan.name}',
              icon: LucideIcons.creditCard,
              expand: true,
              onPressed: onBuy,
            ),
          ],
        ],
      ),
    );
  }
}
