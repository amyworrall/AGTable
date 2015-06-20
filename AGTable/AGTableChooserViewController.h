//
//  AGTableChooserViewController.h
//  AGTable
//
//  Created by Amy Worrall on 29/07/2011.
//

#import <UIKit/UIKit.h>
#import "AGTableDataController.h"
#import "AGTableDataControllerProtocols.h"

@class AGTableChooserTextFieldViewController;

// This is the view controller subclass that displays a choosable options list, which can be used as part of AGTable's simple forms support.

@interface AGTableChooserViewController : UITableViewController <AGTableDataControllerDelegate> 


@property (nonatomic, strong) AGTableDataController *tableDataController;

@property (nonatomic, strong) NSArray *options; // takes an array of dictionaries, with "value" and "title".
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NSString *delegateKeypath;

@property (nonatomic, assign) BOOL allowsOther;
@property (nonatomic, strong) id currentlySelected;
@property (nonatomic, copy) NSString *otherChoice;

@property (nonatomic, strong) UIColor *backgroundColor;

- (void)selectOtherOption;

// overridable
- (void)configureTextFieldViewController:(AGTableChooserTextFieldViewController*)vc;

@end
