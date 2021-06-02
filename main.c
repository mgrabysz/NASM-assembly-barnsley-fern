#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>

#include "f.h"

#include<allegro5/allegro.h>  //adding libraries
#include <allegro5/allegro_image.h>

#define DEBUG 1
#pragma pack(1)

/*
 * important constants
 */
#define OUTPUT_FILE_NAME "output.bmp"

/*
 * Constants for .bmp file such as pixel offset
 * we use basic windows's standard DIB header
 * its size is 14 bytes + 40 bytes = 54 bytes
 */
#define BMP_HEADER_SIZE 54
#define BMP_PIXEL_OFFSET 54
#define BMP_PLANES 1
#define BMP_BPP 24
#define BMP_HORIZONTAL_RES 500 //experimental constants
#define BMP_VERTICAL_RES 500
#define BMP_DIB_HEADER_SIZE 40 //windows header

/*
 * struct for bmp header.
 */
typedef struct {
    unsigned char sig_0;
    unsigned char sig_1;
    uint32_t size;
    uint32_t reserved;
    uint32_t pixel_offset;
    uint32_t header_size;
    uint32_t width;
    uint32_t height;
    uint16_t planes;
    uint16_t bpp_type;
    uint32_t compression;
    uint32_t image_size;
    uint32_t horizontal_res;
    uint32_t vertical_res;
    uint32_t color_palette;
    uint32_t important_colors;
} BmpHeader;

/*
 * Initializes bmp_header with default values
 */
void init_bmp_header(BmpHeader *header)
{
    header -> sig_0 = 'B';
    header -> sig_1 = 'M';
    header -> reserved = 0;
    header -> pixel_offset = BMP_PIXEL_OFFSET;
    header -> header_size = BMP_DIB_HEADER_SIZE;
    header -> planes = BMP_PLANES;
    header -> bpp_type = BMP_BPP;
    header -> compression = 0;
    header -> image_size = 0;
    header -> horizontal_res = BMP_HORIZONTAL_RES;
    header -> vertical_res = BMP_VERTICAL_RES;
    header -> color_palette = 0;
    header -> important_colors = 0;
}

/*
 * writes bmp buffer array into .bmp file
 */
void write_bytes_to_bmp(unsigned  char *buffer, size_t size)
{
    FILE *file;

    file = fopen(OUTPUT_FILE_NAME, "wb");
    if (file == NULL)
    {
        printf("Could not open output file. Exiting!");
        exit(-1);
    }
    fwrite(buffer, 1, size, file);
    fclose(file);
}

/*
 * Generate empty bitmap for assembler usage. Initialize with white pixels
 */
unsigned char *generate_empty_bitmap(unsigned int width, unsigned int height, size_t *output_size)
{
    unsigned int row_size = (width*3 + 3) & ~3; //najmnniejsza wielokrotnosc 4
    *output_size = row_size * height + BMP_HEADER_SIZE;
    unsigned char *bitmap = (unsigned char *) malloc(*output_size);

    BmpHeader header;
    init_bmp_header(&header);
    header.size = *output_size;
    header.width = width;
    header.height = height;

    memcpy(bitmap, &header, BMP_HEADER_SIZE);
    for(int i = BMP_HEADER_SIZE; i < *output_size; ++i)
    {
        bitmap[i] = 0xff;
    }
    return bitmap;
}

//extern int set_pixel(unsigned char *dest_bitmap, unsigned int x, unsigned int y, unsigned int color);
//extern unsigned int get_pixel(unsigned char *src_bitmap, unsigned int x, unsigned int y);

int main()
{
    size_t bmp_size = 0;
    unsigned char *bmp_buffer = generate_empty_bitmap(1024, 1024, &bmp_size);


    int x, y;
    x = 1;
    y = 1;

    f(x, y, bmp_buffer);

    write_bytes_to_bmp(bmp_buffer, bmp_size);//save bmp buffer into file
    free(bmp_buffer); //deallocate bmp buffer


    ALLEGRO_DISPLAY *Screen;
    ALLEGRO_BITMAP *Image = NULL; ///object the holds the graphic. initialize it empty

    al_init();
    al_init_image_addon(); /// this must be called to load images. has to be called after al_init

    Screen = al_create_display(1024, 1024);

    Image = al_load_bitmap("output.bmp"); ///load the bitmap from a file
    al_draw_bitmap(Image, 0, 0, 0);
    al_flip_display();
    al_rest(20.0);
    al_destroy_display(Screen);

    return 0;
}