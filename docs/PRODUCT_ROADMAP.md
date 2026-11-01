# LocalMate AI — kế hoạch sản phẩm, tăng trưởng và Google Play

Ngày lập: 28/10/2026. Trạng thái: đề xuất để nhóm chốt phạm vi, chưa phải cam kết tiến độ hoặc ngân sách. Chủ dự án xác nhận chưa có Google Play Console, dự kiến đăng ký tài khoản cá nhân. Chưa tạo tài khoản, mua dịch vụ, chạy quảng cáo hay nộp bản phát hành trong công việc lập kế hoạch này.

## 1. Điểm xuất phát và định hướng

Đã có APK production ký release, icon và API online. Kiểm thử gần nhất trên emulator xác nhận Home, Explore với 62 địa điểm và Metro 14 ga; chưa xác nhận đầy đủ các luồng có đăng nhập, AI, thanh toán hoặc điện thoại thật. Ảnh Google Cloud xác nhận Web Client ID và Android OAuth đúng package/SHA-1 release. Xem `ANDROID_RELEASE.md` để phân biệt việc đã kiểm chứng và việc còn chờ test.

Mã nguồn có thiết kế sáng/tối, cỡ chữ hệ thống, vùng chạm 48dp, tìm kiếm địa điểm, Metro, Planner, lịch trình, tài khoản và gói PayOS. Chưa thấy luồng xóa tài khoản hoặc báo cáo nội dung AI riêng trong Flutter. Phản hồi chuyến đi đã có, nhưng không mặc nhiên thay thế báo cáo nội dung AI. Tài liệu backend ghi nhận lỗi AI/PayOS trong môi trường thử trước đây; cần kiểm tra lại production, không coi đó là lỗi production đã xác nhận hôm nay.

**Lời hứa sản phẩm đề xuất:** giúp người dùng chọn một chuyến đi quanh ga Metro TP.HCM phù hợp thời gian, ngân sách và khả năng đi bộ, rồi thực sự đi được theo lịch trình đó.

Thị trường đầu tiên nên tập trung quanh tuyến Metro số 1, thay vì mở rộng nhiều thành phố ngay. Nhóm thử nghiệm đầu gồm người địa phương tìm chỗ đi cuối tuần, người mới đi Metro, nhóm bạn và gia đình. Cần phỏng vấn để kiểm chứng, chưa coi đây là phân khúc đã có nhu cầu trả tiền.

“Dễ dùng cho nhiều độ tuổi” là tiêu chí trải nghiệm. Nhóm tuổi khai báo trên Google Play phải phản ánh đúng đối tượng thực sự phục vụ. Nếu chủ đích phục vụ trẻ em, cần đánh giá thêm Families policy và xử lý dữ liệu tương ứng. [Google Play Families](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en).

## 2. Lộ trình 90 ngày và hướng 6–12 tháng

Mốc tính từ lúc nhóm chốt kế hoạch. Các việc cần BE, nội dung và Flutter chạy cùng một backlog; thời gian thực tế phụ thuộc nhân lực. Các điều kiện hoàn thành quan trọng hơn ngày dự kiến.

