#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>

#include "print.h"
#include "image_io.h"
#include "segmentation.h"

#define DEFAULT_N_CLUS 4
#define DEFAULT_MAX_ITERS 150
#define DEFAULT_OUT_PATH "result.jpg"

double get_time();
void print_usage(char *pgr_name);
void print_exec(int width, int height, int n_ch, int n_clus, int n_iters, double sse, double exec_time);

int main(int argc, char **argv)
{
    char *in_path = NULL;
    char *out_path = DEFAULT_OUT_PATH;
    byte_t *data;
    int width, height, n_ch;
    int n_clus = DEFAULT_N_CLUS;
    int n_iters = DEFAULT_MAX_ITERS;
    int seed = time(NULL);
    double sse, start_time, exec_time;

    
    // 输入参数
    char optchar;
    while ((optchar = getopt(argc, argv, "k:m:o:s:h")) != -1) {
        switch (optchar) {
            case 'k':
                n_clus = strtol(optarg, NULL, 10);
                break;
            case 'm':
                n_iters = strtol(optarg, NULL, 10);
                break;
            case 'o':
                out_path = optarg;
                break;
            case 's':
                seed = strtol(optarg, NULL, 10);
                break;
            case 'h':
            default:
                print_usage(argv[0]);
                exit(EXIT_FAILURE);
                break;
        }
    }

    in_path = argv[optind];

    if (in_path == NULL) {
        print_usage(argv[0]);
        exit(EXIT_FAILURE);
    }

    if (n_clus < 2) {
        fprintf(stderr, "INPUT ERROR: << Invalid number of clusters >> \n");
        exit(EXIT_FAILURE);
    }

    if (n_iters < 1) {
        fprintf(stderr, "INPUT ERROR: << Invalid maximum number of iterations >> \n");
        exit(EXIT_FAILURE);
    }

    srand(seed);

    // 扫描输入图像

    data = img_load(in_path, &width, &height, &n_ch);

    // 执行图像分割算法

    start_time = get_time();
    kmeans_segm(data, width, height, n_ch, n_clus, &n_iters, &sse);
    exec_time = get_time() - start_time;

    // 保存并输出结果

    img_save(out_path, data, width, height, n_ch);
    print_exec(width, height, n_ch, n_clus, n_iters, sse, exec_time);

    free(data);

    return EXIT_SUCCESS;
}

double get_time()
{
    struct timeval timecheck;

    gettimeofday(&timecheck, NULL);

    return timecheck.tv_sec + timecheck.tv_usec / 1000000.0;
}
