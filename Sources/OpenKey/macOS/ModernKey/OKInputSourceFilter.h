//
//  OKInputSourceFilter.h
//  LibreKey
//
//  "Turn Vietnamese off when the system input source is not English": the
//  decision, from the languages the selected input source declares. Pure
//  model: the host reads the input source, only when it changes.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OKInputSourceFilter : NSObject

//Input: kTISPropertyInputSourceLanguages of the selected input source.
//Output: YES when keys must pass through untouched - the source declares
//languages and none of them is English (en, en-GB, ...). A source that
//declares nothing is left alone.
+ (BOOL)shouldBypassForLanguages:(nullable NSArray<NSString*>*)languages;

@end

NS_ASSUME_NONNULL_END
