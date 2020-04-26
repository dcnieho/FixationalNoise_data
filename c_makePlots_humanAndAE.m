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
cd('AE_windows');           dirs.winsAE     = cd;
cd ..;
cd('AE_processed');         dirs.procAE     = cd;
cd ..;
cd('human_windows');        dirs.wins       = cd;
cd ..;
cd('human_processed');      dirs.proc       = cd;
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
[filesAE,nfilesAE]  = FileFromFolder(dirs.procAE,[],'mat');
filesAE             = parseFileNames(filesAE);
for f=1:nfilesAE
    fprintf('%d/%d: %s\n',f,nfilesAE,filesAE(f).name);
    
    temp = load(fullfile(dirs.procAE,filesAE(f).name));
    outAE(f) = temp.dat;
end


%% amplitude spectra
% NieZemHol Figures 5, 6 and 7
if 1
    yLims       = [0.000065718377755 2.256982615782695];
    yLimsLTicks = [floor(log10(yLims(1))) ceil(log10(yLims(2)))];
    ETs         = unique({files.tracker});
    subs        = {'ss1','ss2','ss3','ss4'};
    fnames      = {};
    for e=1:length(ETs)
        for p=1:2   % human or AE
            for f=1:2   % filtered or unfiltered
                todo = p*10+f;
                clear data;
                whichSub = [1:4];
                switch todo
                    case 11
                        % filtered human
                        figNum = 5;
                        if strcmp(ETs{e},'EL')
                            qFile = strcmp({files.tracker},'EL')   & [files.isFiltered];
                        elseif ismember(ETs{e},{'RED250','REDm'})
                            qFile = strcmp({files.tracker},ETs{e}) & [files.isFiltered];
                        elseif ismember(ETs{e},{'TX300','X260'})    % no filtered data for these
                            continue;
                        end
                        data = out(qFile);
                        
                        condlbl = 'human_filt';
                        qYlabel = true;
                        
                    case 12
                        % unfiltered human
                        if strcmp(ETs{e},'EL')
                            qFile = strcmp({files.tracker},'EL')   & ~[files.isFiltered];
                            whichSub = [1 4];   % get coloring correct
                            figNum = 6;
                        elseif ismember(ETs{e},{'RED250','REDm'})
                            qFile = strcmp({files.tracker},ETs{e}) & ~[files.isFiltered];
                            figNum = 7;
                        else
                            qFile = ismember({files.tracker},ETs{e});
                            figNum = 5;
                        end
                        data = out(qFile);
                        
                        condlbl = 'human_unfilt';
                        qYlabel = true;
                        
                    case 21
                        % filtered AE
                        figNum = 5;
                        if strcmp(ETs{e},'EL')
                            qFile = strcmp({filesAE.tracker},'EL')   & [filesAE.isFiltered];
                        elseif ismember(ETs{e},{'RED250','REDm'})
                            qFile = strcmp({filesAE.tracker},ETs{e}) & [filesAE.isFiltered];
                        elseif ismember(ETs{e},{'TX300','X260'})    % no filtered data for these
                            continue;
                        end
                        data = outAE(qFile);
                        
                        condlbl = 'AE_filt';
                        qYlabel = false;
                        
                    case 22
                        % unfiltered AE
                        if strcmp(ETs{e},'EL')
                            qFile = strcmp({filesAE.tracker},'EL')   & ~[filesAE.isFiltered];
                            figNum = 6;
                        elseif ismember(ETs{e},{'RED250','REDm'})
                            qFile = strcmp({filesAE.tracker},ETs{e}) & ~[filesAE.isFiltered];
                            figNum = 7;
                        else
                            qFile = ismember({filesAE.tracker},ETs{e});
                            figNum = 5;
                        end
                        data = outAE(qFile);
                        
                        condlbl = 'AE_unfilt';
                        qYlabel = false;
                end
                
                if ismember(todo,[11 12])
                    xSlopes=cat(3,data.PSDX);
                    xSlopes=num2cell(xSlopes,[1 2]);    % take left and right eye, all windows, together, per participant
                    xSlopes=squeeze(cellfun(@(x) nanmean(cat(2,x{:}),2),xSlopes,'uni',false));
                    xSlopes=cat(2,xSlopes{:});
                    ySlopes=cat(3,data.PSDY);
                    ySlopes=num2cell(ySlopes,[1 2]);    % take left and right eye, all windows, together, per participant
                    ySlopes=squeeze(cellfun(@(x) nanmean(cat(2,x{:}),2),ySlopes,'uni',false));
                    ySlopes=cat(2,ySlopes{:});
                else
                    xSlopes=nanmean(cat(2,data.PSDX{:}),2);
                    ySlopes=nanmean(cat(2,data.PSDY{:}),2);
                end
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
                clear h1 h2
                for a=1:size(xSlopes,2)
                    ax.ColorOrderIndex = whichSub(a);
                    h1(a)=loglog(PSDf(1:end-1),sqrt(xSlopes(1:end-1,a)),'-','LineWidth',1.5,extra{:});
                end
                for a=1:size(ySlopes,2)
                    ax.ColorOrderIndex = whichSub(a);
                    h2(a)=loglog(PSDf(1:end-1),sqrt(ySlopes(1:end-1,a)),'--','LineWidth',1.5,extra{:});
                end
                ax.XScale = 'log';
                ax.YScale = 'log';
                axis tight
                xLim = ax.XLim;
                ax.YLim = yLims;
                ax.XLim = xLim;
                if qYlabel
                    ylabel('Amplitude (deg/Hz)')
                end
                if (contains(condlbl,'unfilt')||contains(condlbl,'nofilt')) && ismember(ETs{e},{'EL','REDm','X260'})
                    xlabel('Frequency (Hz)')
                    % all the below shit because adding a label subtly changes
                    % the height of the drawable part of the axis...
                    drawnow
                    xlblPos     = ax.XLabel.Position;
                    xlblFontSz  = ax.XLabel.FontSize;
                    xlabel('')
                    text(xlblPos(1),xlblPos(2),'Frequency (Hz)','HorizontalAlignment','center','VerticalAlignment','top','FontSize',xlblFontSz)
                end
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
                
                if p==1
                    % human data legend
                    lh=legend(h1,subs{whichSub},'Location','SouthWest');
                else
                    % AE data legend
                    lh=legend([h1 h2],'X','Y','Location','SouthWest');
                end
                lh.Box = 'off';
                
                fnames{end+1} = ['NieZemHol_fig' num2str(figNum) '_' ETs{e} '_' condlbl '.png'];
                print(fullfile(dirs.results,fnames{end}),'-dpng','-r300')
            end
        end
    end
    
    % not cut off white edges
    % cut out code
    plaat = cell(size(fnames));
    for p=1:length(fnames)
        plaat{p} = imread(fullfile(dirs.results,fnames{p}));
    end
    % find out how much can trim from each side for each image
    pix = plaat{1}(1,1,:);
    trims = nan(length(plaat),4);
    for p=1:length(plaat)
        qBackGround = all(plaat{p}==pix,3);
        qHori = all(qBackGround,1);
        qVert = all(qBackGround,2);
        % left
        trims(p,1) = find(~qHori,1);
        % right
        trims(p,2) = find(~qHori,1,'last');
        % top
        trims(p,3) = find(~qVert,1);
        % bottom
        trims(p,4) = find(~qVert,1,'last');
    end
    allTrim = [min(trims(:,1)) max(trims(:,2)) min(trims(:,3)) max(trims(:,4))];
    % now trim them all and save
    for p=1:length(plaat)
        im = plaat{p}(allTrim(3):allTrim(4),allTrim(1):allTrim(2),:);
        imwrite(im,fullfile(dirs.results,fnames{p}));
    end
