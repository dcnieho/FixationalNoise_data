function logt = readInRFitFile(fitfile)
fid = fopen(fitfile,'rt');
logtxt = fread(fid,inf,'*char').';
fclose(fid);
logtxt = regexp(logtxt,'\n','split');

% parse log
varsnET = regexp(logtxt,'===== (\w+) vs (\w+) - (\w+) =====','tokens');
runidxs = [find(~cellfun(@isempty,varsnET)) length(logtxt)]; % divides up the lines

varsnET = cat(1,varsnET{runidxs});
varsnET = cat(1,varsnET{:});
logt    = struct('meas1',varsnET(:,1),'meas2',varsnET(:,2),'et',varsnET(:,3));
for p=1:length(logt)
    txt = logtxt(runidxs(p):runidxs(p+1)-1);
    % fprintf('%s\n',txt{:});
    
    % check problems
    logt(p).notIdentifiable = any(contains(txt,'Model is not identifiable'));
    
    % get model coefficients
    fixedIdx = find(strcmp(txt,'Fixed effects:'));
    outlIdx  = find(contains(txt,'n.removed = '));
    aovIdx   = find(contains(txt,'Analysis of Variance Table'));
    R2Idx    = find(contains(txt,'  R^2 Approx'));
    for q=1:length(fixedIdx)
        if q==1
            f='q';
            % noutlier
            logt(p).nOutlier = sscanf(txt{outlIdx},'n.removed = %f');
        else
            f='l';
        end
        
        
        % coeffs
        coeffs = cellfun(@strsplit,txt(fixedIdx(q)+[2:5-q]),'uni',false);
        coeffs = cellfun(@(y) cellfun(@(x) x(x~='<'),y,'uni',false),coeffs,'uni',false);    % sloop < eraf
        coeffs = cellfun(@str2double,coeffs,'uni',false);
        coeffs = cellfun(@(x) x(~isnan(x)),coeffs,'uni',false);
        coeffs = cat(1,coeffs{:});
        
        logt(p).(f).beta   = coeffs(:,1);
        logt(p).(f).betaSE = coeffs(:,2);
        logt(p).(f).df     = coeffs(:,3);
        if size(coeffs,2)>3
            logt(p).(f).t      = coeffs(:,4);
            logt(p).(f).p      = coeffs(:,5);
        end
        
        % AOV
        if any(contains(txt,'Type III Analysis of Variance Table with Satterthwaite''s method'))
            off = [2:4-q];
        else
            off = [3:5-q];
        end
        coeffs = cellfun(@strsplit,txt(aovIdx(q)+off),'uni',false);
        coeffs = cellfun(@(y) cellfun(@(x) x(x~='<'),y,'uni',false),coeffs,'uni',false);    % sloop < eraf
        coeffs = cellfun(@str2double,coeffs,'uni',false);
        coeffs = cellfun(@(x) x(~isnan(x)),coeffs,'uni',false);
        coeffs = cat(1,coeffs{:});
        logt(p).(f).AOV.sumSq    = coeffs(:,1);
        logt(p).(f).AOV.meanSq   = coeffs(:,2);
        logt(p).(f).AOV.numDF    = coeffs(:,3);
        logt(p).(f).AOV.denDF    = coeffs(:,4);
        logt(p).(f).AOV.F        = coeffs(:,5);
        logt(p).(f).AOV.p        = coeffs(:,6);
        
        % get R2 measures
        coeffs = strsplit(txt{R2Idx(q)+1});
        logt(p).(f).R2 = str2double(coeffs(2:end));
    end
    
end
