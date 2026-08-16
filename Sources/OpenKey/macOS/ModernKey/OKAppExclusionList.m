//
//  OKAppExclusionList.m
//  LibreKey
//

#import "OKAppExclusionList.h"

NSString* const OKAppExclusionDefaultsKey = @"vExcludedApps";

static NSString* const kBundleIdKey = @"bundleId";
static NSString* const kNameKey = @"name";

@implementation OKAppExclusionEntry

- (instancetype)initWithBundleId:(NSString*)bundleId name:(NSString*)name {
    self = [super init];
    if (self) {
        _bundleId = [bundleId copy];
        _name = [name copy];
    }
    return self;
}

+ (nullable instancetype)entryFromDictionary:(NSDictionary*)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]])
        return nil;

    id bundleId = dictionary[kBundleIdKey];
    if (![bundleId isKindOfClass:[NSString class]] || [bundleId length] == 0)
        return nil;

    //The name is only ever shown, so a missing one is not worth dropping the
    //entry over - fall back to the bundle id.
    id name = dictionary[kNameKey];
    if (![name isKindOfClass:[NSString class]] || [name length] == 0)
        name = bundleId;

    return [[self alloc] initWithBundleId:bundleId name:name];
}

- (NSDictionary*)dictionaryValue {
    return @{kBundleIdKey: self.bundleId, kNameKey: self.name};
}

@end

@implementation OKAppExclusionList

+ (NSArray<OKAppExclusionEntry*>*)entriesFromDefaults:(NSUserDefaults*)defaults {
    id stored = [defaults objectForKey:OKAppExclusionDefaultsKey];
    if (![stored isKindOfClass:[NSArray class]])
        return @[];

    NSMutableArray<OKAppExclusionEntry*>* entries = [NSMutableArray array];
    for (id item in (NSArray*)stored) {
        OKAppExclusionEntry* entry = [OKAppExclusionEntry entryFromDictionary:item];
        if (entry)
            [entries addObject:entry];
    }
    return entries;
}

+ (void)writeEntries:(NSArray<OKAppExclusionEntry*>*)entries
          toDefaults:(NSUserDefaults*)defaults {
    NSMutableArray<NSDictionary*>* stored = [NSMutableArray arrayWithCapacity:entries.count];
    for (OKAppExclusionEntry* entry in entries) {
        [stored addObject:[entry dictionaryValue]];
    }
    [defaults setObject:stored forKey:OKAppExclusionDefaultsKey];
}

+ (BOOL)entries:(NSArray<OKAppExclusionEntry*>*)entries
containBundleId:(nullable NSString*)bundleId {
    if (bundleId.length == 0)
        return NO;

    for (OKAppExclusionEntry* entry in entries) {
        //Exact match on purpose: a prefix test would turn one excluded app into
        //a whole vendor's worth of them.
        if ([entry.bundleId isEqualToString:bundleId])
            return YES;
    }
    return NO;
}

+ (NSArray<OKAppExclusionEntry*>*)entries:(NSArray<OKAppExclusionEntry*>*)entries
                            byAddingEntry:(OKAppExclusionEntry*)entry {
    if (entry.bundleId.length == 0 || [self entries:entries containBundleId:entry.bundleId])
        return entries;

    return [entries arrayByAddingObject:entry];
}

+ (NSArray<OKAppExclusionEntry*>*)entries:(NSArray<OKAppExclusionEntry*>*)entries
                        byRemovingIndexes:(NSIndexSet*)indexes {
    NSMutableArray<OKAppExclusionEntry*>* left = [NSMutableArray arrayWithCapacity:entries.count];
    [entries enumerateObjectsUsingBlock:^(OKAppExclusionEntry* entry, NSUInteger index, BOOL* stop) {
        if (![indexes containsIndex:index])
            [left addObject:entry];
    }];
    return left;
}

+ (nullable OKAppExclusionEntry*)entryForApplicationAtURL:(NSURL*)url {
    NSBundle* bundle = [NSBundle bundleWithURL:url];
    NSString* bundleId = bundle.bundleIdentifier;
    if (bundleId.length == 0)
        return nil;

    //Prefer what Finder shows over the raw folder name.
    NSString* name = [[NSFileManager defaultManager] displayNameAtPath:url.path];
    if (name.length == 0)
        name = bundle.infoDictionary[@"CFBundleName"];
    if (name.length == 0)
        name = bundleId;

    return [[OKAppExclusionEntry alloc] initWithBundleId:bundleId name:name];
}

@end
