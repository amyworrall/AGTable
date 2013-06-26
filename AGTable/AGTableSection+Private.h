//
//  AGTableSection+Private.h
//  AGTable
//
//  Created by Amy Worrall on 03/12/2012.
//

@interface AGTableSection ()

@property (nonatomic, weak) AGTableDataController *controller;
@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, assign) int tableRowsPerDynamicObject;
@property (nonatomic, strong) UIView *cachedHeaderEnclosingView;
@property (nonatomic, assign) BOOL cachedVisibility; // old, bool value.
@property (nonatomic,assign) int cachedNumSections; // the total number of UITable… sections for this AGSection. Includes one for static rows if applicable.
@property (nonatomic, copy) NSString *dynamicObjectsArrayKeypath;


- (int)_numberOfVisibleTableSections;
- (int)_numberOfRowsInInternalSectionNumber:(int)sectionNumber;
- (AGTableRow*)_rowForInternalIndexPath:(NSIndexPath *)indexPath;
- (AGTableRow*)_rowForSingleSectionSectionRowNumber:(int)rowNumber;
- (AGTableRow*)_rowForStaticSectionRowNumber:(int)rowNumber;
- (int)_numberOfStaticVisibleRows;
- (int)_numberOfDynamicObjects;
- (id) objectForDynamicRowNumber:(int)num;
- (void)cacheVisibility;
- (AGTableRow*)_staticRowForTag:(int)aTag;
- (int)_internalSectionNumberForStaticSection;
- (int)_rowNumberForRow:(AGTableRow*)r internalSection:(int*)local;
- (int)_dynamicObjectIndexForInternalIndexPath:(NSIndexPath*)p;
- (NSIndexPath*)_internalIndexPathForDynamicObjectIndex:(int)index;
- (int)_numberOfVisibleTableSections_nocache;
- (int)_numberOfRowPrototypesToShowForObject:(id)object;
- (NSUInteger)_numberOfDynamicRows;

@end