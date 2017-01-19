//
//  AGTableSection.m
//  AGTableDataController
//
//  Created by Amy Worrall on 10/06/2011.
//

#import "AGTableDataController.h"
#import "AGTableDataController+Private.h"
#import "AGTableSection.h"
#import "AGTableSection+Private.h"
#import "AGTableRow.h"
#import "MAKVONotificationCenter.h"
#define maxInternalSections 2000

@interface AGTableSection ()
{
	NSInteger _internalSectionsRowCache[maxInternalSections];
}
@property (nonatomic, weak) id dynamicArrayBindingObject;
@property (nonatomic, copy) NSString *dynamicArrayBindingKeypath;
@property (nonatomic, assign) NSInteger cachedNumDynamicObjects;
@property (nonatomic, assign) NSInteger cachedNumDynamicRows;

@end


@implementation AGTableSection


+ (AGTableSection*)section;
{
	AGTableSection *section = [[AGTableSection alloc] init];
	
	return section;
}

+ (AGTableSection*)sectionWithTitle:(NSString*)title;
{
	AGTableSection *section = [[AGTableSection alloc] initWithTitle:title];
	
	return section;
}

- (id)init
{
	return [self initWithTitle:nil];
}

- (id)initWithTitle:(NSString*)aTitle;
{
	if (self = [super init])
	{
		self.title = aTitle;
		
		self.rows = [NSMutableArray array];
		self.rowPrototypes = [NSMutableArray array];
		self.tableRowsPerDynamicObject = 1;
		self.cachedNumSections = NSNotFound;
		self.cachedNumDynamicObjects = NSNotFound;
		self.cachedNumDynamicRows = NSNotFound;
	}
	return self;
}

- (AGTableRow*)rowPrototype
{
	if (self.rowPrototypes.count>0)
	{
		return [self.rowPrototypes objectAtIndex:0];
	}
	return nil;
}

- (void) setRowPrototype:(AGTableRow *)r
{
	self.rowPrototypes = @[r];
}



- (void)setRowPrototypes:(NSMutableArray *)rowPrototypes
{
	_rowPrototypes = rowPrototypes;
	
	for (AGTableRow *r in rowPrototypes)
	{
		r.isRowPrototype = YES;
		r.isStaticRow = NO;
		r.section = self;
	}
}

- (AGTableRow*)appendRow:(AGTableRow*)row
{
	row.controller = self.controller;
	row.isStaticRow = YES;
	[row _setSection:self];
	
	[self.rows addObject:row];
  return row;
}

- (AGTableRow*)appendNewRow
{
	AGTableRow *row = [AGTableRow rowWithCellClass:[UITableViewCell class]];
	[self appendRow:row];
	return row;
}

- (AGTableRow*)appendNewRowWithCellClass:(Class)cellClass
{
	AGTableRow *row = [AGTableRow rowWithCellClass:cellClass];
	[self appendRow:row];
	return row;
}

#pragma mark -
#pragma mark Getting numbers out


// Logic: if there is no sectionSplitKeypath, then there cannot be more than one section. If there is, then the dynamic rows are automatically split from the static ones, and split from each other wherever the keypath differs.

- (NSInteger)_numberOfVisibleTableSections
{
	return self.cachedNumSections;
}

- (NSInteger)_numberOfVisibleTableSections_nocache
{
	if (self.mode == sectionModeStatic)
	{
		return ([self _numberOfStaticVisibleRows]>0 ? 1 : 0);
	}
	
	NSInteger numDynamicObjects = [self _numberOfDynamicObjects];
	
	BOOL staticRowsPresent = ([self _numberOfStaticVisibleRows]>0);
	BOOL dynamicRowsPresent = (numDynamicObjects * self.tableRowsPerDynamicObject)>0;
	
	if (!dynamicRowsPresent)
		return (staticRowsPresent) ? 1 : 0;
	
	if ([self.dynamicRowsSectionSplitKeypath length]==0)
		return 1; // There are dynamic rows present, we do display them, and they are not in a separate table-section from the static rows.
	
	
	NSInteger numS = 0;
	
	id comparator = nil;
	for (int i=0; i<numDynamicObjects; i++)
	{
		id oldComparator = comparator;
		comparator = [[self objectForDynamicRowNumber:i] valueForKeyPath:self.dynamicRowsSectionSplitKeypath];
		
		if (![oldComparator isEqual:comparator])
		{
			numS++;
		}
	}
	
	
	if (staticRowsPresent)
		numS += 1; // If we reach this point, if there are any static rows, they'll be in a different section to the dynamic ones (due to presence of a sectionSplitKeypath), so we +1. 
	
	return numS;
}

