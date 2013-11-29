#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#include "md5.h"
#include "glue.h"
#include "decoder.h"
#include "protocol.h"
#include "rc4.h"

#define TYPE_DRAC4_LOGIN_RESPONSE 63
#define TYPE_DRAC4_VIDEO_1024X768 2
#define TYPE_DRAC4_VIDEO_800X600 3
#define TYPE_DRAC4_VIDEO_640X480 4
#define TYPE_DRAC4_VIDEO_640X400 23
#define TYPE_DRAC4_VIDEO_656X496 62

#define TYPE_USER_LOGIN_RESPONSE 33536
#define TYPE_V2_USER_LOGIN_RESPONSE 33541
#define TYPE_PROTOCOL_VERSION     33538
#define TYPE_AVAILABLE_SERVERS    33840
#define TYPE_MOUSE_ACCEL_RESPONSE 33026
#define TYPE_SHARED_USER_RESPONSE 33808
#define TYPE_USER_PRIVILEDGES_RESPONSE 33824
#define TYPE_SESSION_SHARING_REQUEST 33793


#define TYPE_VIDEO_CONNECT_STATUS 132
#define TYPE_SCALING_RESPONSE 33283
#define TYPE_SECONDARY_DVC23_VIDEO 138
#define TYPE_SECONDARY_TEXT_MODE_VIDEO 135
#define TYPE_SECONDARY_COLOR_PALETTE 136
#define TYPE_SECONDARY_FONT_TABLE 137
#define TYPE_SECONDARY_ANDERSON_VIDEO 128
#define TYPE_SECONDARY_DVC7_GRAY_VIDEO 131
#define TYPE_SECONDARY_VIDEO_STOPPED 133
#define TYPE_SECONDARY_ASPEED_JPEG_VIDEO 134


static int handle_msg_ctrl(client_ctx *ctx, uint8_t *data, uint16_t type, uint16_t msg_size);
static int handle_msg_video(client_ctx *ctx, uint8_t *data, uint16_t type, uint16_t msg_size);
static int handle_init_response_ctrl(client_ctx *ctx, uint8_t *data, uint16_t type, uint16_t msg_size);
static int handle_init_response_video(client_ctx *ctx, uint8_t *data, uint16_t type, uint16_t msg_size);
static int handle_login_msg(client_ctx *ctx, uint8_t *data, uint16_t msg_size);
static void drac4_send_login(client_ctx *ctx);
static int drac4_handle_msg_ctrl(client_ctx *ctx, uint8_t *data, uint32_t type, uint32_t msg_size);
static void get_session_info(client_ctx *ctx);

int connect_start_ctrl(client_ctx *ctx, char *_user, char *_passwd)
{
	char INIT_HEADER[] =
		"APCP\x00\x00\x00""5\x01\x00\x00\x00\x03\x02\"\x00\x00\x00\x00\x05 t\xED#\x16\xF3""p6\xF5""1p\xE6\x8E\xC0\x88L\xFD^\x8F\xAE\xCB""8\xDF\xC5""8\xFA\x17""q\x17\xF7\xB3""U\xBE";
		//"APCP\x00\x00\x00""5\x01\x00\x00\x00\x03\x02\"\x00\x00\x00\x00\x05 %"
		//"\x0F\xDA\x15\a\xF1\xDE\xD5\xAA""5jV\xF4.\xDDh\xB5m\x17!\xC4\xCBsO"
        //"\xAA\xE0\xADK\tv?G";
	ctx->user = strdup(_user);
	ctx->passwd = strdup(_passwd);

    if (ctx->dracType >= DRAC6)
        ctx->glue_write_data_ctrl(ctx, INIT_HEADER, sizeof(INIT_HEADER) - 1);
    else if (ctx->dracType == DRAC5)
        handle_init_response_ctrl(ctx, (uint8_t *)"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF", 0, 16);
    else //if (ctx->dracType >= DRAC4)
        drac4_send_login(ctx);

    rc4_set_key(ctx, _passwd);
	ctx->glue_read_data_ctrl(ctx, 8);
	return 0;
}

