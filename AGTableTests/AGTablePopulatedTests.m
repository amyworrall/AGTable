//
//  AGTablePopulatedTests.m
//  AGTable
//
//  Created by Amy Worrall on 04/12/2012.
//

#import "AGTablePopulatedTests.h"
#import "AGTableRow.h"
#import <UIKit/UIKit.h>

@interface AGTablePopulatedTests ()<AGTableDataControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AGTableDataController *tdc;
@property (nonatomic, strong) AGTableRow *firstRow;
@property (nonatomic, strong) AGTableSection *s;

@end

@interface AGTableDataController ()<UITableViewDelegate,UITableViewDataSource>

@end

@implementation AGTablePopulatedTests

- (void)setUp
{
    [super setUp];
    
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tdc = [[AGTableDataController alloc] initWithTableView:self.tableView];
	self.tdc.delegate = self;
	
	AGTableSection *s = [self.tdc appendNewSectionWithTitle:@"Test"];
	self.firstRow = [s appendNewRow];
	s.rowPrototype = [[AGTableRow alloc] init];
	
	self.s = s;
}

- (void)tearDown
{
	[super tearDown];
}

- (void)testPrototypeCount
{
	STAssertTrue(self.s.rowPrototypes.count == 1, @"Add a single row prototype, shoves it in the array");
}

- (void)testConfigSelectors
{
	self.firstRow.initialSetupSelector = @selector(setupCell:forRow:);
	self.firstRow.configurationSelector = @selector(configureCell:forRow:);
	[self.tdc tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)setupCell:(UITableViewCell**)cell forRow:(AGTableRow*)row
{
	STAssertTrue([*cell isKindOfClass:[UITableViewCell class]], @"Setup selector should get a cell");
	STAssertTrue([row isKindOfClass:[AGTableRow class]], @"Setup selector should get a row");
}

- (void)configureCell:(UITableViewCell*)cell forRow:(AGTableRow*)row
{
	STAssertTrue([cell isKindOfClass:[UITableViewCell class]], @"Config selector should get a cell");
	STAssertTrue([row isKindOfClass:[AGTableRow class]], @"Config selector should get a row");
}

- (void)testActionSelectorForm
{
	self.firstRow.actionSelector = @selector(actionSelectorTest:);
	[self.tdc tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)actionSelectorTest:(AGTableRow*)row
{
	STAssertTrue([row isKindOfClass:[AGTableRow class]], @"Action selector should get a row");
}


- (void)testActionBlock
{
	self.firstRow.actionBlock = ^(AGTableRow *row){
		STAssertTrue([row isKindOfClass:[AGTableRow class]], @"Action block should get a row");
	};
	[self.tdc tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

@end
