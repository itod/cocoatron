//
//  Query XML Documents.m
//  Query XML Documents
//
//  Created by Todd Ditchendorf on 11/21/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "Query XML Documents.h"
#import "XmlDocPtrWrapper.h"

static NSString *const KeyQueryURLString  = @"queryURLString";
static NSString *const WhiteSpace		  = @" ";

@interface Query_XML_Documents (Private)
- (XmlDocPtrWrapper *)query:(XmlDocPtrWrapper *)wrapper params:(NSDictionary *)args error:(NSDictionary **)errorInfo;
- (NSXMLDocument *)cocoaDocForWrapper:(XmlDocPtrWrapper *)wrapper;
- (NSString *)fetchXQuery;
- (NSDictionary *)constants;
- (BOOL)isQuotedString:(NSString *)str;
- (NSMutableString *)removeQuotes:(NSMutableString *)str;
- (NSXMLElement *)cocoatronResultElement;
- (NSXMLElement *)cocoatronItemElement;
@end

@implementation Query_XML_Documents

#pragma mark -

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

- (IBAction)browse:(id)sender;
{	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	int result = [openPanel runModalForDirectory:nil file:nil types:nil];
	
	if (NSOKButton == result) {
		[[self parameters] setObject:[openPanel filename] forKey:KeyQueryURLString];
	}
}


#pragma mark -
#pragma mark AMBundleAction

- (void)opened;
{
	[super opened];
}


- (void)writeToDictionary:(NSMutableDictionary *)dict;
{
	[super writeToDictionary:dict];
}


- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	NSArray *inputArray;
	
	//NSLog(@"input  : %@", input);
	//NSLog(@"parameters: %@", [self parameters]);
	
	inputArray = [self arrayForInput:input];
	
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[inputArray count]];
	
	[self setErrorString:[NSMutableString string]];
	[self setConsoleString];
	
	NSEnumerator *e = [input objectEnumerator];
	XmlDocPtrWrapper *wrapper;
	XmlDocPtrWrapper *newWrapper;
	while (wrapper = [e nextObject]) {
		
		newWrapper = [self query:wrapper params:nil error:errorInfo];
		
		if ([errorString length]) {
			NSLog(@"Cocoatron 'Query XML Documents' Error: %@", errorString);
			(*errorInfo) = [self dictionaryWithErrorNumber:-1 message:errorString];
			[self setConsoleString];
		}
		
		NSLog(@"errorInfo: %@", *errorInfo);
		
		if (!newWrapper) { // parsing one of the files was not possible. errorInfo is already populated.
			return result;
		}
		
		[result addObject:newWrapper];
	}
	
	return result;
}


#pragma mark -
#pragma mark Private

