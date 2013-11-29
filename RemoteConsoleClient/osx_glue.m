#include <assert.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/socket.h>

//#include <openssl/ssl.h>

#include "osx_glue.h"
#include "decoder.h"
#include "protocol.h"
#include "util.h"

#import "AsyncSocket.h"

int glue_write_data_ctrl(client_ctx *_ctx, void *data, size_t size)
{
    osx_client_ctx *ctx = (osx_client_ctx *)_ctx;
    [ctx->ctrl_socket writeData:[NSData dataWithBytes:data length:size] withTimeout:-1 tag:1];
    //NSLog(@"queued send of %zu bytes", size);
    return (int)size;
}

int glue_read_data_ctrl(client_ctx *_ctx, size_t size)
{
    osx_client_ctx *ctx = (osx_client_ctx *)_ctx;
    [ctx->ctrl_socket readDataToLength:size withTimeout:-1 tag:2];
    //NSLog(@"queued read of %zu bytes", size);
	return 0;
}

int glue_write_data_video(client_ctx *_ctx, void *data, size_t size)
{
    osx_client_ctx *ctx = (osx_client_ctx *)_ctx;
    [ctx->video_socket writeData:[NSData dataWithBytes:data length:size] withTimeout:-1 tag:3];
    //NSLog(@"video queued send of %zu bytes", size);
    return (int)size;
}

int glue_read_data_video(client_ctx *_ctx, size_t size)
{
    osx_client_ctx *ctx = (osx_client_ctx *)_ctx;
    [ctx->video_socket readDataToLength:size withTimeout:-1 tag:4];
    //NSLog(@"video queued read of %zu bytes", size);
	return 0;
}

int glue_start_ssl_ctrl(client_ctx *_ctx)
{
    osx_client_ctx *ctx = (osx_client_ctx *)_ctx;
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:4];
    
    //[settings setObject:host forKey:(NSString *)kCFStreamSSLPeerName];
    [settings setObject:[NSNumber numberWithBool:YES]
                 forKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
    [settings setObject:[NSNumber numberWithBool:YES]
                 forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    [settings setObject:[NSNumber numberWithBool:NO]
                 forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];

    [ctx->ctrl_socket startTLS:settings];
    if (ctx->lib.dracType == DRAC4)
        ctx->ssl = YES;
	NSLog(@"started ssl for ctrl socket\n");
	return 0;
}


int glue_start_ssl_video(client_ctx *_ctx)
{
    osx_client_ctx *ctx = (osx_client_ctx *)_ctx;
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:4];
    
    //[settings setObject:host forKey:(NSString *)kCFStreamSSLPeerName];
    [settings setObject:[NSNumber numberWithBool:YES]
                 forKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
    [settings setObject:[NSNumber numberWithBool:YES]
                 forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    [settings setObject:[NSNumber numberWithBool:NO]
                 forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
    
    [ctx->video_socket startTLS:settings];
    ctx->ssl = YES;
	NSLog(@"started ssl for video socket\n");
	return 0;
}


osx_client_ctx *alloc_client_ctx(AsyncSocket *_ctrl_socket, AsyncSocket *_video_socket)
{
    osx_client_ctx *ctx = calloc(sizeof(osx_client_ctx), 1);
    ctx->lib.glue_write_data_ctrl = glue_write_data_ctrl;
    ctx->lib.glue_write_data_video = glue_write_data_video;
    ctx->lib.glue_read_data_ctrl = glue_read_data_ctrl;
    ctx->lib.glue_read_data_video = glue_read_data_video;
    ctx->lib.glue_start_ssl_ctrl = glue_start_ssl_ctrl;
    ctx->lib.glue_start_ssl_video = glue_start_ssl_video;
    
    ctx->ctrl_socket = [_ctrl_socket retain];
    ctx->video_socket = [_video_socket retain];
    
    init_decoder((client_ctx *)ctx);
    return ctx;
}

void free_client_ctx(osx_client_ctx *ctx)
{
    [ctx->ctrl_socket release];
    [ctx->video_socket release];
    
    free(ctx);
}
