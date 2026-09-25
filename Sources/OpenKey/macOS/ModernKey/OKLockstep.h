//
//  OKLockstep.h
//  LibreKey
//
//  Which keys LibreKey must post itself so that they cannot overtake the
//  corrections it posted before them. Terminals (and the pty or xterm.js
//  renderer behind them) have been seen letting a real key through ahead of
//  synthetic ones still queued (VKey on Windows, PHTV on macOS). Once a word has
//  had a correction, every key the engine lets through is posted by LibreKey
//  in order - until the word ends and a short quiet time has passed. Pure model:
//  the host passes the time and the plan in.
//

#import <Foundation/Foundation.h>
#import "OKTerminalTyping.h"

NS_ASSUME_NONNULL_BEGIN

@interface OKLockstep : NSObject

//Input: how long after a correction a key still counts as close behind it.
- (instancetype)initWithWindow:(NSTimeInterval)window;

//A correction was just posted.
- (void)noteCorrectionPostedAt:(NSTimeInterval)now;

//The place in the text changed - a click, an app or language switch - so
//nothing typed before is still waiting.
- (void)reset;

//Input: a key the engine lets through. Output: whether LibreKey must post it.
//Yes when the plan asks for lockstep and the key is in a word that had a
//correction, or close behind one. A key that ends the word ends that state
//after it; a shortcut (Cmd, Ctrl, Option) is never re-posted and ends it too.
- (BOOL)shouldPostKeyAt:(NSTimeInterval)now
                   plan:(OKTypingPlan*)plan
               endsWord:(BOOL)endsWord
               shortcut:(BOOL)shortcut;

@end

NS_ASSUME_NONNULL_END
