clear;
clc;
close all;

%% load data
load('ocv_final.mat');
time_ocv = time;
load('pulse_1_c_5.mat');
load('rc1_cf_params.mat');

%% voltage limitations
v_max = 4.4;                                    % cut-over voltage
v_min = 3.0;                                    % cut-off voltage

%% resample ocv and soc
t1 = time_ocv(1);
t2 = time_ocv(end);
dt = 1;                                         % sample time
t = (t1:dt:t2) - t1;

ocv = interp1(time_ocv, ocv, t1:dt:t2);
soc = interp1(time_ocv, soc, t1:dt:t2);

s = length(time);

%% variables
Q = 16.8;
eta = 1.0;                                  % coulombic efficiency

n = 0;                                      % number of rc links
flag = 1;

%% compute soc
ind_init = interp1(soc, 1:length(soc), 0.5168, 'nearest');
v_t(1) = ocv(ind_init);
z0 = soc(ind_init);
z = z0 - dt/(Q*3600)*eta*cumsum(I(1:end));

% manual fit
p = 5;
r0 = r0_cf(p);

%% compute terminal voltage
for j = 1:n
    f(j) = exp(-dt/(r(j)*c(j)));
end
for k = 1:s-1
    if flag == 1
        ind = interp1(soc, 1:length(soc), z(k), 'nearest');
        v_t(k+1) = ocv(ind) - I(k).*r0;
        if v_t(k) < v_min
            fprintf('Reached lower voltage limit.');
            flag = 0;
        end
        if v_t(k) > v_max
            fprintf('Reached upper voltage limit.');
            flag = 0;
        end 
    end
end

%% compute rms error
v_t = reshape(v_t, size(V_batt_time));
rmse = 1000*sqrt(mean((V_batt_time - v_t).^2))     % [mV]

%% plot
figure(1);
hold on;
plot(time, v_t, 'r', 'LineWidth', 2)
hold on;
plot(time, V_batt_time, 'b--', 'LineWidth', 2)
xlabel('Time [s]')
ylabel('Terminal Voltage [V]')
title('RC')
legend('RC', 'Physical', 'location', 'southeast')