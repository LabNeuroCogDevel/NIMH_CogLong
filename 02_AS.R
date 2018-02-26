#!/usr/bin/env Rscript
library(dplyr)
library(stringr)
library(lubridate)
source("funcs.R")
source("getinfo.R")
source("findData.R")

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
   mutate(nii = mapply(get_nii, lunadate, runno) )

# what is missing (136 runs)
subjs_as_nii %>% filter(!grepl(".nii.gz$", nii)) %>% nrow

# make what we need and dont have
make_missing <- F
if (make_missing) {
   cmds <- subjs_as_nii %>%
      filter(is.na(nii)) %>%
      mutate(outdir=sprintf("/Volumes/Hera/Raw/NDAR_Cog/AS/%s/%s",
                            lunadate, runno),
             cmd=sprintf("dcm2niix -o %s -f %s_%%p %s", outdir, ver, dir)) %>%
      select(outdir, cmd)

   lapply(cmds$outdir, dir.create, recursive=T)
   lapply(cmds$cmd, system)
}



# software changes, but nothing else
# so get software (and matrix) for all
software <-
   lapply(subjs_as_nii$dir, img_info_dcmslow) %>%
   lapply(as.data.frame) %>% bind_rows

# and cbind it with the other constants
imgout_as <- subjs_to_img(subjs_as_nii, 831) %>%
   cbind(software) %>%
   cbind(img_info_nii(subjs_as_nii$nii[1])) %>%
   cbind(img_info_hard()) %>%
   cbind(img_info_dcm(subjs_as_nii$dir[nrow(subjs_as_nii)]))

# write out
write.upload(imgout_as, "image", "03",
             outfile="txt/upload/AS_fmri_upload.csv")

# --- AS eye files
eydout_as <-
  subjs_as %>%
  mutate(expcond_notes=ver)  %>%
  subjs_to_eye(876)

write.upload(eydout_as,
             "et_subject_experiment", "01",
             outfile="txt/upload/AS_eye_upload.csv")
