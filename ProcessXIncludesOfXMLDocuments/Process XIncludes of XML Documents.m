//
//  Process XIncludes of XML Documents.m
//  Process XIncludes of XML Documents
//
//  Created by Todd Ditchendorf on 11/21/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "Process XIncludes of XML Documents.h"
#import "XmlDocPtrWrapper.h"

@interface Process_XIncludes_of_XML_Documents (Private)
- (int)currentOptions;
@end

static NSString *const KeyRemoveXIncludeNodes	= @"removeXIncludeNodes";

@implementation Process_XIncludes_of_XML_Documents

#pragma mark -
#pragma mark AMBundleAction

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	NSArray *inputArray;
	
	//NSLog(@"input  : %@", input);
	//NSLog(@"parameters: %@", [self parameters]);
	
	inputArray = [self arrayForInput:input];
	
	[self setErrorString:[NSMutableString string]];
	[self setConsoleString];
	
	// register well-formedness & validity error handlers
	xmlSetGenericErrorFunc((void *)self, (xmlGenericErrorFunc)myGenericErrorFunc);
		
	NSEnumerator *e = [input objectEnumerator];

	XmlDocPtrWrapper *wrapper;
	xmlDocPtr docPtr;

	while (wrapper = [e nextObject]) {

		docPtr = [wrapper docPtr];
		xmlXIncludeProcess(docPtr);
		
		if ([errorString length]) {
			NSLog(@"Cocoatron 'Process XIncludes of XML Documents' Error: %@", errorString);
			(*errorInfo) = [self dictionaryWithErrorNumber:-1 message:errorString];
			[self setConsoleString];
		}
		
		//NSLog(@"errorInfo: %@", *errorInfo);
	}
	return input;
}


#pragma mark -
#pragma mark Private

- (int)currentOptions;
{
	NSDictionary *params = [self parameters];
	
	int opts = XML_PARSE_XINCLUDE; //XML_PARSE_PEDANTIC;
	
	if ([[params objectForKey:KeyRemoveXIncludeNodes] boolValue])
		opts = (opts|XML_PARSE_NOXINCNODE);
	
	return opts;
}


#pragma mark -
#pragma mark Accessors

- (float)smallHeight;
{
	return 97.;
}


- (float)bigHeight;
{
	return 181.;
}

@end
