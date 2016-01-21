function [onset, response, firstPress, lastPress] = testing(data, inputHandler, window, constants)

oldsize = Screen('TextSize', window, 40);
onset = nan(size(data,1),1);
response = cell(size(data,1),1);
firstPress = nan(size(data,1),1);
lastPress = nan(size(data,1),1);
Screen('TextSize', window, 40);
KbQueueStart;
for j = 1:size(data,1)
    duration = constants.testDur;
    string = '';
    rt = [];
    advance = 0;
    input = 0; %#ok<NASGU>
    drawCueTarget(data.cue{j}, '?', window, constants);
    vbl = Screen('Flip', window);
    onset(j) = vbl;
    while GetSecs < onset(j) + duration && advance == 0
        [string, rt, advance, input] = inputHandler([], string, rt, data.target{j});
        drawCueTarget(data.cue{j},  string, window, constants);
        vbl = Screen('Flip', window, vbl + constants.ifi/2);
        if input
            duration = duration + 3;
        end
    end
    [response{j}, firstPress(j), lastPress(j)] = cleanResponses(string, rt);
    Screen('Flip', window);
end
end

function [response, firstPress, lastPress] = cleanResponses(string, RT)

    if isempty(string)
        response = '';
    else
        response = string;
    end

    if isempty(RT)
        firstPress = NaN;
        lastPress = NaN;
    elseif numel(RT) == 1
        firstPress = NaN;
        lastPress = RT;
    else
        firstPress = RT(1);
        lastPress = RT(end);
    end
end