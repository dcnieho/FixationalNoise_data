clear variables; close all; fclose('all'); clc

dbstop if error % for debugging: trigger a debug point when an error occurs

doAE = true;        % if true, process AE data, if false, human data

% setup directories
thuisdir = cd;
cd('data');
if doAE
    cd('AE_processed');         dirs.proc       = cd;
    cd ..;
    cd('AE_windows');           dirs.wins       = cd;
    cd ..;
else
    cd('human_processed');      dirs.proc       = cd;
    cd ..;
    cd('human_windows');        dirs.wins       = cd;
    cd ..;
end
cd ..;
cd function_library;            dirs.funclib    = cd;
cd(thuisdir);
addpath(genpath(dirs.funclib));                 % add dirs to path

% settings lookup table
lookup = getDataDescription(doAE);

% params
P    = 0.68; % for BCEA: cumulative probability of area under the multivariate normal
k    = log(1/(1-P));


% get what files there are to process
[files,nfiles]  = FileFromFolder(dirs.wins,[],'mat');
files           = parseFileNames(files);

for f=1:nfiles
    fprintf('%d/%d: %s\n',f,nfiles,files(f).name);
    
    % get setup for data from this tracker
    [nCol,scrRes,viewDist,scrSz,freq,timeFac] = getValByKey(lookup,files(f).tracker);
    
    % read data
    C       = load(fullfile(dirs.wins,files(f).name)); dat = C.dat;
    nPoint  = max([length(dat.left.wins.start) length(dat.right.wins.start)]);
    
    % pix 2 deg factor
    [pixpercm,pixperdeg,pix2degScaleFunc] = getPixConvs(scrSz,scrRes,viewDist);
    
    % create output variables
    if ~doAE
        out.target          = nan(nPoint,1);
        out.targetDist      = nan(nPoint,1);
    end
    out.RMS             = nan(nPoint,2);
    out.STD             = nan(nPoint,2);
    out.RMS_STD         = nan(nPoint,2);
    out.lenRMSSTD       = nan(nPoint,2);
    out.BCEAarea1       = nan(nPoint,2);
    out.BCEAarea2       = nan(nPoint,2);
    out.BCEAori         = nan(nPoint,2);
    out.BCEAax1         = nan(nPoint,2);
    out.BCEAax2         = nan(nPoint,2);
    out.BCEA_AR         = nan(nPoint,2);
    out.PSDX            =cell(nPoint,2);
    out.PSDY            =cell(nPoint,2);
    out.PSDf            =cell(1);
    out.PSDSlopeX       = nan(nPoint,2);
    out.PSDSlopeY       = nan(nPoint,2);
    out.PSDSlopeX100    = nan(nPoint,2);
    out.PSDSlopeY100    = nan(nPoint,2);
    out.PSDSlopeXLS     = nan(nPoint,2);
    out.PSDSlopeYLS     = nan(nPoint,2);
    
    % precision measures per target presentation
    for e=1:2   % per eye
        switch e
            case 1
                eye = 'left';
            case 2
                eye = 'right';
        end
        for w=1:length(dat.(eye).wins.end)
            if isnan(dat.(eye).wins.start(w))
                continue;
            end
            idxs = dat.(eye).wins.start(w):dat.(eye).wins.end(w);
            idxs(idxs<1 | idxs>length(dat.(eye).X)) = [];
            dataSel = [dat.(eye).X(idxs) dat.(eye).Y(idxs)];
            time = dat.time(idxs);
            
            if doAE
                % for AE, use pix2deg factor assuming center of screen
                % offsets are arbitrary, assuming center of screen makes
                % noise larger if wrong (same distance in pixels on screen
                % is larger angle), which means that we may overestimate AE
                % noise magnitude using this method.
                pix2degFac = pixperdeg;
                % exception: "unfiltered" SMI data is gaze vectors, so
                % already angles, don't scale from pix 2 deg
                if ismember(files(f).tracker,{'RED250','REDm'}) && ~files(f).isFiltered
                    pix2degFac = 1;
                end
            else
                assert(length(dat.(eye).wins.end) == length(dat.target.on))
                % get pix2deg factor for position on screen
                wPos = nanmean(dataSel,1) - scrRes./2;
                pix2degFac = pixperdeg*pix2degScaleFunc(wPos(1),wPos(2));
                % exception: "unfiltered" SMI data is gaze vectors, so
                % already angles, don't scale from pix 2 deg
                if ismember(files(f).tracker,{'RED250','REDm'}) && ~files(f).isFiltered
                    pix2degFac = 1;
                end
                
                % store which point they are looking at. NB: pixel
                % positions might not be the same across systems due to
                % different screens, but positions of targets in cm are
                out.target(w)       = dat.target.idx(w);
                out.targetDist(w)   = hypot(dat.target.Xcm(w),dat.target.Ycm(w));
            end
            
            % noise
            % 1. RMS
            % since its done with diff, don't just exclude missing and treat
            % resulting as one continuous vector. We diff with the nans,
            % and then ignore all diffs where a nan was involved (those are
            % nan too)
            xdif = diff(dataSel(:,1)).^2; xdif(isnan(xdif)) = [];
            ydif = diff(dataSel(:,2)).^2; ydif(isnan(ydif)) = [];
            out.RMS(w,e)     = sqrt(mean((xdif + ydif)))/pix2degFac;
            
            %%%%%
            % for the rest, remove nans
            qNaN = any(isnan(dataSel),2);
            dataSel(qNaN,:) = [];
            %%%%%
            
            % 2. STD
            out.STD(w,e)     = sqrt(var(dataSel(:,1)) + var(dataSel(:,2)))/pix2degFac;
            
            % 3. RMS/STD
            out.RMS_STD(w,e) = out.RMS(w,e)/out.STD(w,e);
            
            % 4. hypot(RMS,STD)
            out.lenRMSSTD(w,e)   = hypot(out.RMS(w,e),out.STD(w,e));
            
            % 5. BCEA direct by formula
            stdx = std(dataSel(:,1));
            stdy = std(dataSel(:,2));
            xx   = corrcoef(dataSel(:,1),dataSel(:,2));
            rho  = xx(1,2);
            out.BCEAarea1(w,e)   = 2*k*pi*stdx*stdy*sqrt(1-rho.^2)/pix2degFac^2;
        
            % 6. BCEA ellipses
            % calculate orientation of the bivariate normal distribution
            % (see
            % https://en.wikipedia.org/wiki/Multivariate_normal_distribution#Geometric_interpretation)
            % or aspect ratio of axes. Note that an axis is half the
            % diameter of ellipse along that direction. Also note that axes
            % have to be scaled by k (i.e., log(1/(1-P))) to match value
            % from direct area calculation above
            % note that v and d outputs below are reordered versions of a
            % and c in [a,b,c]=pca(dataSel(~qMissing,:));
            qMissing = isnan(dataSel(:,1));
            [v,d] = eig(cov(dataSel(~qMissing,1),dataSel(~qMissing,2)));
            [~,i] = max(diag(d));
            out.BCEAori(w,e) = atan2(v(2,i),v(1,i));
            out.BCEAax1(w,e) = sqrt(d(i,i))/pix2degFac;
            out.BCEAax2(w,e) = sqrt(d(3-i,3-i))/pix2degFac;
            out.BCEA_AR(w,e) = max([out.BCEAax1(w,e) out.BCEAax2(w,e)])/min([out.BCEAax1(w,e) out.BCEAax2(w,e)]);
            % to check. should closely match BCEAarea1 from above
            out.BCEAarea2(w,e)   = 2*k*out.BCEAax1(w,e).*out.BCEAax2(w,e)*pi;
            
            % 7. periodogram, get slope
            nfft        = length(idxs);   % no zero padding
            dataPSD     = bsxfun(@minus,dataSel,mean(dataSel,1));   % remove DC
            [out.PSDX{w,e},out.PSDf]    = periodogram(dataPSD(:,1)/pix2degFac,[],nfft,freq);
            out.PSDY{w,e}               = periodogram(dataPSD(:,2)/pix2degFac,[],nfft,freq);
            % fit line
            linFitX     = polyfit(log10(out.PSDf(2:end-1)),log10(out.PSDX{w,e}(2:end-1)),1);
            linFitY     = polyfit(log10(out.PSDf(2:end-1)),log10(out.PSDY{w,e}(2:end-1)),1);
            % output: [x DC], x is what we want. Negate because reciprocal
            % in log space
            out.PSDSlopeX(w,e) = -linFitX(1);
            out.PSDSlopeY(w,e) = -linFitY(1);
            % same, but now only frequencies up to 100 Hz
            qfs         = out.PSDf>0 & out.PSDf<100 & out.PSDf~=out.PSDf(end);
            linFitX     = polyfit(log10(out.PSDf(qfs)),log10(out.PSDX{w,e}(qfs)),1);
            linFitY     = polyfit(log10(out.PSDf(qfs)),log10(out.PSDY{w,e}(qfs)),1);
            % output: [x DC], x is what we want
            out.PSDSlopeX100(w,e) = -linFitX(1);
            out.PSDSlopeY100(w,e) = -linFitY(1);
            
            if 1
                % 8 periodogram check using Lomb-Scargle
                psdx        = plomb(dataPSD(:,1)/pix2degFac,time(~qNaN)./1000,out.PSDf);
                psdy        = plomb(dataPSD(:,2)/pix2degFac,time(~qNaN)./1000,out.PSDf);
                % fit line
                linFitX     = polyfit(log10(out.PSDf(2:end-1)),log10(psdx(2:end-1)),1);
                linFitY     = polyfit(log10(out.PSDf(2:end-1)),log10(psdy(2:end-1)),1);
                % output: [x DC], x is what we want
                out.PSDSlopeXLS(w,e) = -linFitX(1);
                out.PSDSlopeYLS(w,e) = -linFitY(1);
            end
            
            % 9. check inter-sample-interval
            out.ISI{w,e} = diff(time);
            
            if w==1 && e==1
                fprintf('  n point in fft window: %d\n',nfft);
            end
        end
    end
    
    
    % save output
    dat = out;
    save(fullfile(dirs.proc,files(f).name),'dat')
end


rmpath(genpath(dirs.funclib));                 % add dirs to path
