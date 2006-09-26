#import "LoginSheetController.h"
#import "ContactsBrowserApplication.h"

#define MSG(x) [[NSBundle mainBundle] localizedStringForKey:x value:nil table:nil]

enum {
	LSButtonCancelState = 0,
	LSButtonLoginState = 1,
	LSButtonContinueState = 2,
	LSButtonRetryState = 3
};

@implementation LoginSheetController
- (void)setState:(int)s
{
	state = s;

	// set button equivalent to none
	[actionButton setKeyEquivalent:@""];
	
	switch(state)
	{
		case LSButtonCancelState:
			// set button equivalent to ESC
			[actionButton setTitle:MSG(@"Cancel")];
			break;
		case LSButtonLoginState:
			[actionButton setKeyEquivalent:@"\x1b"];
			[textMessage setStringValue:@"Please login"];
			[actionButton setTitle:MSG(@"Login")];
			break;
		case LSButtonContinueState:
			[progressIndicator startAnimation:self];
			[textMessage setStringValue:MSG(@"A browser will be opened up in 3 seconds, after you have finished the authorization process, please click on the Continue button.")];
			[actionButton setTitle:MSG(@"Continue")];
			break;
		case LSButtonRetryState:
			state = LSButtonLoginState;
			[textMessage setStringValue:@"Login failed, please try"];
			[actionButton setTitle:MSG(@"Retry")];
			break;
	}
}
- (IBAction)buttonAction:(id)sender
{
	NSString *token;

	switch(state)
	{
		case LSButtonCancelState:
			// cancel connection
			[apicall cancel];
			[self setState:LSButtonLoginState];
			break;
			
		case LSButtonLoginState:
			// set the button to Cancel
			[self setState:LSButtonCancelState];
			
			// start login process
			[textMessage setStringValue:MSG(@"Checking if you have previously logged in...")];
			[progressIndicator startAnimation:self];
			
			// check if we have a previously obtained auth token
			token = [[NSApp delegate] storedAuthToken];
			
			if ([token length]) {
				[[apicall context] setAuthToken:token];
				[apicall setSelector:@selector(handleCheckAuth:error:data:)];
				[apicall callMethod:@"flickr.auth.checkToken" arguments:nil];
				break;
			}
			
			// if not, get a frob
			[textMessage setStringValue:MSG(@"Connecting to Flickr...")];
			[apicall setSelector:@selector(handleGetFrob:error:data:)];
			[apicall callMethod:@"flickr.auth.getFrob" arguments:nil];
			break;
		case LSButtonContinueState:	
			[self setState:LSButtonCancelState];
			[progressIndicator startAnimation:self];

			// in this state, our stored token is actually the frob
			token = [[NSApp delegate] storedAuthToken];
			[[NSApp delegate] setStoredAuthToken:@""];
			
			// we re-use the handleCheckAuth, which is a propos
			[apicall setSelector:@selector(handleCheckAuth:error:data:)];
			
			[apicall flickr_auth_getToken:nil frob:token];
			//[apicall callMethod:@"flickr.auth.getToken" arguments: [NSArray arrayWithObjects:@"frob", token, nil]];
			break;
	}
	
	// [self closeSheet];
}

- (void)startSheet
{
	NSLog(@"sheet start");
	OFFlickrApplicationContext *c = [(ContactsBrowserApplication*)[NSApp delegate] context];
	apicall = [OFFlickrAPICaller callerWithDelegate:self context:c];
	[apicall retain];
	
	[self setState:LSButtonLoginState];
	[self buttonAction:self];
}

- (void)handleCheckAuth:(OFFlickrAPICaller*)caller error:(int)errorNo data:(id)data
{
	NSLog(@"handle check auth / get token");
	[progressIndicator stopAnimation:self];
	if (errorNo) {
		if (errorNo == OFAPICallCanceled) {
			NSLog(@"check auth canceled");
			return;
		}
		if (errorNo == 98) {	// invalid auth token
			NSLog(@"invalid auth token, now we have to restart the login process");
			[[NSApp delegate] setStoredAuthToken:@""];	// reset stored auth token
			[[caller context] setAuthToken:@""];		// reset the auth token in the context
			
			// rerun the loginState
			[self setState:LSButtonLoginState];
			[self buttonAction:self];
			return;
		}
	
		NSLog(@"error, code=%d, message=%@", errorNo, data);
		[self setState:LSButtonRetryState];
		return;
	}
	
	NSDictionary *d = [(NSXMLDocument*)data flickrDictionaryFromDocument];
	NSString *token = [[[d objectForKey:@"auth"] objectForKey:@"token"] objectForKey:@"$"];
	[[NSApp delegate] setStoredAuthToken:token];
	NSLog(@"logged in, token = %@, user name = %@", token, [[[d objectForKey:@"auth"] objectForKey:@"user"] objectForKey:@"@fullname"]);
	[self closeSheet];
}

- (void)handleOpenBrowser:(NSTimer*)timer 
{
	// remember to single quote the URLstring, lest funny things happen
	NSLog(@"3 seconds lapsed, opening URL %@", [timer userInfo]);
	[progressIndicator stopAnimation:self];
	system([[NSString stringWithFormat:@"open '%@'", [timer userInfo]] UTF8String]);
}
- (void)handleGetFrob:(OFFlickrAPICaller*)caller error:(int)errorNo data:(id)data
{
	NSLog(@"handle get frob");
	[progressIndicator stopAnimation:self];
	if (errorNo) {
		if (errorNo == OFAPICallCanceled) {
			NSLog(@"get frob canceled");
			return;
		}
		NSLog(@"error, code=%d, message=%@", errorNo, data);
		[self setState:LSButtonRetryState];
		return;
	}
	
	NSDictionary *d = [(NSXMLDocument*)data flickrDictionaryFromDocument];
	NSString *frob = [[d objectForKey:@"frob"] objectForKey:@"$"];
	NSLog(@"frob obtained = %@", frob);
	
	// we use the app's token storage to store our frob,
	// it's not a very decent thing we do, but we do it
	[[NSApp delegate] setStoredAuthToken:frob];
	
	NSString *url = [[apicall context] prepareLoginURL:frob permission:@"read"];
	[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(handleOpenBrowser:) userInfo:url repeats:NO];
	
	[self setState:LSButtonContinueState];
}

- (void)flickrAPICaller:(OFFlickrAPICaller*)caller didFetchData:(NSXMLDocument*)xmldoc
{
	NSLog(@"api: data fetched (we shouldn't reach here though)");
	NSLog([[xmldoc flickrDictionaryFromDocument] description]);
}
- (void)flickrAPICaller:(OFFlickrAPICaller*)caller error:(int)errcode errorInfo:(id)errInfo
{
	NSLog(@"api: error (we shouldn't reach here though), code=%d, message=%@", errcode, errInfo);
}
- (void)flickrAPICaller:(OFFlickrAPICaller*)caller progress:(size_t)receivedBytes expectedTotal:(size_t)total
{
	NSLog(@"api: progress %ld of %ld", receivedBytes, total);
}
- (void)closeSheet
{
	NSLog(@"ending sheet!");
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
}
@end
