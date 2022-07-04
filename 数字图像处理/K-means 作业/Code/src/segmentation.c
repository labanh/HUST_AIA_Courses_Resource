#include <stdlib.h>
#include <float.h>
#include <math.h>

#include "image_io.h"
#include "segmentation.h"

void init_centers(byte_t *data, double *centers, int n_px, int n_ch, int n_clus);
void assign_pixels(byte_t *data, double *centers, int *labels, double *dists, int *changes, int n_px, int n_ch, int n_clus);
void update_centers(byte_t *data, double *centers, int *labels, double *dists, int n_px, int n_ch, int n_clus);
void update_data(byte_t *data, double *centers, int *labels, int n_px, int n_ch);

//K-means分割
void kmeans_segm(byte_t *data, int width, int height, int n_ch, int n_clus, int *n_iters, double *sse)
{
    int n_px;
    int iter, max_iters;
    int changes;
    int *labels;
    double *centers;
    double *dists;

    max_iters = *n_iters;

    n_px = width * height;

    labels = malloc(n_px * sizeof(int));
    centers = malloc(n_clus * n_ch * sizeof(double));
    dists = malloc(n_px * sizeof(double));

    init_centers(data, centers, n_px, n_ch, n_clus);

    for (iter = 0; iter < max_iters; iter++) {
        assign_pixels(data, centers, labels, dists, &changes, n_px, n_ch, n_clus);

        if (!changes) {
            break;
        }

        update_centers(data, centers, labels, dists, n_px, n_ch, n_clus);
    }

    update_data(data, centers, labels, n_px, n_ch);

    compute_sse(sse, dists, n_px);

    *n_iters = iter;

    free(centers);
    free(labels);
    free(dists);
}

//初始化中心点
void init_centers(byte_t *data, double *centers, int n_px, int n_ch, int n_clus)
{
    int k, ch, rnd;

    for (k = 0; k < n_clus; k++) {
        rnd = rand() % n_px;

        for (ch = 0; ch < n_ch; ch++) {
            centers[k * n_ch + ch] = data[rnd * n_ch + ch];
        }
    }
}

//将各像素分配到不同的聚类
void assign_pixels(byte_t *data, double *centers, int *labels, double *dists, int *changes, int n_px, int n_ch, int n_clus)
{
    int px, ch, k;
    int min_k, tmp_changes = 0;
    double dist, min_dist, tmp;

    for (px = 0; px < n_px; px++) {
        min_dist = DBL_MAX;

        for (k = 0; k < n_clus; k++) {
            dist = 0;

            for (ch = 0; ch < n_ch; ch++) {
                tmp = (double)(data[px * n_ch + ch] - centers[k * n_ch + ch]);
                dist += tmp * tmp;
            }

            if (dist < min_dist) {
                min_dist = dist;
                min_k = k;
            }
        }

        dists[px] = min_dist;

        if (labels[px] != min_k) {
            labels[px] = min_k;
            tmp_changes = 1;
        }
    }

    *changes = tmp_changes;
}

//更新中心点
void update_centers(byte_t *data, double *centers, int *labels, double *dists, int n_px, int n_ch, int n_clus)
{
    int px, ch, k;
    int *counts;
    int min_k, far_px;
    double max_dist;

    counts = malloc(n_clus * sizeof(int));

    // 重设聚类中心矩阵

    for (k = 0; k < n_clus; k++) {
        for (ch = 0; ch < n_ch; ch++) {
            centers[k * n_ch + ch] = 0;
        }

        counts[k] = 0;
    }

    // 计算每个聚类的颜色分量的平均值

    for (px = 0; px < n_px; px++) {
        min_k = labels[px];

        for (ch = 0; ch < n_ch; ch++) {
            centers[min_k * n_ch + ch] += data[px * n_ch + ch];
        }

        counts[min_k]++;
    }

    for (k = 0; k < n_clus; k++) {
        if (counts[k]) {
            for (ch = 0; ch < n_ch; ch++) {
                centers[k * n_ch + ch] /= counts[k];
            }
        } else {
            // 若聚类为空，则选择较远的像素点作为集群中心

            max_dist = 0;

            for (px = 0; px < n_px; px++) {
                if (dists[px] > max_dist) {
                    max_dist = dists[px];
                    far_px = px;
                }
            }

            for (ch = 0; ch < n_ch; ch++) {
                centers[k * n_ch + ch] = data[far_px * n_ch + ch];
            }

            dists[far_px] = 0;
        }
    }

    free(counts);
}

//像素值更新
void update_data(byte_t *data, double *centers, int *labels, int n_px, int n_ch)
{
    int px, ch, min_k;

    for (px = 0; px < n_px; px++) {
        min_k = labels[px];

        for (ch = 0; ch < n_ch; ch++) {
            data[px * n_ch + ch] = (byte_t)round(centers[min_k * n_ch + ch]);
        }
    }
}