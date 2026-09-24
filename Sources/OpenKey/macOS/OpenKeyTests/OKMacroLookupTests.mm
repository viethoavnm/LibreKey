//
//  OKMacroLookupTests.mm
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#include "Engine.h"

@interface OKMacroLookupTests : XCTestCase
@end

@implementation OKMacroLookupTests

- (void)setUp {
    [super setUp];
    addMacro("btw", "by the way");
    addMacro("->", "→");
}

- (void)tearDown {
    deleteMacro("btw");
    deleteMacro("->");
    [super tearDown];
}

/// The key as the engine builds it while typing: one engine code per character.
- (vector<Uint32>)keyFor:(const char *)text {
    vector<Uint32> key;
    for (const char *c = text; *c; c++)
        key.push_back(_characterMap[(unsigned char)*c]);
    return key;
}

- (void)testWholeKeyMatches {
    vector<Uint32> content;
    int matched = -1;
    XCTAssertTrue(findMacroSkippingLeadingPunctuation([self keyFor:"btw"], content, matched));
    XCTAssertEqual(matched, 3);
    XCTAssertEqual(content.size(), 10u);    //"by the way"
}

- (void)testPunctuationInFrontIsSkipped {
    for (const char *typed : {"\"btw", "(btw", "'btw", "\"(btw"}) {
        vector<Uint32> content;
        int matched = -1;
        XCTAssertTrue(findMacroSkippingLeadingPunctuation([self keyFor:typed], content, matched), @"%s", typed);
        XCTAssertEqual(matched, 3, @"%s", typed);
    }
}

/// A macro whose own key starts with punctuation is found whole first.
- (void)testMacroKeyStartingWithPunctuationMatchesWhole {
    vector<Uint32> content;
    int matched = -1;
    XCTAssertTrue(findMacroSkippingLeadingPunctuation([self keyFor:"->"], content, matched));
    XCTAssertEqual(matched, 2);
}

/// Only punctuation is skipped: a letter or a digit in front makes it another word.
- (void)testLettersAndDigitsInFrontAreNotSkipped {
    vector<Uint32> content;
    int matched = -1;
    XCTAssertFalse(findMacroSkippingLeadingPunctuation([self keyFor:"xbtw"], content, matched));
    XCTAssertFalse(findMacroSkippingLeadingPunctuation([self keyFor:"1btw"], content, matched));
}

- (void)testNoMacro {
    vector<Uint32> content;
    int matched = -1;
    XCTAssertFalse(findMacroSkippingLeadingPunctuation([self keyFor:"zzz"], content, matched));
    XCTAssertEqual(matched, 0);
}

- (void)testKeyIsLeftUntouched {
    vector<Uint32> key = [self keyFor:"\"btw"];
    vector<Uint32> before = key;
    vector<Uint32> content;
    int matched = 0;
    findMacroSkippingLeadingPunctuation(key, content, matched);
    XCTAssertTrue(key == before);
}

@end