| Giai đoạn | Sản phẩm và kỹ thuật | Người dùng và thị trường | Điều kiện chuyển tiếp |
|---|---|---|---|
| Tuần 1–2 | Test các luồng production trên máy thật; đo hiệu năng; chốt phương án thanh toán Play; thiết kế xóa tài khoản, báo cáo AI và lưu nháp | Phỏng vấn khoảng 12–15 người, có người trung niên/lớn tuổi và người ít dùng công nghệ; tuyển 20–30 người cho beta | Có danh sách lỗi ưu tiên, dữ liệu nền, phương án Play và người chịu trách nhiệm |
| Tuần 3–4 | Hoàn tất các việc chặn phát hành; AAB internal test; Privacy/Data safety; kiểm tra 16 KB và OAuth bản Play | Test có quan sát với nhóm nhỏ; kiểm chứng 5 tác vụ chính; chuẩn bị nội dung quanh 3–5 ga | Các luồng cốt lõi ổn định; các nút hiện hữu có tác dụng; có phương án tiếp nhận lỗi |
| Tuần 5–6 hoặc lâu hơn nếu cần | Closed testing; sửa lỗi theo dữ liệu và phản hồi; ghi lại thay đổi qua từng build | Nhóm beta dùng các lịch trình thật; ghi nhật ký sử dụng và phỏng vấn sau chuyến | Đủ điều kiện tài khoản cá nhân và bằng chứng sản phẩm sẵn sàng; mới xin production access |
| Tuần 7–8, phụ thuộc Google xét duyệt | Hoàn thiện store listing, tài khoản reviewer và kiểm tra cuối; phát hành công khai phạm vi nhỏ tại Việt Nam khi được duyệt | Thử nội dung ngắn, cộng đồng địa phương và đối tác nhỏ; theo dõi phản hồi hàng ngày | Không có lỗi nghiêm trọng tồn đọng; có chủ trực hỗ trợ và khả năng ra hotfix |
| Tháng 3 | Cải thiện điểm rơi rớt lớn nhất trong funnel; thử lưu/chia sẻ lịch trình và trải nghiệm quay lại | So sánh các kênh theo người dùng thực sự tạo/sử dụng chuyến; thử giá trị Premium với nhóm nhỏ | Có tín hiệu người dùng quay lại và chi phí phục vụ phù hợp trước khi mở rộng quảng cáo |
| Tháng 4–6 | Cá nhân hóa dựa trên phản hồi, dữ liệu địa điểm tin cậy, lịch trình lưu dùng khi mạng yếu; tiếng Anh nếu có nhu cầu | Mở rộng dần các ga/đối tác sau khi chất lượng khu vực đầu đạt yêu cầu | Các nhóm người dùng mới dùng được app với chi phí hỗ trợ chấp nhận được |
| Tháng 7–12 | Cân nhắc khu vực/thành phố mới, hợp tác dịch vụ thực và iOS theo dữ liệu sử dụng | Mở rộng kênh đã chứng minh có người quay lại; thương mại hóa có kiểm soát | Chỉ mở rộng khi vận hành dữ liệu, hỗ trợ và kinh tế mỗi người dùng có thể duy trì |

Closed test tối thiểu không phải thời hạn Google cam kết duyệt. Không hẹn ngày ra mắt cố định trước khi biết kết quả xác minh và production access.

## 3. UX phù hợp nhiều độ tuổi

Giữ nền tảng giao diện đã hoàn thành; ưu tiên sửa những chỗ người dùng thật bị vướng thay vì redesign toàn bộ.

| Nhu cầu | Thay đổi đề xuất | Cách đánh giá |
|---|---|---|
| Lần đầu mở app | Cho khám phá địa điểm trước; giải thích lợi ích bằng một câu; đăng nhập tại bước cần lưu/đồng bộ | Người mới biết app giúp gì và bắt đầu được mà không cần người hướng dẫn |
| Chọn chuyến nhanh | Câu hỏi chính: đi từ ga nào, có bao nhiêu thời gian, ngân sách bao nhiêu; sở thích có giá trị mặc định và chỉnh sau | Thử luồng rút gọn so với Planner hiện có; giữ lại cách có tỷ lệ hoàn thành tốt hơn |
| Không biết viết prompt | Có lựa chọn “Đi nhẹ nhàng”, “Ăn uống”, “Gia đình”, “Khám phá”; AI là cách nhập bổ sung | Người không dùng AI vẫn nhận được lịch trình có ích |
| Đọc và chạm dễ | Tôn trọng chữ hệ thống tới 200%, body đề xuất khoảng 16sp; nhãn đi cùng icon; vùng chạm ít nhất 48dp; tương phản chữ thông thường ít nhất 4.5:1 | Test TalkBack, chữ lớn, sáng/tối, màn nhỏ và khi dùng ngoài trời trên máy thật |
| Người đi cùng trẻ nhỏ/người lớn tuổi | Cho chọn mức đi bộ, số điểm dừng và khoảng nghỉ; xác minh dữ liệu tiện ích trước khi hiển thị | Mỗi lịch trình nêu rõ tổng đi bộ, chặng dài nhất và thời gian nghỉ; không suy đoán khả năng tiếp cận |
| Thao tác nhầm hoặc bị gián đoạn | Lưu nháp, quay lại đúng bước sau đăng nhập, xác nhận thao tác mất dữ liệu, có hoàn tác khi phù hợp | Đóng/mở app, Back, hết phiên, đổi mạng không làm mất dữ liệu đã cam kết lưu |
| Tin tưởng thông tin | Giá, giờ mở cửa, thời gian đi bộ ghi rõ là ước tính khi cần; hiển thị thời điểm cập nhật và nút báo sai | Nhóm nội dung sửa được báo sai, có lịch rà soát dữ liệu |
| Muốn dùng ngay lúc đang đi | Chỉ đường và điểm tiếp theo rõ ràng; ảnh có fallback; lịch trình đã lưu xem được khi mạng yếu theo phạm vi đã thiết kế | Test mất mạng giữa chuyến, không coi bản cache là thông tin trực tiếp mới cập nhật |

