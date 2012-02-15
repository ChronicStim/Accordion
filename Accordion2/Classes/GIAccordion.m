//
//  GIAccordion.m
//  Accordion2
//
//  Created by Enriquez Gutierrez Guillermo Ignacio on 1/20/11.
//  Copyright 2011 Nacho4D. All rights reserved.
//  See the file license.txt for copying permission.
//


#import "GIAccordion.h"
#import "GIAccordionViewCell.h"
#import "GITreeNode.h"

@interface GIAccordion ()
{
	NSMutableArray *selectedNodes;
	BOOL inPseudoEditMode;
}
@end

@implementation GIAccordion

@synthesize selectedNodes;
@synthesize isInPseudoEditMode;

- (id) initWithPath:(NSString *)baseDirectoryPath{
	self = [super initWithPath:baseDirectoryPath];
	if (self) {
		selectedNodes = [[NSMutableArray alloc] init];
		inPseudoEditMode = NO;
	}
	return self;
}
- (void)setIsInPseudoEditMode:(BOOL)flag{
	isInPseudoEditMode = flag;
	if (!flag) {
		[selectedNodes removeAllObjects];
	}
}

//overwrites default implementation in GITree, dont call super. implementation is very basic
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"MyCellIdentifier";
	GIAccordionViewCell *cell = (GIAccordionViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[GIAccordionViewCell alloc] initWithReuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
		//cell.indentationWidth = cell.frame.size.height;
		cell.indentationWidth = 20.0;//44: icon image size
		
		UILongPressGestureRecognizer *r = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(cellWasLongPressed:)];
		[cell addGestureRecognizer:r];
	}
	
	GITreeNode *node = (GITreeNode *)[self.nodes objectAtIndex:indexPath.row];
//	[cell setTitle:[node.filename stringByDeletingPathExtension]];
    [cell setTitle:node.filename];
	[cell setIcon:[node iconForTreeNode] 
	  isDirectory:node.isDirectory];
	cell.detailTextLabel.text = [[node modificationDate] description];//creationDateFormated];
	cell.indentationLevel = node.depth;

	return cell;

}

//overrides implementation, call super because 
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[super tableView:aTableView didSelectRowAtIndexPath:indexPath];
	

		GITreeNode *node = (GITreeNode *)[self.nodes objectAtIndex:indexPath.row];
		if (node.isDirectory) {
			GIAccordionViewCell *cell = (GIAccordionViewCell *)[aTableView cellForRowAtIndexPath:indexPath];
			[cell setExpanded:!cell.isExpanded];
		}
	if (isInPseudoEditMode) {
		[selectedNodes addObject:node];
	}
	
}


- (void)cellWasLongPressed:(id)sender{
	NSLog(@"%@: Not implemented", NSStringFromSelector(_cmd));
}


@end
