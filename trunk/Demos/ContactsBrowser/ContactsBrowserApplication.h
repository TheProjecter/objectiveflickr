/* ContactsBrowserApplication */

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface ContactsBrowserApplication : NSObject
{
    IBOutlet id browserController;
    IBOutlet id browserWindow;
    IBOutlet id sheetController;
    IBOutlet id sheetWindow;
	
	OFFlickrContext* _context;
}
- (IBAction)terminate:(id)sender;
- (OFFlickrContext*)context;
- (NSString*)storedAuthToken;
- (void)setStoredAuthToken:(NSString*)token;
@end
