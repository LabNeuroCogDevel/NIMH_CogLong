#!/usr/bin/env Rscript
library(dplyr)
library(stringr)
library(lubridate)
source("funcs.R")
source("getinfo.R")

## prepare csv for upload
# https://ndar.nih.gov/ndarpublicweb/Documents/Tutorials/tutorial_validation-tool.mp4

# get month from birth -> visit duration
# floored: 1.9 months reported as 1 month
getmonths <- function(dob, vdate) {
   ymd(dob) %--% ymd(vdate) %/% months(1) %>% as.numeric
}

write.upload <- function(d, uptype, upver, outfile) {
 header <- sprintf('"%s","%s"\n', uptype, upver)

 # remove date part of lunaid - 20180709
 if("src_subject_id" %in% names(d) ) d$src_subject_id <- gsub("_.*","",d$src_subject_id)
 sink(outfile)
 cat(header)
 write.csv(d, row.names=F)
 sink()
}

get_nii <- function(lunadate, run, task="AS") {
   lunadate <- as.character(lunadate)
   if (task=="AS") {
    niistr <- "/Volumes/Phillips/CogRest/subjs/%s/funcs/%s/*.nii.gz"
    niistr2 <- "/Volumes/Hera/Raw/NDAR_Cog/AS/%s/%s/*.nii.gz"
    niipatt <- c(sprintf(niistr,  lunadate, run),
                 sprintf(niistr2, lunadate, run))

   } else if (task=="MS") {
    # /Volumes/Phillips/COG/11111/20130116/MS1/functional.nii.gz
    niistr <- "/Volumes/Phillips/COG/%s/MS%s/functional.nii.gz"
    niistr2 <- "/Volumes/Hera/Raw/NDAR_Cog/MS/%s/%s/*.nii.gz"
    ldslash <- gsub("_", "/", lunadate)
    niipatt <- c(sprintf(niistr,  ldslash,  run),
                 sprintf(niistr2, lunadate, run))
   } else if (task=="T1") {
    # /Volumes/Phillips/COG/11111/20130116/MS1/functional.nii.gz
    DM  <- "/Volumes/Phillips/COG/%s/MPR/mprage.nii.gz"
    FC <- "/Volumes/Phillips/CogRest/subjs/%s/t1_mprage_sag_ns_tilt_dcm224_*/mprage.nii.gz"
    WF <- "/Volumes/Hera/Raw/NDAR_Cog/T1/%s/1/*.nii.gz"
    ldslash <- gsub("_", "/", lunadate)
    niipatt <- c(sprintf(DM, ldslash),
                 sprintf(FC, lunadate),
                 sprintf(WF, lunadate))
   }

   nii <-
      niipatt %>%
      Sys.glob %>%
      head(n=1) %>%
      unlist
   if (length(nii)==0L) nii<-NA

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
subjs_to_ndar <- function(d, expid) {
    d %>%
    mutate(subjectkey=GUID,
           src_subject_id=lunadate,
           gender=sex,
           vdate=gsub(".*_", "", lunadate),
           interview_date= vdate %>%
                          ymd %>% format(format="%m/%d/%Y"),
           interview_age=getmonths(dob, vdate),
           experiment_id=expid)
}
subjs_to_img <- function(d, expid, scan_type="fMRI", dcminfo=NULL) {
   out <- d %>%
    subjs_to_ndar(expid) %>%
    mutate(image_file=nii, #paste(sep="/", dir, "*"),
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

# https://ndar.nih.gov/data_structure.html?short_name=et_subject_experiment01
subjs_to_eye <- function(d, expid) {
   d %>%
    subjs_to_ndar(expid) %>%
    mutate(data_file1 = eyd,
           data_file1_type = "ASL eye position output (eyd)",
           phenotype = "Control") %>%
    select(subjectkey, src_subject_id,
           interview_date, interview_age, gender,
           phenotype, experiment_id, data_file1,
           data_file1_type, expcond_notes)
}
