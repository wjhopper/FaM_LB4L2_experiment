function countdown(text, start, speed, window, constants)
    times = start:-1:1; 
    wakeup = GetSecs;
    for i = times
        message = strjoin({text, num2str(i)}, '\n\n');
        DrawFormattedText(window, message, 'center', 'center',[], constants.wrapat,[],[],1.5);
        vbl = Screen('Flip', window, wakeup -(constants.ifi/2));
        wakeup = WaitSecs('UntilTime', vbl + speed);
    end
end