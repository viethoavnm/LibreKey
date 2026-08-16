//
//  OKSingleInstanceLock.h
//  OpenKey
//
//  Keeps exactly one OpenKey instance alive *per mac user*.
//
//  The lock file lives inside the calling user's own Application Support folder,
//  so the "one instance" scope is per-user by construction: two different mac
//  users hold two different files and never see each other. That is what makes
//  Fast User Switching work, and it is why this replaced the old scan over
//  -[NSWorkspace runningApplications], which could not express "this user only"
//  and was a check-then-act race besides.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OKSingleInstanceLock : NSObject

/// Name of the lock file. Callers join this onto the current user's OpenKey
/// Application Support folder (+[OpenKeyManager getApplicationSupportFolder]);
/// this class deliberately takes a plain path so it stays dependency-free and
/// unit-testable.
extern NSString * const OKSingleInstanceLockFileName;

/// Tries to take the lock at `path`, creating the file and any missing parent
/// directories. Returns YES when this process now owns the lock, NO when another
/// live process in the same user session already holds it (or the path is
/// unusable). The lock is held until -releaseLock or process exit; the kernel
/// drops it automatically if the process crashes.
+ (BOOL)acquireAtPath:(NSString *)path;

/// Releases a lock taken by +acquireAtPath:. No-op when nothing is held.
+ (void)releaseLock;

/// YES while this process owns the lock.
+ (BOOL)isLocked;

@end

NS_ASSUME_NONNULL_END