- (NSInteger)_numberOfRowPrototypes
{
	return self.rowPrototypes.count;
}

- (NSInteger)_numberOfRowPrototypesToShowForObject:(id)object
{
	int count = 0;
	for (AGTableRow *prototype in self.rowPrototypes)
	{
		prototype.object = object;
		if ([self.controller visibilityForDynamicRow:prototype])
		{
			count++;
		}
	}
	return count;
}

- (NSArray*)_prototypesToShowForObject:(id)object
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:10];
	for (AGTableRow *prototype in self.rowPrototypes)
	{
		prototype.object = object;
		if ([self.controller visibilityForDynamicRow:prototype])
		{
			[array addObject:prototype];
		}
	}
	return array;
}

- (NSInteger)_numberOfRowsInInternalSectionNumber:(NSInteger)sectionNumber
{
	if (sectionNumber >= self.cachedNumSections)
	{
		return NSNotFound;
	}
	
	if (sectionNumber>=maxInternalSections)
		return 0;
	
	return _internalSectionsRowCache[sectionNumber];
}

- (NSInteger)_numberOfRowsInInternalSectionNumber_nocache:(NSInteger)sectionNumber
{
	if ([self.dynamicRowsSectionSplitKeypath length]==0 || self.mode == sectionModeStatic || [self _numberOfDynamicObjects]==0)
	{
		NSInteger i=[self _numberOfStaticVisibleRows];
		
		if (self.mode != sectionModeStatic)
		{
			for (int j=0; j<[self _numberOfDynamicObjects]; j++)
			{
				id object = [self objectForDynamicRowNumber:j];
				i += [self _numberOfRowPrototypesToShowForObject:object];
			}
		}
		return i;
	}
	
	// At this point, static and dynamic can't be in the same section
	
	BOOL staticAtStart = NO;
	BOOL staticAtEnd = NO;
	
	if ([self _numberOfStaticVisibleRows]>0)
	{
		if (self.mode == sectionModeStatic || self.mode == sectionModeStaticFirst)
		{
			staticAtStart = YES;
		}
		if (self.mode == sectionModeDynamicFirst)
		{
			staticAtEnd = YES;
		}
	}	
	
	NSInteger numSections = [self _numberOfVisibleTableSections];
	
	if ((sectionNumber == 0 && staticAtStart) || (sectionNumber == numSections-1 && staticAtEnd))
	{
		return [self _numberOfStaticVisibleRows];
	}
	
	// section is a dynamic section.
	
	if (staticAtStart)
	{
		sectionNumber--;
	}
	
	NSInteger sectionCounter = -1;
	NSInteger withinCounter = 0;
	
	id comparator = nil;
	for (int i=0; i<[self _numberOfDynamicObjects]; i++)
	{
		id object = [self objectForDynamicRowNumber:i];
		id oldComparator = comparator;
		comparator = [object valueForKeyPath:self.dynamicRowsSectionSplitKeypath];
		
		
		if (![oldComparator isEqual:comparator])
		{
      if (sectionCounter == sectionNumber)
      {
        return withinCounter;
      }

			sectionCounter ++;
			withinCounter = [self _numberOfRowPrototypesToShowForObject:object]; // this row counts as one for the next section.
		}
		else {
			withinCounter+=[self _numberOfRowPrototypesToShowForObject:object];
		}
	}

  // was last section correct?
  if (sectionCounter == sectionNumber)
  {
    return withinCounter;
  }

	[NSException raise:@"Couldn't count section" format:@"Something odd happened counting section with internal number %li", (long)sectionNumber];
	return NSNotFound;	
}




