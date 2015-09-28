//
//  NSPredicate+KeypathExtraction.m
//
//  Created by Mat Trudel on 2014-10-15.
//  Copyright (c) 2014 Moshozen Inc. All rights reserved.
//

#import "NSPredicate+KeypathExtraction.h"

@implementation NSPredicate (KeypathExtraction)

- (NSSet *)mz_referencedKeyPaths {
    NSMutableSet *result = [NSMutableSet set];
    if ([self isKindOfClass:[NSCompoundPredicate class]]) {
        for (NSPredicate *subpredicate in ((NSCompoundPredicate *)self).subpredicates) {
            [result unionSet:[subpredicate mz_referencedKeyPaths]];
        }
    } else if ([self isKindOfClass:[NSComparisonPredicate class]]) {
        for (NSExpression *expression in @[((NSComparisonPredicate *)self).leftExpression, ((NSComparisonPredicate *)self).rightExpression]) {
            if (expression.expressionType ==  NSKeyPathExpressionType) {
                [result addObject:expression.keyPath];
            }
        }
    }
    return result;
}

@end
