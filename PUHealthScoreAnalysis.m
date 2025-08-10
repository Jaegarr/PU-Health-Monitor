clear; clc;

% =============================
% SETTINGS
% =============================
Data = 'C:\Users\berke\OneDrive\Masaüstü\GitHub\PU-Health-Monitor\Synthetic Race Data';
Drivers = {'ANT', 'RUS'}; 
RaceNames = {'Australia', 'China', 'Japan', 'Bahrain', 'SaudiArabia', 'Miami', 'EmiliaRomagna', 'Monaco', 'Spain', 'Canada', 'Austria', 'GreatBritain', 'Belgium', 'Hungary'};
raceNum = 1:length(RaceNames);
% ICE change (reset health to 100 at these races, assumed the gearbox has changed as well
engineChanges.ANT = {'Miami', 'Canada', 'GreatBritain','Belgium'};
engineChanges.RUS = {'Miami', 'Canada', 'GreatBritain'};
lapHealth = struct();
startHealth = struct('ANT', 100, 'RUS', 100);
for r = raceNum
    raceName = RaceNames{r};
    for d = 1:length(Drivers)
        driver = Drivers{d};
        if ismember(raceName, engineChanges.(driver))
            startHealth.(driver) = 100;
        end

        filename = fullfile(Data, sprintf('%s_R%d_2025_Race_Data_Synthetic.csv', driver, r));
        data = readtable(filename);
        penalties = arrayfun(@(lap) CalculateHealthScore(data(data.LapNumber == lap, :)), unique(data.LapNumber));
        breachCount.(driver)(r) = sum(penalties > 0);
        % Lap-by-lap health calculation
        uniqueLaps = unique(data.LapNumber);
        healthLaps = zeros(length(uniqueLaps), 1);
        currentHealth = startHealth.(driver);
        for i = 1:length(uniqueLaps)
            lapData = data(data.LapNumber == uniqueLaps(i), :);
            lapPenalty = CalculateHealthScore(lapData);
            currentHealth = max(0, currentHealth - lapPenalty);
            healthLaps(i) = currentHealth;
        end
        startHealth.(driver) = healthLaps(end);
        lapHealth.(driver).(raceName) = healthLaps;
    end
end
raceToPlot = 'Australia';
lapsANT = length(lapHealth.ANT.(raceToPlot));
lapsRUS = length(lapHealth.RUS.(raceToPlot));
figure('Name', ['Lap-by-Lap Health - ' raceToPlot]);
hold on;
plot(1:lapsANT, lapHealth.ANT.(raceToPlot), '-o', 'LineWidth', 2, 'DisplayName', 'ANT', 'Color', 'b');
plot(1:lapsRUS, lapHealth.RUS.(raceToPlot), '-x', 'LineWidth', 2, 'DisplayName', 'RUS', 'Color', 'k');
xlabel('Lap Number');
ylabel('Health Score');
title(['Lap-by-Lap Health Comparison - ' raceToPlot]);
legend('Location', 'best');
grid on;
hold off;
finalHealthANT = zeros(length(raceNum), 1);
finalHealthRUS = zeros(length(raceNum), 1);
for r = raceNum
    finalHealthANT(r) = lapHealth.ANT.(RaceNames{r})(end);
    finalHealthRUS(r) = lapHealth.RUS.(RaceNames{r})(end);
end
figure('Name', 'Season Health Progression');
hold on;
plot(raceNum, finalHealthANT, '-o', 'LineWidth', 2, 'DisplayName', 'ANT', 'Color', 'b');
plot(raceNum, finalHealthRUS, '-x', 'LineWidth', 2, 'DisplayName', 'RUS', 'Color', 'k');
xlabel('Race');
ylabel('Health Score');
title('Overall Season Health Progression');
xticks(raceNum);
xticklabels(RaceNames);
xtickangle(45);
legend('Location', 'best');
grid on;
hold off;
figure('Name', 'Breach Count per Race');
bar(raceNum - 0.15, breachCount.ANT, 0.3, 'b', 'DisplayName', 'ANT');
hold on;
bar(raceNum + 0.15, breachCount.RUS, 0.3, 'k', 'DisplayName', 'RUS');
xlabel('Race');
ylabel('Number of Breaches');
title('Breaches per Race');
xticks(raceNum);
xticklabels(RaceNames);
xtickangle(45);
legend('Location', 'best');
grid on;
hold off;