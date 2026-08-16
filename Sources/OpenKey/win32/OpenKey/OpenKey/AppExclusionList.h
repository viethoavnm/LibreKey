/*----------------------------------------
LibreKey - Bộ gõ Tiếng Việt cho Windows
Bản fork của OpenKey (Mai Vũ Tuyên), GPL v3

Danh sách ứng dụng không gõ tiếng Việt.

Định danh là tên file thực thi, khớp với thứ mà
OpenKeyHelper::getLastAppExecuteName() trả về. Windows không phân biệt hoa
thường ở tên file nên mọi phép so sánh ở đây cũng vậy.

Phần logic thuần tách khỏi UI và registry để về sau còn kiểm thử được.
------------------------------------------*/
#pragma once

#include <string>
#include <vector>

using namespace std;

//Khoá registry chứa danh sách.
#define APP_EXCLUSION_REG_KEY _T("vExcludedApps")

class AppExclusionList {
public:
	//Đọc danh sách đã lưu. Không bao giờ ném ngoại lệ - dữ liệu hỏng đọc thành rỗng.
	static vector<string> load();
	static void save(const vector<string>& apps);

	//Câu hỏi duy nhất mà bộ hook bàn phím cần trả lời.
	static bool contains(const vector<string>& apps, const string& exeName);

	//Trả về nguyên danh sách cũ nếu tên rỗng hoặc đã có sẵn.
	static vector<string> add(const vector<string>& apps, const string& exeName);

	//Bỏ qua nếu index nằm ngoài phạm vi.
	static vector<string> remove(const vector<string>& apps, const int& index);

	//"C:\\Program Files\\App\\app.exe" -> "app.exe"
	static string exeNameFromPath(const string& fullPath);

	//Lưu dạng các dòng ngăn nhau bằng '\n'.
	static string serialize(const vector<string>& apps);
	static vector<string> deserialize(const string& blob);

	static string toLower(const string& s);
};
