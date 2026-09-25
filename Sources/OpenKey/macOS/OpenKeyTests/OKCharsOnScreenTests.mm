//
//  OKCharsOnScreenTests.mm
//  OpenKeyTests
//
//  vKeyCharsOnScreen: how far back a correction may reach, counted from what
//  the engine let through and wrote, not from what it thinks the word is.
//

#import <XCTest/XCTest.h>
#include "OKEngineTypist.h"

@interface OKCharsOnScreenTests : XCTestCase
@end

@implementation OKCharsOnScreenTests

//text is the whole field, prefix included
- (void)type:(const std::string&)keys expect:(const std::string&)text onScreen:(int)onScreen
    settings:(const OKTypingSettings&)settings prefix:(const std::string&)prefix {
    OKTypingResult r = OKTypeKeys(keys, settings, prefix);
    XCTAssertEqualObjects(@(r.text.c_str()), @(text.c_str()), @"%s", keys.c_str());
    XCTAssertEqual(r.charsOnScreen, onScreen, @"%s gave %s", keys.c_str(), r.text.c_str());
}

- (void)type:(const std::string&)keys expect:(const std::string&)text onScreen:(int)onScreen
    settings:(const OKTypingSettings&)settings {
    [self type:keys expect:text onScreen:onScreen settings:settings prefix:""];
}

- (void)type:(const std::string&)keys expect:(const std::string&)text onScreen:(int)onScreen {
    [self type:keys expect:text onScreen:onScreen settings:OKTypingSettings() prefix:""];
}

- (void)testLettersThatPassThroughCount {
    [self type:"viet" expect:"viet" onScreen:4];
}

- (void)testCorrectionsCountWhatTheyLeave {
    [self type:"vieet" expect:"viêt" onScreen:4];
    [self type:"vieetj" expect:"việt" onScreen:4];
    //a lone w is swallowed and written as ư
    [self type:"w" expect:"ư" onScreen:1];
}

- (void)testBackspaceTakesOneAway {
    [self type:"viet{BS}" expect:"vie" onScreen:3];
}

/// Text the engine never saw cannot be reached, however much is deleted.
- (void)testBackspaceNeverGoesBelowNothing {
    [self type:"{BS}{BS}{BS}" expect:"" onScreen:0 settings:OKTypingSettings() prefix:"ab"];
}

/// A space in front of the cursor: nothing a correction may delete.
- (void)testSpaceEndsTheWord {
    [self type:"viet " expect:"viet " onScreen:0];
}

/// Backspacing over the space puts the word back in reach, as the engine
/// takes it back for editing.
- (void)testBackspaceOverTheSpaceReturnsToTheWord {
    [self type:"viet {BS}" expect:"viet" onScreen:4];
    [self type:"vieet {BS}j" expect:"việt" onScreen:4];
}

- (void)testPunctuationStaysInTheWord {
    [self type:"a,b" expect:"a,b" onScreen:3];
}

- (void)testReturnForgetsWhatCameBefore {
    [self type:"viet{RET}" expect:"viet\n" onScreen:0];
    [self type:"viet{RET}ab" expect:"viet\nab" onScreen:2];
}

- (void)testClickForgetsWhatCameBefore {
    [self type:"viet{CLICK}" expect:"viet" onScreen:0];
    [self type:"viet{CLICK}ab" expect:"vietab" onScreen:2];
}

/// The macro is written as one piece, spaces and all, and the engine takes
/// the whole of it back when the space after it is deleted.
- (void)testMacroCountsItsContent {
    OKTypingSettings settings;
    settings.macros = {{"btw", "by the way"}};
    [self type:"btw " expect:"by the way " onScreen:0 settings:settings];
    [self type:"btw {BS}" expect:"by the way" onScreen:10 settings:settings];
}

/// Restoring the keys of a misspelt word on space.
- (void)testRestoreCountsTheKeysWrittenBack {
    OKTypingSettings settings;
    settings.restoreIfWrongSpelling = true;
    [self type:"cool {BS}" expect:"cool" onScreen:4 settings:settings];
}

/// The empty character is written and deleted within the correction.
- (void)testEmptyCharacterWorkaroundLeavesNoTrace {
    OKTypingSettings settings;
    settings.emptyCharWorkaround = true;
    [self type:"vieetj" expect:"việt" onScreen:4 settings:settings];
}

@end
