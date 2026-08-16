# LibreKey

**Bộ gõ tiếng Việt cho macOS, chạy được trên máy có nhiều tài khoản người dùng.**

Phiên bản hiện tại: **1.0.0**

> ### ⚠️ Đây là bản fork của OpenKey
>
> LibreKey **không phải phần mềm viết mới**. Đây là tác phẩm phái sinh của
> **[OpenKey](https://github.com/tuyenvm/OpenKey)** — bộ gõ tiếng Việt nguồn mở
> do **Mai Vũ Tuyên** viết và phát hành theo giấy phép **GPL v3**.
>
> Gần như toàn bộ công sức thuộc về tác giả OpenKey. Fork này chỉ sửa một nhóm
> lỗi ở phần vỏ macOS để ứng dụng dùng được trên máy có nhiều tài khoản.

## Fork này lấy gì và sửa gì

| Thành phần | Nguồn gốc |
|---|---|
| `Sources/OpenKey/engine/` — toàn bộ engine tiếng Việt: bỏ dấu, kiểm tra chính tả, bảng mã, gõ tắt, chuyển mã | **Của OpenKey, giữ nguyên không sửa một dòng** |
| `Sources/OpenKey/win32/`, `Sources/OpenKey/linux/` | **Của OpenKey**, fork này không đụng tới |
| Giao diện macOS, storyboard, luồng khởi động | Của OpenKey, đã sửa phần đa người dùng |
| Vòng đời ứng dụng, event tap, login item, khoá một-instance | Sửa và viết thêm trong fork này |
| Tên, logo, bundle identifier, số phiên bản | Của fork này |

Nói cách khác: **phần khó là của OpenKey, fork này chỉ sửa phần vỏ.** Nếu LibreKey
gõ tiếng Việt tốt, đó là nhờ engine của Mai Vũ Tuyên.

Ghi công cũng hiện ngay trong ứng dụng, ở cửa sổ *Giới thiệu*, chứ không chỉ nằm
trong README này.

---

## Vì sao có fork này

Trên máy macOS có nhiều tài khoản, OpenKey chỉ chạy được cho **một người dùng duy
nhất trên toàn máy**. Ai đăng nhập trước thì được, người còn lại hoàn toàn không
mở được ứng dụng — và không có thông báo lỗi nào.

Nguyên nhân đã được xác định và đo trực tiếp: `Info.plist` của OpenKey đặt
`LSMultipleInstancesProhibited = true`. LaunchServices nhìn xuyên qua các phiên
đăng nhập, nên khi user A đang chạy OpenKey thì user B xin mở sẽ nhận
`-10829 kLSMultipleSessionsNotSupportedErr`.

Kết quả đo A/B trên cùng một máy, cùng thời điểm, cùng hai tài khoản đang đăng nhập:

| Bản | `LSMultipleInstancesProhibited` | Khi tài khoản khác đang giữ ứng dụng |
|---|---|---|
| OpenKey 2.0.5 | `true` | ❌ `-10829`, bị chặn hoàn toàn |
| LibreKey 1.0.0 | `false` | ✅ chạy song song bình thường |

## Những gì đã sửa so với OpenKey

| # | Vấn đề | Cách xử lý |
|---|---|---|
| 1 | Cổng một-instance của LaunchServices chặn toàn máy | `LSMultipleInstancesProhibited = false`, thay bằng khoá `flock()` đặt trong thư mục Application Support của từng người dùng — phân tách theo người dùng theo đúng bản chất, và không có tranh chấp check-then-act |
| 2 | Target login item bị mất khỏi project | Khôi phục target `LibreKeyHelper` và nhúng lại vào `Contents/Library/LoginItems`. Trước đó `SMLoginItemSetEnabled` luôn thất bại âm thầm nên "chạy cùng hệ thống" không hề hoạt động với bất kỳ ai build từ mã nguồn |
| 3 | Helper kích hoạt nhầm instance của người dùng khác | Dùng `openApplicationAtURL:` với `createsNewApplicationInstance = YES` |
| 4 | Thoát hẳn khi chưa được cấp quyền Accessibility | Ở lại chạy, tự dò quyền mỗi giây và khởi động tiếp khi được cấp. Không cần mở lại ứng dụng |
| 5 | Hộp thoại xin quyền có thể nằm khuất phía sau | Kích hoạt ứng dụng trước khi hiện; thêm mục "Cấp quyền cho LibreKey..." trên menu bar |
| 6 | Event tap chết vĩnh viễn sau khi chuyển tài khoản | Xử lý `kCGEventTapDisabledBy*` trong callback, lắng nghe `NSWorkspaceSessionDidResignActive` / `DidBecomeActive` |
| 7 | Rò tài nguyên mỗi lần khởi tạo lại event tap | Tách phần cấp phát một lần khỏi phần đọc cấu hình |
| 8 | Hộp thoại cập nhật làm sập ứng dụng | `OpenKeyUpdate.app` không hề được build, khiến `[NSURL fileURLWithPath:nil]` ném ngoại lệ. Đã chặn và tắt hẳn kênh cập nhật |
| 9 | Release build không link được trên Xcode mới | Nâng deployment target từ 10.10 lên 10.13 (`libarclite` đã bị Apple gỡ bỏ) |

Chi tiết từng thay đổi nằm trong lịch sử commit.

## Trạng thái kiểm thử

Nói thẳng để bạn biết chỗ nào chắc chắn, chỗ nào chưa:

**Đã kiểm chứng**
- Chạy song song khi tài khoản khác đang giữ ứng dụng (đo A/B như bảng trên), và
  quan sát được hai tài khoản cùng chạy LibreKey đồng thời trên một máy
- Đăng ký login item qua `SMAppService` — chạy được **kể cả với bản ký ad-hoc**
- Khoá một-instance cho mỗi người dùng — 11 unit test, cộng với chạy thật
- Không tự thoát khi thiếu quyền Accessibility — chạy thật
- Helper được nhúng đúng vị trí trong bundle

**Chưa kiểm chứng** — cần một bản có chữ ký hợp lệ và một máy có hai tài khoản
- Event tap phục hồi sau khi Fast User Switching
- Gõ tiếng Việt trên chính bản LibreKey

## Phát hành

| | |
|---|---|
| Phiên bản | **1.0.0** (build 1) |
| Ngày phát hành | 16/08/2026 |
| Yêu cầu | macOS 10.13 (High Sierra) trở lên |
| Kiến trúc | Universal — `arm64` (Apple Silicon) + `x86_64` (Intel) |
| Bundle ID | `vn.viethoavnm.librekey` |
| Giấy phép | GPL v3 |

Dòng *Ngày cập nhật* trong cửa sổ Giới thiệu lấy từ `__DATE__`, tức là **ngày
biên dịch** của chính bản build đó, không phải ngày phát hành ghi ở bảng trên.

---

## Build

Yêu cầu để build: **Xcode 15 trở lên** (đã kiểm tra với Xcode 26.3).

### Build nhanh bằng dòng lệnh

`DEVELOPMENT_TEAM` để trống, nên build được ngay mà chưa cần tài khoản Apple
Developer, chỉ cần thêm cờ ký ad-hoc:

```bash
cd Sources/OpenKey/macOS

# build bản Release, kết quả ra thư mục ./build
xcodebuild -project OpenKey.xcodeproj -scheme LibreKey -configuration Release \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual CODE_SIGN_ENTITLEMENTS="" build

# chạy unit test (11 test cho khoá một-instance)
xcodebuild test -project OpenKey.xcodeproj -scheme LibreKey -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual CODE_SIGN_ENTITLEMENTS=""
```

Kết quả nằm ở `build/Build/Products/Release/LibreKey.app`, đã nhúng sẵn
`LibreKeyHelper.app` trong `Contents/Library/LoginItems`.

### Đóng gói bản phát hành bằng Xcode

1. Mở `Sources/OpenKey/macOS/OpenKey.xcodeproj`.
2. Ở tab *Signing & Capabilities*, chọn team của bạn cho **cả ba target**:
   `LibreKey`, `LibreKeyHelper`, `LibreKeyTests`.
3. Chọn scheme **LibreKey**, rồi vào menu *Product → Archive*.
4. Trong cửa sổ Organizer hiện ra, bấm *Distribute App* và chọn nơi lưu.

Bước 2 không bỏ qua được nếu muốn bản dùng thật — xem phần dưới.

### Vì sao nên ký bằng chữ ký thật

Bản ký ad-hoc build được và chạy được — login item vẫn đăng ký bình thường, đã
kiểm chứng. Hạn chế thật sự là: macOS gắn quyền Accessibility theo **chữ ký**,
nên mỗi lần build lại là chữ ký đổi và bạn phải cấp quyền lại từ đầu. Ngoài ra
bản ad-hoc không mang sang máy khác được vì Gatekeeper sẽ chặn.

Thêm Apple ID vào Xcode → *Settings → Accounts* là đủ để có Personal Team miễn
phí, đủ dùng trên máy của chính bạn.

### Kiểm tra bản build

```bash
APP=build/Build/Products/Release/LibreKey.app

lipo -archs "$APP/Contents/MacOS/LibreKey"          # mong đợi: x86_64 arm64
ls "$APP/Contents/Library/LoginItems"              # mong đợi: LibreKeyHelper.app
codesign --verify --deep --strict "$APP"           # không in gì là hợp lệ
```

Thiếu `LibreKeyHelper.app` nghĩa là login item chưa được nhúng, và tính năng chạy
cùng hệ thống sẽ hỏng âm thầm — đây đúng là lỗi mà fork này sinh ra để sửa, nên
đáng kiểm tra mỗi lần đóng gói.

## Cài đặt

Kéo `LibreKey.app` vào thư mục `/Applications`.

Sau đó vào *System Settings → Privacy & Security → Accessibility* và bật LibreKey.

**Trên máy nhiều người dùng:** quyền Accessibility do macOS quản lý ở cấp hệ
thống và cần tài khoản quản trị để mở khoá. Một tài khoản thường không tự cấp
quyền cho mình được — phải nhờ quản trị viên. Khi đã được cấp cho
`/Applications/LibreKey.app` thì mọi tài khoản dùng chung bản cài đó đều nhận
được quyền.

Nếu bạn đang dùng bộ gõ khác (kể cả OpenKey gốc), hãy tắt hẳn nó. Hai bộ gõ cùng
chạy sẽ tranh nhau sửa phím và làm hỏng chữ.

## Tính năng

Kế thừa nguyên vẹn từ OpenKey.

**Kiểu gõ:** Telex, VNI, Simple Telex

**Bảng mã:** Unicode dựng sẵn, TCVN3 (ABC), VNI Windows, Unicode tổ hợp,
Vietnamese Locale CP 1258

**Tuỳ chọn:**
- Đặt dấu kiểu mới — oà, uý thay vì òa, úy
- Gõ nhanh — cc=ch, gg=gi, kk=kh, nn=ng, qq=qu, pp=ph, tt=th
- Kiểm tra chính tả và ngữ pháp
- Phục hồi phím với từ sai
- Chạy cùng hệ thống
- Biểu tượng xám trên thanh menu, hợp với Dark mode
- Đổi chế độ gõ bằng phím tắt tuỳ chọn
- Sửa lỗi autocorrect trên Chrome, Safari, Firefox, Microsoft Excel
- Sửa lỗi gạch chân của bộ gõ mặc định macOS
- Tạm tắt kiểm tra chính tả bằng Ctrl; tạm tắt bộ gõ bằng Cmd/Alt
- Cho phép f z w j làm phụ âm đầu
- Gõ tắt phụ âm đầu (f→ph, j→gi, w→qu) và phụ âm cuối (g→ng, h→nh, k→ch)
- Hiện biểu tượng trên Dock
- Viết hoa chữ cái đầu câu
- Chế độ gửi từng phím, cho ứng dụng không tương thích với cách gửi một lần
- **Gõ tắt (Macro)** — không giới hạn số ký tự, khác với giới hạn 20 ký tự của macOS
- **Chuyển chế độ thông minh** — tự nhớ ứng dụng nào dùng tiếng Việt, ứng dụng nào dùng tiếng Anh
- **Tự nhớ bảng mã theo ứng dụng** — tiện cho Photoshop, CAD với VNI/TCVN3
- **Công cụ chuyển mã** — chuyển văn bản cũ VNI, TCVN3 sang Unicode, có phím tắt

## Logo

Logo được **sinh bằng mã nguồn** thay vì lưu ảnh nhị phân, nên có thể tái tạo ở
mọi kích thước và thiết kế nằm ở nơi đọc và sửa được:

```bash
cd Sources/OpenKey/macOS
swiftc -O Tools/GenerateIcons.swift -o /tmp/genicons
/tmp/genicons ModernKey/Resources
iconutil -c icns ModernKey/Resources/Icon.iconset -o ModernKey/Resources/Icon.icns
rm -rf ModernKey/Resources/Icon.iconset
```

## Chưa hoàn thiện

- Không có kênh cập nhật tự động, và toàn bộ mã liên quan đã được gỡ bỏ. Cố ý
  như vậy: nếu trỏ về manifest của OpenKey thì LibreKey 1.0.0 sẽ thấy OpenKey
  2.0.3 là "bản mới" và rủ người dùng thay ứng dụng bằng một sản phẩm khác.
- Nút OK trong Bảng điều khiển đã được đặt làm nút mặc định (phím Return), nhưng
  chưa hiển thị màu nhấn như nút mặc định chuẩn. Chưa tìm ra nguyên nhân.
- Bảng điều khiển còn 25 checkbox rải trên 3 tab. Sắp xếp lại cho dễ dùng cần
  nhìn thấy kết quả thực tế, vì storyboard dùng toạ độ tuyệt đối chứ không có
  Auto Layout.
- Chưa có ảnh chụp màn hình. Ảnh cũ trong README của OpenKey hiển thị thương
  hiệu cũ nên đã bỏ đi.
- Mã nguồn Windows và Linux trong repo là của OpenKey gốc, fork này không đụng tới.
- Tên file và tên lớp bên trong (`OpenKeyManager`, `OpenKey.mm`, thư mục
  `ModernKey/`) vẫn giữ tên cũ. Đây chỉ là vấn đề nội bộ, người dùng không thấy.

## Giấy phép và ghi công

Phát hành theo **GNU General Public License v3** — xem [LICENSE](LICENSE).

### Tác phẩm gốc

**OpenKey** — Bộ gõ tiếng Việt nguồn mở cho macOS, Windows và Linux.

- Tác giả: **Mai Vũ Tuyên** (<maivutuyen.91@gmail.com>)
- Mã nguồn: [github.com/tuyenvm/OpenKey](https://github.com/tuyenvm/OpenKey)
- Trang chủ: [open-key.org](http://open-key.org)
- Fanpage: [facebook.com/OpenKeyVN](https://www.facebook.com/OpenKeyVN)
- Giấy phép: GPL v3

LibreKey giữ nguyên giấy phép GPL v3 của OpenKey.

### Nghĩa vụ của bạn nếu phân phối lại

GPL v3 là giấy phép copyleft. Nếu bạn phát hành lại LibreKey, hoặc phát hành bản
bạn sửa thêm từ LibreKey, thì bản đó:

1. **phải là mã nguồn mở**, kèm theo mã nguồn đầy đủ;
2. **phải tiếp tục dùng giấy phép GPL v3**;
3. **phải ghi rõ tác phẩm gốc là OpenKey của Mai Vũ Tuyên**;
4. phải nêu rõ bạn đã thay đổi những gì.

Đây là yêu cầu pháp lý của GPL v3, đồng thời cũng đúng mong muốn mà tác giả
OpenKey ghi trong README gốc.

### Lời cảm ơn

Cảm ơn Mai Vũ Tuyên đã viết và mở mã nguồn OpenKey. Toàn bộ phần khó — engine
tiếng Việt, xử lý bàn phím, các bảng mã — là công của tác giả. Nếu LibreKey có
ích cho bạn, xin hãy ủng hộ tác giả gốc tại
[tuyenvm.github.io/donate.html](https://tuyenvm.github.io/donate.html).
