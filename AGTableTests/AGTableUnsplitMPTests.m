//
//  AGTableUnsplitMPTests.m
//  AGTable
//
//  Created by Amy Worrall on 17/01/2013.
//

#import "AGTableUnsplitMPTests.h"
#import <objc/runtime.h>

@interface AGTableUnsplitMPTests ()<AGTableDataControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AGTableDataController *tdc;

@end

@interface AGTableDataController ()<UITableViewDelegate,UITableViewDataSource>

@end


@implementation AGTableUnsplitMPTests

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

- (id)tableDataController:(AGTableDataController *)c dynamicObjectForIndex:(NSInteger)index inSection:(AGTableSection *)section
{
	return @{@"Num" : [NSString stringWithFormat:@"%i", index]};
}

#pragma mark - Tests

- (void)testNumSectionsInTableView
{
	NSInteger num = [self.tdc numberOfSectionsInTableView:self.tableView];
	XCTAssertEqual(num, 1, @"Number of sections");
}

- (void)testNumRowsInSection0
{
	[self.tdc numberOfSectionsInTableView:self.tableView]; // Needed because this pre-caches the row visibility
	NSInteger num = [self.tdc tableView:self.tableView numberOfRowsInSection:0];
	XCTAssertEqual(num, 30, @"30 rows: 3 per 10 obects");
}

@end
