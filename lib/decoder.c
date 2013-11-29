#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#include "glue.h"
#include "decoder.h"
#include "protocol.h"

//#define DEBUG_PRINTF printf
#define DEBUG_PRINTF(...)
#define PACKET_BUFFER_MAX_SIZE (1024*1024)

uint32_t dvc7_colormap[] = { 0xff000000, 0xff000046, 0xff00007f, 0xff0000bf, 0xff004600, 0xff004646, 0xff00467f, 0xff0046bf, 0xff007f00, 0xff007f46, 0xff007f7f, 0xff007fbf, 0xff00bf00, 0xff00bf46, 0xff00bf7f, 0xff00bfbf, 0xff460000, 0xff460046, 0xff46007f, 0xff4600bf, 0xff464600, 0xff464646, 0xff46467f, 0xff4646bf, 0xff467f00, 0xff467f46, 0xff467f7f, 0xff467fbf, 0xff46bf00, 0xff46bf46, 0xff46bf7f, 0xff46bfbf, 0xff7f0000, 0xff7f0046, 0xff7f007f, 0xff7f00bf, 0xff7f4600, 0xff7f4646, 0xff7f467f, 0xff7f46bf, 0xff7f7f00, 0xff7f7f46, 0xff7f7f7f, 0xff7f7fbf, 0xff7fbf00, 0xff7fbf46, 0xff7fbf7f, 0xff7fbfbf, 0xffbf0000, 0xffbf0046, 0xffbf007f, 0xffbf00bf, 0xffbf4600, 0xffbf4646, 0xffbf467f, 0xffbf46bf, 0xffbf7f00, 0xffbf7f46, 0xffbf7f7f, 0xffbf7fbf, 0xffbfbf00, 0xffbfbf46, 0xffbfbf7f, 0xffbfbfbf, 0xff0000ff, 0xff4600ff, 0xff7f00ff, 0xffbf00ff, 0xff0046ff, 0xff4646ff, 0xff7f46ff, 0xffbf46ff, 0xff007fff, 0xff467fff, 0xff7f7fff, 0xffbf7fff, 0xff00bfff, 0xff46bfff, 0xff7fbfff, 0xffbfbfff, 0xff00ff00, 0xff00ff46, 0xff00ff7f, 0xff00ffbf, 0xff46ff00, 0xff46ff46, 0xff46ff7f, 0xff46ffbf, 0xff7fff00, 0xff7fff46, 0xff7fff7f, 0xff7fffbf, 0xffbfff00, 0xffbfff46, 0xffbfff7f, 0xffbfffbf, 0xffff0000, 0xffff0046, 0xffff007f, 0xffff00bf, 0xffff4600, 0xffff4646, 0xffff467f, 0xffff46bf, 0xffff7f00, 0xffff7f46, 0xffff7f7f, 0xffff7fbf, 0xffffbf00, 0xffffbf46, 0xffffbf7f, 0xffffbfbf, 0xff00ffff, 0xff46ffff, 0xff7fffff, 0xffbfffff, 0xffff00ff, 0xffff46ff, 0xffff7fff, 0xffffbfff, 0xffffff00, 0xffffff46, 0xffffff7f, 0xffffffbf, 0xffffffff, 0xff5f5f5f, 0xff9f9f9f, 0xffdfdfdf
};
uint32_t dvc15_colormap[COLORMAP_SIZE];

void init_decoder(client_ctx *ctx)
{
	if (dvc15_colormap[COLORMAP_SIZE - 1] == 0) {
		for (int i = 0; i < COLORMAP_SIZE; i++)
		{
			int j = (i & 0x7C00) >> 7;
			int k = (i & 0x3E0) >> 2;
			int m = (i & 0x1F) << 3;
			int n = 0xFF000000 | j << 16 | (k << 8) | (m & 0xFF);
			dvc15_colormap[i] = n;
		}
	}

	ctx->packet_buffer = (uint8_t *)malloc(PACKET_BUFFER_MAX_SIZE);
}

