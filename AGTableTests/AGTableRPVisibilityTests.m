//
//  AGTableRPVisibilityTests.m
//  AGTable
//
//  Created by Amy Worrall on 18/01/2013.
//

#import "AGTableRPVisibilityTests.h"
#import "AGTable+Private.h"
#import <objc/runtime.h>

@interface AGTableRPVisibilityTests ()<AGTableDataControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AGTableDataController *tdc;
@property (nonatomic, strong) AGTableSection *section;


@end

@interface AGTableDataController ()<UITableViewDelegate,UITableViewDataSource>

@end


@implementation AGTableRPVisibilityTests

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
	
	p1.tag=1;
	p2.tag=2;
	p3.tag=3;
	
	s.rowPrototypes = @[p1,p2,p3];
	self.section = s;
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

- (BOOL)tableDataController:(AGTableDataController *)c prototypeVisibilityForDynamicRow:(AGTableRow *)row
{
	// all visible, except the last one in object 2, and the first one in section 4
	if ([[row.object valueForKey:@"Num"] isEqual:@"2"])
	{
		return (row.tag != 3);
	}
	if ([[row.object valueForKey:@"Num"] isEqual:@"4"])
	{
		return (row.tag != 1);
	}
}

#pragma mark - Tests

// A row before the ones we're muddling
- (void)testEarlierRowVisible
{
	[self.tdc numberOfSectionsInTableView:self.tableView];
	[self.tdc tableView:self.tableView numberOfRowsInSection:0];
	UITableViewCell *cell = [self.tdc tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
	
	NSDictionary *object = objc_getAssociatedObject(cell, "obj");
	STAssertEqualObjects([object objectForKey:@"Num"], @"0", @"Object should be number 0");
	
	NSString *prototypeVal = objc_getAssociatedObject(cell, "val");
	STAssertEqualObjects(prototypeVal, @"Number2", @"Prototype should be 2 out of 3");
}

/* Row 8 should be first of 3, not last of 2, and should use first prototype */
- (void)testFirstRowForObject3
{
	[self.tdc numberOfSectionsInTableView:self.tableView];
	[self.tdc tableView:self.tableView numberOfRowsInSection:0];
	UITableViewCell *cell = [self.tdc tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:8 inSection:0]];
	
	NSDictionary *object = objc_getAssociatedObject(cell, "obj");
	STAssertEqualObjects([object objectForKey:@"Num"], @"3", @"Object should be number 3");
	
	NSString *prototypeVal = objc_getAssociatedObject(cell, "val");
	STAssertEqualObjects(prototypeVal, @"Number1", @"Prototype should be 1 out of 3");
}

/* Row 11 should be first of 4, which uses second prototype */
- (void)testFirstRowOfObject4
{
	[self.tdc numberOfSectionsInTableView:self.tableView];
	[self.tdc tableView:self.tableView numberOfRowsInSection:0];
	UITableViewCell *cell = [self.tdc tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:11 inSection:0]];
	
	NSDictionary *object = objc_getAssociatedObject(cell, "obj");
	STAssertEqualObjects([object objectForKey:@"Num"], @"4", @"Object should be number 4");
	
	NSString *prototypeVal = objc_getAssociatedObject(cell, "val");
	STAssertEqualObjects(prototypeVal, @"Number2", @"Prototype should be 2 out of 3");
}

- (void)testIndexOfDynamicObject
{
	[self.tdc numberOfSectionsInTableView:self.tableView];
	[self.tdc tableView:self.tableView numberOfRowsInSection:0];

	for (int i=0; i<12; i++)
	{
		int index = [self.tdc indexOfDynamicObjectAtTableIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		NSLog(@"Row %i, index %i", i, index);
	}
	
	int index = [self.tdc indexOfDynamicObjectAtTableIndexPath:[NSIndexPath indexPathForRow:8 inSection:0]];
	STAssertEquals(index, 3, @"Object should be 3");
}

- (void)testNumDynamicRows
{
	int dr = [self.section _numberOfDynamicRows];
	STAssertEquals(dr, 28, @"Two are hidden");
}

@end