#!/usr/bin/env Rscript

# create guid_luna.csv
# 170 luna ids, assigned to the first guid's given

# all subjects in cog_fc (rest)
# this is what we care about
subj_fcrest <-
 Sys.glob("/Volumes/Phillips/CogRest/subjs/1*_2*/") %>%
 gsub(".*/([0-9]{5}_[0-9]{8})/.*", "\\1", .)

# remove dates
lunas <- unique(gsub("_.*", "", subj_fcrest))

# read in assigned psuedo GUIDs
guid <- read.table("txt/PseudoGUID_Foran_260.csv", sep=",", header=T)
# assing lunas to GUIDs
guid_luna <- guid[1:length(lunas), ]
guid_luna$lunaid <- lunas
# write out
write.table(guid_luna, "txt/guid_luna.csv", sep=",", quote=F, row.names=F)
