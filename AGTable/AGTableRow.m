//
//  AGTableRow.m
//  AGTableDataController
//
//  Created by Amy Worrall on 10/06/2011.
//

#import "AGTableRow.h"
#import "AGTableDataController.h"
#import "MAKVONotificationCenter.h"

NSString * const AGRowBindingStatic = @"AGRowBindingStatic";
NSString * const AGRowBindingObjectProperty = @"AGRowBindingObjectProperty";
NSString * const AGRowBindingObject = @"AGRowBindingObject";

@interface AGTableRow ()
@property (nonatomic, strong) NSMapTable *dynamicRowBindingsByObject;
@end

@implementation AGTableRow

@synthesize object = _object;


+ (AGTableRow*)rowWithCellClass:(Class)cellClass;
{
	AGTableRow *row = [[AGTableRow alloc] initWithCellClass:cellClass];
	
	return row;
}

- (id)init
{
	return [self initWithCellClass:nil];
}

- (id)initWithCellClass:(Class)aCellClass
{
	if (self = [super init])
	{
		self.initialSetupKeyValueData = [NSMutableDictionary dictionary];
		self.configurationKeyValueData = [NSMutableDictionary dictionary];
		self.textFieldBindings = [NSMutableDictionary dictionary];
		
		self.staticBindings = [NSMutableArray array];
		self.dataObjectBindings = [NSMutableArray array];
		
		self.visible = YES;
		self.visibilityMode = visibilityModeStandard;
		self.textFieldClearButton = YES;
		self.textFieldAutocapitalizationType = UITextAutocapitalizationTypeSentences;
		self.textFieldAutocorrectionType = UITextAutocorrectionTypeNo;
		
		self.cellClass = aCellClass;
		
		
	}
	return self;
}

- (void)addConfigurationValue:(id)value forKeyPath:(NSString*)key;
{
	if (value == nil)
	{
		[self.configurationKeyValueData removeObjectForKey:key];
		return;
	}
	
	(self.configurationKeyValueData)[key] = value;
}

#pragma mark - Doing stuff

- (void)refresh;
{
	[self.controller refreshStaticRow:self];
}

#pragma mark -
#pragma mark Bindings



- (void) bind:(id)anObject keypath:(NSString*)anObjectKP toCellKeypath:(NSString*)cellKeypath options:(NSDictionary*)options;
{
	
	NSAssert(self.isStaticRow, @"Binding an object/keypath pair only works on a static row.");
	
	
	AGBinding *binding = [[AGBinding alloc] init];
	binding.modelObject = anObject;
	binding.modelKeypath = anObjectKP;
	binding.viewKeypath = cellKeypath;
	binding.options = options;
	
	[self.staticBindings addObject:binding];
	
}

- (void) bind:(id)anObject keypath:(NSString*)objectKeypath toViewWithTag:(int)tag keypath:(NSString*)viewKeypath options:(NSDictionary*)options;
{
	AGBinding *binding = [[AGBinding alloc] init];
	binding.modelObject = anObject;
	binding.modelKeypath = objectKeypath;
	binding.viewTag = tag;
	binding.viewKeypath = viewKeypath;
	binding.options = options;
	
	[self.staticBindings addObject:binding];

}

- (void) bindDataObjectKeypath:(NSString*)rowObjectKeypath toCellKeypath:(NSString*)cellKeypath options:(NSDictionary*)options;
{
	
	AGBinding *binding = [[AGBinding alloc] init];
	binding.modelObject = self.object;
	binding.modelKeypath = rowObjectKeypath;
	binding.viewKeypath = cellKeypath;
	binding.options = options;
	binding.isBindingPrototype = self.isRowPrototype;
	
	[self.dataObjectBindings addObject:binding];
	

}

- (void) bindDataObjectKeypath:(NSString*)rowObjectKeypath toViewWithTag:(int)tag keypath:(NSString*)viewKeypath options:(NSDictionary*)options;
{
	AGBinding *binding = [[AGBinding alloc] init];
	binding.modelObject = self.object;
	binding.modelKeypath = rowObjectKeypath;
	binding.viewTag = tag;
	binding.viewKeypath = viewKeypath;
	binding.options = options;
	binding.isBindingPrototype = self.isRowPrototype;
	
	[self.dataObjectBindings addObject:binding];

}

