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
cd('AE_processed');             dirs.proc       = cd;
cd ..;
cd('AE_windows');               dirs.wins       = cd;
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
% NieZemHol Figure 2b; and
% NieZemBeeHol Figure 2b
if 1    % for each tracker, get ten data windows most similar to mean or median RMS/STD
    ETs     = unique({files.tracker});
    nFix    = 10;
    allDatSel = cell(length(ETs),10);
    for e=1:length(ETs)
        qTrackers = strcmp({files.tracker},ETs{e});
        if ismember(ETs{e},{'EL','RED250','REDm'})
            qTrackers = qTrackers & [files.isFiltered]==true;
        end
        assert(sum(qTrackers)==1)
        
        % setup windows
        [nCol,scrRes,viewDist,scrSz,freq,timeFac] = getValByKey(lookup,files(qTrackers).tracker);
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
        % now y is the window, and x the eye (first or second column)
        
        
        % select actual data
        datSel  = cell(1,length(x));
        C       = load(fullfile(dirs.wins,files(qTrackers).name)); dat = C.dat;
        for w=1:length(x)
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
    
    
    % NieZemHol Figure 2b
    if 1
        voff = [4.1 2.55 1];
        vloff= [.55 .55 .55];
        lbls = {'SR EyeLink 1000Plus','Tobii TX300','SMI RED250'};
        scale= [.02 .1 .1];
        eidx = [1 4 2];     % TX300 in middle
        pidx = [[1:3 6:7];[1:3 6:7];[1:3 6:7]];
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
        text(a(1),a(3)+0.92*a(4),'Artificial eye data','FontSize',14,'HorizontalAlignment','left','VerticalAlignment','bottom','FontWeight','bold')
        
        print([dirs.results '\NieZemHol_fig2b.png'],'-dpng','-r300')
    end
    
    
    % NieZemBeeHol Figure 2b
    if 1
        voff = [4.1 2.55 1];
        plrange= [-.05 -.151 -.10; .052 .15 .13];
        lbls = {'SR EyeLink 1000Plus','Tobii TX300','SMI RED250'};
        eidx = [1 4 2];     % TX300 in middle
        pidx = [[10];[1];[3]];
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
            set(ax,'FontSize',12)
            ax.XAxis.LineWidth = 1.5;
            ax.YAxis.LineWidth = 1.5;
            ax.YRuler.TickLabelFormat = '%.2f';
            
            % add text identifying setup
            text(0,plrange(2,e)*1.02,lbls{e},'FontSize',12,'HorizontalAlignment','left','VerticalAlignment','bottom','FontWeight','bold')
        end
        
        print([dirs.results '\NieZemBeeHol_fig2b.png'],'-dpng','-r300')
    end
end

rmpath(genpath(dirs.funclib));                 % add dirs to path
