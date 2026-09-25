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

#pragma mark - code editor terminal panels

- (void)testCodeEditorsWithATerminalPanel {
    for (NSString *bundleId in @[@"com.microsoft.VSCode", @"com.microsoft.VSCodeInsiders", @"com.vscodium",
                                 @"com.todesktop.230313mzl4w4u92", @"com.exafunction.windsurf"]) {
        XCTAssertTrue([OKTerminalTyping isCodeEditorBundleId:bundleId], @"%@", bundleId);
    }
}

- (void)testOtherAppsAreNotCodeEditors {
    XCTAssertFalse([OKTerminalTyping isCodeEditorBundleId:@"com.apple.TextEdit"]);
    XCTAssertFalse([OKTerminalTyping isCodeEditorBundleId:@"com.apple.Terminal"]);
    XCTAssertFalse([OKTerminalTyping isCodeEditorBundleId:nil]);
}

/// xterm.js labels its input "Terminal 1, zsh ..." (localised builds keep it).
- (void)testTerminalPanelDescription {
    XCTAssertTrue([OKTerminalTyping isIntegratedTerminalDescription:@"Terminal 1, zsh Run the command: Toggle Screen Reader Accessibility Mode"]);
    XCTAssertTrue([OKTerminalTyping isIntegratedTerminalDescription:@"terminal 2, bash"]);
}

- (void)testEditorDescriptionsAreNotTheTerminal {
    XCTAssertFalse([OKTerminalTyping isIntegratedTerminalDescription:@"Editor content"]);
    XCTAssertFalse([OKTerminalTyping isIntegratedTerminalDescription:@"The editor is not accessible at this time."]);
    XCTAssertFalse([OKTerminalTyping isIntegratedTerminalDescription:@"Terminals"]);
    XCTAssertFalse([OKTerminalTyping isIntegratedTerminalDescription:@""]);
    XCTAssertFalse([OKTerminalTyping isIntegratedTerminalDescription:nil]);
}

- (void)testTerminalPanelGetsTheTerminalPlan {
    OKTypingTarget *panel = [[OKTypingTarget alloc] initWithBundleId:@"com.microsoft.VSCode"
                                                    spotlightVisible:NO
                                                  integratedTerminal:YES];
    OKTypingPlan *plan = [OKTerminalTyping planForTarget:panel];
    XCTAssertFalse(plan.allowsAutocompleteWorkaround);
    XCTAssertTrue(plan.oneCharacterPerEvent);
    XCTAssertTrue(plan.syntheticLockstep);
}

- (void)testEditorPaneKeepsTheRegularPlan {
    OKTypingTarget *editor = [[OKTypingTarget alloc] initWithBundleId:@"com.microsoft.VSCode"
                                                     spotlightVisible:NO
                                                   integratedTerminal:NO];
    XCTAssertTrue([OKTerminalTyping planForTarget:editor].allowsAutocompleteWorkaround);
}

#pragma mark - planForTarget

- (OKTypingPlan *)planForBundleId:(NSString *)bundleId spotlightVisible:(BOOL)spotlightVisible {
    OKTypingTarget *target = [[OKTypingTarget alloc] initWithBundleId:bundleId
                                                     spotlightVisible:spotlightVisible];
    return [OKTerminalTyping planForTarget:target];
}

/// Everything outside a terminal must keep posting exactly as before.
- (void)testRegularAppKeepsTodaysPlan {
    OKTypingPlan *plan = [self planForBundleId:@"com.apple.TextEdit" spotlightVisible:NO];
    XCTAssertTrue(plan.allowsAutocompleteWorkaround);
    XCTAssertFalse(plan.oneCharacterPerEvent);
}

- (void)testUnknownAppKeepsTodaysPlan {
    OKTypingPlan *plan = [self planForBundleId:nil spotlightVisible:NO];
    XCTAssertTrue(plan.allowsAutocompleteWorkaround);
    XCTAssertFalse(plan.oneCharacterPerEvent);
}

/// A terminal has no autocomplete to defeat, and the empty character is one
/// more thing the far end has to receive, draw and erase in step.
- (void)testTerminalSkipsTheAutocompleteWorkaround {
    OKTypingPlan *plan = [self planForBundleId:@"com.googlecode.iterm2" spotlightVisible:NO];
    XCTAssertFalse(plan.allowsAutocompleteWorkaround);
}

/// Some terminals take a multi-character key event for a paste and drop it,
/// while the backspaces before it still land.
- (void)testTerminalGetsOneCharacterPerEvent {
    OKTypingPlan *plan = [self planForBundleId:@"com.apple.Terminal" spotlightVisible:NO];
    XCTAssertTrue(plan.oneCharacterPerEvent);
}

/// A real key must not overtake the correction posted before it.
- (void)testTerminalPostsTheKeysAfterACorrectionItself {
    OKTypingPlan *plan = [self planForBundleId:@"com.googlecode.iterm2" spotlightVisible:NO];
    XCTAssertTrue(plan.syntheticLockstep);
}

- (void)testRegularAppLetsKeysPassOnTheirOwn {
    OKTypingPlan *plan = [self planForBundleId:@"com.apple.TextEdit" spotlightVisible:NO];
    XCTAssertFalse(plan.syntheticLockstep);
    XCTAssertFalse([self planForBundleId:@"com.apple.Terminal" spotlightVisible:YES].syntheticLockstep);
}

/// Spotlight over a terminal gets the keys, not the terminal, so the terminal
/// rules must not apply.
- (void)testSpotlightOverATerminalKeepsTodaysPlan {
    OKTypingPlan *plan = [self planForBundleId:@"com.apple.Terminal" spotlightVisible:YES];
    XCTAssertTrue(plan.allowsAutocompleteWorkaround);
    XCTAssertFalse(plan.oneCharacterPerEvent);
}

@end
