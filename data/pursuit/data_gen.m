close all;
clear all;
clc;
rng('default');

filepath = which(mfilename);
parent_dir = fileparts(filepath);

% Signal space 
N = 256;
% Number of measurements
M = 64;
% Sparsity level
K = 4;

% Constructing a sparse vector
% Choosing the support randomly
Omega = randperm(N, K);
% Initializing a zero vector
x = zeros(N, 1);
% Choosing non-zero values uniformly between (-b, -a) and (a, b)
a = 1;
b = 2; 
% unsigned magnitudes of non-zero entries
xm = a + (b-a).*rand(K, 1);
% Generate sign for non-zero entries randomly
sgn = sign(randn(K, 1));
% Combine sign and magnitude
x(Omega) = sgn .* xm;
%stem(x, '.');

% Constructing a Gaussian sensing matrix
Phi = randn(M, N);

% Computing norm of each column
column_norms = sqrt(sum(Phi .* conj(Phi)));

% Constructing a Gaussian dictionary with normalized columns
for i=1:N
    v = column_norms(i);
    % Scale it down
    Phi(:, i) = Phi(:, i) / v;
end

y0 = Phi * x;

fraction_bits = 15;
float_to_fix_factor = 2^fraction_bits;

x = int32(round(x * float_to_fix_factor));
y = int32(round(y0 * float_to_fix_factor));
Phi2 = int32(round(Phi * float_to_fix_factor));

problem_dir = fullfile(parent_dir, 'problem_0');
if ~isdir(problem_dir)
    mkdir(problem_dir);
end
description_file_path = fullfile(problem_dir, 'description.txt');
description_file = fopen(description_file_path, 'w');
fprintf(description_file, 'M: %d\n',  M);
fprintf(description_file, 'N: %d\n',  N);
fprintf(description_file, 'Fraction bits: %d\n',  fraction_bits);

fclose(description_file);

y_file_path = fullfile(problem_dir, 'y.bin');
x_file_path = fullfile(problem_dir, 'x.bin');
phi_file_path = fullfile(problem_dir, 'dict.bin');

y_id = fopen(y_file_path, 'w');
fwrite(y_id, y, 'integer*4', 'ieee-be');
fclose(y_id);
x_id = fopen(x_file_path, 'w');
fwrite(x_id, x, 'integer*4', 'ieee-be');
fclose(y_id);
phi_id = fopen(phi_file_path, 'w');
fwrite(phi_id, Phi2, 'integer*4', 'ieee-be');
fclose(y_id);


% use following technique to print hexadecimal string.
% fprintf('%08X\n', typecast(y(1:10), 'uint32'))
