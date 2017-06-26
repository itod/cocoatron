//
//  CocoatronAction.h
//  Load XML Documents
//
//  Created by Todd Ditchendorf on 11/21/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/Automator.h>

void myGenericErrorFunc(id self, const char *msg, ...);

@interface CocoatronAction : AMBundleAction 
{
	IBOutlet NSTextView *console;	

	NSMutableString *errorString;
	BOOL showConsole;
}
- (NSArray *)arrayForInput:(id)input;

- (float)smallHeight;
- (float)bigHeight;

- (void)setupFonts;
- (void)appendErrorString:(NSString *)str;
- (void)setConsoleString;
- (void)resize:(BOOL)grow;
- (NSMutableDictionary *)dictionaryWithErrorNumber:(int)num message:(NSString *)msg;
- (BOOL)isFilePath:(id)obj;

- (BOOL)showConsole;
- (void)setShowConsole:(BOOL)yn;
- (NSMutableString *)errorString;
- (void)setErrorString:(NSMutableString *)newStr;

@end
