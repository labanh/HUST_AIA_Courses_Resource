close all;
clear;
clc

%Read the image and divide the rgb data into three dimentions
rgb_data = imread('E:\PicProject\tests\test_pic.jpg');
r_data = rgb_data(:, :, 1);
g_data = rgb_data(:, :, 2);
b_data = rgb_data(:, :, 3);

%Draw the Origin Picture
subplot(3, 2, 1), imshow(rgb_data);
title('Origin Picture');

%set a matrix of the size and dimention of the rgb image
[row, col, dim] = size(rgb_data);

%Loop
for r = 1:row
    for c = 1:col
        Grey_data(r, c) = 0.299 * r_data(r, c) + 0.587 * g_data(r, c) + 0.114 * b_data(r, c);
    end
%for every row & column, use a formula to calculate the depth of the greyscale
end

%Draw the Grey Scale Image
subplot(3,2, 2), imshow(Grey_data);
title('Grey Scale Image');

%Draw the Gray Histogram
subplot(3,2, 3), bar(im_hist(Grey_data), 'g')
title('Gray Histogram')
xlabel('Grayscale Value')
ylabel('Probability')

%Draw the image processed by Histogram Equalization
I_eq = im_histeq(Grey_data);
subplot(1,2, 1), imshow(I_eq);
title('Histogram Equalization');

%Draw the image processed by Homomorphic Filtering
rH = 2; rL = 0.1; c = 0.5; D0 = 10000;
I_homo = homo_filter(rgb_data, rH, rL, c, D0);
subplot(1,2, 2), imshow(I_homo, []);
title('Homomorphic Filtering');


%Fourier Transform
%int I -> Doube I
I = Grey_data;
I = im2double(I);
Ax = ones(row, col);
com = 0 + 1i;
x = row; y = col;

% DFT
for k = 1:x
    for m = 1:y
        sn = 0;
        for n = 1:x
            sn = sn + I(n, m) * exp(-com * 2 * pi * k * n / x);
        end
        Ax(k, m) = sn;
    end
end

% DFT
for l = 1:y
    for k = 1:x
        sn = 0;
        for m = 1:y
            sn = sn + Ax(k, m) * exp(-com * 2 * pi * l * m / y);
        end
        ans(k, l) = sn;
    end
end

% Draw Fourier Transform Picture
% move zero to the center
F = fftshift(ans);
F = abs(F);
F = log(F + 1);

subplot(3,2,4), imshow(F, []);
title('Fourier Transform Picture');



% Draw histogram
function pmf = im_hist(I)
    % rgb -> Grey
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    
    [m, n] = size(I);
    %initialize pmf matrix
    pmf = zeros(1,256);
    % Compute the histogram
    for i = 0:255     
        pmf(i+1) = length(find(I==i))/(m*n);
    end
end


% Histogram Equalization
function I_eq = im_histeq(I)

    % Convert to grayscale image
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    
    % Compute the histogram of I
    pmf = im_hist(I);
    % cumulative distribution function
    csm = cumsum(pmf);
    s = round(csm*255);
    
    % Apply the result to image
    I_eq = I;
    for i = 0:255
        I_eq(I==i) = s(i+1);
    end
    
end

% Homomorphic Filtering
function I_homo = homo_filter(I, rH, rL, c, D0)

    % Convert to grayscale image
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    I = double(I);
    
    % turn the multiplicative components into additive components
    lg_I = log(I+1);

    % fourier transform
    F = fft(lg_I);
        
    % use gaussian high-pass filter
    I_gf = GHPF(I, rH, rL, c, D0);
    IF = I_gf.*F;
    
    % Inverse fourier transform
    ln_if = ifft(IF);
    intermediate = exp(ln_if)-1;
    
    % Normalization
    intermediate = im_norm(intermediate);
    
    % Image retrieval
    I_homo = uint8(round(intermediate*255));
end

% Gaussian high-pass filter.
function H = GHPF(I, rH, rL, c, D0)
    % Convert to grayscale image
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    [M, N] = size(I);
    H = zeros(M, N);
    
    % get the midpoint of the image
    m = floor(M/2);
    n = floor(N/2);
    % Calculate gaussian high-pass filter H(u,v)
    for x = 1:M
        for y = 1:N
            D2_uv = (x-m)^2+(y-n)^2;
            H(x,y) = (rH-rL)*(1-exp(-c*(D2_uv/(D0^2))))+rL;
        end
    end
end

% Normalizes the input image I.   
function I_norm = im_norm(I)
    I = double(I);
    I_max = max(I, [], 'all');
    I_min = min(I, [], 'all');
    % Normalize
    I_norm = (I - I_min)/(I_max-I_min);
end
