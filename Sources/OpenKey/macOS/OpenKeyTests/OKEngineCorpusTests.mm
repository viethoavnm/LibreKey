//
//  OKEngineCorpusTests.mm
//  OpenKeyTests
//
//  Regression gates for the typing engine. Each one fails if fewer rows pass
//  than the last measured count, or if any row breaks a safety rule. Raise the
//  counts when a fix makes more rows pass; never lower them.
//
//  The UniKey table ships in Corpus/. The two large corpora (30,337 Telex
//  pairs and 97,592 English words, from the Gõ Nhanh / uvie-rs repos) have no
//  documented data licence, so they are not in the repository: point
//  LIBREKEY_CORPUS_DIR at a folder holding telex_pairs_space.tsv and
//  english_space.tsv to run them, e.g.
//    TEST_RUNNER_LIBREKEY_CORPUS_DIR=/path/to/corpora xcodebuild ... test
//

#import <XCTest/XCTest.h>
#include "OKEngineCorpus.h"

//Last measured counts. Raise them as fixes land.
static const int kUniKeyTablePassing = 1302;       //of 1,307
static const int kTelexPairsPassing = 30263;       //of 30,337
static const int kEnglishPassing = 94864;          //of 97,592
static const int kEnglishOverDeleteRows = 0;
static const int kEnglishControlCharRows = 0;

@interface OKEngineCorpusTests : XCTestCase
@end

@implementation OKEngineCorpusTests

+ (NSString *)bundledCorpus:(NSString *)name {
    NSString *here = [@(__FILE__) stringByDeletingLastPathComponent];
    return [[here stringByAppendingPathComponent:@"Corpus"] stringByAppendingPathComponent:name];
}

- (NSString *)externalCorpus:(NSString *)name {
    NSString *dir = NSProcessInfo.processInfo.environment[@"LIBREKEY_CORPUS_DIR"];
    if (dir.length == 0)
        return nil;
    NSString *path = [dir stringByAppendingPathComponent:name];
    return [[NSFileManager defaultManager] fileExistsAtPath:path] ? path : nil;
}

- (void)logFailures:(const OKCorpusReport &)report limit:(size_t)limit {
    for (size_t i = 0; i < report.failures.size() && i < limit; i++)
        NSLog(@"corpus failure: %s", report.failures[i].c_str());
}

/// The UniKey test table, typed with spelling check off like UniKey's own run.
- (void)testUniKeyTelexTable {
    std::vector<OKCorpusRow> rows = OKLoadCorpus([OKEngineCorpusTests bundledCorpus:@"unikey-telex.tsv"].UTF8String);
    XCTAssertEqual(rows.size(), 1307u);

    OKTypingSettings settings;
    settings.spelling = false;
    OKCorpusReport report = OKRunCorpus(rows, settings);

    NSLog(@"UniKey table: %d of %d pass", report.passed, report.rows);
    XCTAssertGreaterThanOrEqual(report.passed, kUniKeyTablePassing);
    XCTAssertEqual(report.overDeletes, 0);
    XCTAssertEqual(report.controlChars, 0);
}

- (void)testTelexPairs {
    NSString *path = [self externalCorpus:@"telex_pairs_space.tsv"];
    if (!path)
        XCTSkip(@"set LIBREKEY_CORPUS_DIR to run the 30,337 Telex pairs");

    OKCorpusReport report = OKRunCorpus(OKLoadCorpus(path.UTF8String));
    NSLog(@"Telex pairs: %d of %d pass", report.passed, report.rows);
    [self logFailures:report limit:20];
    XCTAssertGreaterThanOrEqual(report.passed, kTelexPairsPassing);
    XCTAssertEqual(report.overDeletes, 0);
    XCTAssertEqual(report.controlChars, 0);
}

/// English words must come back as typed once restore is on.
- (void)testEnglishWords {
    NSString *path = [self externalCorpus:@"english_space.tsv"];
    if (!path)
        XCTSkip(@"set LIBREKEY_CORPUS_DIR to run the 97,592 English words");

    OKTypingSettings settings;
    settings.restoreIfWrongSpelling = true;
    OKCorpusReport report = OKRunCorpus(OKLoadCorpus(path.UTF8String), settings);
    NSLog(@"English: %d of %d pass, %d over-delete, %d control", report.passed, report.rows,
          report.overDeletes, report.controlChars);
    XCTAssertGreaterThanOrEqual(report.passed, kEnglishPassing);
    XCTAssertLessThanOrEqual(report.overDeletes, kEnglishOverDeleteRows);
    XCTAssertLessThanOrEqual(report.controlChars, kEnglishControlCharRows);
}

@end
