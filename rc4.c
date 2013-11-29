#include <stdint.h>
#include <string.h>

#include "md5.h"
#include "glue.h"


static void set_key(client_ctx *ctx, uint8_t *key);

void rc4_set_key(client_ctx *ctx, char *session_id)
{
    MD5((const unsigned char *)session_id, strlen(session_id), ctx->rc4.digest_key);
    set_key(ctx, ctx->rc4.digest_key);
}

static void set_key(client_ctx *ctx, uint8_t *key)
{
    ctx->rc4.x = 0;
    ctx->rc4.y = 0;
    for (int n = 0; n < 256; n++)
        ctx->rc4.state[n] = ((uint8_t)n);
    int k = 0;
    int m = 0;
    for (int n = 0; n < 256; n++)
    {
        int i = ctx->rc4.state[n];
        m = m + key[k] + i & 0xFF;
        int j = ctx->rc4.state[m];
        ctx->rc4.state[m] = ((uint8_t)(i & 0xFF));
        ctx->rc4.state[n] = ((uint8_t)(j & 0xFF));
        k++;
        if (k >= MD5_DIGEST_LENGTH)
            k = 0;
    }
}

void rc4_encrypt(client_ctx *ctx, uint8_t *abyte0, int i, int j)
{
    for(int l = j; l < i; l += 4)
    {
        for(int i1 = 0; i1 < 4; i1++)
        {
            ctx->rc4.x = ctx->rc4.x + 1 & 0xff;
            ctx->rc4.y = ctx->rc4.state[ctx->rc4.x] + ctx->rc4.y & 0xff;
            uint8_t byte0 = ctx->rc4.state[ctx->rc4.x];
            ctx->rc4.state[ctx->rc4.x] = ctx->rc4.state[ctx->rc4.y];
            ctx->rc4.state[ctx->rc4.y] = byte0;
            int k = (ctx->rc4.state[ctx->rc4.x] & 0xff) + (ctx->rc4.state[ctx->rc4.y] & 0xff) & 0xff;
            int j1 = ctx->rc4.state[k] & 0xff;
            abyte0[l + (3 - i1)] ^= j1;
        }
    }
}
