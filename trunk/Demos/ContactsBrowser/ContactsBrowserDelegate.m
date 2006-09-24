#import "ContactsBrowserDelegate.h"

#import "OFDemoAPIKey.h"

#ifndef OFDemoAPIKey
	#error Please define your OFDemoAPIKey in DemoAPIKey.h. This file will be ignored by svn in subsequent commits.
#endif

#ifndef OFDemoSharedSecret
	#error Please define your OFDemoSharedSecret in DemoAPIKey.h. This file will be ignored by svn in subsequent commits.
#endif

@implementation ContactsBrowserDelegate
- (void)awakeFromNib 
{
	// appContext = nil;
	NSLog(@"awake from nib!");
}
@end
