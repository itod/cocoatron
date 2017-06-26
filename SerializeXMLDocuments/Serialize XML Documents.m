//
//  Serialize XML Documents.m
//  Serialize XML Documents
//
//  Created by Todd Ditchendorf on 11/21/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "Serialize XML Documents.h"
#import "XmlDocPtrWrapper.h"

@implementation Serialize_XML_Documents

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	NSArray *inputArray;
	
	//NSLog(@"input  : %@", input);
	//NSLog(@"parameters: %@", [self parameters]);
	
	inputArray = [self arrayForInput:input];
	
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[inputArray count]];
	
	NSEnumerator *e = [input objectEnumerator];
	
	XmlDocPtrWrapper *wrapper;
	
	while (wrapper = [e nextObject]) {
		[result addObject:[wrapper description]];
	}

	return result;
}

@end