static void drac4_send_login(client_ctx *ctx)
{
    uint32_t size = htonl(8 + 4 + strlen(ctx->passwd));
    uint32_t session_num = htonl(atoi(ctx->user));
    uint32_t cmd = htonl(63);
    uint8_t digest1[MD5_DIGEST_LENGTH], digest2[MD5_DIGEST_LENGTH];
    MD5((const unsigned char *)ctx->passwd, strlen(ctx->passwd), digest1);
    MD5(digest1, MD5_DIGEST_LENGTH, digest2);

    ctx->glue_write_data_ctrl(ctx, &size, sizeof(size));
    ctx->glue_write_data_ctrl(ctx, &cmd, sizeof(cmd));
    ctx->glue_write_data_ctrl(ctx, &session_num, sizeof(session_num));
    ctx->glue_write_data_ctrl(ctx, digest2, MD5_DIGEST_LENGTH);
}

int connect_start_video(client_ctx *ctx)
{
	char VIDEO_INIT_HEADER[] =
		"APCP\x00\x00\x00""5\x01\x00\x00\x00\x04\x02\"\x00\x00\x00\x00\x05 Y"
		"\xCF""7\xC1P\xA0g\r\xFBJ\x80\x94Wr\xEAR\xD5\x8B/3\xED\xF3\xAE""7\x9E"
		"\xBB[B4\xBF""8\x1E";
    if (ctx->dracType >= DRAC6)
        ctx->glue_write_data_video(ctx, VIDEO_INIT_HEADER, sizeof(VIDEO_INIT_HEADER) - 1);
    else
        //XXX need to figure out ssl from web
        handle_init_response_video(ctx, (uint8_t *)"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x00\xFF\xFF\xFF\xFF\xFF\xFF", 0, 16);

	ctx->glue_read_data_video(ctx, 8);
	return 0;
}

int incoming_data_ctrl(client_ctx *ctx, uint8_t *data, size_t len)
{
    uint32_t type, msg_size;
	if (ctx->ctrl_buffer_size + len > BUFFER_SIZE)
		return ERR_OVERFLOW;

	memcpy(&ctx->ctrl_buffer[ctx->ctrl_buffer_size], data, len);
	ctx->ctrl_buffer_size += len;

	if (ctx->ctrl_buffer_size < 8) {
        assert(ctx->ctrl_buffer_size == 0);
		ctx->glue_read_data_ctrl(ctx, 8 - ctx->ctrl_buffer_size);
		return 0;
	}

    if (ctx->dracType == DRAC4) {
        type = ntohl(*(uint32_t *)&ctx->ctrl_buffer[4]);
        msg_size = ntohl(*(uint32_t *)&ctx->ctrl_buffer[0]);
    } else {
        type = ntohs(*(uint16_t *)&ctx->ctrl_buffer[4]);
        msg_size = ntohs(*(uint16_t *)&ctx->ctrl_buffer[6]);
    }

	if (msg_size > ctx->ctrl_buffer_size) {
        assert(ctx->ctrl_buffer_size == 8);
		ctx->glue_read_data_ctrl(ctx, msg_size - ctx->ctrl_buffer_size);
		return 0;
	}

	int r;
	if (memcmp(ctx->ctrl_buffer, "APCP", 4) == 0)
		r = handle_init_response_ctrl(ctx, &ctx->ctrl_buffer[8], type, msg_size - 8);
	else {
        if (ctx->dracType == DRAC4)
            r = drac4_handle_msg_ctrl(ctx, ctx->ctrl_buffer, type, msg_size);
        else
            r = handle_msg_ctrl(ctx, &ctx->ctrl_buffer[8], type, msg_size - 8);
    }
	ctx->ctrl_buffer_size -= msg_size;
    assert (ctx->ctrl_buffer_size == 0);
	if (r >= 0)
		ctx->glue_read_data_ctrl(ctx, 8);
	return r;
}

int incoming_data_video(client_ctx *ctx, uint8_t *data, size_t len)
{
	if (ctx->video_buffer_size + len > BUFFER_SIZE)
		return ERR_OVERFLOW;

	memcpy(&ctx->video_buffer[ctx->video_buffer_size], data, len);
	ctx->video_buffer_size += len;

	if (ctx->video_buffer_size < 8) {
		ctx->glue_read_data_video(ctx, 8 - ctx->video_buffer_size);
		return 0;
	}

	uint16_t type = ntohs(*(uint16_t *)&ctx->video_buffer[4]);
	uint16_t msg_size = ntohs(*(uint16_t *)&ctx->video_buffer[6]);
	if (msg_size > ctx->video_buffer_size) {
		ctx->glue_read_data_video(ctx, msg_size - ctx->video_buffer_size);
		return 0;
	}

	int r;
	if (memcmp(ctx->video_buffer, "APCP", 4) == 0)
		r = handle_init_response_video(ctx, &ctx->video_buffer[8], type, msg_size - 8);
	else
		r = handle_msg_video(ctx, &ctx->video_buffer[8], type, msg_size - 8);
	ctx->video_buffer_size -= msg_size;
	if (r >= 0)
		ctx->glue_read_data_video(ctx, 8);

	return r;
}