- (void) unbind:(id)anObject keypath:(NSString*)objectKeypath cellKeypath:(NSString*)cellKeypath;
{
	
}

- (void) unbind:(id)anObject keypath:(NSString*)objectKeypath viewWithTag:(int)tag keypath:(NSString*)viewKeypath;
{
	
}

- (void) unbindDataObjectKeypath:(NSString*)rowObjectKeypath cellKeypath:(NSString*)cellKeypath;
{
	
}

- (void) unbindDataObjectKeypath:(NSString*)rowObjectKeypath viewWithTag:(int)tag keypath:(NSString*)viewKeypath;
{
	
}

- (void) unbindAll
{
	self.dataObjectBindings = [NSMutableArray array];
	self.staticBindings = [NSMutableArray array];
}


- (id) valueForBoundCellKeypath:(NSString*)keypath;
{
	return [self valueForBoundViewTag:NSNotFound keypath:keypath];
}

- (id) valueForBoundViewTag:(NSInteger)tag keypath:(NSString*)keypath;
{
	for (AGBinding *b in self.dataObjectBindings)
	{
		if ([b.viewKeypath isEqualToString:keypath] && b.viewTag == tag)
		{
			return [b currentModelValue];
		}
	}
	for (AGBinding *b in self.staticBindings)
	{
		if ([b.viewKeypath isEqualToString:keypath] && b.viewTag == tag)
		{
			return [b currentModelValue];
		}
	}
	return nil;
}

// for offscreen prototype
- (void)populateCell:(UITableViewCell*)cell;
{
	NSAssert(self.isStaticRow, @"Only static rows should gain cells via this method.");
	for (AGBinding *b in self.staticBindings)
	{
		[b applyDataToCell:cell forObject:b.modelObject];
	}
	for (AGBinding *b in self.dataObjectBindings)
	{
		[b applyDataToCell:cell forObject:self.object];
	}
}

- (void)rowDidGainCell:(UITableViewCell*)cell;
{
	NSAssert(self.isStaticRow, @"Only static rows should gain cells via this method.");
	
	for (AGBinding *b in self.staticBindings)
	{
		b.cell = cell;
	}
	for (AGBinding *b in self.dataObjectBindings)
	{
		b.cell = cell;
	}
}

- (void)dynamicPopulateCell:(UITableViewCell*)cell forObject:(id)object;
{
	NSAssert(self.isRowPrototype, @"Only prototypes should lose cells via this method.");
	for (AGBinding *b in self.dataObjectBindings)
	{
		[b applyDataToCell:cell forObject:object]; // using passed in object
	}
}

- (void)dynamicRowDidGainCell:(UITableViewCell*)cell forObject:(id)object;
{
	NSAssert(self.isRowPrototype, @"Only prototypes should lose cells via this method.");
	
	if (NSClassFromString(@"NSMapTable"))
	{
		if (!self.dynamicRowBindingsByObject)
		{
			self.dynamicRowBindingsByObject = [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory];
		}
		
		/* A map table of bindings for this particular dynamic object */
		NSMapTable *bindings = [self.dynamicRowBindingsByObject objectForKey:object];
				
		if (!bindings && [NSMapTable respondsToSelector:@selector(weakToStrongObjectsMapTable)])
		{
			bindings = [NSMapTable weakToStrongObjectsMapTable];
			[self.dynamicRowBindingsByObject setObject:bindings forKey:object];
		}
		
		/* Go through each prototype one, find the one for this object (making if needed), and set its cell */
		for (AGBinding *sourceBinding in self.dataObjectBindings)
		{
			AGBinding *destBinding = [bindings objectForKey:sourceBinding];
			
			if (!destBinding)
			{
				destBinding = [sourceBinding copyWithModelObject:object];
				[bindings setObject:destBinding forKey:sourceBinding];
			}
			
			destBinding.cell = cell;
		}
	}
}

- (void)rowWillLoseCell;
{
	NSAssert(self.isStaticRow, @"Only static rows should lose cells via this method.");

	for (AGBinding *b in self.staticBindings)
	{
		b.cell = nil;
	}
	for (AGBinding *b in self.dataObjectBindings)
	{
		b.cell = nil;
	}
}