- (XmlDocPtrWrapper *)query:(XmlDocPtrWrapper *)wrapper params:(NSDictionary *)args error:(NSDictionary **)errorInfo;
{
	NSXMLDocument *doc = [self cocoaDocForWrapper:wrapper];
	
	if (!doc) {
		return nil;
	}

	NSString *xquery = [self fetchXQuery];
	
	NSError *err = nil;
	
	NSArray *resArray = [doc objectsForXQuery:xquery constants:[self constants] error:&err];

	if (err) {
		[self appendErrorString:[err localizedDescription]];
	}
	
	int count = [resArray count];

	if (!count) {
		return nil;
	}	
	
	NSXMLDocument *resDoc = nil;
	
	@try {
		if (1 == count) {
			id obj = [resArray objectAtIndex:0];
			
			// NSXMLDocument
			if ([obj isKindOfClass:[NSXMLDocument class]]) { 
				resDoc = obj;
				
				// NSXMLElement
			} else if ([obj isKindOfClass:[NSXMLElement class]]) {
				resDoc = [[[NSXMLDocument alloc] initWithRootElement:obj] autorelease];
				
				// NXMLNode -- Attribute node
			} else if ([obj isKindOfClass:[NSXMLNode class]] && NSXMLAttributeKind == [obj kind]) {
				NSXMLElement *root = [self cocoatronResultElement];
				[root addAttribute:obj];
				resDoc = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
				
				// NXMLNode -- Namespace node
			} else if ([obj isKindOfClass:[NSXMLNode class]] && NSXMLNamespaceKind == [obj kind]) {
				NSXMLElement *root = [self cocoatronResultElement];
				[root addNamespace:obj];
				resDoc = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
				
				// NSString
			} else if ([obj isKindOfClass:[NSString class]]) {
				NSXMLElement *root = [self cocoatronResultElement];
				[root setStringValue:obj];
				resDoc = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
				
				// id
			} else {
				NSXMLElement *root = [self cocoatronResultElement];
				[root setStringValue:[obj description]];
				resDoc = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
			}	
			
		} else {
			NSXMLElement *root = [self cocoatronResultElement];
			id obj;
			NSXMLElement *itemEl;
			NSEnumerator *e = [resArray objectEnumerator];
			
			while (obj = [e nextObject]) {
				
				itemEl = [self cocoatronItemElement];
				
				// NSXMLDocument
				if ([obj isKindOfClass:[NSXMLDocument class]]) { 
					int len = [[obj children] count];
					NSMutableArray *children = [NSMutableArray arrayWithCapacity:len];
					NSXMLNode *child;
					int i;
					for (i = len -1; i >= 0; i--) {
						child = [obj childAtIndex:i];
						[obj removeChildAtIndex:i];
						[children addObject:child];
					}
					
					NSEnumerator *e2 = [children reverseObjectEnumerator];
					while (child = [e2 nextObject]) {
						[itemEl addChild:child];
					}
					
					// NSXMLElement
				} else if ([obj isKindOfClass:[NSXMLElement class]]) {
					[itemEl addChild:obj];
					
					// NXMLNode -- Attribute node
				} else if ([obj isKindOfClass:[NSXMLNode class]] && NSXMLAttributeKind == [obj kind]) {
					[itemEl addAttribute:obj];
					
					// NXMLNode -- Namespace node
				} else if ([obj isKindOfClass:[NSXMLNode class]] && NSXMLNamespaceKind == [obj kind]) {
					[itemEl addNamespace:obj];
					
					// NSString
				} else if ([obj isKindOfClass:[NSString class]]) {
					[itemEl setStringValue:obj];
					
					// id
				} else {
					[itemEl setStringValue:[obj description]];
				}			
				
				[root addChild:itemEl];
				
			}
			resDoc = [[[NSXMLDocument alloc] initWithRootElement:root] autorelease];
		} 
	}
	@catch (NSException *e) {
		[self appendErrorString:[e reason]];
		return wrapper;
	}

	NSString *resStr = [resDoc XMLString];

	xmlDocPtr resDocPtr = xmlParseMemory((const char *)[resStr UTF8String], [resStr length]);

	XmlDocPtrWrapper *newWrapper = [[[XmlDocPtrWrapper alloc] initWithDocPtr:resDocPtr] autorelease];
	return newWrapper;
}


- (NSXMLDocument *)cocoaDocForWrapper:(XmlDocPtrWrapper *)wrapper;
{
	NSString *xmlString = [wrapper description];

	NSError *err = nil;
	
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xmlString 
														   options:nil 
															 error:&err] autorelease];
	if (err) {
		[self appendErrorString:[err localizedDescription]];
	}

	return doc;
}


- (NSString *)fetchXQuery;
{
	NSString *path = [[self parameters] objectForKey:KeyQueryURLString];
	
	NSString *xquery;
	
	if ([self isFilePath:path]) {
		xquery = [NSString stringWithContentsOfFile:path];
	} else {
		xquery = [NSString stringWithContentsOfURL:[NSURL URLWithString:path]];
	}
	
	return xquery;
}


- (NSDictionary *)constants;
{
	NSMutableDictionary *res = [NSMutableDictionary dictionaryWithCapacity:[params count]];
	NSString *key;
	NSMutableString *val;
	NSEnumerator *e = [params keyEnumerator];
	while (key = [e nextObject]) {
		val = [NSMutableString stringWithString:[params objectForKey:key]];
		if ([self isQuotedString:val]) {
			val = [self removeQuotes:val];
		}
		[res setObject:val forKey:key];
	}
	return res;
}


- (BOOL)isQuotedString:(NSString *)str;
{
	return ([str hasPrefix:@"'"] && [str hasSuffix:@"'"]) 
		|| ([str hasPrefix:@"\""] && [str hasSuffix:@"\""]);
}


- (NSMutableString *)removeQuotes:(NSMutableString *)str;
{
	[str replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
	int len = [str length];
	[str replaceCharactersInRange:NSMakeRange(len-1, 1) withString:@""];
	return str;
}


- (NSXMLElement *)cocoatronResultElement;
{
	NSXMLElement *el = [NSXMLNode elementWithName:@"cocoatron:result" URI:@"http://cocoatron.com/ns/result"];
	NSXMLNode *ns = [NSXMLNode namespaceWithName:@"cocoatron" stringValue:@"http://cocoatron.com/ns/result"];
	[el addNamespace:ns];
	return el;
}


- (NSXMLElement *)cocoatronItemElement;
{
	NSXMLElement *el = [NSXMLNode elementWithName:@"cocoatron:item" URI:@"http://cocoatron.com/ns/result"];
	return el;
}

@end
