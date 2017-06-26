//
//  Transform XML Documents.m
//  Transform XML Documents
//
//  Created by Todd Ditchendorf on 11/20/06.
//  Copyright 2006 Todd Ditchendorf. All rights reserved.
//

#import "Transform XML Documents.h"
#import "AGRegex.h"
#import "XmlDocPtrWrapper.h"
#import <libxml/xmlmemory.h>
#import <libxml/debugXML.h>
#import <libxml/HTMLtree.h>
#import <libxml/xmlIO.h>
#import <libxml/xinclude.h>
#import <libxml/catalog.h>
#import <libxslt/xslt.h>
#import <libxslt/xsltinternals.h>
#import <libxslt/transform.h>
#import <libxslt/xsltutils.h>
#import <libxslt/extensions.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>
#import <libexslt/exslt.h>

static NSString *const KeyStyleURLString  = @"styleURLString";
static NSString *const WhiteSpace		  = @" ";

@interface Transform_XML_Documents (Private)
- (XmlDocPtrWrapper *)transform:(XmlDocPtrWrapper *)wrapper params:(NSDictionary *)args error:(NSDictionary **)errorInfo;
@end

@implementation Transform_XML_Documents

static int regexpModuleGetOptions(xmlChar *optStr)
{
	int opts = 0;
	NSString *flags = [NSString stringWithUTF8String:(char *)optStr];
	NSRange r = [flags rangeOfString:@"i"];
	if (NSNotFound != r.location)
		opts = (opts|AGRegexCaseInsensitive);
	r = [flags rangeOfString:@"s"];
	if (NSNotFound != r.location)
		opts = (opts|AGRegexDotAll);
	r = [flags rangeOfString:@"x"];
	if (NSNotFound != r.location)
		opts = (opts|AGRegexExtended);
	r = [flags rangeOfString:@"m"];
	if (NSNotFound != r.location)
		opts = (opts|AGRegexMultiline);	
	return opts;
}


static void regexpModuleFunctionReplace(xmlXPathParserContextPtr ctxt, int nargs)
{	
	int opts = 0;
	if (4 == nargs) {
		opts = regexpModuleGetOptions(xmlXPathPopString(ctxt));
	}
	
	const xmlChar *replacePattern = xmlXPathPopString(ctxt);
	const xmlChar *matchPattern = xmlXPathPopString(ctxt);
	const xmlChar *input = xmlXPathPopString(ctxt);
	
	AGRegex *regex = [AGRegex regexWithPattern:[NSString stringWithUTF8String:(const char*)matchPattern]
									   options:opts];
	
	NSString *result = [regex replaceWithString:[NSString stringWithUTF8String:(const char*)replacePattern]
									   inString:[NSString stringWithUTF8String:(const char*)input]];
	
	xmlXPathObjectPtr value = xmlXPathNewString((xmlChar *)[result UTF8String]);
	valuePush(ctxt, value);
}


static void regexpModuleFunctionTest(xmlXPathParserContextPtr ctxt, int nargs)
{	
	int opts = 0;
	if (3 == nargs) {
		opts = regexpModuleGetOptions(xmlXPathPopString(ctxt));
	}
	
	const xmlChar *matchPattern = xmlXPathPopString(ctxt);
	const xmlChar *input = xmlXPathPopString(ctxt);
	
	AGRegex *regex = [AGRegex regexWithPattern:[NSString stringWithUTF8String:(const char*)matchPattern]
									   options:opts];
	
	BOOL result = [[regex findInString:[NSString stringWithUTF8String:(const char*)input]] count];
	
	xmlXPathObjectPtr value = xmlXPathNewBoolean(result);
	valuePush(ctxt, value);
}


static void regexpModuleFunctionMatch(xmlXPathParserContextPtr ctxt, int nargs)
{	
	int opts = 0;
	if (3 == nargs) {
		opts = regexpModuleGetOptions(xmlXPathPopString(ctxt));
	}
	
	const xmlChar *matchPattern = xmlXPathPopString(ctxt);
	const xmlChar *input = xmlXPathPopString(ctxt);
	
	AGRegex *regex = [AGRegex regexWithPattern:[NSString stringWithUTF8String:(const char*)matchPattern]
									   options:opts];
	
	AGRegexMatch *match = [[regex findAllInString:[NSString stringWithUTF8String:(const char*)input]] objectAtIndex:0];
	
	int len = [match count];
	
	xmlNodePtr node = xmlNewNode(NULL, (const xmlChar *)"match");
	xmlNodeSetContent(node, (const xmlChar *)[[match groupAtIndex:0] UTF8String]);
	xmlNodeSetPtr nodeSet = xmlXPathNodeSetCreate(node);
	
	int i;
	NSString *item;
	for (i = 1; i < len; i++) {
		item = [match groupAtIndex:i];
		
		node = xmlNewNode(NULL, (const xmlChar *)"match");
		if (item) {
			xmlNodeSetContent(node, (const xmlChar *)[[match groupAtIndex:i] UTF8String]);
		} else {
			xmlNodeSetContent(node, (const xmlChar *)"");
		}
		xmlXPathNodeSetAdd(nodeSet, node);
	}
	
	xmlXPathObjectPtr value = xmlXPathWrapNodeSet(nodeSet);
	valuePush(ctxt, value);
}


