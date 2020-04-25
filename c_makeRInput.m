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

% read in data
[files,nfiles]  = FileFromFolder(dirs.proc,[],'mat');
files           = parseFileNames(files);


%% R input file
measures = {'target','targetDist','RMS','STD','BCEA','RMS_STD','Extent','PSDSlope','PSDSlope100','PSDSlopeLS'};
measuresFile = {'target','targetDist','RMS','STD','BCEAarea1','RMS_STD','lenRMSSTD',{'PSDSlopeX','PSDSlopeY'},{'PSDSlopeX100','PSDSlopeY100'},{'PSDSlopeXLS','PSDSlopeYLS'}};
fmt      = {'d','.4f','.4f','.4f','.4f','.4f','.4f','.4f','.4f','.4f'};
fid = fopen(fullfile(thuisdir,'R','myMeasures.tab'),'wt');
% header
fprintf(fid,'subject\teye\tsubj_eye\ttracker');
fprintf(fid,'\t%s',measures{:});
fprintf(fid,'\n');
thefmt = ['%s\t%d\t%s\t%s' sprintf('\\t%%%s',fmt{:}) '\n'];
for f=1:nfiles
    if ismember(files(f).tracker,{'EL','RED250','REDm'}) && ~files(f).isFiltered
        continue
    end
    
    fprintf('%d/%d: %s\n',f,nfiles,files(f).name);
    
    dat = load(fullfile(dirs.proc,files(f).name)); dat = dat.dat;
    for e=1:2
        writeDat = cell(4+length(measures),length(dat.target));
        [writeDat{1,:}] = deal(files(f).subj);
        [writeDat{2,:}] = deal(e);
        [writeDat{3,:}] = deal([files(f).subj num2str(e)]);
        [writeDat{4,:}] = deal(files(f).tracker);
        
        for m=1:length(measuresFile)
            meas = measuresFile{m};
            if ~iscell(meas)
                meas = {meas};
            end
            temp = nan(length(meas),size(dat.(meas{1}),1));
            for c=1:length(meas)
                temp(c,:) = dat.(meas{c})(:,min(e,end));
            end
            temp = mean(temp,1,'omitnan');
            writeDat(4+m,:) = num2cell(temp);
        end
        fprintf(fid,thefmt,writeDat{:});
    end
end

rmpath(genpath(dirs.funclib));                 % add dirs to path