static int handle_init_response_ctrl(client_ctx *ctx, uint8_t *data, uint16_t type, uint16_t msg_size)
{
	uint8_t len;

	//switch to ssl if the server wants it
	if(data[9] & 0x4) {
		ctx->glue_start_ssl_ctrl(ctx);
        ctx->ctrl_ssl = 1;
    }

	//send login message
    if (ctx->dracType >= DRAC6)
        ctx->glue_write_data_ctrl(ctx, "BEEF\x01\x02\x00\xD9", 8);
    else
        ctx->glue_write_data_ctrl(ctx, "BEEF\x01\x00\x00\xD9", 8);

    len = strlen(ctx->user);
	ctx->glue_write_data_ctrl(ctx, &len, 1);
	ctx->glue_write_data_ctrl(ctx, ctx->user, len);
	for (int i = 0; i < 96 - len; i++)
		ctx->glue_write_data_ctrl(ctx, "\x00", 1);
	len = strlen(ctx->passwd);
	ctx->glue_write_data_ctrl(ctx, &len, 1);
	ctx->glue_write_data_ctrl(ctx, ctx->passwd, len);
	for (int i = 0; i < 104 - len; i++)
		ctx->glue_write_data_ctrl(ctx, "\x00", 1);
	ctx->glue_write_data_ctrl(ctx, "\x01\x00\x00\x00\x00\x00", 6);
    //XXX last byte is a sharing request. probably want to not send it, and then
    //    reconnect and send it if we need to, otherwise we don't know if we're
    //    requesting it and it'll just hang.
    if (ctx->dracType == C6000 || ctx->dracType == DRAC7)
        ctx->glue_write_data_ctrl(ctx, "\x00", 1);
    else
        ctx->glue_write_data_ctrl(ctx, "\x01", 1);
    get_session_info(ctx);
	return 0;
}

static int handle_init_response_video(client_ctx *ctx, uint8_t *data, uint16_t type, uint16_t msg_size)
{
	//switch to ssl if the server wants it
	if(data[9] & 0x4) {
		ctx->glue_start_ssl_video(ctx);
        ctx->video_ssl = 1;
    }
	ctx->glue_write_data_video(ctx, "\x00\x00\x00\x00\x01\x01\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00", 16);
	return 0;
}

static int handle_msg_video(client_ctx *ctx, uint8_t *data, uint16_t type, uint16_t msg_size)
{
	uint64_t status;
	int r;

	switch (type) {
		case TYPE_VIDEO_CONNECT_STATUS:
			status = *(uint64_t *)data;
			if (status != 0) {
				printf("video connect failed with status: %lld\n", status);
				return -1;
			}
			printf("got video connect status\n");
			break;
		case TYPE_SCALING_RESPONSE:
		case TYPE_SECONDARY_VIDEO_STOPPED:
			printf("got video packet type %hu size=%hu (ignored)\n", type, msg_size);
			break;
		case TYPE_SECONDARY_DVC7_VIDEO:
		case TYPE_SECONDARY_DVC15_VIDEO:
			//printf("got legit video packet type %hu size=%hu\n", type, msg_size);
            ctx->glue_write_data_video(ctx, "BEEF\x00\x00\x00\x10\x01\x00\x00\x00\x00\x00\x00\x00", 16);
            r = load_packet(ctx, data, msg_size, type);
            if (r > 0) {
                return NEW_FRAME_READY;
            }

            if (ctx->needs_refresh && ctx->frame_count > 2) {
                //XXX when sharing a session, we sometimes don't get a full screen update, and requesting
                //    one after before the first few frames doesn't seem to work so...
                ctx->glue_write_data_ctrl(ctx, "BEEF\x03\x01\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00", 16);
                ctx->needs_refresh = 0;
            }
            break;
        case TYPE_SECONDARY_DVC23_VIDEO:
		case TYPE_SECONDARY_TEXT_MODE_VIDEO:
		case TYPE_SECONDARY_COLOR_PALETTE:
		case TYPE_SECONDARY_FONT_TABLE:
		case TYPE_SECONDARY_ANDERSON_VIDEO:
		case TYPE_SECONDARY_DVC7_GRAY_VIDEO:
		case TYPE_SECONDARY_ASPEED_JPEG_VIDEO:
		default:
			status = *(uint64_t *)data;
			printf("unhandled video packet type %d (size=%hu): %llx\n", type, msg_size, status);
			break;
	}

	return 0;
}

