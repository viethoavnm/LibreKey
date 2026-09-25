//
//  OKCompoundDeletionTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import "OKCompoundDeletion.h"

@interface OKCompoundDeletionTests : XCTestCase
@end

@implementation OKCompoundDeletionTests

- (OKLetterRemoval *)removeUnits:(NSUInteger)units codeTable:(int)codeTable app:(NSString *)bundleId {
    OKWrittenLetter *letter = [[OKWrittenLetter alloc] initWithUnits:units codeTable:codeTable bundleId:bundleId];
    return [OKCompoundDeletion removalOfLetter:letter];
}

/// One unit is one press, wherever it is.
- (void)testSingleUnitLetterTakesOnePress {
    for (NSNumber *table in @[@0, @2, @3]) {
        OKLetterRemoval *r = [self removeUnits:1 codeTable:table.intValue app:@"com.google.Chrome"];
        XCTAssertEqual(r.backspaces, 1u);
        XCTAssertEqual(r.selectionSteps, 1u);
    }
}

/// VNI Windows is a byte font encoding: every unit is a character of its own.
- (void)testVniUnitsAreSeparateCharactersEverywhere {
    for (NSString *app in @[@"com.apple.TextEdit", @"com.google.Chrome", @"com.microsoft.Word"]) {
        OKLetterRemoval *r = [self removeUnits:2 codeTable:2 app:app];
        XCTAssertEqual(r.backspaces, 2u, @"%@", app);
        XCTAssertEqual(r.selectionSteps, 2u, @"%@", app);
    }
}

/// Cocoa text treats a base letter and its combining mark as one character.
- (void)testCocoaRemovesACompoundLetterWhole {
    OKLetterRemoval *r = [self removeUnits:2 codeTable:3 app:@"com.apple.TextEdit"];
    XCTAssertEqual(r.backspaces, 1u);
    XCTAssertEqual(r.selectionSteps, 1u);
}

/// #182: Chromium selects the letter whole, but a backspace takes off one code
/// point - the mark - and left the base letter behind ("conff" gave "coonf").
- (void)testChromiumDeletesACompoundLetterOneCodePointAtATime {
    for (NSString *app in @[@"com.google.Chrome", @"com.google.Chrome.canary", @"com.brave.Browser",
                            @"com.microsoft.edgemac", @"com.microsoft.edgemac.Dev"]) {
        OKLetterRemoval *r = [self removeUnits:2 codeTable:3 app:app];
        XCTAssertEqual(r.backspaces, 2u, @"%@", app);
        XCTAssertEqual(r.selectionSteps, 1u, @"%@", app);
    }
}

/// Anywhere else nothing is known, so every unit gets its own press, as before.
- (void)testOtherAppsTakeOnePressPerUnit {
    for (NSString *app in @[@"com.microsoft.Word", @"org.mozilla.firefox"]) {
        OKLetterRemoval *r = [self removeUnits:2 codeTable:3 app:app];
        XCTAssertEqual(r.backspaces, 2u, @"%@", app);
        XCTAssertEqual(r.selectionSteps, 2u, @"%@", app);
    }
    OKLetterRemoval *unknown = [self removeUnits:2 codeTable:3 app:nil];
    XCTAssertEqual(unknown.backspaces, 2u);
    XCTAssertEqual(unknown.selectionSteps, 2u);
}

/// A bare prefix must not take in an app that only starts the same way.
- (void)testAppleMatchIsOnTheWholeVendorPart {
    OKLetterRemoval *r = [self removeUnits:2 codeTable:3 app:@"com.applesoft.Editor"];
    XCTAssertEqual(r.backspaces, 2u);
}

@end
