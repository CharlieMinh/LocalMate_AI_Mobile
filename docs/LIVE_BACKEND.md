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
```

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
| Đăng nhập / phiên | `POST /auth/login`, `GET /users/me`. JWT lưu trong secure storage (namespace riêng với bản mock). Không có refresh token: khi gặp 401 hoặc token hết hạn, app tự đăng xuất và báo "Phiên đăng nhập đã hết hạn" |
| Planner | `GET /tags` (sở thích), `POST /trips/generate` → mở thẳng lịch trình nháp vừa lưu. Khách chưa đăng nhập được mời đăng nhập trước |
| Lịch trình của tôi | `GET /trips/my-trips`, `GET /trips/{id}`, `POST /trips/{id}/finalize`, `PUT /trips/items/{id}/visit` |
| Tài khoản / Gói | `GET /subscription/me` (lượt tạo, lịch trình đã lưu, lượt AI), `GET /subscription/plans` (giá thật), `GET /tags` (tên sở thích đã lưu) |

Lỗi ProblemDetails được map sang tiếng Việt trong `lib/core/network/api_messages.dart` (hết lượt tạo, ngoài vùng phục vụ, Metro chưa chạy, trùng địa điểm…). Lỗi từng trường từ server được hiển thị nguyên văn. Timeout, mất mạng và lỗi 5xx có thông điệp riêng.

## Còn để TODO (đánh dấu `TODO(phase-5)` trong code)

- Thanh toán PayOS: `POST /subscription/checkout`, mở `checkoutUrl`, polling `GET /subscription/orders/{id}`.
- Đăng nhập Google (cần `google_sign_in` và client ID), đăng ký + OTP, quên mật khẩu, phiên demo.
- Đánh giá điểm dừng và chuyến đi: `POST /trips/items/{id}/review`, `POST /feedback/trip`.
- Đổi hoặc xóa điểm dừng: `alternatives` / `replace` / `DELETE item`. AI viết lý do (`explanations`) và "Điền giúp tôi" (`parse-request`).
- Sửa hồ sơ và sở thích (`PATCH /users/me`), thông báo (`/notifications`), lưu lựa chọn giao diện.

## Kiểm thử

- `test/live_contract_test.dart`: decode JSON **thu từ backend thật** (`test/fixtures/live/`) bằng model của app. Ngoài ra kiểm tra HTTP client: gắn token, 401 dẫn tới đăng xuất, timeout/offline, map ProblemDetails.
- `test/live_ui_test.dart`: chạy app ở chế độ backend (cấu hình có URL) với phản hồi thật đã thu: đăng nhập, gói, danh sách và chi tiết lịch trình, chốt, đánh dấu đã ghé, chặn khách tạo lịch trình, lỗi hết lượt.
- `tool/live_capture_test.dart`: chụp các màn trên vào `docs/screenshots/after/live-*.png`.
