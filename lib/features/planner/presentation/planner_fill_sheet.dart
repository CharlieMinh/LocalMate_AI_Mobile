import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/api_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../trips/application/trips_providers.dart';
import '../../trips/domain/trip_models.dart';

/// "Điền giúp tôi": the user describes the trip in their own words and the
/// AI returns planner fields. Resolves to null when dismissed.
Future<ParsedTripRequest?> showPlannerFillSheet(BuildContext context) =>
    showModalBottomSheet<ParsedTripRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _FillSheet(),
    );

class _FillSheet extends ConsumerStatefulWidget {
  const _FillSheet();

  @override
  ConsumerState<_FillSheet> createState() => _FillSheetState();
}

class _FillSheetState extends ConsumerState<_FillSheet> {
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (text.length < 5) {
      setState(() => _error = 'Hãy mô tả chuyến đi bạn muốn, từ 5 ký tự.');
      return;
    }
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final parsed = await ref.read(tripsRepositoryProvider).parseRequest(text);
      if (!parsed.isTripRequest) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = parsed.message ?? 'Mình chưa hiểu đây là yêu cầu chuyến đi. Bạn thử nói rõ hơn nhé.';
        });
        return;
      }
      navigator.pop(parsed);
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = apiErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) => AppSheetBody(
    title: 'Điền giúp tôi',
    subtitle: 'Kể chuyến đi bạn muốn, AI sẽ điền sẵn các bước để bạn xem lại.',
    actions: [
      AppButton(
        buttonKey: const ValueKey('planner-fill-submit'),
        label: 'Điền thông tin',
        icon: LucideIcons.sparkles,
        expand: true,
        loading: _busy,
        onPressed: _busy ? null : _submit,
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          fieldKey: const ValueKey('planner-fill-text'),
          controller: _text,
          label: 'Chuyến đi của bạn',
          hint: 'Ví dụ: chiều thứ Bảy đi cà phê quanh ga Bến Thành 3 tiếng, dưới 200 nghìn',
          maxLines: 4,
          maxLength: 500,
          enabled: !_busy,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Mỗi lần điền dùng 1 lượt AI trong ngày của gói.',
          style: context.textStyles.bodySmall,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppBanner(kind: BannerKind.error, message: _error!),
        ],
      ],
    ),
  );
}
