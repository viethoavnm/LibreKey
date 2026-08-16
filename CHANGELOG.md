# LibreKey — Nhật ký thay đổi

LibreKey là bản fork của [OpenKey](https://github.com/tuyenvm/OpenKey) do Mai Vũ
Tuyên viết, phát hành theo giấy phép GPL v3. Nhật ký thay đổi của OpenKey nằm ở
kho gốc; file này chỉ ghi những gì LibreKey khác đi.

## 1.0.0 — 16/08/2026

Bản đầu tiên. Tách ra từ OpenKey 2.0.4.

### Sửa lỗi đa người dùng

Trên máy macOS có nhiều tài khoản, OpenKey chỉ chạy được cho **một người dùng
duy nhất trên toàn máy**. Ai đăng nhập trước thì được, người còn lại không mở
được ứng dụng và không nhận thông báo lỗi nào.

- **Bỏ cổng một-instance của LaunchServices.** `LSMultipleInstancesProhibited`
  chuyển sang `false`. Cổng này áp cho toàn máy chứ không theo từng phiên đăng
  nhập, nên khi tài khoản khác đang giữ ứng dụng thì LaunchServices trả về
  `-10829 kLSMultipleSessionsNotSupportedErr`. Thay bằng khoá `flock()` đặt trong
  thư mục Application Support của từng người dùng — phân tách theo người dùng
  theo đúng bản chất, và không có tranh chấp check-then-act.
- **Khôi phục target login item.** Target `OpenKeyHelper` đã bị xoá khỏi project
  file, nên `SMLoginItemSetEnabled` luôn thất bại âm thầm và "chạy cùng hệ thống"
  không hoạt động với bất kỳ ai build từ mã nguồn.
- **Helper luôn tạo instance mới.** `launchApplication:` kích hoạt instance đang
  có, mà "đang có" có thể là của tài khoản khác — LaunchServices nhìn xuyên phiên
  đăng nhập. Đổi sang `createsNewApplicationInstance = YES`.
- **Sống sót qua Fast User Switching.** Xử lý `kCGEventTapDisabledBy*` trong
  callback và lắng nghe `NSWorkspaceSessionDidResignActive` / `DidBecomeActive`.
  Trước đây event tap chết là chết hẳn.

### Sửa lỗi khác

- **Không tự thoát khi thiếu quyền Accessibility.** Trước đây ứng dụng gọi
  `[NSApp terminate:0]` ngay cả khi người dùng bấm "Cấp quyền", nên quyền được
  cấp cho một ứng dụng đã biến mất. Nay ứng dụng ở lại, tự dò quyền mỗi giây và
  khởi động tiếp.
- **Hộp thoại xin quyền không còn bị khuất.** Ứng dụng là `LSUIElement` nên không
  tự nổi lên; thiếu `activateIgnoringOtherApps:` thì hộp thoại có thể nằm sau cửa
  sổ khác mà không có icon Dock để bấm.
- **Hết rò tài nguyên khi khởi tạo lại event tap.** Tách phần cấp phát một lần
  khỏi phần đọc cấu hình.
- **Hộp thoại cập nhật không còn làm sập ứng dụng.** `OpenKeyUpdate.app` chưa bao
  giờ được build, khiến `[NSURL fileURLWithPath:nil]` ném ngoại lệ.
- **Release build lại link được.** Nâng deployment target 10.10 → 10.13;
  `libarclite` đã bị Apple gỡ khỏi Xcode 14.3 trở đi.
- **Nhận đúng các trình duyệt nhân Chromium.** Cách sửa lỗi đúp từ trước đây dò
  tên bundle bằng phép so khớp tuyệt đối trên một danh sách vốn dùng cho việc
  khác, nên Chromium, Chrome Beta/Dev/Canary, Vivaldi, Opera, Cốc Cốc và Arc đều
  lọt lưới. Nay dò theo tiền tố trên danh sách riêng.
- **Hết lệch `_syncKey` khi gõ VNI/Unicode tổ hợp trên Chromium.** Vòng lặp
  backspace đếm thừa một đơn vị so với số ký tự thực sự bị xoá; với
  `backspaceCount` từ 2 trở lên thì đọc `back()` trên vector rỗng.

### Tính năng mới

- **Loại trừ ứng dụng.** Tab mới nằm giữa "Hệ thống" và "Thông tin", liệt kê
  những ứng dụng LibreKey không gõ tiếng Việt. Bấm **+** để chọn ứng dụng (chọn
  được nhiều cùng lúc), bấm **−** để bỏ dòng đang chọn. Trong ứng dụng bị loại
  trừ, phím đi thẳng qua — engine không đụng vào; riêng phím tắt chuyển ngôn ngữ
  và chuyển mã vẫn dùng được vì đó là phím tắt toàn cục. Danh sách lưu theo từng
  tài khoản macOS, khớp với bản chất đa người dùng của bản fork này.

### Thay đổi

- Đổi tên thành **LibreKey**, bundle identifier `vn.viethoavnm.librekey`.
- Logo mới: khung bo tròn màu hồng sen với chữ **lk**. Biểu tượng trên thanh menu
  hiển thị ngôn ngữ đang dùng — **V** hoặc **E**.
- Phím chuyển mặc định: **Ctrl + Shift** (trước là Option + Z).
- **Gỡ bỏ hoàn toàn tính năng cập nhật tự động.** Bản fork không có kênh cập
  nhật riêng, và trỏ về manifest của OpenKey thì sẽ rủ người dùng thay ứng dụng
  bằng một sản phẩm khác.
- **"Sửa lỗi trên Chromium" luôn bật, bỏ ô tích.** Tính năng này gắn nhãn beta và
  mặc định tắt từ OpenKey. Nay nó chạy thẳng cho mọi trình duyệt nhân Chromium,
  vẫn nằm dưới tuỳ chọn "Sửa lỗi gợi ý" như trước.
- Bảng điều khiển: khung dạng card bỏ viền, thanh tab dùng kiểu `recessed` chuẩn
  macOS, nút bấm bỏ ảnh icon.
- Cửa sổ Giới thiệu: bỏ liên kết về dự án gốc, thêm tác giả và phần ghi công GPL.

### Kỹ thuật

- Thêm target unit test (`LibreKeyTests`) — kho gốc không có test nào. Hiện có
  38 test.
- Logo được sinh bằng mã nguồn (`Tools/GenerateIcons.swift`) thay vì lưu ảnh nhị
  phân, nên tái tạo được ở mọi kích thước.
