//
//  CocoatronAction.m
//  Load XML Documents
//
//  Created by Todd Ditchendorf on 11/21/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "CocoatronAction.h"
#import "XmlDocPtrWrapper.h"
#import <OSAKit/OSAKit.h>

static NSString *const KeyShowConsole = @"showConsole";

void myGenericErrorFunc(id self, const char *msg, ...)
{
	va_list vargs;
	va_start(vargs, msg);
	
	NSString *format = [NSString stringWithUTF8String:msg];
	NSMutableString *str = [[[NSMutableString alloc] initWithFormat:format arguments:vargs] autorelease];
	
	[self appendErrorString:str];
	
	va_end(vargs);
}


@implementation CocoatronAction

- (id)initWithDefinition:(NSDictionary *)dict fromArchive:(BOOL)archived;
{
	self = [super initWithDefinition:dict fromArchive:archived];
	if (self != nil) {
		[self setShowConsole:[[dict objectForKey:KeyShowConsole] boolValue]];
	}
	return self;
}


- (void)dealloc;
{
	[self setErrorString:nil];
	[super dealloc];
}


#pragma mark -
#pragma mark AMBundleAction

- (void)opened;
{
	[super opened];
	BOOL grow = showConsole;
	[self resize:grow];	
	[self setupFonts];
}


- (void)writeToDictionary:(NSMutableDictionary *)dict;
{
	[super writeToDictionary:dict];
	[dict setObject:[NSNumber numberWithBool:showConsole] forKey:KeyShowConsole];
}


- (void)reset;
{
	NSLog(@"reset");
}


#pragma mark -
#pragma mark Public

- (NSArray *)arrayForInput:(id)input;
{
	if (![input isKindOfClass:[NSArray class]]) {
		input = [NSArray arrayWithObject:input];
	} 
	return input;
}


- (void)setupFonts;
{
	NSFont *monaco = [NSFont fontWithName:@"Monaco" size:10.];
	[console setFont:monaco];
}


- (void)appendErrorString:(NSString *)str;
{
	[errorString appendString:str];
}


- (void)setConsoleString;
{
	[console performSelectorOnMainThread:@selector(setString:)
							  withObject:[self errorString]
						   waitUntilDone:NO];
}


- (void)resize:(BOOL)grow;
{
	NSSize s = NSMakeSize(520, (grow ? [self bigHeight] : [self smallHeight]));
	NSView *v = [[self view] superview];
	[v setFrameSize:s];
	[v setNeedsDisplay:YES];
	[[self view] setNeedsDisplay:YES];
	[console setNeedsDisplay:YES];	
}


- (NSMutableDictionary *)dictionaryWithErrorNumber:(int)num message:(NSString *)msg;
{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:num], OSAScriptErrorNumber,
		msg, OSAScriptErrorMessage,
		nil];	
}


- (BOOL)isFilePath:(id)obj;
{
	return [obj isKindOfClass:[NSString class]] && ([obj hasPrefix:@"/"] || [obj hasPrefix:@"file://"]);
}


#pragma mark -
#pragma mark Accessors

- (float)smallHeight;
{
	return 142.;
}


- (float)bigHeight;
{
	return 226.;
}


- (BOOL)showConsole;
{
	return showConsole;
}


- (void)setShowConsole:(BOOL)yn;
{
	showConsole = yn;
	BOOL grow = showConsole;
	[self resize:grow];
}


- (NSMutableString *)errorString;
{
	return errorString;
}


- (void)setErrorString:(NSMutableString *)newStr;
{
	if (errorString != newStr) {
		[errorString autorelease];
		errorString = [newStr retain];
	}
}

@end
