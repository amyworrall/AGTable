//
//  AGTableDataController.m
//  AGTableDataController
//
//  Created by Amy Worrall on 10/06/2011.
//




#import "AGTableDataController.h"
#import "AGTableChooserViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>


@interface AGTableDataController()<UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate>
{
	BOOL editing;
	BOOL _justReloading;
	BOOL _hasMutations;
}

@property (nonatomic, strong) NSMutableArray *indexPathsToInsert;
@property (nonatomic, strong) NSMutableArray *indexPathsToDelete;
@property (nonatomic, strong) NSMutableArray *indexPathsToReload;

@property (nonatomic, assign) NSInteger previousNumberOfSections;

@property (nonatomic, strong) NSMapTable *cellHeightPrototypesForReuseIdentifiers;

@property (nonatomic, assign) NSInteger cachedRespondsToVisibilityDynamicSelector;

@property (nonatomic, assign) BOOL insideReorderingOperation;

@end

@implementation AGTableDataController

- (id)initWithTableView:(UITableView*)aTableView;
{
	
	if (self = [super init])
	{
		self.tableView = aTableView;
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
		
		self.sections_mutable = [NSMutableArray array];
		
		self.cellHeightPrototypesForReuseIdentifiers = [NSMapTable strongToWeakObjectsMapTable];
		
		self.editingTextField = nil;
		
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_UK"]];
		[df setDateStyle:NSDateFormatterMediumStyle];
		[df setTimeStyle:NSDateFormatterShortStyle];
		self.dateDisplayFormatter = df;
		
		// Cache a version check, to work around a bug with inserting table rows
		NSString *reqSysVer = @"3.1";
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
			self.versionCheckMin3_1 = YES;
		
		self.indexPathsToInsert = [NSMutableArray new];
		self.indexPathsToDelete = [NSMutableArray new];
		self.indexPathsToReload = [NSMutableArray new];
		
		self.previousNumberOfSections = NSIntegerMax;
		self.cachedRespondsToVisibilityDynamicSelector = NSNotFound;
		
	}
	return self;
}

- (id)init
{
	if (self = [self initWithTableView:nil])
	{
		
	}
	return self;
}

- (NSArray *)sections
{
	return [NSArray arrayWithArray:self.sections_mutable];
}

- (void)setTableView:(UITableView *)tv
{
	if (_tableView != tv)
	{
		_tableView.delegate = nil;
		_tableView.dataSource = nil;
		_tableView = tv;
		_tableView.delegate = self;
		_tableView.dataSource = self;
	}
}

- (void)appendSection:(AGTableSection*)section;
{
	section.controller = self;
	[self.sections_mutable addObject:section];
}

- (AGTableSection *)appendNewSectionWithTitle:(NSString *)title
{
	AGTableSection *s = [AGTableSection sectionWithTitle:title];
	[self appendSection:s];
	return s;
}

- (AGTableSection *)appendNewSection
{
	AGTableSection *s = [AGTableSection section];
	[self appendSection:s];
	return s;
}

- (void)addRow:(AGTableRow*)row;
{
	NSAssert(false, @"Deprecated this method of adding rows");
	row.controller = self;
	row.isStaticRow = YES;
	[row _setSection:[self.sections_mutable lastObject]];
	
	
	[((AGTableSection*)[self.sections_mutable lastObject]).rows addObject:row];
}

- (void)addRow:(AGTableRow*)row toSection:(NSInteger)sectionTag;
{
	NSAssert(false, @"Deprecated this method of adding rows");
	row.controller = self;
	row.isStaticRow = YES;
	
	for (AGTableSection *s in self.sections_mutable)
	{
		if (s.tag == sectionTag)
		{
			[s.rows addObject:row];
			[row _setSection:s];
			break;
		}
	}
}






#pragma mark -
#pragma mark Arithmancy


- (void)reloadTableView
{
	if (_justReloading)
	{
		return;
	}
	_justReloading = YES;
	[self.tableView reloadData];
	[self performSelector:@selector(resetReloadCounter) withObject:nil afterDelay:0.0];
}

- (void)resetReloadCounter
{
	_justReloading = NO;
}

- (AGTableSection*)sectionForTableSectionNumber:(NSInteger)index localSectionNumber:(NSInteger*)localIndex
{
	NSInteger sectionCounter = 0;
	for (AGTableSection *s in self.sections_mutable)
	{
		NSInteger num = [s _numberOfVisibleTableSections];
		NSInteger after = sectionCounter + num;
		
		if (index < after)
		{
			*localIndex = index - sectionCounter;
			return s;
		}
		
		sectionCounter = after;
	}
	return nil;
}

- (NSInteger)sectionNumberForSection:(AGTableSection*)section localSectionNumber:(NSInteger)localNum;
{
	NSInteger sectionCounter = 0;
	
	for (AGTableSection *s in self.sections_mutable)
	{
		if (s == section)
		{
			return sectionCounter + localNum;
		}
		sectionCounter += [s _numberOfVisibleTableSections];
	}
	return NSNotFound;
}


- (AGTableRow*)rowForTableIndexPath:(NSIndexPath*)indexPath;
{
	NSInteger local;
	AGTableSection *s = [self sectionForTableSectionNumber:indexPath.section localSectionNumber:&local];
	
	NSIndexPath *localIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:local];
	return [s _rowForInternalIndexPath:localIndexPath];
}


// The index path for a row before whatever editing operation happened (i.e. the cached value within the row object)
- (NSIndexPath*)previousIndexPathForRow:(AGTableRow*)row
{
	NSAssert(row.isStaticRow, @"previousIndexPathForRow only supports static rows");
	
	AGTableSection *s = row.section;
	NSInteger local = [s _internalSectionNumberForStaticSection];
	
	NSInteger sNum = [self sectionNumberForSection:s localSectionNumber:local];
	
	return [NSIndexPath indexPathForRow:row.rowNumber inSection:sNum];
}

// The index path for a row after whatever editing operation happened (i.e. derive it now)
- (NSIndexPath*)currentIndexPathForRow:(AGTableRow*)row
{
	NSAssert(row.isStaticRow, @"newIndexPathForRow only supports static rows");
	
	NSInteger local;
	NSInteger rowNum = [row.section _rowNumberForRow:row internalSection:&local];
	
	NSInteger sectionNum = [self sectionNumberForSection:row.section localSectionNumber:local];
	return [NSIndexPath indexPathForRow:rowNum inSection:sectionNum];
}


