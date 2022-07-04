#ifndef SEGMENTATION_H
#define SEGMENTATION_H

void kmeans_segm(byte_t *data, int width, int height, int n_ch, int n_clus, int *n_iters, double *sse);
void kmeans_segm_omp(byte_t *data, int width, int height, int n_ch, int n_clus, int *n_iters, double *sse, int n_threads);

#endif
