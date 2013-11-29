//
//  osx_glue.h
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/28/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#ifndef RemoteConsoleClient_osx_glue_h
#define RemoteConsoleClient_osx_glue_h

#include "glue.h"
#import "AsyncSocket.h"

typedef struct osx_client_ctx
{
    client_ctx lib;
    __unsafe_unretained AsyncSocket *ctrl_socket;
    __unsafe_unretained AsyncSocket *video_socket;
    bool ssl;
} osx_client_ctx;


osx_client_ctx *alloc_client_ctx(AsyncSocket *_ctrl_socket, AsyncSocket *_video_socket);
void free_client_ctx(osx_client_ctx *ctx);

#endif