- (NSInteger)indexOfDynamicObjectAtTableIndexPath:(NSIndexPath*)indexPath
{
	NSInteger local;
	AGTableSection *s = [self sectionForTableSectionNumber:indexPath.section localSectionNumber:&local];
	
	NSIndexPath *p = [NSIndexPath indexPathForRow:indexPath.row inSection:local];
	return [s _dynamicObjectIndexForInternalIndexPath:p];
}

- (NSIndexPath*)indexPathForDynamicObjectIndex:(NSInteger)index inSection:(AGTableSection*)s
{
	NSIndexPath *p = [s _internalIndexPathForDynamicObjectIndex:index];
	NSInteger sNum = [self sectionNumberForSection:s localSectionNumber:p.section];
	return [NSIndexPath indexPathForRow:p.row inSection:sNum];
}

#pragma mark -
#pragma mark Other section/row getters

- (AGTableSection*)sectionForSectionTag:(NSInteger)tag
{
	for (AGTableSection *s in self.sections_mutable)
	{
		if (s.tag == tag)
		{
			return s;
		}
	}
	return nil;
}



#pragma mark -
#pragma mark Methods for getting data about rows/sections


- (id) objectForStaticRow:(AGTableRow*)row
{
	if ([self.delegate respondsToSelector:@selector(tableDataController:objectForStaticRow:)])
	{
		return [self.delegate tableDataController:self objectForStaticRow:row];
	}
	return nil;
}

- (id) delegateObjectForKeyPath:(NSString*)keypath
{
	if ([keypath length]==0)
		return nil;
	
	return [self.delegate valueForKeyPath:keypath];
}


// TODO: Using the _nocache method manually here does work, but it is inefficient for large tables. This needs a logic check.
- (void)contentChangedForRow:(AGTableRow*)row
{
//	NSLog(@"Content changed. Cached is %i", row.cacheVisibility);
	// logic here: first check if visibility changed for section, then for row, then just refresh row.
	
	if (_justReloading)
	{
		return;
	}
	
	if (!self.versionCheckMin3_1)
	{
		// bug in UITableView
		[self reloadTableView];
		return;
	}
	
	NSInteger cachedSections = row.section.cachedNumSections;
	NSInteger noCachedSections = [row.section _numberOfVisibleTableSections_nocache];

	if (cachedSections != noCachedSections)
	{
		
		if (cachedSections == 0 && noCachedSections == 1)
		{
//			int sectionNum = [self sectionNumberForSection:row.section localSectionNumber:0];
//			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionNum] withRowAnimation:UITableViewRowAnimationFade];
			// Disabled ^^ due to: when a section was inserted at the same time as a row reload, UITableView handled the section first. (This happened in LM when banner appeared at the same time as refreshing Recent Search Results on the homescreen.)
			[self reloadTableView];
		}
		else if (cachedSections == 1 && noCachedSections == 0)
		{
			//NSLog(@"WARNING: just reloading, due to difficult change. Need to implement a way to get what a section's index path would be if it were visible.");
			[self reloadTableView];
		}
		else 
		{
			//NSLog(@"WARNING: just reloading, due to difficult change.");
			[self reloadTableView];
		}
		
	}
	
	else if (row.cachedVisibility != [row _isVisible])
	{
		if ([row _isVisible] == NO)
		{
			[self.indexPathsToDelete addObject:[self previousIndexPathForRow:row]];
			[self setHasMutations];
		}
		else if ([row _isVisible] == YES)
		{
			[self.indexPathsToInsert addObject:[self currentIndexPathForRow:row]];
			[self setHasMutations];
		}


	}
	else if ([row _isVisible])
	{
		NSIndexPath *ip = [self currentIndexPathForRow:row];
		
		[self.indexPathsToReload addObject:ip];
		[self setHasMutations];

	}

	[row.section cacheVisibility];
		  
	
}


- (void)setHasMutations
{
	if (!_hasMutations)
	{
		_hasMutations = YES;

		[self performSelector:@selector(performMutations) withObject:nil afterDelay:0.0];
	}
}

- (void)performMutations
{
	_hasMutations = NO;
	
	if (_justReloading)
	{
		[self.indexPathsToDelete removeAllObjects];
		[self.indexPathsToInsert removeAllObjects];
		[self.indexPathsToReload removeAllObjects];
		return;
	}
	
	if (self.indexPathsToReload.count > 0 && (self.indexPathsToInsert.count > 0 || self.indexPathsToDelete.count > 0))
	{
		[self reloadTableView];
		[self.indexPathsToDelete removeAllObjects];
		[self.indexPathsToInsert removeAllObjects];
		[self.indexPathsToReload removeAllObjects];
		return;
	}
	
	/* By this point, we're going to do a begin/end updates. This will cause the table view to recheck its section count. Here, we check that it matches first — if it doesn't match our cache, then we abandon the animation and just do a reload. */
	NSInteger old = self.previousNumberOfSections;
	NSInteger new = [self numberOfSectionsInTableView:self.tableView]; // This is one of the few times it's OK to call this method other than from a table view
	
	if (old != new)
	{
		[self reloadTableView];
		[self.indexPathsToDelete removeAllObjects];
		[self.indexPathsToInsert removeAllObjects];
		[self.indexPathsToReload removeAllObjects];
		return;
	}
	
	[self.tableView beginUpdates];
	
	[self.tableView deleteRowsAtIndexPaths:self.indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView insertRowsAtIndexPaths:self.indexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView reloadRowsAtIndexPaths:self.indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
	
	[self.indexPathsToDelete removeAllObjects];
	[self.indexPathsToInsert removeAllObjects];
	[self.indexPathsToReload removeAllObjects];
	
	[self.tableView endUpdates];
}

- (BOOL)performVisibilityCheckForRow:(AGTableRow*)row
{
	if (row.section.cachedNumSections != [row.section _numberOfVisibleTableSections])
	{
		
		if (row.section.cachedNumSections == 0 && [row.section _numberOfVisibleTableSections] == 1)
		{
			NSInteger sectionNum = [self sectionNumberForSection:row.section localSectionNumber:0];
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionNum] withRowAnimation:UITableViewRowAnimationFade];
		}
		else if (row.section.cachedNumSections == 1 && [row.section _numberOfVisibleTableSections] == 0)
		{
			//NSLog(@"WARNING: just reloading, due to difficult change. Need to implement a way to get what a section's index path would be if it were visible.");
			[self reloadTableView];
		}
		else 
		{
			//NSLog(@"WARNING: just reloading, due to difficult change.");
			[self reloadTableView];
		}

		return YES;
	}
	else if (row.cachedVisibility != [row _isVisible])
	{
		if ([row _isVisible] == NO)
		{
			[self.indexPathsToDelete addObject:[self previousIndexPathForRow:row]];
			[self setHasMutations];

//			[self.tableView deleteRowsAtIndexPaths:@[[self previousIndexPathForRow:row]] withRowAnimation:UITableViewRowAnimationFade];
		}
		else if ([row _isVisible] == YES)
		{
			[self.indexPathsToInsert addObject:[self currentIndexPathForRow:row]];
			[self setHasMutations];

//			[self.tableView insertRowsAtIndexPaths:@[[self currentIndexPathForRow:row]] withRowAnimation:UITableViewRowAnimationFade];
		}
		return YES;
	}
	
		
	
	return NO;
}

