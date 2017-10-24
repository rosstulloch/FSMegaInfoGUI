//
//  MainWindow.m
//  FSMegaInfoGUI
//
//  Created by Ross Tulloch on 15/05/08.
//  Copyright 2008 Ross Tulloch. All rights reserved.
//

#import "MainWindow.h"
#import "Node.h"
#include <sys/mount.h>
#include <sys/syslog.h>

@implementation MainWindow

-(void)awakeFromNib
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(deviceListChanged:) name:NSWorkspaceDidMountNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(deviceListChanged:) name:NSWorkspaceDidUnmountNotification object:nil];

	[self buildVolumePopup];		
	[outputView setFont:[NSFont fontWithName:@"Monaco" size:10]];
    
    mainTreeView.delegate = self;

	NSDictionary*	cmdsDictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Cmds" ofType:@"plist" inDirectory:nil]];
	NSEnumerator	*keys = [cmdsDictionary keyEnumerator];
	NSString*		cmdParentName = nil;
	
	while((cmdParentName = [keys nextObject]))
	{
		Node*	node = [Node nodeWithTitle:cmdParentName];
		[mainTree addObject:node];

		NSEnumerator*	cmds = [[cmdsDictionary objectForKey:cmdParentName] objectEnumerator];
		NSString*		cmd = nil;
		while((cmd = [cmds nextObject])) {
			[self addCmd:cmd parent:node];
		}
	}
		
	[mainTreeView expandItem:[mainTreeView itemAtRow:1]];
	[mainTreeView expandItem:[mainTreeView itemAtRow:0]];
	[mainTreeView selectRow:1 byExtendingSelection:NO];
	[[self window] setInitialFirstResponder:mainTreeView];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    NSTreeNode*	nodeItem = item;
    
    if ( [nodeItem isLeaf] == NO ) {
        return( YES );
    }

	return ( NO );
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
	[self refreshResults:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

- (void)deviceListChanged:(NSNotification *)notification
{
	[self buildVolumePopup];
	[self refreshResults:nil];
}

- (NSArray*)buildLocalVolumeList
{
    NSArray         *itemsToIgnore = [NSArray arrayWithObjects:@"/dev", @"/net", @"/home", nil];
	NSMutableArray  *volumes = [NSMutableArray array];
	struct statfs   *buf;
	int i, count;
	
	// Get all the mount points....
	count = getmntinfo(&buf, 0);
	for (i=0; i<count; i++)
	{
        // Path to it...
        NSString *path = [NSString stringWithUTF8String:buf[i].f_mntonname];
        
        if ( [itemsToIgnore containsObject:path] == NO ) {
            [volumes addObject:path];
        }
	}

	return( volumes );
}

-(void)buildVolumePopup
{	
	[volumesPopup removeAllItems];

	NSMenu			*volumesPopupMenu = [volumesPopup menu];	
	NSEnumerator	*volumeList = [[self buildLocalVolumeList] objectEnumerator];
	NSString		*item = nil;
	
	while((item = [volumeList nextObject]))
	{
		NSString*	shortName = [NSString stringWithString:item];
		if ( [shortName hasPrefix:@"/Volumes/"] ) {
			shortName = [shortName substringFromIndex:[@"/Volumes/" length]];
		}

		NSMenuItem*	menuItem = [[[NSMenuItem alloc] initWithTitle:shortName action:@selector(outlineViewSelectionDidChange:) keyEquivalent:@""] autorelease];
		[menuItem setTarget:self];
		[menuItem setRepresentedObject:item];
		
		NSImage* image = [[NSWorkspace sharedWorkspace] iconForFile:item];
		[image setSize:NSMakeSize(12,12)];
		[menuItem setImage:image];
		
		[volumesPopupMenu addItem:menuItem];
	}
}

-(NSString*)getCurrentVolume {
	return( [[volumesPopup selectedItem] representedObject] );
}

-(NSString*)getCurrentPath {
	return( [[self getCurrentVolume] stringByAppendingPathComponent:[additionalPath stringValue]] );
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSArray*	selectedObjects = [mainTree selectedObjects];
	if ( [selectedObjects count] )
	{
		Node*	selectedNode = [selectedObjects objectAtIndex:0];
		if ( [selectedNode dictionary] != nil ) {
			[self runCmd:[selectedNode dictionary]];
		} else {
			[outputView setString:@""];
		}
	}
}

-(IBAction)refreshResults:(id)sender
{
	[self outlineViewSelectionDidChange:nil];
}

-(void)addCmd:(NSString*)cmdName parent:(Node*)node
{
	Node*	newNode = [Node nodeWithTitle:cmdName];
	if ( newNode != nil )
	{
		[newNode setLeaf:YES];
		[newNode setDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:cmdName, @"cmd", nil]];
		[node addChild:newNode];
	}
}

