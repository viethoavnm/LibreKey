//
//  OKEngineTypistTests.mm
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#include "OKEngineTypist.h"

#define XCTAssertText(result, expected) \
    XCTAssertEqualObjects(@((result).text.c_str()), @(expected))

@interface OKEngineTypistTests : XCTestCase
@end

@implementation OKEngineTypistTests

- (void)testPlainLettersPassThrough {
    XCTAssertText(OKTypeKeys("abc"), "abc");
}

- (void)testTelexCircumflex {
    XCTAssertText(OKTypeKeys("aa"), "â");
}

- (void)testTelexWordWithTone {
    XCTAssertText(OKTypeKeys("vieetj"), "việt");
}

- (void)testShiftedLetterStaysUpperCase {
    XCTAssertText(OKTypeKeys("Vieetj"), "Việt");
}

- (void)testBackspaceToken {
    XCTAssertText(OKTypeKeys("abc{BS}"), "ab");
}

- (void)testPrefixIsKeptAndNotCountedAsOverDelete {
    OKTypingResult r = OKTypeKeys("aa", OKTypingSettings(), "pp ");
    XCTAssertText(r, "pp â");
    XCTAssertEqual(r.overDeletes, 0);
}

/// "aa" is one backspace over the a, then â.
- (void)testCountsWhatTheHostSends {
    OKTypingResult r = OKTypeKeys("aa");
    XCTAssertEqual(r.synthBackspaces, 1);
    XCTAssertEqual(r.synthChars, 1);
    XCTAssertEqual(r.controlChars, 0);
}

/// The empty character costs one more character and one more backspace, and
/// never shows in the text.
- (void)testEmptyCharacterWorkaroundIsCountedButNotShown {
    OKTypingSettings s;
    s.emptyCharWorkaround = true;
    OKTypingResult r = OKTypeKeys("aa", s);
    XCTAssertText(r, "â");
    XCTAssertEqual(r.synthBackspaces, 2);
    XCTAssertEqual(r.synthChars, 2);
}

- (void)testMacroExpandsOnSpace {
    OKTypingSettings s;
    s.macros = {{"ko", "không"}};
    XCTAssertText(OKTypeKeys("ko ", s), "không ");
}

/// A macro registered for one call must not leak into the next.
- (void)testMacrosDoNotLeakBetweenCalls {
    OKTypingSettings s;
    s.macros = {{"ko", "không"}};
    OKTypeKeys("ko ", s);
    XCTAssertText(OKTypeKeys("ko "), "ko ");
}

- (void)testVNI {
    OKTypingSettings s;
    s.inputType = 1;
    XCTAssertText(OKTypeKeys("a6", s), "â");
}

/// Each call starts from a fresh engine: an unfinished word must not carry over.
- (void)testCallsDoNotShareState {
    OKTypeKeys("a");
    XCTAssertText(OKTypeKeys("a"), "a");
}

@end
