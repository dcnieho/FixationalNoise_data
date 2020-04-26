# set cwd to location of this file
pwd = 'C:\\dat\\projects\\noiseTypeExtent\\data_code_release\\data_release\\R'

cat('---')

qToFile = TRUE

# run once with param set to .99 and name to modelResults99.log
# and once with param set to .95 and name to modelResults95.log
if (FALSE) {
    toRemove = .99
    fname = 'modelResults99.log'
} else {
    toRemove = .95
    fname = 'modelResults95.log'
}

if (qToFile) {
    con <- file(file.path(pwd,fname))
    sink(con, append = TRUE)
    sink(con, append = TRUE, type = "message")
}
options(width = 160)

library(lmerTest)
library(LMERConvenienceFunctions)
source(file.path(pwd,'multilevel_effect_size_function.r'))


measures = c('RMS', 'STD', 'rBCEA', 'Extent', 'RMS_STD', 'PSDSlope')

# read in data, set columns of interest as factors, or center them where needed
data <- read.table(file.path(pwd,'myMeasures.tab'), sep = "\t", head = TRUE)
data$tracker = factor(data$tracker)
data$subj_eye = factor(data$subj_eye)
data$rBCEA = sqrt(data$BCEA)
# make sure nans are coded correctly
for (m in measures) {
    data[[m]][is.na(data[[m]])] <- NA
}

# generate all combinations of measures
combs = t(combn(measures, 2))
colnames(combs) = c('measure1', 'measure2')

IQRoutlierFun <- function(dat) {
    outThresh = 2.
    dat > quantile(dat, .25) - outThresh * IQR(dat) & dat < quantile(dat, .75) + outThresh * IQR(dat)
}

# do stats
for (i in 1:nrow(combs)) {
    # (i in c(6)) {
    for (et in levels(data$tracker)) {
        #et in c('hispeed240')) {
        cat('=====', combs[i, 1], 'vs', combs[i, 2], '-', et, '=====\n')

        # setup model
        # this produces something like RMSCent ~ STDCent + I(STDCent^2) + (STDCent + I(STDCent^2) | subj_eye)
        f = as.formula(paste(combs[i, 1], 'Cent ~ 1 + ', combs[i, 2], 'Cent + I(', combs[i, 2], 'Cent^2) + (1 | subj_eye)', sep = ''))
        f2 = as.formula(paste(combs[i, 1], 'Cent ~ 1 + ', combs[i, 2], 'Cent + (1 | subj_eye)', sep = ''))

        # get data and center+standardize
        dat = data[data$tracker == et & complete.cases(data[[combs[i, 1]]]) & complete.cases(data[[combs[i, 2]]]) & complete.cases(data$RMS),] # select eye tracker, remove missing. Use RMS as a standard for missing (PSD sometimes available more)
        for (m in combs[i, ]) {
            dat[[paste(m, 'Cent', sep = '')]] = dat[[m]] - mean(dat[[m]], na.rm = TRUE)
            dat[[paste(m, 'Stand', sep = '')]] = (dat[[m]] - mean(dat[[m]], na.rm = TRUE)) / sd(dat[[m]], na.rm = TRUE)
        }
        
        # simply remove top 1% from data for each et
        n1 = nrow(dat)
        dat = dat[dat[[combs[i, 1]]] < quantile(dat[[combs[i, 1]]], toRemove) & dat[[combs[i, 2]]] < quantile(dat[[combs[i, 2]]], toRemove),]
        cat('n.removed =', n1 - nrow(dat), '\n')
        cat('formula =', as.character(f)[c(2,1,3)], '\n')
        # run it - with quadratic
        lme1 = lmer(f, data = dat, REML = F, control = lmerControl(optimizer = "bobyqa"))
        print(summary(lme1))
        print(anova(lme1))
        cat('\n\n')

        # get R^2 outputs - skip
        print(multilevel.effect.size(lme1))
        cat('\n\n')

        # run it - without quadratic
        cat('formula =', as.character(f2)[c(2,1,3)], '\n')
        lme2 = lmer(f2, data = dat, REML = F, control = lmerControl(optimizer = "bobyqa"))
        print(summary(lme2))
        print(anova(lme2))
        cat('\n\n')

        # get R^2 outputs
        print(multilevel.effect.size(lme2))

        cat('\n\n\n\n')
    }
    cat('\n\n\n\n\n\n')
}


if (qToFile) {
    # Restore output to console
    sink()
    sink(type = "message")
}
