#import "ContactsBrowserApplication.h"
#import "LoginSheetController.h"
#import "OFDemoAPIKey.h"

#ifndef OFDemoAPIKey
	#error Please define your OFDemoAPIKey in DemoAPIKey.h. This file will be ignored by svn in subsequent commits.
#endif

#ifndef OFDemoSharedSecret
	#error Please define your OFDemoSharedSecret in DemoAPIKey.h. This file will be ignored by svn in subsequent commits.
#endif

@implementation ContactsBrowserApplication
- (id)init
{
	NSLog(@"app init!");
	if ((self = [super init])) {
		_context = nil;
	}
	return self;
}
- (void)dealloc
{
	if (_context) [_context release];
	[super dealloc];
}
- (void)awakeFromNib
{
	NSLog(@"app awakeFromNib");
}
- (IBAction)terminate:(id)sender
{
	if ([sheetWindow isVisible]) {
		[sheetController closeSheet];
	}
	[NSApp terminate:self];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[NSApp beginSheet:sheetWindow modalForWindow:browserWindow modalDelegate:sheetController didEndSelector:nil contextInfo:nil];
	[sheetController startLogin];
}
- (OFFlickrApplicationContext*)context {
	if (!_context) {
		_context = [[OFFlickrApplicationContext contextWithAPIKey:OFDemoAPIKey sharedSecret:OFDemoSharedSecret] retain];
	}
	return _context;
}
- (NSString*)storedAuthToken
{
	CFStringRef token = (CFStringRef)CFPreferencesCopyAppValue((CFStringRef)@"auth_token", kCFPreferencesCurrentApplication);
	if (!token) return @"";
	
	NSString *s=[NSString stringWithString:(NSString*)token];
	CFRelease(token);
	return s;
}

- (void)setStoredAuthToken:(NSString*)token
{
	NSLog(@"store!");
	CFPreferencesSetAppValue((CFStringRef)@"auth_token", (CFStringRef)token, kCFPreferencesCurrentApplication);
	CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
}

@end
