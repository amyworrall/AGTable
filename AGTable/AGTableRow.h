//
//  AGTableRow.h
//  AGTableDataController
//
//  Created by Amy Worrall on 10/06/2011.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef void(^CellSetupBlock)(UITableViewCell **cell, AGTableRow *row);
typedef void(^CellConfigBlock)(UITableViewCell *cell, AGTableRow *row);
typedef void(^CellActionBlock)(AGTableRow *row);
typedef int(^CellHeightBlock)(AGTableRow *row);

#define defaultTextfieldTag 9999

typedef enum {
	visibilityModeStandard, // Uses the 'visible' property to determine visibility
	visibilityModeEditingOnly, // Never shown when not in editing mode. As above when in editing mode.
	visibilityModeDelegate, // Asks the TDC's delegate about row visibility
	visibilityModeDelegateEditingOnly // As above in editing mode
} VisibilityMode;

typedef enum {
	objectModeDefault, 
	objectModeStatic, 
	objectModeDelegate,
	objectModeKVO
} ObjectMode;


extern NSString * const AGBindingOptionRegisterForValueChanged ;
extern NSString * const AGBindingOptionRegisterForEditingEvents ;
extern NSString * const AGBindingOptionsValueTransformer ;
extern NSString * const AGBindingOptionsUseValueTransformerInReverse ;
extern NSString * const AGBindingOptionsFormatter;

@class AGTableDataController;
@class AGTableSection;
@protocol AGTableDataControllerDelegate;



@interface AGTableRow : NSObject<UITextFieldDelegate>

// Create a new row with the given cell class. Pass in nil to use UITableViewCell.
- (id)initWithCellClass:(Class)aCellClass;
+ (AGTableRow*)rowWithCellClass:(Class)cellClass;

// Set the controller that is related to this row. You shouldn't need to set it directly, this happens automatically when adding a row to a section.
@property (nonatomic, weak) AGTableDataController *controller;

#pragma mark - Doing stuff

// Convenience method that calls refreshStaticRow: on the row's associated controller.
- (void)refresh;

#pragma mark - Row info

// A number so that you can identify rows.
@property (nonatomic, assign) NSInteger tag;

// The reuse identifier given to the UITableView for the cell representing this row. IF left blank, AGTable tries to construct one automatically.
@property (nonatomic, strong) NSString *reuseIdentifier;

// The UITableViewCell subclass used to display this row.
@property (nonatomic, weak) Class cellClass;


#pragma mark - Working with objects

// The model object associated with this row.
// You can use model objects for static rows, although you don't have to.  But they're always used for dynamic rows. The way it works behind the scenes is when the cell is being set up (in cellForRowAtIndexPath: and a few other places), AGTable will set the object property of the row prototype to the object in question, then call the configuration stuff (or whatever
@property (nonatomic, strong) id object;

// Cached value for the last thing the 'object' property returned (i.e. doesn't perform the full lookup/delegate calls, just outputs from the cache)
@property (readonly, nonatomic, strong) id lastReturnedObject;

// Whether the object for this row is provided by the TDC's delegate, or whether it's static, or whether it's provided by KVO (see objectKeypath)
// This property is only used for static rows: dynamic ones will get their objects using bindings (on the section) or via the TDC's delegate method.
@property (nonatomic, assign) ObjectMode objectMode;

// Does limited KVO of that keypath on the delegate, and refreshes if object changes
@property (nonatomic, copy) NSString *objectKeypath;



#pragma mark - Getting info

// The section that contains this row
- (AGTableSection*)section;

// If this is a row prototype currently being used to represent a dynamic object, this returns the index of that object within the current section's array of dynamic objects
@property (readonly, nonatomic, assign) NSInteger objectIndex;

// The row number (i.e. this is the Nth UITableViewCell in this section)
@property (readonly, nonatomic, assign) NSInteger rowNumber;



#pragma mark - Visibility

