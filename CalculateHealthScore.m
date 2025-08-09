function healthScore = CalculateHealthScore(data)
    % Parameters
    maxRPM = 15000;             % Max safe RPM
    highLoadThreshold = 0.95;   % Throttle threshold for high load
    maxOilTemp = 110;           % Max safe oil temp (°C)
    maxCoolantTemp = 100;       % Max safe coolant temp (°C)
    minDuration_s = 10;          % Min continuous breach duration in seconds for RPM, throttle, gearshift
    tempMinDuration_s = 1;      % Min continuous breach duration for oil/coolant temp breaches

    gearShiftPenaltyPercent = 0.80; % 80% tolerance for gearshift RPM delta penalty

    % Penalties per event
    penaltyRPM = 0.02;        % penalty per RPM breach event
    penaltyHighLoad = 0.02;   % penalty per high load event
    penaltyGearShift = 0.001;  % penalty per rough gear shift event
    penaltyOilTemp = 0.01;    % penalty per oil temp breach event
    penaltyCoolantTemp = 0.01;% penalty per coolant temp breach event

    % Time and dt vector
    time = data.Time; % assume already cumulative seconds
    dt = [diff(time); mean(diff(time))]; % time step vector
    laps = data.LapNumber;

    % Helper function to count breach events with min duration (customizable)
    function [numEvents, lapWithMost] = countBreachEvents(conditionVec, minDur)
        diffC = diff([0; conditionVec; 0]);
        startIdx = find(diffC == 1);
        endIdx = find(diffC == -1) - 1;
        durations = arrayfun(@(s,e) sum(dt(s:e)), startIdx, endIdx);
        longEvents = durations >= minDur;
        numEvents = sum(longEvents);
        if numEvents > 0
            eventLaps = arrayfun(@(s,e) mode(laps(s:e)), startIdx(longEvents), endIdx(longEvents));
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
    throttleBreachRaw = data.Throttle > highLoadThreshold;
    oilTempBreach = data.OilTemp > maxOilTemp;
    coolantTempBreach = data.CoolantTemp > maxCoolantTemp;

    % Count events & laps
    [numRPM, lapRPM] = countBreachEvents(rpmBreach, minDuration_s);
    [numHighLoad, lapHighLoad] = countBreachEvents(throttleBreachRaw, minDuration_s);
    [numOil, lapOil] = countBreachEvents(oilTempBreach, tempMinDuration_s);
    [numCool, lapCool] = countBreachEvents(coolantTempBreach, tempMinDuration_s);

    % Gear shift penalty (unchanged)
    gearChanges = find(diff(data.nGear) ~= 0);
    if isempty(gearChanges)
        numGearShiftPenalties = 0;
    else
        rpmDeltas = abs(diff(data.RPM(gearChanges)));
        avgDeltaRPM = mean(rpmDeltas);
        roughShifts = abs(rpmDeltas - avgDeltaRPM) > (gearShiftPenaltyPercent * avgDeltaRPM);
        numGearShiftPenalties = sum(roughShifts);
    end

    % Total penalty
    totalPenalty = penaltyRPM*numRPM + penaltyHighLoad*numHighLoad + penaltyOilTemp*numOil + penaltyCoolantTemp*numCool + penaltyGearShift*numGearShiftPenalties;

    % Clamp and scale health score
    healthScore = max(0, 100 - totalPenalty);

    % Print summary
    fprintf('PU Health Score: %.2f / 100\n\n', healthScore);
    fprintf('RPM breach events (> %d s): %d', minDuration_s, numRPM);
    if ~isnan(lapRPM), fprintf(' | Most in lap %d\n', lapRPM); else fprintf('\n'); end
    fprintf('High load events (> %d s): %d', minDuration_s, numHighLoad);
    if ~isnan(lapHighLoad), fprintf(' | Most in lap %d\n', lapHighLoad); else fprintf('\n'); end
    fprintf('Oil Temp breach events (> %d s): %d', tempMinDuration_s, numOil);
    if ~isnan(lapOil), fprintf(' | Most in lap %d\n', lapOil); else fprintf('\n'); end
    fprintf('Coolant Temp breach events (> %d s): %d', tempMinDuration_s, numCool);
    if ~isnan(lapCool), fprintf(' | Most in lap %d\n', lapCool); else fprintf('\n'); end
    fprintf('Rough gear shift penalty events: %d\n', numGearShiftPenalties);

end