- (void)dynamicRowWillLoseCellForObject:(id)object
{
	NSAssert(self.isRowPrototype, @"Only prototypes should lose cells via this method.");
	
	if (NSClassFromString(@"NSMapTable"))
	{
		NSMapTable *bindings = [self.dynamicRowBindingsByObject objectForKey:object];
		
		for (AGBinding *sourceBinding in bindings)
		{
			AGBinding *destBinding = [bindings objectForKey:sourceBinding];
			destBinding.cell = nil;
		}
	}
}

- (void)setIsRowPrototype:(BOOL)isRowPrototype
{
	if (!_isRowPrototype && (self.dataObjectBindings.count > 0))
	{
		NSAssert(false, @"Should set row prototype before setting up bindings. If this is impossible, file a ticket.");
	}
	
	_isRowPrototype = isRowPrototype;
}

#pragma mark -
#pragma mark object stuff

- (id)object
{
	id controllerOffers = nil;
	
	if (self.objectMode == objectModeDefault || self.objectMode == objectModeKVO)
	{
		controllerOffers = [self.controller delegateObjectForKeyPath:self.objectKeypath];
		
		if (controllerOffers != nil)
		{
			self.lastReturnedObject = controllerOffers;
			return controllerOffers;
		}
	}
	
	if (self.objectMode == objectModeDefault || self.objectMode == objectModeDelegate)
	{
		controllerOffers = [self.controller objectForStaticRow:self];
		
		if (controllerOffers != nil)
		{
			self.lastReturnedObject = controllerOffers;
			return controllerOffers;
		}
	}
	
	if (self.objectMode == objectModeDefault || self.objectMode == objectModeStatic)
	{
		self.lastReturnedObject = _object;
		return _object;
	}
	
	return nil;
}

- (void) setObject:(id)o
{
	if (_object != o)
	{
		[self updateObjectBindingsOld:_object new:o];
		_object = o;
	}
	self.objectMode = objectModeStatic;
}


- (void)updateObjectBindingsOld:(id)old new:(id)new
{
	if (!self.isStaticRow)
	{
		return;
	}
	
	for (AGBinding *binding in [self.dataObjectBindings copy])
	{
		AGBinding *newBinding = [binding copyWithModelObject:new];
		[self.dataObjectBindings removeObject:binding];
		[self.dataObjectBindings addObject:newBinding];
	}
}

//TODO: This needs rewriting. SetObject Needs to go through all bound objectKP->anything things and remove KVO from old object, add to new.
- (void) setObjectKeypath:(NSString *)k
{
	if (_objectKeypath != nil)
	{
		[self.controller.delegate removeObserver:self forKeyPath:_objectKeypath];
	}
	
//	[self.controller.delegate addObserver:self
//					forKeyPath:k
//					   options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
//					   context:(__bridge void *)(AGRowBindingObject)];
	[self.controller.delegate addObserver:self
								  keyPath:k
								 selector:@selector(observeValueForKeyPath:ofObject:change:context:)
								 userInfo:AGRowBindingObject
								  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld];
	
	_objectKeypath = [k copy];
	
	self.objectMode = objectModeKVO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)anObject
                        change:(NSDictionary *)change
                       context:(void *)context
{
	
	if (context == (__bridge void *)(AGRowBindingObject))
	{
		[self updateObjectBindingsOld:change[NSKeyValueChangeOldKey] new:change[NSKeyValueChangeNewKey]];
		
		[self.controller contentChangedForRow:self];
	}
}



#pragma mark -
#pragma mark Caching stuff 

- (void)cacheVisibility
{
	self.cachedVisibility = [self _isVisible];
}

- (UIImage*)imageFieldCachedSmallImage
{
	if (_imageFieldCachedSmallImage)
		return _imageFieldCachedSmallImage;
	
	[self refreshImageCache];
	return _imageFieldCachedSmallImage;
}

- (void)refreshImageCache
{
	UIImage *image = [self.controller.delegate valueForKeyPath:self.imageFieldBoundToProperty];
	
	if (!image)
		return;
	
	CGSize newSize = CGSizeMake(image.size.width/(image.size.height/88.0), 88.0);
	
	UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
	
	self.imageFieldCachedSmallImage = newImage;
	
}

#pragma mark -
#pragma mark Convenience key/values accessors

- (NSString *) text
{
	return (self.configurationKeyValueData)[@"textLabel.text"];
}

