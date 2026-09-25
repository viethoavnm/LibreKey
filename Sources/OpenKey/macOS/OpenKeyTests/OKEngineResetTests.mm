//
//  OKEngineResetTests.mm
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#include "Engine.h"

@interface OKEngineResetTests : XCTestCase
@end

@implementation OKEngineResetTests {
    vKeyHookState *_state;
}

- (void)setUp {
    [super setUp];
    _state = (vKeyHookState *)vKeyInit();
    vKeyResetState();
}

- (void)tearDown {
    vKeyResetState();
    [super tearDown];
}

- (void)press:(Uint16)key {
    vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, key);
}

/// Without a reset, a third a would undo the circumflex of "aa". After one, it
/// is the first letter of a new word.
- (void)testResetStartsAFreshWord {
    [self press:KEY_A];
    [self press:KEY_A];
    XCTAssertEqual(_state->code, vWillProcess);

    vKeyResetState();
    [self press:KEY_A];

    XCTAssertEqual(_state->code, vDoNothing);
    XCTAssertEqual(_state->backspaceCount, 0);
    XCTAssertEqual(_state->newCharCount, 0);
}

/// Backspacing over a space normally brings the previous word back for editing;
/// after a reset there is no previous word left to bring back.
- (void)testResetForgetsThePreviousWord {
    [self press:KEY_A];
    [self press:KEY_SPACE];
    vKeyResetState();
    [self press:KEY_DELETE];

    [self press:KEY_A];
    XCTAssertEqual(_state->code, vDoNothing, @"a lone a must not merge into a forgotten word");
}

- (void)testResetClearsTheMacroKey {
    [self press:KEY_B];
    [self press:KEY_T];
    XCTAssertEqual(_state->macroKey.size(), 2u);

    vKeyResetState();

    XCTAssertEqual(_state->macroKey.size(), 0u);
    XCTAssertEqual(_state->macroData.size(), 0u);
}

- (void)testResetLeavesSettingsAlone {
    int spelling = vCheckSpelling;
    int inputType = vInputType;
    vKeyResetState();
    XCTAssertEqual(vCheckSpelling, spelling);
    XCTAssertEqual(vInputType, inputType);
}

@end
