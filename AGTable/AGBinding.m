//
//  AGBinding.m
//  AGTable
//
//  Created by Amy Worrall on 04/12/2012.
//

#import "AGBinding.h"
#import "MAKVONotificationCenter.h"

@interface AGBinding ()
@property (nonatomic, assign) BOOL hasBound;
@property (assign) BOOL currentlyUpdatingModel;
@property (assign) BOOL currentlyUpdatingView;
@property (nonatomic, weak) UIView *observationView;

@end

// NB. Switched to Mike Ash KVO framework.

@implementation AGBinding

NSString * const AGBindingOptionRegisterForValueChanged = @"AGBindingOptionRegisterForValueChanged";
NSString * const AGBindingOptionRegisterForEditingEvents = @"AGBindingOptionRegisterForEditingEvents";
NSString * const AGBindingOptionsValueTransformer = @"AGBindingOptionsValueTransformer";
NSString * const AGBindingOptionsFormatter = @"AGBindingOptionsFormatter";
NSString * const AGBindingOptionsUseValueTransformerInReverse = @"AGBindingOptionsUseValueTransformerInReverse";

- (id)init
{
	if (self = [super init])
	{
		self.viewTag = NSNotFound;
	}
	return self;
}

- (void)setCell:(UITableViewCell *)cell
{
	if (_cell == cell)
		return;
	
	
	if (_cell)
	{
		[self unbindOldCell:_cell];
	}
	if (cell)
	{
		[self bindNewCell:cell];
	}
	
		_cell = cell;

	[self populateCellFromModel];

}

- (void)setModelKeypath:(NSString *)modelKeypath
{
	_modelKeypath = modelKeypath;
	[self bindModel];
}

- (void)setModelObject:(id)modelObject
{
	_modelObject = modelObject;
	[self bindModel];
}

- (void)setObservationView:(UIView *)observationView
{
	_observationView = observationView;
}

- (void)bindModel
{
	/* If it has both object and keypath, it hasn't already bound, and it's a live binding rather than a prototype */
	if (self.hasBound == NO && self.modelObject && self.modelKeypath && !self.isBindingPrototype)
	{
		[self.modelObject addObserver:self keyPath:self.modelKeypath selector:@selector(observeValueForKeyPath:ofObject:change:context:) userInfo:nil options:0];
		self.hasBound = YES;
	}
}

- (void)unbindOldCell:(UITableViewCell*)cell
{
	[self.observationView removeObserver:self keyPath:self.viewKeypath];
	
	if ([self boolForOption:AGBindingOptionRegisterForEditingEvents] || [self boolForOption:AGBindingOptionRegisterForValueChanged])
	{
		// find last keypath bit
		UIView *testView = self.observationView;
		
		if (![testView isKindOfClass:[UIControl class]])
		{
			NSInteger tempIndex = [self.viewKeypath rangeOfString:@"." options:NSBackwardsSearch].location;
			if (tempIndex != NSNotFound)
			{
				NSString *prevKeypath = [self.viewKeypath substringToIndex:tempIndex];
				testView = [self.observationView valueForKeyPath:prevKeypath];
			}
		}
		
		// test again, have we got a UIControl yet?
		if ([testView isKindOfClass:[UIControl class]])
		{
			UIControl *c = (UIControl*)testView;
			
			if ([self boolForOption:AGBindingOptionRegisterForEditingEvents])
			{
				[c removeTarget:self action:@selector(updateViaEvent:) forControlEvents:UIControlEventAllEditingEvents];
			}
			if ([self boolForOption:AGBindingOptionRegisterForValueChanged])
			{
				[c removeTarget:self action:@selector(updateViaEvent:) forControlEvents:UIControlEventValueChanged];
			}
		}
	}

	
	self.observationView = nil;
}

- (BOOL)boolForOption:(NSString*)option
{
	return [[self.options objectForKey:option] boolValue];
}

- (id)objectForOption:(NSString*)option
{
	return [self.options objectForKey:option];
}

- (NSValueTransformer*)valueTransformer
{
	return [self objectForOption:AGBindingOptionsValueTransformer];
}

- (NSFormatter*)formatter
{
	return [self objectForOption:AGBindingOptionsFormatter];
}

