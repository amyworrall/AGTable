//
//  AGTableViewController.m
//  AGTable
//
//  Created by Amy Worrall on 10/12/2012.
//

#import "AGTableViewController.h"

@interface AGTableViewController ()
@property(strong, nonatomic) NSIndexPath *savedSelectedIndexPath;
@end


@implementation AGTableViewController

@synthesize tableDataController = _tableDataController;

- (id)init
{
  return [self initWithStyle:UITableViewStylePlain];
}

- (UITableViewStyle)tableViewStyle
{
	return UITableViewStylePlain;
}

- (id)initWithStyle:(UITableViewStyle)style
{
  if (self = [super initWithStyle:[self tableViewStyle]])
  {
    self.tableDataController = [[AGTableDataController alloc] initWithTableView:nil];
    self.tableDataController.delegate = self;
    self.clearsSelectionOnViewWillAppear = NO;
  }
  return self;
}

- (void)loadView
{
	[super loadView];
	[self.tableDataController setTableView:self.tableView];
}

// below code from http://stackoverflow.com/questions/19379510/uitableviewcell-doesnt-get-deselected-when-swiping-back-quickly

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  self.savedSelectedIndexPath = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  if (self.savedSelectedIndexPath) {
    [self.tableView selectRowAtIndexPath:self.savedSelectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  }
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.savedSelectedIndexPath = self.tableView.indexPathForSelectedRow;

  if (self.savedSelectedIndexPath) {
    [self.tableView deselectRowAtIndexPath:self.savedSelectedIndexPath animated:YES];
  }
}

@end
