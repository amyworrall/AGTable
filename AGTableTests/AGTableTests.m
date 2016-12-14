//
//  AGTableTests.m
//  AGTableTests
//
//  Created by Amy Worrall on 03/12/2012.
//

#import "AGTableTests.h"
#import <UIKit/UIKit.h>

@interface AGTableTests ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AGTableDataController *tdc;

@end

@implementation AGTableTests

- (void)setUp
{
    [super setUp];
    
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tdc = [[AGTableDataController alloc] initWithTableView:self.tableView];
	
}

- (void)tearDown
{
     [super tearDown];
}

- (void)testAddSection
{
	[self.tdc appendNewSection];
	XCTAssertTrue(self.tdc.sections.count == 1, @"Must have one section after appending");
}

- (void)testAddSectionWithTitle
{
	[self.tdc appendNewSectionWithTitle:@"Test"];
	XCTAssertEqualObjects([[self.tdc.sections objectAtIndex:0] title], @"Test", @"New section with title");
}

- (void)testAppendNewRow
{
	AGTableSection *s = [self.tdc appendNewSectionWithTitle:@"Test"];
	AGTableRow *r = [s appendNewRow];
	
	XCTAssertNotNil(r, @"Should return a row");
	XCTAssertTrue([r isKindOfClass:[AGTableRow class]], @"Should return a row of AGTableRow class");
	XCTAssertEqualObjects(r, [s.rows objectAtIndex:0], @"Row should be in the section");
}



@end
