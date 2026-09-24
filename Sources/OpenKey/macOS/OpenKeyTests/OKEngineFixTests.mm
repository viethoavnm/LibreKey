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

@end
