//
//  MainWindow.h
//  FSMegaInfoGUI
//
//  Created by Ross Tulloch on 15/05/08.
//  Copyright 2008 Ross Tulloch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Node;

@interface MainWindow : NSWindowController<NSOutlineViewDelegate> {
	IBOutlet	NSTreeController*	mainTree;
	IBOutlet	NSOutlineView*		mainTreeView;
	IBOutlet	NSTextView*			outputView;
	IBOutlet	NSPopUpButton*		volumesPopup;
	IBOutlet	NSTextField*		additionalPath;
}

-(void)awakeFromNib;
-(void)runCmd:(NSMutableDictionary*)testDict;
-(void)outputEndOfFileNotification: (NSNotification*) notification;

-(void)addCmd:(NSString*)cmdName parent:(Node*)node;
-(void)buildVolumePopup;
-(NSString*)getCurrentPath;
-(NSString*)getCurrentVolume;

-(IBAction)outlineViewSelectionDidChange:(NSNotification *)notification;
-(IBAction)refreshResults:(id)sender;

@end
