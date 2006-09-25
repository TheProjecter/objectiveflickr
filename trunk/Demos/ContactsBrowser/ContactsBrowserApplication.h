/* ContactsBrowserApplication */

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface ContactsBrowserApplication : NSObject
{
    IBOutlet id browserWindow;
    IBOutlet id sheetController;
    IBOutlet id sheetWindow;
	
	OFFlickrApplicationContext* _context;
}
- (IBAction)terminate:(id)sender;
- (OFFlickrApplicationContext*)context;
- (NSString*)storedAuthToken;
- (void)setStoredAuthToken:(NSString*)token;
@end
