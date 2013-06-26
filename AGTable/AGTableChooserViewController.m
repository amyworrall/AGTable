//
//  AGTableChooserViewController.m
//  AGTable
//
//  Created by Amy Worrall on 29/07/2011.
//

#import "AGTableChooserViewController.h"
#import "AGTableChooserTextFieldViewController.h"

enum sectionTags
{
	SECTION_ONE,
	SECTION_OTHER
};

enum rowTags {
	ROW_ONE,
	ROW_OTHER_TEXT,
	ROW_OTHER_BUTTON
};


@implementation AGTableChooserViewController


#pragma mark -
#pragma mark Initialization


- (id)init
{
	return [self initWithStyle:UITableViewStyleGrouped];
}

- (void) setOtherChoice:(NSString *)oc
{
	_otherChoice = [oc copy];
	[self.tableView reloadData];
}

- (void) viewDidLoad
{
	if (self.backgroundColor)
	{
		self.view.backgroundColor = self.backgroundColor;
	}
}


- (void) loadView
{
	[super loadView];
	
	self.navigationItem.title = self.title;
	self.currentlySelected = [self.delegate valueForKeyPath:self.delegateKeypath];
	
	BOOL flag = NO;
	for (NSDictionary *d in self.options)
	{
		if ([d[@"value"] isEqual:self.currentlySelected])
		{
			flag=YES;
		}
	}
	if (!flag)
	{
		self.otherChoice = self.currentlySelected;
	}
	
	AGTableDataController *tdc = [[AGTableDataController alloc] initWithTableView:self.tableView];
	tdc.delegate = self;
	
	AGTableSection *s;
	AGTableRow *r;
	
	// Section One
	s = [AGTableSection sectionWithTitle:nil];
	s.tag = SECTION_ONE;
	s.mode = sectionModeDynamic;
	[tdc appendSection:s];
	
	// Row One
	r = [AGTableRow rowWithCellClass:nil];
	r.tag = ROW_ONE;
	r.configurationSelector = @selector(configureCell:forRow:);
	r.actionSelector = @selector(actionChoseItem:);
	s.rowPrototype = r;
	
	
	s = [AGTableSection sectionWithTitle:nil];
	s.tag = SECTION_OTHER;
	s.mode = sectionModeStatic;
	[tdc appendSection:s];
	
	r = [s appendNewRow];
	r.tag = ROW_OTHER_TEXT;
	r.configurationSelector = @selector(configureOtherCell:forRow:);
	r.visibilityMode = visibilityModeDelegate;
	r.actionSelector = @selector(selectOtherOption);
	
	r = [s appendNewRow];
	r.tag = ROW_OTHER_BUTTON;
	r.text = @"Other";
	r.visibilityMode = visibilityModeDelegate;
	r.actionSelector = @selector(otherButton);
	
	self.tableDataController = tdc;
}


#pragma mark -
#pragma mark AGTableDataController delegate methods


- (NSInteger)tableDataController:(AGTableDataController *)c numberOfDynamicObjectsInSection:(AGTableSection *)section
{
	return [self.options count];
}


- (id)tableDataController:(AGTableDataController *)c dynamicObjectForIndex:(int)index inSection:(AGTableSection *)section
{
	return (self.options)[index];
}

- (void)configureCell:(UITableViewCell*)cell forRow:(AGTableRow*)row
{
	NSDictionary *object = (NSDictionary *)row.object;
	
	cell.textLabel.text = object[@"title"];
	
	if ([self.currentlySelected isEqual:object[@"value"]])
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
}

- (void)configureOtherCell:(UITableViewCell*)cell forRow:(AGTableRow*)row
{
	cell.textLabel.text = self.otherChoice;
	
	if ([self.currentlySelected isEqual:self.otherChoice])
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
}

- (void)selectOtherOption
{
	self.currentlySelected = self.otherChoice;
	[self.delegate setValue:self.currentlySelected forKey:self.delegateKeypath];
	[self.tableView reloadData];
}


- (BOOL)tableDataController:(AGTableDataController *)c visibilityForRow:(AGTableRow *)row
{
	switch (row.tag)
	{
		case ROW_OTHER_TEXT:
			return ([self.otherChoice length]>0 && self.allowsOther);
		case ROW_OTHER_BUTTON:
			return (self.allowsOther);
	}
	return NO;
}


- (void)actionChoseItem:(AGTableRow*)row
{
	NSDictionary *anItem = (NSDictionary*)row.object;
	
	self.currentlySelected = anItem[@"value"];
	[self.delegate setValue:self.currentlySelected forKey:self.delegateKeypath];
	[self.tableView reloadData];
}

- (void)otherButton
{
	AGTableChooserTextFieldViewController *vc = [[AGTableChooserTextFieldViewController alloc] init];
	vc.delegate = self;
	vc.text = self.otherChoice;
	vc.backgroundColor = self.backgroundColor;
	
	[self configureTextFieldViewController:vc];
	
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)configureTextFieldViewController:(AGTableChooserTextFieldViewController*)vc
{
	
}

#pragma mark -
#pragma mark Disposal


- (void)viewDidUnload 
{
    self.tableDataController = nil;
}




@end

