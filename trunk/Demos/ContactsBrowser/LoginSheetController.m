#import "LoginSheetController.h"
#import "ContactsBrowserApplication.h"

#define MSG(x) [[NSBundle mainBundle] localizedStringForKey:x value:nil table:nil]

@implementation LoginSheetController
- (void)flickrAPICaller:(OFFlickrAPICaller*)caller didFetchData:(NSXMLDocument*)xmldoc
{
	NSLog(@"api: data fetched");
	NSLog([[xmldoc flickrDictionaryFromDocument] description]);
}
- (void)flickrAPICaller:(OFFlickrAPICaller*)caller error:(int)errorCode errorInfo:(id)errInfo
{
	NSLog(@"api: error, code=%d, message=%@", errorCode, errInfo);
}
- (void)flickrAPICaller:(OFFlickrAPICaller*)caller progress:(size_t)receivedBytes expectedTotal:(size_t)total
{
	NSLog(@"api: progress %ld of %ld", receivedBytes, total);
}
- (void)APICaller:(OFFlickrAPICaller*)caller error:(int)errorNo data:(id)data
{
	NSLog(@"api sel error code = %d", errorNo);
	
	if (!errorNo) {
		NSLog([data description]);
	}
}
- (void)startLogin
{
	[actionButton setTitle:MSG(@"Login")];
	[textMessage setStringValue:MSG(@"Checking if you've already loggined in")];
	
	NSLog(@"sheet awakeFromNib");

	OFFlickrApplicationContext *c = [(ContactsBrowserApplication*)[NSApp delegate] context];
	apicall = [OFFlickrAPICaller callerWithDelegate:self context:c];
	[apicall retain];
	
	[apicall setSelector:@selector(APICaller:error:data:)];
	[apicall performMethod:@"flickr.auth.getFrob" parametersAsArray:nil];


	id test=[apicall testCall];
	NSLog(test ? @"not null" : @"null");
	test=[apicall testArray:[NSArray arrayWithObjects:@"foo", @"bar", nil]];
	NSLog(test ? @"not null" : @"null");
	test=[apicall testTest:nil orz:@"bar" bling:[NSArray arrayWithObjects:@"foo", @"bar", nil]];
	NSLog(test ? @"not null" : @"null");

/*	
	context = (OFFlickrApplicationContext*)[[NSApp delegate] context];
	request = [[OFFlickrRESTRequest requestWithDelegate:self timeoutInterval:OFRequestDefaultTimeoutInterval] retain];

	NSString *prev_token = [[NSApp delegate] storedAuthToken];
	if (prev_token) {
		[context setAuthToken:prev_token];
		NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:
			@"flickr.blogs.getList", @"method", nil];
		NSString *call = [context prepareRESTGETURL:param authentication:YES sign:NO];
		[request GETRequest:call userInfo:@"checkPreviousToken"];
		[progressIndicator startAnimation:self];
	}

*/
/*

	[progressIndicator startAnimation:self];		
	[[OFFlickrRESTRequest requestWithDelegate:self timeoutInterval:OFRequestDefaultTimeoutInterval] GETRequest:
		[context prepareRESTGETURL:[NSDictionary dictionaryWithObjectsAndKeys:@"f_lickr.photos.getRecent", @"method", nil] 
			authentication:NO sign:NO]
		userInfo:@"testXML"]; */

/*
	OFFlickrAPICaller *c=[OFFlickrAPICaller callerWithDelegate:self context:context];
	[c performMethod:@"test" parametersAsArray:
		[NSArray arrayWithObjects:@"test1", @"value1", @"test2", 
			[NSArray arrayWithObjects:@"123", nil]
			, nil]
	]; */
	
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



/*
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request didCancel:(id)userinfo
{
	NSLog(@"cancel, userinfo=%@", userinfo);
	[progressIndicator stopAnimation:self];
}
- (void)flickrRESTRequest:(OFFlickrRESTRequest*)request didFetchData:(NSXMLDocument*)xmldoc userInfo:(id)userinfo
{
	NSLog(@"data, userinfo=%@, data=%@", userinfo, [xmldoc description]);

	[progressIndicator stopAnimation:self];
	
	NSDictionary *d = [xmldoc flickrDictionaryFromDocument];
	NSLog([d description]);
	
	int errcode;
	id msg;
	if ([xmldoc hasFlickrError:&errcode message:&msg]) {
		NSLog(@"has error! code=%d, message=%@", errcode, msg);
	}
	else {
		NSLog(@"normal");
	}
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
*/

@end
