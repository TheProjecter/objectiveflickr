/* PhotoSearchController */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface PhotoSearchController : NSWindowController
{
    IBOutlet id progressIndicator;
    IBOutlet id searchField;
    IBOutlet id webView;
	OFFlickrContext *context;
	OFFlickrInvocation *invoc;
}
- (IBAction)startSearch:(id)sender;
@end
