# Định hướng thiết kế — LocalMate AI Mobile Redesign

Ngày: 27/10/2026 · Đi kèm: `docs/UI_AUDIT.md`

> **Quyết định đã duyệt (27/10/2026):**
> - Chọn **Hướng B "Tuyến Ga"**.
> - Duyệt package: `skeletonizer`, `flutter_animate`, `animations`, `lucide_icons_flutter`, `cached_network_image`, `url_launcher`, `connectivity_plus`. Không dùng `flutter_svg`; minh họa vẽ bằng `CustomPainter`.
> - Được phép tách logic form planner sang `PlannerFormController`, với điều kiện giữ nguyên hành vi.
> - Sở thích là **tùy chọn**.
> - Hero trang chủ dùng **minh họa vector**.
> - Các câu hỏi còn lại trong `UI_AUDIT.md` (phạm vi màn mới, test, disclaimer, `/private`, bottom nav 5 tab) theo đề xuất đã ghi trong audit.
> - Ghi chú kỹ thuật: font Be Vietnam Pro không có ký tự "→" (U+2192), nên mũi tên trong UI dùng icon `LucideIcons.arrowRight`.

Ràng buộc chung cho cả hai hướng:
- Giữ nhận diện **navy #1D3E82 + amber #F6A623 + Be Vietnam Pro**, thống nhất với bản web và thiết kế gốc.
- Chuẩn Material 3, có dark mode đầy đủ.
- Lưới 8pt, vùng chạm ≥ 48dp, hỗ trợ text scale tới 200%.

---

## 1. Hai hướng thiết kế

### Hướng A — "Sài Gòn Rực Rỡ": tươi sáng, nhiều ảnh, cảm hứng khám phá

Tinh thần: như một tạp chí du lịch. Ảnh lớn tràn viền, màu ấm, nhiều năng lượng; người dùng "lướt để được truyền cảm hứng".

**Bảng màu**

| Token | Light | Dark |
|---|---|---|
| primary (navy) | `#1D3E82` | `#8FB0FF` |
| secondary (amber) | `#F6A623` | `#FFC15E` |
| tertiary (coral – ẩm thực, điểm nóng) | `#FF6B4A` | `#FF8A70` |
| background (cát ấm) | `#FAF7F2` | `#12151C` |
| surface | `#FFFFFF` | `#1B1F29` |
| onSurface | `#14213D` | `#EEF1F7` |
| onSurfaceVariant | `#6B7280` | `#A3ABBD` |
| outline | `#ECE6DC` | `#2C3240` |

- **Font:** Be Vietnam Pro. Tiêu đề ExtraBold 800, cỡ 28–32; nội dung 16.
- **Card:** ảnh chiếm 70% card, bo góc 24, bóng mềm `0 8 24 rgba(20,33,61,.08)`. Chữ nằm trên ảnh với gradient đen 0→60%.
- **Icon:** Phosphor (duotone cho danh mục).
- **Chuyển động:** header ảnh có parallax khi cuộn, hero ảnh, chip "nảy" nhẹ khi chọn, danh sách so le.
- **App tham khảo:** Airbnb (Experiences), Klook, Traveloka Xperience, Google Travel.
- **Rủi ro:** phụ thuộc hoàn toàn vào ảnh. Hiện **không có ảnh hợp lệ**: seed backend `imageUrl = null`, và ảnh trong prototype không được phép dùng. Khi thiếu ảnh, hướng này trông "trống" và rẻ hơn hẳn.

### Hướng B — "Tuyến Ga": tối giản, sang trọng, lấy Metro/timeline làm xương sống

Tinh thần: như một app giao thông cao cấp. Đường ray Metro số 1 là motif chủ đạo: timeline lịch trình, sơ đồ 14 ga và loading đều dùng hình "đường ray + chấm ga". Nhiều khoảng trắng, chữ lớn rõ ràng, màu dùng tiết chế và có chủ đích.

**Bảng màu**

