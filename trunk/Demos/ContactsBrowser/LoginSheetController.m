#import "LoginSheetController.h"

@implementation LoginSheetController

- (IBAction)buttonAction:(id)sender
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
}
- (void)cancelOperation:(id)sender
{
	NSLog(@"cancel!");
}
- (void)keyDown:(NSEvent *)event
{
	
	NSLog(@"%@, %d, mask=%d", [actionButton keyEquivalent], [[actionButton keyEquivalent] characterAtIndex:0], [actionButton keyEquivalentModifierMask]);
	NSLog([[self window] isVisible] ? @"visible" : @"closed");

	[actionButton setKeyEquivalent:@"\x1b"];

	NSLog(@"key down!");
    NSString *chars = [event characters];
    unichar character = [chars characterAtIndex: 0];

    if (character == 27)
        NSLog (@"ESCAPE!");	
}
@end
