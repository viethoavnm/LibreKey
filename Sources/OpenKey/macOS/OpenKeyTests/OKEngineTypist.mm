//
//  OKEngineTypist.mm
//  OpenKeyTests
//

#import <Foundation/Foundation.h>
#include "OKEngineTypist.h"
#include "Engine.h"

namespace {

//Every engine setting OKTypingSettings covers, so one call cannot leak into
//the next test.
struct SavedSettings {
    int inputType, codeTable, spelling, freeMark, modern, restore, quickTelex,
        quickStart, quickEnd, zfwj, upperFirst, useMacro, autoCapsMacro, language;
    SavedSettings()
        : inputType(vInputType), codeTable(vCodeTable), spelling(vCheckSpelling), freeMark(vFreeMark),
          modern(vUseModernOrthography), restore(vRestoreIfWrongSpelling), quickTelex(vQuickTelex),
          quickStart(vQuickStartConsonant), quickEnd(vQuickEndConsonant), zfwj(vAllowConsonantZFWJ),
          upperFirst(vUpperCaseFirstChar), useMacro(vUseMacro), autoCapsMacro(vAutoCapsMacro),
          language(vLanguage) {}
    ~SavedSettings() {
        vInputType = inputType; vCodeTable = codeTable; vCheckSpelling = spelling; vFreeMark = freeMark;
        vUseModernOrthography = modern; vRestoreIfWrongSpelling = restore; vQuickTelex = quickTelex;
        vQuickStartConsonant = quickStart; vQuickEndConsonant = quickEnd; vAllowConsonantZFWJ = zfwj;
        vUpperCaseFirstChar = upperFirst; vUseMacro = useMacro; vAutoCapsMacro = autoCapsMacro;
        vLanguage = language;
        vKeyResetState();
    }
};

void applySettings(const OKTypingSettings& s) {
    vLanguage = 1;
    vInputType = s.inputType;
    vCodeTable = s.codeTable;
    vCheckSpelling = s.spelling;
    vFreeMark = s.freeMark;
    vUseModernOrthography = s.modernOrthography;
    vRestoreIfWrongSpelling = s.restoreIfWrongSpelling;
    vQuickTelex = s.quickTelex;
    vQuickStartConsonant = s.quickStartConsonant;
    vQuickEndConsonant = s.quickEndConsonant;
    vAllowConsonantZFWJ = s.allowConsonantZFWJ;
    vUpperCaseFirstChar = s.upperCaseFirstChar;
    vUseMacro = s.useMacro;
    vAutoCapsMacro = s.autoCapsMacro;
}

struct Key { Uint16 code; bool shift; int kind; };   //kind 0 key, 1 click

std::vector<Key> parseScript(const std::string& script) {
    std::vector<Key> keys;
    for (size_t i = 0; i < script.size(); i++) {
        if (script[i] == '{') {
            size_t end = script.find('}', i);
            std::string token = script.substr(i + 1, end - i - 1);
            if (token == "BS") keys.push_back({KEY_DELETE, false, 0});
            else if (token == "RET") keys.push_back({KEY_RETURN, false, 0});
            else if (token == "CLICK") keys.push_back({0, false, 1});
            i = end;
            continue;
        }
        auto it = _characterMap.find((unsigned char)script[i]);
        if (it == _characterMap.end()) continue;
        keys.push_back({(Uint16)(it->second & 0xFFFF), (it->second & CAPS_MASK) != 0, 0});
    }
    return keys;
}

//The text field plus the part of OpenKey.mm that turns the engine's answer
//into events. Kept line for line with the host so the tests exercise what
//users get.
struct Host {
    vKeyHookState* pData;
    const OKTypingSettings& settings;
    std::u16string screen;
    std::vector<Uint16> syncKey;
    size_t guard = 0;
    bool inSynth = false;
    OKTypingResult result;
    Uint16 keycode = 0;
    bool shift = false;

    Host(vKeyHookState* data, const OKTypingSettings& s) : pData(data), settings(s) {}

