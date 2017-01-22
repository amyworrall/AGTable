//
//  AGTableSection.h
//  AGTableDataController
//
//  Created by Amy Worrall on 10/06/2011.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class AGTableRow;
@class AGTableDataController;

typedef void(^WillDisplayHeaderBlock)(AGTableSection *section, UIView *header);

@protocol AGTableDataControllerDelegate;


typedef enum {
	sectionModeStatic,
	sectionModeDynamic,
	sectionModeDynamicFirst,
	sectionModeStaticFirst
} SectionMode;


@interface AGTableSection : NSObject


#pragma mark - Creation

// Ways of making a new section. You can also make one through convenience methods on AGTableDataController.
+ (AGTableSection*)sectionWithTitle:(NSString*)title;
+ (AGTableSection*)section;
- (id)initWithTitle:(NSString*)title;


#pragma mark - Section metadata

// A numerical ID that represents the section.
// This number is for your own use, and you can happily omit it.
@property (nonatomic, assign) int tag;

// Whether the section contains just static rows, just dynamic rows, dynamic then static, or static then dynamic.
@property (nonatomic, assign) SectionMode mode;


#pragma mark - Section info

// Views that are given to the UITableView as section header/footer
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *footerView;

// The section title.
@property (nonatomic, strong) NSString *title;


#pragma mark - Adding rows

// Append an existing static row to the end of the section
- (AGTableRow*)appendRow:(AGTableRow*)row;

// Creates a new row and appends it to the end of the section.
- (AGTableRow*)appendNewRow;
- (AGTableRow*)appendNewRowWithCellClass:(Class)cellClass;


#pragma mark - Setting up dynamic rows

// The row object used as a prototype for any dynamic objects in this section.
// When the table is displayed, this AGTableRow object is reused. For each cell, the row prototype's 'object' is set appropriately. Thus it can be used in any of the configuration/action selectors etc to retrieve the object in question.
@property (nonatomic, strong) AGTableRow *rowPrototype;

// You can have more than one row prototype. This could be because you want to choose a different one for different dynamic objects in your section, or it could be that each dynamic object should be represented by multiple UITableView cells. If the latter, they're displayed in the order they are in this array. (To configure displaying different prototypes per object, look at the AGTableDataControllerDelegate protocol.)
@property (nonatomic, strong) NSArray *rowPrototypes;

// Set to YES to allow the user to reorder the dynamic rows in this section when in edit mode
@property (nonatomic, assign) BOOL canEditReorderDynamicRows;

// Sometimes to achieve the visual effect that is desired, you want one AGTableSection to be split over multiple UITableView sections. To do this, offer a keypath that can be applied to your model object. For any two sequential dynamic objects, if the valueForKeypath:s are not equal, a new UITableView section is created between the cells for those objects.
// If each object should entirely be in its own section, set this to @"self".
@property (nonatomic, copy) NSString *dynamicRowsSectionSplitKeypath;

// You can bind the array of dynamic objects for this section to an object/keypath. Bindings are an alternative to using the AGTableDataController delegate methods to populate the section with dynamic objects.
// AGTable uses the KVO to-many operations to appropriately animate insertions/deletions/replacement.
- (void)bindDynamicObjectsArrayTo:(id)bindingObject keypath:(NSString*)keypath;

// Some properties for the gaps between sections
@property (nonatomic, assign) CGFloat headerHeight;
@property (nonatomic, assign) CGFloat footerHeight;
@property (nonatomic, assign) CGFloat splitSectionHeaderHeight;
@property (nonatomic, assign) CGFloat splitSectionFooterHeight;

@property (nonatomic, copy) WillDisplayHeaderBlock willDisplayHeaderBlock;

@end