static void *regexpModuleInit(xsltTransformContextPtr ctxt, const xmlChar *URI)
{	
	xsltRegisterExtFunction(ctxt, (const xmlChar *)"replace", URI,
							(xmlXPathFunction)regexpModuleFunctionReplace);
	xsltRegisterExtFunction(ctxt, (const xmlChar *)"test", URI,
							(xmlXPathFunction)regexpModuleFunctionTest);
	xsltRegisterExtFunction(ctxt, (const xmlChar *)"match", URI,
							(xmlXPathFunction)regexpModuleFunctionMatch);
	
	return NULL;
}


static void *regexpModuleShutdown(xsltTransformContextPtr ctxt,
								  const xmlChar *URI,
								  void *data)
{
	return NULL;
}


#pragma mark -

+ (void)initialize;
{
	xsltRegisterExtModule((const xmlChar *)"http://exslt.org/regular-expressions",
						  (xsltExtInitFunction)regexpModuleInit,
						  (xsltExtShutdownFunction)regexpModuleShutdown);
	
	xmlSubstituteEntitiesDefaultValue = 1;
	xmlLoadExtDtdDefaultValue = 1;
	exsltRegisterAll();
}


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
		[[self parameters] setObject:[openPanel filename] forKey:KeyStyleURLString];
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
		
		newWrapper = [self transform:wrapper params:nil error:errorInfo];
		
		if ([errorString length]) {
			NSLog(@"Cocoatron 'Transform XML Documents' Error: %@", errorString);
			(*errorInfo) = [self dictionaryWithErrorNumber:-1 message:errorString];
			[self setConsoleString];
		}
		
		//NSLog(@"errorInfo: %@", *errorInfo);
		
		if (!newWrapper) { // parsing one of the files was not possible. errorInfo is already populated.
			return result;
		}
		
		[result addObject:newWrapper];
	}
	
	return result;
}


#pragma mark -
#pragma mark Private

- (XmlDocPtrWrapper *)transform:(XmlDocPtrWrapper *)wrapper params:(NSDictionary *)args error:(NSDictionary **)errorInfo;
{	
	xmlSetGenericErrorFunc((void *)self, (xmlGenericErrorFunc)myGenericErrorFunc);
	xsltSetGenericErrorFunc((void *)self, (xmlGenericErrorFunc)myGenericErrorFunc);
	
	xmlDocPtr source = [wrapper docPtr];
	xsltStylesheetPtr stylesheet = NULL;
	xsltTransformContextPtr xformCtxt = NULL;
	xmlDocPtr resDoc = NULL;
		
	NSString *styleURLString = [[self parameters] objectForKey:KeyStyleURLString];
	
	stylesheet = xsltParseStylesheetFile((const xmlChar*)[styleURLString UTF8String]);
	
	if (!stylesheet) {
		NSLog(@"Cocoatron 'Transform XML Documents' error: cannot parse stylesheet, returning input document.");
		// free memory
		if (stylesheet)
			xsltFreeStylesheet(stylesheet);		
		xmlCleanupParser();
		return wrapper;
	}
	
	xformCtxt = xsltNewTransformContext(stylesheet, source);
	xsltSetTransformErrorFunc(xformCtxt, (void *)self, (xmlGenericErrorFunc)myGenericErrorFunc);
	
	const int count = [params count]*2 +1;
	const char *xsltParams[count];
	
	if ([params count] == 0) {
		*xsltParams = NULL;
	} else {
		NSEnumerator *e = [params keyEnumerator];
		id key, val;
		int i = -1;
		while (key = [e nextObject]) {
			if (![key isEqualToString:WhiteSpace]) {
				val = [params objectForKey:key];
				xsltParams[++i] = [key UTF8String];
				xsltParams[++i] = [val UTF8String];
			}
		}
		xsltParams[++i] = NULL;
	}
	
	resDoc = xsltApplyStylesheet(stylesheet, source, xsltParams);
	
	XmlDocPtrWrapper *newWrapper;
	
	if (resDoc) {
		newWrapper = [[[XmlDocPtrWrapper alloc] initWithDocPtr:resDoc] autorelease];
	} else {
		NSLog(@"Cocoatron 'Transform XML Documents' error: error during transformation");
		newWrapper = wrapper;
	}	

leave:
	// free memory
	if (stylesheet)
		xsltFreeStylesheet(stylesheet);
	if (xformCtxt)
		xsltFreeTransformContext(xformCtxt);
	
	xmlCleanupParser();

	return newWrapper;
}

@end
