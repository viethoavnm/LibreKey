//
//  OKAppExclusionList.h
//  LibreKey
//
//  The list of applications the user does not want Vietnamese typing in.
//  Pure model: no UI, no globals, so it can be unit tested.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//NSUserDefaults key holding the excluded apps. Per mac user, like every other
//LibreKey setting.
extern NSString* const OKAppExclusionDefaultsKey;

//One excluded app. The bundle id is the identity - the name is carried along
//only so the table can show something a human recognises.
@interface OKAppExclusionEntry : NSObject

@property (nonatomic, copy, readonly) NSString* bundleId;
@property (nonatomic, copy, readonly) NSString* name;

- (instancetype)initWithBundleId:(NSString*)bundleId name:(NSString*)name;

//nil when the dictionary carries no usable bundle id.
+ (nullable instancetype)entryFromDictionary:(NSDictionary*)dictionary;
- (NSDictionary*)dictionaryValue;

@end

@interface OKAppExclusionList : NSObject

//Reads the stored list. Never nil - a missing or malformed value reads as empty.
+ (NSArray<OKAppExclusionEntry*>*)entriesFromDefaults:(NSUserDefaults*)defaults;

+ (void)writeEntries:(NSArray<OKAppExclusionEntry*>*)entries
          toDefaults:(NSUserDefaults*)defaults;

//The one question the event tap asks. A nil bundle id is never excluded.
+ (BOOL)entries:(NSArray<OKAppExclusionEntry*>*)entries
containBundleId:(nullable NSString*)bundleId;

//Returns the list unchanged when the bundle id is already in it.
+ (NSArray<OKAppExclusionEntry*>*)entries:(NSArray<OKAppExclusionEntry*>*)entries
                            byAddingEntry:(OKAppExclusionEntry*)entry;

+ (NSArray<OKAppExclusionEntry*>*)entries:(NSArray<OKAppExclusionEntry*>*)entries
                        byRemovingIndexes:(NSIndexSet*)indexes;

//Reads bundle id and display name out of an .app on disk. nil when the URL is
//not an application bundle or carries no bundle id.
+ (nullable OKAppExclusionEntry*)entryForApplicationAtURL:(NSURL*)url;

@end

NS_ASSUME_NONNULL_END
