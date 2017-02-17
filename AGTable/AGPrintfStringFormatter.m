//
//  AGPrintfStringFormatter.m
//  AGTable
//
//  Created by Amy Worrall on 17/02/2017.
//  Copyright © 2017 Amy Worrall. All rights reserved.
//

#import "AGPrintfStringFormatter.h"

@implementation AGPrintfStringFormatter

- (NSString *)stringForObjectValue:(id)obj
{
  return [NSString stringWithFormat:self.formatString, obj];
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString *__autoreleasing  _Nullable *)error
{
  NSArray *bits = [self.formatString componentsSeparatedByString:@"%@"];

  if (bits.count > 2) {
    *error = @"Invalid format string";
    return NO;
  }

  NSScanner *scanner = [NSScanner scannerWithString:string];
  [scanner scanString:bits[0] intoString:nil];

  NSString *dest;

  if (bits.count == 2) {
    [scanner scanUpToString:bits[1] intoString:&dest];
  } else {
    dest = [string substringFromIndex:scanner.scanLocation];
  }

  if (dest) {
    *obj = dest;
    return YES;
  }

  *error = @"Couldn't find second half of string";
  return NO;
}

@end
