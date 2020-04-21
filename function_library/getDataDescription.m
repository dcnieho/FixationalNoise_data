function lookup = getDataDescription(isAE)

% nCol, scrRes, viewDist, scrSz, freq, timeFac, plotIdx, RMS/STD limit
lookup = {
    'EL'    , 7,[1920 1080],56.5,[53.3 30.1],1000,   1,5, 0.2
    'RED250',19,[1680 1050],56.5,[47.5 29.8], 250,1000,3, 1.2
    'REDm'  ,19,[1680 1050],56.5,[47.5 29.8], 120,1000,2, 2.0
    'TX300' ,19,[1920 1080],56.5,[51 28.8]  , 300,1000,4, 0.8
    'X260'  ,19,[1920 1080],56.5,[51 28.8]  ,  60,1000,1, 1.8
    };

if isAE
    [lookup{4:5,2}] = deal(7);  % 7, not 19 columns for tobii AE data
end
