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
    'trip_not_finalized' => 'Hãy chốt lịch trình trước khi đánh dấu đã ghé.',
    'cannot_delete_last_item' =>
      'Lịch trình cần ít nhất một địa điểm nên không xoá được điểm cuối cùng.',
    'place_already_in_trip' => 'Địa điểm này đã có trong lịch trình.',
    'replacement_too_long' =>
      'Thay địa điểm này sẽ làm lịch dài quá 24 giờ. Hãy chọn địa điểm khác.',
    // AI & payments
    'ai_daily_limit_reached' => 'Bạn đã dùng hết lượt AI của hôm nay.',
    'ai_cooldown' =>
      'AI vừa gặp lỗi. Bạn thử lại sau ${failure.details['retryAfterSeconds'] ?? 30} giây nhé.',
    'ai_unavailable' =>
      'AI đang tạm thời không khả dụng. Vui lòng thử lại sau.',
    'payment_gateway_unavailable' || 'payment_provider_unavailable' =>
      'Cổng thanh toán đang bận. Vui lòng thử lại sau.',
    _ => null,
  };
  // Field-level messages from the server are the most specific.
  if (failure.kind == FailureKind.validation && failure.fields.isNotEmpty) {
    return failure.fields.values.expand((e) => e).join('\n');
  }
  if (byCode != null) return byCode;
  return switch (failure.kind) {
    FailureKind.offline =>
      'Không có kết nối mạng. Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.',
    FailureKind.timeout => 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.',
    FailureKind.unavailable =>
      'Máy chủ đang bận. Vui lòng thử lại sau ít phút.',
    FailureKind.unauthorized => 'Phiên đã hết hạn. Vui lòng đăng nhập lại.',
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