int load_packet(client_ctx *ctx, uint8_t *data, uint16_t size, uint16_t type)
{
	if (size < 12)
		return -1;
    
	short height = ntohs(*(short *)&data[4]);
	short width  = ntohs(*(short *)&data[6]);
	int bof = data[8] & 1;
	int eof = data[8] & 2;
    
	return load_data(ctx, height, width, eof, bof, &data[12], size - 12, type);
}

static int drac4_handle_msg_ctrl(client_ctx *ctx, uint8_t *data, uint32_t type, uint32_t msg_size)
{
    uint32_t msgtype = type & 0x3F;
    uint16_t height, width;
    printf("got ctrl packet type %u size=%u\n", type, msg_size);
	switch (msgtype) {
        case TYPE_DRAC4_LOGIN_RESPONSE:
            ctx->glue_write_data_ctrl(ctx, "\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x00", 12);
            break;

        case TYPE_DRAC4_VIDEO_1024X768:
            width  = 1024;
            height = 768;
            goto handle_video;
        case TYPE_DRAC4_VIDEO_800X600:
            width  = 800;
            height = 600;
            goto handle_video;
        case TYPE_DRAC4_VIDEO_640X480:
            width  = 640;
            height = 480;
            goto handle_video;
        case TYPE_DRAC4_VIDEO_640X400:
            width  = 640;
            height = 400;
            goto handle_video;
        case TYPE_DRAC4_VIDEO_656X496:
            width  = 656;
            height = 496;
handle_video:
            if (msg_size < 28)
                return -1;
            int bof = data[6] & 1;
            int eof = data[6] & 2;
            
            if (eof) {
                ctx->frame_count++;
                if (ctx->frame_count % 8 == 0)
                    ctx->glue_write_data_ctrl(ctx, "\x00\x00\x00\x08\x00\x00\x00\x0c", 8);
            }
            if (load_data(ctx, height, width, eof, bof, &data[28], msg_size - 28, TYPE_SECONDARY_DVC7_VIDEO) > 0)
                return NEW_FRAME_READY;
            break;
    }
    
    return 0;
}

static int handle_msg_ctrl(client_ctx *ctx, uint8_t *data, uint16_t type, uint16_t msg_size)
{
    char msg[16];

    printf("got ctrl packet type %hu size=%hu\n", type, msg_size);
	switch (type) {
		case TYPE_USER_LOGIN_RESPONSE:
		case TYPE_V2_USER_LOGIN_RESPONSE:
			return handle_login_msg(ctx, data, msg_size);
			break;
		case TYPE_PROTOCOL_VERSION:
			if (msg_size == 8)
				printf("protocol version is %llx\n", *(uint64_t *)data);
			else
				printf("protocol version had weird payload size\n");
			break;
		case TYPE_MOUSE_ACCEL_RESPONSE:
			if (msg_size == 8)
				printf("mouse accel is %llx\n", *(uint64_t *)data);
			else
				printf("mouse accel had weird payload size\n");
			break;
        case TYPE_AVAILABLE_SERVERS:
            if (msg_size > 12) {
                uint16_t count = ntohs(*(uint16_t *)data);
                if (count > 0) {
                    uint16_t len = ntohs(*(uint16_t *)&data[2]);
                    if (len > 0 && len < sizeof(ctx->session_id) - 1) {
                        memcpy(ctx->session_id, &data[4], len);
                        return 0;
                    } //else
                        //NSLog(@"server info returned bad len (%d)", len);
                } //else
                    //NSLog(@"server info returned bad count (%d)", count);
            }
            break;
		case TYPE_USER_PRIVILEDGES_RESPONSE:
		case TYPE_SHARED_USER_RESPONSE:
			//printf("got ctrl packet type %hu size=%hu (ignored)\n", type, msg_size);
			break;
        case TYPE_SESSION_SHARING_REQUEST:
            // always just allow the connection
            memcpy(msg, "BEEF\x04\x13\x00\x10\x02\x00\x00\x00\x00\x00\x00\x00", 16);
            *(uint16_t *)&msg[10] = *(uint16_t *)data;
            ctx->glue_write_data_ctrl(ctx, msg, 16);
            break;
		default:
			printf("unknown message type %d\n", type);
			break;
	}

	return 0;
}

