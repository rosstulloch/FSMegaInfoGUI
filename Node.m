//
//  Node.m
//  FSMegaInfoGUI
//
//  Created by Ross Tulloch on 15/05/08.
//  Copyright 2008 Ross Tulloch. All rights reserved.
//

#import "Node.h"


@implementation Node

+ (Node*) nodeWithTitle:(NSString*)title
{
	return( [[[Node alloc] initWithTitle:title] autorelease] );
}

- (id) initWithTitle:(NSString*)aTitle
{
	self = [super init];
	if (self != nil) {
		[self setTitle:aTitle];
	}
	return self;
}

// -------------------------------------------------------------------------------
//	setLeaf:flag
// -------------------------------------------------------------------------------
- (void)setLeaf:(BOOL)flag
{
	isLeaf = flag;
	if (isLeaf)
		[self setChildren:[NSArray arrayWithObject:self]];
	else
		[self setChildren:[NSArray array]];
}

// -------------------------------------------------------------------------------
//	isLeaf:
// -------------------------------------------------------------------------------
- (BOOL)isLeaf
{
	return isLeaf;
}

-(void)addChild:(Node*)newKid
{
	if ( children == nil ) {
		[self setChildren:[NSArray arrayWithObject:newKid]];
	} else {
		[children addObject:newKid];
	}
}

// -------------------------------------------------------------------------------
//	setChildren:newChildren
// -------------------------------------------------------------------------------
- (void)setChildren:(NSArray*)newChildren
{
	if (children != newChildren)
    {
        [children autorelease];
        children = [[NSMutableArray alloc] initWithArray:newChildren];
    }
}

// -------------------------------------------------------------------------------
//	children:
// -------------------------------------------------------------------------------
- (NSMutableArray*)children
{
	return children;
}

// -------------------------------------------------------------------------------
//	setNodeTitle:newNodeTitle
// -------------------------------------------------------------------------------
- (void)setTitle:(NSString*)newNodeTitle
{
	[newNodeTitle retain];
	[title release];
	title = newNodeTitle;
}

// -------------------------------------------------------------------------------
//	nodeTitle:
// -------------------------------------------------------------------------------
- (NSString*)title
{
	return title;
}

- (void)setDictionary:(NSMutableDictionary*)newDict
{
	[newDict retain];
	[dictionary release];
	dictionary = newDict;
}

- (NSMutableDictionary*)dictionary
{
	return dictionary;
}

@end
