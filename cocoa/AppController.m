#import "AppController.h"

@implementation AppController

-(void)awakeFromNib 
{
	[self setupWebView];
	[self setupSocket];
}

- (void)setupWebView
{
	[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"WebKitDeveloperExtras"];
	[[webView preferences] setShouldPrintBackgrounds: YES];
}

- (void)setupSocket
{
	socketPort = [[NSSocketPort alloc] initWithTCPPort:6429];
	if(!socketPort)
	{
        [self alert:@"Could not bind to port (6429)."];
        return;
	}
	fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:[socketPort socket]
											   closeOnDealloc:YES];
	
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(handleConnection:)
			   name:NSFileHandleConnectionAcceptedNotification
			 object:nil];
	
	[fileHandle acceptConnectionInBackgroundAndNotify];	
}

- (void)handleConnection:(NSNotification *)notification
{
	NSDictionary* userInfo = [notification userInfo];
	NSFileHandle* remoteFileHandle = [userInfo objectForKey:
									  NSFileHandleNotificationFileHandleItem];
	
	NSNumber* errorNo = [userInfo objectForKey:@"NSFileHandleError"];
	if(errorNo) 
	{
		NSLog(@"NSFileHandle Error: %s", strerror([errorNo intValue]));
		return;
	}
	
	[fileHandle acceptConnectionInBackgroundAndNotify];
	if(remoteFileHandle) 
		[self updateWithData:[remoteFileHandle readDataToEndOfFile]]; 
}


- (void)updateWithData:(NSData*)data
{
	if([data length] == 0) {
		NSLog(@"connection closed");
	} else {
		NSString* html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		[[webView mainFrame] loadHTMLString:html baseURL:nil];
	}	
}

- (void)alert:(NSString*)message
{
    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText: @"Error!"];
    [alert setInformativeText: message];
    [alert setAlertStyle: NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

// should take (NSString*)path here
- (void)save
{
    NSString* path = @"/tmp/celerity_viewer.png";

    NSView* viewPort = [[[webView mainFrame] frameView] documentView];
    NSRect bounds   = [viewPort bounds];
    NSBitmapImageRep* imageRep = [viewPort bitmapImageRepForCachingDisplayInRect:bounds];
    
    [viewPort cacheDisplayInRect:bounds toBitmapImageRep:imageRep];

    if(!imageRep)
        return;
    
    [[imageRep representationUsingType:NSPNGFileType properties:nil] writeToFile:path atomically:true];
    NSLog(@"wrote screenshot to %@", path);
}

- (void)dealloc
{
    [nc removeObserver:self];
	[fileHandle release];
    [socketPort release];
    [super dealloc];
}
@end