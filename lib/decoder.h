int decode_packet(client_ctx *ctx);
void processNCCommand(client_ctx *ctx, uint8_t);
void processCACommand(client_ctx *ctx, uint8_t);
void processCLCommand(client_ctx *ctx, uint8_t);
void processMSCommand(client_ctx *ctx, uint8_t);
void processMPCommand(client_ctx *ctx, uint8_t);
int getRunLength(client_ctx *ctx, uint8_t arg);
int load_packet(client_ctx *ctx, uint8_t *data, uint16_t size, uint16_t type);


void init_decoder(client_ctx *ctx);
int load_data(client_ctx *ctx, int _height, int _width, int eof, int bof, uint8_t *buffer, int size, uint16_t type);
