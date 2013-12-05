//
//  ViewController.m
//  OPenGLV-Rect
//
//  Created by msp msp on 13-4-10.
//  Copyright (c) 2013年 ___FULLUSERNAME___. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor yellowColor];
    
    m_pOpenGLView = [[OpenGLView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:m_pOpenGLView];
    [m_pOpenGLView release];
    
    UIButton * pZoomOutBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    pZoomOutBtn.frame = CGRectMake(10, 10, 50, 20);
    [pZoomOutBtn setTitle:@"放大" forState:UIControlStateNormal];
    [pZoomOutBtn addTarget:self action:@selector(ZoomOut) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pZoomOutBtn];
    
    UIButton * pZoomInBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    pZoomInBtn.frame = CGRectMake(100, 10, 50, 20);
    [pZoomInBtn setTitle:@"缩小" forState:UIControlStateNormal];
    [pZoomInBtn addTarget:self action:@selector(ZoomIn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pZoomInBtn];
}

- (void)ZoomOut
{
    [m_pOpenGLView ZoomOut];
}

- (void)ZoomIn
{
    [m_pOpenGLView ZoomIn];
//    [m_pOpenGLView setFrame:CGRectMake(0, 0, 100, 100)];
//    [m_pOpenGLView Render];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
