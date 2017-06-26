//
//  XmlDocPtrWrapper.m
//  Load XML Documents
//
//  Created by Todd Ditchendorf on 11/15/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "XmlDocPtrWrapper.h"


@implementation XmlDocPtrWrapper

- (id)initWithDocPtr:(xmlDocPtr)ptr;
{
	self = [super init];
	if (self != nil) {
		[self setDocPtr:ptr];
	}
	return self;
}


- (void)dealloc;
{
	[self setDocPtr:NULL];
	[super dealloc];
}



- (NSString *)description;
{
	NSString *result = nil;
	if (!docPtr) {
		result = @"(null)";
	} else {
		int len;
		xmlChar *mem;
		//xmlDocDumpMemory(docPtr, &mem, &len);
		xmlDocDumpMemoryEnc(docPtr, &mem, &len, "utf-8");
		result = [NSString stringWithUTF8String:(const char *)mem];
		free(mem);
	}
	return result;
}


- (xmlDocPtr)docPtr;
{
	return docPtr;
}


- (void)setDocPtr:(xmlDocPtr)ptr;
{
	if (ptr != docPtr) {
		if (NULL != docPtr) {
			xmlFreeDoc(docPtr);
		}
		docPtr = ptr;
	}
}


- (NSString *)baseURI;
{
	return baseURI;
}


- (void)setBaseURI:(NSString *)newStr;
{
	if (baseURI != newStr) {
		[baseURI autorelease];
		baseURI = [newStr retain];
	}
}


- (NSString *)filename;
{
	return [baseURI lastPathComponent];
}


@end
