% @name_file:   analyze_stat.sh
% @author:      Giovanni Toso
% @last_update: 2014.02.24
% --
% @brief_description: process the stat file and create plots

%% Reset the workspace

clc;
clear all;
close all;
format long g;

%% Variables %%

SECONDS_MEAN = 60;
SMOOTH_FACTOR = 5;
BASE_FOLDER = '/home/giovanni/underwater/papers2c/log_files/';
FOLDER_NAME = 'gumstix_high traffic/';
DESTINATION_FOLDER = [BASE_FOLDER FOLDER_NAME];
NUM_SAMPLES = 60; % stop the x axis after n samples.
SAMPLING_PERIOD = 1; % in seconds;
SMOOTH = 0;

%% Preprocess the Data %%

system(['./profiler_pre_processing.sh ' DESTINATION_FOLDER]);

%% Load Data %%

USR = importdata([DESTINATION_FOLDER '/USR_stat_clean.log']);
APP = importdata([DESTINATION_FOLDER '/APP_stat_clean.log']);
NET = importdata([DESTINATION_FOLDER '/NET_stat_clean.log']);
MAC = importdata([DESTINATION_FOLDER '/MAC_stat_clean.log']);
NSC = importdata([DESTINATION_FOLDER '/NSC_stat_clean.log']);

tmp_min_start = min([USR(1, 1), ...
    APP(1, 1), ...
    NET(1, 1), ...
    MAC(1, 1), ...
    NSC(1, 1)]);

% sync the start of the log files
tmp_diff = USR(1, 1) - tmp_min_start;
for j = 1 : tmp_diff
    tmp_vector(j, :) = [tmp_min_start + j - 1, 0 ,0];
end
if (exist('tmp_vector') == 1)
    USR = [tmp_vector;USR];
end
clear tmp_diff;
clear tmp_vector;
clear j;

tmp_diff = APP(1, 1) - tmp_min_start;
for j = 1 : tmp_diff
    tmp_vector(j, :) = [tmp_min_start + j - 1, 0 ,0];
end
if (exist('tmp_vector') == 1)
    APP = [tmp_vector;APP];
end
clear tmp_diff;
clear tmp_vector;
clear j;

tmp_diff = NET(1, 1) - tmp_min_start;
for j = 1 : tmp_diff
    tmp_vector(j, :) = [tmp_min_start + j - 1, 0 ,0];
end
if (exist('tmp_vector') == 1)
    NET = [tmp_vector;NET];
end
clear tmp_diff;
clear tmp_vector;
clear j;

tmp_diff = MAC(1, 1) - tmp_min_start;
for j = 1 : tmp_diff
    tmp_vector(j, :) = [tmp_min_start + j - 1, 0 ,0];
end
if (exist('tmp_vector') == 1)
    MAC = [tmp_vector;MAC];
end
clear tmp_diff;
clear tmp_vector;
clear j;

tmp_diff = NSC(1, 1) - tmp_min_start;
for j = 1 : tmp_diff
    tmp_vector(j, :) = [tmp_min_start + j - 1, 0 ,0];
end
if (exist('tmp_vector') == 1)
    NSC = [tmp_vector;NSC];
end
clear tmp_diff;
clear tmp_vector;
clear j;

clear tmp_min_start;
%% Mean and smooth Data %%

for i = 1 : size(USR, 1)
    if ((i) * 60 + 1 <= size(USR, 1))
        tmp_vector = USR(((i - 1) * 60 + 1):((i) * 60 + 1), 2);
        USR_mean(i, 1) = mean(tmp_vector);
        tmp_vector = USR(((i - 1) * 60 + 1):((i) * 60 + 1), 3);
        USR_mean(i, 2) = mean(tmp_vector);
    end
end
if (SMOOTH == 1)
    USR_mean_smooth(:, 1) = smooth(USR_mean(:, 1), SMOOTH_FACTOR);
    USR_mean_smooth(:, 2) = smooth(USR_mean(:, 2), SMOOTH_FACTOR);
else
    USR_mean_smooth(:, 1) = USR_mean(:, 1);
    USR_mean_smooth(:, 2) = USR_mean(:, 2);
end
clear i;
clear tmp_vector;

for i = 1 : size(APP, 1)
    if ((i) * SECONDS_MEAN + 1 <= size(APP, 1))
        tmp_vector = APP(((i - 1) * SECONDS_MEAN + 1):((i) * SECONDS_MEAN + 1), 2);
        APP_mean(i, 1) = mean(tmp_vector);
        tmp_vector = APP(((i - 1) * SECONDS_MEAN + 1):((i) * SECONDS_MEAN + 1), 3);
        APP_mean(i, 2) = mean(tmp_vector);
    end
