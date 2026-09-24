//
//  OKTerminalTypingTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import "OKTerminalTyping.h"

@interface OKTerminalTypingTests : XCTestCase
@end

@implementation OKTerminalTypingTests

#pragma mark - isTerminalBundleId

- (void)testRecognisesTheBundledTerminals {
    XCTAssertTrue([OKTerminalTyping isTerminalBundleId:@"com.apple.Terminal"]);
    XCTAssertTrue([OKTerminalTyping isTerminalBundleId:@"com.googlecode.iterm2"]);
}

- (void)testRecognisesThirdPartyTerminals {
    NSArray<NSString *> *terminals = @[@"dev.warp.Warp-Stable",
                                       @"net.kovidgoyal.kitty",
                                       @"org.alacritty",
                                       @"com.github.wez.wezterm",
                                       @"com.mitchellh.ghostty",
                                       @"co.zeit.hyper",
                                       @"org.tabby",
                                       @"com.termius-dmg.mac"];
    for (NSString *bundleId in terminals) {
        XCTAssertTrue([OKTerminalTyping isTerminalBundleId:bundleId], @"%@", bundleId);
    }
}

/// Release channels and store builds hang a suffix off the id, after a dot or
/// a dash; they must come along without listing every one of them.
- (void)testMatchesChannelsHangingOffAKnownId {
    XCTAssertTrue([OKTerminalTyping isTerminalBundleId:@"dev.warp.Warp-Preview"]);
    XCTAssertTrue([OKTerminalTyping isTerminalBundleId:@"com.mitchellh.ghostty.debug"]);
    XCTAssertTrue([OKTerminalTyping isTerminalBundleId:@"com.termius.mac"]);
}

/// A bare prefix test would take any app whose id merely starts the same way.
- (void)testDoesNotMatchAnIdThatOnlySharesLeadingLetters {
    XCTAssertFalse([OKTerminalTyping isTerminalBundleId:@"org.tabbyml.Tabby"]);
    XCTAssertFalse([OKTerminalTyping isTerminalBundleId:@"com.apple.TerminalHelper"]);
}

- (void)testIgnoresCase {
    XCTAssertTrue([OKTerminalTyping isTerminalBundleId:@"com.googlecode.iTerm2"]);
    XCTAssertTrue([OKTerminalTyping isTerminalBundleId:@"COM.APPLE.TERMINAL"]);
}

- (void)testRejectsNilAndEmpty {
    XCTAssertFalse([OKTerminalTyping isTerminalBundleId:nil]);
    XCTAssertFalse([OKTerminalTyping isTerminalBundleId:@""]);
}

/// VS Code has a terminal panel, but it is an editor first and the bundle id
/// cannot tell the two apart - it keeps the regular behaviour.
- (void)testRejectsAppsThatAreNotTerminals {
    XCTAssertFalse([OKTerminalTyping isTerminalBundleId:@"com.apple.Safari"]);
    XCTAssertFalse([OKTerminalTyping isTerminalBundleId:@"com.apple.TextEdit"]);
    XCTAssertFalse([OKTerminalTyping isTerminalBundleId:@"com.google.Chrome"]);
    XCTAssertFalse([OKTerminalTyping isTerminalBundleId:@"com.microsoft.VSCode"]);
}

@end
