function files = parseFileNames(files)

fnames  = {files.fname}.';
[~,i]   = natsortfiles(fnames);
fnames  = fnames(i);
files   = files(i);
fnames  = regexp(fnames,'_','split');
for p=1:length(fnames)
    switch length(fnames{p})
        % AE files are 1 or 2 parts
        case 1
            files(p).tracker    = fnames{p}{1};
            if ismember(files(p).tracker,{'TX300','X260'})
                files(p).isFiltered = false;
            else
                files(p).isFiltered = true;
            end
        case 2
            files(p).tracker    = fnames{p}{1};
            files(p).isFiltered = strcmpi(fnames{p}{2},'filtered');
            
            
            % human files are 3 or 4 parts
        case 3
            files(p).tracker = fnames{p}{2};
            files(p).subj    = fnames{p}{3};
            if ismember(files(p).tracker,{'TX300','X260'})
                files(p).isFiltered = false;
            else
                files(p).isFiltered = true;
            end
        case 4
            files(p).tracker = fnames{p}{2};
            files(p).subj    = fnames{p}{3};
            files(p).isFiltered = strcmpi(fnames{p}{4},'filtered');
    end
end
