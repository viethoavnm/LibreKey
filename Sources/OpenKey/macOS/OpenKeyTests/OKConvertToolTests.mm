//
//  OKConvertToolTests.mm
//  OpenKeyTests
//
//  The clipboard convert tool (engine/ConvertTool.cpp), Unicode to Unicode so
//  only the case and mark options are at play.
//

#import <XCTest/XCTest.h>
#include "Engine.h"
#include "ConvertTool.h"

@interface OKConvertToolTests : XCTestCase
@end

@implementation OKConvertToolTests

- (void)setUp {
    [super setUp];
    [self resetOptions];
}

- (void)tearDown {
    [self resetOptions];
    [super tearDown];
}

- (void)resetOptions {
    convertToolRemoveMark = false;
    convertToolToAllCaps = false;
    convertToolToAllNonCaps = false;
    convertToolToCapsFirstLetter = false;
    convertToolToCapsEachWord = false;
    convertToolFromCode = 0;
    convertToolToCode = 0;
}

- (NSString *)convert:(const char *)text {
    return @(convertUtil(text).c_str());
}

/// With no case option the case of every letter is kept.
- (void)testNoOptionKeepsTheText {
    XCTAssertEqualObjects([self convert:"VIỆT Nam đẹp"], @"VIỆT Nam đẹp");
}

/// Removing marks keeps upper case letters upper case (upstream PR #297).
- (void)testRemovingMarksKeepsTheCase {
    convertToolRemoveMark = true;
    XCTAssertEqualObjects([self convert:"VIỆT Nam đẹp"], @"VIET Nam dep");
}

- (void)testAllCapsUppercasesMarkedLetters {
    convertToolToAllCaps = true;
    XCTAssertEqualObjects([self convert:"Việt nam"], @"VIỆT NAM");
    convertToolRemoveMark = true;
    XCTAssertEqualObjects([self convert:"Việt nam"], @"VIET NAM");
}

- (void)testAllLowerCase {
    convertToolToAllNonCaps = true;
    XCTAssertEqualObjects([self convert:"VIỆT Nam"], @"việt nam");
}

- (void)testCapitaliseEachWordAlsoWhenRemovingMarks {
    convertToolToCapsEachWord = true;
    convertToolRemoveMark = true;
    XCTAssertEqualObjects([self convert:"việt nam"], @"Viet Nam");
}

- (void)testCapitaliseSentences {
    convertToolToCapsFirstLetter = true;
    XCTAssertEqualObjects([self convert:"việt nam. hà nội"], @"Việt nam. Hà nội");
}

@end