- (void) setText:(NSString *)text
{
	if (!text)
		return;
	(self.configurationKeyValueData)[@"textLabel.text"] = text;
}

- (UIFont *) font
{
	return (self.configurationKeyValueData)[@"textLabel.font"];
}

- (void) setFont:(UIFont *)font
{
	(self.configurationKeyValueData)[@"textLabel.font"] = font;
}

- (UIColor *)textColor
{
	return (self.configurationKeyValueData)[@"textLabel.textColor"];
}

- (void)setTextColor:(UIColor*)aColor
{
	(self.configurationKeyValueData)[@"textLabel.textColor"] = aColor;
}

- (UITableViewCellSelectionStyle)selectionStyle
{
	return [(self.configurationKeyValueData)[@"selectionStyle"] intValue];
}

- (void)setSelectionStyle:(UITableViewCellSelectionStyle)selectionStyle
{
	(self.configurationKeyValueData)[@"selectionStyle"] = [NSNumber numberWithInt:selectionStyle];
}

- (NSString *) detailText
{
	return (self.configurationKeyValueData)[@"detailTextLabel.text"];
}

- (void) setDetailText:(NSString *)text
{
	if (text == nil)
		return;
	(self.configurationKeyValueData)[@"detailTextLabel.text"] = text;
}

- (UIFont *) detailFont
{
	return (self.configurationKeyValueData)[@"detailTextLabel.font"];
}

- (void) setDetailFont:(UIFont *)font
{
	(self.configurationKeyValueData)[@"detailTextLabel.font"] = font;
}

- (UITextAlignment)textAlignment
{
	return [(self.configurationKeyValueData)[@"textLabel.textAlignment"] intValue];
}

- (void)setTextAlignment:(UITextAlignment)textAlignment
{
	(self.configurationKeyValueData)[@"textLabel.textAlignment"] = [NSNumber numberWithInt:textAlignment];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)t
{
	_accessoryType = t;
	self.accessoryTypeExplicitlySet = YES;
}

- (void) setTextFieldBoundToProperty:(NSString*)aProperty;
{
	if (_textFieldBoundToProperty != aProperty)
	{
		_textFieldBoundToProperty = [aProperty copy];
	}
	[self bindTextFieldTagged:defaultTextfieldTag toDelegatePropertyNamed:aProperty observeChanges:YES];
}

- (void)bindTextFieldTagged:(int)textFieldTag toDelegatePropertyNamed:(NSString*)property observeChanges:(BOOL)observe;
{
//#warning Observing changes not yet implemented
	
	(self.textFieldBindings)[@(textFieldTag)] = property;
}

- (void)saveTextField:(UITextField*)textField
{
	NSInteger tfTag = [textField tag];
	NSNumber *tagNumber = @(tfTag);
	
	NSString *content = [textField text];
	
	[_controller textFieldChangedText:content forProperty:(self.textFieldBindings)[tagNumber]];
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
//#warning Limiting to character set not implemented
	[self saveTextField:textField];
	return YES;
}

-(void) textFieldDidBeginEditing:(UITextField *)textField
{
	[self.controller textFieldDidBeginEditing:textField];
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{	
	[self saveTextField:textField];
	[self.controller textFieldDidEndEditing:textField forRow:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	[self saveTextField:textField];
	NSLog(@"Return");
	[self.controller textFieldShouldReturn:textField forRow:self];
	
	return YES;	
}

- (void)_setSection:(AGTableSection*)aSection;
{
	self.section = aSection;
}

#pragma mark -

- (BOOL)_isVisible
{
	switch (self.visibilityMode)
	{
		case visibilityModeStandard:
			return self.visible;
			break;
		case visibilityModeDelegate:
			return [self.controller.delegate tableDataController:self.controller visibilityForRow:self];
			break;
		case visibilityModeEditingOnly:
			return (self.controller.editing) ? self.visible	: NO;
			break;
		case visibilityModeDelegateEditingOnly:
			return (self.controller.editing) ? [self.controller.delegate tableDataController:self.controller visibilityForRow:self]	: NO;
			break;
	}
	return NO;
}

- (void) dealloc
{
	if (_objectKeypath != nil)
	{
		[self.controller.delegate removeObserver:self forKeyPath:_objectKeypath];
	}
	
}

@end