end
if (SMOOTH == 1)
    APP_mean_smooth(:, 1) = smooth(APP_mean(:, 1), SMOOTH_FACTOR);
    APP_mean_smooth(:, 2) = smooth(APP_mean(:, 2), SMOOTH_FACTOR);
else
    APP_mean_smooth(:, 1) = APP_mean(:, 1);
    APP_mean_smooth(:, 2) = APP_mean(:, 2);
end
clear i;
clear tmp_vector;

for i = 1 : size(NET, 1)
    if ((i) * SECONDS_MEAN + 1 <= size(NET, 1))
        tmp_vector = NET(((i - 1) * SECONDS_MEAN + 1):((i) * SECONDS_MEAN + 1), 2);
        NET_mean(i, 1) = mean(tmp_vector);
        tmp_vector = NET(((i - 1) * SECONDS_MEAN + 1):((i) * SECONDS_MEAN + 1), 3);
        NET_mean(i, 2) = mean(tmp_vector);
    end
end
if (SMOOTH == 1)
    NET_mean_smooth(:, 1) = smooth(NET_mean(:, 1), SMOOTH_FACTOR);
    NET_mean_smooth(:, 2) = smooth(NET_mean(:, 2), SMOOTH_FACTOR);
else
    NET_mean_smooth(:, 1) = NET_mean(:, 1);
    NET_mean_smooth(:, 2) = NET_mean(:, 2);
end
clear i;
clear tmp_vector;

for i = 1 : size(MAC, 1)
    if ((i) * SECONDS_MEAN + 1 <= size(MAC, 1))
        tmp_vector = MAC(((i - 1) * SECONDS_MEAN + 1):((i) * SECONDS_MEAN + 1), 2);
        MAC_mean(i, 1) = mean(tmp_vector);
        tmp_vector = MAC(((i - 1) * SECONDS_MEAN + 1):((i) * SECONDS_MEAN + 1), 3);
        MAC_mean(i, 2) = mean(tmp_vector);
    end
end
if (SMOOTH == 1)
    MAC_mean_smooth(:, 1) = smooth(MAC_mean(:, 1), SMOOTH_FACTOR);
    MAC_mean_smooth(:, 2) = smooth(MAC_mean(:, 2), SMOOTH_FACTOR);
else
    MAC_mean_smooth(:, 1) = MAC_mean(:, 1);
    MAC_mean_smooth(:, 2) = MAC_mean(:, 2);
end
clear i;
clear tmp_vector;

for i = 1 : size(NSC, 1)
    if ((i) * SECONDS_MEAN + 1 <= size(NSC, 1))
        tmp_vector = NSC(((i - 1) * SECONDS_MEAN + 1):((i) * SECONDS_MEAN + 1), 2);
        NSC_mean(i, 1) = mean(tmp_vector);
        tmp_vector = NSC(((i - 1) * SECONDS_MEAN + 1):((i) * SECONDS_MEAN + 1), 3);
        NSC_mean(i, 2) = mean(tmp_vector);
    end
end
if (SMOOTH == 1)
    NSC_mean_smooth(:, 1) = smooth(NSC_mean(:, 1), SMOOTH_FACTOR);
    NSC_mean_smooth(:, 2) = smooth(NSC_mean(:, 2), SMOOTH_FACTOR);
else
    NSC_mean_smooth(:, 1) = NSC_mean(:, 1);
    NSC_mean_smooth(:, 2) = NSC_mean(:, 2);
end
clear i;
clear tmp_vector;

tmp_min_length = min([size(USR_mean_smooth, 1), ...
    size(APP_mean_smooth, 1), ...
    size(NET_mean_smooth, 1), ...
    size(MAC_mean_smooth, 1), ...
    size(NSC_mean_smooth, 1)]);

RAM_data(:,1) = USR_mean_smooth(1:tmp_min_length, 1);
RAM_data(:,2) = APP_mean_smooth(1:tmp_min_length, 1);
RAM_data(:,3) = NET_mean_smooth(1:tmp_min_length, 1);
RAM_data(:,4) = MAC_mean_smooth(1:tmp_min_length, 1);
RAM_data(:,5) = NSC_mean_smooth(1:tmp_min_length, 1);
RAM_data(:,6) = RAM_data(:,1) + ...
    RAM_data(:,2) + ...
    RAM_data(:,3) + ...
    RAM_data(:,4) + ...
    RAM_data(:,5);