end

%% type vs alpha
% NieZemBeeHol Figure 9
if 1
    figure('Units','normalized','Position',[0 .1 1 0.7])
    simulation = load(fullfile(dirs.proc,'..','type_vs_alpha_simul.mat'));
    ETs = unique({files.tracker});
    legs = {'AE unfiltered', 'AE filtered','human unfiltered','human filtered'};
    ax(1) = subplot(2,3,1);
    plot(simulation.slopes,simulation.ratios.','LineWidth',1);
    tlegs = arrayfun(@num2str,simulation.N,'uni',false);
    lh=legend(tlegs{:},'Location','SouthWest');
    legend boxoff
    lh.FontSize = 10;
    text(-3.75,0.96,'Number of samples','HorizontalAlignment','left','VerticalAlignment','bottom','FontName',ax(1).YAxis.Label.FontName,'FontSize',11);
    ylabel('signal type','interpreter','latex')
    xlim([-4 4])
    ylim([0 2])
    box off
    title('simulation')
    set(ax(1),'FontSize',12)
    ax(1).XAxis.LineWidth = 1.5;
    ax(1).YAxis.LineWidth = 1.5;
    ax(1).YAxis.TickLabelFormat = '%.1f';
    text(ax(1).YLabel.Extent(1)+ax(1).YLabel.Extent(3)/2,sum(ax(1).Title.Extent([2 4])),'A','FontWeight','bold','FontSize',15,'HorizontalAlignment','center','VerticalAlignment','top')
    for e=1:length(ETs)
        ax(e+1) = subplot(2,3,e+1); hold on
        qTrackers = strcmp({files.tracker},ETs{e});
        [~,~,~,~,~,~,plotIdx,lim] = getValByKey(lookup,ETs{e});
        
        ht = plot(simulation.slopes,simulation.ratios(plotIdx,:),'k','LineWidth',2);
        qHave = true(1,4);
        theET = ETs{e};     % for raw files, and label
        if strcmpi(theET,'RED500')
            theET = 'RED250';
        end
        for p=1:4
            clear data;
            switch p
                case 1
                    % unfiltered AE
                    if strcmp(ETs{e},'EL')
                        qFile = strcmp({filesAE.tracker},'EL')   & ~[filesAE.isFiltered];
                    elseif ismember(ETs{e},{'RED250','REDm'})
                        qFile = strcmp({filesAE.tracker},ETs{e}) & ~[filesAE.isFiltered];
                    else
                        qFile = ismember({filesAE.tracker},ETs{e});
                    end
                    data = outAE(qFile);
                    design = {'o','Color',[1 0 0],'MarkerFaceColor',[1 0 0]};
                case 2
                    % filtered AE
                    if strcmp(ETs{e},'EL')
                        qFile = strcmp({filesAE.tracker},'EL')   & [filesAE.isFiltered];
                    elseif ismember(ETs{e},{'RED250','REDm'})
                        qFile = strcmp({filesAE.tracker},ETs{e}) & [filesAE.isFiltered];
                    elseif ismember(ETs{e},{'TX300','X260'})    % no filtered data for these
                        continue;
                    end
                    data = outAE(qFile);
                    design = {'s','Color',[1 .5 0],'LineWidth',1.5};
                case 3
                    % unfiltered human
                    if strcmp(ETs{e},'EL')
                        qFile = strcmp({files.tracker},'EL')   & ~[files.isFiltered];
                    elseif ismember(ETs{e},{'RED250','REDm'})
                        qFile = strcmp({files.tracker},ETs{e}) & ~[files.isFiltered];
                    else
                        qFile = ismember({files.tracker},ETs{e});
                    end
                    data = out(qFile);
                    design = {'o','Color',[0 0 1],'MarkerFaceColor',[0 0 1]};
                case 4
                    % filtered human
                    if strcmp(ETs{e},'EL')
                        qFile = strcmp({files.tracker},'EL')   & [files.isFiltered];
                    elseif ismember(ETs{e},{'RED250','REDm'})
                        qFile = strcmp({files.tracker},ETs{e}) & [files.isFiltered];
                    elseif ismember(ETs{e},{'TX300','X260'})    % no filtered data for these
                        continue;
                    end
                    data = out(qFile);
                    design = {'s','Color',[0 .6 1],'LineWidth',1.5};
            end
            
            if isempty(data)
                qHave(p) = false;
                continue;
            end
            
            % get X and Y PSD slopes
            xSlopes = reshape([data.PSDSlopeX],[],1);
            ySlopes = reshape([data.PSDSlopeY],[],1);
            slopes  = mean([xSlopes ySlopes],2);
            % get RMS/STDs
            RMSSTDs = reshape([data.RMS_STD],[],1);
            h(p) = plot(slopes,RMSSTDs,design{:},'MarkerSize',3);
            
            
            set(ax(e+1),'FontSize',12)
            ax(e+1).XAxis.LineWidth = 1.5;
            ax(e+1).YAxis.LineWidth = 1.5;
            ax(e+1).YAxis.TickLabelFormat = '%.1f';
            
            text(ax(1).YLabel.Extent(1)+ax(1).YLabel.Extent(3)/2,sum(ax(1).Title.Extent([2 4])),char('A'+e),'FontWeight','bold','FontSize',15,'HorizontalAlignment','center','VerticalAlignment','top')
        end
        
        if e==3
            lh = legend([ht h(qHave)],'simulated',legs{qHave},'Location','SouthWest');
            legend boxoff
            lh.FontSize = 10;
        end
        if e==3
            ylabel('signal type','interpreter','latex')
        end
        if e>=3
            xlabel('scaling exponent ($\alpha$)','interpreter','latex')
        end
        xlim([-4 4])
        ylim([0 2])
        switch theET
            case 'EL'
                titlbl = 'SR EyeLink 1000Plus';
            case 'RED250'
                titlbl = 'SMI RED250';
            case 'REDm'
                titlbl = 'SMI REDm';
            case 'TX300'
                titlbl = 'Tobii TX300';
            case 'X260'
                titlbl = 'Tobii X2-60';
        end
        title(titlbl)
    end
    
    print([dirs.results '\NieZemBeeHol_fig9.png'],'-dpng','-r300')
    close
end

%% RMS-STD space plots
% NieZemBeeHol Figure 10
% RMS/STD version of NieZemHol Figure 5, 6 and 7
if 1
    fac = [1.05 1.15];
    ETs = unique({files.tracker});
    refLines = [sqrt(2)];
    refLinClr= {'g'};
    refLineAng= atan(refLines);
    for e=1:length(ETs)
        [~,~,~,~,~,~,plotIdx,lim] = getValByKey(lookup,ETs{e});
        for p=1:2   % human or AE
            for f=1:2   % filtered or unfiltered
                todo = p*10+f;
                clear data;
                whichSub = [1:4];
                switch todo
                    case 11
                        % filtered human
                        figNum = 5;
                        if strcmp(ETs{e},'EL')
                            qFile = strcmp({files.tracker},'EL')   & [files.isFiltered];
                        elseif ismember(ETs{e},{'RED250','REDm'})
                            qFile = strcmp({files.tracker},ETs{e}) & [files.isFiltered];
                        elseif ismember(ETs{e},{'TX300','X260'})    % no filtered data for these
                            continue;
                        end
                        data = out(qFile);
                        
                        condlbl = 'human_filt';
                        
                    case 12
                        % unfiltered human
                        if strcmp(ETs{e},'EL')
                            qFile = strcmp({files.tracker},'EL')   & ~[files.isFiltered];
                            whichSub = [1 4];   % get coloring correct
                            figNum = 6;
                        elseif ismember(ETs{e},{'RED250','REDm'})
                            qFile = strcmp({files.tracker},ETs{e}) & ~[files.isFiltered];
                            figNum = 7;
                        else
                            qFile = ismember({files.tracker},ETs{e});
                            figNum = 5;
                        end
                        data = out(qFile);
                        
                        condlbl = 'human_nofilt';
                        
                    case 21
                        % filtered AE
                        figNum = 5;
                        if strcmp(ETs{e},'EL')
                            qFile = strcmp({filesAE.tracker},'EL')   & [filesAE.isFiltered];
                        elseif ismember(ETs{e},{'RED250','REDm'})
                            qFile = strcmp({filesAE.tracker},ETs{e}) & [filesAE.isFiltered];
                        elseif ismember(ETs{e},{'TX300','X260'})    % no filtered data for these
                            continue;
                        end
                        data = outAE(qFile);
                        
                        condlbl = 'AE_filt';
                        
                    case 22
                        % unfiltered AE
                        if strcmp(ETs{e},'EL')
                            qFile = strcmp({filesAE.tracker},'EL')   & ~[filesAE.isFiltered];
                            figNum = 6;
                        elseif ismember(ETs{e},{'RED250','REDm'})
                            qFile = strcmp({filesAE.tracker},ETs{e}) & ~[filesAE.isFiltered];
                            figNum = 7;
                        else
                            qFile = ismember({filesAE.tracker},ETs{e});
                            figNum = 5;
                        end
                        data = outAE(qFile);
                        
                        condlbl = 'AE_unfilt';
                end
                
                clf
                [axLines,rLblDist] = polar_hist_plot(gca,lim,fac); hold on
                % draw reflines
                for l=1:length(refLines)
                    plot([0 lim*fac(2)*cos(refLineAng)],[0 lim*fac(2)*sin(refLineAng)],refLinClr{l},'LineWidth',1.5);
                end
                % get data
                input=[reshape([data.STD],[],1), reshape([data.RMS],[],1)];
                qNaN = any(isnan(input),2);
                
                % get 2D kde
                [bandwidth,density,X,Y]=kde2d(input(~qNaN,:),2^9,[0 0],[lim lim]);
                % draw data
                % 1. set densities beyong plot limit to 0
                density(hypot(X,Y)>lim) = 0;
                % 2. threshold
                md = max(density(:));
                levels = linspace(0,md,16);
                % plot
                contourf(X,Y,density,levels(2:end),'LineStyle','none');  % remove lowest level
                
                % 1D RMS/STD histogram in outer ring
                RMS_STD = input(:,2)./input(:,1);
                [~,density,x]=kde(RMS_STD,2^14,0);
                levels = linspace(0,max(density),16);
                qRemove = density<levels(2);
                density(qRemove) = [];
                x(qRemove) = [];
                density = density/max(density)*md;  % scale to same range as 2D density plot, so same color map does the trick
                th = atan(x);
                % turn into patches on the outer ring
                rin = lim*fac(1);
                rout= lim*fac(2);
                X = [rout*cos(th(1:end-1)); rout*cos(th(2:end)); rin*cos(th(2:end)); rin*cos(th(1:end-1))];
                Y = [rout*sin(th(1:end-1)); rout*sin(th(2:end)); rin*sin(th(2:end)); rin*sin(th(1:end-1))];
                xSlopes = [density(1:end-1)       density(2:end)       density(2:end)      density(1:end-1)].';
                patch(X,Y,xSlopes,'FaceColor','interp','EdgeColor','none')
                
                % make up
                % just X and Y axis
                xlabel('STD (°)')
                ylabel('RMS-S2S (°)')
                % polar axis label
                ax=gca;
                rLblDist = rLblDist*1.07;
                polLblLoc = [1 1].*rLblDist*sqrt(2)/2;
                polLbl = 'signal type';
                h = text(polLblLoc(1),polLblLoc(2), polLbl,'HorizontalAlignment','center','VerticalAlignment','middle','FontName',ax.YAxis.Label.FontName,'FontSize',ax.YAxis.Label.FontSize);
                len = h.Extent(3);
                delete(h);
                baseRot = -34.5;
                poss = conv(linspace(0,len,length(polLbl)+1),[.5 .5],'valid')-len/2;  % character centers. Assume characters equally wide, works for this specific label :)
                angs = poss./(2*pi*rLblDist*.85)*360+baseRot;
                hh = text(cosd(angs)*rLblDist,-sind(angs)*rLblDist, num2cell(polLbl),'HorizontalAlignment','center','VerticalAlignment','middle','FontName',ax.YAxis.Label.FontName,'FontSize',ax.YAxis.Label.FontSize);
                set(hh,{'Rotation'},num2cell(-(90+angs)).')
                % color
                cmap = DNcolormap2(64)./255;
                colormap(cmap);
                % legend
                if 1
                    cpos = [.23 .55 .035 .2];
                    cax = axes('Position',cpos);
                    % put value axis only on right
                    yyaxis right
                    cax.YAxis(1).Visible = 'off';
                    cax.YAxis(2).Color = [0 0 0];
                    cax.XAxis.Visible = 'off';
                    cax.YLim = [0 size(cmap,1)];
                    cax.XLim = [0 1];
                    % draw the heatmap
                    for c=1:64
                        patch([0 1 1 0],c-1+[0 0 1 1],cmap(c,:),'EdgeColor','none');
                    end
                    cax.YAxis(2).TickDirection = 'out';
                    cax.YAxis(2).TickValues = [0 32 64];
                    cax.YAxis(2).TickLabels = {'low','medium','high'};
                    text(0,68,'Density','Parent',cax,'HorizontalAlignment','left','VerticalAlignment','bottom')
                end
                % axis lines to top
                uistack(axLines,'top')
                
                if strcmp(ETs{e},'EL')
                    print([dirs.results '\NieZemBeeHol_fig10_' ETs{e} '_' condlbl '.png'],'-dpng','-r300')
                end
                if ~isfolder(fullfile(dirs.results,'NieZemHol_fig5,6,7 using RMS_STD'))
                    mkdir(fullfile(dirs.results,'NieZemHol_fig5,6,7 using RMS_STD'));
                end
                print(fullfile(dirs.results,'NieZemHol_fig5,6,7 using RMS_STD',['NieZemHol_fig' num2str(figNum) '_' ETs{e} '_' condlbl '.png']),'-dpng','-r300')
            end
        end
    end
end



rmpath(genpath(dirs.funclib));                 % add dirs to path
