/* LoginSheetController */

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface LoginSheetController : NSWindowController
{
    IBOutlet id actionButton;
    IBOutlet id messageText;
    IBOutlet id progressIndicator;
}
- (IBAction)buttonAction:(id)sender;
@end
