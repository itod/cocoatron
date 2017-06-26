//
//  CocoatronParamsTableAction.h
//  Transform XML Documents
//
//  Created by Todd Ditchendorf on 11/21/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "CocoatronAction.h"

@interface CocoatronParamsTableAction : CocoatronAction {
	IBOutlet NSTableView *paramsTable;
	NSMutableDictionary *params;
	NSMutableArray *paramsOrder;
	int lastClickedCol;	
}
- (IBAction)insertParam:(id)sender;
- (IBAction)removeParam:(id)sender;

- (void)handleTableClicked:(id)sender;
- (void)handleTextChanged:(id)sender;

- (void)insertParamAtIndex:(int)index;
- (void)removeParamAtIndex:(int)index;

- (void)setupParamsTable;
- (void)registerForNotifications;

- (NSImage *)plusImage;
- (NSImage *)minusImage;
- (NSTextFieldCell *)textFieldCellWithTag:(int)tag;
- (void)windowDidResize:(NSNotification *)aNotification;
- (BOOL)paramsAreEmpty;

- (NSMutableDictionary *)params;
- (void)setParams:(NSMutableDictionary *)newParams;
- (NSMutableArray *)paramsOrder;
- (void)setParamsOrder:(NSMutableArray *)newOrder;
@end
