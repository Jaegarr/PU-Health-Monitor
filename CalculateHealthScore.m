function healthScore = calculateHealthScore(data, oilTemp, coolantTemp)
    % Parameters
    maxRPM = 15000;             % Max safe RPM
    highLoadThreshold = 0.95;   % Throttle threshold for high load
    maxOilTemp = 110;           % Max safe oil temp (°C)
    maxCoolantTemp = 100;       % Max safe coolant temp (°C)
    minDuration_s = 5;          % Min continuous breach duration in seconds to count event

    % Penalties per event
    penaltyRPM = 0.01;        % penalty per RPM breach event
    penaltyHighLoad = 0.02;   % penalty per high load event
    penaltyOilTemp = 0.03;    % penalty per oil temp breach event
    penaltyCoolantTemp = 0.01;% penalty per coolant temp breach event

    % Time and dt vector
    time = data.CumulativeTime_s;
    dt = [diff(time); mean(diff(time))]; % time step vector

    % Get laps vector (assumes data.LapNumber exists)
    laps = data.LapNumber;

    % Helper function to detect breach events
    function [numEvents, lapWithMost] = countBreachEvents(conditionVec)
        % Find start and end indices of continuous breach periods
        diffC = diff([0; conditionVec; 0]);
        startIdx = find(diffC == 1);
        endIdx = find(diffC == -1) - 1;

        % Calculate duration of each breach period
        durations = arrayfun(@(s,e) sum(dt(s:e)), startIdx, endIdx);

        % Filter by min duration
        longEvents = durations >= minDuration_s;

        % Count events
        numEvents = sum(longEvents);

        if numEvents > 0
            % Find laps for each long event (mode lap in event segment)
            eventLaps = arrayfun(@(s,e) mode(laps(s:e)), startIdx(longEvents), endIdx(longEvents));
            % Find lap with most events
            uniqueLaps = unique(eventLaps);
            counts = histcounts(eventLaps, [uniqueLaps; max(uniqueLaps)+1]);
            [~, idxMax] = max(counts);
            lapWithMost = uniqueLaps(idxMax);
        else
            lapWithMost = NaN;
        end
    end

    % Calculate breach conditions
    rpmBreach = data.RPM > maxRPM;
    highLoadBreach = data.Throttle > highLoadThreshold;
    oilTempBreach = oilTemp > maxOilTemp;
    coolantTempBreach = coolantTemp > maxCoolantTemp;

    % Count events & find laps with most events
    [numRPM, lapRPM] = countBreachEvents(rpmBreach);
    [numHL, lapHL] = countBreachEvents(highLoadBreach);
    [numOil, lapOil] = countBreachEvents(oilTempBreach);
    [numCool, lapCool] = countBreachEvents(coolantTempBreach);

    % Calculate total penalty
    totalPenalty = penaltyRPM*numRPM + penaltyHighLoad*numHL + penaltyOilTemp*numOil + penaltyCoolantTemp*numCool;

    % Compute health score and clamp
    healthScore = max(0, 100 - totalPenalty);

    % Print summary
    fprintf('PU Health Score: %.2f / 100\n\n', healthScore);

    fprintf('RPM breach events (> %d s): %d', minDuration_s, numRPM);
    if ~isnan(lapRPM), fprintf(' | Most in lap %d\n', lapRPM); else fprintf('\n'); end

    fprintf('High load events (> %d s): %d', minDuration_s, numHL);
    if ~isnan(lapHL), fprintf(' | Most in lap %d\n', lapHL); else fprintf('\n'); end

    fprintf('Oil Temp breach events (> %d s): %d', minDuration_s, numOil);
    if ~isnan(lapOil), fprintf(' | Most in lap %d\n', lapOil); else fprintf('\n'); end

    fprintf('Coolant Temp breach events (> %d s): %d', minDuration_s, numCool);
    if ~isnan(lapCool), fprintf(' | Most in lap %d\n', lapCool); else fprintf('\n'); end

end