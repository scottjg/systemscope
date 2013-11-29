#define COLORMAP_SIZE 32768
#define BUFFER_SIZE 65535

typedef enum {UNKNOWN = 0, DRAC4 = 4, DRAC5 = 5, DRAC6 = 6, DRAC7 = 7, C6000 = 8} drac_type_t;

typedef struct client_ctx
{
    int (*glue_write_data_ctrl)(struct client_ctx *, void *, size_t);
    int (*glue_write_data_video)(struct client_ctx *, void *, size_t);
    int (*glue_read_data_ctrl)(struct client_ctx *, size_t);
    int (*glue_read_data_video)(struct client_ctx *, size_t);
    int (*glue_start_ssl_ctrl)(struct client_ctx *);
    int (*glue_start_ssl_video)(struct client_ctx *);

    uint8_t ctrl_buffer[BUFFER_SIZE];
    size_t ctrl_buffer_size;
    uint8_t video_buffer[BUFFER_SIZE];
    size_t video_buffer_size;
    size_t unacked_video_packets;
    char *user, *passwd;
    char session_id[64];
    drac_type_t dracType;
    
    int ctrl_ssl;
    int video_ssl;
    
    int step_count;
    int pointer_index;
    int bytes_read;
    int frame_count;
    int needs_refresh;
    uint8_t *packet_buffer;
    int packet_buffer_size;
    int height, width, eof, bof;
    uint16_t codec;
    uint32_t *framebuffer;
    
    struct {
        uint8_t state[256];
        uint8_t digest_key[16];
        int x;
        int y;
    } rc4;
} client_ctx;