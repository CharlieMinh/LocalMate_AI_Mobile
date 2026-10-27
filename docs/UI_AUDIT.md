# UI Audit — LocalMate AI Mobile

Mục 1–4 là audit **trước redesign** (giữ nguyên để đối chiếu). Mục 5 là trạng thái **sau redesign** (Giai đoạn 5, 27/10/2026).

Ngày audit: 27/10/2026 · Branch: `feat/ui-redesign-v02` (tách từ `feature/v02-visual-alignment` @ `fb9a35b`)

Nguồn đối chiếu:
- Thiết kế gốc: `outputs/mobile-v02-rendered-reference-20261022/` (26 ảnh chụp prototype HTML + README ràng buộc)
- Backend: `../_reference/LocalMate_AI_BE` (ASP.NET Core .NET 10, PostgreSQL/PostGIS, JWT)
- Frontend web: `../_reference/LocalMate_AI_FE` (React 19 + Vite + Tailwind)
- Code Flutter hiện tại (Riverpod 3.4.3, go_router 18.1.0, Dio 5.11.1 với adapter mock fail-closed)

Ảnh "before": `docs/screenshots/before/` (390×844, text 1.0) và `docs/screenshots/before/320-text2x/` (320 px, text 2.0). Ảnh được render bằng `tool/ui_capture_test.dart` (widget test), **không phải emulator**: máy hiện chỉ có thiết bị Windows/Chrome/Edge, không có Android emulator.

---

## 1. Bảng màn hình

Điểm chất lượng là chất lượng thị giác hiện tại, thang 1–10.

