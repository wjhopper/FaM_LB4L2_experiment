function data = study(data, window, constants)

onsets = data.onset;
Screen('TextSize', window, 40);
wakeup = Screen('Flip', window);
for j = 1:size(data,1);
    DrawFormattedText(window,data.cue{j},'right', 'center',[],[],[],[],[],[],constants.left_half-[0 0 constants.spacing 0]);
    DrawFormattedText(window,' - ', 'center','center');
    DrawFormattedText(window,data.target{j},constants.right_half(1)+constants.spacing, 'center');
    Screen('DrawingFinished', window);
    vbl = Screen('Flip', window, wakeup + (constants.ifi/2));
    onsets(j) = vbl;
	wakeup = WaitSecs('UntilTime', vbl + constants.cueDur - constants.ifi);
end

end

