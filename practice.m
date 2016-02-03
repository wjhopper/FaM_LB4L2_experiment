function data = practice(data, first, inputHandler, window, constants)

for i = 1:2
    studyRows = strcmp(data.practice,'S') & data.round == i;
    testRows = strcmp(data.practice,'T') & data.round == i;
    if strcmp('S', first)
        countdown('It''s time to restudy pairs from the last list', constants.practiceCountdown,...
            constants.countdownSpeed,  window, constants);
        data.onset(studyRows) = study(data(studyRows, {'cue','target'}), window, constants);
        countdown('Time for a practice test on pairs from the last list', constants.practiceCountdown,...
            constants.countdownSpeed,  window, constants);    
        [onset, response, firstPress, lastPress] = testing(data(testRows,:), inputHandler, window, constants);
    else
        countdown('Time for a practice test on pairs from the last list', constants.practiceCountdown,...
            constants.countdownSpeed,  window, constants);
        [onset, response, firstPress, lastPress] = testing(data(testRows,:), inputHandler, window, constants);
        countdown('It''s time to restudy pairs from the last list', constants.practiceCountdown,...
            constants.countdownSpeed,  window, constants);
        data.onset(studyRows) = study(data(studyRows, {'cue','target'}), window, constants);
    end
    data.onset(testRows) = onset;
    data.response(testRows) = response;
    data.firstPress(testRows) = firstPress;
    data.lastPress(testRows) = lastPress;
end
end