| Màn hình | Trong thiết kế | Trong Flutter | Điểm | Vấn đề chính |
|---|---|---|---|---|
| App shell + bottom nav | Có (5 tab) | `AppShell` trong `app/router.dart` | 7 | Ổn định, accessible; nhưng AppBar mỗi tab chung chung, nút hành động `filledTonal` lạc tông, indicator nhạt; UI nằm trong file routing |
| Trang chủ | 01, 02, 26 | `DiscoveryHomePage` (`/home`) | 6 | Thanh tìm kiếm là `OutlinedButton` giả field; hero là khối navy phẳng, nửa phải trống; chuỗi dev "M3 OFFLINE · …" lộ ra người dùng; card gợi ý chỉ có placeholder icon chiếm 60% card; spacing lệch lưới (5, 9, 13, 15, 18) |
| Khám phá | 03, 04, 05 | `ExplorePage` (`/explore`) | 5 | Helper text lộ hợp đồng API ("2–100 ký tự · tối đa 5 kết quả mỗi nhóm"); 2 nút "Tìm kiếm"/"Xóa tìm kiếm" thay vì clear trong field + IME search; kết quả trộn `ListTile` mặc định và grid; empty/has-more là `Text()` trần; chỉ 2 danh mục hardcode |
| Chi tiết địa điểm | 06 | `PlaceDetailPage` (`/places/:id`) | 5 | Placeholder 220 px chiếm vùng đẹp nhất; khối "Thông tin tham khảo" là 5–6 dòng `Text()` 14sp, to hơn mô tả 12sp; không icon, không key/value; banner lặp lại CTA; không có giờ mở cửa dạng bảng, không có đánh giá |
| Lịch trình mẫu (curated) | — (không có) | `CuratedDetailPage` (`/curated/:id`) | 6 | Timeline tạm ổn; card điểm dừng chỉ có icon 48×56 + tên, thiếu giờ/thời lượng/danh mục; offline notice đứng đầu trang |
| Metro | 18, 19 | `MetroPage` (`/metro`) | 6.5 | Tương tác tốt nhất app (segmented, picker có tìm không dấu, nút đổi chiều) nhưng **không có sơ đồ tuyến**; 14 ga là `ListTile` + `CircleAvatar`; kết quả hành trình là các dòng text; màu tuyến `#1679C5` hardcode |
| Chi tiết ga | — (ngầm từ 18) | `StationDetailPage` (`/stations/:order`) | 6 | Nút Maps đứng trước nội dung; lịch chạy dày chữ, `ExpansionTile` mặc định; giờ tàu không trình bày dạng chip/bảng |
| Lịch trình (tab) | 17 | `PlannerEntryPage` (`/trips`) | 4 | Chỉ là empty state với icon ví (sai ẩn dụ); khối offline màu hổ phách + 2 dòng disclaimer; **không có danh sách chuyến** |
| Planner 4 bước | 07, 08, 09, 10, 11 | `PlannerPage` (`/planner`) | 6 | Nhãn trường lặp 2 lần (label trên + labelText); ngày nhập text "yyyy-MM-dd", giờ "HH:mm"; thời lượng hỏi 2 lần (card 2/4/6/8 + dropdown 1–24); ngân sách là ô số mặc định "0"; bước 4 nhồi phương tiện + ghi chú + 6 dòng tóm tắt; file 1352 dòng, lồng ~25 cấp |
| Đang chuẩn bị | 12 | `_PlannerLoading` | 7 | Gọn, nhưng tĩnh; thiết kế có checklist 3 bước tiến triển |
| Lịch trình nháp | 13, 14 | `PlannerPreviewPage` (`/planner/preview/:key`) | 5.5 | 4 disclaimer chồng nhau; card điểm dừng placeholder 67×67, tên 12sp; meta 12sp không nhóm; chưa có "Xem địa điểm"/"Đổi điểm", chặng di chuyển chỉ là text |
| Xác nhận chốt (sheet) | 15 | **Chưa có** | — | — |
| Lịch trình đã chốt | 16 | **Chưa có** | — | — |
| Đăng nhập | 24 | `LoginPage` (`/login`) | 6 | Logo dựng lại inline (3 bản logo khác nhau trong app); nhãn lặp; lỗi là `Text` đỏ trần; nút Google luôn disabled; nút dev "Điền tài khoản mẫu" + banner cảnh báo gây rối |
| Tài khoản | 20, 21 | `AuthAccountPage` (`/account`) | 5 | 2 ô thống kê hiển thị "—"; 3 disclaimer trên 1 màn; menu `ListTile` sát mép (inset ngang 0); nút Đăng xuất/Đổi tài khoản xếp chồng |
| Cá nhân hóa | 22 | Trang push bằng `Navigator` (không có route) | 5 | Chỉ banner + text, trường tên bị khóa; không chọn được sở thích |
| Gói & quyền sử dụng | 23, 25 | Trang push bằng `Navigator` (không có route) | 5 | Chỉ các dòng "chưa khả dụng"; không có card gói, không có giá |
| Phiên mẫu (`/private`) | — | inline trong router | 3 | Bản sao `/account` trong AppBar trần |
| Kết quả thanh toán | — | `/payment-return` | 3 | `EmptyContent` trần |
| Trang lỗi router | — | `errorBuilder` | 4 | `ErrorContent` trần |
| Sheet Google Maps | 19 | `MapsPreviewButton` sheet | 5 | Chỉ hiện URL để chọn, không mở được Maps (chưa có `url_launcher`) |

**Vấn đề xuyên suốt:**
- Chữ nội dung 11–12sp gần như mọi nơi; 2 thang chữ song song (`TextTheme` và `BrandTypography`) cộng style inline cho ra **12 cỡ chữ khác nhau**.
- Không có ảnh thật: mọi địa điểm đều là cùng một placeholder icon xanh nhạt.
- Chuỗi dành cho dev hiện ra với người dùng ("M3 OFFLINE", "M2 OFFLINE", "CHẾ ĐỘ OFFLINE", "mốc minh họa", "không phải dữ liệu production").
- Phẳng, chỉ dùng viền, không có phân tầng độ cao; bo góc lẫn lộn 4/5/8/16.
- **Không có dark mode**: widget gọi thẳng hằng màu `Brand.*` 139 lần, chỉ ~5 lần dùng `Theme.of(context)`.
- Literal rải rác: 158 `SizedBox` số cứng, 46 `TextStyle(` inline, 49 `EdgeInsets` số cứng; nặng nhất là `planner_page.dart`, `auth_pages.dart`, `discovery_pages.dart`.
- Không skeleton, không pull-to-refresh, không hero/chuyển trang tùy biến, không haptic.
- Không phát hiện offline thật: "offline" hiện chỉ có nghĩa là "đang chạy dữ liệu mock".

**Điểm mạnh cần giữ:** semantics/live region đầy đủ, vùng chạm 48dp, layout đã test ở text 200% và 3 bề rộng, logic auth/session có fencing tốt, tìm ga không dấu, quy tắc hiển thị độ chính xác lịch tàu (`ScheduleView`).

