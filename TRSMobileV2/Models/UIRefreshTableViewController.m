//
//  UIRefreshTableViewController.m
//  TRSMobileV2
//
//  Created by  TRS on 16/4/25.
//  Copyright © 2016年  TRS. All rights reserved.
//

#import "UIRefreshTableViewController.h"
#import "UIViewController+AssociatedObject.h"
#import "UICycleScrollView.h"
#import "StroageService+Provider.h"
#import "NSDictionary+Extension.h"
#import "AFHTTP+Provider.h"

@implementation UIRefreshTableViewController

- (instancetype) init {

    if(self = [super init]) {
        
        _pageIndex = 0;
        _pageTotal = 0;
        _hasRefreshHeader = YES;
        _hasRefreshFooter = YES;
        _datasource = [NSMutableArray arrayWithCapacity:0];
        _ads = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
    [self initUIControls];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void) initUIControls {

    __weak __typeof(self) wself = self;
    if(_hasRefreshHeader) {
        
        self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{

            __strong __typeof(wself) sself = wself;
            
            sself.isRefresh = YES;
            sself.pageIndex = sself.pageTotal = 0;
            [sself request];
        }];
        [self.tableView.mj_header beginRefreshing];
    }
    else {
        [self request];
    }
    
    if(_hasRefreshFooter) {
    
        self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
            
            __strong __typeof(wself) sself = wself;
            
            sself.isRefresh = NO;
            [sself request];
        }];
        self.tableView.mj_footer.automaticallyHidden = YES;
    }
}

- (UICycleScrollView *) csView {
    
    if(!_csView) {
        CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame) * 9/16);
        _csView = [[UICycleScrollView alloc] initWithFrame:frame];
    }
    return _csView;
}

#pragma mark -

- (NSString *)url {

    if(_urlBlock) return _urlBlock();

    NSString *url = [self.dict objectForVitualKey:@"url"];
    if(!_isRefresh ) {
        url = [[url stringByDeletingPathExtension] stringByAppendingFormat:@"_%ld.json", (_pageIndex + 1) ];
    }
    return url;
}

- (void)request {

    if(_requestBlock) {_requestBlock(); return;}
    
    /*先加载缓存数据*/
    if(_isRefresh && _pageIndex == 0) {
        [self responseHandler:YES response:[StroageService valueForKey:self.url serviceType:serviceTypeDefault] ];
    }
    
    /*从网络请求数据*/
    [AFHTTP request:self.url cachePolicy:(_isRefresh ? cachePolicyYes : cachePolicyNone) completion:^(BOOL success, id _Nullable response, NSError * _Nullable error) {
             
             _responseBlock ? _responseBlock(success, response) : [self responseHandler:success response:response];
             
    }];
}

- (void)responseHandler:(BOOL)success response:(id)response {
    
    if(success) {
        
        BOOL isKeyValue = [response isKindOfClass:[NSDictionary class]];
        if(isKeyValue) {
            _pageIndex = [[response valueForKeyPath:@"page_info.page_index"] integerValue];
            _pageTotal = [[response valueForKeyPath:@"page_info.page_count"] integerValue];
        }
        
        if(_isRefresh) {
            [_ads removeAllObjects];
            [_datasource removeAllObjects];
            [_ads addObjectsFromArray:response[@"topic_datas"] ? : @[] ];
        }
        
        if(isKeyValue) {
            [_datasource addObjectsFromArray:response[@"datas"] ? : @[] ];
        }
        else {
            [_datasource addObjectsFromArray:response];
        }
        
        [self.tableView performSelector:@selector(reloadData)];
    }
    
    [self.tableView.mj_header performSelector:@selector(endRefreshing)];
    if(_pageIndex != _pageTotal - 1) {
        [self.tableView.mj_footer performSelector:@selector(endRefreshing)];
    }
    else {
        [self.tableView.mj_footer performSelector:@selector(endRefreshingWithNoMoreData)];
    }
}

@end
