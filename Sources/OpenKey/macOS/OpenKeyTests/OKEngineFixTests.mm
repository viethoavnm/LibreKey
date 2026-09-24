//
//  OKEngineFixTests.mm
//  OpenKeyTests
//
//  One group per engine bug: the keys that used to come out wrong, and the
//  neighbours that must keep working.
//

#import <XCTest/XCTest.h>
#include "OKEngineTypist.h"

#define XCTAssertTyped(keys, expected) \
    XCTAssertEqualObjects(@(OKTypeKeys(keys).text.c_str()), @(expected), @"keys: %s", keys)

@interface OKEngineFixTests : XCTestCase
@end

@implementation OKEngineFixTests

#pragma mark - A w after an automatic horn confirms it

/// Typing "ưo" then i, c, n... makes the engine horn the o by itself. A w the
/// user adds afterwards, to horn that o, used to undo both horns instead.
- (void)testWAfterAutomaticHornKeepsIt {
    XCTAssertTyped("buwoiw ", "bươi ");
    XCTAssertTyped("buwocsw ", "bước ");
    XCTAssertTyped("xuwosngw ", "xướng ");
}

/// A second w after that one is an undo again, like any doubled w.
- (void)testSecondWAfterAutomaticHornStillUndoes {
    XCTAssertTyped("buwoiww ", "buoiw ");
}

/// When the user typed both horns, a further w still undoes them.
- (void)testWAfterManualHornsStillUndoes {
    XCTAssertTyped("buwow ", "bươ ");
    XCTAssertTyped("buwoww ", "buow ");
}

- (void)testUsualHornTypingUnchanged {
    XCTAssertTyped("thuwowng ", "thương ");
    XCTAssertTyped("dduowcj ", "được ");
}

#pragma mark - A lone w that loses its horn is a w again

/// "ee" takes the horn off every vowel of the word, including an ư the w typed
/// on its own. That left a "standalone u" the host turned into U+0000.
- (void)testLoneWThatLosesItsHornSendsNoControlCharacter {
    for (const char *keys : {"were", "weeps", "woof", "sweet", "khwaja"}) {
        OKTypingResult r = OKTypeKeys(keys);
        XCTAssertEqual(r.controlChars, 0, @"keys: %s gave %s", keys, r.text.c_str());
    }
}

- (void)testEnglishWordsWithALoneWComeBackOnRestore {
    OKTypingSettings restore;
    restore.restoreIfWrongSpelling = true;
    for (const char *word : {"were ", "sweet ", "woof ", "weekend "}) {
        XCTAssertEqualObjects(@(OKTypeKeys(word, restore).text.c_str()), @(word));
    }
}

- (void)testLoneWStillMakesUHorn {
    XCTAssertTyped("w", "ư");
    XCTAssertTyped("tw", "tư");
}

#pragma mark - A lone w not drawn yet is not counted as on screen

/// The ư a lone w makes is not on screen yet when checkGrammar moves the tone
/// onto it, but it was counted in the backspaces: "irwin" typed after "pp "
/// deleted the space in front of it.
- (void)testMovingTheToneOntoALoneWDoesNotDeleteIntoThePreviousWord {
    OKTypingResult r = OKTypeKeys("irwin", OKTypingSettings(), "pp ");
    XCTAssertEqual(r.overDeletes, 0, @"gave %s", r.text.c_str());
    XCTAssertTrue([@(r.text.c_str()) hasPrefix:@"pp "], @"gave %s", r.text.c_str());
}

- (void)testToneMovesOntoALoneW {
    XCTAssertTyped("irw", "iử");
    XCTAssertTyped("twf", "từ");
}

@end