int load_data(client_ctx *ctx, int _height, int _width, int eof, int bof, uint8_t *buffer, int size, uint16_t type)
{
	if (bof) {
		if (ctx->height != _height || ctx->width != _width) {
			ctx->height = _height;
			ctx->width = _width;
            if (ctx->framebuffer)
                free(ctx->framebuffer);
			ctx->framebuffer = malloc(sizeof(uint32_t)*_height*_width);
			for (int i = 0; i < _height*_width; i++)
				ctx->framebuffer[i] = 0xff000000;
		}
		ctx->packet_buffer_size = 0;
		ctx->pointer_index = 0;
        ctx->codec = type;
	}

	if (eof)
		ctx->frame_count++;

	//wait for first frame
	if (ctx->needs_refresh || ctx->framebuffer == NULL) {
		//XXX if we started getting video data without a beginning of frame, we need
		//    to request a full screen refresh in order to have consistent video.
		//    this seems to happen sometimes when joining an existing session.
		ctx->needs_refresh = 1;
		return -1;
	}
    
	//DEBUG_PRINTF("packet_buffer_size=%d PACKET_BUFFER_MAX_SIZE=%d size=%d\n", packet_buffer_size, PACKET_BUFFER_MAX_SIZE, size);
	memcpy(&ctx->packet_buffer[ctx->packet_buffer_size], buffer, size);
	ctx->packet_buffer_size += size;

	if (eof) {
		decode_packet(ctx);
		return 1;
	} else
		return 0;
}

int decode_packet(client_ctx *ctx)
{
	ctx->bytes_read = 0;
	while (ctx->bytes_read < ctx->packet_buffer_size) {
		uint8_t j = ctx->packet_buffer[ctx->bytes_read++];
		int k = j & 0xE0;
		switch (k)
		{
		case 0:
			processNCCommand(ctx, j);
			break;
		case 64:
			processCACommand(ctx, j);
			break;
		case 32:
			processCLCommand(ctx, j);
			break;
		case 96:
			processMSCommand(ctx, j);
			break;
		default:
			if ((j & 0x80) != 0)
				processMPCommand(ctx, j);
			break;
		}
		ctx->step_count++;
		DEBUG_PRINTF("step=%d pointer_index=%x prev_color=%x\n", ctx->step_count, ctx->pointer_index, ctx->framebuffer[ctx->pointer_index-1]);
	}

	return 0;
}

void processNCCommand(client_ctx *ctx, uint8_t arg)
{
	int i = getRunLength(ctx, arg);

	DEBUG_PRINTF("%d) No Change (length=%d)\n", ctx->step_count, i);
	ctx->pointer_index += i;
}

void processCACommand(client_ctx *ctx, uint8_t arg)
{
	int i = getRunLength(ctx, arg);
	int j = ctx->pointer_index - ctx->width;
	if (j >= 0) {
		for (int k = 0; k < i; k++)
			ctx->framebuffer[ctx->pointer_index + k] = ctx->framebuffer[j + k];
		ctx->pointer_index += i;
		DEBUG_PRINTF("%d) Copy Above (length=%d)\n", ctx->step_count, i);
	} else
		DEBUG_PRINTF("%d) Copy Above on first line ignored (length=%d pointer_index=%d width=%d)\n", ctx->step_count, i, ctx->pointer_index, ctx->width);
}

void processCLCommand(client_ctx *ctx, uint8_t paramInt)
{
	int i = getRunLength(ctx, paramInt);
	DEBUG_PRINTF("%d) Copy Left (length=%d)\n", ctx->step_count, i);
	for (int j = 0; j < i; j++)
		ctx->framebuffer[ctx->pointer_index + j] = ctx->framebuffer[ctx->pointer_index - 1];
	ctx->pointer_index += i;
}

