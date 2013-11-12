//
//  AGTableDataControllerDelegate.h
//  AGTableDataController
//
//  Created by Amy Worrall on 10/06/2011.
//

#import <UIKit/UIKit.h>

@class AGTableDataController, AGTableSection, AGTableRow;


// Implement this protocol on the delegate for your AGTableDataController. If you're writing a subclass AGTableViewController, it already declares that it implements it (but you still have to implement any of these methods yourself).
@protocol AGTableDataControllerDelegate

@optional


// For sections that are not just static objects, use this delegate method to tell it how many dynamic objects are in the section.
// This method is not called if you use - [AGTableSection bindDynamicObjectsArrayTo:keypath:].
- (NSInteger)	tableDataController:(AGTableDataController*)c numberOfDynamicObjectsInSection:(AGTableSection*)section ;

// Return the model object at a certain index in the current section. Again, not called if you're binding a dynamic objects array.
- (id)			tableDataController:(AGTableDataController*)c dynamicObjectForIndex:(NSInteger)index inSection:(AGTableSection*)section;

// If a static row's objectMode is objectModeDelegate (or it is objectModeDefault and it has already tried KVO), it'll ask for the object for a static row using this method.
- (id)			tableDataController:(AGTableDataController*)c objectForStaticRow:(AGTableRow*)row;

// If a row's visibilityMode is visibilityModeDelegate, it'll ask the delegate for its visibility. Called whenever the TDC recalculates its visibility cache (such as when contentChangedForRow is called).
- (BOOL)		tableDataController:(AGTableDataController*)c visibilityForRow:(AGTableRow*)row;

// Dynamic rows can have more than one row prototype. You can use this delegate method to choose which one(s) to display for any given dynamic row. The row object will be the row prototype, populated with the model object.
- (BOOL)		tableDataController:(AGTableDataController*)c prototypeVisibilityForDynamicRow:(AGTableRow*)row;

// If you haven't defined the cellClass property on a row, it'll ask the delegate. This method is optional, and UITableViewCell is used by default.
- (Class)		tableDataController:(AGTableDataController*)c cellClassForRow:(AGTableRow*)row;

// If you want to provide a custom reuse identifier for your cells, you can set the reuseIdentifier property or you can implement this delegate method.
- (NSString*)	tableDataController:(AGTableDataController*)c reuseIdentifierForRow:(AGTableRow*)row;

// If a row has an action, this means it is tappable to do something. By default, having an action implies a blue selection style, a right chevron, an accessibility trait of Button, and a few other things. A row normally has an action if it has its actionBlock or actionSelector property set: however, you can use this method to disable that action if you like.
- (BOOL)		tableDataController:(AGTableDataController*)c canPerformActionForRow:(AGTableRow*)row;

// If a row has hasInsertAction set to YES, then when the table's in editing mode it'll show the green plus. When the plus is tapped, this method gets called.
- (int)			tableDataController:(AGTableDataController*)c insertPressedForRow:(AGTableRow*)row;

// Like above, but for hasDeleteAction.
- (BOOL)		tableDataController:(AGTableDataController*)c deletePressedForRow:(AGTableRow*)row;

// The if a row's section has canEditReorderDynamicRows set to YES, then when a reorder action happens, this method is called.
- (void)		tableDataController:(AGTableDataController*)c dynamicItem:(id)object index:(NSInteger)oldIndex inSection:(AGTableSection*)section didMoveToIndex:(NSInteger)newIndex;


@end


typedef enum {
	cellPositionFirst = 1 << 0,
	cellPositionLast = 1 << 1
} CellPosition;


@protocol AGTableCellHeight

@optional

// This method can be implemented on UITableViewCell subclasses. It allows a cell class to compute the height required for a cell. The row object passed into this method contains the model object, and you're also passed the UITableViewStyle, the cell's position (whether it is first in the section, last, neither or both), the width of the table view, and which (if any) cell accessory is to be displayed.
+ (CGFloat)cellHeightForRow:(AGTableRow*)row tableStyle:(UITableViewStyle)style position:(CellPosition)position width:(CGFloat)width accessoryType:(UITableViewCellAccessoryType)accessoryType;

// This one is called when using the prototype cell method of obtaining height.
- (CGFloat)desiredCellHeight;

@end



// If you implement this protocol on your UITableViewCell subclass, these properties will be set when about to display a cell.
@protocol AGTableCellProperties

@optional
@property (nonatomic, assign) CellPosition cellPosition;
@property (nonatomic, assign) UITableViewStyle tableStyle;

// This is the row object used to populate the cell.
// One VERY IMPORTANT caveat of using this method: if you're writing a cell that uses a row prototype, the same AGTableRow object is used for many cells. What that means is that you can only guarantee the row object is set up for the cell in question whilst inside the -[id<AGTableCellProperties> setRow:] method. If you synthesize this property, and thus store the row in an instance variable, then by the time you get to drawRect or whatever, the row object will be configured for a completely different cell.
// The workaround is don't synthesize this property: instead, implement -[id<AGTableCellProperties> setRow:] yourself, and extract the important information out of the AGTableRow (such as its object, or rowNumber, or whatever), and store those as properties of your UITableViewCell subclass.
@property (nonatomic, weak) AGTableRow *row;

@end