---

## 2. Ánh xạ màn hình ↔ API ↔ model Dart

Ghi chú:
- Mọi route backend có tiền tố `/api`. Mock Flutter hiện gọi path không có `/api`, baseUrl hardcode `https://mock.invalid`.
- Auth là 1 JWT access token, hạn 60 phút. **Không có refresh token**: hết hạn thì phải đăng nhập lại.
- Lỗi theo RFC 7807 ProblemDetails, luôn rẽ nhánh theo `code`.

| Màn hình | Endpoint backend | Model Dart hiện có | Khoảng trống |
|---|---|---|---|
| Trang chủ | `GET /api/places/metro-clusters`, `GET /api/itineraries/curated` | `StationCluster`, `Place`, `CuratedTrip` | `imageUrl`/`coverImageUrl` đã có trong model nhưng không render |
| Khám phá | `GET /api/search?q=&limit=` (3 nhóm: stations/places/curatedItineraries + `hasMore`), `GET /api/places/metro-clusters` | `SearchQuery`, `SearchResults`, `SearchStation`, `ResultGroup` | Danh mục lấy từ `master-data.placeCategories` (`Cafe/Food/Culture/CheckIn`); UI đang hardcode 2 |
| Chi tiết địa điểm | `GET /api/places/{id}`, `GET /api/places/{id}/reviews` | `Place` | Chưa map `openingHours`, `averageRating`, `reviewCount`, `tags`, `nearestStation.distanceMeters`; chưa có model Review |
| Lịch trình mẫu | `GET /api/itineraries/curated`, `POST /api/itineraries/curated/{id}/apply` | `CuratedTrip`, `CuratedStop` | Chưa có hành động "Áp dụng" (tạo Draft) |
| Metro | `GET /api/master-data` (14 ga), `GET /api/metro/journeys?from=&to=&date=` | `Station`, `MetroJourney`, `Headway` | — |
| Chi tiết ga | `GET /api/metro/stations/{order}/departures?date=` | `MetroSchedule`, `MetroDirection` | — |
| Planner bước 1–4 | `GET /api/master-data` (timeSlots, travelModes, tripLimits), `GET /api/tags`, `POST /api/trips/feasibility-check`, `POST /api/trips/parse-request` (AI điền giúp) | `PlannerCriteria`, `PlannerTag`, `PlannerTravelMode`, `TripGenerationRequestDto` | Chưa gọi feasibility-check; chưa có UI cho `suggestedStations`/`metroServiceHours` |
| Đang chuẩn bị → Nháp | `POST /api/trips/generate` → 201 `TripDetailResponse` | `TripGenerationResponseDto` (đã chuẩn bị, chưa dùng), `OfflineDraftPreview` | Nháp hiện là 2 điểm hardcode |
| Lịch trình nháp (sửa) | `GET .../items/{itemId}/alternatives`, `PUT .../replace`, `DELETE .../items/{itemId}`, `POST /api/trips/{id}/explanations` | — | Chưa có model `TripItemResponse`/`TripLegResponse`/`AlternativePlace` |
| Xác nhận chốt | `POST /api/trips/{id}/finalize` (403 `saved_trip_quota_exceeded`) | — | Chưa có |
| Đã chốt | `PUT /api/trips/items/{id}/visit`, `POST /api/trips/items/{id}/review`, `POST /api/feedback/trip` | — | Chưa có |
| Lịch trình của tôi | `GET /api/trips/my-trips`, `GET /api/trips/{id}`, `DELETE /api/trips/{id}`, `POST /api/trips/{id}/fork` | — | Chưa có model `MyTripResponse` |
| Đăng nhập | `POST /api/auth/login`, `POST /api/auth/google`, `POST /api/auth/demo` | `LoginRequest`, `LoginResponse`, `AuthSession` | Google/demo chưa có |
| Đăng ký / quên mật khẩu | `POST /api/auth/register`, `/register/verify`, `/register/resend`, `/password-reset/request`, `/password-reset/confirm` | — | Màn hình chưa có |
| Tài khoản | `GET /api/users/me`, `GET /api/subscription/me` | `AuthProfile` | Chưa có số liệu dùng gói, số chuyến đã lưu |
| Cá nhân hóa | `PATCH /api/users/me` (`fullName`, `preferences.interestTagIds`, `travelStyleTagIds`), `GET /api/tags` | — | Chưa có |
| Gói & quyền | `GET /api/subscription/plans`, `/me`, `/checkout-quote`, `POST /checkout`, `/renew`, `GET /orders/{id}`; `/api/itinerary-purchases/*` | — | Chưa có; thanh toán PayOS cần mở `checkoutUrl` + polling |
| Kết quả thanh toán | `GET /api/subscription/orders/{orderId}` | `PaymentReturnIntent` | Chưa verify trạng thái |
| Thông báo | `GET /api/notifications`, `/unread-count`, `POST /{id}/read`, `/read-all` | — | Chỉ là sheet tĩnh |

