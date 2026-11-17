//
//  OKRimeEngineTests.mm
//  LibreKeyTests
//

#import <Foundation/Foundation.h>
#import <cassert>
#import <iostream>
#include "RimeEngine.h"

int main() {
    std::cout << "Running OKRimeEngineTests..." << std::endl;

    NSString *currentFile = [NSString stringWithUTF8String:__FILE__];
    NSString *testsDir = [currentFile stringByDeletingLastPathComponent];
    NSString *sharedDirStr = [[testsDir stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"ModernKey/Resources/rime"];
    std::string sharedDir = sharedDirStr.UTF8String;
    std::string userDir = "/tmp/librekey_test_user_rime";

    // 1. Test init
    bool inited = RimeEngine::instance().init(sharedDir, userDir);
    assert(inited && "RimeEngine initialization failed");
    std::cout << "PASS: RimeEngine init" << std::endl;

    // 2. Test typing "nihao"
    std::string commit;
    RimeUIState state;
    const char* pinyin = "nihao";
    for (int i = 0; pinyin[i]; ++i) {
        bool handled = RimeEngine::instance().processKey(pinyin[i], 0, commit, state);
        assert(handled && "Key should be handled by Rime");
    }

    assert(state.has_menu && "Menu should be visible");
    assert(state.candidates.size() > 0 && "Candidates should not be empty");
    assert(state.candidates[0].text == "你好" && "First candidate should be 你好");
    std::cout << "PASS: Typing 'nihao' generates candidate '你好'" << std::endl;

    // 3. Test space commit
    bool handled = RimeEngine::instance().processKey(' ', 0, commit, state);
    assert(handled && "Space should be handled");
    assert(commit == "你好" && "Committed text should be 你好");
    std::cout << "PASS: Space commits '你好'" << std::endl;

    // 4. Test candidate number selection: type 'z', 'h', 'o', 'n', 'g' then '2'
    commit.clear();
    const char* zhong = "zhong";
    for (int i = 0; zhong[i]; ++i) {
        RimeEngine::instance().processKey(zhong[i], 0, commit, state);
    }
    assert(state.candidates.size() >= 2 && "Should have at least 2 candidates");
    std::string expectedSecond = state.candidates[1].text;

    RimeEngine::instance().processKey('2', 0, commit, state);
    assert(commit == expectedSecond && "Selecting '2' should commit 2nd candidate");
    std::cout << "PASS: Number key selects candidate (" << commit << ")" << std::endl;

    // 5. Test Backspace
    commit.clear();
    RimeEngine::instance().processKey('b', 0, commit, state);
    RimeEngine::instance().processKey('a', 0, commit, state);
    assert(state.preedit == "ba");
    RimeEngine::instance().processKey(0xff08, 0, commit, state); // Backspace
    assert(state.preedit == "b");
    std::cout << "PASS: Backspace pops character" << std::endl;

    RimeEngine::instance().clearComposition();
    RimeEngine::instance().cleanup();

    std::cout << "ALL OKRimeEngineTests PASSED!" << std::endl;
    return 0;
}
