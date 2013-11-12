//
//  AGTableDataController+Private.h
//  AGTable
//
//  Created by Amy Worrall on 03/12/2012.
//


@interface AGTableDataController ()

- (void)addRow:(AGTableRow*)row;
- (void)addRow:(AGTableRow*)row toSection:(int)sectionTag;
- (void)beginUpdates;
- (void)endUpdates;
- (void)refreshRowTagged:(int)rowTag inSection:(int)sectionTag;
- (void)commitTextFieldEditingOperations;
@property (nonatomic, strong) NSMutableArray *sections_mutable;

@property (nonatomic, weak) UITextField *editingTextField;
@property (nonatomic, weak) AGTableRow *rowForDateEditing;
@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, weak) AGTableRow *rowForImageEditing;


@property (nonatomic, assign) BOOL inUpdateBlock;
@property (nonatomic, assign) BOOL hasDoneAutoFocus;

@property (nonatomic, assign) BOOL hasDoneTextFieldNextButtonCache;

@property (nonatomic, assign) BOOL versionCheckMin3_1;
- (IBAction)showDatePicker:(id)sender;
- (void) textFieldDidBeginEditing:(UITextField *)textField;
//- (void) textFieldDidEndEditing:(UITextField *)textField;
- (void) textFieldChangedText:(NSString*)text forProperty:(NSString*)property;

- (id) delegateObjectForKeyPath:(NSString*)keypath;
- (id) objectForStaticRow:(AGTableRow*)row;
- (void)contentChangedForRow:(AGTableRow*)row;
- (BOOL)performVisibilityCheckForRow:(AGTableRow*)row;
- (BOOL)visibilityForDynamicRow:(AGTableRow*)row;
- (BOOL)canPerformActionForRow:(AGTableRow*)row;
- (void) textFieldDidEndEditing:(UITextField *)textField forRow:(AGTableRow*)row;
- (void)textFieldShouldReturn:(UITextField*)textField forRow:(AGTableRow*)row;
- (NSInteger)indexOfDynamicObjectAtTableIndexPath:(NSIndexPath*)indexPath;

// Array observing for dynamic objects
- (void)_sectionReloadDueToDynamicObjectArrayKVO:(AGTableSection*)section;




@end