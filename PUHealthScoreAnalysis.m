clear; clc;

raceNums = 1:14;
drivers = {'ANT', 'RUS'};
inputFolder = 'C:\Users\berke\OneDrive\Masaüstü\GitHub\PU-Health-Monitor\Synthetic Race Data';

% Initialize containers
allLapScores = struct();

for r = raceNums
    fprintf('Processing Race %d...\n', r);
    for d = 1:length(drivers)
        driver = drivers{d};
        filename = fullfile(inputFolder, sprintf('%s_R%d_2025_Race_Data_Synthetic.csv', driver, r));
        data = readtable(filename);

        uniqueLaps = unique(data.LapNumber);
        lapScores = zeros(length(uniqueLaps),1);

        for iLap = 1:length(uniqueLaps)
            lapData = data(data.LapNumber == uniqueLaps(iLap), :);
            lapScores(iLap) = CalculateHealthScore(lapData);
        end

        allLapScores.(driver).(['Race' num2str(r)]) = lapScores;
    end
end

% Plot lap-by-lap comparison for a selected race (example: race 1)
raceToPlot = 1;
figure;
hold on;
laps = 1:length(allLapScores.ANT.(['Race' num2str(raceToPlot)]));
plot(laps, allLapScores.ANT.(['Race' num2str(raceToPlot)]), '-o', 'DisplayName', 'ANT');
plot(laps, allLapScores.RUS.(['Race' num2str(raceToPlot)]), '-x', 'DisplayName', 'RUS');
xlabel('Lap Number');
ylabel('Health Score');
title(sprintf('Lap-by-Lap Health Score Comparison - Race %d', raceToPlot));
legend;
grid on;

% Calculate overall race health (mean lap health)
overallHealthANT = zeros(length(raceNums),1);
overallHealthRUS = zeros(length(raceNums),1);

for r = raceNums
    overallHealthANT(r) = mean(allLapScores.ANT.(['Race' num2str(r)]));
    overallHealthRUS(r) = mean(allLapScores.RUS.(['Race' num2str(r)]));
end

% Plot overall race-by-race health comparison
figure;
plot(raceNums, overallHealthANT, '-o', 'DisplayName', 'ANT');
hold on;
plot(raceNums, overallHealthRUS, '-x', 'DisplayName', 'RUS');
xlabel('Race Number');
ylabel('Average Health Score');
title('Race-by-Race Overall Health Score Comparison');
legend;
grid on;