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
@property (nonatomic,assign) NSInteger cachedNumSections; // the total number of UITable… sections for this AGSection. Includes one for static rows if applicable.
@property (nonatomic, copy) NSString *dynamicObjectsArrayKeypath;


- (NSInteger)_numberOfVisibleTableSections;
- (NSInteger)_numberOfRowsInInternalSectionNumber:(NSInteger)sectionNumber;
- (AGTableRow*)_rowForInternalIndexPath:(NSIndexPath *)indexPath;
- (AGTableRow*)_rowForSingleSectionSectionRowNumber:(NSInteger)rowNumber;
- (AGTableRow*)_rowForStaticSectionRowNumber:(NSInteger)rowNumber;
- (NSInteger)_numberOfStaticVisibleRows;
- (NSInteger)_numberOfDynamicObjects;
- (id) objectForDynamicRowNumber:(NSInteger)num;
- (void)cacheVisibility;
- (AGTableRow*)_staticRowForTag:(NSInteger)aTag;
- (NSInteger)_internalSectionNumberForStaticSection;
- (NSInteger)_rowNumberForRow:(AGTableRow*)r internalSection:(NSInteger*)local;
- (NSInteger)_dynamicObjectIndexForInternalIndexPath:(NSIndexPath*)p;
- (NSIndexPath*)_internalIndexPathForDynamicObjectIndex:(NSInteger)index;
- (NSInteger)_numberOfVisibleTableSections_nocache;
- (NSInteger)_numberOfRowPrototypesToShowForObject:(id)object;
- (NSUInteger)_numberOfDynamicRows;

- (void)resetDynamicObjectsCaches;

@end
