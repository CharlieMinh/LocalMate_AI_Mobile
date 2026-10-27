# Tổng kết redesign UI — LocalMate AI Mobile

Branch `feat/ui-redesign-v02` · 27/10/2026 · Hướng thiết kế B "Tuyến Ga"

## 1. Kết quả

Toàn bộ tầng UI được viết lại trên một design system mới. Tầng logic giữ nguyên hành vi: route, tham số điều hướng, provider, repository và model. Ngoại lệ duy nhất là `PlannerFormController`, được tách ra khỏi widget theo đúng phạm vi đã duyệt. App chạy ở 2 chế độ, chọn lúc build:

- **Mock (mặc định):** dùng fixture cục bộ, không mở socket. Nhãn "Dữ liệu minh họa" chỉ hiện ở chế độ này.
- **Backend thật:** bật bằng `--dart-define=API_BASE_URL=...`, nối với `LocalMate_AI_BE`. Chi tiết trong [`LIVE_BACKEND.md`](LIVE_BACKEND.md).

| Chỉ số | Trước | Sau |
|---|---|---|
| Điểm thị giác trung bình (thang của `UI_AUDIT.md`) | 5.3 / 10 (19 màn đã có) | 8.4 / 10 (22 màn) |
| Màu hardcode `Brand.*` | 139 | 0 |
| Cỡ chữ khác nhau | 12 | 1 `TextTheme`, tối đa 3–4 cỡ / màn |
| Dark mode | Không | Sáng / Tối / Theo hệ thống, lưu trên thiết bị |
| Màn hình có trạng thái loading / empty / error / offline đầy đủ | Không có | Mọi màn tải dữ liệu |
| Khai báo `test(` / `testWidgets(` trong `test/` | 162 | 199 (311 test chạy, tính cả các vòng lặp ma trận) |

Bảng điểm từng màn và các vấn đề còn lại: [`UI_AUDIT.md` mục 5](UI_AUDIT.md). Ảnh trước / sau: `docs/screenshots/before/`, `docs/screenshots/after/` (thêm `-dark`), `docs/screenshots/after/live-*.png`.

## 2. Design system (`lib/core/theme`, `lib/core/widgets`)

- **Token:** lưới 8pt (`AppSpacing`), bo góc 12/16/20/24 (`AppRadius`), thời lượng chuyển động 150/250/350ms (`AppDurations`), kích thước (`AppSizes`, vùng chạm tối thiểu 48dp).
- **Màu:** `ColorScheme` sáng/tối cùng `AppColors` (ThemeExtension), gồm màu tuyến Metro #1779BE, success/warning, màu hero và màu theo danh mục địa điểm. Navy #1D3E82 và amber là màu thương hiệu.
- **Chữ:** Be Vietnam Pro 400–800. Font này không có glyph "→" nên dùng `LucideIcons.arrowRight`.
- **Component:** nút, ô nhập, thanh tìm kiếm, chip, banner, thẻ địa điểm và ảnh có fallback, timeline điểm dừng và chặng (đi bộ / xe máy / Metro), sơ đồ tuyến 14 ga, bottom sheet và sheet xác nhận, thanh tiêu đề, bottom nav M3, skeleton, empty / error / offline state, minh họa vector, haptic, stagger.
- **Gallery** cho mọi component: route debug `/dev/gallery`, ảnh ở `docs/screenshots/gallery/`.

## 3. Màn hình

- **Đã redesign:** Trang chủ, Khám phá, Chi tiết địa điểm, Lịch trình mẫu, Metro, Chi tiết ga, Planner 4 bước và màn đang chuẩn bị, Lịch trình nháp, sheet chốt, Lịch trình đã chốt, Lịch trình của tôi, Đăng nhập, Tài khoản, Cá nhân hóa, Gói, trang thanh toán và trang lỗi.
- **Màn mới (chế độ backend):**
  - Chi tiết chuyến `/trips/:id`.
  - Đăng ký kèm OTP `/register`, quên mật khẩu `/forgot-password`.
  - Thông báo `/notifications`.
  - Sheet đánh giá điểm dừng và phản hồi chuyến đi.
  - Sheet đổi địa điểm.
  - "Điền giúp tôi bằng AI".
  - Checkout PayOS và màn theo dõi đơn.
  - Đăng nhập Google.