    //--- what the focused app does with an event
    void appBackspace() {
        if (inSynth) result.synthBackspaces++;
        if (screen.size() <= guard) result.overDeletes++;
        if (!screen.empty()) screen.pop_back();
    }
    void appInsert(const Uint16* chars, int count) {
        for (int i = 0; i < count; i++) {
            if (inSynth) result.synthChars++;
            if (chars[i] < 0x20) result.controlChars++;
            screen.push_back((char16_t)chars[i]);
        }
    }
    void appKeyEvent(Uint16 code, bool withShift) {
        if (code == KEY_DELETE) { appBackspace(); return; }
        if (code == KEY_RETURN || code == KEY_ENTER) { screen.push_back(u'\n'); return; }
        Uint16 ch = keyCodeToCharacter(code | (withShift ? CAPS_MASK : 0));
        if (ch) screen.push_back((char16_t)ch);
    }

    //--- OpenKey.mm helpers
    void insertKeyLength(Uint8 len) { syncKey.push_back(len); }

    void sendEmptyCharacter() {
        if (IS_DOUBLE_CODE(vCodeTable)) insertKeyLength(1);
        Uint16 c = 0x202F;
        appInsert(&c, 1);
    }

    void sendBackspace() {
        appBackspace();
        if (IS_DOUBLE_CODE(vCodeTable) && !syncKey.empty()) {
            if (syncKey.back() > 1) appBackspace();
            syncKey.pop_back();
        }
    }

    void sendKeyCode(Uint32 data) {
        Uint16 ch = (Uint16)data;
        if (!(data & CHAR_CODE_MASK)) {
            if (IS_DOUBLE_CODE(vCodeTable)) insertKeyLength(1);
            appKeyEvent(ch, data & CAPS_MASK);
        } else if (vCodeTable == 0) {
            appInsert(&ch, 1);
        } else if (vCodeTable == 1 || vCodeTable == 2 || vCodeTable == 4) {
            Uint16 hi = HIBYTE(ch), lo = LOBYTE(ch);
            appInsert(&lo, 1);
            if (hi > 32) { if (vCodeTable == 2) insertKeyLength(2); appInsert(&hi, 1); }
            else if (vCodeTable == 2) insertKeyLength(1);
        } else if (vCodeTable == 3) {
            Uint16 hi = ch >> 13;
            Uint16 pair[2] = {(Uint16)(ch & 0x1FFF), (Uint16)(hi > 0 ? _unicodeCompoundMark[hi - 1] : 0)};
            insertKeyLength(hi > 0 ? 2 : 1);
            appInsert(pair, hi > 0 ? 2 : 1);
        }
    }

    void sendNewCharString(bool fromMacro = false, Uint16 offset = 0) {
        Uint16 chars[20];
        int j = 0, k = 0;
        int size = fromMacro ? (int)pData->macroData.size() : pData->newCharCount;
        bool willContinue = false, willSendControlKey = false;
        if (size > 0) {
            for (k = fromMacro ? offset : pData->newCharCount - 1 - offset;
                 fromMacro ? k < (int)pData->macroData.size() : k >= 0;
                 fromMacro ? k++ : k--) {
                if (j >= 16) { willContinue = true; break; }
                Uint32 t = fromMacro ? pData->macroData[k] : pData->charData[k];
                if (t & PURE_CHARACTER_MASK) {
                    chars[j++] = (Uint16)t;
                    if (IS_DOUBLE_CODE(vCodeTable)) insertKeyLength(1);
                } else if (!(t & CHAR_CODE_MASK)) {
                    if (IS_DOUBLE_CODE(vCodeTable)) insertKeyLength(1);
                    chars[j++] = keyCodeToCharacter(t);
                } else if (vCodeTable == 0) {
                    chars[j++] = (Uint16)t;
                } else if (vCodeTable == 1 || vCodeTable == 2 || vCodeTable == 4) {
                    Uint16 hi = HIBYTE((Uint16)t);
                    chars[j++] = LOBYTE((Uint16)t);
                    if (hi > 32) { if (vCodeTable == 2) insertKeyLength(2); chars[j++] = hi; size++; }
                    else if (vCodeTable == 2) insertKeyLength(1);
                } else if (vCodeTable == 3) {
                    Uint16 hi = ((Uint16)t) >> 13;
                    insertKeyLength(hi > 0 ? 2 : 1);
                    chars[j++] = ((Uint16)t) & 0x1FFF;
                    if (hi > 0) { size++; chars[j++] = _unicodeCompoundMark[hi - 1]; }
                }
            }
        }
        if (!willContinue && (pData->code == vRestore || pData->code == vRestoreAndStartNewSession)) {
            if (keyCodeToCharacter(keycode) != 0) {
                size++;
                chars[j++] = keyCodeToCharacter(keycode | (shift ? CAPS_MASK : 0));
            } else {
                willSendControlKey = true;
            }
        }
        if (!willContinue && pData->code == vRestoreAndStartNewSession) startNewSession();
        appInsert(chars, willContinue ? 16 : size - offset);
        if (willContinue) sendNewCharString(fromMacro, fromMacro ? k : 16);
        if (willSendControlKey) sendKeyCode(keycode);
    }

