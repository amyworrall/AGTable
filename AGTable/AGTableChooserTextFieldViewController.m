//
//  AGTableChooserTextFieldViewController.m
//  AGTable
//
//  Created by Amy Worrall on 05/08/2011.
//

#import "AGTableChooserTextFieldViewController.h"


enum sectionTags
{
	SECTION_ONE
};

enum rowTags {
	ROW_ONE
};


@implementation AGTableChooserTextFieldViewController



#pragma mark -
#pragma mark Initialization


- (id)init
{
	return [self initWithStyle:UITableViewStyleGrouped];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
	{
		
	}
	return self;
}

- (void) viewDidLoad
{
	if (self.backgroundColor)
	{
		self.view.backgroundColor = self.backgroundColor;
	}
}


- (void) setUpTableView
{
	AGTableDataController *tdc = [[AGTableDataController alloc] initWithTableView:nil];
	tdc.delegate = self;
	
	AGTableSection *s;
	AGTableRow *r;
	
	// Section One
	s = [AGTableSection sectionWithTitle:nil];
	s.tag = SECTION_ONE;
	[tdc appendSection:s];
	
	// Row One
	r = [AGTableRow rowWithCellClass:nil];
	r.textFieldBoundToProperty = @"text";
	r.textFieldPlaceholder = self.delegate.title;
	[tdc addRow:r];
	r.textFieldAutoFocus = YES;
	r.textFieldAutocapitalizationType = UITextAutocapitalizationTypeSentences;
	r.textFieldAutocorrectionType = UITextAutocorrectionTypeNo;
	
	
	self.tableDataController = tdc;
}


#pragma mark -
#pragma mark AGTableDataController delegate methods


- (NSInteger)numberOfRowsInSection:(NSInteger)sectionTag tableDataController:(AGTableDataController*)c
{
	return 0;
}


- (id)objectForRow:(NSInteger)row inSection:(NSInteger)sectionTag tableDataController:(AGTableDataController*)c
{
	return nil;
}


#pragma mark -
#pragma mark View Lifecycle


- (void) loadView
{
	[super loadView];
	
	if (!self.tableDataController)
	{
		[self setUpTableView];
	}
	
	self.navigationItem.title = self.delegate.title;
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
	
	
	self.tableDataController.tableView = self.tableView;
}

- (void) viewWillAppear:(BOOL)animated
{
	
}

- (void)cancel:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)save:(id)sender
{
	[self.tableDataController commitTextFieldEditingOperations];
	self.delegate.otherChoice = self.text;
	self.delegate.currentlySelected = self.text;
	[self.delegate selectOtherOption];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidUnload 
{
    
}




@end

