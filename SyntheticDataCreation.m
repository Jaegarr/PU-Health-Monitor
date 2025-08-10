raceNum = 1:14;
drivers = {'ANT', 'RUS'};
inputFolder = 'C:\Users\berke\OneDrive\Masaüstü\GitHub\PU-Health-Monitor\Race Data';
outputFolder = 'C:\Users\berke\OneDrive\Masaüstü\GitHub\PU-Health-Monitor\Synthetic Race Data';
for r = raceNum
    for d = 1:length(drivers)
        driver = drivers{d};
        File = fullfile(inputFolder, sprintf('%s_R%d_2025_Race_Data.csv', driver, r));
        data = readtable(File);
        uniqueLaps = unique(data.LapNumber);
        cumulativeTime_s = zeros(height(data),1);
        timeOffset = 0;
        for iLap = 1:length(uniqueLaps)
            lapIdx = data.LapNumber == uniqueLaps(iLap);
            lapTimes = data.Time(lapIdx);          % Already numeric seconds
            lapTimes = lapTimes - lapTimes(1);     % Zero lap time start
            cumulativeTime_s(lapIdx) = lapTimes + timeOffset;
            timeOffset = cumulativeTime_s(find(lapIdx,1,'last'));
        end 
        data.CumulativeTime_s = cumulativeTime_s;
        n = height(data);
        throttle = data.Throttle;
        oilTemp = 100 + cumsum(0.05*randn(n,1));
        oilTemp = smoothdata(oilTemp, 'movmean', 50);
        highThrottleIdx = throttle > 0.9;
        oilTemp(highThrottleIdx) = oilTemp(highThrottleIdx) + 5*rand(sum(highThrottleIdx),1);
        coolantTemp = 90 + 0.5*sin(linspace(0,10*pi,n))' + 0.2*randn(n,1);
        coolantTemp = smoothdata(coolantTemp, 'movmean', 100);
        data.OilTemp = oilTemp;
        data.CoolantTemp = coolantTemp;
        outFile = fullfile(outputFolder, sprintf('%s_R%d_2025_Race_Data_Synthetic.csv', driver, r));
        writetable(data, outFile);
        fprintf('Saved synthetic data for %s race %d to %s\n', driver, r, outFile);
    end
end