-(void)runCmd:(NSMutableDictionary*)testDict
{
    NSPipe			*stdOut = [NSPipe pipe];
    NSFileHandle	*outputFile = [stdOut fileHandleForReading];
    NSTask			*task = [[NSTask alloc] init];
	NSString		*cmd = [testDict objectForKey:@"cmd"];
	NSString		*argsSelector = [cmd stringByAppendingString:@"__Args"];
	SEL				argsSEL = NSSelectorFromString(argsSelector);
	
	if ( [self respondsToSelector:argsSEL] ) {
		NSMutableArray	*array = [NSMutableArray arrayWithObject:cmd];
		[array addObjectsFromArray:[self performSelector:argsSEL]];
		[task setArguments:array];
	} else {
		[task setArguments:[NSArray arrayWithObjects:cmd, [self getCurrentVolume],  nil]];
	}
	
	// Add -v to args...
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"verboseOutput"] ) {
		[task setArguments:[[NSArray arrayWithObject:@"-v"] arrayByAddingObjectsFromArray:[task arguments]]];
	}
	
	[task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"FSMegaInfo" ofType:nil inDirectory:nil]];
	[task setStandardOutput:stdOut];
	[task setStandardError:stdOut];

	NSLog(@"args:%@", [task arguments]);

	[[NSNotificationCenter defaultCenter]	addObserver:self selector:@selector(outputEndOfFileNotification:)
											name:NSFileHandleReadToEndOfFileCompletionNotification object:outputFile ];

	[task launch];
	[outputFile readToEndOfFileInBackgroundAndNotify];
}

- (void)outputEndOfFileNotification: (NSNotification*) notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notification object]];

	NSData*		data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ( data != nil ) {
		[outputView setString:[[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding]];
	}
}


-(NSArray*)FSGetCatalogInfo__Args
{
	NSMutableArray*	results = [NSMutableArray arrayWithObjects:@"-spec", @"-parent", @"-kFSCatInfoTextEncoding,kFSCatInfoNodeFlags,kFSCatInfoVolume,kFSCatInfoParentDirID,kFSCatInfoNodeID,kFSCatInfoCreateDate,kFSCatInfoContentMod,kFSCatInfoAttrMod,kFSCatInfoAccessDate,kFSCatInfoBackupDate,kFSCatInfoPermissions,kFSCatInfoFinderInfo,kFSCatInfoFinderXInfo,kFSCatInfoValence,kFSCatInfoDataSizes,kFSCatInfoRsrcSizes,kFSCatInfoSharingFlags,kFSCatInfoUserPrivs,kFSCatInfoUserAccess,kFSCatInfoFSFileSecurityRef", nil];
	NSString*		currentVolume = [self getCurrentPath];

	[results addObject:currentVolume];

	return(results);
}

-(NSArray*)FSGetCatalogInfoBulk__Args
{
	NSMutableArray*	results = [NSMutableArray arrayWithObjects:@"-refs", @"-specs", @"-kFSCatInfoGettableInfo", nil];
	NSString*		currentVolume = [self getCurrentPath];

	[results addObject:currentVolume];

	return(results);
}

-(NSArray*)FSCopyAliasInfo__Args
{
	return([NSArray arrayWithObjects:[self getCurrentPath], nil]);
}

-(NSArray*)GetAliasInfo__Args
{
	return([NSArray arrayWithObjects:[self getCurrentPath], nil]);
}

-(NSArray*)getdirentries__Args {
	return([NSArray arrayWithObjects:[self getCurrentPath], nil]);
}

-(NSArray*)readdir__Args {
	return([NSArray arrayWithObjects:[self getCurrentPath], nil]);
}

-(NSArray*)fts__Args {
	return([NSArray arrayWithObjects:[self getCurrentPath], nil]);
}

-(NSArray*)stat__Args {
	return([NSArray arrayWithObjects:[self getCurrentPath], nil]);
}

-(NSArray*)access__Args {
	return([NSArray arrayWithObjects:[self getCurrentPath], nil]);
}

-(NSArray*)getattrlist__Args
{
	NSString*	itemsPath = [[NSBundle mainBundle] pathForResource:@"getattrlist__Items" ofType:@"txt"];
	NSString*	items = [NSString stringWithContentsOfFile:itemsPath encoding:NSUTF8StringEncoding error:nil];
	return([NSArray arrayWithObjects:items,[self getCurrentPath], nil]);
}

-(NSArray*)DADiskCopyDescription__Args
{
	NSMutableArray*	results = [NSMutableArray array];
	NSString*		diskID = @"";
	NSString*		currentVolume = [self getCurrentVolume];
	
	NSURL*		url = [[NSURL alloc] initFileURLWithPath:currentVolume];
	if ( url != nil )
	{
		FSRef	ref = {};
		if ( CFURLGetFSRef( (CFURLRef)url, &ref) ) 
		{
			FSCatalogInfo	catalogInfo = {};
			if ( FSGetCatalogInfo( &ref, kFSCatInfoVolume, &catalogInfo, NULL, NULL, NULL ) == noErr )
			{
				if ( FSCopyDiskIDForVolume ( catalogInfo.volume, (CFStringRef*)&diskID ) == noErr ) {
					[results addObject:diskID];
					[diskID autorelease];
				}
			}
		}
		
		[url release];
	}
	
	return( results );
}

@end