- (AGTableRow*)_rowForInternalIndexPath:(NSIndexPath *)indexPath
{
	NSInteger targetSectionNum = indexPath.section;
	NSInteger rowNum = indexPath.row;
	
	if ([self.dynamicRowsSectionSplitKeypath length]==0 || self.mode == sectionModeStatic || [self _numberOfDynamicObjects]==0)
	{
		// section contains only static
		return [self _rowForSingleSectionSectionRowNumber:rowNum];
	}
	
	// There cannot be static and dynamic in the same section. There are definitely visible dynamic objects. They're definitely split by keypath.
	
	
	BOOL staticAtStart = NO;
	BOOL staticAtEnd = NO;
	
	if ([self _numberOfStaticVisibleRows]>0)
	{
		if (self.mode == sectionModeStatic || self.mode == sectionModeStaticFirst)
		{
			staticAtStart = YES;
		}
		if (self.mode == sectionModeDynamicFirst)
		{
			staticAtEnd = YES;
		}
	}	
	
	NSInteger numVisibleSections = [self _numberOfVisibleTableSections];
	
	if ((targetSectionNum == 0 && staticAtStart) || (targetSectionNum == numVisibleSections-1 && staticAtEnd))
	{
		return [self _rowForStaticSectionRowNumber:rowNum];
	}
	
	
	// section is a dynamic section.
	int startS = 0;
	if (staticAtStart)
	{
		startS++;
	}
	
	int beforeCounter = 0;
	for (int i=startS; i<targetSectionNum; i++) // count all rows before the target section
	{
		if (i>=maxInternalSections)
			continue;
		
		beforeCounter += _internalSectionsRowCache[i];
	}
	
	/* Loop through dynamic objects, work out how many prototypes for each one, stop when value takes you past the desired number. */
	/* We need an object and a prototype to use */
	NSInteger targetRow = rowNum+beforeCounter;
	NSInteger rowCount = 0;
	
	id chosenObject;
	AGTableRow *chosenPrototype;
	NSUInteger chosenIndex = NSNotFound;
	
	for (int i=0; i<[self _numberOfDynamicObjects]; i++)
	{
		id object = [self objectForDynamicRowNumber:i];
		
		for (AGTableRow *aPrototype in [self _prototypesToShowForObject:object])
		{
			
			if (rowCount == targetRow)
			{
				chosenObject = object;
				chosenPrototype = aPrototype;
				chosenIndex = i;
			}
			rowCount++;
		}
	}
	
	chosenPrototype.object = chosenObject;
	chosenPrototype.rowNumber = indexPath.row;
	chosenPrototype.dynamicObjectIndex = chosenIndex;
	
	return chosenPrototype;
}





- (NSInteger)_dynamicObjectIndexForInternalIndexPath:(NSIndexPath*)p
{
	AGTableRow *row = [self _rowForInternalIndexPath:p];
	return row.dynamicObjectIndex;
	
//	int targetSectionNum = p.section;
//	int rowNum = p.row;
//
//	
//	if ([self.dynamicRowsSectionSplitKeypath length]==0)
//	{
//		// Do it the old way. Calculate dynamic offset.
//		int numStatic = [self _numberOfStaticVisibleRows];
//		
//		int dynamicOffset = (self.mode == sectionModeStaticFirst) ? numStatic : 0;
//		
//		if (self.mode == sectionModeDynamicFirst || self.mode == sectionModeDynamic)
//		{
//			return p.row;
//		}
//		return p.row - dynamicOffset;
//	}
//	
//	// We have a splitting keypath
//	if (self.mode == sectionModeStatic || self.mode == sectionModeStaticFirst)
//	{
//		targetSectionNum--;;
//	}
//	
//	int sectionCounter = 0;
//	int withinCounter = 0;
//	
//	id comparator = [[self objectForDynamicRowNumber:0] valueForKeyPath:self.dynamicRowsSectionSplitKeypath];
//	for (int i=0; i<[self _numberOfDynamicObjects]; i++)
//	{
//		id oldComparator = comparator;
//		comparator = [[self objectForDynamicRowNumber:i] valueForKeyPath:self.dynamicRowsSectionSplitKeypath];
//		
//		
//		if (sectionCounter == targetSectionNum && withinCounter == rowNum)
//		{
//			return i;
//		}
//		if (![oldComparator isEqual:comparator])
//		{
//			sectionCounter++;
//			withinCounter=0;
//		}
//		else
//		{
//			withinCounter++; // unlike the number of rows method, we're using withinCounter for index numbers rather than as a total.
//		}
//		
//		
//	}
//	return NSNotFound;
}


