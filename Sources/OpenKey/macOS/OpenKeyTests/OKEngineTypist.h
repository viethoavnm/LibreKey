//
//  OKEngineTypist.h
//  OpenKeyTests
//
//  Types a key script into the real engine through a copy of what the macOS
//  host does with the engine's answer (OpenKey.mm: backspaces, the replacement
//  string, macros, the empty character) and a simulated text field, so a test
//  can say "these keys give this text".
//

#ifndef OKEngineTypist_h
#define OKEngineTypist_h

#include <string>
#include <utility>
#include <vector>

//Input: the settings the keys are typed with. Defaults are a fresh install.
struct OKTypingSettings {
    int inputType = 0;              //vTelex, vVNI, vSimpleTelex1, vSimpleTelex2
    int codeTable = 0;              //0 Unicode, 3 Unicode compound, ...
    bool spelling = true;
    bool freeMark = false;
    bool modernOrthography = false;
    bool restoreIfWrongSpelling = false;
    bool quickTelex = false;
    bool quickStartConsonant = false;
    bool quickEndConsonant = false;
    bool allowConsonantZFWJ = false;
    bool upperCaseFirstChar = false;
    bool useMacro = true;
    bool autoCapsMacro = false;
    //Whether the host sends U+202F before corrections (on for ordinary apps,
    //off in terminals).
    bool emptyCharWorkaround = false;
    std::vector<std::pair<std::string, std::string>> macros;   //key text -> content
};

//Output: what ended up in the text field, and what it took to get there.
struct OKTypingResult {
    std::string text;               //UTF-8; U+202F left by the workaround is dropped
    int overDeletes = 0;            //backspaces that reached text typed before the script
    int controlChars = 0;           //characters below U+0020 the host was told to insert
    int synthBackspaces = 0;        //backspaces the host sent on its own
    int synthChars = 0;             //characters the host inserted on its own
};

//Types `keys` after `prefix` (whose text must survive: deleting into it counts
//as an over-delete). Plain characters are typed on a US layout, upper case and
//symbols with Shift. Tokens: {BS} backspace, {RET} return, {CLICK} mouse click.
OKTypingResult OKTypeKeys(const std::string& keys,
                          const OKTypingSettings& settings = OKTypingSettings(),
                          const std::string& prefix = "");

#endif