- (BOOL)visibilityForDynamicRow:(AGTableRow*)row;
{
	if ([self delegateImplementsDynamicRowVisibility])
	{
		return [self.delegate tableDataController:self prototypeVisibilityForDynamicRow:row];
	}
	return YES;
}

- (BOOL)delegateImplementsDynamicRowVisibility;
{
	if (self.cachedRespondsToVisibilityDynamicSelector != NSNotFound)
	{
		if (self.cachedRespondsToVisibilityDynamicSelector)
		{
			return YES;
		}
		else
		{
			return NO;
		}
	}
	if ([self.delegate respondsToSelector:@selector(tableDataController:prototypeVisibilityForDynamicRow:)])
	{
		self.cachedRespondsToVisibilityDynamicSelector = (NSInteger)YES;
		return YES;
	}
	self.cachedRespondsToVisibilityDynamicSelector = (NSInteger)NO;
	return NO;
}

- (BOOL)canPerformActionForRow:(AGTableRow*)row
{
	if ([row.optionFieldBoundToProperty length]>0 || [row.imageFieldBoundToProperty length] > 0)
	{
		return YES;
	}
	if ([self.delegate respondsToSelector:@selector(tableDataController:canPerformActionForRow:)])
	{
		if ([self.delegate tableDataController:self canPerformActionForRow:row])
		{
			return (row.actionBlock != nil || row.actionSelector != nil);
		}
		return NO;
	}
	return (row.actionBlock != nil || row.actionSelector != nil);
}




#pragma mark -
#pragma mark UITableView data source methods


- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	// Some initial setup
	if (!self.hasDoneTextFieldNextButtonCache)
	{
		[self cacheTableViewNextButtons];
	}
	
	
	int snum=0;
	for (AGTableSection *s in self.sections_mutable)
	{
		[s cacheVisibility];
		snum += [s _numberOfVisibleTableSections];
	}
	
	// remember this for last time it was checked (see perform mutations)
	self.previousNumberOfSections = snum;
	
	return snum;
}



- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionNum
{
	NSInteger local;
	AGTableSection *s = [self sectionForTableSectionNumber:sectionNum localSectionNumber:&local];
	
	NSInteger retval = [s _numberOfRowsInInternalSectionNumber:local];
	
	return retval;
}

- (Class)cellClassForRow:(AGTableRow*)row
{
	Class cellClass = row.cellClass;
	
	if (!cellClass && [self.delegate respondsToSelector:@selector(tableDataController:cellClassForRow:)])
	{
		cellClass = [self.delegate tableDataController:self cellClassForRow:row];
	}
	
	if (!cellClass)
	{
		cellClass = [UITableViewCell class];
	}

	return cellClass;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	
	if (row.estimatedHeight > 0)
	{
		return row.estimatedHeight;
	}
	return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	id object = row.object;
	
	if (row.calculateHeightWithAutoLayout || row.calculateHeightWithPrototypeCell)
	{
		// 1. create cell to do the height calculation if needed
		NSString *reuseIdentifier = [self reuseIdentifierForIndexPath:indexPath];
		UITableViewCell *heightTestCell = [self.cellHeightPrototypesForReuseIdentifiers objectForKey:reuseIdentifier];
		 if (!heightTestCell)
		 {
			 heightTestCell = [self createCellForIndexPath:indexPath];
			 [self.cellHeightPrototypesForReuseIdentifiers setObject:heightTestCell forKey:reuseIdentifier];
		 }
		
		// 2. configure the cell, then ask for its layout
		heightTestCell.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 0.0);
		heightTestCell.accessoryType = [self accessoryTypeForRow:row];
		[self configureCell:heightTestCell forIndexPath:indexPath isForOffscreenUse:YES];
		[heightTestCell layoutIfNeeded];
		
		CGFloat height;
		if (row.calculateHeightWithAutoLayout)
		{
			CGSize size = [heightTestCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
			height = size.height;
		}
		else
		{
			UITableViewCell<AGTableCellHeight> *agCell = (UITableViewCell<AGTableCellHeight> *)heightTestCell;
			height = [agCell desiredCellHeight];
		}
		return height;
	}
	
	if (row.rowHeight)
	{
		return row.rowHeight;
	}
	
	if (row.heightBlock)
	{
		return row.heightBlock(row);
	}
	
	if (row.heightSelector)
	{
		IMP myImp1 = [self.delegate methodForSelector:row.heightSelector];
		CGFloat aDouble1 = ((CGFloat (*) (id,SEL,id))myImp1)(self.delegate,row.heightSelector,row);
		
		return aDouble1;
	}
	
	if ([[self cellClassForRow:row] respondsToSelector:@selector(cellHeightForRow:tableStyle:position:width:accessoryType:)])
	{
		CellPosition pos = [self cellPositionForIndexPath:indexPath];
		return [[self cellClassForRow:row] cellHeightForRow:row tableStyle:self.tableView.style position:pos width:self.tableView.bounds.size.width accessoryType:[self accessoryTypeForRow:row]];
	}
	
	
	
	
	NSString *heightString = row.text;
	if (row.autoHeightForObjectKeypath != nil)
	{
		heightString = [object valueForKeyPath:row.autoHeightForObjectKeypath];
	}
	
	if (row.autoHeightForText == YES || row.autoHeightForObjectKeypath != nil)
	{
		CGFloat width = 280.0;
		
		if ([self canPerformActionForRow:row] || row.accessoryType != UITableViewCellAccessoryNone)
		{
			width -= 20.0;
		}
		
		UIFont *font = (row.font) ? row.font : [UIFont systemFontOfSize:17.0];
		
		// Ignoring deprecation as we're supporting iOS 5
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		CGFloat fontHeight = [heightString sizeWithFont:font constrainedToSize:CGSizeMake(width, 4000.0) lineBreakMode:NSLineBreakByWordWrapping].height;
#pragma clang diagnostic pop
		
		return ((fontHeight + 20.0) > 44.0) ? fontHeight + 20.0 : 44.0;
	}
	
	
	// default
	return 44.0;
}

