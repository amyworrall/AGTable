//
//  AGTableViewController.m
//  AGTable
//
//  Created by Amy Worrall on 10/12/2012.
//

#import "AGTableViewController.h"

@interface AGTableViewController ()
@end


@implementation AGTableViewController

@synthesize tableDataController = _tableDataController;

- (id)init
{
	if (self = [super initWithStyle:[self tableViewStyle]])
	{
		self.tableDataController = [[AGTableDataController alloc] initWithTableView:nil];
		self.tableDataController.delegate = self;
	}
	return self;
}

- (UITableViewStyle)tableViewStyle
{
	return UITableViewStylePlain;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self init];
}

- (void)loadView
{
	[super loadView];
	[self.tableDataController setTableView:self.tableView];
}



@end
