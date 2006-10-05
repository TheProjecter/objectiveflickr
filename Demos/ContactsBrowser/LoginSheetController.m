#import "LoginSheetController.h"
#import "ContactsBrowserApplication.h"

#define MSG(x) [[NSBundle mainBundle] localizedStringForKey:x value:nil table:nil]

enum {
	LSButtonCancelState = 0,
	LSButtonLoginState = 1,
	LSButtonContinueState = 2,
	LSButtonRetryState = 3,
};

@implementation LoginSheetController
- (void)dealloc
{
	if (_apicall) [_apicall release];
	if (_token) [_token release];
	[super dealloc];
}
- (NSDictionary*)token
{
	return _token;
}
- (void)setState:(int)s
{
	_state = s;

	switch(_state)
	{
		case LSButtonCancelState:
			// set button equivalent to ESC
			[actionButton setTitle:MSG(@"Cancel")];
			break;
		case LSButtonLoginState:
			[textMessage setStringValue:@"Please login"];
			[actionButton setTitle:MSG(@"Login")];
			break;
		case LSButtonContinueState:
			[progressIndicator startAnimation:self];
			[textMessage setStringValue:MSG(@"A browser will be opened up in 3 seconds, after you have finished the authorization process, please click on the Continue button.")];
			[actionButton setTitle:MSG(@"Continue")];
			break;
		case LSButtonRetryState:
			_state = LSButtonLoginState;
			[textMessage setStringValue:@"Login failed, please try"];
			[actionButton setTitle:MSG(@"Retry")];
			break;
	}
}
- (void)awakeFromNib 
{
	[self setState:LSButtonLoginState];
}
- (IBAction)buttonAction:(id)sender
{
	NSString *token;

	switch(_state)
	{
		case LSButtonCancelState:
			// cancel connection
			[_apicall cancel];
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
				[[_apicall context] setAuthToken:token];
				[_apicall setSelector:@selector(handleCheckAuth:error:data:)];
				[_apicall callMethod:@"flickr.auth.checkToken" arguments:nil];
				break;
			}
			
			// if not, get a frob
			[textMessage setStringValue:MSG(@"Connecting to Flickr...")];
			// [_apicall setSelector:@selector(handleGetFrob:error:data:)];
			// [_apicall callMethod:@"flickr.auth.getFrob" arguments:nil];
			// [_apicall callMethod:@"flickr.auth.getFrob" arguments:nil selector:@selector(handleGetFrob:error:data:)];
			[_apicall flickr_auth_getFrob:nil selector:@selector(handleGetFrob:error:data:)];
			break;
		case LSButtonContinueState:	
			[self setState:LSButtonCancelState];
			[progressIndicator startAnimation:self];

			// in this state, our stored token is actually the frob
			token = [[NSApp delegate] storedAuthToken];
			[[NSApp delegate] setStoredAuthToken:@""];
			
			// we re-use the handleCheckAuth, which is a propos
			[_apicall setSelector:@selector(handleCheckAuth:error:data:)];
			
			[_apicall flickr_auth_getToken:nil frob:token];
			//[_apicall callMethod:@"flickr.auth.getToken" arguments: [NSArray arrayWithObjects:@"frob", token, nil]];
			break;
	}
	
	// [self closeSheet];
}

- (void)startSheet
{
	NSLog(@"sheet start");
	_token = nil;
	OFFlickrContext *c = [(ContactsBrowserApplication*)[NSApp delegate] context];
	_apicall = [OFFlickrInvocation invocationWithContext:c delegate:self];
	[_apicall retain];
	
	[self setState:LSButtonLoginState];
	[self buttonAction:self];
}

- (void)handleCheckAuth:(OFFlickrInvocation*)caller error:(int)errorNo data:(id)data
{
	NSLog(@"handle check auth / get token");
	[progressIndicator stopAnimation:self];
	if (errorNo) {
		if (errorNo == OFConnectionCanceled) {
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
	NSString *t = [[[d objectForKey:@"auth"] objectForKey:@"token"] objectForKey:@"$"];
	[[NSApp delegate] setStoredAuthToken:t];
	[[_apicall context] setAuthToken:t];
	NSLog(@"logged in, token = %@, user name = %@", t, [[[d objectForKey:@"auth"] objectForKey:@"user"] objectForKey:@"@fullname"]);
	
	_token = [NSDictionary dictionaryWithDictionary:d];
	[_token retain];

	[self closeSheet];
}

- (void)handleOpenBrowser:(NSTimer*)timer 
{
	// remember to single quote the URLstring, lest funny things happen
	NSLog(@"3 seconds lapsed, opening URL %@", [timer userInfo]);
	[progressIndicator stopAnimation:self];
	system([[NSString stringWithFormat:@"open '%@'", [timer userInfo]] UTF8String]);
}
- (void)handleGetFrob:(OFFlickrInvocation*)caller error:(int)errorNo data:(id)data
{
	NSLog(@"handle get frob");
	[progressIndicator stopAnimation:self];
	if (errorNo) {
		if (errorNo == OFConnectionCanceled) {
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
	
	NSString *url = [[_apicall context] prepareLoginURL:frob permission:@"read"];
	[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(handleOpenBrowser:) userInfo:url repeats:NO];
	
	[self setState:LSButtonContinueState];
}

- (void)flickrInvocation:(OFFlickrInvocation*)caller didFetchData:(NSXMLDocument*)xmldoc
{
	NSLog(@"api: data fetched (we shouldn't reach here though)");
	NSLog([[xmldoc flickrDictionaryFromDocument] description]);
}
- (void)flickrInvocation:(OFFlickrInvocation*)caller errorCode:(int)errcode errorInfo:(id)errInfo
{
	NSLog(@"api: error (we shouldn't reach here though), code=%d, message=%@", errcode, errInfo);
}
- (void)flickrInvocation:(OFFlickrInvocation*)caller progress:(size_t)receivedBytes expectedTotal:(size_t)total
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
