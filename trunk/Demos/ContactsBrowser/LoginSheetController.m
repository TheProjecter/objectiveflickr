#import "LoginSheetController.h"
#import "ContactsBrowserApplication.h"

@interface NSXMLNode(OFFlickrXMLExtension)
- (NSDictionary*)dictionaryFromElement;
@end

@interface NSXMLElement(OFFlickrXMLExtension)
- (NSDictionary*)dictionaryFromElement;
@end

@implementation NSXMLNode(OFFlickrXMLExtension)
- (NSDictionary*)dictionaryFromElement
{
	NSLog(@"node name=%@, value=%@", [self name], [self stringValue]);

	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	
	unsigned i, c = [self childCount];
	for (i = 0; i<c; i++) {
		#warning need to consider array issues
		NSXMLNode *n = [self childAtIndex:i];
		NSLog(@"child node %@=%@", [n name], [[n dictionaryFromElement] description]);
		
		NSString *name=[n name];
		if (name) {
			[d setObject:[n dictionaryFromElement] forKey:name];
		}
		else {
			[d setObject:[n stringValue] forKey:@"$"];	// text node
		}
	}
	return d;
}
@end

@implementation NSXMLElement(OFFlickrXMLExtension)
- (NSDictionary*)dictionaryFromElement
{
	NSLog(@"element name=%@, value=%@", [self name], [self stringValue]);
	NSMutableDictionary *d = (NSMutableDictionary*)[super dictionaryFromElement];

	NSArray *a = [self attributes];
	unsigned i, c = [a count];

	for (i = 0; i < c; i++) {
		NSXMLNode *n = [a objectAtIndex:i];
		NSLog(@"element attr @%@=%@", [n name], [n stringValue]);
		[d setObject:[n stringValue] forKey:[NSString stringWithFormat:@"@%@", [n name]]];
	}
	return d;
}
@end




@implementation LoginSheetController
- (void)startLogin
{
	NSLog(@"sheet awakeFromNib");
	
	context = (OFFlickrApplicationContext*)[[NSApp delegate] context];
	request = [[OFFlickrRESTRequest requestWithDelegate:self timeoutInterval:OFRequestDefaultTimeoutInterval] retain];
	
	NSString *prev_token = [[NSApp delegate] storedAuthToken];
	if (prev_token) {
		[context setAuthToken:prev_token];
		NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:
			@"flickr.test.login", @"method", nil];
		NSString *call = [context prepareRESTGETURL:param authentication:YES sign:YES];
		[request GETRequest:call userInfo:@"checkPreviousToken"];
		[progressIndicator startAnimation:self];
	}
}
- (IBAction)buttonAction:(id)sender
{
	[self closeSheet];
}
- (void)closeSheet
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request didCancel:(id)userinfo
{
	NSLog(@"cancel, userinfo=%@", userinfo);
	[progressIndicator stopAnimation:self];
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request didFetchData:(NSXMLDocument*)xmldoc userInfo:(id)userinfo
{
	NSLog(@"data, userinfo=%@, data=%@", userinfo, [xmldoc description]);

	[progressIndicator stopAnimation:self];
	
	NSDictionary *d = [[xmldoc rootElement] dictionaryFromElement];
	NSLog([d description]);

}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request error:(int)errorCode errorInfo:(id)errinfo userInfo:(id)userinfo
{
	NSLog(@"error, userinfo=%@, code=%d", userinfo, errorCode);
	[progressIndicator stopAnimation:self];

}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request progress:(size_t)receivedBytes expectedTotal:(size_t)total userInfo:(id)userinfo
{
	NSLog(@"progress, userinfo=%@, %ld of %ld", userinfo, receivedBytes, total);
}

@end
