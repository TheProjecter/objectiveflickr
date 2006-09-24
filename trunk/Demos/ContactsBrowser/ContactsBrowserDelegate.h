/* ContactsBrowserDelegate */

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface ContactsBrowserDelegate : NSObject
{
	OFFlickrApplicationContext *appContext;
    IBOutlet id loginSheet;
}
- (IBAction)loginSheetButtonAction:(id)sender;
- (IBAction)beginSheet:(id)sender;
@end
