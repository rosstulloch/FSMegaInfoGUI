//
//  Node.h
//  FSMegaInfoGUI
//
//  Created by Ross Tulloch on 15/05/08.
//  Copyright 2008 Ross Tulloch. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Node : NSObject
{
	NSString			*title;
	NSMutableArray		*children;
	BOOL				isLeaf;
	NSMutableDictionary	*dictionary;
}

+ (Node*) nodeWithTitle:(NSString*)title;
- (void)setLeaf:(BOOL)flag;
- (BOOL)isLeaf;
- (void)setChildren:(NSArray*)newChildren;
- (NSMutableArray*)children;
- (void)setTitle:(NSString*)newNodeTitle;
- (NSString*)title;
- (void)setDictionary:(NSMutableDictionary*)newDict;
- (NSMutableDictionary*)dictionary;
-(void)addChild:(Node*)newKid;

@end
