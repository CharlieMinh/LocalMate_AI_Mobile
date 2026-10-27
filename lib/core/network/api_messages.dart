import 'api_failure.dart';

/// Friendly Vietnamese copy for backend error codes (ProblemDetails `code`)
/// and transport failures. Wording follows the web frontend where it exists.
String apiErrorMessage(
  ApiFailure failure, {
  String fallback = 'Chưa tải được dữ liệu. Vui lòng thử lại.',
}) {
  final byCode = switch (failure.code) {
    // Auth & session
    'invalid_credentials' => 'Email hoặc mật khẩu không đúng.',
    'account_locked' => 'Tài khoản đã bị khoá, vui lòng liên hệ hỗ trợ.',
    'account_not_found' => 'Tài khoản không còn tồn tại.',
    'session_expired' => 'Phiên đã hết hạn. Vui lòng đăng nhập lại.',
    'invalid_identity' => 'Phiên không hợp lệ. Vui lòng đăng nhập lại.',
    'user_not_found' => 'Không tìm thấy tài khoản. Vui lòng đăng nhập lại.',
    'duplicate_email' => 'Email này đã được đăng ký. Hãy đăng nhập.',
    'invalid_otp' => _otp(failure),
    'otp_expired' => 'Mã xác thực đã hết hạn. Hãy gửi lại mã mới.',
    'otp_attempts_exceeded' =>
      'Bạn đã nhập sai quá nhiều lần. Hãy gửi lại mã mới.',
    'otp_resend_cooldown' ||
    'otp_rate_limited' ||
    'too_many_requests' => _retryLater(failure),
    'password_reset_google_account' =>
      'Tài khoản này đăng nhập bằng Google nên không có mật khẩu để đặt lại.',
    'invalid_google_token' =>
      'Không xác thực được tài khoản Google. Vui lòng thử lại.',
    'account_link_required' => 'Email này đã đăng ký bằng mật khẩu. Hãy đăng nhập bằng email và mật khẩu.',
    'account_conflict' =>
      'Tài khoản Google này đang gắn với một tài khoản khác.',
    'invalid_preference' => 'Sở thích đã chọn không còn hợp lệ. Hãy chọn lại.',
    'no_changes' => 'Chưa có thay đổi nào để lưu.',
    'notifications_requires_persisted_user' ||
    'feedback_requires_persisted_user' ||
    'ai_requires_persisted_user' ||
    'generate_requires_persisted_user' ||
    'persisted_account_required' ||
    'trip_detail_requires_persisted_user' =>
      'Vui lòng đăng nhập bằng tài khoản đã đăng ký để dùng tính năng này.',
    // Discovery
    'invalid_search_query' => 'Nhập từ 2 đến 100 ký tự để tìm kiếm.',
    'metro_station_not_found' => 'Không tìm thấy ga Metro này.',
    'place_not_found' => 'Địa điểm không còn khả dụng.',
    // Planner
    'out_of_service_area' => 'Vị trí xuất phát nằm ngoài khu vực phục vụ.',
    'too_far_from_station_for_metro' =>
      'Bạn đang ở quá xa ga để đi Metro. Hãy đổi sang Xe máy hoặc Tự động.',
    'insufficient_candidates' => 'Khu này chưa có địa điểm nào trong ngân sách của bạn. Hãy thử ga khác hoặc tăng ngân sách.',
    'duration_too_short' => 'Số giờ chưa đủ để tới và tham quan địa điểm nào. Hãy tăng thời lượng hoặc chọn khu gần hơn.',
    'no_places_open' =>
      'Giờ này chưa có địa điểm nào đang mở cửa. Hãy chọn giờ bắt đầu khác.',
    'metro_not_running' => _metroHours(failure),
    'generate_quota_exceeded' =>
      'Bạn đã dùng hết lượt tạo lịch trình trong tháng này.',
    'invalid_tag_ids' => 'Sở thích đã chọn không còn hợp lệ. Hãy chọn lại.',
    // Trips
    'trip_not_found' => 'Không tìm thấy lịch trình.',
    'trip_finalized' => 'Lịch trình đã chốt nên không sửa được nữa.',
    'already_finalized' => 'Lịch trình này đã được chốt rồi.',
    'saved_trip_quota_exceeded' =>
      'Bạn đã đạt giới hạn lịch trình được lưu của gói hiện tại.',
    'trip_not_finalized' =>
      'Hãy chốt lịch trình trước khi thực hiện thao tác này.',
    'item_not_visited' => 'Hãy đánh dấu đã ghé trước khi đánh giá điểm này.',
    'review_already_exists' => 'Bạn đã đánh giá điểm dừng này rồi.',
    'invalid_place_review' => 'Đánh giá chưa hợp lệ. Hãy chọn từ 1 đến 5 sao.',
    'feedback_already_exists' => 'Bạn đã gửi phản hồi cho chuyến đi này rồi.',
    'invalid_feedback' => 'Phản hồi chưa hợp lệ. Hãy chọn một nhận xét.',
    'itinerary_item_not_found' => 'Điểm dừng này không còn trong lịch trình.',
    'same_place' => 'Hãy chọn một địa điểm khác với địa điểm hiện tại.',
    'cannot_delete_last_item' =>
      'Lịch trình cần ít nhất một địa điểm nên không xoá được điểm cuối cùng.',
    'place_already_in_trip' => 'Địa điểm này đã có trong lịch trình.',
    'replacement_too_long' =>
      'Thay địa điểm này sẽ làm lịch dài quá 24 giờ. Hãy chọn địa điểm khác.',
    // AI & payments
    'ai_daily_limit_reached' => 'Bạn đã dùng hết lượt AI của hôm nay.',
    'ai_trip_limit_reached' =>
      'Lịch trình này đã dùng hết lượt AI giải thích của gói hiện tại.',
    'ai_cooldown' =>
      'AI vừa gặp lỗi. Bạn thử lại sau ${failure.details['retryAfterSeconds'] ?? 30} giây nhé.',
    'ai_unavailable' =>
      'AI đang tạm thời không khả dụng. Vui lòng thử lại sau.',
    'payment_gateway_unavailable' || 'payment_provider_unavailable' =>
      'Cổng thanh toán đang bận. Vui lòng thử lại sau.',
    'plan_already_active' => 'Bạn đang dùng gói này rồi.',
    'already_covered_by_higher_plan' =>
      'Gói hiện tại của bạn đã bao gồm quyền lợi của gói này.',
    'target_plan_already_scheduled' => 'Gói này đã được lên lịch kích hoạt.',
    'upgrade_checkout_not_ready' || 'no_active_subscription' =>
      'Chưa thể nâng cấp lúc này. Vui lòng thử lại sau.',
    'pending_order_exists' ||
    'another_pending_order' => 'Bạn đang có một đơn thanh toán chưa hoàn tất.',
    'payment_review_required' =>
      'Đơn thanh toán trước đang được kiểm tra. Vui lòng liên hệ hỗ trợ.',
    'payment_order_not_found' => 'Không tìm thấy đơn thanh toán.',
    'invalid_plan_code' => 'Gói này không còn được bán.',
    _ => null,
  };
  // Field-level messages from the server are the most specific, but only
  // localized ones: default ASP.NET validation text is English.
  if (failure.kind == FailureKind.validation) {
    final local = failure.fields.values
        .expand((e) => e)
        .where((m) => m.runes.any((r) => r > 0x7f))
        .toList();
    if (local.isNotEmpty) return local.join('\n');
  }
  if (byCode != null) return byCode;
  return switch (failure.kind) {
    FailureKind.offline =>
      'Không có kết nối mạng. Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.',
    FailureKind.timeout => 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.',
    FailureKind.unavailable =>
      'Máy chủ đang bận. Vui lòng thử lại sau ít phút.',
    FailureKind.unauthorized => 'Phiên đã hết hạn. Vui lòng đăng nhập lại.',
    FailureKind.validation => 'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.',
    FailureKind.forbidden => 'Tài khoản chưa được phép thực hiện thao tác này.',
    _ when failure.status == 404 => 'Dữ liệu không còn khả dụng.',
    _ when failure.status == 429 =>
      'Bạn thao tác hơi nhanh. Vui lòng thử lại sau.',
    _ => fallback,
  };
}

String _metroHours(ApiFailure failure) {
  final hours = failure.details['metroServiceHours'];
  if (hours is Map) {
    String clock(Object? t) =>
        t is String && t.length >= 5 ? t.substring(0, 5) : '?';
    return 'Metro ở ga ${hours['stationName']} chạy từ ${clock(hours['firstDeparture'])} '
        'đến ${clock(hours['lastDeparture'])} (giờ dự kiến). Hãy chọn giờ khác hoặc đổi phương tiện.';
  }
  return 'Metro chưa chạy vào giờ này. Hãy chọn giờ khác hoặc đổi phương tiện.';
}

String _otp(ApiFailure failure) {
  final left = failure.details['remainingAttempts'];
  return left is num
      ? 'Mã xác thực không đúng. Bạn còn ${left.toInt()} lần thử.'
      : 'Mã xác thực không đúng.';
}

String _retryLater(ApiFailure failure) {
  final seconds = failure.details['retryAfterSeconds'];
  return seconds is num
      ? 'Bạn thao tác hơi nhanh. Thử lại sau ${seconds.toInt()} giây nhé.'
      : 'Bạn thao tác hơi nhanh. Vui lòng thử lại sau.';
}