void processMSCommand(client_ctx *ctx, uint8_t paramInt)
{
	int i = ctx->framebuffer[ctx->pointer_index - 1];
    uint32_t *framebuffer = ctx->framebuffer;
	int j = i;
	int k = ctx->pointer_index - 1;
	for (int m = k; m >= 0; m--) {
		int n = ctx->framebuffer[m];
		if (n != i) {
			j = n;
			break;
		}
	}
	DEBUG_PRINTF("paramInt=%x i=%x j=%x k=%x\n", paramInt, i, j, k);
    if (ctx->pointer_index + 4 > ctx->height*ctx->width)
        return;

	framebuffer[ctx->pointer_index++] = paramInt & 0x8 ? j : i;
	framebuffer[ctx->pointer_index++] = paramInt & 0x4 ? j : i;
	framebuffer[ctx->pointer_index++] = paramInt & 0x2 ? j : i;
	framebuffer[ctx->pointer_index++] = paramInt & 0x1 ? j : i;

	if ((paramInt & 0x10) == 0)
		DEBUG_PRINTF("%d) MS (length=4)\n", ctx->step_count);
	else {
		int m = 0;
		while (1) {
			assert(ctx->bytes_read < ctx->packet_buffer_size);
			paramInt = ctx->packet_buffer[ctx->bytes_read++];
			m += 7;

            if (ctx->pointer_index + 7 > ctx->height*ctx->width)
                break;

			framebuffer[ctx->pointer_index++] = paramInt & 0x40 ? j : i;
			framebuffer[ctx->pointer_index++] = paramInt & 0x20 ? j : i;
			framebuffer[ctx->pointer_index++] = paramInt & 0x10 ? j : i;
			framebuffer[ctx->pointer_index++] = paramInt & 0x08 ? j : i;
			framebuffer[ctx->pointer_index++] = paramInt & 0x04 ? j : i;
			framebuffer[ctx->pointer_index++] = paramInt & 0x02 ? j : i;
			framebuffer[ctx->pointer_index++] = paramInt & 0x01 ? j : i;
			DEBUG_PRINTF("paramInt=%x pointer_index=%x  m=%x\n", (int)(int8_t)paramInt, ctx->pointer_index, m);
			if ((paramInt & 0x80) == 0)
				break;
		}

		DEBUG_PRINTF("%d) MS2 (length=%d)\n", ctx->step_count, m + 4);
	}
}

void processMPCommand(client_ctx *ctx, uint8_t arg)
{
	uint8_t i = arg & 0x7F;
	int m;

	assert(ctx->bytes_read < ctx->packet_buffer_size);

    if (ctx->codec == TYPE_SECONDARY_DVC15_VIDEO) {
        int j = ctx->packet_buffer[ctx->bytes_read++] & 0xFF;
        int k = (i << 8) | (j & 0xFF);
        m = dvc15_colormap[k];
    } else //if (ctx->codec == TYPE_SECONDARY_DVC7_VIDEO)
        m = dvc7_colormap[i];
	ctx->framebuffer[ctx->pointer_index] = m;
	ctx->pointer_index++;
	DEBUG_PRINTF("%d) Make Pixel (%x)\n", ctx->step_count, m);
}

int getRunLength(client_ctx *ctx, uint8_t arg)
{
	int i = arg & 0xE0;
	int j = arg & 0x1F;
	int k = 1;

	//assert(bytes_read < packet_buffer_size);
	while (k < 5)
	{
		if (ctx->bytes_read >= ctx->packet_buffer_size) {
			DEBUG_PRINTF("RLE overran end of frame\n");
			break;
		}
		
        int m = ctx->packet_buffer[ctx->bytes_read];
		int n = m & 0xE0;
		DEBUG_PRINTF("paramInt=%x i=%x j=%x k=%x m=%x n=%x\n", arg, i, j, k, m, n);
		if (n != i)
			break;

		ctx->bytes_read++;
		j |= (m & 0x1F) << k++ * 5;
	}

	DEBUG_PRINTF("returned j=%x\n", j);
    if (ctx->codec == TYPE_SECONDARY_DVC15_VIDEO)
        return j;
    else //if (ctx->codec == TYPE_SECONDARY_DVC7_VIDEO)
        return j + 2;
}
