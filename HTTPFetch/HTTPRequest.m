//
//  HTTPRequest.m
//  HTTPFetch
//
//  Created by zjs on 14/8/12.
//  Copyright (c) 2014年 zjs. All rights reserved.
//

#import "HTTPRequest.h"
#include <stdio.h> 
#include <stdlib.h> 
#include <string.h> 
#include <sys/types.h> 
#include <sys/socket.h> 
#include <errno.h> 
#include <unistd.h> 
#include <netinet/in.h> 
#include <limits.h> 
#include <netdb.h> 
#include <arpa/inet.h> 
#include <ctype.h>


@implementation HTTPRequest {
    NSMutableArray * _history;
}

- (NSMutableArray *)history
{
    if(!_history) {
        _history = [[NSMutableArray alloc] initWithCapacity:2];
    }
    return _history;
}

- (NSString *)fetchHeaderWithURL:(NSURL *)url
{
    NSURL *reurl = url;
    do {
        NSData *data = [self fetchWithURL:reurl];
        NSString *header = [self getHeaderFromData:data];
        reurl = [self reLocationURLWithHeader:header];
        if(header) {
            [self.history addObject:header];
        } else {
            [self.history addObject:@"解析失败"];
        }
    } while (reurl);
    
    NSMutableString *temp = [NSMutableString string];
    for(NSString * obj in self.history) {
        if(temp.length != 0) {
            [temp appendString:@"\r\n\r\n------------↓↓↓↓------------\r\n\r\n"];
        }
        [temp appendString:obj];
    }
    return [NSString stringWithString:temp];
}

- (NSData *)fetchWithURL:(NSURL *)url
{
    NSString * string = [url absoluteString];
    if (![string hasPrefix:@"http"]) {
        string = [string stringByReplacingCharactersInRange:NSMakeRange(0,0) withString:@"http://"];
    }
    const char * urlString = [string UTF8String];
    
    char *host = NULL;
    char *file = NULL;
    int port[1] = {0};
    
    [self parseURL:urlString toHost:&host file:&file port:port];
    printf("webhost:%s\n", host);
    printf("hostfile:%s\n", file);
    printf("portnumber:%d\n\n", *port);
    
    struct hostent *sHost = gethostbyname(host);
    if (sHost == NULL) {
        fprintf(stderr,"Gethostname error, %s\n", strerror(errno));
        return nil;
    }
    
    int sockfd = socket(AF_INET,SOCK_STREAM,0);
    if(sockfd == -1) {
        fprintf(stderr,"Socket Error:%s\a\n",strerror(errno));
        return nil;
    }
    
    struct sockaddr_in server_addr;
    bzero(&server_addr,sizeof(server_addr));
    server_addr.sin_family=AF_INET;
    server_addr.sin_port=htons(*port);
    server_addr.sin_addr=*((struct in_addr *)sHost->h_addr);
    
    int status = connect(sockfd,(struct sockaddr *)(&server_addr),sizeof(struct sockaddr));
    if(status == -1) {
        fprintf(stderr,"Connect Error:%s\a\n",strerror(errno));
        return nil;
    }
    
    NSString *hostStr = [NSString stringWithFormat:@"%s",host];
    NSString *fileStr = [NSString stringWithFormat:@"%s",file];
    NSString *header = [self getHeaderByHost:hostStr file:fileStr port:*port];
    const char * request = [header UTF8String];
    printf("%s", request);
    
    /*发送http请求request*/
    size_t send = 0;
    size_t totalsend = 0;
    size_t nbytes=strlen(request);
    while(totalsend < nbytes) {
        send = write(sockfd, request + totalsend, nbytes - totalsend);
        if(send == -1)  {
            printf("send error!%s\n", strerror(errno));
            close(sockfd);
            return nil;
        }
        totalsend+=send;
        printf("%zu bytes send OK!\n", totalsend);
    }
    
    char *buffer = malloc(1024*10);
    char *response = calloc(1024, 1024);
    size_t cuPosition = 0;
    nbytes = read(sockfd,buffer,1024*1024);
    if (nbytes > 0) {
        size_t readSize = nbytes;
        if (cuPosition + readSize<=1024*1024) {
            memcpy(response+cuPosition, buffer, readSize);
            cuPosition += readSize;
        } else {
            printf("数据溢出");
        }
    }
    else if(nbytes == -1) {
        printf("read error!%s\n", strerror(errno));
        close(sockfd);
        return nil;
    } else //(nbytes == 0)
    {
        printf("read end!\n");
    }
    close(sockfd);
    return [NSData dataWithBytes:response length:cuPosition];
}

- (NSURL *)reLocationURLWithHeader:(NSString *)header
{
    if(header.length == 0) {
        return nil;
    }
    NSString* location = nil;
    NSScanner * scanner = [[NSScanner alloc] initWithString:header];
    while (![scanner isAtEnd])
    {
        if([scanner scanString:@"Location:" intoString:NULL]) {
            [scanner scanUpToString:@"\r\n" intoString:&location];
        }
        else
        {
            scanner.scanLocation++;
        }
    }
    if (location.length == 0) {
        return nil;
    }
    location = [location stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [NSURL URLWithString:location];
    
}

- (NSString *)getHeaderFromData:(NSData *)data
{
    if(data == nil) {
        return nil;
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:1];
    NSArray *text = [string componentsSeparatedByString:@"\r\n\r\n"];
    NSString *header = text[0];
    return header;
}

- (void)parseURL:(const char *)url toHost:(char **)host file:(char **)file port:(int *)port
{
    char * scheme = NULL;
    if(!strncmp(url, "http://", strlen("http://"))) {
        scheme = "http://";
    } else if(!strncmp(url, "https://", strlen("https://"))) {
        scheme = "https://";
    }
    const char *hostStart = url + strlen(scheme);
    char *hostEnd =strchr(hostStart, '/');
    if(hostEnd) {
        char *tempHost = malloc(strlen(hostStart) - strlen(hostEnd));
        memcpy(tempHost, hostStart, strlen(hostStart) - strlen(hostEnd));
        *host = tempHost;
        
        if(hostEnd + 1) {
            char *tempFile = malloc(strlen(hostEnd) - 1);
            memcpy(tempFile, hostEnd + 1, strlen(hostEnd) - 1);
            *file = tempFile;
        }
    } else {
        char *tempHost = malloc(strlen(hostStart));
        memcpy(tempHost, hostStart, strlen(hostStart));
        *host = tempHost;
    }
    
    char *tempPort = strchr(hostStart, ':');
    if(tempPort) {
        *port = atoi(tempPort + 1);
    } else {
        *port = 80;
    }
}

- (NSString *)getHeaderByHost:(NSString *)host file:(NSString *)path port:(int)port
{
    NSString * headerPath = [[NSBundle mainBundle] pathForResource:@"Header" ofType:nil];
    NSString * header = [[NSString alloc] initWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:nil];
    header = [header stringByReplacingOccurrencesOfString:@"%@1" withString:path];
    if(port != 0 && port != 80) {
        header = [header stringByReplacingOccurrencesOfString:@"%@2" withString:[NSString stringWithFormat:@"%@:%d",host,port]];
    } else {
        header = [header stringByReplacingOccurrencesOfString:@"%@2" withString:host];
    }
    return header;
}


@end
