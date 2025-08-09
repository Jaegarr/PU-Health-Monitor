raceNums = 1:14;
drivers = {'ANT', 'RUS'}; % Antonelli and Russell
inputFolder = 'C:\Users\berke\OneDrive\Masaüstü\GitHub\PU-Health-Monitor\Race Data';
outputFolder = 'C:\Users\berke\OneDrive\Masaüstü\GitHub\PU-Health-Monitor\Synthetic Race Data';
for r = raceNums
    for d = 1:length(drivers)
        driver = drivers{d};
        % Input file path
        inFile = fullfile(inputFolder, sprintf('%s_R%d_2025_Race_Data.csv', driver, r));
        % Load data
        data = readtable(inFile);
        % Convert lap-reset Time to cumulative time in seconds
        uniqueLaps = unique(data.LapNumber);
        cumulativeTime_s = zeros(height(data),1);
        timeOffset = 0;
        
        for iLap = 1:length(uniqueLaps)
            lapIdx = data.LapNumber == uniqueLaps(iLap);
            lapTimes = seconds(duration(data.Time(lapIdx), 'InputFormat', 'mm:ss.SSS'));
            lapTimes = lapTimes - lapTimes(1); % zero lap time start
            cumulativeTime_s(lapIdx) = lapTimes + timeOffset;
            timeOffset = cumulativeTime_s(find(lapIdx,1,'last'));
        end
        
        data.CumulativeTime_s = cumulativeTime_s;
        
        % Generate synthetic Oil Temp (random walk + throttle spikes)
        n = height(data);
        throttle = data.Throttle;
        oilTemp = 100 + cumsum(0.05*randn(n,1)); % random walk around 100
        oilTemp = smoothdata(oilTemp, 'movmean', 50);
        highThrottleIdx = throttle > 0.9;
        oilTemp(highThrottleIdx) = oilTemp(highThrottleIdx) + 5*rand(sum(highThrottleIdx),1);
        
        % Generate synthetic Coolant Temp (sinusoidal + noise)
        coolantTemp = 90 + 0.5*sin(linspace(0,10*pi,n))' + 0.2*randn(n,1);
        coolantTemp = smoothdata(coolantTemp, 'movmean', 100);
        
        % Append synthetic data columns
        data.OilTemp = oilTemp;
        data.CoolantTemp = coolantTemp;
        
        % Save new CSV with synthetic data
        outFile = fullfile(outputFolder, sprintf('%s_R%d_2025_Race_Data_Synthetic.csv', driver, r));
        writetable(data, outFile);
        
        fprintf('Saved synthetic data for %s race %d to %s\n', driver, r, outFile);
    end
end