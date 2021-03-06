#import "Tweak.h"

%hook PSListController

NSArray *map;
NSInteger count, cellularSectionNumber;
BOOL enabled = YES;

- (NSInteger)numberOfSectionsInTableView:(id)view {
    NSInteger result = %orig;
    if ([[self specifier].identifier isEqualToString:@"MOBILE_DATA_SETTINGS_ID"]) {
        if (result > 2 && ![self tableView:view titleForHeaderInSection:result - 2])
            cellularSectionNumber = result - 3;
        else
            cellularSectionNumber = result - 2;
    }
    return result;
}

- (NSInteger)tableView:(id)view numberOfRowsInSection:(NSInteger)section {
    NSInteger result = %orig;
    if ([[self specifier].identifier isEqualToString:@"MOBILE_DATA_SETTINGS_ID"] && section == cellularSectionNumber) {
        count = 0;
        if (result > 1) {
            NSInteger num;
            if ([[self tableView:view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:result - 2 inSection:section]] isKindOfClass:[%c(PSSubtitleSwitchTableCell) class]])
                num = result - 1;
            else
                num = result - 2;
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:num];
            for (NSInteger i = 0; i < num; i++) {
                NSString *sizeString = [self tableView:view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]].detailTextLabel.text;
                float size = [sizeString floatValue];
                NSInteger length = [sizeString length];
                if (length > 2)
                    switch ([sizeString characterAtIndex:length - 2]) {
                        case 'M':
                            size *= 1024;
                            break;
                        case 'G':
                            size *= 1024 * 1024;
                            break;
                        case 'T':
                            size *= 1024 * 1024 * 1024;
                    }
                if (length > 3) {
                    switch ([sizeString characterAtIndex:length - 3]) {
                        case L'מ':
                            size *= 1024;
                            break;
                        case L'ג':
                            size *= 1024 * 1024;
                    }
                }
                [data addObject:[[Entry alloc] initWithIndex:i data:@(size)]];
            }
            map = [data sortedArrayUsingComparator:^NSComparisonResult(Entry *a, Entry *b) {
                return [b.data compare: a.data];
            }];
            count = num;
        }
    }
    return result;
}

- (id)tableView:(id)view cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (enabled && indexPath.row < count && [[self specifier].identifier isEqualToString:@"MOBILE_DATA_SETTINGS_ID"] && indexPath.section == cellularSectionNumber)
        return %orig(view, [NSIndexPath indexPathForRow:((Entry *)map[indexPath.row]).index inSection:indexPath.section]);
    else
        return %orig;
}

- (void)tableView:(id)view didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[self specifier].identifier isEqualToString:@"MOBILE_DATA_SETTINGS_ID"] && indexPath.section == cellularSectionNumber - 1) {
        enabled = !enabled;
        [view reloadData];
    }
    %orig;
}

%end