// Whether the row is visible or not, assuming a standard visibility mode
@property (assign) BOOL visible;

// How the row's visibility is calculated 
@property (assign) VisibilityMode visibilityMode;



#pragma mark - Editing


// Whether the green + or red - are shown when in editing mode. Requires the delegate method to handle the action if invoked.
@property (assign) BOOL hasDeleteAction;
@property (assign) BOOL hasInsertAction;




#pragma mark - Configuring the UITableViewCell

// Initial setup refers to the stuff done after creating a cell, but that is not done after dequeueing a cell.
// The first parameter of the selector or block is a double pointer to a cell: AGTable creates one by default (for the cell class specified), but you can return a different cell object if you so desire.
@property (assign) SEL initialSetupSelector;
@property (copy) CellSetupBlock initialSetupBlock;
@property (strong) NSMutableDictionary *initialSetupKeyValueData;

// Configuration is the stuff done after creating or dequeueing a cell.
// You could set properties on the cell here, such as cell.textLabel.text = @"Test";.
@property (assign) SEL configurationSelector;
@property (copy) CellConfigBlock configurationBlock;
@property (strong) NSMutableDictionary *configurationKeyValueData;
- (void)addConfigurationValue:(id)object forKeyPath:(NSString*)key;

#pragma mark - xibs

@property (copy) NSString *cellNibName;
@property (assign) BOOL calculateHeightWithAutoLayout;


#pragma mark - Cell height

// The height of the UITableView row for this AGTableRow.
@property (assign) CGFloat rowHeight;


// A block or selector that is invoked to allow you to calculate the height yourself.
@property (copy) CellHeightBlock heightBlock;
@property (assign) SEL heightSelector;

// Height can also be obtained directly from the UITableViewCell subclass, if it implements the AGTableCellHeight protocol.

#pragma mark - Actions

// An action is the thing that happens when you tap the cell (or its accessory, in the case of accessoryActionSelector).
@property (assign) SEL actionSelector; 
@property (copy) CellActionBlock actionBlock;
@property (assign) SEL accessoryActionSelector;



#pragma mark - Text

// Convenience methods for setting the textLabel.text and detailTextLabel.text properties on the cell
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *detailText;

// These options are soon to be deprecated. They were written before AGTable had generic bindings support, and were specific special case ways to bind the text to keypaths on the TDC delegate.
@property (nonatomic, copy) NSString *textBoundToKeypath;
@property (nonatomic, copy) NSString *detailTextBoundToKeypath;


#pragma mark - Auto height

// Turns on auto cell height based on the text property. This uses a magic number so may need upgrading for later versions of iOS
@property (assign) BOOL autoHeightForText;

// Like the above, but gets the text by using a keypath on the row's object
@property (copy) NSString* autoHeightForObjectKeypath;


#pragma mark - Convenience configuration

// The type of cell accessory. If not defined, AGTable will automatically add a cheveron if an action is present.
@property (nonatomic, assign) UITableViewCellAccessoryType accessoryType;

// Some properties common to UITableViewCells
@property (assign) UITableViewCellSelectionStyle selectionStyle;
@property (assign) UITableViewCellStyle cellStyle;
@property (assign) UIAccessibilityTraits accessibilityTraits;

// For the cell's textLabel
@property (strong) UIFont *font;

// For the cell's detailTextLabel
@property (strong) UIFont *detailFont;

@property (strong) UIColor *textColor;
@property (assign) UITextAlignment textAlignment;
@property (strong) UIColor *backgroundColor;

// For doing alternating table row backgrounds
@property (strong) UIColor *alternatingBackgroundColor;



#pragma mark - Convenience text field

// Methods to easily obtain a text field that the user can type into. With the introduction of the general method for doing bindings (see below), these methods are less useful and will eventually be deprecated and replaced with methods built on top of the new system.

// The keypath on the TDC's delegate that the text field is bound to.
@property (nonatomic, copy) NSString *textFieldBoundToProperty;