- (NSIndexPath*)_internalIndexPathForDynamicObjectIndex:(NSInteger)index
{
	if ([self.dynamicRowsSectionSplitKeypath length]==0)
	{
		// Do it the old way. Calculate dynamic offset.
		NSInteger numStatic = [self _numberOfStaticVisibleRows];
		
		NSInteger dynamicOffset = (self.mode == sectionModeStaticFirst) ? numStatic : 0;
		
		return [NSIndexPath indexPathForRow:index + dynamicOffset inSection:0];
	}
	
	// We have a splitting keypath
	int sectionOffset = 0;
	
	if (self.mode == sectionModeStatic || self.mode == sectionModeStaticFirst)
	{
		sectionOffset++;;
	}
	
	int sectionCounter = 0;
	int withinCounter = 0;
	
	id comparator = [[self objectForDynamicRowNumber:0] valueForKeyPath:self.dynamicRowsSectionSplitKeypath];
	for (int i=0; i<[self _numberOfDynamicObjects]; i++)
	{
		id oldComparator = comparator;
		comparator = [[self objectForDynamicRowNumber:i] valueForKeyPath:self.dynamicRowsSectionSplitKeypath];
		
		
		if (i == index)
		{
			return [NSIndexPath indexPathForRow:withinCounter inSection:sectionCounter + sectionOffset];
		}
		if (![oldComparator isEqual:comparator])
		{
			sectionCounter++;
			withinCounter=0;
		}
		else
		{
			withinCounter++; // unlike the number of rows method, we're using withinCounter for index numbers rather than as a total.
		}
		
		
	}
	return nil;
}

- (NSInteger)_internalSectionNumberForStaticSection
{
	if ([self _numberOfStaticVisibleRows]>0)
	{
		if (self.mode == sectionModeStatic || self.mode == sectionModeStaticFirst)
		{
			return 0;
		}
		if (self.mode == sectionModeDynamicFirst)
		{
			return [self _numberOfVisibleTableSections]-1;
		}
	}	
	return NSNotFound;
}


- (NSInteger)_rowNumberForRow:(AGTableRow*)r internalSection:(NSInteger*)local
{
	NSAssert(r.isStaticRow, @"Row number for row not working for dynamic rows yet");
	
	
	NSInteger staticS = [self _internalSectionNumberForStaticSection];
	
	NSInteger staticOffset;
	if ([self.dynamicRowsSectionSplitKeypath length]>0)
	{
		staticOffset = 0;
	}
	else if (self.mode == sectionModeDynamicFirst)
	{
		staticOffset = [self _numberOfDynamicObjects];
	}
	else {
		staticOffset = 0;
	}
	
	int i=0;
	for (AGTableRow *testRow in self.rows)
	{
		if ([testRow _isVisible])
		{
			if (testRow == r)
			{
				*local = staticS;
				return i + staticOffset;
			}
			
			i++;
		}
	}
	return NSNotFound;

}


- (NSUInteger)_numberOfDynamicRows
{
	if (self.mode == sectionModeStatic)
	{
		return 0;
	}
	
	// TODO: this cache is only useful when we're doing bindings. Otherwise, how would we invalidate it? TODO come up with a way to invalidate it.
	if (self.cachedNumDynamicRows != NSNotFound && self.dynamicArrayBindingObject)
	{
		return self.cachedNumDynamicRows;
	}
	
	NSUInteger count = 0;
	for (int i=0; i<self._numberOfDynamicObjects; i++)
	{
		count += [self _numberOfRowPrototypesToShowForObject:[self objectForDynamicRowNumber:i]];
	}
	self.cachedNumDynamicRows = count;
	return count;
}

