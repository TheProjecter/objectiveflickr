/* LoginSheetController */

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface LoginSheetController : NSWindowController
{
    IBOutlet id actionButton;
    IBOutlet id progressIndicator;
    IBOutlet id textMessage;
	
	NSDictionary *_token;
	OFFlickrAPICaller *_apicall;
	int _state;
}
- (IBAction)buttonAction:(id)sender;
- (void)startSheet;
- (void)closeSheet;
- (NSDictionary*)token;
@end
