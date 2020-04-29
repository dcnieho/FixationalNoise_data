clear variables; close all; fclose('all'); clc

dbstop if error % for debugging: trigger a debug point when an error occurs

% setup directories
thuisdir = cd;
cd('data');
cd('human_samples');      dirs.data       = cd;
cd ..;
cd('human_windows');      dirs.wins       = cd;
cd ..;
cd('human_msgs');         dirs.msgs       = cd;
cd ..;
cd ..;
cd function_library;            dirs.funclib    = cd;
cd(thuisdir);
addpath(genpath(dirs.funclib));                 % add dirs to path

% settings lookup table
lookup = getDataDescription(false);

% params
windowLength    = 200;      % ms
windowSkip      = 200;      % ms
allowMissingFrac= .2;       % fraction missing allowed during a window, 0 for none
excludeIDTRange = .5;



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
    % pix 2 cm factor
    pixpercm    = getPixConvs(scrSz,scrRes,viewDist);
    
    % read msgs and data
    data    = readNumericFile(fullfile(dirs.data,files(f).name),nCol,1);
    msgs    = readNumericFile(fullfile(dirs.msgs,files(f).name),4   ,0);
    
    % fixup timestamps
    data(:,1) = data(:,1)/timeFac;
    msgs(:,1) = msgs(:,1)/timeFac;
    tOff      = msgs(1,1);
    data(:,1) = data(:,1)-tOff;
    msgs(:,1) = msgs(:,1)-tOff;
    
    % get target pos
    tStep       = round(mean(diff(msgs(:,1))));
    targets     = [msgs(:,1) [msgs(2:end,1); msgs(end,1)+tStep] msgs(:,3:4)];
    nPoint      = size(targets,1);
    [tPoss,~,idx] = unique(targets(:,3:4),'rows');
    targetsCm   = (targets(:,3:4) - repmat(targets(1,3:4),size(targets,1),1))/pixpercm; % first target is always at center of screen, so this line transforms to distance from center of screen
    
    % throw data into nice struct
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
        clear dat;
        dat.time    = data(:,1);
        dat.left.X  = 90+lAngsH*180/pi;
        dat.right.X = 90+rAngsH*180/pi;
        dat.left.Y  = lAngsV*180/pi;
        dat.right.Y = rAngsV*180/pi;
    else
        dat.time    = data(:,1);
        dat.left.X  = data(:,2);
        dat.right.X = data(:,4);
        dat.left.Y  = data(:,3);
        dat.right.Y = data(:,5);
    end
    dat.left.pup    = data(:,6);
    dat.right.pup   = data(:,7);
    
    % add target info
    dat.target.on   = targets(:,1);
    dat.target.off  = targets(:,2);
    dat.target.X    = targets(:,3);
    dat.target.Y    = targets(:,4);
    dat.target.Xcm  = targetsCm(:,1);
    dat.target.Ycm  = targetsCm(:,2);
    dat.target.idx  = idx;
    
    % setup windows
    nSamp       = ceil(windowLength*freq/1000);
    nSampSkip   = ceil(windowSkip  *freq/1000);
    nMissAllowed= ceil(windowLength*freq/1000*allowMissingFrac);
    
    % calculate window means
    % left eye
    [X,winOffs]     = rovingBin(dat.left.X,nSamp);
    Y               = rovingBin(dat.left.Y,nSamp);
    left.Xwin       = nanmean(X,2);
    left.Ywin       = nanmean(Y,2);
    left.XwRang     = nanmax(X,[],2)-nanmin(X,[],2);
    left.YwRang     = nanmax(Y,[],2)-nanmin(Y,[],2);
    % check if too many missing in window, then set to nan
    qMissing        = sum(isnan(X),2)>nMissAllowed;
    left.Xwin(qMissing)     = nan;
    left.Ywin(qMissing)     = nan;
    left.XwRang(qMissing)   = nan;
    left.YwRang(qMissing)   = nan;
    
    % right eye
    X               = rovingBin(dat.right.X,nSamp);
    Y               = rovingBin(dat.right.Y,nSamp);
    right.Xwin      = nanmean(X,2);
    right.Ywin      = nanmean(Y,2);
    right.XwRang    = nanmax(X,[],2)-nanmin(X,[],2);
    right.YwRang    = nanmax(Y,[],2)-nanmin(Y,[],2);
    % check if too many missing in window, then set to nan
    qMissing        = sum(isnan(X),2)>nMissAllowed;
    right.Xwin(qMissing)    = nan;
    right.Ywin(qMissing)    = nan;
    right.XwRang(qMissing)  = nan;
    right.YwRang(qMissing)  = nan;
    
    % get info about windows
    for e=1:2
        switch e
            case 1
                eye = 'left';
            case 2
                eye = 'right';
        end
        [dat.(eye).wins.start, dat.(eye).wins.end, ...
            dat.(eye).wins.xpos, dat.(eye).wins.ypos, ...
            dat.(eye).wins.target]  = deal(nan(1,nPoint));
    end
    for t=1:nPoint
        [on,off] = bool2bounds(dat.time>=targets(t,1) & dat.time<targets(t,2));
        on  = on +nSampSkip+winOffs(1);
        off = off-winOffs(2);
        for e=1:2
            switch e
                case 1
                    eye = 'left';
                    wins = left;
                case 2
                    eye = 'right';
                    wins = right;
            end
            
            % get mean positions for each window during target
            X = wins.Xwin(on:off);
            Y = wins.Ywin(on:off);
            
            % no data
            qNaN = isnan(X);
            if all(qNaN)
                continue
            end
            
            % for any windows where dispersion belong to top x%, remove
            % from consideration
            disps = hypot(wins.XwRang(on:off),wins.YwRang(on:off));
            [~,idx] = sort(disps,'descend'); idx(isnan(X(idx))) = []; % don't include the samples that are already nan
            if length(idx) > round(excludeIDTRange*length(X))
                X(idx(1:round(excludeIDTRange*length(X)))) = nan;
                Y(idx(1:round(excludeIDTRange*length(Y)))) = nan;
            elseif length(idx) > round(.1*length(X)) && length(idx)>3
                % not enough samples. remove top half
                X(idx(1:round(.5*length(idx)))) = nan;
                Y(idx(1:round(.5*length(idx)))) = nan;
            end
            
            % calculate distances
            dists = hypot(X-targets(t,3), Y-targets(t,4));
            
            % take window closest to target
            [~,idx]   = min(dists);
            wcenter = on+idx-1;
            won     = wcenter-winOffs(1);
            woff    = wcenter+winOffs(2);
            
            % get info about windows
            dat.(eye).wins.start(t)     = won;
            dat.(eye).wins.end(t)       = woff;
            dat.(eye).wins.xpos(t)      = X(idx);
            dat.(eye).wins.ypos(t)      = Y(idx);
            dat.(eye).wins.target(t)    = find(all(targets(t,3:4)==tPoss,2));
        end
    end
    
    % save output
    save(fullfile(dirs.wins,[files(f).fname '.mat']),'dat')
end


rmpath(genpath(dirs.funclib));                 % add dirs to path
