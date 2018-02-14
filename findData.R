#!/usr/bin/env Rscript
library(dplyr)

cogrest <- "/Volumes/Phillips/CogRest/"
cog_dm  <- "/Volumes/Phillips/COG/"
bea_res <- "/Volumes/L/bea_res/Data/Tasks"

subj <-
 Sys.glob(paste0(cogrest, "subjs/1*_2*/")) %>%
 gsub(".*/([0-9]{5}_[0-9]{8})/.*", "\\1", .)

eydfiles <- function(s, task){
  gsub("_", "/", s) %>%
    sprintf("%s/%s/Basic/%s/Raw/EyeData/*eyd", bea_res, task, .) %>%
    Sys.glob %>% grep("abort", ., invert=T,value=T)
}

mrfiles <- function(s, task,file="functional.nii.gz"){
  gsub("_", "/", s) %>%
    sprintf("%s/%s/%s/%s", cog_dm, ., task,file) %>%
    Sys.glob
}

mrfiles_fc <- function(s,nii="funcs/[0-9]/9VGSANTI_*.nii.gz") {
    sprintf("%s/subjs/%s/%s", cogrest, s, nii) %>%
    Sys.glob
}
list_csv <- function(l) {
 unname(unlist(lapply(l, paste, sep=",", collapse=",")))
}


d_f <- data.frame(
  lunadate  = subj,
  ey.anti   = lapply(subj, eydfiles, "AntiState") %>% list_csv,
  ey.mgs    = lapply(subj, eydfiles, "MGSEncode") %>% list_csv,
  mr.mgs    = lapply(subj, mrfiles, "MS[1-3]") %>% list_csv,
  mr.anti   = lapply(subj, mrfiles, "AS[1-4]") %>% list_csv,
  mr.antifc = lapply(subj, mrfiles_fc) %>% list_csv,
  t1        = lapply(subj, mrfiles, "MPR", "mprage.nii.gz") %>% list_csv,
  t1.fc     = lapply(subj, mrfiles_fc, "t1_*/mprage.nii.gz") %>% list_csv
)

d_f_cnt <-
 d_f %>%
 mutate_at(vars(-lunadate),
           funs(as.character(.) %>%
                strsplit(split=',') %>%
                lapply(length) %>%
                unlist))



# ditch those who have no task data
nmgs <- unlist(lapply(mgs, length))
nanti <- unlist(lapply(antistate, length))
keep <- nmgs > 1 & nanti > 1 & (nmgs + nanti > 2)
# 149 people are ditched
subj <- subj[keep]
anti <- antistate[keep]
mgs <- mgs[keep]


## try from dicom
# library(dbplyr)
# mrcon <- DBI::dbConnect(RSQLite::SQLite(), "/Volumes/Zeus/mr_sqlite/db")
# mrinfo <- data.frame(tbl(mrcon, "mrinfo"))
# d <-
#    mrinfo %>%
#    filter(grepl("cog", study),
#           grepl("bold|t1_mprage", Name) ) %>%
#    #filter(ndcm %in% c(229, 244) ) %>%
#    filter(ndcm > 150 ) %>%
#    select(study, seqno, ndcm, Name, Date, dir)
# 
# d %>% group_by(Date) %>% summarise(n=paste(collapse=',',unique(sort(ndcm)))) %>% group_by(n) %>% summarise(dr=paste(collapse=",",range(Date)),cnt=n()) %>% arrange(cnt) %>% print.data.frame