---

## 3. Màn hình / tính năng còn thiếu

Có trong thiết kế hoặc backend, nhưng Flutter chưa có:

1. **Lịch trình nháp thật**: tạo từ `generate`, đổi điểm (alternatives + replace), xóa điểm, "Xem địa điểm", chặng di chuyển (`leg`: đi bộ / xe máy / Metro với ga lên-xuống).
2. **Sheet xác nhận chốt** và **màn Đã chốt** (đánh dấu đã ghé, đánh giá điểm dừng, phản hồi chuyến đi).
3. **Danh sách "Lịch trình của tôi"** và **chi tiết chuyến** (Nháp/Đã chốt, xóa, nhân bản).
4. **Đăng ký + xác thực OTP 6 số**, **quên mật khẩu**, **đăng nhập Google**, **phiên demo**.
5. **Cá nhân hóa thật**: sửa tên, chọn sở thích và phong cách từ `/api/tags`.
6. **Gói & quyền sử dụng thật**: card gói Free/TripPass/Membership, hạn mức dùng, checkout PayOS, mua thêm 1 lượt chốt.
7. **Sơ đồ tuyến Metro 14 ga** (README thiết kế bắt buộc đủ 14 ga; HTML chỉ vẽ 3).
8. **Mở Google Maps** thật (hiện chỉ hiện URL).
9. **Kiểm tra khả thi** trước khi tạo, kèm gợi ý ga khác hoặc giờ chạy Metro.
10. **AI "Điền giúp tôi"** (parse-request) và **AI giải thích điểm dừng** (explanations).
11. **Thông báo** (polling, badge chưa đọc).
12. **Đánh giá địa điểm** công khai trên trang chi tiết.
13. **Trạng thái offline thật** (mất mạng), skeleton loading, pull-to-refresh, dark mode.

---

## 4. Câu hỏi cần anh/chị trả lời

1. **Ảnh địa điểm.** Thiết kế dùng ảnh thật, nhưng README cấm đưa bộ ảnh đó vào app. Backend có `imageUrl` (Cloudinary) nhưng dữ liệu seed đều `null`. Đề xuất: hiển thị ảnh khi API có `imageUrl`; khi không có thì dùng fallback được thiết kế (gradient theo danh mục, kèm icon/hoạ tiết). Ảnh hero trang chủ: dùng minh họa vector tự vẽ (Bến Thành / đoàn tàu), hay anh/chị có ảnh được phép dùng?
2. **Kết nối backend (Giai đoạn 4).** App đang cố ý ở chế độ mock fail-closed. Backend thật dùng URL nào: `https://localmate.io.vn/api` hay server khác? Đề xuất truyền qua `--dart-define=API_BASE_URL`, giữ mock làm mặc định cho test.
3. **Sở thích bắt buộc hay tùy chọn?** Backend cho phép `tagIds` rỗng, README thiết kế nói "tùy chọn", nhưng web bắt buộc ≥ 1. Mobile theo bên nào?
4. **Thời lượng.** README yêu cầu 1–24 giờ và chuyến qua đêm; web chỉ có 2/4/6/8. Đề xuất: chip nhanh 2/4/6/8 kèm "Tùy chỉnh" mở bottom sheet chọn 1–24 giờ (bỏ dropdown trùng lặp). Đồng ý không?
5. **Phạm vi màn hình mới.** Mục 3 có nhiều màn chưa tồn tại: đăng ký/OTP, quên mật khẩu, Đã chốt, chi tiết chuyến, thông báo, thanh toán PayOS. Giai đoạn 3 chỉ redesign các màn đang có (kèm sheet chốt và màn Đã chốt, vì chúng có trong thiết kế), còn lại làm ở Giai đoạn 4 hay để đợt sau?
6. **Tách logic khỏi UI.** `planner_page.dart` chứa nhiều logic (validate từng bước, quay lại bước lỗi, ghép request, tạm dừng khi app vào nền). Muốn viết lại UI an toàn thì cần chuyển phần này sang một `PlannerFormController` (Riverpod), **giữ nguyên hành vi**. Việc này chạm tầng logic. Cho phép không?
7. **Widget test.** Test hiện tìm widget theo text 177 lần và theo key 47 lần. Redesign sẽ đổi câu chữ và cấu trúc nên nhiều test sẽ phải cập nhật. Tôi sẽ giữ nguyên các `ValueKey` hiện có và chỉ sửa test khi câu chữ thay đổi có chủ đích. Đồng ý không?
8. **Disclaimer dữ liệu mẫu.** Thay toàn bộ chuỗi "M3 OFFLINE…" bằng một nhãn nhỏ thống nhất "Dữ liệu minh họa", chỉ hiện khi build ở chế độ mock. Vẫn giữ nhãn độ chính xác lịch tàu ("ước tính", "khoảng X phút/chuyến") vì đó là nội dung nghiệp vụ. Đồng ý không?
9. **Route `/private`.** Đây là bản sao của `/account`. Giữ route (theo quy tắc không đổi tên route) nhưng hiển thị y hệt Tài khoản, được không?
10. **Bottom nav.** Thiết kế có 5 tab, web có 6 (thêm "Hội viên"). Tôi đề xuất giữ 5 tab và đặt Gói trong Tài khoản, đúng như thiết kế gốc.

