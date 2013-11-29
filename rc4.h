//
//  rc4.h
//  Server Scope
//
//  Created by Scott J. Goldman on 12/16/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#ifndef Server_Scope_rc4_h
#define Server_Scope_rc4_h

void rc4_set_key(client_ctx *ctx, char *session_id);
void rc4_encrypt(client_ctx *ctx, uint8_t *paramArrayOfByte, int paramInt1, int paramInt2);

#endif
