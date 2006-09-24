#import "ContactsBrowserDelegate.h"


@implementation ContactsBrowserDelegate
- (void)awakeFromNib 
{
	// appContext = nil;
	NSLog(@"awake from nib!");
	
	NSLog(@"awakeFromNib ended");
	
	// [NSApp setDelegate:self];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSLog(@"NSApp finish launching!");
	NSLog(@"deleg noti ended");
}

@end
