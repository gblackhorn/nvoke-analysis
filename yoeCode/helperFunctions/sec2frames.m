function frames = sec2frames(s, FRAMERATE)
if (~exist('FRAMERATE', 'var'))
    FRAMERATE = 10;
end

% FRAMERATE in Hz
frames = s * FRAMERATE;