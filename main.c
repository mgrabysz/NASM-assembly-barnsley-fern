#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>

#include "f.h"

#include<allegro5/allegro.h>
#include <allegro5/allegro_image.h>

#pragma pack(1)

#define OUTPUT_FILE_NAME "barnsley_fern.bmp"

#define BMP_HEADER_SIZE 54
#define BMP_PIXEL_OFFSET 54
#define BMP_PLANES 1
#define BMP_BPP 24
#define BMP_HORIZONTAL_RES 500
#define BMP_VERTICAL_RES 500
#define BMP_DIB_HEADER_SIZE 40

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

void write_bytes_to_bmp(unsigned  char *buffer, size_t size)
{
    FILE *file;

    file = fopen(OUTPUT_FILE_NAME, "wb");
    if (file == NULL)
    {
        printf("Could not open output file.");
        exit(-1);
    }
    fwrite(buffer, 1, size, file);
    fclose(file);
}

unsigned char *generate_empty_bitmap(unsigned int width, unsigned int height, size_t *output_size)
{
    unsigned int row_size = (width*3 + 3) & ~3; // possible padding
    *output_size = row_size * height + BMP_HEADER_SIZE;
    unsigned char *bitmap = (unsigned char *) malloc(*output_size);

    BmpHeader header;

    header.sig_0 = 'B';
    header.sig_1 = 'M';
    header.size = *output_size;
    header.reserved = 0;
    header.pixel_offset = BMP_PIXEL_OFFSET;
    header.header_size = BMP_DIB_HEADER_SIZE;
    header.width = width;
    header.height = height;
    header.planes = BMP_PLANES;
    header.bpp_type = BMP_BPP;
    header.compression = 0;
    header.image_size = row_size * height;
    header.horizontal_res = BMP_HORIZONTAL_RES;
    header.vertical_res = BMP_VERTICAL_RES;
    header.color_palette = 0;
    header.important_colors = 0;

    memcpy(bitmap, &header, BMP_HEADER_SIZE);

    return bitmap;
}

int main()
{
    size_t bmp_size = 0;
    unsigned char *bmp_buffer = generate_empty_bitmap(1024, 1024, &bmp_size);

    int counter, prob1, prob2, prob3, value, sum, is_displayed = 0;
    char exit[3];
    char no[3] = "n";


    ALLEGRO_DISPLAY *Screen;
    ALLEGRO_BITMAP *Image = NULL;


    do {
        printf("Enter number of steps: ");
        scanf("%d", &counter);

        printf("Enter probability of calling f1: ");
        scanf("%d", &prob1);

        printf("Enter probability of calling f2: ");
        scanf("%d", &prob2);

        printf("Enter probability of calling f3: ");
        scanf("%d", &prob3);

        sum = prob1 + prob2+ prob3;
        if (sum >= 100) {
            printf("These values are not correct\n");
            continue;
        }

        printf("Probability of calling f4 is computed automatically\n");

        if (is_displayed == 1) {
            al_destroy_display(Screen);
        }

        f(bmp_buffer, counter, prob1, prob2, prob3);

        write_bytes_to_bmp(bmp_buffer, bmp_size); //save bmp buffer into file

        al_init();
        al_init_image_addon();

        Screen = al_create_display(1024, 1024);
        is_displayed = 1;

        Image = al_load_bitmap("barnsley_fern.bmp");
        al_draw_bitmap(Image, 0, 0, 0);
        al_flip_display();
        // al_rest(5.0);

        printf("Do you want to quit? [y/n]: ");
        scanf("%s", exit);;
        value=strcmp(exit, no);

    } while (value == 0);

    al_destroy_display(Screen);
    free(bmp_buffer);

    return 0;
}