/* ContactsBrowserController */

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface ContactsBrowserController : NSWindowController
{
    IBOutlet id contactsList;
    IBOutlet id labelRealName;
    IBOutlet id labelUserName;
    IBOutlet id labelFamily;
    IBOutlet id labelFriend;
    IBOutlet id progressIndicator;
    IBOutlet id sheetController;
	
	OFFlickrInvocation *_apicall;
	NSArray *_contacts;
}
- (void)startBrowser;
@end
