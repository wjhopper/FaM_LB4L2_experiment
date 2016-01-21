function data = practice(data, first, inputHandler, window, constants)

for i = 1:2
    studyRows = strcmp(data.practice,'S') & data.pracRound == i;
    testRows = strcmp(data.practice,'T') & data.pracRound == i;
    if strcmp('S', first)
        countdown('Now its time to restudy some pairs from the last list', constants.practiceCountdown,...
            constants.countdownSpeed,  window, constants);
        data.onset(studyRows) = study(data(studyRows, {'cue','target'}), window, constants);
        countdown('It''s time for a practice test on some pairs from the last list', constants.practiceCountdown,...
            constants.countdownSpeed,  window, constants);    
        [onset, response, firstPress, lastPress] = testing(data(testRows,:), inputHandler, window, constants);
    else
        countdown('It''s time for a practice test on some pairs from the last list', constants.practiceCountdown,...
            constants.countdownSpeed,  window, constants);
        [onset, response, firstPress, lastPress] = testing(data(testRows,:), inputHandler, window, constants);
        countdown('Now its time to restudy some pairs from the last list', constants.practiceCountdown,...
            constants.countdownSpeed,  window, constants);
        data.onset(studyRows) = study(data(studyRows, {'cue','target'}), window, constants);
    end
    data.onset(testRows) = onset;
    data.response(testRows) = response;
    data.firstPress(testRows) = firstPress;
    data.lastPress(testRows) = lastPress;
end
end