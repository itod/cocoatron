//
//  Validate XML Documents.m
//  Validate XML Documents
//
//  Created by Todd Ditchendorf on 11/21/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "Validate XML Documents.h"
#import "XmlDocPtrWrapper.h"
#import <libxml/parser.h>
#import <libxml/valid.h>
#import <libxml/xmlschemas.h>
#import <libxml/relaxng.h>


static NSString *const KeySchemaURLString  = @"schemaURLString";
static NSString *const KeySchemaType	   = @"schemaType";

typedef enum {
	SchemaTypeDTD = 0,
	SchemaTypeXSD,
	SchemaTypeRNG
} SchemaType;


@interface Validate_XML_Documents (Private)
- (void)doDTDValidation:(xmlDocPtr)source;
- (void)doXSDValidation:(xmlDocPtr)source;
- (void)doRNGValidation:(xmlDocPtr)source;
@end

@implementation Validate_XML_Documents

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
		[[self parameters] setObject:[openPanel filename] forKey:KeySchemaURLString];
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
	
	[self setErrorString:[NSMutableString string]];
	[self setConsoleString];
	
	SchemaType schemaType = [[[self parameters] objectForKey:KeySchemaType] intValue];
	
	xmlSetGenericErrorFunc((void *)self, (xmlGenericErrorFunc)myGenericErrorFunc);

	NSEnumerator *e = [input objectEnumerator];
	XmlDocPtrWrapper *wrapper;
	xmlDocPtr source;
	while (wrapper = [e nextObject]) {
		
		source = [wrapper docPtr];

		switch (schemaType) {
			case SchemaTypeDTD:
				[self doDTDValidation:source];
				break;
			case SchemaTypeXSD:
				[self doXSDValidation:source];
				break;
			case SchemaTypeRNG:
				[self doRNGValidation:source];
				break;
		}
		
		if ([errorString length]) {
			NSLog(@"Cocoatron 'Validate XML Documents' Error: %@", errorString);
			(*errorInfo) = [self dictionaryWithErrorNumber:-1 message:errorString];
			[self setConsoleString];
		}
		
		//NSLog(@"errorInfo: %@", *errorInfo);
	}
	
	return input;
}


#pragma mark -
#pragma mark Private

- (void)doDTDValidation:(xmlDocPtr)source;
{
	xmlValidCtxtPtr validCtxt = NULL;
	xmlDtdPtr dtd = NULL;
	int res;
	
	validCtxt = xmlNewValidCtxt();
	
	if (!validCtxt) {
		[self appendErrorString:@"DTD validation failed due to possible libxml2 error."];
		goto leave;
	}
	
	NSString *systemId = [[self parameters] objectForKey:KeySchemaURLString];

	if ([systemId length]) {

		dtd = xmlParseDTD(NULL, (xmlChar *)[systemId UTF8String]);
		
		if (!dtd) {
			[self appendErrorString:@"Error parsing DTD document."];
			goto leave;
		}
		
		res = xmlValidateDtd(validCtxt, source, dtd);

	} else {
	
		res = xmlValidateDocument(validCtxt, source);
	
	}
	
leave:
	if (validCtxt)
		xmlFreeValidCtxt(validCtxt);
	if (dtd)
		xmlFreeDtd(dtd);
}


- (void)doXSDValidation:(xmlDocPtr)source;
{
	NSString *loc = [[self parameters] objectForKey:KeySchemaURLString];
	
	int res;
	xmlSchemaParserCtxtPtr parserCtxt = NULL;
	xmlSchemaPtr schema	= NULL;
	xmlSchemaValidCtxtPtr validCtxt = NULL;
	
	if ([loc length]) {
		parserCtxt = xmlSchemaNewParserCtxt([loc UTF8String]);
		
		if (!parserCtxt) {
			[self appendErrorString:@"Could not locate XML Schema document."];
			goto leave;
		}
		
		schema = xmlSchemaParse(parserCtxt);
		
		if (!schema) {
			[self appendErrorString:@"Error parsing XML Schema document."];
			goto leave;
		}
		
		validCtxt = xmlSchemaNewValidCtxt(schema);
		
		if (!validCtxt) {
			[self appendErrorString:@"Error parsing XML Schema document."];
			goto leave;
		}
		
		res = xmlSchemaValidateDoc(validCtxt, source);
		
	} else {
		xmlSchemaValidCtxtPtr validCtxt = xmlSchemaNewValidCtxt(NULL);
	
		if (!validCtxt) {
			[self appendErrorString:@"XML Schema validation failed due to possible libxml2 error."];
			goto leave;
		}
		
		res = xmlSchemaValidateDoc(validCtxt, source);
	}

	if (res) {
		[self appendErrorString:@"XML Schema validation failed."];
	}	

leave:
	if (parserCtxt)
		xmlSchemaFreeParserCtxt(parserCtxt);
	if (schema);
		xmlSchemaFree(schema);
	if (validCtxt) 
		xmlSchemaFreeValidCtxt(validCtxt);
}


- (void)doRNGValidation:(xmlDocPtr)source;
{
	NSString *loc = [[self parameters] objectForKey:KeySchemaURLString];
	
	int res;
	xmlRelaxNGParserCtxtPtr parserCtxt = NULL;
	xmlRelaxNGPtr schema = NULL;
	xmlRelaxNGValidCtxtPtr validCtxt = NULL;
	
	parserCtxt = xmlRelaxNGNewParserCtxt([loc UTF8String]);
	
	if (!parserCtxt) {
		[self appendErrorString:@"Could not locate RELAX NG document."];
		goto leave;
	}
	
	schema = xmlRelaxNGParse(parserCtxt);
	
	if (!schema) {
		[self appendErrorString:@"Error parsing RELAX NG document."];
		goto leave;
	}
	
	validCtxt = xmlRelaxNGNewValidCtxt(schema);
	
	if (!validCtxt) {
		[self appendErrorString:@"Error parsing RELAX NG document."];
		goto leave;
	}
	
	res = xmlRelaxNGValidateDoc(validCtxt, source);
	
	if (res) {
		[self appendErrorString:@"RELAX NG validation failed."];
	}	
	
leave:
	//xmlRelaxNGCleanupTypes();
	if (parserCtxt)
		xmlRelaxNGFreeParserCtxt(parserCtxt);
	if (schema)
		xmlRelaxNGFree(schema);
	if (validCtxt)
		xmlRelaxNGFreeValidCtxt(validCtxt);
}


#pragma mark -
#pragma mark Accessors

- (float)smallHeight;
{
	return 125.;
}


- (float)bigHeight;
{
	return 206.;
}


@end