---

## 5. Sau redesign (Giai đoạn 5)

Ảnh "after": `docs/screenshots/after/` (chế độ mock, sáng và `-dark`) và `docs/screenshots/after/live-*.png` (chế độ backend, phản hồi thu từ backend thật). Ảnh vẫn render bằng widget test, không phải emulator.

### 5.1 Bảng màn hình

| Màn hình | Trước | Sau | Thay đổi chính | Còn lại |
|---|---|---|---|---|
| App shell + bottom nav | 7 | 9 | NavigationBar M3, header riêng từng tab, banner mất mạng thật (connectivity_plus) | — |
| Trang chủ | 6 | 8.5 | Hero minh họa vector tuyến Metro, ô tìm kiếm thật, carousel địa điểm có ảnh/fallback theo danh mục, skeleton, pull-to-refresh | Ảnh seed đều `null` nên chủ yếu thấy fallback |
| Khám phá | 5 | 8.5 | Search bar có xoá + IME search, chip đủ 4 danh mục từ backend, kết quả nhóm, empty/has-more có minh họa | — |
| Chi tiết địa điểm | 5 | 8.5 | SliverAppBar ảnh + Hero, InfoRow có icon, đánh giá, giờ mở cửa theo tuần (khi backend có), mở Google Maps thật (live) | Chưa có danh sách đánh giá công khai (`/places/{id}/reviews`) |
| Lịch trình mẫu (curated) | 6 | 8 | Timeline đầy đủ giờ/thời lượng/danh mục | Chưa có "Áp dụng" (`/curated/{id}/apply`) |
| Metro | 6.5 | 9 | Sơ đồ tuyến đủ 14 ga, chọn ga có tìm không dấu, kết quả hành trình dạng tuyến | — |
| Chi tiết ga | 6 | 8.5 | Lịch tàu dạng chip/hàng giãn cách, nhãn độ chính xác giữ nguyên quy tắc cũ | — |
| Lịch trình của tôi | 4 | 8.5 | Danh sách Đã chốt / Bản nháp từ backend, khách được mời đăng nhập, bản mock giữ màn giới thiệu | Chưa có xoá / nhân bản chuyến |
| Planner 4 bước | 6 | 8.5 | `PlannerFormController`, chip thời lượng + sheet 1–24 giờ, ngày/giờ bằng picker, ngân sách định dạng, "Điền giúp tôi bằng AI" (live) | Chưa gọi `feasibility-check` trước khi tạo |
| Đang chuẩn bị | 7 | 8.5 | Checklist 3 bước có chuyển động | — |
| Lịch trình nháp | 5.5 | 8.5 | Timeline + chặng (đi bộ / xe máy / Metro có ga lên-xuống), đổi điểm, xoá điểm, AI giải thích (live) | — |
| Xác nhận chốt (sheet) | — | 8.5 | Bottom sheet xác nhận | — |
| Lịch trình đã chốt | — | 8.5 | Tiến độ đã ghé, đánh dấu đã ghé, đánh giá điểm dừng, phản hồi chuyến đi | — |
| Đăng nhập | 6 | 8.5 | BrandLockup chung, lỗi dạng banner, Quên mật khẩu / Tạo tài khoản / Google (live) | Google chỉ bật khi có `GOOGLE_SERVER_CLIENT_ID` |
| Đăng ký + OTP, Quên mật khẩu | — | 8 | Form 2 bước, đếm ngược gửi lại mã, tự đăng nhập sau xác thực | Chưa chạy với SMTP thật |
| Tài khoản | 5 | 8.5 | Thẻ hồ sơ + hạn mức thật, section card, menu, Giao diện (lưu trên thiết bị) | — |
| Hồ sơ & cá nhân hóa | 5 | 8.5 | Sửa tên, sở thích, phong cách (live) | — |
| Gói & quyền sử dụng | 5 | 8.5 | Card gói giá thật, thanh hạn mức, checkout PayOS | Chưa có mua lẻ một lượt chốt |
| Thanh toán (`/payment-return`) | 3 | 8 | Theo dõi đơn tới khi Paid / Failed / Expired / ReviewRequired | Chưa chạy với PayOS thật |
| Thông báo | — | 8 | Danh sách, chấm chưa đọc, đọc hết, số chưa đọc ở Tài khoản | Không có push notification (backend không hỗ trợ) |
| Phiên mẫu (`/private`) | 3 | 8 | Dùng lại trang Tài khoản | — |
| Trang lỗi router | 4 | 8 | `AppStateView` có minh họa + về trang chủ | — |

