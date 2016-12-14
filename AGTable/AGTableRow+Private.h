//
//  AGTableRow+Private.h
//  AGTable
//
//  Created by Amy Worrall on 03/12/2012.
//



@interface AGTableRow ()

- (void)populateCell:(UITableViewCell*)cell;
- (void)dynamicPopulateCell:(UITableViewCell*)cell forObject:(id)object;


// override to make writeable
@property (nonatomic,assign) NSInteger rowNumber;
@property (readwrite, nonatomic, strong) NSIndexPath *tableIndexPath;



@property (nonatomic,strong) id lastReturnedObject;



@property (assign) BOOL accessoryTypeExplicitlySet;
 // NB retain not copy, for pointer
@property (assign) BOOL cachedVisibility;


@property (nonatomic, weak, readwrite) AGTableSection *section;



/// @name Private

// Private
- (void)_setSection:(AGTableSection*)section;
- (BOOL)_isVisible;

- (void)cacheVisibility;

// Private bindings stuff
@property (nonatomic, assign) BOOL isStaticRow;
@property (nonatomic, assign) BOOL insideBindingsUpdate;
@property (nonatomic, assign) BOOL isRowPrototype;
@property (nonatomic, strong) NSMutableArray *staticBindings;
@property (nonatomic, strong) NSMutableArray *dataObjectBindings;

@property (readwrite, nonatomic, assign) NSInteger objectIndex;

- (void)rowDidGainCell:(UITableViewCell*)cell;
- (void)rowWillLoseCell;
- (void)dynamicRowDidGainCell:(UITableViewCell*)cell forObject:(id)object;
- (void)dynamicRowWillLoseCellForObject:(id)object;

@property (nonatomic, assign) NSUInteger dynamicObjectIndex;

@end