// Some properties on the text field.
@property (assign) UIKeyboardType textFieldKeyboardType;
@property (strong) NSCharacterSet *textFieldLimitToCharactersInSet;
@property (copy) NSString *textFieldPlaceholder;
@property (nonatomic, assign) BOOL textFieldClearButton;
@property (nonatomic, assign) UITextAutocapitalizationType textFieldAutocapitalizationType;
@property (nonatomic, assign) UITextAutocorrectionType textFieldAutocorrectionType;
@property (nonatomic, assign) BOOL textFieldAutoFocus;

// A way to bind text fields with arbitrary tags to different properties.
// This method is deprecated and should be replaced with -[AGTableRow bind:keypath:toViewWithTag:keypath:options:] with AGBindingOptionRegisterForEditingEvents
- (void)bindTextFieldTagged:(int)textFieldTag toDelegatePropertyNamed:(NSString*)property observeChanges:(BOOL)observe; 



#pragma mark - Convenience other fields


// In a similar way to the convenience text field described above, these options give you an option picker (pushes a view controller with a choice of options), a date picker, and an image picker.

// AGTable is not a very comprehensive forms library at present. These fields are useful but not very customisable, and may not be suited to all apps. They were also all written before AGTable gained generic bindings support. One day they may be replaced with newer methods built on top of the new bindings system.

@property (strong) NSArray *optionChoices;
@property (strong) NSString *optionFieldBoundToProperty;
@property (strong) Class customOptionSelectorViewController;
@property (assign) BOOL optionAllowsOther;

@property (strong) NSString *dateFieldBoundToProperty;
@property (assign) UIDatePickerMode datePickerMode;
@property (nonatomic, strong) NSTimeZone *datePickerTimeZone;

@property (strong) NSString *imageFieldBoundToProperty;



#pragma mark - Binding

// Binding lets you specify that a keypath on an object of your choice should be bound to a keypath on something within the view hierarchy of your UITableViewCell. The binding is bidirectional, and changes are observed and handled intelligently.
// You can bind to the model object represented by a row, by using the methods starting bindDataObjectKeypath:.
// You can also bind to a view with a certain tag. This lets you avoid subclassing UITableViewCell if you want.

- (void) bind:(id)anObject keypath:(NSString*)objectKeypath toCellKeypath:(NSString*)cellKeypath options:(NSDictionary*)options;
- (void) bind:(id)anObject keypath:(NSString*)objectKeypath toViewWithTag:(int)tag keypath:(NSString*)viewKeypath options:(NSDictionary*)options;
- (void) bindDataObjectKeypath:(NSString*)rowObjectKeypath toCellKeypath:(NSString*)cellKeypath options:(NSDictionary*)options;
- (void) bindDataObjectKeypath:(NSString*)rowObjectKeypath toViewWithTag:(int)tag keypath:(NSString*)viewKeypath options:(NSDictionary*)options;

// Unbinding is yet implemented as of Dec 10 2012
- (void) unbind:(id)anObject keypath:(NSString*)objectKeypath cellKeypath:(NSString*)cellKeypath;
- (void) unbind:(id)anObject keypath:(NSString*)objectKeypath viewWithTag:(int)tag keypath:(NSString*)viewKeypath;
- (void) unbindDataObjectKeypath:(NSString*)rowObjectKeypath cellKeypath:(NSString*)cellKeypath;
- (void) unbindDataObjectKeypath:(NSString*)rowObjectKeypath viewWithTag:(int)tag keypath:(NSString*)viewKeypath;
- (void) unbindAll;

// Methods used internally, but may also be useful to expose. These methods interrogate the bindings that exist on the row, and look up the appropriate value from the model.
- (id) valueForBoundCellKeypath:(NSString*)keypath;
- (id) valueForBoundViewTag:(NSInteger)tag keypath:(NSString*)keypath;


@end