- (UITableViewCellAccessoryType)accessoryTypeForRow:(AGTableRow*)row
{
	if (row.accessoryTypeExplicitlySet == YES)
	{
		return row.accessoryType;
	}
	else
	{
		return ([self canPerformActionForRow:row]) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	}
}

#pragma mark - Creation

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self createCellForIndexPath:indexPath];
	[self configureCell:cell forIndexPath:indexPath isForOffscreenUse:NO];
	
	return cell;
}

- (UITableViewCellStyle)cellStyleForIndexPath:(NSIndexPath*)indexPath;
{
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	row.objectIndex = [self indexOfDynamicObjectAtTableIndexPath:indexPath];
	
	UITableViewCellStyle style = row.cellStyle;
	if ([row.textFieldBoundToProperty length]>0 && style == UITableViewCellStyleDefault && [row.text length]>0)
	{
		style = UITableViewCellStyleValue2;
	}
	
	if ([row.optionFieldBoundToProperty length]>0 && style == UITableViewCellStyleDefault && [row.text length]>0)
	{
		style = UITableViewCellStyleValue2;
	}
	
	if ([row.dateFieldBoundToProperty length]>0 && style == UITableViewCellStyleDefault && [row.text length]>0)
	{
		style = UITableViewCellStyleValue2;
	}
	return style;
}

- (NSString*)reuseIdentifierForIndexPath:(NSIndexPath*)indexPath
{
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	Class cellClass = [self cellClassForRow:row];
	UITableViewCellStyle style = [self cellStyleForIndexPath:indexPath];
	
	NSString *reuseIdentifier = nil;
	
	if ([self.delegate respondsToSelector:@selector(tableDataController:reuseIdentifierForRow:)])
	{
		reuseIdentifier = [self.delegate tableDataController:self reuseIdentifierForRow:row];
	}
	
	if (reuseIdentifier == nil)
	{
		if ([row.reuseIdentifier length]>0)
		{
			reuseIdentifier = row.reuseIdentifier;
		}
		else if ([cellClass isEqual:[UITableViewCell class]])
		{
			// possible optimisation: use a switch and constant strings, to get pointer comparisons.
			reuseIdentifier = [NSString stringWithFormat:@"UITableViewCell-%li-%@-%@-%p", (long)style, row.textFieldBoundToProperty, NSStringFromSelector(row.initialSetupSelector), row.initialSetupBlock];
			reuseIdentifier = @"Bob";
		}
		else
		{
			reuseIdentifier = NSStringFromClass(cellClass);
		}
	}
	return reuseIdentifier;
}