## 4. Package đã thêm (đều đã được duyệt, pin đúng phiên bản)

| Package | Phiên bản | Dùng cho |
|---|---|---|
| skeletonizer | 3.0.0 | Skeleton loading |
| flutter_animate | 4.5.2 | Stagger, hiệu ứng vào danh sách |
| animations | 3.0.0 | SharedAxis chuyển trang / chuyển bước |
| lucide_icons_flutter | 4.0.1 | Bộ icon |
| cached_network_image | 4.0.5 | Ảnh địa điểm từ Cloudinary (chỉ ở chế độ backend) |
| url_launcher | 6.3.3 | Mở PayOS và Google Maps |
| connectivity_plus | 7.3.2 | Banner và trạng thái mất mạng thật |
| google_sign_in | 7.2.0 | Đăng nhập Google |

`flutter_svg` không được duyệt, nên mọi minh họa đều vẽ bằng `CustomPainter`.

## 5. Kiểm tra

- `flutter analyze`: sạch.
- `flutter test`: 311 test pass, gồm các nhóm:
  - Token và tương phản WCAG.
  - Component.
  - `PlannerFormController`.
  - Hợp đồng với JSON thu từ backend thật (`test/fixtures/live`, không chứa token).
  - Luồng UI ở chế độ backend (`live_ui_test.dart`).
  - Khả năng tiếp cận (`accessibility_test.dart`): vùng chạm 48dp, nhãn, tương phản trên các màn chính và bottom sheet, sáng và tối.
  - Một test quét để chữ của bản mock không lọt sang bản live.
- **Ma trận layout** (`tool/redesign_capture_test.dart`, `tool/live_capture_test.dart`): 390×844 sáng/tối, 360×640 chữ 1.3, 393×852 chữ 1.3 tối, 430×932 chữ 1.3, 320×640 chữ 2.0. Không có lỗi tràn.
- `flutter build web --release`: thành công.

## 6. Chưa làm được / cần lưu ý

1. **Chưa build APK.** Máy dev không có Android SDK (`flutter doctor`: "Unable to locate Android SDK"). Cấu hình Android đã sửa nhưng chưa chạy qua Gradle:
   - Thêm quyền INTERNET cho bản release, vì bản cũ là mock-only nên không có quyền này.
   - Bản debug cho phép HTTP tới 10.0.2.2 / localhost qua network security config.
   - `google_sign_in` có mã native Android, cũng chưa được biên dịch.
2. **Chưa chạy trên thiết bị hoặc emulator thật.** Mọi ảnh chụp đều là widget test.
3. **Dịch vụ ngoài chưa chạy thật**, vì backend dev không có SMTP, Gemini, PayOS và Google OAuth:
   - Luồng gửi mã email (đăng ký, quên mật khẩu), AI, PayOS và Google mới được kiểm bằng phản hồi đúng hình dạng hợp đồng.
   - Các phản hồi lỗi thì đã thu từ backend thật.
4. **Google trên Android cần cấu hình ngoài mã nguồn:** một OAuth client loại Android (package `vn.io.localmate.mobile` + SHA-1 của keystore) trong cùng Google Cloud project với web client ID truyền qua `GOOGLE_SERVER_CLIENT_ID`.
5. **Chưa làm:**
   - Mua lẻ một lượt chốt lịch trình (`/itinerary-purchases`).
   - Góp ý ứng dụng (`/app-feedback`), phiên demo.
   - "Áp dụng" lịch trình mẫu (`/curated/{id}/apply`).
   - Xoá / nhân bản chuyến.
   - Danh sách đánh giá công khai của địa điểm.
   - `feasibility-check` trước khi tạo lịch trình.

## 7. Chạy lại các kiểm tra

```bash
flutter analyze
flutter test
flutter test tool/redesign_capture_test.dart tool/live_capture_test.dart tool/gallery_capture_test.dart
flutter build apk --debug   # cần Android SDK
```
