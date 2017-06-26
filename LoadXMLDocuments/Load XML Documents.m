//
//  Load XML Documents.m
//  Load XML Documents
//
//  Created by Todd Ditchendorf on 8/15/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "Load XML Documents.h"
#import "XmlDocPtrWrapper.h"
#import <libxml/parser.h>
#import <libxml/xmlreader.h>

typedef enum {
	CheckboxTagLoadDTD = 0,
	CheckboxTagDefaultDTDAttrs,
	CheckboxTagSubstituteEntities,
	CheckboxTagMergeCDATA
} CheckboxTag;

static NSString *const KeyLoadDTD				= @"loadDTD";
static NSString *const KeyDefaultDTDAttrs		= @"defaultDTDAttrs";
static NSString *const KeyMergeCDATA			= @"mergeCDATA";
static NSString *const KeySubstituteEntities	= @"substituteEntities";

@interface Load_XML_Documents (Private)
- (int)currentOptions;
- (xmlDocPtr)parseXMLData:(NSData *)data baseURI:(NSString *)baseURI options:(int)opts error:(NSDictionary **)errorInfo;
- (NSMutableDictionary *)dictionaryWithErrorNumber:(int)num message:(NSString *)msg;
@end

@implementation Load_XML_Documents

- (id)initWithDefinition:(NSDictionary *)dict fromArchive:(BOOL)archived;
{
	self = [super initWithDefinition:dict fromArchive:archived];
	if (self != nil) {
	}
	return self;
}


- (void)dealloc;
{
	[super dealloc];
}


#pragma mark -
#pragma mark Actions


- (IBAction)parameterWasChanged:(id)sender;
{
	//NSLog(@"parameterWasChanged: %i boolval: %i", [sender tag], [sender state]);
	
	BOOL checked = (NSOnState == [sender state]);
	
	NSMutableDictionary *params = [self parameters];
	
	switch ([sender tag]) {
		
		case CheckboxTagLoadDTD:
			if (!checked) {
				[params setObject:[NSNumber numberWithBool:NO] forKey:KeyDefaultDTDAttrs];
				[params setObject:[NSNumber numberWithBool:NO] forKey:KeySubstituteEntities];
			}
			break;
		case CheckboxTagDefaultDTDAttrs:
			if (checked) {
				[params setObject:[NSNumber numberWithBool:YES] forKey:KeyLoadDTD];
			}
			break;
		case CheckboxTagSubstituteEntities:
			if (checked) {
				[params setObject:[NSNumber numberWithBool:YES] forKey:KeyLoadDTD];
			}
			break;
	}
}


#pragma mark -
#pragma mark AMAction

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{	
	NSArray *inputArray;
	
	NSLog(@"input  : %@", input);
	NSLog(@"parameters: %@", [self parameters]);
	
	inputArray = [self arrayForInput:input];

	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[inputArray count]];
	
	[self setErrorString:[NSMutableString string]];
	[self setConsoleString];

	int opts = [self currentOptions];
	
	NSEnumerator *e = [input objectEnumerator];
	id obj;
	XmlDocPtrWrapper *wrapper;
	xmlDocPtr docPtr;
	NSData *data;
	NSString *baseURI;
	while (obj = [e nextObject]) {
		if ([obj isKindOfClass:[NSURL class]]) {
			NSLog(@"found url:%@", obj);
			baseURI = [obj absoluteString];
			data = [NSData dataWithContentsOfURL:obj];
		} else if ([obj isKindOfClass:[NSData class]]) {
			NSLog(@"found data: %@", obj);
			baseURI = nil;
			data = obj;
		} else if ([self isFilePath:obj]) {
			baseURI = obj;
			data = [NSData dataWithContentsOfFile:baseURI];
			NSLog(@"found filepath:%@", obj);
		} else {
			baseURI = nil;
			data = [obj dataUsingEncoding:NSUTF8StringEncoding];
			NSLog(@"found xml string:%@", obj);
		}
		docPtr = [self parseXMLData:data baseURI:baseURI options:opts error:errorInfo];
		
		if ([errorString length]) {
			NSLog(@"Cocoatron 'Load XML Documents' Error: %@", errorString);
			(*errorInfo) = [self dictionaryWithErrorNumber:-1 message:errorString];
			[self setConsoleString];
		}
		
		//NSLog(@"errorInfo: %@", *errorInfo);

		if (!docPtr) { // parsing one of the files was not possible. errorInfo is already populated.
			return result;
		}
		
		wrapper = [[[XmlDocPtrWrapper alloc] initWithDocPtr:docPtr] autorelease];
		[wrapper setBaseURI:baseURI];
		[result addObject:wrapper];
	}

	return result;
}


#pragma mark -
#pragma mark Private

- (int)currentOptions;
{
	NSDictionary *params = [self parameters];
	
	int opts = 0; //XML_PARSE_PEDANTIC;
	
	if ([[params objectForKey:KeyLoadDTD] boolValue])
		opts = (opts|XML_PARSE_DTDLOAD);
	
	if ([[params objectForKey:KeyDefaultDTDAttrs] boolValue])
		opts = (opts|XML_PARSE_DTDATTR);
	
	if ([[params objectForKey:KeySubstituteEntities] boolValue])
		opts = (opts|XML_PARSE_NOENT);
	
	if ([[params objectForKey:KeyMergeCDATA] boolValue])
		opts = (opts|XML_PARSE_NOCDATA);
	
	return opts;
}


- (xmlDocPtr)parseXMLData:(NSData *)data baseURI:(NSString *)baseURI options:(int)opts error:(NSDictionary **)errorInfo;
{	
	xmlDocPtr doc = NULL;
	
	// register well-formedness & validity error handlers
	xmlSetGenericErrorFunc((void *)self, (xmlGenericErrorFunc)myGenericErrorFunc);

	doc = xmlReadMemory([data bytes], [data length], [baseURI UTF8String], NULL, opts);
	
	if (!doc) {
		return NULL;
	}

	return doc;
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

@end
