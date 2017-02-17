//
//  AGPrintfStringFormatter.h
//  AGTable
//
//  Created by Amy Worrall on 17/02/2017.
//  Copyright © 2017 Amy Worrall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AGPrintfStringFormatter : NSFormatter

@property (nonatomic, copy) NSString *formatString; // should contain exactly one %@

@end
