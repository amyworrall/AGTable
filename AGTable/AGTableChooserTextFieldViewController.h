//
//  AGTableChooserTextFieldViewController.h
//
//  Created by Amy Worrall on 05/08/2011.
//

#import <UIKit/UIKit.h>
#import "AGTableDataController.h"
#import "AGTableDataControllerProtocols.h"

// This is the view controller that presents a text field, for when the user chooses "other" when using an AGTableChooserViewController.

@interface AGTableChooserTextFieldViewController : UITableViewController <AGTableDataControllerDelegate> 

@property (nonatomic, strong) AGTableDataController *tableDataController;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, weak) AGTableChooserViewController *delegate;
@property (nonatomic, strong) UIColor *backgroundColor;


- (void) setUpTableView;

@end
