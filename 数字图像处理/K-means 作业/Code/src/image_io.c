#include <stdio.h>
#include <string.h>

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include "../libs/stb_image.h"
#include "../libs/stb_image_write.h"

#include "image_io.h"

//载入图片
byte_t *img_load(char *img_file, int *width, int *height, int *n_channels)
{
    byte_t *data;

    data = stbi_load(img_file, width, height, n_channels, 0);
    if (data == NULL) {
        fprintf(stderr, "ERROR LOADING IMAGE: << Invalid file name or format >> \n");
        exit(EXIT_FAILURE);
    }

    return data;
}

// 保存图片
void img_save(char *img_file, byte_t *data, int width, int height, int n_channels)
{
    char *ext;

    ext = strrchr(img_file, '.');

    if (!ext) {
        fprintf(stderr, "ERROR SAVING IMAGE: << Unspecified format >> \n\n");
        return;
    }
    
    //保存为不同图片格式
    if ((strcmp(ext, ".jpeg") == 0) || (strcmp(ext, ".jpg") == 0)) {
        stbi_write_jpg(img_file, width, height, n_channels, data, 100);
    } else if (strcmp(ext, ".png") == 0) {
        stbi_write_png(img_file, width, height, n_channels, data, width * n_channels);
    } else if (strcmp(ext, ".bmp") == 0) {
        stbi_write_bmp(img_file, width, height, n_channels, data);
    } else if (strcmp(ext, ".tga") == 0) {
        stbi_write_tga(img_file, width, height, n_channels, data);
    } else {
        fprintf(stderr, "ERROR SAVING IMAGE: << Unsupported format >> \n\n");
    }
}
