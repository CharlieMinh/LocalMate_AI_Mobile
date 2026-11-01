# Android release — LocalMate AI

## Trạng thái chuẩn bị ngày 28/10/2026

- Package giữ nguyên: `vn.io.localmate.mobile`; tên trên máy: `LocalMate AI`.
- Icon mới dựa trên logo được chủ dự án duyệt: robot trong ghim định vị, vòng cung vàng, không có chữ.
- Đã có legacy icon đủ 5 mật độ, adaptive icon Android 8+, monochrome Android 13+, icon Play Store 512×512.
- Đã cấu hình release signing riêng. Keystore và mật khẩu nằm ngoài Git; không dùng debug key cho release.
- Leader đã cung cấp `https://api.localmate.io.vn/api/master-data`. Kiểm tra HTTPS ngày 28/10/2026 trả HTTP 200, JSON có 14 `metroStations` và các danh mục đúng cấu trúc app. Đã điền `API_BASE_URL=https://api.localmate.io.vn` vào file production local; không kèm `/api/master-data` vì app tự thêm `/api` và đường dẫn từng chức năng.
- Chủ dự án đã cung cấp Google Client ID ngày 28/10/2026; đã điền vào `GOOGLE_SERVER_CLIENT_ID` trong file production local. Ảnh Google Cloud do chủ dự án cung cấp xác nhận client loại **Web application** và đã tạo `LocalMate Android Release` trong cùng project, đúng package `vn.io.localmate.mobile` và SHA-1 release `19:9F:8C:0B:5F:8E:60:8B:93:A7:C0:C7:40:30:C2:D9:10:24:35:1C`. Đăng nhập thực tế và audience BE production vẫn cần kiểm thử. Endpoint master-data hoạt động chưa chứng minh đăng nhập, AI hay thanh toán hoạt động.
- Đã build APK production `0.1.0+1` ngày 28/10/2026: `build/app/outputs/flutter-apk/app-release.apk`, 64.126.988 byte (~61,16 MiB), gồm ARM64/ARMv7/x86_64. `apksigner verify` đạt, SHA-256 chứng thư khớp release key đã tạo; `zipalign -c -P 16 4` đạt. Package/min SDK/target SDK: `vn.io.localmate.mobile` / 24 / 36, không debuggable; tài nguyên icon hiện diện trong resource table. Chưa cài thử trên điện thoại thật; không có thiết bị ADB kết nối khi build.
- Build có cảnh báo SDK XML v3/v4 và font Cupertino chưa khai báo. Không thấy tham chiếu `CupertinoIcons` trực tiếp trong `lib`; vẫn cần kiểm tra icon và UI khi chạy APK thật. Không coi build thành công là bằng chứng tất cả màn hình hoạt động.
- Đã cài chính APK release lên AVD riêng `LocalMate_Release_API_35` / `emulator-5556` ngày 28/10/2026, Android 15 x86_64 có Google Play services, WHPX và GPU host NVIDIA RTX 3060. Mở app thành công; Home hiển thị, Explore tải 62 địa điểm kèm ảnh, Metro tải tuyến 14 ga và Account hiển thị trạng thái khách. Chưa đăng nhập, chưa test AI/thanh toán. Dữ liệu AVD cũ `LocalMate_API_35` được giữ nguyên. Báo cáo tại `outputs/mobile-apk-emulator-test-20261028/RESULT.md` tính từ workspace EXE201.

## 1. Thông tin cần lấy từ Leader

> Anh gửi giúp em URL API public có HTTPS để app Android kết nối, kèm Swagger nếu có. Cho em biết URL đã bao gồm `/api` chưa. Nếu dùng đăng nhập Google, anh gửi Google Web Client ID mà BE đang xác thực; em sẽ gửi package name và fingerprint chứng thư ký Android để cấu hình OAuth release.

Không cần tài khoản SSH/VPS hay mật khẩu database. Nếu URL nhận được là `https://<domain>/api`, cấu hình app dùng origin `https://<domain>` vì `ApiClient` đã thêm `/api`. Xác nhận endpoint `GET /api/master-data` trả JSON có `metroStations`, không phải HTML website hoặc trang đăng nhập.

Google Web Client ID là cấu hình public. Các key Gemini/SMTP/PayOS, JWT signing key và mật khẩu Postgres chỉ nằm ở BE, không đưa vào dart-define.

Web Client ID vẫn là Google OAuth Client ID; chữ **Web** chỉ loại client được tạo trong Google Cloud. App Android hiện truyền ID này qua `serverClientId` để lấy Google ID token có audience được BE chấp nhận. Kiểm tra tại Google Cloud → Google Auth Platform → Clients (hoặc APIs & Services → Credentials), loại **Web application**. ID thường có đuôi `.apps.googleusercontent.com`; đuôi này không đủ phân biệt Android với Web. Android OAuth client riêng dùng package + SHA-1 của chứng thư ký, trong cùng project. Không cần gửi Client Secret.

## 2. Cấu hình production

```powershell
Copy-Item config/dart_defines.production.example.json config/dart_defines.production.local.json
```

File mẫu để trống API có chủ đích; **chưa chạy được release khi chưa điền**. Không ghi đè file `.local.json` đã có giá trị.

```json
{
  "APP_ENV": "production",
  "API_BASE_URL": "https://api.localmate.io.vn",
  "GOOGLE_SERVER_CLIENT_ID": "<web-client-id>.apps.googleusercontent.com"
}
```

Nếu chưa bật Google thì để Client ID rỗng. File `.local.json` bị gitignore. Quy trình build từ chối field khác ngoài ba field trên để tránh đưa nhầm key server vào APK.

## 3. Ký release và sao lưu

