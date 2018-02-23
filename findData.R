#!/usr/bin/env Rscript
library(dplyr)
library(stringr)
library(lubridate)
source("funcs.R")
getmonths <- function(dob, vdate)  ymd(dob) %--% ymd(vdate) %/% months(1) %>% as.numeric

# https://ndar.nih.gov/ndarpublicweb/Documents/Tutorials/tutorial_validation-tool.mp4
write.upload <- function(d, uptype, upver, outfile) {
 header <- sprintf('"%s","%s"\n', uptype, upver)
 sink(outfile)
 cat(header)
 write.csv(d, row.names=F)
 sink()
}

get_as_nii <- function(lunadate, run, task="AS") {
   nii<-NULL
   if (task=="AS") {
    nii <- sprintf("/Volumes/Phillips/CogRest/subjs/%s/funcs/%s/*.nii.gz", lunadate, run) %>%
       Sys.glob %>%
       head(n=1) %>%
       unlist
   }
   return(nii)
}

# odd interleaved slice tiems, ucMode=0x4
gen_slice_time <- function(nslc=29, tr=2){
  nslc <- 29
  stim <- seq(0, tr - 1/nslc, length.out=nslc)
  sidx <- c(seq(1, nslc, 2), seq(2, nslc, 2))
  slicetimes <- stim[sidx]
  return(paste0("[", paste(slicetimes, collapse=", "), "]"))
}

#  01_goodsubjs.R ouptut to upload dataframe
#  expect lunadate,GUID,interview_date,dob,image_description
#  will generate interview_age and add missing columns
subjs_to_img <- function(d, expid, scan_type="fMRI", dcminfo=NULL) {
   out <-
    d %>%
    mutate(subjectkey=GUID,
           src_subject_id=lunadate,
           gender=sex,
           vdate=gsub(".*_", "", lunadate),
           interview_date= vdate %>%
                          ymd %>% format(format="%m/%d/%Y"),
           interview_age=getmonths(dob, vdate),
           image_file=nii, #paste(sep="/", dir, "*"),
           experiment_id=expid,
           scan_type=scan_type,
           scan_object="Live",
           image_file_format="NIFTI", #"DICOM",
           image_modality="MRI",
           transformation_performed="No") %>%
    select(subjectkey, src_subject_id, gender, interview_date, interview_age,
          image_file, image_description, experiment_id, scan_type, scan_object,
          image_file_format, image_modality, transformation_performed)

    return(out)
}




# created by 01_goodsubjs.R
# has all IDS -  one row per dicom directory
subjs <- read.table("txt/goodsubjs.csv", sep=",", header=T)

antistate_eye_list <-
    subjs[subjs$has.AS, "lunadate"] %>%
    unique %>%
    lapply(function(x) {
      eyd <- eydfiles(x, "AntiState")
      if (length(eyd)>0L){
         return(data.frame(lunadate=x, eyd=eyd))
      } else {
         return(NULL)
      }
    })

antistate_eye <-
   antistate_eye_list %>%
   bind_rows %>%
   group_by(lunadate) %>%
   mutate( runno = str_extract(eyd, regex("(?<=run)\\d", ignore_case=T)) %>%
                                  as.numeric,
           ver = str_extract(eyd, regex("(?<=_)[0-2]?[0-9][AVav][AVav]")) %>%
                 toupper,
           neyd = n())

antistate_eye %>% filter(is.na(ver)|neyd!=4|is.na(runno)) %>% print.data.frame
# 10361/20061111 has 6!
# 0136/20090716 - no 4, 10152/20080806 - no 2; 10173_20140524 - no 1

# merge good subjects with good antistate by run and id
subjs_as <-
 antistate_eye %>%
 filter(neyd <= 4) %>%
 merge(subjs %>% filter(grepl("Anti", Name, ignore.case=T)),
       by=c("lunadate", "runno")) %>%
 mutate( image_description=sprintf("run%d;%s", runno, ver))

subjs_as_nii <-
   subjs_as %>%
   mutate(nii = get_as_nii(lunadate, runno) )
# nothing missing
subjs_as_nii %>% filter(!grepl('.nii.gz$',nii)) %>% nrow


# software changes, but nothing else
# so get software (and matrix) for all
software <-
   lapply(subjs_as_nii$dir,img_info_dcmslow) %>%
   lapply(as.data.frame) %>% bind_rows

# and cbind it with the other constants
imgout_as <- subjs_to_img(subjs_as_nii, 831) %>%
   cbind(software) %>%
   cbind(img_info_nii(subjs_as_nii$nii[1])) %>%
   cbind(img_info_hard()) %>%
   cbind(img_info_dcm(subjs_as_nii$dir[nrow(subjs_as_nii)]))

# write out
write.upload(imgout_as, "image", "03", outfile="AS_upload.csv")

## again for mgs






##### OLD
eyefiles <- sapply(subjs$lunadate, eydfiles, "AntiState")
# -- build list
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


d_f_cnt <- cntcommas(d_f)

mgs.missing <- d_f_cnt %>%
   filter( t1 + t1.fc != 0, mr.mgs == 0, ey.mgs != 0 ) %>%
   tidyr::separate(lunadate, c("luna", "date")) %>%
   mutate(bircdatepart=substr(date, 3, 8)) %>%
   select(luna, date, bircdatepart)


## find all dcms
mrinfo %>%
  filter(study %in% c("coglongbirc", "coglong"),
         ( (Name == "ep2d_bold_MGS" & ndcm == 229) |
           (grepl("AntiVGS|VGSAnti", Name, ignore.case=T)) &
            ndcm %in% c(244, 245))) %>%
  mutate(bircdatepart=substr(id, 0, 6)) %>%
  merge(mgs.missing, by="bircdatepart") %>%
  select(luna, date, id, dir) %>%
  tidyr::unite("lunadate", luna, date) %>%
  group_by(id) %>%
  arrange(dir)




## try to find mgs dicoms

mgs.found <-
  mrinfo %>%
  filter(study %in% c("coglongbirc", "coglong"),
         Name == "ep2d_bold_MGS",
         ndcm == 229) %>%
  mutate(bircdatepart=substr(id, 0, 6)) %>%
  merge(mgs.missing, by="bircdatepart") %>%
  select(luna, date, id, dir) %>%
  tidyr::unite("lunadate", luna, date) %>%
  group_by(id) %>%
  arrange(dir)

# make sure only one birc partial per lunaid
badidmatch <-
   mgs.found %>% ungroup %>%
   group_by(lunadate) %>%
   summarise(n=length(unique(id))) %>% filter(n!=1)
if (length(badidmatch) != 0L) stop(badidmatch)

# add new dcms, and recalc d_f_cnt
mgs.dcm <-
   mgs.found %>%
   group_by(lunadate) %>%
   summarise(mgs.dcm=paste(collapse=",", unique(dir)) )
d_f_dcm <- merge(d_f, mgs.dcm, by="lunadate", all=T)
d_f_cnt <- cntcommas(d_f_dcm)
