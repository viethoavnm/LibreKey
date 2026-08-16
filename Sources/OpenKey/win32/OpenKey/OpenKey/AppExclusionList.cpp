/*----------------------------------------
LibreKey - Bộ gõ Tiếng Việt cho Windows
Bản fork của OpenKey (Mai Vũ Tuyên), GPL v3
------------------------------------------*/
#include "stdafx.h"
#include "AppExclusionList.h"

#include <algorithm>
#include <cctype>

string AppExclusionList::toLower(const string& s) {
	string out = s;
	std::transform(out.begin(), out.end(), out.begin(),
		[](unsigned char c) { return (char)std::tolower(c); });
	return out;
}

string AppExclusionList::serialize(const vector<string>& apps) {
	string blob;
	for (size_t i = 0; i < apps.size(); i++) {
		if (i > 0)
			blob += '\n';
		blob += apps[i];
	}
	return blob;
}

vector<string> AppExclusionList::deserialize(const string& blob) {
	vector<string> apps;
	size_t start = 0;
	while (start <= blob.size()) {
		size_t end = blob.find('\n', start);
		if (end == string::npos)
			end = blob.size();
		string line = blob.substr(start, end - start);
		//Bỏ '\r' nếu dữ liệu cũ dùng CRLF.
		while (!line.empty() && (line.back() == '\r' || line.back() == ' '))
			line.pop_back();
		if (!line.empty())
			apps.push_back(line);
		if (end == blob.size())
			break;
		start = end + 1;
	}
	return apps;
}

vector<string> AppExclusionList::load() {
	DWORD size = 0;
	BYTE* data = OpenKeyHelper::getRegBinary(APP_EXCLUSION_REG_KEY, size);
	if (data == NULL || size == 0)
		return vector<string>();
	return deserialize(string((const char*)data, size));
}

void AppExclusionList::save(const vector<string>& apps) {
	string blob = serialize(apps);
	OpenKeyHelper::setRegBinary(APP_EXCLUSION_REG_KEY, (const BYTE*)blob.data(), (int)blob.size());
}

bool AppExclusionList::contains(const vector<string>& apps, const string& exeName) {
	if (exeName.empty())
		return false;
	string wanted = toLower(exeName);
	for (size_t i = 0; i < apps.size(); i++) {
		if (toLower(apps[i]) == wanted)
			return true;
	}
	return false;
}

vector<string> AppExclusionList::add(const vector<string>& apps, const string& exeName) {
	if (exeName.empty() || contains(apps, exeName))
		return apps;
	vector<string> updated = apps;
	updated.push_back(exeName);
	return updated;
}

vector<string> AppExclusionList::remove(const vector<string>& apps, const int& index) {
	if (index < 0 || index >= (int)apps.size())
		return apps;
	vector<string> updated = apps;
	updated.erase(updated.begin() + index);
	return updated;
}

string AppExclusionList::exeNameFromPath(const string& fullPath) {
	size_t pos = fullPath.find_last_of("\\/");
	return pos == string::npos ? fullPath : fullPath.substr(pos + 1);
}