- (AGTableRow*)_rowForSingleSectionSectionRowNumber:(NSInteger)rowNumber
{
	NSInteger numDynamicObjects = (self.mode != sectionModeStatic) ? [self _numberOfDynamicObjects] : 0;
	NSInteger numDynamicRows = [self _numberOfDynamicRows];
	NSInteger numStatic = [self _numberOfStaticVisibleRows];
	
	NSInteger dynamicOffset = (self.mode == sectionModeStaticFirst) ? numStatic : 0;
	NSInteger staticOffset = (self.mode == sectionModeDynamicFirst) ? numDynamicRows : 0;
	
	if ( rowNumber >= dynamicOffset && rowNumber < (dynamicOffset + numDynamicRows) )
	{
		NSInteger targetRow = rowNumber - dynamicOffset;
		NSInteger rowCount = 0;
		
		id chosenObject;
		AGTableRow *chosenPrototype;
		NSUInteger chosenIndex = NSNotFound;
		
		if (![self.controller delegateImplementsDynamicRowVisibility])
		{
			NSInteger prototypeNum = targetRow % self.rowPrototypes.count;
			NSInteger objectNum = (targetRow / self.rowPrototypes.count);
            chosenIndex = objectNum;
			
			chosenPrototype = self.rowPrototypes[prototypeNum];
			chosenPrototype.object = [self objectForDynamicRowNumber:objectNum];
			chosenPrototype.rowNumber = rowNumber;
			chosenPrototype.dynamicObjectIndex = chosenIndex;
			return chosenPrototype;
		}
		else // Have to do it the long way
		{
			for (int i=0; i<[self _numberOfDynamicObjects]; i++)
			{
				id object = [self objectForDynamicRowNumber:i];
				
				for (AGTableRow *aPrototype in [self _prototypesToShowForObject:object])
				{
					
					if (rowCount == targetRow)
					{
						chosenObject = object;
						chosenPrototype = aPrototype;
						chosenIndex = i;
					}
					rowCount++;
				}
			}
			
			chosenPrototype.object = chosenObject;
			chosenPrototype.rowNumber = rowNumber;
			chosenPrototype.dynamicObjectIndex = chosenIndex;
			return chosenPrototype;
		}
	}
	
	if ( rowNumber >= staticOffset && rowNumber < (staticOffset + numStatic) )
	{
		NSInteger desiredRowNum = rowNumber - staticOffset;
		AGTableRow *foundRow = nil;
		
		int i=0;
		for (AGTableRow *r in self.rows)
		{
			if ([r _isVisible])
			{
				if (i == desiredRowNum)
				{
					foundRow = r;
					break;
				}
				i++;
			}
		}
		
		if (foundRow)
		{
			foundRow.rowNumber = rowNumber;
			return foundRow;
		}
	}
	
	
	[NSException raise:@"Invalid row number" format:@"Something odd happened finding row %li: numD %li, numS %li, dO %li, sO %li", (long)rowNumber, (long)numDynamicObjects, (long)numStatic, (long)dynamicOffset, (long)staticOffset];
	return nil;	
}


- (AGTableRow*)_rowForStaticSectionRowNumber:(NSInteger)rowNumber
{
	AGTableRow *foundRow = nil;
	
	int i=0;
	for (AGTableRow *r in self.rows)
	{
		if ([r _isVisible])
		{
			if (i == rowNumber)
			{
				foundRow = r;
				break;
			}
			i++;
		}
	}
	
	if (foundRow)
	{
		foundRow.rowNumber = rowNumber;
		return foundRow;
	}
	return nil;
}


- (NSInteger)_numberOfStaticVisibleRows
{
	int i=0;
	if (self.mode != sectionModeDynamic)
	{
		for (AGTableRow *r in self.rows)
		{
			if ([r _isVisible])
			{
				i++;
			}
		}
	}
	return i;
}