### 5.2 Vấn đề xuyên suốt: trước → sau

| Vấn đề | Trước | Sau |
|---|---|---|
| Thang chữ | 12 cỡ, 2 hệ song song | 1 `TextTheme` Be Vietnam Pro; tối đa 3–4 cỡ mỗi màn |
| Màu hardcode | `Brand.*` 139 lần | 0; màu qua `ColorScheme` + `AppColors` (ThemeExtension). Hex còn lại chỉ ở `lib/dev/previews` (công cụ debug) |
| Literal spacing | 158 `SizedBox`, 49 `EdgeInsets`, 46 `TextStyle(` số cứng | Lưới 8pt qua `AppSpacing`/`AppRadius`; số cứng chỉ còn trong `lib/dev/previews` |
| Dark mode | Không có | Sáng/Tối/Theo hệ thống; kiểm tương phản WCAG trong `design_tokens_test.dart` và `accessibility_test.dart` |
| Trạng thái | Text trần | Skeleton, empty, error, offline (mất mạng thật) cho mọi màn tải dữ liệu |
| Chuyển động | Không | SharedAxis chuyển trang, Hero ảnh địa điểm, stagger danh sách, haptic (150–350ms) |
| Chuỗi dành cho dev | "M3 OFFLINE"... lộ ra | Nhãn "Dữ liệu minh họa" chỉ ở bản mock; bản live có test quét để không lọt chữ của bản mock |
| Kết nối dữ liệu | Mock fail-closed | Mock mặc định; live qua `API_BASE_URL` (xem `LIVE_BACKEND.md`) |

### 5.3 Kiểm tra đã chạy

- **Kích thước × cỡ chữ × giao diện**: `tool/redesign_capture_test.dart` (mock) và `tool/live_capture_test.dart` (live) chạy cùng ma trận 390×844 sáng/tối, 360×640 chữ 1.3, 393×852 chữ 1.3 tối, 430×932 chữ 1.3, 320×640 chữ 2.0. Không có lỗi layout/tràn.
- **Khả năng tiếp cận**: `test/accessibility_test.dart` kiểm vùng chạm ≥48dp, nhãn cho phần tử bấm được và tương phản chữ trên các màn chính và các bottom sheet, chế độ mock và live, sáng và tối.
- `flutter analyze`: sạch. `flutter test`: 311 test pass. `flutter build web --release`: thành công.
- `flutter build apk --debug`: thành công. **Chưa chạy** trên thiết bị/emulator thật.