- (void)bindNewCell:(UITableViewCell*)cell
{
	UIView *view = cell;
	
	if (self.viewTag != NSNotFound)
	{
		view = [cell viewWithTag:self.viewTag];
	}
	
	self.currentlyUpdatingView = YES;
	
	self.observationView = view;

	[view addObserver:self keyPath:self.viewKeypath selector:@selector(observeValueForKeyPath:ofObject:change:context:) userInfo:nil options:0];
	[self populateCellFromModel];
	
	
	// Do the target adding stuff if necessary
	if ([self boolForOption:AGBindingOptionRegisterForEditingEvents] || [self boolForOption:AGBindingOptionRegisterForValueChanged])
	{
		// find last keypath bit
		UIView *testView = self.observationView;
		
		if (![testView isKindOfClass:[UIControl class]])
		{
			NSInteger tempIndex = [self.viewKeypath rangeOfString:@"." options:NSBackwardsSearch].location;
			if (tempIndex != NSNotFound)
			{
				NSString *prevKeypath = [self.viewKeypath substringToIndex:tempIndex];
				testView = [self.observationView valueForKeyPath:prevKeypath];
			}
		}
		
		// test again, have we got a UIControl yet?
		if ([testView isKindOfClass:[UIControl class]])
		{
			UIControl *c = (UIControl*)testView;
			
			if ([self boolForOption:AGBindingOptionRegisterForEditingEvents])
			{
				[c addTarget:self action:@selector(updateViaEvent:) forControlEvents:UIControlEventAllEditingEvents];
			}
			if ([self boolForOption:AGBindingOptionRegisterForValueChanged])
			{
				[c addTarget:self action:@selector(updateViaEvent:) forControlEvents:UIControlEventValueChanged];
			}
		}
	}
	
	
	
	self.currentlyUpdatingView = NO;
}

- (void)updateViaEvent:(id)sender
{
	[self populateModelFromCell];
}

- (void)populateCellFromModel
{
	if (!self.cell || self.isBindingPrototype)
		return;
	
	id modelValue = [self currentModelValue];
	
	UIView *view = self.cell;
	
	if (self.viewTag != NSNotFound)
	{
		view = [self.cell viewWithTag:self.viewTag];
	}
	
	self.currentlyUpdatingView = YES;

	[view setValue:modelValue forKeyPath:self.viewKeypath];
	self.currentlyUpdatingView = NO;
}

- (void)populateModelFromCell
{
	if (!self.cell || self.isBindingPrototype)
		return;

	id viewValue = [self.observationView valueForKeyPath:self.viewKeypath];
	
	if (self.valueTransformer)
	{
		if ([self boolForOption:AGBindingOptionsUseValueTransformerInReverse])
		{
			viewValue = [self.valueTransformer transformedValue:viewValue];
		}
		else
		{
			viewValue = [self.valueTransformer reverseTransformedValue:viewValue];
		}
	}
	if (self.formatter)
	{
		if (![self.formatter getObjectValue:&viewValue forString:viewValue errorDescription:nil])
		{
			return;
		}
	}
	
	self.currentlyUpdatingModel = YES;

	[self.modelObject setValue:viewValue forKeyPath:self.modelKeypath];
	self.currentlyUpdatingModel = NO;
}

// intended use: getting the binding value, such as for use in the class methods in a table cell subclass.
- (id)currentModelValue
{
	
	id modelValue = [self.modelObject valueForKeyPath:self.modelKeypath];
	
	if (self.valueTransformer)
	{
		if ([self boolForOption:AGBindingOptionsUseValueTransformerInReverse])
		{
			modelValue = [self.valueTransformer reverseTransformedValue:modelValue];
		}
		else
		{
			modelValue = [self.valueTransformer transformedValue:modelValue];
		}
	}
	if (self.formatter)
	{
		modelValue = [self.formatter stringForObjectValue:modelValue];
	}

	return modelValue;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == self.modelObject && self.cell && !self.currentlyUpdatingModel)
	{
		[self populateCellFromModel];
	}
	
	if (object == self.observationView && !self.currentlyUpdatingView)
	{
		[self populateModelFromCell];
	}
}

- (AGBinding*)copyWithModelObject:(id)modelObject;
{
	AGBinding *newBinding = [[AGBinding alloc] init];
	
	newBinding.modelObject = modelObject;
	newBinding.modelKeypath = self.modelKeypath;
	newBinding.viewTag = self.viewTag;
	newBinding.viewKeypath = self.viewKeypath;
	newBinding.options = self.options;
	newBinding.cell = self.cell;
	
	return newBinding;
}

@end
