//
//  OKLayoutRemap.h
//  LibreKey
//
//  The engine names keys after their place on a US keyboard. On AZERTY the key
//  printed w sits where US has z, on QWERTZ y and z trade places, on Dvorak
//  nearly every letter moves - so without help a Telex w there is read as a z.
//  This maps each key to the US key of the character it types, for letters and
//  the unshifted US punctuation only: a key typing anything else (é, &, ü) is
//  left where it is, as before. Pure model: the host reads the layout.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OKLayoutRemap : NSObject

//Whether every key stays where it is, as on US, ABC or British.
@property (nonatomic, readonly) BOOL isIdentity;

//Input: the character each key of the main block types with no modifier on
//the current layout, by virtual key code. Keys outside the main block (keypad,
//function keys, Return, Tab, Space) are ignored.
+ (OKLayoutRemap*)remapForCharacters:(NSDictionary<NSNumber*, NSString*>*)charactersByKeyCode;

//Output: the US key code the engine should see for a key.
- (uint16_t)usKeyCodeFor:(uint16_t)keyCode;

@end

NS_ASSUME_NONNULL_END
