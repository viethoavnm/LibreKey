//
//  OKSingleInstanceLock.m
//  OpenKey
//

#import "OKSingleInstanceLock.h"

#include <sys/file.h>
#include <fcntl.h>
#include <unistd.h>

NSString * const OKSingleInstanceLockFileName = @"instance.lock";

//Held for the lifetime of the process. flock() is tied to the open file
//description, so the kernel releases it even if we crash - no stale lock files.
static int _lockFD = -1;

@implementation OKSingleInstanceLock

+ (BOOL)acquireAtPath:(NSString *)path {
    if (path.length == 0)
        return NO;

    NSString *dir = [path stringByDeletingLastPathComponent];
    if (dir.length > 0 &&
        ![[NSFileManager defaultManager] createDirectoryAtPath:dir
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:NULL]) {
        return NO;
    }

    int fd = open(path.fileSystemRepresentation, O_CREAT | O_RDWR | O_CLOEXEC, 0644);
    if (fd < 0)
        return NO;

    //LOCK_NB: never block. Failure here means another OpenKey instance for this
    //same mac user is alive and holding the file.
    if (flock(fd, LOCK_EX | LOCK_NB) != 0) {
        close(fd);
        return NO;
    }

    //Record the owning pid. Purely diagnostic - the flock is what enforces.
    const char *pid = [[NSString stringWithFormat:@"%d\n", getpid()] UTF8String];
    if (ftruncate(fd, 0) == 0)
        (void)write(fd, pid, strlen(pid));

    if (_lockFD >= 0)
        close(_lockFD);
    _lockFD = fd;
    return YES;
}

+ (void)releaseLock {
    if (_lockFD < 0)
        return;
    flock(_lockFD, LOCK_UN);
    close(_lockFD);
    _lockFD = -1;
}

+ (BOOL)isLocked {
    return _lockFD >= 0;
}

@end
