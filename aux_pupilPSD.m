clear variables; close all; fclose('all'); clc

dbstop if error % for debugging: trigger a debug point when an error occurs

% setup directories
thuisdir = cd;
cd('data');
cd('human_processed');      dirs.proc       = cd;
cd ..;
cd('human_windows');        dirs.wins       = cd;
cd ..;
cd ..;
cd function_library;            dirs.funclib    = cd;
cd ..;
cd results;                     dirs.results    = cd;
cd(thuisdir);
addpath(genpath(dirs.funclib));                 % add dirs to path

% settings lookup table
lookup = getDataDescription(false);

% params
P    = 0.68; % for BCEA: cumulative probability of area under the multivariate normal
k    = log(1/(1-P));


% get what files there are to process
[files,nfiles]  = FileFromFolder(dirs.wins,[],'mat');
files           = parseFileNames(files);

dirs.results = fullfile(dirs.results,'pupilPSD');
if ~isfolder(dirs.results)
    mkdir(dirs.results);
end


%% load in data
for f=1:nfiles
    fprintf('%d/%d: %s\n',f,nfiles,files(f).name);
    
    % get setup for data from this tracker
    [nCol,scrRes,viewDist,scrSz,freq] = getValByKey(lookup,files(f).tracker);
    
    % read data
    C       = load(fullfile(dirs.wins,files(f).name)); dat = C.dat;
    nPoint  = max([length(dat.left.wins.start) length(dat.right.wins.start)]);
    
    % create output variables
    files(f).PSD            =cell(nPoint,2);
    files(f).PSDf           = [];
    files(f).PSDSlope       = nan(nPoint,2);
    files(f).PSDSlope100    = nan(nPoint,2);
    
    for e=1:2   % per eye
        switch e
            case 1
                eye = 'left';
            case 2
                eye = 'right';
        end
        
        % remove missing
        dat.(eye).pup(dat.(eye).pup==0) = nan;
        
        for w=1:length(dat.(eye).wins.end)
            if isnan(dat.(eye).wins.start(w))
                continue;
            end
            idxs = dat.(eye).wins.start(w):dat.(eye).wins.end(w);
            idxs(idxs<1 | idxs>length(dat.(eye).X)) = [];
            dataSel = dat.(eye).pup(idxs);
            time = dat.time(idxs);
            
            % remove nans
            qNaN = any(isnan(dataSel),2);
            dataSel(qNaN,:) = [];
            %%%%%
            
            nfft        = length(idxs);   % no zero padding
            dataPSD     = bsxfun(@minus,dataSel,mean(dataSel,1));   % remove DC
            [files(f).PSD{w,e},files(f).PSDf]    = periodogram(dataPSD(:,1),[],nfft,freq);
            % fit line
            linFitX     = polyfit(log10(files(f).PSDf(2:end-1)),log10(files(f).PSD{w,e}(2:end-1)),1);
            % output: [x DC], x is what we want. Negate because reciprocal
            % in log space
            files(f).PSDSlope(w,e) = -linFitX(1);
            % same, but now only frequencies up to 100 Hz
            qfs         = files(f).PSDf>0 & files(f).PSDf<100 & files(f).PSDf~=files(f).PSDf(end);
            linFitX     = polyfit(log10(files(f).PSDf(qfs)),log10(files(f).PSD{w,e}(qfs)),1);
            % output: [x DC], x is what we want
            files(f).PSDSlope100(w,e) = -linFitX(1);
            
            if w==1 && e==1
                fprintf('  n point in fft window: %d\n',nfft);
            end
        end
    end
end

