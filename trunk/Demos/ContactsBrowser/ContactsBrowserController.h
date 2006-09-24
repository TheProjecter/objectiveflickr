/* ContactsBrowserController */

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface ContactsBrowserController : NSWindowController
{
    IBOutlet id loginSheet;
    IBOutlet id loginSheetController;
}
- (IBAction)terminate:(id)sender;
@end
