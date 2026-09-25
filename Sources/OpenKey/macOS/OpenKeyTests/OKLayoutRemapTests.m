//
//  OKLayoutRemapTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import "OKLayoutRemap.h"

@interface OKLayoutRemapTests : XCTestCase
@end

@implementation OKLayoutRemapTests

//What each main-block key types unshifted on a US keyboard, by key code.
static NSDictionary<NSNumber *, NSString *> *USLayout(void) {
    return @{@0: @"a", @1: @"s", @2: @"d", @3: @"f", @4: @"h", @5: @"g", @6: @"z", @7: @"x", @8: @"c",
             @9: @"v", @11: @"b", @12: @"q", @13: @"w", @14: @"e", @15: @"r", @16: @"y", @17: @"t",
             @18: @"1", @19: @"2", @20: @"3", @21: @"4", @22: @"6", @23: @"5", @24: @"=", @25: @"9",
             @26: @"7", @27: @"-", @28: @"8", @29: @"0", @30: @"]", @31: @"o", @32: @"u", @33: @"[",
             @34: @"i", @35: @"p", @36: @"\r", @37: @"l", @38: @"j", @39: @"'", @40: @"k", @41: @";",
             @42: @"\\", @43: @",", @44: @"/", @45: @"n", @46: @"m", @47: @".", @48: @"\t", @49: @" ",
             @50: @"`"};
}

static NSDictionary<NSNumber *, NSString *> *Layout(NSDictionary<NSNumber *, NSString *> *changes) {
    NSMutableDictionary *layout = [USLayout() mutableCopy];
    [layout addEntriesFromDictionary:changes];
    return layout;
}

//French AZERTY, as far as the tests need it.
static NSDictionary<NSNumber *, NSString *> *AZERTY(void) {
    return Layout(@{@0: @"q", @12: @"a", @6: @"w", @13: @"z", @41: @"m", @46: @",", @43: @";",
                    @47: @":", @44: @"=", @18: @"&", @19: @"é", @20: @"\"", @21: @"'", @24: @"-"});
}

- (void)testUSStaysPut {
    OKLayoutRemap *remap = [OKLayoutRemap remapForCharacters:USLayout()];
    XCTAssertTrue(remap.isIdentity);
    for (uint16_t code = 0; code <= 50; code++) {
        XCTAssertEqual([remap usKeyCodeFor:code], code);
    }
}

/// The Telex w on AZERTY is where US has z: it used to reach the engine as z.
- (void)testAzertyLettersGoToTheirUSKeys {
    OKLayoutRemap *remap = [OKLayoutRemap remapForCharacters:AZERTY()];
    XCTAssertFalse(remap.isIdentity);
    XCTAssertEqual([remap usKeyCodeFor:6], 13);    //w
    XCTAssertEqual([remap usKeyCodeFor:13], 6);    //z
    XCTAssertEqual([remap usKeyCodeFor:0], 12);    //q
    XCTAssertEqual([remap usKeyCodeFor:12], 0);    //a
    XCTAssertEqual([remap usKeyCodeFor:41], 46);   //m
}

- (void)testAzertyUnshiftedUSPunctuationFollowsToo {
    OKLayoutRemap *remap = [OKLayoutRemap remapForCharacters:AZERTY()];
    XCTAssertEqual([remap usKeyCodeFor:46], 43);   //,
    XCTAssertEqual([remap usKeyCodeFor:43], 41);   //;
    XCTAssertEqual([remap usKeyCodeFor:24], 27);   //-
    XCTAssertEqual([remap usKeyCodeFor:21], 39);   //'
}

/// & é " : are not unshifted US keys: those keys stay where they are.
- (void)testOtherCharactersLeaveTheKeyAlone {
    OKLayoutRemap *remap = [OKLayoutRemap remapForCharacters:AZERTY()];
    XCTAssertEqual([remap usKeyCodeFor:18], 18);   //&
    XCTAssertEqual([remap usKeyCodeFor:19], 19);   //é
    XCTAssertEqual([remap usKeyCodeFor:20], 20);   //"
    XCTAssertEqual([remap usKeyCodeFor:47], 47);   //:
}

- (void)testQwertzSwapsYAndZ {
    OKLayoutRemap *remap = [OKLayoutRemap remapForCharacters:Layout(@{@16: @"z", @6: @"y", @33: @"ü", @44: @"-"})];
    XCTAssertEqual([remap usKeyCodeFor:16], 6);
    XCTAssertEqual([remap usKeyCodeFor:6], 16);
    XCTAssertEqual([remap usKeyCodeFor:33], 33);
    XCTAssertEqual([remap usKeyCodeFor:44], 27);
}

- (void)testUpperCaseIsReadAsTheLetter {
    OKLayoutRemap *remap = [OKLayoutRemap remapForCharacters:Layout(@{@0: @"Q"})];
    XCTAssertEqual([remap usKeyCodeFor:0], 12);
}

/// The keypad, Return, Tab and Space keep their own codes whatever they type.
- (void)testKeysOutsideTheMainBlockAreIgnored {
    OKLayoutRemap *remap = [OKLayoutRemap remapForCharacters:Layout(@{@83: @"1", @36: @"a", @48: @"b", @49: @"c"})];
    XCTAssertTrue(remap.isIdentity);
    XCTAssertEqual([remap usKeyCodeFor:83], 83);
    XCTAssertEqual([remap usKeyCodeFor:36], 36);
}

- (void)testMoreThanOneCharacterIsIgnored {
    OKLayoutRemap *remap = [OKLayoutRemap remapForCharacters:Layout(@{@0: @"qu"})];
    XCTAssertEqual([remap usKeyCodeFor:0], 0);
}

/// Russian and the like type nothing the engine knows: nothing moves, and
/// the other language setting decides what happens to those keys.
- (void)testNonLatinLayoutStaysPut {
    OKLayoutRemap *remap = [OKLayoutRemap remapForCharacters:Layout(@{@0: @"ф", @12: @"й", @13: @"ц", @6: @"я"})];
    XCTAssertTrue(remap.isIdentity);
}

- (void)testKeyCodeNotReadStaysPut {
    OKLayoutRemap *remap = [OKLayoutRemap remapForCharacters:@{}];
    XCTAssertTrue(remap.isIdentity);
    XCTAssertEqual([remap usKeyCodeFor:13], 13);
}

@end
