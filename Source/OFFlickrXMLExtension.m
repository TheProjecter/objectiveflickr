#import "ObjectiveFlickr.h"

@implementation NSXMLDocument(OFFlickrXMLExtension)
- (BOOL)hasFlickrError:(int*)errorCode message:(NSString**)errorMsg
{
	if (errorCode) *errorCode = 0;
	if (errorMsg) *errorMsg = @"";
	
	NSXMLNode *stat =[[self rootElement] attributeForName:@"stat"];
	if ([[stat stringValue] isEqualToString:@"ok"]) return NO;
	
	NSXMLNode *e = [[self rootElement] childAtIndex:0];
	NSXMLNode *codestr = [(NSXMLElement*)e attributeForName:@"code"];
	NSXMLNode *msg = [(NSXMLElement*)e attributeForName:@"msg"];
	
	if (errorCode) *errorCode = [[codestr stringValue] intValue];
	if (errorMsg) *errorMsg = [NSString stringWithString:[msg stringValue]];
	return YES;
}
- (NSDictionary*)flickrDictionaryFromDocument
{
	NSMutableDictionary *d=(NSMutableDictionary*)[[self rootElement] flickrDictionaryFromNode];
	
	NSXMLNode *stat =[[self rootElement] attributeForName:@"stat"];
	if ([[stat stringValue] isEqualToString:@"ok"])  {
		[d removeObjectForKey:@"@stat"];
	}
	return d;
}
@end



@implementation NSXMLNode(OFFlickrXMLExtension)
- (NSDictionary*)flickrDictionaryFromNode
{
	// NSLog(@"node name=%@, value=%@", [self name], [self stringValue]);

	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	
	unsigned i, c = [self childCount];
	for (i = 0; i<c; i++) {
		NSXMLNode *n = [self childAtIndex:i];
		// NSLog(@"child node %@=%@", [n name], [[n flickrDictionaryFromNode] description]);
		
		NSString *name=[n name];
		if (name) {
			id obj = [d objectForKey:name];
			
			if (!obj) {
				[d setObject:[n flickrDictionaryFromNode] forKey:name];
			}
			else {
				// it's already an array
				if ([obj isKindOfClass:[NSMutableArray class]]) {
					[obj addObject:[n flickrDictionaryFromNode]];
				}
				else {
					NSMutableArray *a = [NSMutableArray arrayWithObject:obj];
					[d setObject:a forKey:name];
				}
			}
		}
		else {
			[d setObject:[n stringValue] forKey:@"$"];	// text node
		}
	}
	return d;
}
@end

@implementation NSXMLElement(OFFlickrXMLExtension)
- (NSDictionary*)flickrDictionaryFromNode
{
	// NSLog(@"element name=%@, value=%@", [self name], [self stringValue]);
	NSMutableDictionary *d = (NSMutableDictionary*)[super flickrDictionaryFromNode];

	NSArray *a = [self attributes];
	unsigned i, c = [a count];

	for (i = 0; i < c; i++) {
		NSXMLNode *n = [a objectAtIndex:i];
		// NSLog(@"element attr @%@=%@", [n name], [n stringValue]);
		[d setObject:[n stringValue] forKey:[NSString stringWithFormat:@"@%@", [n name]]];
	}
	return d;
}
@end
