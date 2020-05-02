clear variables; close all; fclose('all'); clc
% this functions makes the figures for two papers:
% 1.: "NieZemBeeHol"
% Niehorster, Zemblys, Beelders & Holmqvist (in press). Characterizing gaze
% position signals and synthesizing noise during fixations in eye-tracking
% data. Behavior Research Methods
%
% 2.: "NieZemHol"
% Niehorster, Zemblys & Holmqvist (under review). Is apparent fixational
% drift in eye-tracking data due to filters or eyeball rotation? Behavior
% Research Methods

dbstop if error % for debugging: trigger a debug point when an error occurs

% setup directories
thuisdir = cd;
cd('data');
cd('human_windows');            dirs.wins       = cd;
cd ..;
cd('human_processed');          dirs.proc       = cd;
cd ..;
cd ..;
cd function_library;            dirs.funclib    = cd;
cd ..;
cd results;                     dirs.results    = cd;
cd(thuisdir);
addpath(genpath(dirs.funclib));                 % add dirs to path

% settings lookup table
lookup  = getDataDescription(false);

% params
windowLength    = 200;      % ms


% read in data
[files,nfiles]  = FileFromFolder(dirs.proc,[],'mat');
files           = parseFileNames(files);
for f=1:nfiles
    fprintf('%d/%d: %s\n',f,nfiles,files(f).name);
    
    temp = load(fullfile(dirs.proc,files(f).name));
    out(f) = temp.dat;
end

%% raw data figures
% NieZemHol Figure 1
if 1
    tracker = 'EL';
    subs    = {'ss2','ss1'};
    filtered= [true false];
    idxs    = {[294400:297100],[294400:297100]};    % yes, really the same
    off     = [.3 -.3];
    colIdx  = [1 3];
    
    [~,scrRes,viewDist,scrSz]               = getValByKey(lookup,tracker);
    [pixpercm,pixperdeg,pix2degScaleFunc]   = getPixConvs(scrSz,scrRes,viewDist);
    
    fig = clf;
    ax=gca;
    hold on
    for p=1:2
        qWhich = strcmp({files.tracker},tracker) & strcmp({files.subj},subs{p}) & [files.isFiltered]==filtered(p);
        assert(sum(qWhich)==1)
        
        % load data file
        dat = load(fullfile(dirs.wins,files(qWhich).name)); dat = dat.dat;
        
        dataSel = [dat.left.X(idxs{p}) dat.left.Y(idxs{p})];
        wPos = mean(dataSel,1) - scrRes./2;
        pix2degFac = pixperdeg*pix2degScaleFunc(wPos(1),wPos(2));
        dataSel = (dataSel- scrRes./2)/pix2degFac;
        dataSel = bsxfun(@minus,dataSel,mean(dataSel,1));   % remove mean
        
        ax.ColorOrderIndex = colIdx(p);
        h(p)=plot([0:size(dataSel,1)-1],dataSel(:,1)+off(p),'LineWidth',1.2);
    end
    
    ax=gca;
    ylabel('Horizontal gaze position (°)')
    xlabel('Time (ms)')
    xlim([0 size(dataSel,1)-1])
    box off
    set(ax,'FontSize',12)
    ax.XAxis.LineWidth = 1.5;
    ax.YAxis.LineWidth = 1.5;
    ax.YRuler.TickLabelFormat = '%.1f';
    
    fig.Position(3)=fig.Position(3)*1.2;
    
    lh=legend(h,'filtered','unfiltered','Location','SouthEast');
    legend boxoff
    lh.FontSize = 10;
    
    print([dirs.results '\NieZemHol_fig1.png'],'-dpng','-r300');
    print([dirs.results '\NieZemHol_fig1'    ],'-depsc')
    close
