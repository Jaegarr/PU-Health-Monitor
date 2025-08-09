function totalPenalty = CalculateHealthScore(data)
    % Parameters and thresholds
    maxRPM = 15000;
    highLoadThreshold = 0.95;
    maxOilTemp = 110;
    maxCoolantTemp = 100;
    minDuration_s = 5;
    tempMinDuration_s = 1;
    gearShiftPenaltyPercent = 0.80;

    penaltyRPM = 0.01;
    penaltyHighLoad = 0.01;
    penaltyGearShift = 0.005;
    penaltyOilTemp = 0.005;
    penaltyCoolantTemp = 0.005;

    time = data.Time;
    dt = [diff(time); mean(diff(time))];
    laps = data.LapNumber;

    % Helper function to count breach events with min duration
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

    % Count events
    [numRPM, ~] = countBreachEvents(rpmBreach, minDuration_s);
    [numHighLoad, ~] = countBreachEvents(throttleBreachRaw, minDuration_s);
    [numOil, ~] = countBreachEvents(oilTempBreach, tempMinDuration_s);
    [numCool, ~] = countBreachEvents(coolantTempBreach, tempMinDuration_s);

    % Gear shift penalty
    gearChanges = find(diff(data.nGear) ~= 0);
    if isempty(gearChanges)
        numGearShiftPenalties = 0;
    else
        rpmDeltas = abs(diff(data.RPM(gearChanges)));
        avgDeltaRPM = mean(rpmDeltas);
        roughShifts = abs(rpmDeltas - avgDeltaRPM) > (gearShiftPenaltyPercent * avgDeltaRPM);
        numGearShiftPenalties = sum(roughShifts);
    end

    % Total penalty calculation
    totalPenalty = penaltyRPM*numRPM + penaltyHighLoad*numHighLoad + penaltyOilTemp*numOil + penaltyCoolantTemp*numCool + penaltyGearShift*numGearShiftPenalties;
end