Đây là mục tiêu thiết kế và kiểm thử, không khẳng định mọi tiêu chí đã đạt. Tham khảo [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps) và [Flutter accessibility](https://docs.flutter.dev/ui/accessibility).

Năm tác vụ nghiên cứu: tìm quán gần ga; tạo chuyến trong ngân sách; sửa một điểm dừng; mở chỉ đường; tìm lại lịch trình đã lưu. Người quan sát không chỉ tay hướng dẫn. Ghi thời gian, tỷ lệ hoàn thành, lỗi chạm và lời người dùng mô tả; ưu tiên lỗi lặp lại ở nhiều người.

## 4. Backlog ưu tiên

### P0 — cần chốt trước khi đưa bản Play cho công chúng

| Công việc | Phụ trách đề xuất | Bằng chứng hoàn thành |
|---|---|---|
| Kiểm thử production: email/Google, OTP, reset mật khẩu, tạo/sửa/chốt/tìm lại chuyến, hết phiên và mất mạng | Flutter + BE + QA | Ma trận thiết bị và kết quả từng luồng, có regression test phù hợp với lỗi sửa |
| Thanh toán trên bản Google Play | Product + Flutter + BE | Chọn beta miễn phí hoặc Play Billing; không mặc nhiên mang luồng PayOS hiện tại lên Play |
| Xóa tài khoản và dữ liệu liên quan | BE + Flutter + web | Có đường dẫn trong app và trang web yêu cầu xóa, mô tả dữ liệu giữ lại nếu có; test bằng tài khoản riêng |
| Báo cáo nội dung AI và xử lý báo cáo | Flutter + BE + vận hành | Người dùng báo cáo ngay tại nội dung, quản trị nhận và xử lý được; có kiểm soát nội dung đầu ra |
| Privacy policy, Data safety, quyền và SDK | Product + BE + Flutter | Đối chiếu dữ liệu thực sự truyền tới API, Google và nhà cung cấp AI; không dùng bản khai chung chung |
| AAB, signing, OAuth Play, 64-bit, 16 KB, SDK và cập nhật | Flutter/release | Internal install từ Play thành công, kiểm tra trên thiết bị phù hợp và cập nhật không mất phiên/dữ liệu |
| Theo dõi lỗi, trạng thái API và sao lưu | BE + Flutter | Có cảnh báo sự cố, log không chứa mật khẩu/token, thử khôi phục backup và quy trình hotfix |

### P1 — tối ưu sau khi có nhóm dùng thử

- Bảo toàn nháp, quay lại bước đang làm sau đăng nhập; cơ chế phiên lâu dài/refresh token cần BE thiết kế và kiểm thử, không tự đổi client đơn phương.
- Tìm kiếm/chip lọc rõ ràng; “Áp dụng lịch trình mẫu”, nhân bản/xóa chuyến nếu nghiên cứu xác nhận cần.
- Góp ý ứng dụng và báo thông tin địa điểm sai; phân biệt góp ý sản phẩm, đánh giá chuyến và báo cáo AI.
- Chia sẻ lịch trình bằng liên kết mở đúng nội dung, có xử lý khi chưa cài app/chưa đăng nhập; không làm lộ chuyến riêng tư.
- Cache/lazy load ảnh, phân trang nếu dữ liệu tăng, đo trên Android tầm trung và mạng di động.
- AI có timeout hợp lý, retry không trừ lượt/tạo trùng, lịch trình chỉ dùng địa điểm đã xác minh, kiểm tra ràng buộc thời gian/ngân sách; có gợi ý đã kiểm duyệt khi AI lỗi.

### P2 — chỉ làm khi có bằng chứng nhu cầu

- Cá nhân hóa sâu, đa ngôn ngữ, nhiều thành phố, tích điểm, mạng xã hội, chat nhóm và iOS.
- Chưa ưu tiên nhiều gói phức tạp, mini-game hoặc chatbot tổng quát khi luồng chọn chuyến còn khó dùng.

## 5. Thu hút và giữ chân người dùng

**Thông điệp mẫu:** “Có 3 giờ và 200.000đ? Chọn một lịch trình quanh ga Metro.” Đây là ý tưởng nội dung; chỉ công bố lịch trình/giá khi đã kiểm tra dữ liệu thực tế.

| Thử nghiệm | Cách làm nhỏ ban đầu | Chỉ số quyết định |
|---|---|---|
| Nội dung TikTok/Reels/Facebook | Khoảng 3 nội dung/tuần trong 4 tuần: một ga, một nhu cầu, một hành trình; quay thao tác app và trải nghiệm thật | Người mở link → cài → chấp nhận lịch trình đầu tiên; không chỉ số lượt xem |
| Cộng đồng Metro/sinh viên/khám phá thành phố | Xin phép quản trị viên để tuyển người test và chia sẻ tuyến đi có ích | Tỷ lệ hoàn thành chuyến và phản hồi từ đúng đối tượng |
| Quán/cửa hàng gần ga | Thử 3–5 địa điểm, QR riêng tới lịch trình/khu vực; kiểm tra hiệu quả trước khi tăng đối tác | Người dùng có nguồn từ QR và hành động mở chỉ đường/đánh dấu đã ghé |
| Giới thiệu bạn bè | Trước hết thử chia sẻ lịch trình hữu ích; dùng mã giới thiệu đơn giản nếu cần đo | Người được giới thiệu thực sự dùng chuyến, tỷ lệ quay lại; tránh thưởng chỉ cho lượt cài |
| Trang Google Play và website | Ảnh chụp nêu rõ tìm chỗ, chọn chuyến, ngân sách, Metro; từ khóa đúng trải nghiệm và địa bàn | Tỷ lệ trang giới thiệu → cài đặt, sau đó activation của cùng nguồn |

Không tự gửi tin, đăng nhóm hoặc liên hệ đối tác trong kế hoạch này. Khi triển khai, chỉ tiếp cận đúng phạm vi nhóm đã duyệt.

Giữ chân bằng lịch trình đã lưu, gợi ý mới quanh ga yêu thích, xử lý báo sai và nhắc chuyến người dùng chủ động chọn. Mỗi tuần xem 5 phản hồi có tác động nhất, trả lời và ghi nhận lỗi đã sửa. Không gắn phần thưởng với đánh giá 5 sao.

Chưa ấn định ngân sách quảng cáo. Trước mỗi thử nghiệm trả phí phải chốt ngân sách tối đa, thời gian và điều kiện dừng. Chỉ tăng chi khi biết người dùng làm được việc chính và quay lại; không dùng số lượt tải đơn lẻ để quyết định.

## 6. Đo lường và mô hình doanh thu

**Chỉ số sản phẩm chính đề xuất:** số chuyến mỗi tuần có ít nhất một điểm được người dùng đánh dấu đã ghé. Đây là tự xác nhận, không phải bằng chứng định vị họ thực sự tới nơi.

Funnel cần đo: nguồn giới thiệu → mở app → xem địa điểm/mẫu → bắt đầu tạo → có kết quả hợp lệ → chủ động chấp nhận/lưu/chốt → mở chỉ đường → tự đánh dấu đã ghé → quay lại sử dụng chuyến khác.

Định nghĩa event trước khi cài analytics: `first_open`, `place_viewed`, `planner_started`, `itinerary_generated`, `itinerary_accepted`, `directions_opened`, `stop_marked_visited`, `feedback_submitted`. Nếu dùng SDK mới, đánh giá dữ liệu/consent và cập nhật Data safety trước khi phát hành. Không gửi email, JWT, prompt nguyên văn hoặc tọa độ chính xác vào event mặc định. Tách môi trường dev/test khỏi production.

| Chỉ số | Cách dùng |
|---|---|
| Activation | Người dùng mới chủ động chấp nhận lịch trình / người dùng mới đủ điều kiện trong cùng cohort; không tính chỉ vì BE tự lưu nháp |
| Tỷ lệ hoàn thành tác vụ | Hoàn thành không cần trợ giúp / số người thử tác vụ; theo từng nhóm tuổi và mức quen công nghệ |
| Quay lại trong tuần 4 | Người trong cohort ban đầu có hành động sản phẩm trong ngày 22–28 / cohort đó; xem cả số người tuyệt đối |
| Chất lượng | Crash/ANR, lỗi API/AI, tỷ lệ lịch trình phải sửa vì dữ liệu sai, thời gian phản hồi p50/p95 |
| Chi phí | Chi phí thu hút / người đã activation; chi phí AI và hạ tầng / chuyến được chấp nhận |

Mục tiêu thử nghiệm ban đầu do nhóm tự đặt, **không phải chuẩn ngành hay cam kết**: ít nhất 80% người nghiên cứu hoàn thành 5 tác vụ chính không cần hướng dẫn; phần lớn có thể chấp nhận chuyến đầu trong khoảng 2 phút; không có lỗi nghiêm trọng chặn luồng chính. Đo dữ liệu nền ở 2 tuần đầu rồi mới đặt mục tiêu activation/retention. Không kết luận từ một nhóm quá nhỏ hoặc so retention giữa cohort chưa đủ thời gian.

Freemium đề xuất: khám phá/Metro và một trải nghiệm lập chuyến đủ hữu ích miễn phí; Premium chỉ bán lợi ích đã có nhu cầu như hạn mức cao hơn, nhiều phương án hoặc tiện ích chuyến đi. Phỏng vấn mức sẵn sàng trả tiền trước khi chốt giá. Điểm tài trợ cần nhãn rõ ràng, không làm sai lệch tiêu chí phù hợp đã hứa. Hoa hồng dịch vụ thực là hướng về sau, cần thiết kế thanh toán và trách nhiệm riêng.

Tổng chi vận hành cần theo dõi: VPS + database/backup + tên miền + email + ảnh/băng thông + AI + hỗ trợ + marketing + phí nền tảng áp dụng. Chưa có đủ số liệu để dự báo lợi nhuận. Hạn mức AI phải được BE thực thi; khi tính doanh thu, trừ chi phí nền tảng, hoàn tiền và chi phí phục vụ thực tế.

## 7. Đưa app lên Google Play bằng tài khoản cá nhân mới

### Tài khoản và điều kiện

- Tạo Google Play Console riêng; chốt người sở hữu tài khoản và quản lý khóa của dự án. Phí đăng ký hiện là **25 USD một lần**, chủ tài khoản phải từ 18 tuổi; thực hiện xác minh theo yêu cầu Console. Chủ dự án tự làm bước danh tính và thanh toán. [Đăng ký Play Console](https://support.google.com/googleplay/android-developer/answer/6112435).
- Tài khoản cá nhân mới cần xác minh quyền truy cập **điện thoại Android thật, không root, Android 10 trở lên** qua ứng dụng Play Console. Emulator không thay thế điều kiện này. [Xác minh thiết bị](https://support.google.com/googleplay/android-developer/answer/14316361?hl=en).
- Cần closed test với **ít nhất 12 tester opted-in liên tục 14 ngày** rồi mới xin production access; đây không phải phê duyệt tự động. Nên tuyển 20–30 người để có dự phòng và phản hồi thật. Cài APK từ Drive hay test emulator không thay cho đợt closed test trên Play. [Yêu cầu testing](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

### Bản build và hồ sơ

- Build **Android App Bundle (.aab)** cho app mới; APK hiện có phục vụ cài trực tiếp. AAB cho phép Play tạo bản cài phù hợp thiết bị. [Android App Bundles](https://developer.android.com/guide/app-bundle).
- Giữ package `vn.io.localmate.mobile`, tăng versionCode mỗi lần upload; quản lý upload key và Play App Signing, sao lưu khóa ngoài máy. Khi Play ký bằng chứng thư khác, đăng ký thêm SHA-1 **app signing certificate** trên Google Cloud để test Google login từ bản cài qua Play. [App signing](https://developer.android.com/studio/publish/app-signing).
- Bản hiện tại target API 36, phù hợp mức yêu cầu cho app điện thoại mới từ 31/08/2026; tiếp tục kiểm tra yêu cầu tại lần nộp thực tế. [Target API](https://developer.android.com/google/play/requirements/target-sdk).
- Kiểm tra thư viện native 64-bit và 16 KB cả ELF/bundle lẫn runtime thích hợp. `zipalign -P 16` đạt trên APK hiện tại không đủ để tự khẳng định toàn bộ tương thích 16 KB. [16 KB page sizes](https://developer.android.com/guide/practices/page-sizes).
- Chuẩn bị icon 512 đã có, feature graphic và ảnh chụp màn hình thật, mô tả tiếng Việt, email hỗ trợ, release notes, chính sách riêng tư và website xóa tài khoản. Dùng quy cách hiện trong Play Console cho tài sản hình ảnh. [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).
- Hoàn thành App access, Data safety, content rating, target audience và khai báo quảng cáo đúng thực tế. Có tài khoản reviewer riêng và hướng dẫn truy cập các chức năng cần đăng nhập; không dùng dữ liệu riêng của khách hàng. Nội dung store phải khớp tính năng thật.

### Ba việc liên quan chính sách cần làm rõ

1. **Gói số/AI và PayOS:** repo hiện mở PayOS để mua gói tính năng trong app. Theo policy, giao dịch số trên app phân phối qua Play nhìn chung phải dùng Google Play Billing, trừ ngoại lệ/chương trình đủ điều kiện. Đề xuất bản Play beta miễn phí với hạn mức rõ ràng, không hiện luồng mua/CTA PayOS cho gói số; giữ và xử lý quyền lợi hợp lệ của tài khoản đã có. Khi bán Premium, tích hợp Play Billing và BE xác minh purchase token, đồng bộ quyền, khôi phục, hủy/gia hạn/hoàn tiền. Không xem việc mở trình duyệt thay WebView là tự đáp ứng policy. [Payments](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en).
2. **Tài khoản và dữ liệu:** app có đăng ký nên cần đường dẫn xóa tài khoản trong app và tài nguyên web để yêu cầu xóa, cùng cách xử lý dữ liệu liên quan. Privacy policy/Data safety phải khớp app, API và SDK thực tế. [Account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en), [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).
3. **Nội dung AI:** bổ sung báo cáo nội dung ngay trong app và quy trình xử lý; kiểm tra nội dung hạn chế, đặc biệt các tình huống nguy hiểm. Đánh giá phạm vi chính sách trên tính năng AI thực tế. [AI-generated content](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en).

### Trình tự phát hành

Tài khoản/xác minh → sửa các việc chặn phát hành → AAB/internal testing → closed testing đạt điều kiện → xin production access → gửi bản production để Google xét duyệt → ra mắt phạm vi nhỏ và theo dõi.

Trong closed test vẫn ghi nhận phản hồi, cải tiến và test cập nhật. Chỉ lên production sau khi Console cho phép và các luồng quan trọng có bằng chứng đạt; lập kế hoạch thời gian đệm cho vòng sửa và xét duyệt.

## 8. Nhịp làm việc và bước đầu tiên

Phân công đề xuất: một người Product/UX và tuyển người dùng; một người Flutter/release; một người BE/dữ liệu/AI; một người nội dung/growth/hỗ trợ; QA có thể kiêm nhiệm nhưng phải có người chịu trách nhiệm kết quả. Đây là vai trò cần chốt, không phải giao việc tự động cho thành viên.

Mỗi tuần có một backlog, tối đa 3 ưu tiên chính, một buổi xem số liệu/phản hồi và một bản release có ghi chú. Lỗi mất dữ liệu, bảo mật hoặc thanh toán được ưu tiên hotfix. Không mở rộng phạm vi chỉ vì có thêm ý tưởng.

Trong 7 ngày đầu:

1. Chốt định vị, người phụ trách và bảng chi phí hiện tại; lập danh sách 20–30 tester.
2. Chủ dự án tạo/xác minh Play Console cá nhân, bố trí Android thật để xác minh và QA.
3. Đo và test production trên máy thật; ghi bằng chứng cho đăng nhập, tạo/sửa/tìm lại chuyến, AI và lỗi mạng.
4. Chốt beta Play miễn phí hay bán gói bằng Play Billing; rà API cần cho xóa tài khoản và báo cáo AI.
5. Quan sát 5 người đầu tiên làm 5 tác vụ; xếp hạng các điểm vướng trước khi sửa UI.
6. Chuẩn bị dự thảo Privacy/Data safety và sự kiện đo lường tối thiểu; chỉ khai báo sau khi đối chiếu dòng dữ liệu.
7. Chốt backlog của tuần sau và tiêu chí để tạo AAB internal test. Việc này chưa tự tạo tài khoản, thu tiền hoặc phát hành.

## 9. Các giả định cần chốt dần

- Số người và thời gian thực sự có thể dành mỗi tuần; ngân sách vận hành/marketing.
- Người sở hữu Play Console và quy trình bàn giao trong nhóm.
- Nhóm tuổi/địa bàn phục vụ thực tế; ngôn ngữ ưu tiên.
- Beta miễn phí và hạn mức; chức năng nào khách hàng thực sự sẵn sàng trả tiền.
- Chủ phụ trách kiểm chứng địa điểm, xử lý phản hồi, quyền sử dụng ảnh và cập nhật dữ liệu.

Các mục trên chưa ngăn nhóm bắt đầu nghiên cứu người dùng và kiểm thử, nhưng cần được chốt trước khi cam kết chi phí hoặc ngày ra mắt.