end
% NieZemBeeHol Figure 1
if 1
    tracker = 'EL';
    subs    = 'ss2';
    filtered= true;
    idxs    = [69800:71540];
    
    [~,scrRes,viewDist,scrSz]               = getValByKey(lookup,tracker);
    [pixpercm,pixperdeg,pix2degScaleFunc]   = getPixConvs(scrSz,scrRes,viewDist);
    
    qWhich = strcmp({files.tracker},tracker) & strcmp({files.subj},subs) & [files.isFiltered]==filtered;
    assert(sum(qWhich)==1)
    
    % load data file
    dat = load(fullfile(dirs.wins,files(qWhich).name)); dat = dat.dat;
    
    dataSel = [dat.left.X(idxs) dat.left.Y(idxs)];
    wPos = mean(dataSel,1) - scrRes./2;
    pix2degFac = pixperdeg*pix2degScaleFunc(wPos(1),wPos(2));
    dataSel = (dataSel- scrRes./2)/pix2degFac;
    
    fig = clf;
    ax=gca;
    plot([0:size(dataSel,1)-1],dataSel(:,1),'k','LineWidth',1.2)
    
    
    ylabel('Horizontal gaze position (°)')
    xlabel('Time (ms)')
    xlim([0 size(dataSel,1)-1])
    box off
    set(ax,'FontSize',12)
    ax.XAxis.LineWidth = 1.5;
    ax.YAxis.LineWidth = 1.5;
    ax.YRuler.TickLabelFormat = '%.1f';
    
    fig.Position(3)=fig.Position(3)*1.2;
    
    print([dirs.results '\NieZemBeeHol_fig1.png'],'-dpng','-r300');
    print([dirs.results '\NieZemBeeHol_fig1'    ],'-depsc')
    close
end