| Token | Light | Dark | Dùng cho |
|---|---|---|---|
| primary | `#1D3E82` | `#9DB7F5` | CTA, tab active, tiêu đề nhấn |
| onPrimary | `#FFFFFF` | `#0B1F4D` | |
| primaryContainer | `#E6ECF8` | `#1E2F57` | chip chọn, indicator nav |
| metroLine (tuyến số 1) | `#1779BE` | `#4FA8E8` | đường ray, badge ga |
| secondary (amber) | `#F6A623` | `#FFB840` | trạng thái Nháp, điểm nhấn hiếm |
| background | `#F5F7FB` | `#0B1220` | |
| surface | `#FFFFFF` | `#121A2B` | card, sheet |
| surfaceContainer | `#EEF2F8` | `#1A2438` | ô nhập, khối phụ |
| onSurface (ink) | `#0F2148` | `#E8EDF7` | chữ chính |
| onSurfaceVariant | `#5C6B8A` | `#94A3BF` | chữ phụ |
| outline | `#DCE2EE` | `#26324A` | viền mảnh |
| success | `#1F8A5B` | `#5BD69A` | Đã chốt, đã ghé |
| error | `#C4321C` | `#FF8A7A` | |

- **Font:** Be Vietnam Pro, bổ sung weight 500 và 800 (file TTF, license OFL, không cần package). Thang chữ tối đa 4 cỡ mỗi màn hình:

  | Vai trò | Cỡ / dòng | Weight |
  |---|---|---|
  | display | 28/34 | 800 |
  | title | 20/26 | 700 |
  | body | 15/22 | 400 |
  | label | 13/18 | 600 |

  Chữ nội dung tăng từ 12 lên 15sp.
- **Card:** bo góc 20 cho card, 16 cho nút và ô nhập, 28 cho đỉnh bottom sheet.
  - Light mode: viền 1px `outline` cộng bóng rất mềm `0 2 12 rgba(15,33,72,.06)`.
  - Dark mode: không có bóng; phân tầng bằng tông `surface`.
  - Ảnh khi có thì tràn viền phía trên card, kèm gradient.
- **Motif riêng:**
  - Badge ga hình tròn có số thứ tự, giống biển báo Metro thật.
  - Timeline dọc nối các điểm dừng bằng "đường ray"; chặng Metro hiện đoạn ray màu `metroLine` kèm ga lên/xuống.
  - Sơ đồ ngang 14 ga cuộn được.
- **Icon:** Lucide (đúng với thiết kế gốc), nét 1.75, outline; đổi sang filled khi active.
- **Chuyển động:**
  - Mặc định 200–300ms, curve `easeOutCubic` / emphasized decelerate.
  - Planner chuyển bước bằng shared-axis ngang.
  - Hero cho ảnh địa điểm và badge ga.
  - Danh sách xuất hiện so le 40ms.
  - Loading là chấm tàu chạy dọc đường ray kèm checklist 3 bước.
  - Haptic nhẹ khi chọn ga, chốt lịch trình và đánh dấu đã ghé.
- **App tham khảo:** Citymapper, Apple Maps (chỉ đường giao thông công cộng), Google Maps Transit, Tokyo Metro app, Linear (về độ tiết chế).

---

## 2. Khuyến nghị: **Hướng B "Tuyến Ga"**, mượn cách xử lý ảnh của Hướng A

Lý do, xét theo người dùng là khách du lịch đi Metro số 1 TP.HCM:

1. **Metro chính là khung định hướng của người dùng.** Khách du lịch nghĩ theo kiểu "xuống ga nào, quanh đó có gì". Hướng B biến tuyến số 1 thành hệ thống thị giác xuyên suốt (badge ga, đường ray, sơ đồ 14 ga). Đây là thứ không app du lịch chung chung nào có, và là bản sắc riêng của LocalMate.
2. **Chịu được việc thiếu ảnh.** Dữ liệu hiện tại và gần sắp tới không có ảnh. Hướng B vẫn đẹp khi không có ảnh nhờ badge ga, gradient theo danh mục và typography. Khi backend có `imageUrl`, card tự "nâng cấp" lên dạng ảnh tràn viền như Hướng A.
3. **Dùng ngoài trời, một tay, khi đang di chuyển.** Tương phản cao, chữ lớn 15sp, ít nhiễu thị giác: đọc được dưới nắng Sài Gòn và khi đang đứng trên tàu.
4. **Liền mạch với web và thiết kế gốc.** Giữ navy/amber, Be Vietnam Pro và bố cục màn hình gốc, nên ít phải giải thích lại với team và người dùng web.
5. **Dark mode tự nhiên.** Bảng màu navy chuyển sang dark rất đẹp, phù hợp khi dùng app buổi tối (food tour, phố đi bộ).
6. **Khách quốc tế và người lớn tuổi** dễ dùng hơn với một giao diện rõ ràng, giống app giao thông quen thuộc.