static int handle_login_msg(client_ctx *ctx, uint8_t *data, uint16_t msg_size)
{
	switch(data[0]) {
		case 0:
			//Success!
			printf("login ok!\n");
			//video enable
			ctx->glue_write_data_ctrl(ctx, "BEEF\x03\x0E\x00\x10\x01\x01\x00\x00\x00\x00\x00\x00", 16);
            ctx->glue_write_data_ctrl(ctx, "BEEF\x03\x02\x00\x10\x04\x00\x03\x00\x00\x00\x00\x00", 16);
            ctx->glue_write_data_ctrl(ctx, "BEEF\x03\x04\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00", 16);
            return NEED_TO_CONNECT_VIDEO;
			break;
		default:
			return ERR_LOGIN_FAILURE - (data[0] - 1);
	}
}

void send_key(client_ctx *ctx, uint32_t keycode, uint8_t keydown)
{
    uint8_t data[16];
    if (ctx->dracType == DRAC4) {
        memcpy(data, "\x00\x00\x00\x10\x00\x00\x00\x32\x00\x00\x00\x00\x00\x00\x00\x00", 16);
        if (keydown)
            data[11] = 10;
        else
            data[11] = 11;
        *(uint32_t *)&data[12] = htonl(keycode);
        rc4_encrypt(ctx, data, 16, 8);
    } else {
        memcpy(data, "BEEF\x02\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00", 16);
        if (keydown)
            data[9] = 0;
        else
            data[9] = 1;
        *(uint16_t *)&data[10] = htons(keycode);
    }

    ctx->glue_write_data_ctrl(ctx, data, 16);
}

void send_mouse(client_ctx *ctx, int x, int y, uint8_t mouse_buttons, uint8_t button_changed)
{
    uint8_t data[32];
    uint8_t size;
    if (ctx->dracType == DRAC4) {
        memcpy(data, "\x00\x00\x00\x14\x00\x00\x00\x0e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", 20);

        if (!button_changed) {
            size = 20;
            data[3] = size;
            *(uint32_t *)&data[12] = htonl(x);
            *(uint32_t *)&data[16] = htonl(y);
        } else {
            size = 16;
            data[3] = size;
            if (button_changed == 1) {
                data[11] = (mouse_buttons & 1) ? 1 : 2;
                data[15] = 16;
            } else if (button_changed == 2) {
                data[11] = (mouse_buttons & 2) ? 1 : 2;
                data[15] = 4;
            }
        }
    } else {
        memcpy(data, "BEEF\x02\x01\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00", 16);

        data[9] = mouse_buttons;
        *(uint16_t *)&data[10] = htons(x);
        *(uint16_t *)&data[12] = htons(y);
        size = 16;
    }
    ctx->glue_write_data_ctrl(ctx, data, size);
}

static void get_session_info(client_ctx *ctx)
{
    if (ctx->dracType == DRAC4)
        return; //XXX unsupported?
    
    uint8_t msg[] = "BEEF\x04\x20\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00";
    ctx->glue_write_data_ctrl(ctx, msg, sizeof(msg) - 1);
}

void send_power_command(client_ctx *ctx, uint8_t power_status)
{
    if (ctx->session_id[0] == 0)
        return;
    
    char msg[128];
    uint16_t msg_len;
    size_t session_len = strlen(ctx->session_id);
    msg_len = 8 + 2 + session_len + 1;

    memcpy(msg, "BEEF\x04\x24", 6);
    *(uint16_t *)&msg[6] = htons(msg_len);
    *(uint16_t *)&msg[8] = htons(session_len);
    strlcpy(&msg[10], ctx->session_id, sizeof(msg) - 8);
    msg[10 + session_len] = power_status;
    ctx->glue_write_data_ctrl(ctx, msg, msg_len);
}

void send_keepalive(client_ctx *ctx)
{
    if (ctx->dracType >= DRAC7) {
        ctx->glue_write_data_video(ctx, "APCP\x00\x00\x00\f\x04\x00\x00\x00", 12);
        ctx->glue_write_data_ctrl(ctx,  "APCP\x00\x00\x00\f\x04\x00\x00\x00", 12);
    }
}

