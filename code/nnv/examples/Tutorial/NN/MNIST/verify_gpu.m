%% Robustness verification of a NN (L infinity adversarial attack)
%  if f(x) = y, then forall x' in X s.t. ||x - x'||_{\infty} <= eps,
%  then f(x') = y = f(x)

% Load network 
mnist_model = load('mnist_model.mat');

% Create NNV model
net = matlab2nnv(mnist_model.net);
net = net.params2gpu;

% Load data (no download necessary)
digitDatasetPath = fullfile(matlabroot,'toolbox','nnet','nndemos', ...
    'nndatasets','DigitDataset');
% Images
imds = imageDatastore(digitDatasetPath, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');

% Load one image in dataset
[img, fileInfo] = readimage(imds,10);
target = single(fileInfo.Label); % label = 0 (index 1 for our network)
img = gpuArray(single(img)); % change precision

% Visualize image;
figure;
imshow(img);

% Create input set

% One way to define it is using original image +- disturbance (L_inf epsilon)
ones_ = gpuArray(ones(size(img), 'single'));
disturbance = 1 .* ones_; % one pixel value (images are not normalized, they get normalized in the ImageInputLayer)
I = ImageStar(img, -disturbance, disturbance);

% Can also define it with just lower and upper bounds
I2 = ImageStar(img-disturbance, img+disturbance);

% However, we need to ensure the values are within the valid range for pixels ([0 255])
lb_min = zeros(size(img)); % minimum allowed values for lower bound is 0
ub_max = 255*ones(size(img)); % maximum allowed values for upper bound is 255
lb_clip = max((img-disturbance),lb_min);
ub_clip = min((img+disturbance), ub_max);
IS = ImageStar(lb_clip, ub_clip); % this is the input set we will use


% Let's evaluate the image and the lower and upper bounds to ensure these
% are correctly classified

% Evaluate lower and upper bounds
LB_outputs = net.evaluate(lb_clip);
[~, LB_Pred] = max(LB_outputs); % (expected: yPred = target)
UB_outputs = net.evaluate(ub_clip);
[~, UB_Pred] = max(UB_outputs); % (expected: yPred = target)
% Evaluate input image
Y_outputs = net.evaluate(img); 
[~, yPred] = max(Y_outputs); % (expected: yPred = target)

% Now, we can do the verification process of this image w/ L_inf attack

% The easiest way to do it is using the verify_robustness function

% First, we need to define the reachability options
reachOptions = struct; % initialize
reachOptions.reachMethod = 'approx-star'; % using approxiate method

% Verification
t = tic;
res_approx = net.verify_robustness(IS, reachOptions, target);

if res_approx == 1
    disp("Neural network is verified to be robust!")
else
    disp("Unknown result")
end

toc(t);


%% Let's visualize the ranges for every possible output

% Get output reachable set
R = net.reachSet{end};

% Get (overapproximate) ranges for each output index
[lb_out, ub_out] = R.getRanges;
lb_out = squeeze(lb_out);
ub_out = squeeze(ub_out);

% Get middle point for each output and range sizes
mid_range = (lb_out + ub_out)/2;
range_size = ub_out - mid_range;

% Label for x-axis
x = [0 1 2 3 4 5 6 7 8 9];

% Visualize set ranges and evaluation points
figure;
errorbar(x, mid_range, range_size, '.');
hold on;
xlim([-0.5 9.5]);
scatter(x,Y_outputs, 'x', 'MarkerEdgeColor', 'r');
