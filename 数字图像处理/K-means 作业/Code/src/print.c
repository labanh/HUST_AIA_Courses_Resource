#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

void print_usage(char *pgr_name);
void print_exec(int width, int height, int n_ch, int n_clus, int n_iters, double sse, double exec_time);


void print_usage(char *pgr_name)
{
    char *usage = "\nPROGRAM USAGE \n\n"
        "   %s [-h] [-k num_clusters] [-m max_iters] [-o output_img] \n"
        "                [-o output_img] [-s seed] input_image \n\n"
        "   The input image filepath is the only mandatory argument and \n"
        "   must be specified last, after all the optional parameters. \n"
        "   Valid input image formats are JPEG, PNG, BMP, GIF, TGA, PSD, \n"
        "   PIC, HDR and PNM. The program performs a color-based segmentation\n"
        "   of the input image using the k-means clustering algorithm. \n\n"
        "OPTIONAL PARAMETERS \n\n"
        "   -k num_clusters : number of clusters to use for the segmentation of \n"
        "                     the image. Must be bigger than 1. Default is %d. \n"
        "   -m max_iters    : maximum number of iterations that the clustering \n"
        "                     algorithm can perform before being forced to stop. \n"
        "                     Must be bigger that 0. Default is %d. \n"
        "   -o output_image : filepath of the output image. Valid output image \n"
        "                     formats are JPEG, PNG, BMP and TGA. If not specified, \n"
        "                     the resulting image will be saved in the current \n"
        "                     directory using JPEG format. \n"
        "   -s seed         : seed to use for the random selection of the initial \n"
        "                     centers. The clustering algorithm will always use  \n"
        "                     the same set of initial centers if the same \n"
        "                     seed is specified. \n"
        "   -h              : print usage information. \n\n";

    fprintf(stderr, usage, pgr_name, DEFAULT_N_CLUS, DEFAULT_MAX_ITERS);
}

void print_exec(int width, int height, int n_ch, int n_clus, int n_iters, double sse, double exec_time)
{
    char *details = "\nEXECUTION DETAILS\n\n"
        "  Image size             : %d x %d\n"
        "  Color channels         : %d\n"
        "  Number of clusters     : %d\n"
        "  Number of iterations   : %d\n"
        "  Sum of squared errors  : %f\n"
        "  Execution time         : %f\n\n";

    fprintf(stdout, details, width, height, n_ch, n_clus, n_iters, sse, exec_time);
}
