//
//  OKEngineCorpusRunnerTests.mm
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#include "OKEngineCorpus.h"

@interface OKEngineCorpusRunnerTests : XCTestCase
@end

@implementation OKEngineCorpusRunnerTests {
    NSString *_path;
}

- (void)setUp {
    [super setUp];
    _path = [NSTemporaryDirectory() stringByAppendingPathComponent:
             [NSString stringWithFormat:@"OKCorpus-%@.tsv", [[NSUUID UUID] UUIDString]]];
}

- (void)tearDown {
    [[NSFileManager defaultManager] removeItemAtPath:_path error:NULL];
    [super tearDown];
}

- (void)write:(NSString *)content {
    [content writeToFile:_path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

#pragma mark - OKLoadCorpus

- (void)testLoadSkipsCommentsAndBlankLines {
    [self write:@"# source: somewhere\n\naa\tâ\nvieetj \tviệt \n"];
    std::vector<OKCorpusRow> rows = OKLoadCorpus(_path.UTF8String);
    XCTAssertEqual(rows.size(), 2u);
    XCTAssertEqualObjects(@(rows[0].keys.c_str()), @"aa");
    XCTAssertEqualObjects(@(rows[0].expected.c_str()), @"â");
    //trailing spaces are part of the row: they are typed and expected
    XCTAssertEqualObjects(@(rows[1].keys.c_str()), @"vieetj ");
    XCTAssertEqualObjects(@(rows[1].expected.c_str()), @"việt ");
}

- (void)testLoadIgnoresLinesWithoutATab {
    [self write:@"aa\tâ\nnot a row\n"];
    XCTAssertEqual(OKLoadCorpus(_path.UTF8String).size(), 1u);
}

- (void)testLoadOfMissingFileIsEmpty {
    XCTAssertEqual(OKLoadCorpus("/nonexistent/corpus.tsv").size(), 0u);
}

#pragma mark - OKRunCorpus

- (void)testRunCountsPassesAndFailures {
    std::vector<OKCorpusRow> rows = {{"aa", "â"}, {"ab", "ab"}, {"aa", "a"}};
    OKCorpusReport report = OKRunCorpus(rows, OKTypingSettings(), "");
    XCTAssertEqual(report.rows, 3);
    XCTAssertEqual(report.passed, 2);
    XCTAssertEqual(report.failures.size(), 1u);
    XCTAssertTrue([@(report.failures[0].c_str()) containsString:@"want a"]);
}

/// The prefix is typed first and must still be there, in front of the row.
- (void)testRunExpectsThePrefixInFront {
    std::vector<OKCorpusRow> rows = {{"aa", "â"}};
    XCTAssertEqual(OKRunCorpus(rows, OKTypingSettings(), "pp ").passed, 1);
}

- (void)testRunCountsRowsThatDeleteIntoThePrefix {
    std::vector<OKCorpusRow> rows = {{"{BS}", "pp"}, {"a", "a"}};
    OKCorpusReport report = OKRunCorpus(rows, OKTypingSettings(), "pp ");
    XCTAssertEqual(report.overDeletes, 1);
}

- (void)testRunPassesSettingsThrough {
    OKTypingSettings vni;
    vni.inputType = 1;
    std::vector<OKCorpusRow> rows = {{"a6", "â"}};
    XCTAssertEqual(OKRunCorpus(rows, vni, "").passed, 1);
}

@end
