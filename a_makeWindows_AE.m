clear variables; close all; fclose('all'); clc

dbstop if error % for debugging: trigger a debug point when an error occurs

% setup directories
thuisdir = cd;
cd('data');
cd('AE_samples');       dirs.data       = cd;
cd ..;
cd('AE_windows');       dirs.wins       = cd;
cd ..;
cd ..;
cd function_library;    dirs.funclib    = cd;
cd(thuisdir);
addpath(genpath(dirs.funclib));                 % add dirs to path

% settings lookup table
lookup = getDataDescription(true);

% params
windowLength    = 200;      % ms
windowMove      = 50;
allowMissingFrac= .2;       % fraction missing allowed during a window, 0 for none

qRemoveOutliers = true;


% get what files there are to process
files   = FileFromFolder(dirs.data,[],'txt');
files   = parseFileNames(files);
% we need to also create "unfiltered" version for the SMI data, make some
% fake extra files that'll trigger the right processing below
for tr={'RED250','REDm'}
    qFile = strcmp({files.tracker},tr{1});
    add = files(qFile);
    fnames = {add.fname};
    fnames = cellfun(@(x) [x '_unfiltered'],fnames,'uni',false);    % adjust fname but not name so right input data is read, but resulting windows will be saved under another name
    [add.fname] = fnames{:};
    [add.isFiltered] = deal(false);
    files = [files; add];
end
nfiles = length(files);

