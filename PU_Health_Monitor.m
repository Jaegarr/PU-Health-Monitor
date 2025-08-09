% Load telemetry CSV for one driver
data = readtable('C:\Users\berke\OneDrive\Masaüstü\GitHub\PU-Health-Monitor\ANT_Bahrain_2025_Race_Data.csv');

% Extract throttle and cumulative time vector (already in seconds)
throttle = data.Throttle;
time = data.CumulativeTime_s;  % Use cumulative time in seconds directly

n = length(throttle);

% Generate synthetic Oil Temp
oilTemp = 100 + cumsum(0.05*randn(n,1)); % Random walk around 100
oilTemp = smoothdata(oilTemp, 'movmean', 50);

% Add spikes on high throttle zones
highThrottleIdx = throttle > 0.95;
oilTemp(highThrottleIdx) = oilTemp(highThrottleIdx) + 5*rand(sum(highThrottleIdx),1);

% Generate synthetic Coolant Temp (smoother)
coolantTemp = 90 + 0.5*sin(linspace(0,10*pi,n))' + 0.2*randn(n,1);
coolantTemp = smoothdata(coolantTemp, 'movmean', 100);

% Plot for visualization using tiled layout
figure;
tl = tiledlayout(2,1,'Padding','compact','TileSpacing','compact');

% Engine RPM subplot
nexttile;
plot(time, data.RPM, 'b');
xlabel('Time (s)');
ylabel('RPM');
title('Engine RPM');
grid on;

% Oil Temp and Coolant Temp subplot
nexttile;
plot(time, oilTemp, 'r', 'DisplayName', 'Oil Temp (°C)');
hold on;
plot(time, coolantTemp, 'g', 'DisplayName', 'Coolant Temp (°C)');
xlabel('Time (s)');
ylabel('Temperature (°C)');
title('Oil & Coolant Temperatures');
legend('Location','best');
grid on;

% Add overall title
title(tl, 'Telemetry + Synthetic Subsystem Data');

% --- Thresholds (tweak as needed) ---
maxRPM = 15000;            % Max safe RPM limit
highLoadThreshold = 0.95;   % Throttle > 95% considered high load
maxOilTemp = 110;          % Max safe oil temp (°C)
maxCoolantTemp = 100;      % Max safe coolant temp (°C)

% --- Time vector (seconds) ---
time = data.CumulativeTime_s;
dt = [diff(time); mean(diff(time))]; % approximate time step vector

% --- Breach conditions (logical vectors) ---
rpmBreach = data.RPM > maxRPM;
highLoad = throttle > highLoadThreshold;
oilTempBreach = oilTemp > maxOilTemp;
coolantTempBreach = coolantTemp > maxCoolantTemp;

% --- Calculate breach durations (seconds) ---
rpmBreachDur = sum(dt(rpmBreach));
highLoadDur = sum(dt(highLoad));
oilTempBreachDur = sum(dt(oilTempBreach));
coolantTempBreachDur = sum(dt(coolantTempBreach));

% --- Penalty weights ---
penaltyRPM = 0.02;        % per second RPM breach penalty
penaltyHighLoad = 0.01;   % per second high load penalty
penaltyOilTemp = 0.03;    % per second oil temp breach penalty
penaltyCoolantTemp = 0.02;% per second coolant temp breach penalty

% --- Calculate total penalty ---
totalPenalty = ...
    penaltyRPM * rpmBreachDur + ...
    penaltyHighLoad * highLoadDur + ...
    penaltyOilTemp * oilTempBreachDur + ...
    penaltyCoolantTemp * coolantTempBreachDur;

% --- Compute health score ---
healthScore = 100 - totalPenalty;
healthScore = max(min(healthScore,100),0); % clamp 0 to 100

% --- Display results ---
fprintf('Health Score: %.2f / 100\n', healthScore);
fprintf('RPM breach duration: %.1f s\n', rpmBreachDur);
fprintf('High load duration: %.1f s\n', highLoadDur);
fprintf('Oil temp breach duration: %.1f s\n', oilTempBreachDur);
fprintf('Coolant temp breach duration: %.1f s\n', coolantTempBreachDur);