RAM_data_peak = max(RAM_data(:,6));

CPU_data(:,1) = USR_mean_smooth(1:tmp_min_length, 2);
CPU_data(:,2) = APP_mean_smooth(1:tmp_min_length, 2);
CPU_data(:,3) = NET_mean_smooth(1:tmp_min_length, 2);
CPU_data(:,4) = MAC_mean_smooth(1:tmp_min_length, 2);
CPU_data(:,5) = NSC_mean_smooth(1:tmp_min_length, 2);
CPU_data(:,6) = CPU_data(:,1) + ...
    CPU_data(:,2) + ...
    CPU_data(:,3) + ...
    CPU_data(:,4) + ...
    CPU_data(:,5);
CPU_data_peak = max(CPU_data(:,6));

clear tmp_min_length;
%% Plot data %%

fsize = 16;
lfsize = 14;

x_legend = 1 : SAMPLING_PERIOD : SAMPLING_PERIOD * NUM_SAMPLES;

figure(1);
clf;
plot(x_legend, RAM_data(1:NUM_SAMPLES, 1), 'md', 'MarkerSize', 8, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Cyan');
hold all;
plot(x_legend, RAM_data(1:NUM_SAMPLES, 2), 'mo', 'MarkerSize', 8, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Green');
hold all;
plot(x_legend, RAM_data(1:NUM_SAMPLES, 3), 'mx', 'MarkerSize', 6, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Blue');
hold all;
plot(x_legend, RAM_data(1:NUM_SAMPLES, 4), 'm^', 'MarkerSize', 6, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Red');
hold all;
plot(x_legend, RAM_data(1:NUM_SAMPLES, 5), 'm*', 'MarkerSize', 6, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Magenta');
hold all;
plot(x_legend, RAM_data(1:NUM_SAMPLES, 6), 'mo', 'MarkerSize', 8, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Black');
hold all;
xlabel('Experiment minute');
ylabel('Ram usage [kilobyte]');
ylim([0 5000]);
grid on;
set(get(gca,'XLabel'),'FontSize', fsize);
set(get(gca,'YLabel'),'FontSize', fsize);
set(gca,'FontName', 'Helvetica');
set(gca,'FontSize', fsize);
legh = legend('USR', 'APP', 'NET', 'MAC', 'NSC', 'TOTAL');
set(legh, 'Location', 'East');
set(legh, 'EdgeColor', [1 1 1]);
set(legh, 'FontSize', lfsize);
print('-depsc', [DESTINATION_FOLDER '/RAM']);
print('-dpng', [DESTINATION_FOLDER '/RAM']);

figure(2);
clf;
plot(x_legend, CPU_data(1:NUM_SAMPLES, 1), 'md', 'MarkerSize', 8, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Cyan');
hold all;
plot(x_legend, CPU_data(1:NUM_SAMPLES, 2), 'mo', 'MarkerSize', 8, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Green');
hold all;
plot(x_legend, CPU_data(1:NUM_SAMPLES, 3), 'mx', 'MarkerSize', 6, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Blue');
hold all;
plot(x_legend, CPU_data(1:NUM_SAMPLES, 4), 'm^', 'MarkerSize', 6, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Red');
hold all;
plot(x_legend, CPU_data(1:NUM_SAMPLES, 5), 'm*', 'MarkerSize', 6, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Magenta');
hold all;
plot(x_legend, CPU_data(1:NUM_SAMPLES, 6), 'mo', 'MarkerSize', 8, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'Black');
hold all;
xlabel('Experiment minute');
ylabel('Cpu usage [percentage]');
ylim([0 4]);
grid on;
set(get(gca,'XLabel'),'FontSize', fsize);
set(get(gca,'YLabel'),'FontSize', fsize);
set(gca,'FontName', 'Helvetica');
set(gca,'FontSize', fsize);
legh = legend('USR', 'APP', 'NET', 'MAC', 'NSC', 'TOTAL');
set(legh, 'Location', 'East');
set(legh, 'EdgeColor', [1 1 1]);
set(legh, 'FontSize', lfsize);
print('-depsc', [DESTINATION_FOLDER '/CPU']);
print('-dpng', [DESTINATION_FOLDER '/CPU']);

close all;
clear legh;
clear fsize;
clear lfsize;