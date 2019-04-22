function jpegCompression(image)

    rgb = imread(image);
    
    % STEP 1: COMPRESSION
    % -------------------
    
    
    % Conversion to YCbCr
    ycbcr = rgb2ycbcr(rgb);
    
    width = size(rgb);
    height = width(2);
    width = width(1);
    
    % Chroma Sub-Sampling 4:2:0
    subsampled = double(zeros(width,height,3));
    N = 8;
    for i=1:width
        for j=1:height
            x = mod(i-1, 2);
            y = mod(j-1, 2);
            
            subsampled(i,j,1) = ycbcr(i,j,1);
            subsampled(i,j,2) = ycbcr(i-x,j-y,2); 
            subsampled(i,j,3) = ycbcr(i-x,j-y,3);
        end
    end
    
    %dct_matlab = 255*dct(subsampled/255);
    %imwrite(ycbcr2rgb(idct(dct_matlab)), 'test-idct.png');
    
    % 2D DCT Transform
    dct = double(zeros(width,height,3));
    dct(:,:,1) = 255*dct2(subsampled(:,:,1)/255, N, N);
    dct(:,:,2) = 255*dct2(subsampled(:,:,2)/255, N, N);
    dct(:,:,3) = 255*dct2(subsampled(:,:,3)/255, N, N);
    for channel = 1:3
        for i = 0:N:width-1-N
            for j = 0:N:height-1-N
                for x = 1:N
                    for y = 1:N
                        if x == 0
                            kx = sqrt(1/N);
                        else
                            kx = sqrt(2/N);
                        end
    
                        if y == 0
                            ky = sqrt(1/N);
                        else
                            ky = sqrt(2/N);
                        end
                        
                        sum = 0;
                        for k = 1:N
                            for l = 1:N
                                dct_coef = subsampled(i + k, j + l, channel) * cos(((2 * (k-1) + 1) * (x-1) * pi) / (2 * N)) * cos(((2 * (l-1) + 1) * (y-1) * pi) / (2 * N));
                                sum = sum + dct_coef;
                            end
                        end
                        %dct(i + x, j + y) = (kx * ky * sum)/(2*N);
                    end
                end
            end
        end
    end
    
    % Quantization
    lum_matrix = [16 11 10 16 24 40 51 61; 12 12 14 19 26 58 60 55; 14 13 16 24 40 57 69 56; 14 17 22 29 51 87 80 62; 18 22 37 56 68 109 103 77; 24 35 55 64 81 104 113 92; 49 64 78 87 103 121 120 101; 72 92 95 98 112 100 103 99];
    chrom_matrix = [17 18 24 47 99 99 99 99; 18 21 26 66 99 99 99 99; 24 26 56 99 99 99 99 99; 47 66 99 99 99 99 99 99; 99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99];
    quantized = double(zeros(width,height,3));
    for i = 1:width
        for j = 1:height
            x = mod(i, N);
            y = mod(j, N);
            
            if x == 0
                x = 8;
            end
            if y == 0
                y = 8;
            end
            
            quantized(i, j, 1) = round(dct(i, j, 1) / (lum_matrix(x, y)));
            
            quantized(i, j, 2) = round(dct(i, j, 2) / (chrom_matrix(x, y)));
            
            quantized(i, j, 3) = round(dct(i, j, 3) / (chrom_matrix(x, y)));
        end
    end
    
    % STEP 2: DECOMPRESSION
    % ---------------------
    
    
    % Dequantization
    dequantized = double(zeros(width,height,3));
    for i = 1:width
        for j = 1:height
            x = mod(i, N);
            y = mod(j, N);
            
            if x == 0
                x = 8;
            end
            if y == 0
                y = 8;
            end
            
            dequantized(i, j, 1) = round(quantized(i, j, 1) * (lum_matrix(x, y)));
            
            dequantized(i, j, 2) = round(quantized(i, j, 2) * (chrom_matrix(x, y)));
            
            dequantized(i, j, 3) = round(quantized(i, j, 3) * (chrom_matrix(x, y)));
        end
    end
    
    %idct_matlab = idct(double(dequantized))/255;
    
    % 2D IDCT Transform
    idct = double(zeros(width,height,3));
    idct(:,:,1) = idct2(dequantized(:,:,1), N, N)/255;
    idct(:,:,2) = idct2(dequantized(:,:,2), N, N)/255;
    idct(:,:,3) = idct2(dequantized(:,:,3), N, N)/255;
    for channel = 1:3
        for i = 0:N:width-1-N
            for j = 0:N:height-1-N
                for k = 1:N
                    for l = 1:N
                        
                        sum = 0;
                        for x = 1:N
                            for y = 1:N
                                if x == 0
                                    kx = sqrt(1/N);
                                else
                                    kx = sqrt(2/N);
                                end
            
                                if y == 0
                                    ky = sqrt(1/N);
                                else
                                    ky = sqrt(2/N);
                                end
                                
                                idct_coef = ((kx * ky)/(2*N)) * dequantized(i + k, j + l, channel) * cos(((2 * (k-1) + 1) * (x-1) * pi) / (2 * N)) * cos(((2 * (l-1) + 1) * (y-1) * pi) / (2 * N));
                                sum = sum + idct_coef;
                            end
                        end
                        %idct(i + x, j + y) = sum;
                    end
                end
            end
        end
    end
    
    % YCbCr to RGB
    final_rgb = double(zeros(width,height,3));
    final_rgb = ycbcr2rgb(idct);
    
    % STEP 3: DISPLAY
    % ---------------
    
    
    % Display and save
    step1_subsample = strcat('step1_subsample_', image);
    step1_dct = strcat('step1_dct_', image);
    step1_quantization = strcat('step1_quantization_', image);
    ss_rgb = ycbcr2rgb(subsampled);
    dct_rgb = ycbcr2rgb(dct);
    quantized_rgb = ycbcr2rgb(quantized);
    
    step2_dequantization = strcat('step2_dequantization_', image);
    step2_idct = strcat('step2_idct-and-conversion_', image);
    dequantized_rgb = ycbcr2rgb(dequantized);
    
    imshow(ss_rgb);
    imshow(dct_rgb);
    imshow(quantized_rgb);
    
    imshow(dequantized_rgb);
    imshow(final_rgb);
    
    imwrite(ss_rgb, step1_subsample);
    imwrite(dct_rgb, step1_dct);
    imwrite(quantized_rgb, step1_quantization);
    
    imwrite(dequantized_rgb, step2_dequantization);
    imwrite(final_rgb, step2_idct);
end