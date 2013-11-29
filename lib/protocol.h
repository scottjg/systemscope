
#define ERR_OVERFLOW -10
#define ERR_LOGIN_FAILURE -11
#define ERR_LOGIN_FAILURE_MAX -30

#define NEED_TO_CONNECT_VIDEO 1
#define NEW_FRAME_READY 2

#define TYPE_SECONDARY_DVC15_VIDEO 129
#define TYPE_SECONDARY_DVC7_VIDEO 130

int connect_start_ctrl(client_ctx *ctx, char *_user, char *_passwd);
int incoming_data_ctrl(client_ctx *ctx, uint8_t *data, size_t len);
int incoming_data_video(client_ctx *ctx, uint8_t *data, size_t len);
int connect_start_video(client_ctx *ctx);

void send_keepalive(client_ctx *ctx);
void send_key(client_ctx *ctx, uint32_t keycode, uint8_t keydown);
void send_mouse(client_ctx *ctx, int x, int y, uint8_t mouse_buttons, uint8_t button_changed);
void send_power_command(client_ctx *ctx, uint8_t power_status);
