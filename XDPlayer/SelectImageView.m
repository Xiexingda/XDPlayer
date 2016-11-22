//
//  SelectImageView.m
//  XDPlayer
//
//  Created by 谢兴达 on 16/9/19.
//  Copyright © 2016年 谢兴达. All rights reserved.
//

#import "SelectImageView.h"

@interface SelectImageView()

@property (nonatomic, copy) void (^action)(id obj);

@end

@implementation SelectImageView

- (instancetype)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)tapGestureBlock:(void(^)(id obj))action {
    self.action = [action copy];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap)];
    [self addGestureRecognizer:tap];
}

- (void)tap {
    if (self.action) {
        self.action(self);
    }
}

@end
