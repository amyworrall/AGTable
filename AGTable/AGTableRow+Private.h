//
//  AGTableRow+Private.h
//  AGTable
//
//  Created by Amy Worrall on 03/12/2012.
//



@interface AGTableRow ()


// override to make writeable
@property (nonatomic,assign) NSInteger rowNumber;



@property (nonatomic,strong) id lastReturnedObject;



@property (assign) BOOL accessoryTypeExplicitlySet;
 // NB retain not copy, for pointer
@property (assign) BOOL cachedVisibility;


@property (strong) NSMutableDictionary *textFieldBindings;
@property (nonatomic, strong) UITextField *cachedTextField;
@property (nonatomic, assign) BOOL textFieldShowsNextButton; // NB set by TDC
- (void)refreshImageCache;
@property (nonatomic,strong) UIImage *imageFieldCachedSmallImage;

/// Not yet implemented.
@property (nonatomic, assign) CGFloat imageFieldImageMaxWidth;


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
