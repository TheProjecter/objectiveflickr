/* LoginSheetController */

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface LoginSheetController : NSWindowController
{
    IBOutlet id actionButton;
    IBOutlet id progressIndicator;
    IBOutlet id textMessage;
	
	OFFlickrApplicationContext *context;
	OFFlickrRESTRequest *request;
}
- (IBAction)buttonAction:(id)sender;
- (void)startLogin;
- (void)closeSheet;
@end
