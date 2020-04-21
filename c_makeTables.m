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


%% RMS and STD
% NieZemBeeHol Table 1
if 1
    ETs = unique({files.tracker});
    RMS = nan(size(ETs));
    STD = nan(size(ETs));
    for e=1:length(ETs)
        % collect data
        if ismember(ETs{e},{'EL','RED250','REDm'})
            qTrackers = strcmp({files.tracker},ETs{e}) & [files.isFiltered];
        else
            qTrackers = strcmp({files.tracker},ETs{e});
        end
        RMS(e)=nanmedian([reshape([out(qTrackers).RMS],[],1)]);
        STD(e)=nanmedian([reshape([out(qTrackers).STD],[],1)]);
    end
    [RMSs,ir] = sort(RMS);
    [STDs,is] = sort(STD);
    printDat = [ETs(ir); num2cell(RMSs); ETs(is); num2cell(STDs)];
    fprintf('%s\t%.4f\t%s\t%.4f\n',printDat{:});
end

%% amplitude spectra
% NieZemHol Table 2
if 1
    ETs = unique({files.tracker});
    PSD    = nan(length(ETs),4);
    PSD100 = nan(length(ETs),4);
    fields = {'PSDSlopeX','PSDSlopeY'; 'PSDSlopeX100','PSDSlopeY100'};
    
    for e=1:length(ETs)
        for p=1:2   % human or AE
            for f=1:2   % filtered or unfiltered
                todo = p+(f-1)*2;
                clear data;
                switch todo
                    case 1
                        % filtered human
                        if strcmp(ETs{e},'EL')
                            qFile = strcmp({files.tracker},'EL')   & [files.isFiltered];
                        elseif ismember(ETs{e},{'RED250','REDm'})
                            qFile = strcmp({files.tracker},ETs{e}) & [files.isFiltered];
                        elseif ismember(ETs{e},{'TX300','X260'})    % no filtered data for these
                            continue;
                        end
                        data = out(qFile);
                        
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
                        
                    case 4
                        % unfiltered AE
                        if strcmp(ETs{e},'EL')
                            qFile = strcmp({filesAE.tracker},'EL')   & ~[filesAE.isFiltered];
                        elseif ismember(ETs{e},{'RED250','REDm'})
                            qFile = strcmp({filesAE.tracker},ETs{e}) & ~[filesAE.isFiltered];
                        else
                            qFile = ismember({filesAE.tracker},ETs{e});
                        end
                        data = outAE(qFile);
                end
                
                for d=1:size(fields,1)
                    dat = [];
                    for g=1:size(fields,2)
                        dat = cat(1,dat,data.(fields{d,g}));
                    end
                    if d==1
                        PSD(e,todo) = nanmean(dat(:));
                    else
                        PSD100(e,todo) = nanmean(dat(:));
                    end
                end
            end
        end
    end
    
    % print
    for e=1:length(ETs)
        fprintf('%s\t%.3f\t%.3f\t%.3f\t%.3f\t\t%.3f\t%.3f\t%.3f\t%.3f\n',ETs{e},PSD(e,:),PSD100(e,:));
    end
end

%% ISI numbers
% appear in NieZemHol, section "Method / Analysis / Amplitude spectra"
if 1
    ETs = unique({files.tracker});
    for e=1:length(ETs)
        [~,~,~,~,freq] = getValByKey(lookup,ETs{e});
        if ismember(ETs{e},{'EL','RED250','REDm'})
            qTrackers = strcmp({files.tracker},ETs{e}) & [files.isFiltered];
        else
            qTrackers = strcmp({files.tracker},ETs{e});
        end
        ISI = [out(qTrackers).ISI];
        ISI = cat(1,ISI{:});
        fprintf('%s\t%.4f\t%.4f\n',ETs{e},std(ISI),std(ISI)/(1000/freq)*100);
    end
end

rmpath(genpath(dirs.funclib));                 % add dirs to path
