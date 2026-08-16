//
//  OKSingleInstanceLockTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import <sys/file.h>
#import <fcntl.h>
#import <unistd.h>
#import "OKSingleInstanceLock.h"

@interface OKSingleInstanceLockTests : XCTestCase
@end

@implementation OKSingleInstanceLockTests {
    NSString *_dir;
    NSString *_path;
}

- (void)setUp {
    [super setUp];
    _dir = [NSTemporaryDirectory() stringByAppendingPathComponent:
            [NSString stringWithFormat:@"OKLockTests-%@", [[NSUUID UUID] UUIDString]]];
    _path = [_dir stringByAppendingPathComponent:OKSingleInstanceLockFileName];
    [[NSFileManager defaultManager] createDirectoryAtPath:_dir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
}

- (void)tearDown {
    [OKSingleInstanceLock releaseLock];
    [[NSFileManager defaultManager] removeItemAtPath:_dir error:NULL];
    [super tearDown];
}

/// Stands in for a second OpenKey process: an independent open + flock on the
/// same file, which is exactly what a second instance would do.
- (int)openAndLockForeignHolder {
    int fd = open(_path.fileSystemRepresentation, O_CREAT | O_RDWR, 0644);
    XCTAssertGreaterThanOrEqual(fd, 0, @"could not open lock file for the stand-in holder");
    XCTAssertEqual(flock(fd, LOCK_EX | LOCK_NB), 0, @"stand-in holder should get the lock");
    return fd;
}

#pragma mark - acquire

- (void)testAcquireSucceedsOnFreshPath {
    XCTAssertTrue([OKSingleInstanceLock acquireAtPath:_path]);
    XCTAssertTrue([OKSingleInstanceLock isLocked]);
}

- (void)testAcquireCreatesMissingParentDirectories {
    NSString *nested = [[_dir stringByAppendingPathComponent:@"a/b/c"]
                        stringByAppendingPathComponent:OKSingleInstanceLockFileName];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:nested]);

    XCTAssertTrue([OKSingleInstanceLock acquireAtPath:nested]);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:nested]);
}

- (void)testAcquireWritesOwningPid {
    XCTAssertTrue([OKSingleInstanceLock acquireAtPath:_path]);

    NSString *contents = [NSString stringWithContentsOfFile:_path
                                                   encoding:NSUTF8StringEncoding
                                                      error:NULL];
    XCTAssertEqual([contents integerValue], (NSInteger)getpid());
}

#pragma mark - mutual exclusion

- (void)testAcquireFailsWhileAnotherHolderOwnsTheFile {
    int foreign = [self openAndLockForeignHolder];

    XCTAssertFalse([OKSingleInstanceLock acquireAtPath:_path],
                   @"a second instance for the same user must not get the lock");
    XCTAssertFalse([OKSingleInstanceLock isLocked]);

    close(foreign);
}

- (void)testHeldLockBlocksAnotherHolder {
    XCTAssertTrue([OKSingleInstanceLock acquireAtPath:_path]);

    int fd = open(_path.fileSystemRepresentation, O_CREAT | O_RDWR, 0644);
    XCTAssertGreaterThanOrEqual(fd, 0);
    XCTAssertNotEqual(flock(fd, LOCK_EX | LOCK_NB), 0,
                      @"while we hold the lock nobody else may take it");
    close(fd);
}

/// Two mac users get two different paths, so they never contend. This is the
/// property that makes Fast User Switching work.
- (void)testDifferentPathsDoNotContend {
    NSString *otherUserPath = [[_dir stringByAppendingPathComponent:@"other-user"]
                               stringByAppendingPathComponent:OKSingleInstanceLockFileName];

    int foreign = [self openAndLockForeignHolder];      // "user A" holds _path
    XCTAssertTrue([OKSingleInstanceLock acquireAtPath:otherUserPath],
                  @"another mac user's instance must still start");
    close(foreign);
}

#pragma mark - release

- (void)testAcquireSucceedsAgainAfterRelease {
    XCTAssertTrue([OKSingleInstanceLock acquireAtPath:_path]);
    [OKSingleInstanceLock releaseLock];
    XCTAssertFalse([OKSingleInstanceLock isLocked]);

    XCTAssertTrue([OKSingleInstanceLock acquireAtPath:_path]);
}

- (void)testReleaseWithoutAcquireIsSafe {
    XCTAssertNoThrow([OKSingleInstanceLock releaseLock]);
    XCTAssertFalse([OKSingleInstanceLock isLocked]);
}

- (void)testReleaseFreesTheFileForAnotherHolder {
    XCTAssertTrue([OKSingleInstanceLock acquireAtPath:_path]);
    [OKSingleInstanceLock releaseLock];

    int fd = [self openAndLockForeignHolder];
    close(fd);
}

#pragma mark - bad input

- (void)testAcquireFailsCleanlyOnUnwritablePath {
    XCTAssertFalse([OKSingleInstanceLock acquireAtPath:@"/System/no-such-dir/instance.lock"]);
    XCTAssertFalse([OKSingleInstanceLock isLocked]);
}

- (void)testAcquireFailsCleanlyOnEmptyPath {
    XCTAssertFalse([OKSingleInstanceLock acquireAtPath:@""]);
    XCTAssertFalse([OKSingleInstanceLock isLocked]);
}

@end