- (UITableViewCell*)createCellForIndexPath:(NSIndexPath*)indexPath;
{
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	row.objectIndex = [self indexOfDynamicObjectAtTableIndexPath:indexPath];
	
	Class cellClass = [self cellClassForRow:row];
	
	UITableViewCellStyle style = [self cellStyleForIndexPath:indexPath];
		
	
	// dequeue cell
	NSString *reuseIdentifier = [self reuseIdentifierForIndexPath:indexPath];
	
	// Attempt to dequeue
	UITableViewCell *cell = nil;
	cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	
	
	if (!cell)
	{
		
		if (row.cellNibName.length > 0)
		{
			NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:row.cellNibName owner:self options:nil];
			
			for (NSObject *obj in topLevelObjects)
			{
				if ([obj isKindOfClass:[UITableViewCell class]])
				{
					cell = (UITableViewCell*)obj;
				}
			}
		}
		
		if (!cell) // still no cell after loading the xib
		{
			cell = [[cellClass alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
		}
		
		if (row.initialSetupKeyValueData)
		{
			for (NSString *key in row.initialSetupKeyValueData)
			{
				[cell setValue:[row.initialSetupKeyValueData valueForKey:key] forKeyPath:key];
			}
		}
		
		if (row.initialSetupSelector)
		{
			IMP setupMethod = [self.delegate methodForSelector:row.initialSetupSelector];
			((void (*) (id,SEL,id*,id))setupMethod)(self.delegate, row.initialSetupSelector, &cell, row);
		}
		
		if (row.initialSetupBlock)
		{
			row.initialSetupBlock(&cell, row);
		}
		
		if ([row.textFieldBoundToProperty length]>0)
		{
			UITextField *tf = [[UITextField alloc] init];
			tf.adjustsFontSizeToFitWidth = YES;
			
			
			//tf.textColor = cell.detailTextLabel.textColor; // [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
			tf.tag = defaultTextfieldTag;
			
			
			[cell addSubview:tf];
		}
		
		
		
		if ([row.imageFieldBoundToProperty length]>0)
		{
			cell.imageView.layer.masksToBounds = YES;
			cell.imageView.layer.cornerRadius = 10.0;
		}
		
	}

	return cell;
}

- (void)configureCell:(UITableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath isForOffscreenUse:(BOOL)offscreen;
{
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	row.objectIndex = [self indexOfDynamicObjectAtTableIndexPath:indexPath];
	
	cell.tag = row.tag;
	
	cell.accessoryView = row.accessoryView;
	
	if ([row.optionFieldBoundToProperty length]>0)
	{
		id aValue = [self.delegate valueForKeyPath:row.optionFieldBoundToProperty];
		
		BOOL flag = NO;
		for (NSDictionary *aChoice in row.optionChoices)
		{
			if ([aChoice[@"value"] isEqual:aValue])
			{
				cell.detailTextLabel.text = aChoice[@"title"];
				flag = YES;
			}
		}
		if (row.optionAllowsOther && !flag)
		{
			cell.detailTextLabel.text = aValue;
		}
		
	}
	
	
	if ([row.dateFieldBoundToProperty length]>0)
	{
		if (row.datePickerTimeZone)
		{
			self.dateDisplayFormatter.timeZone = row.datePickerTimeZone;
		}
		else
		{
			self.dateDisplayFormatter.timeZone = [NSTimeZone defaultTimeZone];
		}
		
		cell.detailTextLabel.text = [self.dateDisplayFormatter stringFromDate:[self.delegate valueForKeyPath:row.dateFieldBoundToProperty]];
	}
	
	
	if ([row.imageFieldBoundToProperty length]>0)
	{
		cell.imageView.image = row.imageFieldCachedSmallImage;
	}
	
	if ([row.textFieldBoundToProperty length]>0)
	{
		UITextField *tf = (UITextField*)[cell viewWithTag:defaultTextfieldTag];
		
		tf.placeholder = row.textFieldPlaceholder ;
		tf.autocorrectionType = row.textFieldAutocorrectionType ;
		tf.autocapitalizationType = row.textFieldAutocapitalizationType;
		tf.keyboardType = row.textFieldKeyboardType;
		
		CGRect tfRect = ([row.text length]>0) ? CGRectMake(93, 11, 210, 20) : CGRectMake(20, 11, 320-40, 22);
		
		if (indexPath.row == 0 && self.tableView.style == UITableViewStyleGrouped)
		{
			tfRect.origin.y++;
		}
		tf.frame = tfRect;
		
		if ([self cellStyleForIndexPath:indexPath] == UITableViewCellStyleValue2)
		{
			tf.font = [UIFont boldSystemFontOfSize:15.0];
		}
		
		
		tf.clearButtonMode = row.textFieldClearButton ? UITextFieldViewModeWhileEditing : UITextFieldViewModeNever;
		tf.accessibilityLabel = row.text;
	}
	
	if ([[row.textFieldBindings allKeys] count]>0)
	{
		for (NSNumber *key in row.textFieldBindings)
		{
			int tfTag = [key intValue];
			NSString *property = (row.textFieldBindings)[key];
			
			UITextField *tf = (UITextField*)[cell viewWithTag:tfTag];
			
			if (tf)
			{
				tf.delegate = row;
				tf.text = [self.delegate valueForKey:property];
			}
		}
	}
	
	if ([row.textBoundToKeypath length]>0)
	{
		cell.textLabel.text = [self.delegate valueForKeyPath:row.textBoundToKeypath];
	}
	
	if ([row.detailTextBoundToKeypath length]>0)
	{
		cell.detailTextLabel.text = [self.delegate valueForKeyPath:row.detailTextBoundToKeypath];
	}
	
	if (![self canPerformActionForRow:row])
	{
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	else
	{
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	
	if (row.text)
	{
		cell.textLabel.text = row.text;
	}
	
	if (row.autoHeightForText)
	{
		cell.textLabel.numberOfLines = 0;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
#pragma clang diagnostic pop
	}
	
	if (row.font)
	{
		cell.textLabel.font = row.font;
	}
	
	if (row.detailText)
	{
		cell.detailTextLabel.text = row.detailText;
	}
	
	if (row.detailFont)
	{
		cell.detailTextLabel.font = row.detailFont;
	}
	
	cell.accessoryType = [self accessoryTypeForRow:row];
	
	
	
	cell.accessibilityTraits = row.accessibilityTraits;
	
	if ([self canPerformActionForRow:row])
	{
		cell.accessibilityTraits = cell.accessibilityTraits | UIAccessibilityTraitButton;
	}
	
	if (row.textFieldBoundToProperty)
	{
		UITextField *tf = (UITextField*)[cell viewWithTag:defaultTextfieldTag];
		
		cell.isAccessibilityElement = NO;
		cell.accessibilityTraits = UIAccessibilityTraitNone;
		cell.accessibilityLabel = nil;
		cell.textLabel.isAccessibilityElement = NO;
		cell.textLabel.accessibilityTraits = UIAccessibilityTraitNone;
		
		cell.accessibilityValue = tf.text;
		cell.accessibilityHint = @"Double tap to edit text field.";
		
		tf.returnKeyType = row.textFieldShowsNextButton ? UIReturnKeyNext : UIReturnKeyDone;
		
		row.cachedTextField = tf;
	}
	
	if (row.configurationKeyValueData)
	{
		for (NSString *key in row.configurationKeyValueData)
		{
			[cell setValue:[row.configurationKeyValueData valueForKey:key] forKeyPath:key];
		}
	}
	
	if (row.configurationSelector)
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[self.delegate performSelector:row.configurationSelector withObject:cell withObject:row];
#pragma clang diagnostic pop
	}
	
	if (row.configurationBlock)
	{
		row.configurationBlock(cell, row);
	}
	
	// START newBindings population
	if (!offscreen)
	{
		objc_setAssociatedObject(cell, "AGRow", row, OBJC_ASSOCIATION_ASSIGN);
		objc_setAssociatedObject(cell, "AGObject", row.object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
		if (row.isStaticRow)
		{
			[row rowDidGainCell:cell];
		}
		else if (row.isRowPrototype)
		{
			[row dynamicRowDidGainCell:cell forObject:row.object];
		}
	}
	else
	{
		// An offscreen (i.e. height prototype) cell
		if (row.isStaticRow)
		{
			[row populateCell:cell];
		}
		else if (row.isRowPrototype)
		{
			[row dynamicPopulateCell:cell forObject:row.object];
		}

	}
	// END newBindings
	
	if ([cell respondsToSelector:@selector(setCellPosition:)])
	{
		CellPosition pos = [self cellPositionForIndexPath:indexPath];
		[((UITableViewCell<AGTableCellProperties> *)cell) setCellPosition:pos];
	}
	
	if ([cell respondsToSelector:@selector(setTableStyle:)])
	{
		[((UITableViewCell<AGTableCellProperties> *)cell) setTableStyle:self.tableView.style];
	}
	
	if ([cell respondsToSelector:@selector(setRow:)])
	{
		[((UITableViewCell<AGTableCellProperties> *)cell) setRow:row];
	}

}

#pragma mark -


- (CellPosition)cellPositionForIndexPath:(NSIndexPath*)indexPath
{
	CellPosition pos = 0;
	
	if (indexPath.row == 0)
	{
		pos |= cellPositionFirst;
	}
	
	if (indexPath.row == [self tableView:self.tableView numberOfRowsInSection:indexPath.section] - 1)
	{
		pos |= cellPositionLast;
	}

	return pos;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	AGTableRow *row = objc_getAssociatedObject(cell, "AGRow"); //[self rowForTableIndexPath:indexPath];
	id object = objc_getAssociatedObject(cell, "AGObject"); 

	
	if (row.isStaticRow)
	{
		[row rowWillLoseCell];
	}
	else if (row.isRowPrototype)
	{
		[row dynamicRowWillLoseCellForObject:object];
	}
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	if (row.hasDeleteAction)
	{
		return UITableViewCellEditingStyleDelete;
	}
	else if (row.hasInsertAction)
	{
		return UITableViewCellEditingStyleInsert;
	}
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	return (row.hasDeleteAction || row.hasInsertAction);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    AGTableRow *row = [self rowForTableIndexPath:indexPath];
	if (row.isRowPrototype && row.section.canEditReorderDynamicRows)
	{
		return YES;
	}
	return NO;
}

-(NSIndexPath *) tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	// Just keep moves within their section, for now.
	if (sourceIndexPath.section != proposedDestinationIndexPath.section)
	{
		return sourceIndexPath;
	}
	
	// Also need to make sure it doesn't hit static rows
	// let's find out what's there already. THIS IS ONLY SAFE BECAUSE OF THE SECTION LIMIT ABOVE!
	AGTableRow *alreadyThere = [self rowForTableIndexPath:proposedDestinationIndexPath];
	if (!alreadyThere.isRowPrototype)
	{
		// trying to drag it within section, but either below or above where it should be. Work out which,  and snap drag to that end of the dynamic bit.
		if (proposedDestinationIndexPath.row > sourceIndexPath.row)
		{
			// drag downwards
			//return [self indexPathForLastDynamicObjectInSection:alreadyThere.section];
			return [self indexPathForDynamicObjectIndex:[alreadyThere.section _numberOfDynamicObjects]-1 inSection:alreadyThere.section];
		}
		// drag upwards
		//return [self indexPathForFirstDynamicObjectInSection:alreadyThere.section];
		return [self indexPathForDynamicObjectIndex:0 inSection:alreadyThere.section];
	}
	
	
	return proposedDestinationIndexPath;
}



-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath 
{
    self.insideReorderingOperation = YES;
    
	AGTableRow *row = [self rowForTableIndexPath:sourceIndexPath];
    id object = row.object; // have to grab the object now. The indexOfDynamicObjectAtTableIndexPath methods mutate the row prototype, so we can't rely on row being the same after those have been called.
	NSInteger dynamicIndex = [self indexOfDynamicObjectAtTableIndexPath:sourceIndexPath];
	NSInteger newDynamicIndex = [self indexOfDynamicObjectAtTableIndexPath:destinationIndexPath];
 	
	if (dynamicIndex == newDynamicIndex)
	{
		return;
	}
    
 	[self.delegate tableDataController:self dynamicItem:object index:dynamicIndex inSection:row.section didMoveToIndex:newDynamicIndex];
    
    self.insideReorderingOperation = NO;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// Returns the title if the table section is the first one for the local section of the section.
	NSInteger local;
	AGTableSection *s = [self sectionForTableSectionNumber:section localSectionNumber:&local];
	
	if (local>0)
	{
		return nil;
	}
	return s.title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionNum
{
	NSInteger local;
	AGTableSection *section = [self sectionForTableSectionNumber:sectionNum localSectionNumber:&local];
	UIView *hv = [section headerView];
	
	if (local>0)
	{
		return nil;
	}
	
	
	return hv;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	NSInteger local;
	AGTableSection *s = [self sectionForTableSectionNumber:section localSectionNumber:&local];
	
	
	UIView *hv = [s headerView];
	
	if (local>0)
	{
		return s.splitSectionHeaderHeight;
	}
	
	if (s.headerHeight>0)
	{
		return s.headerHeight;
	}

	
	if (hv)
	{
		return hv.bounds.size.height;
	}
	
//	if ([[s title] length]>0)
//	{
//		return (section == 0) ? 46.0 : 36.0;
//	}
	
	return -1;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	NSInteger local;
	AGTableSection *s = [self sectionForTableSectionNumber:section localSectionNumber:&local];
	
	if (local != ([s _numberOfVisibleTableSections]-1))
	{
		return nil;
	}
	
	return s.footerView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	NSInteger local;
	AGTableSection *s = [self sectionForTableSectionNumber:section localSectionNumber:&local];
	

	
	if (local != ([s _numberOfVisibleTableSections]-1))
	{
		return s.splitSectionFooterHeight;
	}
	
	if (s.footerHeight>0)
	{
		return s.footerHeight;
	}

	
	UIView *hv = [s footerView];
	if (hv)
	{
		return hv.bounds.size.height;
	}
	
	return 0;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	
	if (row.backgroundColor && !row.alternatingBackgroundColor)
	{
		cell.backgroundColor = row.backgroundColor;
	}
	else if (indexPath.row % 2 == 0 && row.backgroundColor)
	{
		cell.backgroundColor = row.backgroundColor;
	}
	else if (indexPath.row %2 == 1 && row.alternatingBackgroundColor)
	{
		cell.backgroundColor = row.alternatingBackgroundColor;
	}
	
	if (row.textFieldAutoFocus && !self.hasDoneAutoFocus)
	{
		self.hasDoneAutoFocus = YES;
		[[cell viewWithTag:defaultTextfieldTag] becomeFirstResponder];
	}
	
	if (row.willDisplayBlock) {
		row.willDisplayBlock(row, cell, indexPath);
	}
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	row.objectIndex = [self indexOfDynamicObjectAtTableIndexPath:indexPath];
	
	if (editingStyle == UITableViewCellEditingStyleDelete && row.hasDeleteAction)
	{
		[self.delegate tableDataController:self deletePressedForRow:row];
	}
	if (editingStyle == UITableViewCellEditingStyleInsert && row.hasInsertAction)
	{
		[self.delegate tableDataController:self insertPressedForRow:row];
	}
}

#pragma mark -
#pragma mark Animations & Reloading

- (void)beginUpdates
{
	[self.tableView beginUpdates];
	self.inUpdateBlock = YES;
}


- (void)reloadSectionTagged:(NSInteger)sectionTag animation:(UITableViewRowAnimation)animation
{

}


- (void)endUpdates
{
	self.inUpdateBlock = NO;
	[self.tableView endUpdates];
}




- (void)section:(AGTableSection*)s insertedDynamicObjectAtIndex:(NSInteger)index
{
	NSIndexPath *p = [self indexPathForDynamicObjectIndex:index inSection:s];
	
	NSInteger prevSections = [s _numberOfVisibleTableSections];
	NSInteger newSections = [s _numberOfVisibleTableSections_nocache];
	
	if (prevSections < newSections && prevSections==0)
	{
//		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:p.section] withRowAnimation:UITableViewRowAnimationAutomatic];
		// ^ removed since it conflicts with our handling of contentChanged: (the one where you toggle visibility of static rows)
		[self reloadTableView];
	}
	else
	{
		[self.indexPathsToInsert addObject:p];
		[self setHasMutations];

//		[self.tableView insertRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void)section:(AGTableSection*)s deletedDynamicObjectAtIndex:(NSInteger)index
{
	if ([s _numberOfVisibleTableSections]>1)
	{
		[NSException raise:@"Unimplemented" format:@"deletedDynamicObject… method not yet implemented for sections using the multiple table sections mode."];
	}
	NSIndexPath *p = [self indexPathForDynamicObjectIndex:index inSection:s];
	
	if ([s _numberOfVisibleTableSections] > [s _numberOfVisibleTableSections_nocache] && [s _numberOfVisibleTableSections_nocache]==0)
	{
		NSLog(@"[A] deleting section %li", (long)p.section);
//		[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:p.section] withRowAnimation:UITableViewRowAnimationAutomatic];
		// ^ removed since it conflicts with our handling of contentChanged: (the one where you toggle visibility of static rows)
		[self reloadTableView];
	}
	else
	{
		[self.indexPathsToDelete addObject:p];
		[self setHasMutations];

	}
}

- (void)section:(AGTableSection*)s replacedDynamicObjectAtIndex:(NSInteger)index
{
	NSIndexPath *p = [self indexPathForDynamicObjectIndex:index inSection:s];
	
	[self.indexPathsToReload addObject:p];
	[self setHasMutations];

	// VV old, for pre-ARC UKRR
//	[self.tableView reloadRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationAutomatic];
}



- (void)refreshRowTagged:(NSInteger)rowTag inSection:(NSInteger)sectionTag
{
	
	AGTableSection *s = [self sectionForSectionTag:sectionTag];
	AGTableRow *r = [s _staticRowForTag:rowTag];
	//NSLog(@"Refreshing the insert button: %i %i", rowTag, r.rowNumber);
	[self contentChangedForRow:r];
}

- (void)refreshStaticRow:(AGTableRow*)r
{
	[self contentChangedForRow:r];
}

- (void)_sectionReloadDueToDynamicObjectArrayKVO:(AGTableSection*)section
{
    if (self.insideReorderingOperation == YES) {
        return;
    }
    
	NSInteger numInternalSections = [section _numberOfVisibleTableSections];
	
	if (numInternalSections > 0)
	{
		// Not trying this -- would have to work out inserts/removals for the internal sections
		[self reloadTableView];
		return;
	}
	
	NSInteger sectionNum = [self sectionNumberForSection:section localSectionNumber:0];
	

	if ([section _numberOfVisibleTableSections] == 0 || [section _numberOfRowsInInternalSectionNumber:0] == 0)
	{
		// if section is empty, reload data. At the future, maybe
		[self reloadTableView];
		return;		
	}
	
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionNum] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark -
#pragma mark UITableView delegate methods


- (void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self commitTextFieldEditingOperations];

	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	row.objectIndex = [self indexOfDynamicObjectAtTableIndexPath:indexPath];

	
	if (![self canPerformActionForRow:row] && !row.textFieldBoundToProperty && !row.optionFieldBoundToProperty && !row.dateFieldBoundToProperty && !row.imageFieldBoundToProperty)
	{
		return;
	}
	
	if (row.actionSelector)
	{
				
		
		if ([self.delegate respondsToSelector:row.actionSelector])
		{
			[[UIApplication sharedApplication] sendAction:row.actionSelector to:self.delegate from:row forEvent:nil];
		}
		

	}
	else if (row.actionBlock)
	{
		row.actionBlock(row);
	}
	else if (row.textFieldBoundToProperty)
	{
		// If no other action to do and it has a default text field, we select that.
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
		UITextField *tf = (UITextField *)[cell viewWithTag:defaultTextfieldTag];
		[tf becomeFirstResponder];
	}
	else if (row.optionFieldBoundToProperty)
	{
		AGTableChooserViewController *vc = nil;
		if (row.customOptionSelectorViewController)
		{
			vc = [[row.customOptionSelectorViewController alloc] init];
		}
		else
		{
			vc = [[AGTableChooserViewController alloc] init];
		}
		
		vc.title = [row.text capitalizedString];
		vc.delegate = self.delegate;
		vc.delegateKeypath = row.optionFieldBoundToProperty;
		vc.options = row.optionChoices;
		vc.allowsOther = row.optionAllowsOther;
		vc.backgroundColor = self.delegate.view.backgroundColor;
		
		[[self.delegate valueForKeyPath:@"navigationController"] pushViewController:vc animated:YES];
	}
	else if (row.dateFieldBoundToProperty)
	{
		self.rowForDateEditing = row;
		[self showDatePicker:self];
	}
	else if (row.imageFieldBoundToProperty)
	{
		self.rowForImageEditing = row;
		
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Choose an image source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo Library", @"Camera", nil];
			[as showInView:self.delegate.view];
		}
		else {
			[self summonImagePickerForSource:UIImagePickerControllerSourceTypePhotoLibrary];
		}

		
		
	}
	
	if (self.clearSelectionOnAction)
	{
		[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	}

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//NSLog(@"Chosen %i", buttonIndex);
	// Has to be image picker sheet
	switch (buttonIndex) {
		case 0:
			[self summonImagePickerForSource:UIImagePickerControllerSourceTypePhotoLibrary];
			break;
		case 1:
			[self summonImagePickerForSource:UIImagePickerControllerSourceTypeCamera];
			break;
		default:
			break;
	}
}

- (void)summonImagePickerForSource:(UIImagePickerControllerSourceType)source
{
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
	imagePicker.sourceType = source;
	[self.delegate presentViewController:imagePicker animated:YES completion:nil];
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	AGTableRow *row = [self rowForTableIndexPath:indexPath];
	
	if (row.accessoryActionSelector)
	{
		if ([self.delegate respondsToSelector:row.accessoryActionSelector])
		{
			[[UIApplication sharedApplication] sendAction:row.accessoryActionSelector to:self.delegate from:row forEvent:nil];
		}

		
	}
	
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self.delegate setValue:info[UIImagePickerControllerOriginalImage] forKeyPath:self.rowForImageEditing.imageFieldBoundToProperty];
	[self.rowForImageEditing refreshImageCache];
	
	[picker dismissViewControllerAnimated:YES completion:nil];
	
	self.rowForImageEditing = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	//NSLog(@"Cancel");
	[picker dismissViewControllerAnimated:YES completion:nil];
	self.rowForImageEditing = nil;
}

#pragma mark -

- (BOOL)editing
{
	return editing;
}

- (void)setEditing:(BOOL)e
{
	editing = e;
	
//	[self.tableView beginUpdates];
	for (AGTableSection *s in self.sections_mutable)
	{
		for (AGTableRow *r in s.rows)
		{
			[self performVisibilityCheckForRow:r];
		}
	}
//	[self.tableView endUpdates];
}





#pragma mark -

- (void) textFieldDidBeginEditing:(UITextField *)textField;
{
	self.editingTextField = textField;
}

- (void) textFieldDidEndEditing:(UITextField *)textField forRow:(AGTableRow*)row
{
	UITableViewCell *c = (UITableViewCell*)[textField superview];
	c.accessibilityValue = textField.text;
	
	self.editingTextField = nil;
}

- (void)textFieldShouldReturn:(UITextField*)textField forRow:(AGTableRow*)row
{
	//NSLog(@"ReturnReturn");
	BOOL foundTarget = NO;
	BOOL doneBecome = NO;
	for (AGTableSection *s in self.sections_mutable)
	{
		for (AGTableRow *r in s.rows)
		{
			//NSLog(@"FoundTarget %i, doneBecome %i, bound %@", foundTarget, doneBecome, r.textFieldBoundToProperty);
			if (foundTarget == YES && doneBecome == NO && r.textFieldBoundToProperty)
			{
				//NSLog(@"Trying");
				[self.tableView scrollToRowAtIndexPath:[self previousIndexPathForRow:r] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
				[r.cachedTextField becomeFirstResponder];
				doneBecome = YES;
			}
			if (r == row)
			{
				//NSLog(@"Target");
				foundTarget = YES;
			}
		}
	}
	if (!doneBecome)
	{
		[textField resignFirstResponder];
	}
	
}

- (void)commitTextFieldEditingOperations
{
	if (self.editingTextField)
	{
		[self.editingTextField resignFirstResponder];
	}
}

- (void) textFieldChangedText:(NSString*)text forProperty:(NSString*)property;
{
	[self.delegate setValue:text forKey:property];
}



#pragma mark -
#pragma mark Date Picker Methods

- (void)changeDate:(UIDatePicker *)sender {
	[self.delegate setValue:sender.date forKeyPath:self.rowForDateEditing.dateFieldBoundToProperty];
	[self refreshStaticRow:self.rowForDateEditing];
}

- (void)removeViews:(id)object {
	UIView *dpView = [[UIApplication sharedApplication] windows][0];
	
	[[dpView viewWithTag:9] removeFromSuperview];
	[[dpView viewWithTag:10] removeFromSuperview];
	[[dpView viewWithTag:11] removeFromSuperview];
	self.rowForDateEditing = nil;
}

- (void)dismissDatePicker:(id)sender {
	UIView *dpView = [[UIApplication sharedApplication] windows][0];
	
	[self changeDate:(UIDatePicker*)[dpView viewWithTag:10]];
	
	CGRect toolbarTargetFrame = CGRectMake(0, dpView.bounds.size.height, 320, 44);
	CGRect datePickerTargetFrame = CGRectMake(0, dpView.bounds.size.height+44, 320, 216);
	[UIView beginAnimations:@"MoveOut" context:nil];
	[dpView viewWithTag:9].alpha = 0;
	[dpView viewWithTag:10].frame = datePickerTargetFrame;
	[dpView viewWithTag:11].frame = toolbarTargetFrame;
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removeViews:)];
	[UIView commitAnimations];
}

- (void)showDatePicker:(id)sender {
	UIView *dpView = [[UIApplication sharedApplication] windows][0];
	
	if ([dpView viewWithTag:9]) {
		return;
	}
	
	CGRect toolbarTargetFrame = CGRectMake(0, dpView.bounds.size.height-216-44, 320, 44);
	CGRect datePickerTargetFrame = CGRectMake(0, dpView.bounds.size.height-216, 320, 216);
	
	UIView *darkView = [[UIView alloc] initWithFrame:dpView.bounds];
	darkView.alpha = 0;
	darkView.backgroundColor = [UIColor blackColor];
	darkView.tag = 9;
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDatePicker:)];
	[darkView addGestureRecognizer:tapGesture];
	[dpView addSubview:darkView];
	
	UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, dpView.bounds.size.height+44, 320, 216)];
	datePicker.tag = 10;
	
	
	
	[datePicker addTarget:self action:@selector(changeDate:) forControlEvents:UIControlEventValueChanged];
	
	if (self.rowForDateEditing.datePickerTimeZone)
	{
		datePicker.timeZone = self.rowForDateEditing.datePickerTimeZone;
	}

	NSDate *d = [self.delegate valueForKeyPath:self.rowForDateEditing.dateFieldBoundToProperty];
	if ([d isKindOfClass:[NSDate class]])
	{
		datePicker.date = d;
	}
	
	[dpView addSubview:datePicker];
	
	UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, dpView.bounds.size.height, 320, 44)];
	toolBar.tag = 11;
	toolBar.barStyle = UIBarStyleBlackTranslucent;
	UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissDatePicker:)];
	[toolBar setItems:@[spacer, doneButton]];
	[dpView addSubview:toolBar];
	
	[UIView beginAnimations:@"MoveIn" context:nil];
	toolBar.frame = toolbarTargetFrame;
	datePicker.frame = datePickerTargetFrame;
	darkView.alpha = 0.5;
	[UIView commitAnimations];
	
	//NSLog(@"Date picker %@", NSStringFromCGRect(datePicker.frame));
}


- (void)cacheTableViewNextButtons
{
	AGTableRow *previous = nil;
	for (AGTableSection *s in self.sections_mutable)
	{
		for (AGTableRow *r in s.rows)
		{
			if (r.textFieldBoundToProperty)
			{
				previous.textFieldShowsNextButton = YES;
				previous = r;
			}
		}
	}
	self.hasDoneTextFieldNextButtonCache = YES;
}


@end
