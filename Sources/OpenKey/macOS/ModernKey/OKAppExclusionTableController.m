//
//  OKAppExclusionTableController.m
//  LibreKey
//

#import "OKAppExclusionTableController.h"

NSString* const OKAppExclusionColumnAppName = @"AppName";
NSString* const OKAppExclusionColumnBundleId = @"BundleId";

@implementation OKAppExclusionTableController {
    NSUserDefaults* _defaults;
}

- (instancetype)initWithDefaults:(NSUserDefaults*)defaults {
    self = [super init];
    if (self) {
        _defaults = defaults;
        _entries = [OKAppExclusionList entriesFromDefaults:defaults];
    }
    return self;
}

- (void)reload {
    _entries = [OKAppExclusionList entriesFromDefaults:_defaults];
    [self.tableView reloadData];
    [self updateRemoveButton];
}

//Every change goes through here: the event tap reads the defaults, so an edit
//that stops at the in-memory array would do nothing at all.
- (void)commitEntries:(NSArray<OKAppExclusionEntry*>*)entries {
    _entries = [entries copy];
    [OKAppExclusionList writeEntries:_entries toDefaults:_defaults];
    [self.tableView reloadData];
    [self updateRemoveButton];
}

- (BOOL)addApplicationAtURL:(NSURL*)url {
    OKAppExclusionEntry* entry = [OKAppExclusionList entryForApplicationAtURL:url];
    if (entry == nil)
        return NO;

    NSArray<OKAppExclusionEntry*>* updated = [OKAppExclusionList entries:self.entries byAddingEntry:entry];
    if (updated.count == self.entries.count)
        return NO; //already listed

    [self commitEntries:updated];
    return YES;
}

- (BOOL)removeEntriesAtIndexes:(NSIndexSet*)indexes {
    NSArray<OKAppExclusionEntry*>* updated = [OKAppExclusionList entries:self.entries byRemovingIndexes:indexes];
    if (updated.count == self.entries.count)
        return NO;

    [self commitEntries:updated];
    return YES;
}

- (nullable NSString*)textForColumnIdentifier:(NSString*)identifier row:(NSInteger)row {
    if (row < 0 || row >= (NSInteger)self.entries.count)
        return nil;

    OKAppExclusionEntry* entry = self.entries[row];
    if ([identifier isEqualToString:OKAppExclusionColumnAppName])
        return entry.name;
    if ([identifier isEqualToString:OKAppExclusionColumnBundleId])
        return entry.bundleId;
    return nil;
}

- (void)updateRemoveButton {
    self.removeButton.enabled = self.tableView.selectedRow >= 0;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView {
    return (NSInteger)self.entries.count;
}

#pragma mark - NSTableViewDelegate

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row {
    NSString* identifier = (NSString*)tableColumn.identifier;
    NSTableCellView* cell = [tableView makeViewWithIdentifier:identifier owner:self];
    cell.textField.stringValue = [self textForColumnIdentifier:identifier row:row] ?: @"";
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification*)notification {
    [self updateRemoveButton];
}

@end