- `android/key.properties` bị gitignore, trỏ tới keystore bên ngoài repository.
- Keystore dùng PKCS12, RSA 4096, alias `localmate-release`; không tự tạo lại mỗi lần build.
- Trên máy chuẩn bị bản đầu: `%USERPROFILE%/.localmate-signing/android/` chứa keystore và thông tin ký; có bản sao ZIP trong `backups/`.
- ZIP chỉ chứa keystore được mã hóa bằng mật khẩu, không kèm file mật khẩu. Giữ mật khẩu riêng khi sao lưu ra ngoài máy.
- `release-signing.properties`, keystore và ZIP backup đều là tài liệu riêng tư. Không gửi chúng cho Leader để cấu hình Google, không đưa vào Git hoặc đính kèm cùng APK.
- Backup hiện nằm cùng máy, chỉ giúp phục hồi xóa nhầm. Chủ dự án cần giữ thêm bản sao riêng an toàn ngoài máy để bảo vệ các lần cập nhật lâu dài.
- File certificate `.pem` và fingerprint SHA-1/SHA-256 là **public**, có thể gửi Leader. Với Google đăng nhập Android cần đăng ký client Android có đúng package + SHA-1 release trong cùng Google Cloud project với Web Client ID.
- Sau này phát hành qua Google Play, nếu Play App Signing dùng chứng thư khác thì phải đăng ký thêm fingerprint của **app signing certificate**, không nhầm với upload certificate.

Không có khóa trên CI vẫn build debug bình thường. Release sẽ dừng nếu thiếu signing, không dùng APP_ENV production hoặc API không phải origin HTTPS public. API phải là tên miền công khai; địa chỉ IP (kể cả `[::1]`, `127.x`, `10.0.2.2`), tên một nhãn và `*.localhost` đều bị từ chối.

Gradle hỗ trợ `-Plocalmate.signingProperties=<path>` nếu cần trỏ trực tiếp tới file properties bên ngoài repo. Khi không truyền, mặc định dùng `android/key.properties`. Tùy chọn này cũng cho phép kiểm tra debug/CI khi không có khóa release mà không di chuyển file riêng tư.

## 4. Build và xác minh

Windows/PowerShell, từ repository root:

```powershell
./tool/build_android_release.ps1
```

Script kiểm tra config, đọc `GET /api/master-data`, khôi phục dependency theo lockfile, rồi build APK release đã ký. Để tách APK theo ABI:

```powershell
./tool/build_android_release.ps1 -SplitPerAbi
```

Lệnh Flutter tương đương sau khi cấu hình hoàn tất:

```powershell
flutter build apk --release --dart-define-from-file=config/dart_defines.production.local.json
```

Một APK: `build/app/outputs/flutter-apk/app-release.apk`. Khi split: chọn bản `app-arm64-v8a-release.apk` cho máy ARM64 tương ứng; không nhầm x86_64 emulator với điện thoại.

Kiểm tra bằng `apksigner verify --verbose --print-certs <apk>` trong Android SDK build-tools. Đối chiếu chứng thư release, application ID, version và cấu hình API đã xác nhận trước khi chia sẻ.

Version hiện giữ `0.1.0+1`; tăng số sau dấu `+` cho bản cập nhật. Giữ cùng package và signing key cho các lần cập nhật. APK release có chữ ký khác APK debug, nên không cài đè debug bằng cách xóa dữ liệu người dùng mà chưa phối hợp với chủ máy.

## 5. Icon và nguồn artwork

- `assets/brand/logo.jpg`: logo gốc, giữ nguyên.
- `assets/brand/app-icon-mark.png`: artwork nền trong suốt tạo bằng built-in image_gen từ logo.
- `assets/brand/app-icon-play-512.png`: PNG 512×512 nền trắng đặc, không bo góc/shadow sẵn.
- Android resources chứa các PNG legacy, foreground 432px và monochrome, cùng adaptive XML v26/v33.
- Artwork adaptive được giữ trong vòng tròn bán kính 31dp ở giữa canvas 108dp, có thêm khoảng trống trong safe zone 66dp để tránh cắt ghim/mũi tên.
- Xuất lại bằng `./tool/export_android_icons.ps1` trên Windows/PowerShell. Đây là export kích thước và mask kỹ thuật từ artwork; không vẽ lại nhận diện.
- Prompt và nguồn: `assets/brand/app-icon-source.md`.

## 6. Kiểm tra điện thoại trước khi chia sẻ

- Cài bản **release** lên Android thật; tắt kết nối với máy dev và dùng Wi-Fi/mạng di động để xác nhận API online.
- Icon: tròn/vuông bo, themed icon nếu launcher hỗ trợ, danh sách app và thông tin ứng dụng.
- Đăng nhập email/Google, OTP và khôi phục phiên; Google phải thử với chứng thư release.
- Địa điểm, tìm kiếm, Metro, ảnh và retry khi mất mạng.
- Planner/AI, chuyến nháp/chốt, chỉnh điểm, đã ghé và review/feedback.
- Gói/quyền sử dụng và luồng quay lại sau PayOS. Không coi redirect Paid là xác nhận thanh toán; app phải đọc trạng thái từ BE.
- Không thực hiện thanh toán thật thay chủ dự án. Rà chính sách billing riêng trước khi đưa lên Google Play.

Chỉ đánh dấu mục đã có bằng chứng thật; không suy ra tất cả chức năng hoạt động từ một lần build thành công.

## Tài liệu chính thức

- https://docs.flutter.dev/deployment/android
- https://developer.android.com/studio/publish/app-signing
- https://developer.android.com/develop/ui/compose/system/icon_design_adaptive
- https://developer.android.com/distribute/google-play/resources/icon-design-specifications
- https://pub.dev/packages/google_sign_in_android
- https://developers.google.com/identity/sign-in/android/backend-auth
