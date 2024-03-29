#import "ContactsBrowserApplication.h"
#import "ContactsBrowserController.h"
#import "LoginSheetController.h"
#import "OFDemoAPIKey.h"

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
	[NSApp beginSheet:sheetWindow modalForWindow:browserWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[sheetController startSheet];
}
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if ([sheetController token]) {
		NSLog(@"token obtained, let the show begin");
		[browserController startBrowser];
	}
}
- (OFFlickrContext*)context {
	if (!_context) {
		_context = [[OFFlickrContext contextWithAPIKey:OFDemoAPIKey sharedSecret:OFDemoSharedSecret] retain];
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
