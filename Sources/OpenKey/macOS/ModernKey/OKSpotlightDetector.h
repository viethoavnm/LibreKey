//
//  OKSpotlightDetector.h
//  LibreKey
//
//  Whether Spotlight is up. Spotlight takes the keyboard without becoming the
//  front app, so the only way to tell is the window list - which takes about
//  half a millisecond to read, and was read twice for every correction typed.
//  Pure model: no window server calls, the host feeds it the list and the time.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OKSpotlightDetector : NSObject

//Input: a CGWindowListCopyWindowInfo result. Output: whether it shows Spotlight
//up - a window Spotlight owns that is drawn (alpha > 0) above normal windows
//(layer > 0). A dismissed Spotlight stays in the list while it fades out, and
//counting it made corrections go the Spotlight way in the next app.
+ (BOOL)windowListShowsSpotlight:(NSArray<NSDictionary*>*)windows;

//The last answer, kept for `lifetime` seconds so most corrections need no
//window list at all. The host drops it early on the events that can open or
//close Spotlight: modifier changes (Cmd+Space), Esc, Return and clicks.
- (instancetype)initWithLifetime:(NSTimeInterval)lifetime;

@property (nonatomic, readonly) BOOL answer;

- (BOOL)hasAnswerAt:(NSTimeInterval)now;
- (void)storeAnswer:(BOOL)answer at:(NSTimeInterval)now;
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