---

## 3. Những chỗ sẽ lệch khỏi thiết kế gốc

| # | Thiết kế gốc | Redesign | Lý do |
|---|---|---|---|
| 1 | Hero trang chủ dùng ảnh Bến Thành | Khối gradient navy kèm minh họa vector đường ray / ga, ảnh hiện khi có nguồn hợp lệ | README cấm đưa ảnh prototype vào app; chưa có ảnh được cấp phép |
| 2 | Sơ đồ Metro chỉ có 3 ga | Sơ đồ đủ 14 ga, cuộn ngang, ga đang chọn được làm nổi | README bắt buộc đủ 14 ga; sơ đồ 3 ga không mở rộng được |
| 3 | Khám phá có 3 chip, chỉ 1 nhóm kết quả | 4 danh mục từ `master-data` (Cà phê, Ẩm thực, Văn hóa, Check-in) cộng "Tất cả"; kết quả chia 3 nhóm Ga / Địa điểm / Lịch trình mẫu | Bám backend và README |
| 4 | Thời lượng chỉ có 4 preset | Chip 2/4/6/8 giờ cộng "Tùy chỉnh" (bottom sheet 1–24 giờ, báo khi qua đêm) | README yêu cầu 1–24 giờ và chuyến qua đêm; bỏ dropdown trùng lặp |
| 5 | Date picker gốc của trình duyệt, định dạng kiểu Mỹ | Dải chọn ngày ngang (hôm nay đến +13 ngày, "Thứ Bảy, 26/09") cộng "Chọn ngày khác" (M3 date picker, locale vi) | Định dạng Việt; backend cho phép tối đa 90 ngày |
| 6 | Ngân sách viết 2 kiểu ("150k – 300k" và "300.000đ") | Thống nhất chip "150.000đ / 300.000đ / 500.000đ / 1.000.000đ" kèm "mỗi người" | Nhất quán; backend tính theo người |
| 7 | Bo góc ~12, gần như không bóng | Card 20, nút/ô nhập 16, sheet 28; bóng rất mềm ở light mode | Tiêu chí "hiện đại" của dự án |
| 8 | Chữ nội dung ~12sp | 15sp | Dễ đọc ngoài trời |
| 9 | Dropdown kiểu web | Bottom sheet chọn ga có tìm kiếm không dấu | Pattern mobile |
| 10 | Loading là spinner kèm checklist | Chấm tàu chạy dọc đường ray kèm checklist tuần tự | Bản sắc; thay vòng xoay đơn điệu |
| 11 | Chi tiết địa điểm thiếu thông tin | Thêm địa chỉ, giờ mở cửa 7 ngày, điểm đánh giá và số lượt (chỉ khi backend có), khoảng cách tới ga, nút mở Google Maps | Backend có đủ field này |
| 12 | Chặng di chuyển là 1 dòng text | Chặng hiển thị theo phương tiện (đi bộ / xe máy / Metro kèm ga lên-xuống, thời gian chờ) | Dùng `TripLegResponse` |
| 13 | Nhiều disclaimer dev | Một nhãn "Dữ liệu minh họa" duy nhất, chỉ ở bản mock | Sạch giao diện; vẫn trung thực |
| 14 | Tên màn hình không nhất quán ("Lịch trình" / "Lịch trình cá nhân" / "Lịch trình của bạn") | Tab "Lịch trình", tiêu đề "Lịch trình của tôi", màn chi tiết lấy tên chuyến | Nhất quán |
| 15 | Không có dark mode, không có trạng thái lỗi/offline | Đủ: light/dark, skeleton, rỗng, lỗi, offline | Yêu cầu dự án |
| 16 | Dòng gói hiện "—" khi chưa có giá | Skeleton khi đang tải; khối "Chưa thể tải bảng giá" kèm nút thử lại khi lỗi | Tránh cảm giác hỏng |
| 17 | Hero trang chủ tràn viền | Hero dạng card bo góc 20, cách lề 16 | Đồng bộ với các card khác; minh họa vector cần khung |
| 18 | Chi tiết địa điểm có thanh tiêu đề "Chi tiết địa điểm" | Header ảnh co giãn 300px, chuyển thành tên địa điểm khi cuộn; nút back nổi trên ảnh | Pattern chi tiết hiện đại; hero animation từ card |
| 19 | Khám phá có 2 nút "Tìm kiếm" / "Xóa tìm kiếm" dưới ô nhập | Thanh tìm kiếm nổi: tìm bằng phím Tìm trên bàn phím, nút xóa (X) trong ô | Pattern mobile chuẩn; bớt nút thừa |
| 20 | Nhãn bottom nav phóng theo cỡ chữ hệ thống | Nhãn nav giới hạn phóng 1.3×, tự xuống 2 dòng khi chữ lớn hoặc màn < 360px | Nav là "chrome"; tránh tràn; nội dung trang vẫn phóng đầy đủ |
| 22 | Planner: ngày/giờ là dropdown/ô nhập kiểu web | Chip "Hôm nay / Ngày mai / Ngày khác" và "Sáng 08:00 / Chiều 13:00 / Tối 18:00 / Giờ khác" kèm date/time picker locale vi; không còn gõ tay `yyyy-MM-dd` | Không thể nhập sai định dạng; khớp `timeSlots` của backend. Validate trong domain giữ nguyên |
| 23 | Planner: ga chọn bằng dropdown | Ô chọn ga mở bottom sheet tìm không dấu, kèm sơ đồ 14 ga chạm để chọn ga xuất phát | Pattern mobile; tái sử dụng picker của Metro |
| 24 | Sheet "Chốt lịch trình?" dẫn tới màn Đã chốt | Ở bản mock, sheet giải thích "Chưa khả dụng ở bản offline", nút xác nhận bị vô hiệu. Màn Đã chốt đã có giao diện (`FinalizedTripView`), xem qua route debug `/dev/finalized`, nối API ở Giai đoạn 4 | Không tạo trạng thái thành công giả (quy tắc handoff) |
| 25 | Lịch trình nháp có "Xem địa điểm / Đổi điểm" từng điểm dừng | Chưa hiện ở bản mock vì điểm dừng mẫu không có `placeId`; component đã hỗ trợ `actions` | Không hiển thị hành động không có dữ liệu thật |
| 26 | Nút "Tạo lịch trình từ ga này" (chi tiết ga) điền sẵn ga | Nút chung "Tạo lịch trình mẫu" (chưa điền sẵn ga) | Điền sẵn cần thay đổi luồng điều hướng planner; để Giai đoạn 4 |
| 21 | Không có dark mode | Theme sáng/tối đầy đủ, **mặc định theo hệ thống** (bật sau khi mọi màn đã chuyển sang design system); đổi tại Tài khoản › Giao diện (lưu trong phiên) | Yêu cầu dự án; dùng buổi tối ngoài trời |
| 27 | Tài khoản: 2 ô thống kê hiện "—" | Ô thống kê có icon + "Chưa đồng bộ"; thêm mục **Giao diện** (Sáng / Tối / Theo hệ thống) | Không hiển thị số giả; dark mode cần nơi chọn |
| 28 | Đăng nhập có "Tiếp tục bằng tài khoản mẫu" + "Trải nghiệm nhanh (Demo)" | "Đăng nhập mẫu" + "Điền tài khoản mẫu"; nút Google hiển thị nhưng vô hiệu kèm lý do | Backend có `/auth/demo` và Google; nối ở Giai đoạn 4 |
| 29 | Lịch trình của tôi (trống) | Trạng thái rỗng minh họa + thẻ "Cách hoạt động" 3 bước | Chưa có `GET /api/trips/my-trips` ở bản mock; danh sách thật ở Giai đoạn 4 |
| 30 | Gói: dòng giá "—" | Card gói với "Chưa tải giá", không có nút mua | Không bịa giá; PayOS ở Giai đoạn 4 |

