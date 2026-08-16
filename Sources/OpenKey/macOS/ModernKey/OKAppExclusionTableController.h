//
//  OKAppExclusionTableController.h
//  LibreKey
//
//  Drives the table in the "Loại trừ" tab. Owns the in-memory copy of the list
//  and writes every change straight back to NSUserDefaults, which is where the
//  event tap reads it from.
//

#import <Cocoa/Cocoa.h>
#import "OKAppExclusionList.h"

NS_ASSUME_NONNULL_BEGIN

//Table column identifiers, matching Main.storyboard.
extern NSString* const OKAppExclusionColumnAppName;
extern NSString* const OKAppExclusionColumnBundleId;

@interface OKAppExclusionTableController : NSObject <NSTableViewDataSource, NSTableViewDelegate>

//The table this controller drives. Optional, so the logic can be exercised
//without a live view.
@property (nonatomic, weak) NSTableView* tableView;

//Enabled only while a row is selected.
@property (nonatomic, weak) NSButton* removeButton;

@property (nonatomic, copy, readonly) NSArray<OKAppExclusionEntry*>* entries;

- (instancetype)initWithDefaults:(NSUserDefaults*)defaults;

//Re-reads the stored list and refreshes the table.
- (void)reload;

//NO when the URL is not an application, or when the app is already listed.
- (BOOL)addApplicationAtURL:(NSURL*)url;

//NO when nothing was removed.
- (BOOL)removeEntriesAtIndexes:(NSIndexSet*)indexes;

//The text one cell shows. Split out of the delegate so it can be tested
//without a live NSTableView. nil for an unknown column or an out of range row.
- (nullable NSString*)textForColumnIdentifier:(NSString*)identifier row:(NSInteger)row;

@end

NS_ASSUME_NONNULL_END