%% amplitude spectra plots
if 1
    yLims       = [0.001094014305016 7.944889858903269];
    yLimsLTicks = [floor(log10(yLims(1))) ceil(log10(yLims(2)))];
    ETs         = unique({files.tracker});
    subs        = {'ss1','ss2','ss3','ss4'};
    fnames      = {};
    for e=1:length(ETs)
        for f=1:2   % filtered or unfiltered
            clear data;
            whichSub = [1:4];
            switch f
                case 1
                    % filtered human
                    if strcmp(ETs{e},'EL')
                        qFile = strcmp({files.tracker},'EL')   & [files.isFiltered];
                    elseif ismember(ETs{e},{'RED250','REDm'})
                        qFile = strcmp({files.tracker},ETs{e}) & [files.isFiltered];
                    elseif ismember(ETs{e},{'TX300','X260'})    % no filtered data for these
                        continue;
                    end
                    data = files(qFile);
                    condlbl = 'human_filt';
                    
                case 2
                    % unfiltered human
                    if strcmp(ETs{e},'EL')
                        qFile = strcmp({files.tracker},'EL')   & ~[files.isFiltered];
                        whichSub = [1 4];   % get coloring correct
                    elseif ismember(ETs{e},{'RED250','REDm'})
                        qFile = strcmp({files.tracker},ETs{e}) & ~[files.isFiltered];
                    else
                        qFile = ismember({files.tracker},ETs{e});
                    end
                    data = files(qFile);
                    
                    condlbl = 'human_unfilt';
            end
            
            xSlopes=cat(3,data.PSD);
            xSlopes=num2cell(xSlopes,[1 2]);    % take left and right eye, all windows, together, per participant
            xSlopes=squeeze(cellfun(@(x) nanmean(cat(2,x{:}),2),xSlopes,'uni',false));
            xSlopes=cat(2,xSlopes{:});
            PSDf = data(1).PSDf;
            
            % now plot
            fh=figure;
            ax = gca;
            hold on
            if strcmp(condlbl(1:2),'AE')
                extra = {'Color',[0 0 0]};
            else
                extra = {};
            end
            clear h1
            for a=1:size(xSlopes,2)
                ax.ColorOrderIndex = whichSub(a);
                h1(a)=loglog(PSDf(1:end-1),sqrt(xSlopes(1:end-1,a)),'-','LineWidth',1.5,extra{:});
            end
            
            ax.XScale = 'log';
            ax.YScale = 'log';
            axis tight
            xLim = ax.XLim;
            ax.YLim = yLims;
            ax.XLim = xLim;
            ylabel('Amplitude (deg/Hz)')
            xlabel('Frequency (Hz)')
            % all the below shit because adding a label subtly changes
            % the height of the drawable part of the axis...
            drawnow
            xlblPos     = ax.XLabel.Position;
            xlblFontSz  = ax.XLabel.FontSize;
            xlabel('')
            text(xlblPos(1),xlblPos(2),'Frequency (Hz)','HorizontalAlignment','center','VerticalAlignment','top','FontSize',xlblFontSz)
            box off
            ax.FontSize = 12;
            
            yTicks = [yLimsLTicks(1):yLimsLTicks(2)];
            yTicks = yTicks+log10(2:9).';
            yTicks = 10.^yTicks(:);
            ax.YRuler.MinorTickValues = yTicks(:);
            drawnow;
            ax.YRuler.TickValues = 10.^[floor(log10(yLims(1))):ceil(log10(yLims(2)))];
            
            ax.XAxis.LineWidth = 1.5;
            ax.YAxis.LineWidth = 1.5;
            ax.XRuler.TickValues = [1, 10, 100];
            ax.XRuler.TickLabels = {'1','10','100'};
            
            lh=legend(h1,subs{whichSub},'Location','SouthWest');
            lh.Box = 'off';
            
            print(fullfile(dirs.results,['NieZemHol_pupilPSD_' ETs{e} '_' condlbl '.png']),'-dpng','-r300')
        end
    end
end


%% amplitude spectra table
if 1
    ETs = unique({files.tracker});
    PSD    = nan(length(ETs),2);
    PSD100 = nan(length(ETs),2);
    fields = {'PSDSlope'; 'PSDSlope100'};
    
    for e=1:length(ETs)
        for f=1:2   % filtered or unfiltered
            clear data;
            switch f
                case 1
                    % filtered human
                    if strcmp(ETs{e},'EL')
                        qFile = strcmp({files.tracker},'EL')   & [files.isFiltered];
                    elseif ismember(ETs{e},{'RED250','REDm'})
                        qFile = strcmp({files.tracker},ETs{e}) & [files.isFiltered];
                    elseif ismember(ETs{e},{'TX300','X260'})    % no filtered data for these
                        continue;
                    end
                    
                case 2
                    % unfiltered human
                    if strcmp(ETs{e},'EL')
                        qFile = strcmp({files.tracker},'EL')   & ~[files.isFiltered];
                    elseif ismember(ETs{e},{'RED250','REDm'})
                        qFile = strcmp({files.tracker},ETs{e}) & ~[files.isFiltered];
                    else
                        qFile = ismember({files.tracker},ETs{e});
                    end
            end
            data = files(qFile);
            
            for d=1:size(fields,1)
                dat = [];
                for g=1:size(fields,2)
                    dat = cat(1,dat,data.(fields{d,g}));
                end
                dat(isinf(dat)) = nan;
                if d==1
                    PSD(e,f) = nanmean(dat(:));
                else
                    PSD100(e,f) = nanmean(dat(:));
                end
            end
        end
    end
    
    % print
    for e=1:length(ETs)
        fprintf('%s\t%.3f\t%.3f\t\t%.3f\t%.3f\n',ETs{e},PSD(e,:),PSD100(e,:));
    end
end

rmpath(genpath(dirs.funclib));                 % add dirs to path
