//
//  AGTableDataController.h
//  AGTableDataController
//
//  Created by Amy Worrall on 10/06/2011.
//

#import <Foundation/Foundation.h>

#import "AGTableDataControllerProtocols.h"

@class AGTableSection, AGTableRow;


@interface AGTableDataController : NSObject

#pragma mark - Creation

// Designated initialiser. If you don't use this method, you'll need to make sure you use - [AGTableDataController setTableView:].
- (id)initWithTableView:(UITableView*)tableView;
- (void)setTableView:(UITableView *)tv;

// Used so the TDC knows the table is in editing mode: it does things like handles rows that are only visible in editing mode.
@property (nonatomic, assign) BOOL editing;

// If you set the tableView property directly, make sure you also set the table view's delegate and data source to the TDC
@property (nonatomic, strong) UITableView *tableView;

// The TDC's delegate. This is the object that gets interrogated for things like the number of dynamic rows in a section (see AGTableDataControllerProtocols.h).
// In hindsight this probably shouldn't have been required to be a view controller. I may update that in the future.
@property (nonatomic, weak) UIViewController<AGTableDataControllerDelegate> *delegate;

// The AGTableSection objects in this AGTableDataController
@property (nonatomic, readonly) NSArray *sections;


#pragma mark - Adding sections

// Creates and returns a new section, adding it to the end of the table.
- (AGTableSection*)appendNewSection;

// Same as the above, but with a section title.
- (AGTableSection*)appendNewSectionWithTitle:(NSString*)title;

// Appends a section you've created manually to the end of the table.
- (void)appendSection:(AGTableSection*)section;

#pragma mark - Dynamic objects

// Call these methods when a dynamic object is inserted/deleted/replaced.
- (void)section:(AGTableSection*)s insertedDynamicObjectAtIndex:(NSInteger)index;
- (void)section:(AGTableSection*)s deletedDynamicObjectAtIndex:(NSInteger)index;
- (void)section:(AGTableSection*)s replacedDynamicObjectAtIndex:(NSInteger)index;

#pragma mark - Refreshing

// If something has changed for a static row (such as its visibility, or you've done something that will make its configuration block set it up differently), call this to refresh it.
- (void)refreshStaticRow:(AGTableRow*)r;

// Call this to reload the whole table view. Calling this rather than just calling reloadData on the table view makes sure that AGTable is not trying to reload the table view at the same time.
- (void)reloadTableView;

// Used to make an AGTable-created text field resign the first responder.
- (void)commitTextFieldEditingOperations;

// If YES, the UITableView's selectedRows are cleared when the action is pressed. Doing this means you don't get the nice fade out when the user goes back to the screen, but it means you don't have to worry about deselecting things manually when you do actions that don't push things onto a navigation controller.
@property (nonatomic, assign) BOOL clearSelectionOnAction;

@end