for f=1:nfiles
    fprintf('%d/%d: %s\n',f,nfiles,files(f).name);
    
    % get setup for data from this tracker
    [nCol,scrRes,viewDist,scrSz,freq,timeFac] = getValByKey(lookup,files(f).tracker);
    
    % setup windows
    nSamp       = ceil(windowLength*freq/1000);
    nSampMove   = ceil(windowMove*freq/1000);
    nMissAllowed= ceil(windowLength*freq/1000*allowMissingFrac);
    
    % read msgs and data
    data    = readNumericFile(fullfile(dirs.data,files(f).name),nCol,1);
    
    clear dat;
    if ismember(files(f).tracker,{'RED250','REDm'}) && ~files(f).isFiltered
        % turn SMI gaze vectors into angle away from straight ahead
        lPoss = data(:, 8:10);
        rPoss = data(:,11:13);
        lVecs = data(:,14:16);
        rVecs = data(:,17:19);
        
        % compute angle between them using dot product (simple as we already
        % know vectors have unit length)
        [lAngsH,lAngsV] = cart2sph(lVecs(:,1),lVecs(:,3),lVecs(:,2));   % matlab's Z is our Y
        [rAngsH,rAngsV] = cart2sph(rVecs(:,1),rVecs(:,3),rVecs(:,2));
        
        % throw data into nice struct
        dat.time    = data(:,1);
        dat.left.X  = 90+lAngsH*180/pi;
        dat.right.X = 90+rAngsH*180/pi;
        dat.left.Y  = lAngsV*180/pi;
        dat.right.Y = rAngsV*180/pi;
        miss = [90 0];
    else
        dat.time    = data(:,1);
        dat.left.X  = data(:,2);
        dat.right.X = data(:,5);
        dat.left.Y  = data(:,3);
        dat.right.Y = data(:,6);
        miss = [0 0];
    end
    
    % deal with missing data
    qMissingL = dat.left.X==miss(1) & dat.left.Y==miss(2);
    dat.left.X(qMissingL) = nan;
    dat.left.Y(qMissingL) = nan;
    qMissingR = dat.right.X==miss(1) & dat.right.Y==miss(2);
    dat.right.X(qMissingR) = nan;
    dat.right.Y(qMissingR) = nan;
    
    % position windows
    % left eye
    dat.left.wins.start = 1+[1:nSampMove:length(dat.time)-nSamp+1]-1;
    dat.left.wins.end   = dat.left.wins.start+nSamp-1;
    [X,Y] = deal(nan(length(dat.left.wins.start),nSamp));
    for w=1:length(dat.left.wins.start)
        idxs = [dat.left.wins.start(w):dat.left.wins.end(w)];
        X(w,:) = dat.left.X(idxs);
        Y(w,:) = dat.left.Y(idxs);
    end
    dat.left.wins.xpos  = nanmean(X,2).';
    dat.left.wins.ypos  = nanmean(Y,2).';
    % check if too many missing in window, then set to nan
    qMissing            = sum(isnan(X),2)>nMissAllowed | dat.left.wins.start.'<1 | dat.left.wins.end.'>length(dat.left.X);
    X(qMissing,:)       = [];
    Y(qMissing,:)       = [];
    dat.left.wins.start(qMissing)   = [];
    dat.left.wins.  end(qMissing)   = [];
    dat.left.wins. xpos(qMissing)   = [];
    dat.left.wins. ypos(qMissing)   = [];
    % calculate RMS/STD if we'll check whether there are outlier RMS/STD in window
    if qRemoveOutliers
        lRMS    = zeros(size(X,1),1);
        lSTD    = zeros(size(X,1),1);
        for w=1:size(X,1)
            dataSel     = [X(w,:); Y(w,:)].';
            xdif        = diff(dataSel(:,1)).^2; xdif(isnan(xdif)) = [];
            ydif        = diff(dataSel(:,2)).^2; ydif(isnan(ydif)) = [];
            lRMS(w)     = sqrt(mean((xdif + ydif)));
            lSTD(w)     = sqrt(nanvar(dataSel(:,1)) + nanvar(dataSel(:,2)));
        end
    end
    
    % right eye
    dat.right.wins.start = 1+[1:nSampMove:length(dat.time)-nSamp+1]-1;
    dat.right.wins.end   = dat.right.wins.start+nSamp-1;
    [X,Y] = deal(nan(length(dat.right.wins.start),nSamp));
    for w=1:length(dat.right.wins.start)
        idxs = [dat.right.wins.start(w):dat.right.wins.end(w)];
        X(w,:) = dat.right.X(idxs);
        Y(w,:) = dat.right.Y(idxs);
    end
    dat.right.wins.xpos = nanmean(X,2).';
    dat.right.wins.ypos = nanmean(Y,2).';
    qMissing            = sum(isnan(X),2)>nMissAllowed | dat.right.wins.start.'<1 | dat.right.wins.end.'>length(dat.right.X);
    X(qMissing,:)       = [];
    Y(qMissing,:)       = [];
    dat.right.wins.start(qMissing)  = [];
    dat.right.wins.  end(qMissing)  = [];
    dat.right.wins. xpos(qMissing)  = [];
    dat.right.wins. ypos(qMissing)  = [];
    % calculate RMS/STD if we'll check whether there are outlier RMS/STD in window
    if qRemoveOutliers
        rRMS    = zeros(size(X,1),1);
        rSTD    = zeros(size(X,1),1);
        for w=1:size(X,1)
            dataSel     = [X(w,:); Y(w,:)].';
            xdif        = diff(dataSel(:,1)).^2; xdif(isnan(xdif)) = [];
            ydif        = diff(dataSel(:,2)).^2; ydif(isnan(ydif)) = [];
            rRMS(w)     = sqrt(mean((xdif + ydif)));
            rSTD(w)     = sqrt(nanvar(dataSel(:,1)) + nanvar(dataSel(:,2)));
        end
    end
    
    if qRemoveOutliers
        % remove windows with outlier RMS or STD values
        allDat  = [cat(1,lSTD,rSTD), cat(1,lRMS,rRMS)];
        qOutlier= any(abs(allDat-median(allDat,1))>2.5*iqr(allDat,1),2);
        nWinL   = length(lRMS);
        
        dat.left.wins.start(qOutlier(1:nWinL))  = [];
        dat.left.wins.  end(qOutlier(1:nWinL))  = [];
        dat.left.wins. xpos(qOutlier(1:nWinL))  = [];
        dat.left.wins. ypos(qOutlier(1:nWinL))  = [];
        
        dat.right.wins.start(qOutlier(nWinL+1:end)) = [];
        dat.right.wins.  end(qOutlier(nWinL+1:end)) = [];
        dat.right.wins. xpos(qOutlier(nWinL+1:end)) = [];
        dat.right.wins. ypos(qOutlier(nWinL+1:end)) = [];
    end
    
    % save output
    save(fullfile(dirs.wins,[files(f).fname '.mat']),'dat')
end


rmpath(genpath(dirs.funclib));                 % add dirs to path
