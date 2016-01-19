function data = practice(data, first, inputHandler, window, constants)

for i = 1:2
    studyRows = strcmp(data.practice,'S') & data.pracRound == i;
    testRows = strcmp(data.practice,'T') & data.pracRound == i;
    if strcmp('S', first)
        countdown('Restudy', 3, constants.countdownSpeed,  window, constants);
        data.onset(studyRows) = study(data(studyRows, {'cue','target'}), window, constants);
        countdown('Practice Test', 3, constants.countdownSpeed,  window, constants);    
        [onset, response, firstPress, lastPress] = testing(data(testRows,:), inputHandler, window, constants);
    else
        countdown('Practice Test', 3, constants.countdownSpeed,  window, constants);
        [onset, response, firstPress, lastPress] = testing(data(testRows,:), inputHandler, window, constants);
        countdown('Restudy', 3, constants.countdownSpeed,  window, constants);
        data.onset(studyRows) = study(data(studyRows, {'cue','target'}), window, constants);
    end
    data.onset(testRows) = onset;
    data.response(testRows) = response;
    data.firstPress(testRows) = firstPress;
    data.lastPress(testRows) = lastPress;
end
end