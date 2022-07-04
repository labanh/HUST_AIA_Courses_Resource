#ifndef IMAGE_IO_H
#define IMAGE_IO_H

typedef unsigned char byte_t;

byte_t *img_load(char *img_file, int *width, int *height, int *n_channels);
void img_save(char *img_file, byte_t *data, int width, int height, int n_channels);

#endif
