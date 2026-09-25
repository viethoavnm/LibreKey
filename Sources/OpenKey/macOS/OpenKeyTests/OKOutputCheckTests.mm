//
//  OKOutputCheckTests.mm
//  OpenKeyTests
//
//  vCheckOutput, the check every correction passes on its way to the host:
//  no backspace past what the engine wrote, no control character.
//

#import <XCTest/XCTest.h>
#include "Engine.h"

@interface OKOutputCheckTests : XCTestCase
@end

@implementation OKOutputCheckTests

static vOutputCheckIn Correction(Byte code, Byte backspaces, const std::vector<Uint32>& chars, int onScreen, int codeTable = 0) {
    static Uint32 data[MAX_BUFF];
    memset(data, 0, sizeof(data));
    for (size_t i = 0; i < chars.size() && i < MAX_BUFF; i++)
        data[i] = chars[i];
    return {code, backspaces, (Byte)chars.size(), data, onScreen, codeTable};
}

static const Uint32 kE = 0x1EBF | CHAR_CODE_MASK;    //ế, a precomputed character
static const Uint32 kI = KEY_I;                       //i, a plain key

#pragma mark - backspaces

/// "vieet" + s: two back, "ết" in - well within the four letters on screen.
- (void)testCorrectionWithinReachIsUntouched {
    vOutputCheckOut out = vCheckOutput(Correction(vWillProcess, 2, {KEY_T, kE}, 4));
    XCTAssertEqual(out.backspaceCount, 2);
    XCTAssertEqual(out.newCharCount, 2);
    XCTAssertEqual(out.charData[0], (Uint32)KEY_T);
    XCTAssertEqual(out.charData[1], kE);
    XCTAssertFalse(out.clampedBackspaces);
    XCTAssertFalse(out.droppedCharacters);
}

- (void)testBackspacesPastWhatTheEngineWroteAreClamped {
    vOutputCheckOut out = vCheckOutput(Correction(vWillProcess, 4, {kE, kI}, 1));
    XCTAssertEqual(out.backspaceCount, 1);
    XCTAssertTrue(out.clampedBackspaces);
    //the new characters still go in
    XCTAssertEqual(out.newCharCount, 2);
    XCTAssertFalse(out.droppedCharacters);
}

- (void)testNothingOnScreenMeansNoBackspace {
    XCTAssertEqual(vCheckOutput(Correction(vRestore, 3, {kI}, 0)).backspaceCount, 0);
    XCTAssertEqual(vCheckOutput(Correction(vRestore, 3, {kI}, -2)).backspaceCount, 0);
}

- (void)testExactlyEverythingOnScreenIsAllowed {
    vOutputCheckOut out = vCheckOutput(Correction(vRestoreAndStartNewSession, 3, {kI}, 3));
    XCTAssertEqual(out.backspaceCount, 3);
    XCTAssertFalse(out.clampedBackspaces);
}

/// The host writes a macro's content from macroData, not charData.
- (void)testMacroBackspacesAreClampedAndItsCharDataIgnored {
    vOutputCheckIn in = Correction(vReplaceMaro, 5, {}, 3);
    vOutputCheckOut out = vCheckOutput(in);
    XCTAssertEqual(out.backspaceCount, 3);
    XCTAssertTrue(out.clampedBackspaces);
    XCTAssertFalse(out.droppedCharacters);
}

/// Nothing is posted for vDoNothing, so there is nothing to check.
- (void)testDoNothingPassesAsIs {
    vOutputCheckOut out = vCheckOutput(Correction(vDoNothing, 2, {kI}, 0));
    XCTAssertEqual(out.backspaceCount, 2);
    XCTAssertEqual(out.newCharCount, 1);
    XCTAssertFalse(out.clampedBackspaces);
}

#pragma mark - characters

- (void)testNulCharacterIsDroppedAndTheRestKeepTheirOrder {
    vOutputCheckOut out = vCheckOutput(Correction(vWillProcess, 3, {KEY_T, CHAR_CODE_MASK, kE}, 3));
    XCTAssertEqual(out.newCharCount, 2);
    XCTAssertEqual(out.charData[0], (Uint32)KEY_T);
    XCTAssertEqual(out.charData[1], kE);
    XCTAssertTrue(out.droppedCharacters);
    //the backspaces are not the problem
    XCTAssertEqual(out.backspaceCount, 3);
    XCTAssertFalse(out.clampedBackspaces);
}

/// A key the layout table cannot turn into a character reaches the app as NUL.
- (void)testKeyWithoutACharacterIsDropped {
    vOutputCheckOut out = vCheckOutput(Correction(vWillProcess, 1, {KEY_ESC, kI}, 1));
    XCTAssertEqual(out.newCharCount, 1);
    XCTAssertEqual(out.charData[0], kI);
    XCTAssertTrue(out.droppedCharacters);
}

- (void)testPureCharacterBelowSpaceIsDropped {
    vOutputCheckOut out = vCheckOutput(Correction(vWillProcess, 0, {PURE_CHARACTER_MASK | '\t', PURE_CHARACTER_MASK | 'a'}, 0));
    XCTAssertEqual(out.newCharCount, 1);
    XCTAssertEqual(out.charData[0], (Uint32)(PURE_CHARACTER_MASK | 'a'));
    XCTAssertTrue(out.droppedCharacters);
}

- (void)testDeleteCharacterIsDropped {
    vOutputCheckOut out = vCheckOutput(Correction(vWillProcess, 0, {PURE_CHARACTER_MASK | 0x7F}, 0));
    XCTAssertEqual(out.newCharCount, 0);
    XCTAssertTrue(out.droppedCharacters);
}

/// Unicode compound: the base letter sits in the low 13 bits, the mark above.
- (void)testCompoundCharacterIsReadByItsBaseLetter {
    Uint32 aAcute = 'a' | (1 << 13) | CHAR_CODE_MASK;
    Uint32 broken = (1 << 13) | CHAR_CODE_MASK;
    vOutputCheckOut out = vCheckOutput(Correction(vWillProcess, 0, {aAcute, broken}, 0, 3));
    XCTAssertEqual(out.newCharCount, 1);
    XCTAssertEqual(out.charData[0], aAcute);
}

/// VNI Windows and TCVN3 draw the low byte first.
- (void)testByteCodeTablesAreReadByTheirLowByte {
    Uint32 vniAAcute = 'a' | (0xF9 << 8) | CHAR_CODE_MASK;
    Uint32 broken = (0xF9 << 8) | CHAR_CODE_MASK;
    vOutputCheckOut out = vCheckOutput(Correction(vWillProcess, 0, {vniAAcute, broken}, 0, 2));
    XCTAssertEqual(out.newCharCount, 1);
    XCTAssertEqual(out.charData[0], vniAAcute);
}

/// charData holds MAX_BUFF characters; a count past it must not read beyond.
- (void)testCountPastTheBufferIsCut {
    vOutputCheckIn in = Correction(vWillProcess, 0, std::vector<Uint32>(MAX_BUFF, kI), 0);
    in.newCharCount = MAX_BUFF + 8;
    vOutputCheckOut out = vCheckOutput(in);
    XCTAssertEqual(out.newCharCount, MAX_BUFF);
    XCTAssertTrue(out.droppedCharacters);
}

@end
