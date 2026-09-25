# LibreKey — Nhật ký thay đổi

LibreKey là bản fork của [OpenKey](https://github.com/tuyenvm/OpenKey) do Mai Vũ
Tuyên viết, phát hành theo giấy phép GPL v3. Nhật ký thay đổi của OpenKey nằm ở
kho gốc; file này chỉ ghi những gì LibreKey khác đi.

## Chưa phát hành

- **Cài bằng Homebrew trên macOS.** Cask nằm ở tap riêng
  [viethoavnm/homebrew-librekey](https://github.com/viethoavnm/homebrew-librekey);
  `brew install --cask librekey` là đủ, nâng cấp về sau bằng `brew upgrade`.
  Homebrew Cask chính thức chưa nhận vì kho chưa đủ ngưỡng phổ biến (75 sao, hoặc
  30 fork, hoặc 30 watcher). Cask được workflow `homebrew-bump.yml` cập nhật tự
  động mỗi khi có release mới, nên không có bước sửa `sha256` bằng tay. Ứng dụng
  không đổi một dòng nào.
- **Sửa lỗi chữ nhảy loạn khi gõ trong terminal, nhất là qua SSH lúc mạng kém**
  (macOS). Trong terminal, người sửa chữ không phải terminal mà là shell hay
  chương trình ở đầu bên kia; byte tới đó bị mạng cắt và gộp tuỳ ý, nên mọi
  thao tác thừa đều là thêm một chỗ để lệch nhịp với engine. Có hai thao tác
  thừa như vậy:
  - *Ký tự rỗng của "sửa lỗi gợi ý".* Tuỳ chọn này bật sẵn và gửi U+202F kèm một
    backspace thừa trước **mỗi** lần bỏ dấu, ở mọi ứng dụng trừ Spotlight và
    Chromium — kể cả terminal, nơi không có ô gợi ý nào để lách. Chỗ nào làm rơi
    ký tự rỗng (iTerm2, xem OpenKey #95) thì backspace thừa ăn mất một chữ thật.
    Nay terminal không nhận ký tự rỗng nữa, bất kể tuỳ chọn bật hay tắt.
  - *Cả cụm chữ mới trong một event.* Terminal dựng trên xterm.js (Hyper, Tabby,
    Termius) coi event nhiều ký tự mà không có composition là paste và bỏ đi,
    trong khi các backspace trước nó vẫn tới shell. Dòng lệnh tụt lại sau engine
    và từ đó mỗi lần sửa lại xoá nhầm chữ. Nay terminal nhận mỗi ký tự một event.

  - *Phím thật vượt lên trước phần sửa.* Terminal (hay pty, hay xterm.js) có thể
    cho một phím thật đi trước các event tổng hợp còn trong hàng đợi. Nay khi
    một từ đã có lần sửa, LibreKey tự gửi lại các phím tiếp theo của từ đó ngay
    sau phần sửa (`OKLockstep`), cho tới hết từ và thêm 0,15 giây.
  - *Event tái sử dụng, timestamp cũ.* Mỗi event gửi đi giờ là event mới, có
    timestamp tăng dần và được đánh dấu là của LibreKey.

  Nhận diện theo bundle id: Terminal, iTerm2, Warp, kitty, Alacritty, WezTerm,
  Ghostty, Hyper, Tabby, Termius. **Terminal trong VS Code** (cùng VS Code
  Insiders, VSCodium, Cursor, Windsurf) được nhận diện qua Accessibility: ô đang
  focus là terminal khi mô tả của nó bắt đầu bằng "Terminal", còn khung soạn
  thảo vẫn đi đường cũ. Khi Spotlight đang mở phía trên terminal thì phím vào
  Spotlight nên vẫn đi đường cũ. Ứng dụng khác không đổi gì. Logic nằm trong
  `OKTerminalTyping` và `OKLockstep`, đều có unit test.

  Không sửa được từ phía bộ gõ: chương trình ở remote đọc mỗi lần một chunk và
  không xử lý backspace nằm lẫn trong chunk đó (các TUI dựng trên Ink, ví dụ
  Claude Code bản cũ). Mạng kém khiến chunk bị gộp nhiều hơn, nên lỗi này nằm
  ở chương trình đó chứ không ở LibreKey.
- **Engine gõ đúng hơn.** Đo trên 30.337 cặp Telex tiếng Việt, tỉ lệ đúng tăng từ
  96,33% lên 99,76%. Trên bảng đối chiếu của UniKey (1.307 dòng) tăng từ 1.264 lên
  1.302 dòng. Trên 97.592 từ tiếng Anh khi bật tự khôi phục, tỉ lệ tăng từ 93,93% lên
  97,43%. Các sửa đổi chính:
  - `w` xác nhận móc mà engine đã tự thêm, thay vì huỷ nó; `w` thứ hai huỷ móc ở
    nguyên âm thứ hai (#216); `huơ`, `khuơ`, `uở` gõ theo UniKey (#229).
  - Macro: khoá macro dựng lại khi xoá lùi vào một từ (#242), cập nhật theo đúng
    chữ host viết (#313), và macro nằm trong dấu câu vẫn được bung (#279).
  - Xoá lùi kết thúc thao tác huỷ khi tắt kiểm tra chính tả (#145). Phụ âm cuối
    `k` nhận dấu khi tắt kiểm tra chính tả, cho địa danh như Đắk Lắk (#134).
  - Viết hoa đầu câu sau `!` và `?` nhưng không sau `>`, và bỏ khi xoá lùi (#285).
  - Tự khôi phục từ sai giờ cũng khôi phục khi phím gõ đôi đã huỷ dấu và bị
    nuốt mất: `official` không còn ra `oficial`, `necessary` không còn ra
    `necesary` (#141). Engine giữ thêm một log phím gốc cho mỗi từ. Khôi phục
    chỉ dùng phím của chính từ đó: trước đây xoá lùi vào một từ cũ rồi gõ sai
    có thể xoá mất cả từ.
  - Công cụ chuyển mã giữ nguyên kiểu chữ khi bỏ dấu (#297).
  - Hết các trường hợp engine gửi ký tự U+0000.
- **Engine không bao giờ xoá quá phần chính nó viết.** Engine tự đếm những gì nó
  đã cho qua và đã viết trước con trỏ, theo từng từ, và quên hết sau click,
  Return, phím mũi tên hay phím tắt. Mọi lần sửa đều được kiểm tra trước khi tới
  host (`vCheckOutput`): số backspace không vượt quá phần đó, và không có ký tự
  điều khiển. Nếu một lỗi logic khác có đòi xoá thêm thì thiệt hại cũng chỉ nằm
  trong từ đang gõ.
- **Sửa dấu cách sau backspace với bảng mã VNI và Unicode tổ hợp** (macOS và
  Windows). Dấu cách mang theo mã "xoá" của phím trước đó, nên host tưởng đó là
  một lần xoá nữa và xoá mất nửa chữ hai byte (VNI `ấ` = `a` + byte dấu).
- **Unicode tổ hợp trong Chrome, Brave, Edge** (#182). Chromium chọn cả chữ và
  dấu tổ hợp một lượt nhưng xoá từng code point, nên `conff` ra `coonf`. Nay mỗi
  ứng dụng được hỏi riêng cần bao nhiêu lần Backspace và Shift+Left
  (`OKCompoundDeletion`).
- **Ít ký tự rỗng hơn.** U+202F của "sửa lỗi gợi ý" chỉ còn được gửi khi có thể
  có gợi ý bôi đen sau con trỏ. Trong ô nhiều dòng (TextEdit, Notes, Mail...) mà
  Accessibility báo không có gì được chọn thì không gửi, nên không còn thừa một
  bước trong lịch sử hoàn tác. Ô một dòng và ứng dụng không đọc được qua
  Accessibility vẫn như cũ (`OKAutocompleteGuard`).
- **Bàn phím AZERTY, QWERTZ, Dvorak** khi chưa bật "tương thích bố cục". Engine
  đặt tên phím theo vị trí trên bàn phím US, nên Telex `w` trên AZERTY bị đọc
  thành `z`, còn trên Dvorak gần như chữ nào cũng sai. Nay LibreKey đọc layout
  đang chọn và đưa cho engine đúng chữ in trên phím. Chỉ áp dụng cho chữ cái và
  dấu câu không cần Shift của bàn US; phím gõ ra `é`, `&`, `ü` vẫn giữ như trước.
  Phím tắt đã ghi theo vị trí không bị ảnh hưởng (`OKLayoutRemap`).
- **Bớt việc trên mỗi phím** (macOS). Danh sách cửa sổ để dò Spotlight chỉ còn
  được đọc một lần cho mỗi lần Spotlight mở, thay vì tới ba lần mỗi lần sửa.
  Ngôn ngữ của nguồn nhập được đọc khi nó đổi, thay vì ở mỗi lần nhấn và nhả
  phím; việc này cũng sửa một lần `CFRelease` thừa và một chỗ rò bộ nhớ. Event
  tap không còn nhận sự kiện kéo chuột.
- **Windows: Shift + số** luôn được đưa vào engine như phím có Shift, dù có bật
  Caps Lock hay không (#290).
- **211 unit test** (trước là 50), gồm một bộ gõ mô phỏng dùng đúng engine và
  logic gửi phím của host, cùng bảng đối chiếu UniKey (GPL-2+) có sẵn trong kho.
  Hai tập corpus lớn (cặp Telex và từ tiếng Anh) nằm ngoài kho. Muốn chạy thì trỏ
  `TEST_RUNNER_LIBREKEY_CORPUS_DIR` tới thư mục chứa chúng.

## 1.2.0 — 16/08/2026

Đưa tính năng Loại trừ ứng dụng sang bản Windows.

### Tính năng mới

- **Loại trừ ứng dụng trên Windows.** Tab thứ tư, nằm giữa "Hệ thống" và "Thông
  tin", giống vị trí ở bản macOS. Danh sách tên file thực thi, kèm nút *Thêm ứng
  dụng...* mở hộp thoại chọn `.exe` và nút *Bỏ khỏi danh sách* (chỉ bật khi có
  dòng được chọn). Trong ứng dụng bị loại trừ, phím đi thẳng qua — engine không
  đụng vào; riêng phím tắt chuyển ngôn ngữ và chuyển mã vẫn dùng được vì đó là
  phím tắt toàn cục.

  Định danh là **tên file thực thi**, khớp với thứ mà `getLastAppExecuteName()`
  trả về, và mọi phép so sánh đều bỏ qua hoa thường vì tên file Windows vốn không
  phân biệt. Danh sách lưu trong registry cùng chỗ với các thiết lập khác, và mỗi
  lần sửa là cache của bộ hook được nạp lại ngay, không cần khởi động lại.

### Sửa lỗi

- Thiếu `<commdlg.h>` khiến hộp thoại chọn file không biên dịch được.
- Thông báo khởi động lại với quyền Admin còn sót tên OpenKey.

### Chưa kiểm chứng

Giống bản 1.1.0: bản Windows build sạch trên CI và các chuỗi đã được kiểm tra
trực tiếp trong binary, nhưng **chưa ai chạy thử trên máy Windows thật**. Ngoài
ra `AppExclusionList` bên win32 **chưa có unit test** — win32 không có test
target, khác với bản macOS nơi logic tương đương có 16 test. Phần logic thuần đã
được tách khỏi UI và registry để sau này thêm test được.

## 1.1.0 — 16/08/2026

Bổ sung bản Windows. Số phiên bản đồng nhất giữa hai nền tảng.

### Bản Windows

Mã nguồn `win32/` trước đây giữ nguyên của OpenKey, fork không đụng tới. Bản này
đưa nó về đúng thương hiệu LibreKey và port các bản vá đã làm ở macOS.

- **Gỡ bỏ hoàn toàn hệ thống cập nhật tự động.** Cùng lý do như bản macOS:
  `OpenKeyManager::checkUpdate` đọc manifest ở
  `raw.githubusercontent.com/tuyenvm/OpenKey/master/version.json`, nên một bản
  LibreKey sẽ báo người dùng rằng có "OpenKey mới" rồi rủ họ thay ứng dụng bằng
  một sản phẩm khác. Gỡ project `OpenKeyUpdate`, hai hàm `checkUpdate`, hai
  handler nút bấm, tuỳ chọn `vCheckNewVersion` và các control liên quan.
- **Đổi ba định danh hệ thống**, không phải để cho đẹp mà vì nếu giữ nguyên thì
  LibreKey và OpenKey sẽ chặn lẫn nhau không cho chạy — đúng loại lỗi mà fork này
  sinh ra để sửa: window class `APP_CLASS` mà `FindWindow` dùng để dò instance
  đang chạy, khoá registry `SOFTWARE\TuyenMai\OpenKey` → `SOFTWARE\LibreKey`, và
  tên giá trị run-at-startup.
- **Sửa lỗi đúp từ trên Chromium** — port từ macOS: luôn bật thay vì ô tích beta
  mặc định tắt; nhận thêm Chromium, Vivaldi, Opera/GX, Cốc Cốc, Arc và khớp không
  phân biệt hoa thường (tên file Windows vốn không phân biệt); thêm guard
  `backspaceCount > 0` mà bản Windows thiếu — không có nó, khi không cần xoá gì
  thì Shift+Left vẫn bôi đen một ký tự rồi bị chuỗi mới ghi đè, tức là xoá mất
  một ký tự lẽ ra không được đụng tới.
- **Hết lệch `_syncKey`** khi gõ VNI / Unicode tổ hợp, và thêm guard vector rỗng.
- **Build tự động bằng GitHub Actions**, x86 và x64, có bước kiểm tra binary đúng
  tên, và tự đính kèm vào release khi push tag `v*`.

### Ghi công

Ghi công OpenKey và Mai Vũ Tuyên giữ nguyên và bổ sung ở bản Windows: header bản
quyền trong từng file mã nguồn không đụng tới, hộp thoại Giới thiệu và tab Thông
tin ghi rõ đây là tác phẩm phái sinh theo GPL v3, trường `LegalCopyright` ghi cả
hai bên, và liên kết fanpage OpenKey đổi thành liên kết "Bản gốc" trỏ về kho mã
nguồn gốc.

### Chưa kiểm chứng

Bản Windows build sạch trên CI và các chuỗi thương hiệu đã được kiểm tra trực
tiếp trong binary, nhưng **chưa ai chạy thử nó trên một máy Windows thật**.

## 1.0.0 — 16/08/2026

Bản đầu tiên. Tách ra từ OpenKey 2.0.4. Chỉ có macOS.

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
