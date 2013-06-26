//
//  AGTableViewController.h
//  AGTable
//
//  Created by Amy Worrall on 10/12/2012.
//

#import <UIKit/UIKit.h>
#import <AGTable/AGTable.h>

@interface AGTableViewController : UITableViewController<AGTableDataControllerDelegate>

// This is a UITableViewController subclass that already has an AGTableDataController connected and set up. You don't have to use this class, it's just there as a convenience.

@property (nonatomic, strong) AGTableDataController *tableDataController;

// designated initialiser
- (id)init;

// subclasses override to pick a style
- (UITableViewStyle)tableViewStyle;

@end