    void handleMacro() {
        if (settings.emptyCharWorkaround) { sendEmptyCharacter(); pData->backspaceCount++; }
        for (int i = 0; i < pData->backspaceCount; i++) sendBackspace();
        sendNewCharString(true);
        sendKeyCode(keycode | (shift ? CAPS_MASK : 0));
    }

    //--- OpenKeyCallback, key down in Vietnamese mode
    void keyDown(Uint16 code, bool withShift) {
        keycode = code;
        shift = withShift;
        vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, code, withShift ? 1 : 0, false);
        if (pData->code == vDoNothing) {
            if (IS_DOUBLE_CODE(vCodeTable)) {
                if (pData->extCode == 1) syncKey.clear();
                else if (pData->extCode == 2) {
                    if (!syncKey.empty()) {
                        if (syncKey.back() > 1 && vCodeTable == 2) appBackspace();
                        syncKey.pop_back();
                    }
                } else if (pData->extCode == 3) insertKeyLength(1);
            }
            appKeyEvent(code, withShift);
            return;
        }
        inSynth = true;
        if (pData->code == vWillProcess || pData->code == vRestore || pData->code == vRestoreAndStartNewSession) {
            if (settings.emptyCharWorkaround && pData->extCode != 4) { sendEmptyCharacter(); pData->backspaceCount++; }
            if (pData->backspaceCount > 0 && pData->backspaceCount < MAX_BUFF)
                for (int i = 0; i < pData->backspaceCount; i++) sendBackspace();
            sendNewCharString();
        } else if (pData->code == vReplaceMaro) {
            handleMacro();
        }
        inSynth = false;
    }

    void click() {
        vKeyHandleEvent(vKeyEvent::Mouse, vKeyEventState::MouseDown, 0);
        if (IS_DOUBLE_CODE(vCodeTable)) syncKey.clear();
    }

    void type(const std::string& script) {
        for (const Key& key : parseScript(script)) {
            if (key.kind == 1) click();
            else keyDown(key.code, key.shift);
        }
    }
};

std::string visibleText(const std::u16string& screen) {
    std::u16string shown;
    for (char16_t c : screen)
        if (c != 0x202F) shown.push_back(c);
    NSString* text = [[NSString alloc] initWithCharacters:(const unichar*)shown.data() length:shown.size()];
    return std::string(text.UTF8String ?: "");
}

} //namespace

OKTypingResult OKTypeKeys(const std::string& keys,
                          const OKTypingSettings& settings,
                          const std::string& prefix) {
    SavedSettings saved;
    applySettings(settings);
    vKeyHookState* data = (vKeyHookState*)vKeyInit();
    vKeyResetState();
    for (const auto& macro : settings.macros)
        addMacro(macro.first, macro.second);

    Host host(data, settings);
    host.type(prefix);
    host.guard = host.screen.size();
    host.result = OKTypingResult();
    host.type(keys);

    for (const auto& macro : settings.macros)
        deleteMacro(macro.first);

    host.result.text = visibleText(host.screen);
    return host.result;
}