- (void)setCachedNumDynamicObjects:(NSInteger)cachedNumDynamicObjects {
	_cachedNumDynamicObjects = cachedNumDynamicObjects;
}

- (NSInteger)_numberOfDynamicObjects
{
	if (self.dynamicArrayBindingObject)
	{
		if (self.cachedNumDynamicObjects != NSNotFound)
		{
			return self.cachedNumDynamicObjects;
		}
		NSArray *array = [self.dynamicArrayBindingObject valueForKeyPath:self.dynamicArrayBindingKeypath];
		self.cachedNumDynamicObjects = array.count;
		return self.cachedNumDynamicObjects;
	}
	
	// just use delegate methods, we're not KVOing
	return [self.controller.delegate tableDataController:self.controller numberOfDynamicObjectsInSection:self];
}

- (id) objectForDynamicRowNumber:(NSInteger)num
{
	if (self.dynamicArrayBindingObject)
	{
		NSArray *array = [self.dynamicArrayBindingObject valueForKeyPath:self.dynamicArrayBindingKeypath];
		return [array objectAtIndex:num];
	}

	// just use delegate methods, we're not KVOing
	return [self.controller.delegate tableDataController:self.controller dynamicObjectForIndex:num inSection:self];
}

- (void)bindDynamicObjectsArrayTo:(id)bindingObject keypath:(NSString*)keypath;
{
	self.dynamicArrayBindingObject = bindingObject;
	self.dynamicArrayBindingKeypath = keypath;
	
	[bindingObject addObserver:self keyPath:keypath selector:@selector(observeValueForKeyPath:ofObject:change:context:) userInfo:nil options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// so far just the dynamic object array, so we assume it's that.
	self.cachedNumDynamicObjects = NSNotFound;
	self.cachedNumDynamicRows = NSNotFound;
	
	NSInteger changeType = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
	
	if (changeType == NSKeyValueChangeSetting)
	{
    if (![change[NSKeyValueChangeNewKey] isEqual:change[NSKeyValueChangeOldKey]]) {
      [self.controller _sectionReloadDueToDynamicObjectArrayKVO:self];
    }
	}
	else if (changeType == NSKeyValueChangeInsertion)
	{
		NSIndexSet *set = [change objectForKey:NSKeyValueChangeIndexesKey];
		
//		[self.controller beginUpdates];
		[set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[self.controller section:self insertedDynamicObjectAtIndex:idx];
		}];
//		[self.controller endUpdates];
	}
	else if (changeType == NSKeyValueChangeRemoval)
	{
		NSIndexSet *set = [change objectForKey:NSKeyValueChangeIndexesKey];
		
//		[self.controller beginUpdates];
		[set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[self.controller section:self deletedDynamicObjectAtIndex:idx];
		}];
//		[self.controller endUpdates];
	}
	else if (changeType == NSKeyValueChangeReplacement)
	{
		NSIndexSet *set = [change objectForKey:NSKeyValueChangeIndexesKey];
		
//		[self.controller beginUpdates];
		[set enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[self.controller section:self replacedDynamicObjectAtIndex:idx];
		}];
//		[self.controller endUpdates];
	}
	
}


- (void)cacheVisibility
{
	for (AGTableRow *row in self.rows)
	{
		[row cacheVisibility];
	}
	self.cachedNumSections = [self _numberOfVisibleTableSections_nocache];
	
	for (int i=0; i<self.cachedNumSections; i++)
	{
		if (i>=maxInternalSections)
			continue;
		
		_internalSectionsRowCache[i] = [self _numberOfRowsInInternalSectionNumber_nocache:i];
	}
}

- (void)resetDynamicObjectsCaches;
{
  self.cachedNumDynamicRows = NSNotFound;
  self.cachedNumDynamicObjects = NSNotFound;
}

#pragma mark -
#pragma mark Doing things to rows


- (AGTableRow*)_staticRowForTag:(NSInteger)aTag;
{
	for (AGTableRow *r in self.rows)
	{
		if (r.tag == aTag)
		{
			return r;
		}
	}
	return nil;
}




@end
