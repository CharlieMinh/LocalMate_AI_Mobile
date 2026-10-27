# Kết nối backend thật (Giai đoạn 4)

App có hai chế độ, chọn **lúc build**:

| Chế độ | Cách bật | Dữ liệu |
|---|---|---|
| Mock (mặc định) | không truyền gì | Fixture cục bộ, không mở socket nào (fail-closed) |
| Backend thật | `--dart-define=API_BASE_URL=<origin>` | `LocalMate_AI_BE`, tiền tố `/api` được thêm tự động |

`API_BASE_URL` phải là `https://...`. Riêng `APP_ENV=development` cho phép thêm `http://` tới `localhost`, `127.0.0.1` hoặc `10.0.2.2` (Android emulator). Không có URL nào được hardcode trong mã nguồn.

```bash
# Android emulator trỏ vào backend chạy trên máy dev
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5286

# Production
flutter build apk --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://<api-domain>

# Bật đăng nhập Google (client ID loại *web*, trùng GoogleAuth__ClientId của backend)
flutter run --dart-define=API_BASE_URL=... --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Không có `GOOGLE_SERVER_CLIENT_ID` thì nút Google bị tắt. Android cần thêm một OAuth client loại Android (package name + SHA-1 của keystore) trong cùng Google Cloud project; việc này cấu hình trên console, không nằm trong mã nguồn.

### Lưu giá trị trên máy (không commit)

Thay vì gõ từng `--dart-define`, có thể lưu các giá trị vào một file local bị gitignore:

```bash
cp config/dart_defines.example.json config/dart_defines.local.json   # rồi điền giá trị
flutter run --dart-define-from-file=config/dart_defines.local.json
flutter build apk --debug --dart-define-from-file=config/dart_defines.local.json
```

`config/*.local.json` nằm trong `.gitignore`. File chỉ chứa 3 giá trị mà app thật sự đọc:

| Khoá | Lấy từ đâu |
|---|---|
| `APP_ENV` | `development`, `staging` hoặc `production` |
| `API_BASE_URL` | Địa chỉ backend (emulator + backend trên máy dev: `http://10.0.2.2:5286`) |
| `GOOGLE_SERVER_CLIENT_ID` | `GoogleAuth__ClientId` trong `.env` của backend (client ID loại web, không phải bí mật) |

### Không đưa key của backend vào app

SMTP, Gemini (`Llm__ApiKey`, `Embedding__ApiKey`), PayOS, Cloudinary, `Jwt__SigningKey`, `Otp__HashKey` và mật khẩu Postgres là **bí mật phía server**.

- App không gọi các dịch vụ này mà đi qua API của backend, nên không cần các key đó.
- Mọi giá trị truyền bằng `--dart-define` đều được đóng vào APK, và ai có APK cũng giải nén lấy ra được, kể cả khi không push lên GitHub.

Muốn đăng ký / quên mật khẩu, AI và PayOS chạy thật: hãy chạy **backend** với `.env` của nó (xem mục dưới); app tự dùng được qua API.

## Chạy backend cục bộ để thử

Không cần sửa repo BE. Các biến môi trường dưới đây chỉ dùng cho máy dev:

```bash
cd ../_reference/LocalMate_AI_BE
POSTGRES_PASSWORD=<tự đặt> Jwt__SigningKey=<base64 ≥32 byte> GoogleAuth__ClientId=local-dev \
  docker compose -p localmate-dev up -d database
ConnectionStrings__DefaultConnection="Host=localhost;Port=5433;Database=localmateai;Username=localmate;Password=<như trên>" \
Jwt__SigningKey=<như trên> GoogleAuth__ClientId=local-dev Cors__AllowedOrigins__0=http://localhost:5173 \
ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS=http://0.0.0.0:5286 \
  dotnet run --project LocalMateAI.API --no-launch-profile
```

Backend tự migrate và seed dữ liệu: 14 ga, khoảng 65 địa điểm, 3 gói và các tài khoản dev `user1..3@localmate.dev` (mật khẩu dev nằm trong `DataSeeder.cs`, chỉ có ở môi trường Development).

## Đã nối

| Màn hình | Endpoint |
|---|---|
| Trang chủ / Khám phá / Chi tiết địa điểm | `GET /places/metro-clusters`, `/itineraries/curated`, `/search`, `/places/{id}` |
| Metro / Chi tiết ga | `GET /master-data`, `/metro/journeys`, `/metro/stations/{order}/departures` |
| Đăng nhập / phiên | `POST /auth/login`, `POST /auth/google`, `GET /users/me`. JWT lưu trong secure storage (namespace riêng với bản mock). Không có refresh token: khi gặp 401 hoặc token hết hạn, app tự đăng xuất và báo "Phiên đăng nhập đã hết hạn" |
| Đăng ký (`/register`) | `POST /auth/register` → mã 6 số qua email → `/auth/register/verify`, `/auth/register/resend` (đếm ngược theo `resendAfterSeconds`). Xác thực xong app tự đăng nhập |
| Quên mật khẩu (`/forgot-password`) | `POST /auth/password-reset/request`, `/auth/password-reset/confirm` |
| Hồ sơ & cá nhân hóa | `PATCH /users/me` (tên, sở thích, phong cách), tên tag từ `GET /tags` |
| Thông báo (`/notifications`) | `GET /notifications`, `/notifications/unread-count` (số chưa đọc ở Tài khoản), `POST /notifications/{id}/read`, `/notifications/read-all`. Chạm thông báo mở lịch trình / gói / Planner |
| Planner | `GET /tags`, `POST /trips/generate` → mở thẳng lịch trình nháp. "Điền giúp tôi bằng AI": `POST /trips/parse-request` điền sẵn các bước rồi quay về bước 1 để xem lại |
| Lịch trình nháp | `GET /trips/{id}`, đổi điểm (`GET …/alternatives`, `PUT …/replace`), xoá điểm (`DELETE /trips/{id}/items/{itemId}`), AI giải thích (`POST /trips/{id}/explanations`), chốt (`POST /trips/{id}/finalize`) |
| Lịch trình đã chốt | `PUT /trips/items/{id}/visit`; đánh giá điểm đã ghé (`GET/POST/DELETE /trips/items/{id}/review`, nhận xét nhanh từ `master-data.reviewQuickTags`); phản hồi chuyến đi (`GET/POST /feedback/trip`, `feedbackQuickTags`) |
| Gói & thanh toán | `GET /subscription/me`, `/subscription/plans`, `/subscription/checkout-quote`, `POST /subscription/checkout` → mở `checkoutUrl` (PayOS) bằng trình duyệt → `/payment-return?orderId&flow=subscription` hỏi `GET /subscription/orders/{id}` mỗi 3 giây tới khi Paid/Failed/Expired (tối đa 15 phút). Đơn đang mở (409 `pending_order_exists`) được mở lại thay vì tạo đơn mới. Liên kết quay về không bao giờ được coi là bằng chứng thanh toán |
| Giao diện | Lựa chọn Sáng/Tối/Theo hệ thống lưu trên thiết bị (secure storage, khoá `localmate.prefs.themeMode`) |

Lỗi ProblemDetails được map sang tiếng Việt trong `lib/core/network/api_messages.dart`. Lỗi từng trường từ server chỉ hiển thị nguyên văn khi server đã trả tiếng Việt; thông điệp mặc định tiếng Anh của ASP.NET được thay bằng câu tiếng Việt. Timeout, mất mạng và lỗi 5xx có thông điệp riêng.

## Thử với key thật (27/10/2026)

Backend chạy trên máy với `.env` thật (SMTP, Gemini, PayOS), DB thử nghiệm riêng. Phản hồi thật được giải mã bằng model của app (test tạm, không commit).

| Luồng | Kết quả |
|---|---|
| Đăng ký + OTP qua email | **Chạy được**: email tới hộp thư thật, `register/verify` → 201, đăng nhập, hồ sơ, gói Free, thông báo chào mừng |
| "Điền giúp tôi" (`parse-request`) | **Chạy được** với Gemini (~8–10 s); app điền đúng thời lượng, ngân sách, phương tiện, ngày giờ, sở thích, ga đích và hỏi thêm ga xuất phát |
| AI giải thích (`explanations`) | **Lỗi phía backend**: `TripExplanationService.ProviderTimeout` = 10 s nên Gemini bị cắt (`ProviderFailed` sau 10.010 ms, cả 2 lần). App hiện đúng thông báo 503 |
| PayOS checkout | **Lỗi phía backend**: mã đơn lấy từ sequence `PaymentOrderCodeSequence`, nên DB mới đánh số lại từ đầu và trùng đơn đã có trên cùng tài khoản PayOS (đơn thật, đã thanh toán). Backend trả 502; không có đơn mới nào được tạo |

Chưa kiểm: quên mật khẩu với email thật, PayOS thành công (cần dải mã đơn riêng cho môi trường thử), Google với ID token thật (cần OAuth client Android), chạy trên thiết bị thật.

Chưa làm: mua lẻ một lượt chốt lịch trình (`/itinerary-purchases/*`; màn trạng thái đơn đã hỗ trợ `flow=single`), góp ý ứng dụng (`/app-feedback`), phiên demo (`/auth/demo`).

## Kiểm thử

- `test/live_contract_test.dart`: decode JSON **thu từ backend thật** (`test/fixtures/live/`) bằng model của app. Ngoài ra kiểm tra HTTP client: gắn token, 401 dẫn tới đăng xuất, timeout/offline, map ProblemDetails.
- `test/live_ui_test.dart`: chạy app ở chế độ backend (cấu hình có URL) với phản hồi thật đã thu: đăng nhập, gói, danh sách và chi tiết lịch trình, chốt, đánh dấu đã ghé, đánh giá điểm dừng và chuyến đi, đổi / xoá điểm nháp, AI, "Điền giúp tôi", đăng ký, quên mật khẩu, sửa hồ sơ, thông báo, PayOS (thành công, cổng lỗi, đơn đang mở, hết hạn), Google (thành công, huỷ, lỗi), chặn khách tạo lịch trình, lỗi hết lượt.
- `test/theme_preference_test.dart`: lưu và khôi phục lựa chọn giao diện.
- `tool/live_capture_test.dart`: chụp các màn trên vào `docs/screenshots/after/live-*.png`.
