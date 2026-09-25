//
//  OKTerminalTyping.h
//  LibreKey
//
//  How a correction is posted when the app in front is a terminal.
//  Pure model: no globals, no events posted, so it can be unit tested.
//
//  In a terminal the correction is not applied by the terminal itself but by
//  whatever reads the line on the other end - a shell, an editor, a TUI, often
//  over SSH. The bytes reach it split and merged however the network pleases,
//  so the tricks that help GUI text fields only give it more ways to fall out
//  of step with the engine.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//Where the keystroke is going, as far as the event tap can tell.
@interface OKTypingTarget : NSObject

@property (nonatomic, copy, readonly, nullable) NSString* bundleId;
//Spotlight takes the keyboard without becoming the front app, so a terminal can
//be in front while the user is really typing into Spotlight.
@property (nonatomic, readonly) BOOL spotlightVisible;
//The focused element is the terminal panel of a code editor (VS Code and its
//forks), which the bundle id alone cannot tell from the editor pane.
@property (nonatomic, readonly) BOOL integratedTerminal;

- (instancetype)initWithBundleId:(nullable NSString*)bundleId
                spotlightVisible:(BOOL)spotlightVisible;
- (instancetype)initWithBundleId:(nullable NSString*)bundleId
                spotlightVisible:(BOOL)spotlightVisible
              integratedTerminal:(BOOL)integratedTerminal;

@end

//How to post the correction to that target.
@interface OKTypingPlan : NSObject

//NO means never send the empty character or the Chromium selection, whatever
//the fix autocomplete setting says.
@property (nonatomic, readonly) BOOL allowsAutocompleteWorkaround;
//YES means every character goes in a key event of its own, instead of the whole
//replacement in one.
@property (nonatomic, readonly) BOOL oneCharacterPerEvent;
//YES means that once a word has had a correction, the keys after it are posted
//by LibreKey too instead of passing on their own: a terminal (or its pty, or an
//xterm.js renderer) can let a real key overtake synthetic ones still queued.
@property (nonatomic, readonly) BOOL syntheticLockstep;

- (instancetype)initWithAllowsAutocompleteWorkaround:(BOOL)allowsAutocompleteWorkaround
                                oneCharacterPerEvent:(BOOL)oneCharacterPerEvent
                                   syntheticLockstep:(BOOL)syntheticLockstep;

@end

@interface OKTerminalTyping : NSObject

//Whether the bundle id belongs to a known terminal emulator. nil never does.
+ (BOOL)isTerminalBundleId:(nullable NSString*)bundleId;

//Whether the bundle id is a code editor with a terminal panel - VS Code, its
//Insiders build and forks (VSCodium, Cursor, Windsurf). Only for these is the
//focused element worth asking about.
+ (BOOL)isCodeEditorBundleId:(nullable NSString*)bundleId;

//Whether the Accessibility description of the focused element is the input of
//such a terminal panel: xterm.js labels it "Terminal 1, zsh ...".
+ (BOOL)isIntegratedTerminalDescription:(nullable NSString*)description;

+ (OKTypingPlan*)planForTarget:(OKTypingTarget*)target;

@end

NS_ASSUME_NONNULL_END