---

## 4. Package UI đề xuất (chờ duyệt, CHƯA thêm vào pubspec)

Dự án đang ghim phiên bản chính xác. Khi được duyệt, tôi sẽ chọn bản ổn định mới nhất tương thích Flutter 3.47.6 và ghim tương tự.

| Package | Mục đích | Lý do chọn |
|---|---|---|
| `cached_network_image` | Ảnh Cloudinary kèm cache, placeholder và fade-in | Chuẩn de facto, bảo trì tốt |
| `skeletonizer` | Skeleton shimmer tự sinh từ chính widget thật | Không phải vẽ skeleton riêng cho từng màn; ít code hơn `shimmer` |
| `flutter_animate` | Fade/slide so le, micro-animation khai báo ngắn gọn | Gọn, phổ biến, hỗ trợ tắt animation theo accessibility |
| `animations` (của Flutter team) | SharedAxis / FadeThrough / container transform khi chuyển trang | Package chính thức, đúng chuẩn Material motion |
| `lucide_icons_flutter` | Bộ icon giống thiết kế gốc | Thiết kế dùng Lucide; Material Icons lệch phong cách |
| `url_launcher` | Mở Google Maps, trang thanh toán PayOS | Package chính thức; hiện app chỉ hiện URL |
| `connectivity_plus` | Phát hiện offline thật, hiện banner offline | Package chính thức (plus.fluttercommunity) |
| `flutter_svg` *(tùy chọn)* | Minh họa vector cho empty state và hero | Chỉ cần nếu dùng SVG; có thể thay bằng `CustomPainter` |

