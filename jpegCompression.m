function jpegCompression(image)

    rgb = imread(image);
    ycbcr = rgb2ycbcr(rgb);
    
    width = size(rgb);
    height = width(2);
    width = width(1);
    
    N = 8;
    
    for i=1:width
        for j=1:height
            x = mod(i-1, 2);
            y = mod(j-1, 2);
            
            ycbcr(i,j,1) = ycbcr(i,j,1);
            ycbcr(i,j,2) = ycbcr(i-x,j-y,2); 
            ycbcr(i,j,3) = ycbcr(i-x,j-y,3);
        end
    end
    
    lum_matrix = [16 11 10 16 24 40 51 61; 12 12 14 19 26 58 60 55; 14 13 16 24 40 57 69 56; 14 17 22 29 51 87 80 62; 18 22 37 56 68 109 103 77; 24 35 55 64 81 104 113 92; 49 64 78 87 103 121 120 101; 72 92 95 98 112 100 103 99];
    chrom_matrix = [17 18 24 47 99 99 99 99; 18 21 26 66 99 99 99 99; 24 26 56 99 99 99 99 99; 47 66 99 99 99 99 99 99; 99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99; 99 99 99 99 99 99 99 99];
    
    dct = uint8(zeros(width,height,3));
    quantized = uint8(zeros(width,height,3));
    dequantized = uint8(zeros(width,height,3));
    idct = uint8(zeros(width,height,3));
    for i = 0:floor(width/8)
        for j = 0:floor(height/8)
            for channel = 1:3
                for m = 0:1:N-1
                    for n = 0:1:N-1
                        if n == 0
                            kn = sqrt(1/N);
                        else
                            kn = sqrt(2/N);
                        end

                        if n == 0
                            km = sqrt(1/N);
                        else
                            km = sqrt(2/N);
                        end

                        sum = 0;
                        for k = 0:1:N-1
                            for l = 0:1:N-1
                                dct_coef = ycbcr((i * 8) + k, (j * 8) + l, channel) * cos((2 * k + 1) * i * pi / (2 * N)) * cos((2 * l + 1) * j * pi / (2 * N));
                                sum = sum + dct_coef;
                            end
                        end
                        dct(i*8 + m + 1, j*8 + n + 1) = kn * km * sum;
                        if channel == 1
                            quantized(i*8 + m, j*8 + n, 1) = dct(i*8 + m, j*8 + n, 1) / lum_matrix(m, n);
                        end
                        if channel == 2
                            quantized(i*8 + m, j*8 + n, 2) = dct(i*8 + m, j*8 + n, 2) / chrom_matrix(m, n);
                        end
                        if channel == 3
                            quantized(i*8 + m, j*8 + n, 3) = dct(i*8 + m, j*8 + n, 3) / chrom_matrix(m, n);
                        end
                        
                        if channel == 1
                            dequantized(i*8 + m, j*8 + n, 1) = quantized(i*8 + m, j*8 + n, 1) * lum_matrix(m, n);
                        end
                        if channel == 2
                            dequantized(i*8 + m, j*8 + n, 2) = quantized(i*8 + m, j*8 + n, 2) * chrom_matrix(m, n);
                        end
                        if channel == 3
                            dequantized(i*8 + m, j*8 + n, 3) = quantized(i*8 + m, j*8 + n, 3) * chrom_matrix(m, n);
                        end
                        
                        isum = 0;
                        for k = 0:1:N-1
                            for l = 0:1:N-1
                                idct_coef = kn * km * dequantized((i * 8) + k, (j * 8) + l, channel) * cos((2 * k + 1) * i * pi / (2 * N)) * cos((2 * l + 1) * j * pi / (2 * N));
                                isum = isum + idct_coef;
                            end
                        end
                        idct(i*8 + m, j*8 + n) = sum;
                    end
                end
            end
        end
    end
    
    step1_name = strcat('step1_', image);
    step2_name = strcat('step2_', image);
    step1 = ycbcr2rgb(quantized);
    step2 = ycbcr2rgb(idct);
    
    imwrite(step1, step1_name);
    imwrite(step2, step2_name);
end