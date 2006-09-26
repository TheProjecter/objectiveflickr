/* LoginSheetController */

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface LoginSheetController : NSWindowController
{
    IBOutlet id actionButton;
    IBOutlet id progressIndicator;
    IBOutlet id textMessage;
	
	OFFlickrAPICaller *apicall;
	int state;
}
- (IBAction)buttonAction:(id)sender;
- (void)startSheet;
- (void)closeSheet;
@end
