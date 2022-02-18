function s = frames2sec(frames, FRAMERATE)


if (~exist('FRAMERATE', 'var'))
    FRAMERATE = 10;
end

s = frames / FRAMERATE;
end