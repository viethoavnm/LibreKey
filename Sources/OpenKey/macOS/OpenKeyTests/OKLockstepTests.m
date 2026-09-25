//
//  OKLockstepTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import "OKLockstep.h"

@interface OKLockstepTests : XCTestCase
@end

@implementation OKLockstepTests {
    OKTypingPlan *_terminal;
    OKTypingPlan *_regular;
    OKLockstep *_lockstep;
}

- (void)setUp {
    [super setUp];
    _terminal = [[OKTypingPlan alloc] initWithAllowsAutocompleteWorkaround:NO oneCharacterPerEvent:YES syntheticLockstep:YES];
    _regular = [[OKTypingPlan alloc] initWithAllowsAutocompleteWorkaround:YES oneCharacterPerEvent:NO syntheticLockstep:NO];
    _lockstep = [[OKLockstep alloc] initWithWindow:0.15];
}

- (BOOL)key:(NSTimeInterval)now plan:(OKTypingPlan *)plan {
    return [_lockstep shouldPostKeyAt:now plan:plan endsWord:NO shortcut:NO];
}

- (void)testNothingToFollowBeforeAnyCorrection {
    XCTAssertFalse([self key:10 plan:_terminal]);
}

- (void)testKeysAfterACorrectionInTheWordArePosted {
    [_lockstep noteCorrectionPostedAt:10];
    XCTAssertTrue([self key:10.05 plan:_terminal]);
    //still the same word, long after: still in lockstep
    XCTAssertTrue([self key:15 plan:_terminal]);
}

- (void)testRegularAppsNeverRepost {
    [_lockstep noteCorrectionPostedAt:10];
    XCTAssertFalse([self key:10.05 plan:_regular]);
}

/// The key that ends the word is posted too, and ends the word's lockstep.
- (void)testWordEndIsPostedAndEndsTheWord {
    [_lockstep noteCorrectionPostedAt:10];
    XCTAssertTrue([_lockstep shouldPostKeyAt:10.05 plan:_terminal endsWord:YES shortcut:NO]);
    //right behind the correction: still posted
    XCTAssertTrue([self key:10.1 plan:_terminal]);
    //a quiet moment later, a new word goes back to normal
    XCTAssertFalse([self key:11 plan:_terminal]);
}

- (void)testShortcutsAreNeverRepostedAndEndTheWord {
    [_lockstep noteCorrectionPostedAt:10];
    XCTAssertFalse([_lockstep shouldPostKeyAt:10.05 plan:_terminal endsWord:YES shortcut:YES]);
    XCTAssertFalse([self key:11 plan:_terminal]);
}

- (void)testResetForgetsEverything {
    [_lockstep noteCorrectionPostedAt:10];
    [_lockstep reset];
    XCTAssertFalse([self key:10.05 plan:_terminal]);
}

@end
