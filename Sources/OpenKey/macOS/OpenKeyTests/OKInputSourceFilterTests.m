//
//  OKInputSourceFilterTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import "OKInputSourceFilter.h"

@interface OKInputSourceFilterTests : XCTestCase
@end

@implementation OKInputSourceFilterTests

- (void)testEnglishSourcesKeepVietnamese {
    XCTAssertFalse([OKInputSourceFilter shouldBypassForLanguages:@[@"en"]]);
    XCTAssertFalse([OKInputSourceFilter shouldBypassForLanguages:@[@"en-GB"]]);
}

- (void)testOtherLanguagesPassKeysThrough {
    XCTAssertTrue([OKInputSourceFilter shouldBypassForLanguages:@[@"vi"]]);
    XCTAssertTrue([OKInputSourceFilter shouldBypassForLanguages:@[@"ja"]]);
    XCTAssertTrue(([OKInputSourceFilter shouldBypassForLanguages:@[@"fr", @"de"]]));
}

/// A layout that lists English among its languages is still an English layout.
- (void)testEnglishAnywhereInTheListCounts {
    XCTAssertFalse(([OKInputSourceFilter shouldBypassForLanguages:@[@"de", @"en"]]));
}

/// "english-like" is not English: only en and en-XX are.
- (void)testPrefixMatchStopsAtTheLanguageBoundary {
    XCTAssertTrue([OKInputSourceFilter shouldBypassForLanguages:@[@"enx"]]);
}

- (void)testSourceWithoutLanguagesIsLeftAlone {
    XCTAssertFalse([OKInputSourceFilter shouldBypassForLanguages:@[]]);
    XCTAssertFalse([OKInputSourceFilter shouldBypassForLanguages:nil]);
}

@end