% NieZemHol Figure 2a; and
% NieZemBeeHol Figure 2a
if 1
    ETs     = unique({files.tracker});
    nFix    = 10;
    allDatSel = cell(length(ETs),10);
    for e=1:length(ETs)
        qTrackers = strcmp({files.tracker},ETs{e});
        if ismember(ETs{e},{'EL','RED250','REDm'})
            qTrackers = qTrackers & [files.isFiltered]==true;
        end
        iTrackers = find(qTrackers);
        
        % setup windows
        [nCol,scrRes,viewDist,scrSz,freq,timeFac] = getValByKey(lookup,files(iTrackers(1)).tracker);
        nSamp       = ceil(windowLength*freq/1000);
        [pixpercm,pixperdeg(e)]   = getPixConvs(scrSz,scrRes,viewDist);
        
        % get RMS/STD and magnitude
        RMS_STD     = [out(qTrackers).RMS_STD];
        lenRMSSTD   = [out(qTrackers).lenRMSSTD];
        PSDslope    = mean(cat(3,[out(qTrackers).PSDSlopeX],[out(qTrackers).PSDSlopeY]),3);
        
        % get mean RMS/STD
        mRS         = nanmean(RMS_STD(:));
        
        % get 10 fixs closest to mean RMS/STD
        [~,icl]  = sort(abs(RMS_STD(:)-mRS));
        
        % find which files, which column and which row
        [y,x] = ind2sub(size(RMS_STD),icl(1:nFix));
        f = iTrackers(ceil(x/2));
        x = mod(x,2); x(x==0) = 2;
        % now f is the file, y the fixation, and x the eye (first or second
        % column)
        
        
        % select actual data
        datSel = cell(1,length(x));
        for w=1:length(x)
            C       = load(fullfile(dirs.wins,files(f(w)).name)); dat = C.dat;
            if x(w)==1
                eye = 'left';
            else
                eye = 'right';
            end
            idxs = dat.(eye).wins.start(y(w)):dat.(eye).wins.end(y(w));
            datSel{w} = [dat.(eye).X(idxs) dat.(eye).Y(idxs)];
        end
        % zero mean
        for w=1:length(datSel)
            datSel{w} = bsxfun(@minus,datSel{w},nanmean(datSel{w},1));
        end
        % save for later
        allDatSel(e,:)      = datSel;
    end
    
    
    % NieZemHol Figure 2a
    if 1
        voff = [4.1 2.55 1];
        vloff= [.55 .55 .55];
        lbls = {'SR EyeLink 1000Plus','Tobii TX300','SMI RED250'};
        scale= [.1 1/3 1/3];
        eidx = [1 4 2];     % TX300 in middle
        pidx = [[1 3 4 7 9];[1 3 5 6 8];[9 2:3 1 7]];
        idx = sub2ind(size(allDatSel),repmat(eidx.',1,5),pidx);
        plotDat = allDatSel(idx);
        scaleindic = scale.*pixperdeg(eidx);
        
        % scale to equate magnitude for all
        % scale uniformly and arbitrarily so that range of largest bit of data is 1
        sFac = cellfun(@(x) max([range(x(~isnan(x(:,1)),1)) range(x(~isnan(x(:,1)),2))]),plotDat);
        % scale per row
        mFac = max(sFac,[],2);
        plotDat = cellfun(@(x,f) x./f,plotDat,repmat(num2cell(mFac),1,5),'uni',false);
        scaleindic = scaleindic./mFac';
        % shift so that bounding box is centered around zero
        minsx = cellfun(@(x) nanmin(x(:,1)),plotDat);
        maxsx = cellfun(@(x) nanmax(x(:,1)),plotDat);
        centerx= mean(cat(3,minsx,maxsx),3);
        minsy = cellfun(@(x) nanmin(x(:,2)),plotDat);
        maxsy = cellfun(@(x) nanmax(x(:,2)),plotDat);
        centery= mean(cat(3,minsy,maxsy),3);
        plotDat = cellfun(@(d,cx,cy) [d(:,1)-cx d(:,2)-cy],plotDat,num2cell(centerx),num2cell(centery),'uni',false);
        
        
        % plot
        clf, hold on
        left = cellfun(@(x) nanmin(x(:,1)),plotDat(:,1));
        for e=1:size(plotDat,1)
            for f=1:size(plotDat,2)
                plot(plotDat{e,f}(:,1) + f,plotDat{e,f}(:,2) + voff(e),'k');
            end
            
            text(0.51,voff(e)+.52,lbls{e},'FontSize',12,'HorizontalAlignment','left','VerticalAlignment','bottom','FontWeight','bold')
            
            % scale indicator
            ht = text(max(cellfun(@(x) max(x(:,1)),plotDat(:,end)))+f,voff(e)-vloff(e),sprintf('%.2f$^\\circ$',scale(e)),'FontSize',12,'HorizontalAlignment','right','VerticalAlignment','middle','FontWeight','bold','interpreter','latex');
            plot(ht.Position(1)-ht.Extent(3)-.1+[-1 0]*scaleindic(e),voff([e e])-vloff(e),'k-','LineWidth',2);
        end
        axis([0.3098	5.7000	0.4439	4.8622])
        axis equal
        axis off
        
        a=axis();
        text(a(1),a(3)+0.92*a(4),'Human data','FontSize',14,'HorizontalAlignment','left','VerticalAlignment','bottom','FontWeight','bold')
        
        print([dirs.results '\NieZemHol_fig2a.png'],'-dpng','-r300')
        print([dirs.results '\NieZemHol_fig2a'    ],'-depsc')
    end
    
    
    % NieZemBeeHol Figure 2a
    if 1
        voff = [4.1 2.55 1];
        plrange= [-.1 -.5 -.5; .1 .6 .5];
        lbls = {'SR EyeLink 1000Plus','Tobii TX300','SMI RED250'};
        eidx = [1 4 2];     % TX300 in middle
        pidx = [[1];[7];[9]];
        idx = sub2ind(size(allDatSel),eidx.',pidx);
        plotDat = allDatSel(idx);
        plotDat = cellfun(@rdivide,plotDat,num2cell(pixperdeg(eidx)).','uni',false);
        
        % plot
        close all
        fig = figure;
        fig.Position(3)=fig.Position(3)*1.2;
        for e=1:size(plotDat,1)
            ax=subplot(3,1,e);
            ax.Position = [0.1300 0.7169-0.2996*(e-1) 0.7750 0.1881];
            t = linspace(0,200-1,size(plotDat{e},1));
            plot(t,plotDat{e}(:,1),'k','LineWidth',1);
            
            if e==2
                ylabel('Horizontal gaze position (°)')
            end
            if e==3
                xlabel('Time (ms)')
            end
            xlim([0 200])
            ylim([plrange(1,e) plrange(2,e)])
            box off
            ax.FontSize = 12;
            ax.XAxis.LineWidth = 1.5;
            ax.YAxis.LineWidth = 1.5;
            ax.YRuler.TickLabelFormat = '%.2f';
            
            % add text identifying setup
            text(0,plrange(2,e)*1.02,lbls{e},'FontSize',12,'HorizontalAlignment','left','VerticalAlignment','bottom','FontWeight','bold')

            % panel label
            if e==1
                text(-15,plrange(2,e)*1.4,'Human data','FontSize',14,'HorizontalAlignment','left','VerticalAlignment','bottom','FontWeight','bold')
            end
        end
        
        print([dirs.results '\NieZemBeeHol_fig2a.png'],'-dpng','-r300')
        print([dirs.results '\NieZemBeeHol_fig2a'    ],'-depsc')
    end
    close
end

% NieZemBeeHol Figure 3
if 1
    ETs     = unique({files.tracker});
    nFix    = 10;
    allDatSel = cell(length(ETs),10);
    for e=1:length(ETs)
        qTrackers = strcmp({files.tracker},ETs{e});
        if ismember(ETs{e},{'EL','RED250','REDm'})
            qTrackers = qTrackers & [files.isFiltered]==true;
        end
        iTrackers = find(qTrackers);
        
        % setup windows
        [nCol,scrRes,viewDist,scrSz,freq,timeFac] = getValByKey(lookup,files(iTrackers(1)).tracker);
        nSamp       = ceil(windowLength*freq/1000);
        [pixpercm,pixperdeg(e)]   = getPixConvs(scrSz,scrRes,viewDist);
        
        % get RMS/STD and magnitude
        RMS_STD     = [out(qTrackers).RMS_STD];
        lenRMSSTD   = [out(qTrackers).lenRMSSTD];
        PSDslope    = mean(cat(3,[out(qTrackers).PSDSlopeX],[out(qTrackers).PSDSlopeY]),3);
        
        % get max RMS/STD
        mRS         = nanmax(RMS_STD(:));
        
        % get 10 fixs closest to mean RMS/STD
        [~,icl]  = sort(abs(RMS_STD(:)-mRS));
        
        % find which files, which column and which row
        [y,x] = ind2sub(size(RMS_STD),icl(1:nFix));
        f = iTrackers(ceil(x/2));
        x = mod(x,2); x(x==0) = 2;
        % now f is the file, y the fixation, and x the eye (first or second
        % column)
        
        
        % select actual data
        datSel = cell(1,length(x));
        for w=1:length(x)
            C       = load(fullfile(dirs.wins,files(f(w)).name)); dat = C.dat;
            if x==1
                eye = 'left';
            else
                eye = 'right';
            end
            idxs = dat.(eye).wins.start(y(w)):dat.(eye).wins.end(y(w));
            datSel{w} = [dat.(eye).X(idxs) dat.(eye).Y(idxs)];
        end
        % zero mean
        for w=1:length(datSel)
            datSel{w} = bsxfun(@minus,datSel{w},nanmean(datSel{w},1));
        end
        % save for later
        allDatSel(e,:)      = datSel;
    end
    
    
    % NieZemBeeHol Figure 3a
    if 1
        voff = [2.25 1];
        vloff= [.5 .4];
        lbls = {'SMI RED250', 'Tobii TX300'};
        eidx = [2 4];
        pidx = [[4 1 8];[2 6 9]];
        scale= [1 .2];
        idx = sub2ind(size(allDatSel),repmat(eidx.',1,3),pidx);
        plotDat = allDatSel(idx);
        scaleindic = scale.*pixperdeg(eidx);
        
        % scale to equate magnitude for all
        % scale uniformly and arbitrarily so that range of largest bit of data is 1
        sFac = cellfun(@(x) max([range(x(~isnan(x(:,1)),1)) range(x(~isnan(x(:,1)),2))]),plotDat);
        % scale per row
        mFac = max(sFac,[],2);
        plotDat = cellfun(@(x,f) x./f,plotDat,repmat(num2cell(mFac),1,3),'uni',false);
        scaleindic = scaleindic./mFac';
        % shift so that bounding box is centered around zero
        minsx = cellfun(@(x) nanmin(x(:,1)),plotDat);
        maxsx = cellfun(@(x) nanmax(x(:,1)),plotDat);
        centerx= mean(cat(3,minsx,maxsx),3);
        minsy = cellfun(@(x) nanmin(x(:,2)),plotDat);
        maxsy = cellfun(@(x) nanmax(x(:,2)),plotDat);
        centery= mean(cat(3,minsy,maxsy),3);
        plotDat = cellfun(@(d,cx,cy) [d(:,1)-cx d(:,2)-cy],plotDat,num2cell(centerx),num2cell(centery),'uni',false);
        
        
        % plot
        clf, hold on
        left = cellfun(@(x) nanmin(x(:,1)),plotDat(:,1));
        for e=1:size(plotDat,1)
            for f=1:size(plotDat,2)
                plot(plotDat{e,f}(:,1) + f,plotDat{e,f}(:,2) + voff(e),'k');
            end
            
            text(0.51,voff(e)+.52,lbls{e},'FontSize',12,'HorizontalAlignment','left','VerticalAlignment','bottom','FontWeight','bold')
            
            % scale indicator
            ht = text(max(cellfun(@(x) max(x(:,1)),plotDat(:,end)))+f,voff(e)-vloff(e),sprintf('%.2f$^\\circ$',scale(e)),'FontSize',12,'HorizontalAlignment','right','VerticalAlignment','middle','FontWeight','bold','interpreter','latex');
            plot(ht.Position(1)-ht.Extent(3)-.05+[-1 0]*scaleindic(e),voff([e e])-vloff(e),'k-','LineWidth',2);
        end
        axis([0.6971 3.3585 0.5833 2.75])
        axis equal
        axis off
        
        print([dirs.results '\NieZemBeeHol_fig3a.png'],'-dpng','-r300')
        print([dirs.results '\NieZemBeeHol_fig3a'    ],'-depsc')
    end
    
    
    % NieZemBeeHol Figure 3b
    if 1
        plrange= [-2.8 -1.1; 1.0 1.0];
        lbls = {'SMI RED250', 'Tobii TX300'};
        eidx = [2 4];
        pidx = [[4];[2]];
        idx = sub2ind(size(allDatSel),eidx.',pidx);
        plotDat = allDatSel(idx);
        plotDat = cellfun(@rdivide,plotDat,num2cell(pixperdeg(eidx)).','uni',false);
        
        % plot
        close all
        fig = figure;
        fig.Position(3)=fig.Position(3)*1.2;
        for e=1:size(plotDat,1)
            ax=subplot(2,1,e);
            ax.Position = [0.1300 0.5838-0.4738*(e-1) 0.7750 0.32];
            t = linspace(0,200-1,size(plotDat{e},1));
            plot(t,plotDat{e}(:,2),'k','LineWidth',1);
            
            if e==3
                xlabel('Time (ms)')
            end
            xlim([0 200])
            ylim([plrange(1,e) plrange(2,e)])
            box off
            set(ax,'FontSize',12)
            ax.XAxis.LineWidth = 1.5;
            ax.YAxis.LineWidth = 1.5;
            ax.YRuler.TickLabelFormat = '%.0f';
            if e==2
                ylabel('Vertical gaze position (°)')
                ax.YRuler.Label.Position(2) = 1.5;
            end
            
            % add text identifying setup
            text(0,plrange(2,e)*1.02,lbls{e},'FontSize',12,'HorizontalAlignment','left','VerticalAlignment','bottom','FontWeight','bold')
        end
        
        print([dirs.results '\NieZemBeeHol_fig3b.png'],'-dpng','-r300')
        print([dirs.results '\NieZemBeeHol_fig3b'    ],'-depsc')
    end
    close
end


%% amplitude spectra
% NieZemHol Figure 3
if 1
    tracker = 'EL';
    subs    = {'ss2','ss1'};
    filtered= [true false];
    idxs    = {[294400:297100],[294400:297100]};    % yes, really the same
    off     = [.3 -.3];
    colIdx  = [1 3];
    
    [~,scrRes,viewDist,scrSz,freq]          = getValByKey(lookup,tracker);
    [pixpercm,pixperdeg,pix2degScaleFunc]   = getPixConvs(scrSz,scrRes,viewDist);
    
    fig = clf;
    ax=gca;
    hold on
    for p=1:2
        qWhich = strcmp({files.tracker},tracker) & strcmp({files.subj},subs{p}) & [files.isFiltered]==filtered(p);
        assert(sum(qWhich)==1)
        
        % load data file
        dat = load(fullfile(dirs.wins,files(qWhich).name)); dat = dat.dat;
        
        dataSel = [dat.left.X(idxs{p}) dat.left.Y(idxs{p})];
        wPos = mean(dataSel,1) - scrRes./2;
        pix2degFac = pixperdeg*pix2degScaleFunc(wPos(1),wPos(2));
        dataSel = (dataSel- scrRes./2)/pix2degFac;
        
        nfft        = length(idxs{p});   % no zero padding
        dataPSD     = bsxfun(@minus,dataSel,mean(dataSel,1));   % remove DC
        % use multitaper method here to get a bit smoother plot from
        % only a single short bit of data
        [psdx,fpsd] = pmtm(dataPSD(:,1),4,nfft,freq);
        
        ax.ColorOrderIndex = colIdx(p);
        h(p)=plot(fpsd(1:end-1),sqrt(psdx(1:end-1)),'LineWidth',1.2);
    end
    
    ax=gca;
    set(ax,'XScale','log')
    set(ax,'YScale','log')
    axis tight
    ax.XLim = [0 500];
    ax.YLim(1) = 2.0323e-05;
    ylabel('Amplitude (deg/Hz)')
    xlabel('Frequency (Hz)')
    box off
    set(ax,'FontSize',12)
    ax.XAxis.LineWidth = 1.5;
    ax.YAxis.LineWidth = 1.5;
    ax.YRuler.TickLabelFormat = '%.1f';
    ax.XRuler.TickValues = [1, 10, 100];
    ax.XRuler.TickLabels = {'1','10','100'};
    
    fig.Position(3)=fig.Position(3)*1.2;
    
    lh=legend(h,'filtered','unfiltered','Location','SouthWest');
    legend boxoff
    lh.FontSize = 10;
    
    print([dirs.results '\NieZemHol_fig3.png'],'-dpng','-r300');
    print([dirs.results '\NieZemHol_fig3'    ],'-depsc')
    close
end


%% empirical cdfs
% NieZemBeeHol Figure 11
if 1
    ETs     = unique({files.tracker});
    
    % data structure that is good at growing for storing samples
    storage = arrayfun(@(~)simpleVec,zeros(2,5));
    
    % get data
    for t=1:length(ETs)
        if strcmp(ETs{t},'EL')
            qFile = strcmp({files.tracker},'EL')   & [files.isFiltered];
        elseif ismember(ETs{t},{'RED250','REDm'})
            qFile = strcmp({files.tracker},ETs{t}) & [files.isFiltered];
        elseif ismember(ETs{t},{'TX300','X260'})    % no filtered data for these
            qFile = strcmp({files.tracker},ETs{t});
        end
        
        [~,scrRes,viewDist,scrSz,freq]          = getValByKey(lookup,ETs{t});
        [pixpercm,pixperdeg,pix2degScaleFunc]   = getPixConvs(scrSz,scrRes,viewDist);
        
        % load data files
        iFiles = find(qFile);
        for f=length(iFiles):-1:1
            dat = load(fullfile(dirs.wins,files(iFiles(f)).name));
            data(f) = dat.dat;
        end
        
        % get all samples during windows for all data files
        for f=1:length(data)
            for e=1:2   % per eye
                switch e
                    case 1
                        eye = 'left';
                    case 2
                        eye = 'right';
                end
                for w=1:length(data(f).(eye).wins.end)
                    if isnan(data(f).(eye).wins.start(w))
                        continue;
                    end
                    idxs = data(f).(eye).wins.start(w):data(f).(eye).wins.end(w);
                    dataSel = [data(f).(eye).X(idxs) data(f).(eye).Y(idxs)];
                    
                    wPos = nanmean(dataSel,1) - scrRes./2;
                    pix2degFac = pixperdeg*pix2degScaleFunc(wPos(1),wPos(2));
                    
                    dataSel = dataSel/pix2degFac;
                    dataSel = dataSel-nanmean(dataSel,1);
                    storage(1,t).append(dataSel(:,1));
                    storage(2,t).append(dataSel(:,2));
                end
            end
        end
    end
    storage = arrayfun(@(x) x.get(), storage, 'uni',false);
    
    % make plot
    fits = [.1];
    cols = [0];
    ETs = {'SR EyeLink 1000Plus','SMI RED250','SMI REDm','Tobii TX300','Tobii X2-60'};
    linelims = norminv([fits; 1-fits]).';
    
    for p=1:size(storage,2)
        % take data
        X = storage{1,p};
        Y = storage{2,p};
        
        % take empirical cdf
        Xs  = sort(X(~isnan(X)));
        cpnX= norminv([1:length(Xs)].'/length(Xs));
        Ys  = sort(Y(~isnan(Y)));
        cpnY= norminv([1:length(Ys)].'/length(Ys));
        
        clear qDatX qDatY
        for fs = 1:length(fits)
            fitlimsX(fs,1:2) = quantile(Xs,[fits(fs) 1-fits(fs)]);
            qDatX(:,fs)   = Xs>=fitlimsX(fs,1) & Xs<=fitlimsX(fs,2);
            px(fs,1:2)=polyfit(Xs(qDatX(:,fs)),cpnX(qDatX(:,fs)),1);
            fx{fs}=polyval(px(fs,:),Xs(qDatX(:,fs)));
            
            fitlimsY(fs,1:2)= quantile(Ys,[fits(fs) 1-fits(fs)]);
            qDatY(:,fs)   = Ys>=fitlimsY(fs,1) & Ys<=fitlimsY(fs,2);
            py(fs,1:2)=polyfit(Ys(qDatY(:,fs)),cpnY(qDatY(:,fs)),1);
            fy{fs}=polyval(py(fs,:),Ys(qDatY(:,fs)));
        end
        
        
        % plot to compare: motivation: given enough data any difference from
        % normality can be significant. lets just look at the data and see if it
        % looks "relevantly" different
        figure
        
        ax(1) = subplot(1,2,1); hold on
        plot(Xs,cpnX,'r')
        for fs = 1:length(fits)
            xcoords = (linelims(fs,:)-px(fs,2))/px(fs,1);
            plot(xcoords,polyval(px(fs,:),xcoords),'-','LineWidth',2,'Color',cols(fs)*[1 1 1])
        end
        set(gca,'YTick',norminv([1 2 5 10 20 50 80 90 95 98 99]./100));
        set(gca,'YTickLabel',[1 2 5 10 20 50 80 90 95 98 99]);
        grid on
        ylim(norminv([.5 99.5]./100));
        xlim(quantile(Xs,[.005 .995]))
        hold on
        xlabel('Horizontal Position (°)');
        ylabel('Cumulative frequency (%)');
        
        ax(2)=subplot(1,2,2); hold on
        plot(Ys,cpnY,'r')
        for fs = 1:length(fits)
            xcoords = (linelims(fs,:)-py(fs,2))/py(fs,1);
            plot(xcoords,polyval(py(fs,:),xcoords),'-','LineWidth',2,'Color',cols(fs)*[1 1 1])
        end
        set(gca,'YTick',norminv([1 2 5 10 20 50 80 90 95 98 99]./100));
        set(gca,'YTickLabel',[]);
        grid on
        ylim(norminv([.5 99.5]./100));
        xlim(quantile(Ys,[.005 .995]))
        hold on
        xlabel('Vertical Position (°)');
        
        fh = gcf;
        fh.Position(4) = fh.Position(4)*.75;
        fh.Position(3) = fh.Position(3)*1.4;
        drawnow
        
        poss = cat(1,ax.Position);
        margin = poss(2:end,1)-(poss(1:end-1,1)+poss(1:end-1,3));
        ax(2).Position(1) = ax(2).Position(1)-margin*.6;
        
        print([dirs.results '\NieZemBeeHol_fig11_' ETs{p} '.png'],'-dpng','-r300');
        print([dirs.results '\NieZemBeeHol_fig11_' ETs{p}       ],'-depsc')
    end
end


rmpath(genpath(dirs.funclib));                 % add dirs to path
