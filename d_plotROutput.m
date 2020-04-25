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
cd('R');                        dirs.Rstuff     = cd;
cd ..;
cd function_library;            dirs.funclib    = cd;
cd ..;
cd results;                     dirs.results    = cd;
cd(thuisdir);
addpath(genpath(dirs.funclib));                 % add dirs to path


%% plot of R output
% NieZemBeeHol fig 8
ETlabels= {'SR EyeLink 1000Plus','SMI RED250','SMI REDm','Tobii TX300','Tobii X2-60'};

fid = fopen(fullfile(dirs.Rstuff,'myMeasures.tab'),'rt');
header = fgetl(fid);
header = strsplit(header,'\t');
dataTable = textscan(fid,'%s\t%d\t%s\t%s\t%d\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n');
fclose(fid);
dataTable = cell2struct(dataTable.',header);
% BCEA -> sqrt(BCEA)
dataTable.rBCEA = sqrt(dataTable.BCEA);

logt99  = readInRFitFile(fullfile(dirs.Rstuff,'modelResults99.log'));
logt95  = readInRFitFile(fullfile(dirs.Rstuff,'modelResults95.log'));
% we use 99 percentile data everywhere, except for fits of RED250 involving
% RMS-S2S. patch those in the log file
assert(any(strcmpi(unique({logt99.meas1}),'RMS'))&&~any(strcmpi(unique({logt99.meas2}),'RMS')))
assert(any(strcmpi(unique({logt95.meas1}),'RMS'))&&~any(strcmpi(unique({logt95.meas2}),'RMS')))
logt = logt99;
qRMS = strcmpi({logt.meas1},'RMS');
qRED = strcmpi({logt.et   },'RED250');
assert(all(qRMS==strcmpi({logt95.meas1},'RMS')))
assert(all(qRED==strcmpi({logt95.et   },'RED250')))
qAll = qRMS&qRED;
iAll = find(qAll);
for p=1:length(iAll)
    logt(iAll(p)) = logt95(iAll(p));
end
[logt(~qAll).prctiles] = deal([99 99]);
[logt(qAll).prctiles] = deal([95 95]);



% make plots, unstandardize coefficients and draw fit lines
measures = {'RMS','STD','rBCEA','Extent','RMS_STD','PSDSlope'};%,'PSDSlopeLS'};
ncomb    = size(combnk(measures,2),1);
measurest= cellfun(@(x) texlabel(x,'literal'),measures,'uni',false);
measurest{1} = '$\mbox{RMS-S2S}$';
measurest{2} = '$\mbox{STD}$';
measurest{3} = '$\sqrt{\mbox{BCEA}}$';
measurest{4} = 'magnitude';
measurest{5} = 'signal type';
measurest{6} = '$\alpha$';
measunits = repmat({'$^\circ$'},1,6); [measunits{5:6}] = deal('');
R2      = zeros(5,ncomb);
R2OLS   = zeros(5,ncomb);
for p=1:length(logt)
    % get data
    coeffs = [logt(p).l.beta.'];
    R2(p)  = logt(p).l.R2(end);
    R2OLS(p)= logt(p).l.R2(end-1);
end



%%% R^2 plot
cmap = [
005 048 097
006 050 099
007 052 102
008 054 105
009 056 108
010 058 111
011 060 114
012 062 117
013 064 120
014 067 123
015 069 126
017 071 129
018 073 132
019 075 135
020 077 138
021 079 141
022 081 144
023 084 147
024 086 149
025 088 152
026 090 155
028 092 158
029 094 161
030 096 164
031 098 167
032 100 170
033 102 172
035 104 173
036 106 174
037 108 175
039 109 176
040 111 176
041 113 177
043 115 178
044 117 179
045 118 180
047 120 181
048 122 182
049 124 183
051 125 184
052 127 185
053 129 185
055 131 186
056 132 187
057 134 188
059 136 189
060 138 190
061 139 191
063 141 192
064 143 193
065 145 194
067 147 195
070 148 196
073 150 197
076 152 198
079 154 199
082 156 200
085 158 201
088 160 202
091 162 203
094 164 204
097 166 205
101 168 206
104 170 207
107 172 208
110 174 209
113 176 210
116 178 211
119 180 213
122 182 214
125 184 215
128 186 216
132 188 217
135 190 218
138 192 219
141 194 220
144 196 221
147 197 222
149 198 223
152 200 223
154 201 224
157 202 225
159 203 225
162 205 226
164 206 227
167 207 228
169 208 228
171 210 229
174 211 230
176 212 230
179 213 231
181 215 232
184 216 232
186 217 233
189 218 234
191 220 235
194 221 235
196 222 236
199 223 237
201 225 237
204 226 238
206 227 239
209 229 240
210 229 240
211 230 240
213 231 240
214 231 241
216 232 241
217 233 241
219 233 241
220 234 242
222 235 242
223 236 242
225 236 243
226 237 243
228 238 243
229 238 243
231 239 244
232 240 244
234 241 244
235 241 244
237 242 245
238 243 245
240 243 245
241 244 246
243 245 246
244 245 246
246 246 246
247 246 246
247 245 244
247 244 242
247 243 240
248 242 238
248 240 236
248 239 234
248 238 232
249 237 231
249 236 229
249 235 227
249 234 225
249 233 223
250 232 221
250 231 219
250 229 217
250 228 215
251 227 214
251 226 212
251 225 210
251 224 208
252 223 206
252 222 204
252 221 202
252 220 200
253 219 199
252 216 196
252 214 193
251 212 190
251 210 188
251 208 185
250 206 182
250 204 180
250 202 177
249 199 174
249 197 171
249 195 169
248 193 166
248 191 163
248 189 161
247 187 158
247 185 155
247 183 153
246 180 150
246 178 147
245 176 144
245 174 142
245 172 139
244 170 136
244 168 134
244 166 131
243 163 128
242 160 126
241 158 124
239 155 122
238 152 120
237 150 118
236 147 116
235 144 114
234 142 112
232 139 110
231 136 108
230 133 106
229 131 104
228 128 101
226 125 099
225 123 097
224 120 095
223 117 093
222 114 091
221 112 089
219 109 087
218 106 085
217 104 083
216 101 081
215 098 079
214 096 077
212 093 075
211 090 074
209 087 073
208 084 071
206 081 070
205 079 069
204 076 067
202 073 066
201 070 065
199 067 063
198 064 062
197 062 061
195 059 059
194 056 058
192 053 057
191 050 055
190 048 054
188 045 053
187 042 051
185 039 050
184 036 049
182 033 047
181 031 046
180 028 045
178 025 043
176 023 042
173 022 042
170 021 041
167 020 041
164 019 040
161 018 040
158 017 039
155 016 039
153 016 039
150 015 038
147 014 038
144 013 037
141 012 037
138 011 036
135 010 036
132 009 035
129 008 035
126 007 034
123 006 034
120 005 033
117 004 033
114 003 032
111 002 032
108 001 031
105 000 031
103 000 031]./255;
fh=figure('Position',[10 40 1400 700],'PaperPositionMode','auto');
for p=1:5
    switch p
        case 1
            pos = [.1 .60 .18 .35];
        case 2
            pos = [.1+.18+.055 .60 .18 .35];
        case 3
            pos = [.1+(.18+.055)*2 .60 .18 .35];
        case 4
            pos = [.425-.18-.055/2 .12 .18 .35];
        case 5
            pos = [.425+.055 .12 .18 .35];
    end
    ax(p)=axes('Position',pos);
    title(ETlabels{p});
    xlim([ .5 6.5])
    ylim([0.5 6.5])
    axis ij
    axis square
    ax(p).XTick = 1:6;
    ax(p).YTick = 1:6;
    ax(p).XAxis.FontSize = 11;
    ax(p).YAxis.FontSize = 11;
    ax(p).TickLabelInterpreter='latex';
    ax(p).XTickLabels = measurest([1:6]);
    ax(p).XTickLabelRotation = 45;
    ax(p).YTickLabels = measurest([1:6]);
    for q=[nan 1:5 nan 6:9 nan 10:12 nan 13:14 nan 15 nan; 1:6 2:6 3:6 4:6 5:6 6; 1 1 1 1 1 1 2 2 2 2 2 3 3 3 3 4 4 4 5 5 6]
        if isnan(q(1))
            Rval = 1;
            Rvaltxt = '-';
            clr = [1 1 1];
        else
            Rval = R2(p,q(1));
            Rvaltxt = sprintf('%.2f',Rval);
            clr = interp1(linspace(0,1,256),cmap,Rval,'linear','extrap');
        end
        
        if 0.2989 * clr(1) + 0.5870 * clr(2) + 0.1140 * clr(3) < .5
            tclr = [1 1 1];
        else
            tclr = [0 0 0];
        end
        patch('XData',[-.5 .5 .5 -.5 -.5]+q(3),'YData',[.5 .5 -.5 -.5 .5]+q(2),'FaceColor',clr,'EdgeColor','none');
        
        text(q(3),q(2),Rvaltxt,'HorizontalAlignment','center','VerticalAlignment','middle','Color',tclr);
    end
    3;
end
drawnow
print(fullfile(dirs.results,'NieZemBeeHol_fig8.png'),'-dpng','-r300')

rmpath(genpath(dirs.funclib));                 % add dirs to path
