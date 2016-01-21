function onsets = study(data, window, constants)

onsets = nan(size(data,1),1);
oldsize = Screen('TextSize', window, 40);
wakeup = Screen('Flip', window);
for j = 1:size(data,1);
    drawCueTarget(data.cue{j}, data.target{j}, window, constants)    
    vbl = Screen('Flip', window, wakeup + (constants.ifi/2));
    onsets(j) = vbl;
	wakeup = WaitSecs('UntilTime', vbl + constants.cueDur - constants.ifi);
end
Screen('TextSize', window, oldsize);
end

