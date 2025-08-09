% Load telemetry CSV for one driver
data = readtable('C:\Users\berke\OneDrive\Masaüstü\GitHub\PU-Health-Monitor\ANT_Bahrain_2025_Race_Data.csv');

% Extract throttle and time vector
throttle = data.Throttle;
% Convert cell array of time strings to duration
timeDur = duration(data.Time, 'InputFormat', 'hh:mm:ss.SSS');

% Convert duration to seconds numeric vector
time = seconds(timeDur);

% Normalize time to start at zero
time = time - time(1);

n = length(throttle);

% Generate synthetic Oil Temp
oilTemp = 100 + cumsum(0.05*randn(n,1)); % Random walk around 100
oilTemp = smoothdata(oilTemp, 'movmean', 50);

% Add spikes on high throttle zones
highThrottleIdx = throttle > 0.9;
oilTemp(highThrottleIdx) = oilTemp(highThrottleIdx) + 5*rand(sum(highThrottleIdx),1);

% Generate synthetic Coolant Temp (smoother)
coolantTemp = 90 + 0.5*sin(linspace(0,10*pi,n))' + 0.2*randn(n,1);
coolantTemp = smoothdata(coolantTemp, 'movmean', 100);

% Generate synthetic Battery SOC (oscillates, dips on high throttle)
batterySOC = 70 + 20*sin(linspace(0,4*pi,n))' - 10*highThrottleIdx;
batterySOC = max(min(batterySOC,95),20); % Clamp between 20 and 95%

% Plot for visualization
figure;
plot(time, data.RPM, 'b', 'DisplayName', 'Engine RPM'); hold on;
plot(time, oilTemp, 'r', 'DisplayName', 'Oil Temp (°C)');
plot(time, coolantTemp, 'g', 'DisplayName', 'Coolant Temp (°C)');
plot(time, batterySOC, 'k', 'DisplayName', 'Battery SOC (%)');
xlabel('Time (s)');
legend;
title('Telemetry + Synthetic Subsystem Data');
grid on;