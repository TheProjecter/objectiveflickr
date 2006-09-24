#import "ContactsBrowserController.h"

#import "OFDemoAPIKey.h"

#ifndef OFDemoAPIKey
	#error Please define your OFDemoAPIKey in DemoAPIKey.h. This file will be ignored by svn in subsequent commits.
#endif

#ifndef OFDemoSharedSecret
	#error Please define your OFDemoSharedSecret in DemoAPIKey.h. This file will be ignored by svn in subsequent commits.
#endif

@implementation ContactsBrowserController
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSLog(@"app finished launching!");
	[NSApp beginSheet:loginSheet modalForWindow:[self window] modalDelegate:loginSheetController didEndSelector:nil contextInfo:nil];
	// [NSApp runModalForWindow:loginSheet];
	NSLog([loginSheet isVisible] ? @"visible" : @"closed");

}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSLog(@"should terminate?");
	return YES;
}
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action
{
	NSLog(@"menu item!");
	return NO;
}
- (IBAction)terminate:(id)sender
{
	[loginSheetController buttonAction:self];
	NSLog([loginSheet isVisible] ? @"visible" : @"closed");
	[NSApp terminate:self];
}
@end
