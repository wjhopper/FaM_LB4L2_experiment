function drawCueTarget(cue, target, window, constants )

DrawFormattedText(window, cue ,'right', 'center',[],[],[],[],[],[],constants.left_half-[0 0 constants.spacing 0]);
DrawFormattedText(window,' - ', 'center','center');
DrawFormattedText(window, target , constants.right_half(1)+constants.spacing, 'center');

end

