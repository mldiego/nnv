%% Example of reachability for a randomly generated neural network

% Load the network (parameters)
load('../NN/compareReachability/NeuralNetwork7_3.mat');

% Create NNV model
n = length(b);
Layers = cell(n,1);
% hidden layers are all ReLUs
for i=1:n - 1
    bi = cell2mat(b(i));
    Wi = cell2mat(W(i));
    Li = LayerS(Wi, bi, 'poslin');
    Layers{i} = Li;
end
% output layer is linear
bn = cell2mat(b(n));
Wn = cell2mat(W(n));
Ln = LayerS(Wn, bn, 'purelin');
Layers{end} = Ln;
% Create NN model
F = NN(Layers);

% Define input set for the network
lb = [-1; -1 ; -1];
ub = [1; 1; 1];
I = Star(lb, ub);

% select option for reachability algorithm
reachOptions = struct; % initialize
reachOptions.reachMethod = 'exact-star'; % reachability method

% Comute reachability (exact)
te = tic;
Re = F.reach(I, reachOptions); % exact reach set using stars
te = toc(te);

% generate some input to test the output (evaluate network)
e = 0.2;
x = [];
y = [];
for x1 = lb(1):e:ub(1)
    for x2 = lb(2):e:ub(2)
        for x3=lb(3):e:ub(3)
            xi = [x1; x2; x3];
            yi = F.evaluate(xi);
            x = [x, xi];
            y = [y, yi];
        end
    end
end


%% Visualize results

monocolor = false;

% Plot exact and approx sets 
fig = figure;
hold on;
if monocolor
    Star.plots(Re,'b'); % if monocolor, plot all exact sets in cyan
else
    plot_color = ['r', 'g', 'b', 'm', 'y'];
    k = 1;
    for i = 1:length(Re)
        Star.plot(Re(i), plot_color(k))
        hold on;
        k = k+1;
        if k > length(plot_color)
            k = 1;
        end
    end
end

% Plot some of the evaluated inputs
plot(y(1, :), y(2, :), '.', 'Color', 'k');

% Evaluate upper, lower bounds
y1 = F.evaluate(lb);
y2 = F.evaluate(ub);
y3 = F.evaluate((lb+ub)/2);

% Plot upper and lower bound results
plot(y1(1,:), y1(2,:), 'x', 'Color', 'k');
hold on;
plot(y2(1,:), y2(2,:), 'x', 'Color', 'k');
hold on;
plot(y3(1,:), y3(2,:), 'x', 'Color', 'k');
rectangle('Position',[-50,10,30,15],'FaceColor',[1 0 0])

% Save figure
saveas(fig,'exactSets.png');

% Figure with convex hull
fig = figure;
convexHull = Star.get_convex_hull(Re);
convexHull.plot('color','k');
hold on;
plot_color = ['r', 'g', 'b', 'm', 'y'];
k = 1;
for i = 1:length(Re)
    Star.plot(Re(i), plot_color(k))
    hold on;
    k = k+1;
    if k > length(plot_color)
        k = 1;
    end
end
rectangle('Position',[-50,10,30,15],'FaceColor',[1 0 0])


% Save figure
saveas(fig,'exactSetsConvexHull.png');

