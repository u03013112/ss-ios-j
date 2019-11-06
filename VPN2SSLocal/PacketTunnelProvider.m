//
//  PacketTunnelProvider.m
//  VPN2SSLocal
//
//  Created by 宋志京 on 2019/11/1.
//  Copyright © 2019 宋志京. All rights reserved.
//

#import "PacketTunnelProvider.h"
#import <ssLocal/ssLocal.h>
#import <ShadowPath/ShadowPath.h>

#define TunnelMTU 1600

static int localPort = 0;
static int proxyPort = 0;
void ss_local_handler(int fd, void *udata);
void ss_client_handler(int fd, void *udata);

@interface PacketTunnelProvider(){
    NSString *host;
    NSString *method;
    NSString *passwd;
    int port;
}
@end

@implementation PacketTunnelProvider
- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
//    [self openLog];
    NSLog(@"startTunnelWithOptions");
    self->_pendingStartCompletion = completionHandler;
    self->port = 0;
    [NSThread detachNewThreadSelector:@selector(updatePerSec) toTarget:self withObject:nil];
    
//    [NSThread detachNewThreadSelector:@selector(startSSLocal) toTarget:self withObject:nil];
}

-(void) updatePerSec {
    for (;;){
        [self keepalive];
        sleep(30);
    }
}
    
-(void) keepalive {
    NSURL *tokenUrl = [[NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:@"group.U0.ss"]URLByAppendingPathComponent:@"token.conf"];
    NSString *confContent = [NSString stringWithContentsOfURL:tokenUrl encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[confContent dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    NSString *token = json[@"token"];
    if (token == nil){
        exit(0);
    }
    NSURL *url = [NSURL URLWithString:@"https://frp.u03013112.win:18022/v1/ios/config"];
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url];
    NSDictionary *head = [[NSDictionary alloc]initWithObjectsAndKeys:@"application/json",@"Content-Type", nil];
    NSMutableDictionary *postBodyDict = [[NSMutableDictionary alloc]init];
    [postBodyDict setObject:token forKey:@"token"];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postBodyDict options:NSJSONWritingPrettyPrinted error:nil];
    [mutableRequest setHTTPMethod:@"POST"];
    [mutableRequest setHTTPBody:postData];
    [mutableRequest setAllHTTPHeaderFields:head];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:mutableRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            NSDictionary *d= [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if ([d objectForKey:@"error"]!=nil){
                exit(0);
            }
            if (self->port == 0){
                self->host = [d objectForKey:@"IP"];
                self->method = [d objectForKey:@"method"];
                self->passwd = [d objectForKey:@"passwd"];
                self->port = [[d objectForKey:@"port"]intValue];
                [NSThread detachNewThreadSelector:@selector(startSSLocal) toTarget:self withObject:nil];
            }
        }else{
            exit(0);
        }
    }];
    [task resume];
}
    
- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    // Add code here to start the process of stopping the tunnel.
    completionHandler();
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler {
    // Add code here to handle the message.
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
    // Add code here to get ready to sleep.
    completionHandler();
}

- (void)wake {
    // Add code here to wake up.
}

    
- (void)startSSLocal {
//    char *host = "64.64.233.232";
//    int port = 58700;
//    char *password = "xKpQV8wUVe";
//    char *method = "aes-256-gcm";

    char *host = (char *)[self->host UTF8String];
    int port = self->port;
    char *password = (char *)[self->passwd UTF8String];
    char *method = (char *)[self->method UTF8String];
    
    profile_t profile;
    memset(&profile, 0, sizeof(profile_t));
    profile.remote_host = host;
    profile.remote_port = port;
    profile.password = password;
    profile.method = method;
    profile.local_addr = "127.0.0.1";
    profile.local_port = 0;
    profile.timeout = 600;
    profile.verbose = 1;
    profile.log = (char*)[[[[NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:@"group.U0.ss"]URLByAppendingPathComponent:@"a.log"]path]UTF8String];
    start_ss_local_server_with_callback(profile, ss_local_handler, (__bridge void *)self);
}
    
-(void)startSSClient{
    struct forward_spec *proxy = malloc(sizeof(struct forward_spec));
    memset(proxy, 0, sizeof(struct forward_spec));
    
    proxy->type = SOCKS_5;
    proxy->gateway_host = "127.0.0.1";
    proxy->gateway_port = localPort;
    
    NSString *confStr = [[[NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:@"group.U0.ss"]URLByAppendingPathComponent:@"http.conf"]path];
    
    shadowpath_main(strdup([confStr UTF8String]), proxy, ss_client_handler, (__bridge void *)self);
}
    
    
- (void)startVPNWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *error))completionHandler {
    NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.168.12.1"] subnetMasks:@[@"255.255.255.0"]];
    ipv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]];
    NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"192.168.12.2"];
    settings.IPv4Settings = ipv4Settings;
    settings.MTU = @(TunnelMTU);
    NEProxySettings* proxySettings = [[NEProxySettings alloc] init];
    NSInteger proxyServerPort = proxyPort;
    NSString *proxyServerName = @"localhost";

    proxySettings.HTTPEnabled = YES;
    proxySettings.HTTPServer = [[NEProxyServer alloc] initWithAddress:proxyServerName port:proxyServerPort];
    proxySettings.HTTPSEnabled = YES;
    proxySettings.HTTPSServer = [[NEProxyServer alloc] initWithAddress:proxyServerName port:proxyServerPort];
    proxySettings.excludeSimpleHostnames = YES;
    settings.proxySettings = proxySettings;

    [self setTunnelNetworkSettings:settings completionHandler:^(NSError * _Nullable error) {
        if (error) {
            if (completionHandler) {
                completionHandler(error);
            }
        }else{
            if (completionHandler) {
                completionHandler(nil);
            }
        }
    }];
}
    
- (void)openLog {
    NSString *logFilePath = [[[NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:@"group.U0.ss"]URLByAppendingPathComponent:@"a.log"]path];
    [[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "w+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "w+", stderr);
}
    
@end


void ss_client_handler(int fd, void *udata) {
    if (fd > 0) {
        struct sockaddr_in sin;
        socklen_t len = sizeof(sin);
        if (getsockname(fd, (struct sockaddr *)&sin, &len) < 0) {
            NSLog(@"getsock_port(%d) error: %s",
                  fd, strerror (errno));
            return;
        }else{
            proxyPort = ntohs(sin.sin_port);
            NSLog(@"proxy port : %d",proxyPort);
            PacketTunnelProvider *provider = (__bridge PacketTunnelProvider *)udata;
            [provider startVPNWithOptions:nil completionHandler:^(NSError *error) {
                if (provider->_pendingStartCompletion) {
                    provider->_pendingStartCompletion(error);
                    provider->_pendingStartCompletion = nil;
                }
            }];
        }
    }
}

void ss_local_handler(int fd, void *udata) {
    if (fd > 0) {
        struct sockaddr_in sin;
        socklen_t len = sizeof(sin);
        if (getsockname(fd, (struct sockaddr *)&sin, &len) < 0) {
            NSLog(@"getsock_port(%d) error: %s",
                  fd, strerror (errno));
        }else{
            localPort = ntohs(sin.sin_port);
            NSLog(@"local port : %d",localPort);
            PacketTunnelProvider *provider = (__bridge PacketTunnelProvider*)udata;
            [NSThread detachNewThreadSelector:@selector(startSSClient) toTarget:provider withObject:nil];
        }
    }
}