Không cần package: haptic (`HapticFeedback` có sẵn), font (dùng file TTF), định dạng ngày (đã có `formatters.dart`; chỉ thêm `intl` nếu cần).

---

## 5. Kế hoạch triển khai (thứ tự ưu tiên)

Độ phức tạp: S = nhỏ, M = vừa, L = lớn.

| # | Hạng mục | Độ phức tạp | Ghi chú |
|---|---|---|---|
| 0 | **Design system + ComponentGalleryScreen** (Giai đoạn 2) | L | `app_tokens.dart`, theme sáng/tối, khoảng 20 component trong `lib/core/widgets/`; **DỪNG để duyệt ảnh gallery** |
| 1 | App shell + bottom nav nổi + chuyển trang | S | Tách `AppShell` khỏi `router.dart`, giữ nguyên route |
| 2 | Trang chủ | M | Hero gradient, search nổi, carousel điểm dừng, "Dọc tuyến Metro số 1", lịch trình gần đây |
| 3 | Khám phá + tìm kiếm | M | SliverAppBar, search có nút xóa, chip danh mục, 3 nhóm kết quả, rỗng/lỗi |
| 4 | Chi tiết địa điểm | M | Header ảnh co giãn với hero, khối thông tin dạng hàng có icon, giờ mở cửa, CTA ghim đáy |
| — | *Báo cáo trước/sau lần 1* | | |
| 5 | Planner 4 bước + loading | L | Cần tách `PlannerFormController` trước (xem câu hỏi 6 trong `UI_AUDIT.md`) |
| 6 | Lịch trình nháp + sheet chốt + màn Đã chốt | L | Timeline đường ray, chặng di chuyển, sheet xác nhận |
| 7 | Metro + chi tiết ga | L | Sơ đồ 14 ga, picker sheet, lịch tàu dạng chip giờ |
| — | *Báo cáo trước/sau lần 2* | | |
| 8 | Lịch trình của tôi | M | Danh sách Nháp/Đã chốt (mock cho tới Giai đoạn 4), empty state minh họa |
| 9 | Tài khoản + Cá nhân hóa + Gói | M | Card hồ sơ, hạn mức dạng thanh tiến trình, card gói |
| 10 | Đăng nhập (+ đăng ký/OTP nếu duyệt) | M | |
| 11 | Màn phụ: kết quả thanh toán, trang lỗi, `/private`, sheet Maps | S | |
| — | *Báo cáo trước/sau lần 3, sang Giai đoạn 4 (kết nối dữ liệu)* | | |

Mỗi màn được kiểm tra ở 360×640, 393×852 và 430×932, text 1.3, sáng/tối. Ảnh chụp "after" dùng chính `tool/ui_capture_test.dart`, mở rộng thêm các kích thước và dark mode, đặt cùng tên file với ảnh "before".
