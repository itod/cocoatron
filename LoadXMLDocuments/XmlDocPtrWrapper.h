//
//  XmlDocPtrWrapper.h
//  Load XML Documents
//
//  Created by Todd Ditchendorf on 11/15/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libxml/parser.h>

@interface XmlDocPtrWrapper : NSObject {
	xmlDocPtr docPtr;
	NSString *baseURI;
}
- (id)initWithDocPtr:(xmlDocPtr)ptr;
- (xmlDocPtr)docPtr;
- (void)setDocPtr:(xmlDocPtr)ptr;
- (NSString *)baseURI;
- (void)setBaseURI:(NSString *)newStr;
- (NSString *)filename;
@end
