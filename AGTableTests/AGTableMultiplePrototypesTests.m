//
//  AGTableMultiplePrototypesTests.m
//  AGTable
//
//  Created by Amy Worrall on 17/01/2013.
//

#import "AGTableMultiplePrototypesTests.h"
#import <objc/runtime.h>

@interface AGTableMultiplePrototypesTests ()<AGTableDataControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AGTableDataController *tdc;

@end

@interface AGTableDataController ()<UITableViewDelegate,UITableViewDataSource>

@end


@implementation AGTableMultiplePrototypesTests

- (void)setUp
{
    [super setUp];
    
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tdc = [[AGTableDataController alloc] initWithTableView:self.tableView];
	self.tdc.delegate = self;
	
	AGTableSection *s = [self.tdc appendNewSectionWithTitle:@"Test"];
	s.mode = sectionModeDynamic;
	
	AGTableRow *p1 = [[AGTableRow alloc] init];
	p1.configurationBlock = ^(UITableViewCell *cell, AGTableRow *row){
		objc_setAssociatedObject(cell, "val", @"Number1", OBJC_ASSOCIATION_RETAIN);
		objc_setAssociatedObject(cell, "obj", row.object, OBJC_ASSOCIATION_RETAIN);
	};
	AGTableRow *p2 = [[AGTableRow alloc] init];
	p2.configurationBlock = ^(UITableViewCell *cell, AGTableRow *row){
		objc_setAssociatedObject(cell, "val", @"Number2", OBJC_ASSOCIATION_RETAIN);
		objc_setAssociatedObject(cell, "obj", row.object, OBJC_ASSOCIATION_RETAIN);
	};
	AGTableRow *p3 = [[AGTableRow alloc] init];
	p3.configurationBlock = ^(UITableViewCell *cell, AGTableRow *row){
		objc_setAssociatedObject(cell, "val", @"Number3", OBJC_ASSOCIATION_RETAIN);
		objc_setAssociatedObject(cell, "obj", row.object, OBJC_ASSOCIATION_RETAIN);
	};
	
	s.rowPrototypes = @[p1,p2,p3];
	s.dynamicRowsSectionSplitKeypath = @"self";
	
}

- (void)tearDown
{
	[super tearDown];
}

#pragma mark - TDC delegate

- (NSInteger)tableDataController:(AGTableDataController *)c numberOfDynamicObjectsInSection:(AGTableSection *)section
{
	return 10;
}

- (id)tableDataController:(AGTableDataController *)c dynamicObjectForIndex:(int)index inSection:(AGTableSection *)section
{
	return @{@"Num" : [NSString stringWithFormat:@"%i", index]};
}

#pragma mark - Tests

- (void)testNumSectionsInTableView
{
	NSInteger num = [self.tdc numberOfSectionsInTableView:self.tableView];
	STAssertEquals(num, 10, @"Number of sections");
}

- (void)testNumRowsInSection0
{
	[self.tdc numberOfSectionsInTableView:self.tableView]; // Needed because this pre-caches the row visibility
	NSInteger num = [self.tdc tableView:self.tableView numberOfRowsInSection:1];
	STAssertEquals(num, 3, @"3 rows, for the 3 prototypes");
}

- (void)testExpectRP1
{
	[self.tdc numberOfSectionsInTableView:self.tableView]; // Needed because this pre-caches the row visibility
	NSInteger num = [self.tdc tableView:self.tableView numberOfRowsInSection:1];
	UITableViewCell *cell = [self.tdc tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	NSString *val = objc_getAssociatedObject(cell, "val");
	STAssertEqualObjects(val, @"Number1", @"Should get back a cell configured with rp 1");
}

- (void)testSection1Row1IsCorrectObject
{
	[self.tdc numberOfSectionsInTableView:self.tableView]; // Needed because this pre-caches the row visibility
	NSInteger num = [self.tdc tableView:self.tableView numberOfRowsInSection:1];
	UITableViewCell *cell = [self.tdc tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
	NSDictionary *object = objc_getAssociatedObject(cell, "obj");
	STAssertEqualObjects([object objectForKey:@"Num"], @"1", @"Object should be number 1");
}

- (void)testExpectRP2
{
	[self.tdc numberOfSectionsInTableView:self.tableView]; // Needed because this pre-caches the row visibility
	NSInteger num = [self.tdc tableView:self.tableView numberOfRowsInSection:1];
	UITableViewCell *cell = [self.tdc tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
	NSString *val = objc_getAssociatedObject(cell, "val");
	STAssertEqualObjects(val, @"Number2", @"Should get back a cell configured with rp 2");
}

@end
