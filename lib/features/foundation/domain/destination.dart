import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum Destination {
  home(
    '/home',
    'Trang chủ',
    LucideIcons.house,
    'Hôm nay mình đi đâu?',
    'Khám phá TP. Hồ Chí Minh theo nhịp Metro. Đây là nền tảng ứng dụng, chưa kết nối dữ liệu địa điểm.',
  ),
  explore(
    '/explore',
    'Khám phá',
    LucideIcons.compass,
    'Những điểm dừng mới',
    'Tìm kiếm và chi tiết địa điểm sẽ được kết nối ở mốc Discovery. Chưa có dữ liệu địa điểm trong bản M1.',
  ),
  metro(
    '/metro',
    'Metro',
    LucideIcons.trainFront,
    'Dọc tuyến Metro số 1',
    'Bến Thành – Suối Tiên. Chưa kết nối danh sách ga, giờ tàu hoặc chỉ đường; không có lịch tàu trực tiếp.',
  ),
  trips(
    '/trips',
    'Lịch trình',
    LucideIcons.route,
    'Hành trình của bạn',
    'Tạo, xem và quản lý lịch trình ở các mốc tiếp theo. Chưa tải dữ liệu; đây không phải danh sách lịch trình rỗng của tài khoản.',
  ),
  account(
    '/account',
    'Tài khoản',
    LucideIcons.user,
    'Một hành trình theo gu bạn',
    'Đăng nhập và cá nhân hóa chưa được tích hợp. Không có phiên đăng nhập, gói dịch vụ hoặc hạn mức được xác nhận.',
  );

  const Destination(
    this.path,
    this.label,
    this.icon,
    this.heading,
    this.description,
  );
  final String path;
  final String label;
  final IconData icon;
  final String heading;
  final String description;
}
