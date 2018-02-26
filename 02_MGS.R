#!/usr/bin/env Rscript
library(dplyr)
library(stringr)
library(lubridate)
source("funcs.R")
source("findData.R") # also source getinfo.R

subjs <- read.table("txt/goodsubjs.csv", sep=",", header=T)

mgs_eye_list <-
    subjs[subjs$has.MGS, "lunadate"] %>%
    unique %>%
    lapply(function(x) {
      eyd <- eydfiles(x, "MGSEncode")
      if (length(eyd)>0L){
         return(data.frame(lunadate=x, eyd=eyd))
      } else {
         return(NULL)
      }
    })

mgs_eye <-
   mgs_eye_list %>%
   bind_rows %>%
   group_by(lunadate) %>%
   mutate( runno =
              str_extract(eyd,
                          regex("\\d(?=.eyd)", ignore_case=T)) %>%
              as.numeric,
           neyd = n())

subjs_mgs <-
 mgs_eye %>%
 filter(neyd <= 3) %>%
 merge(subjs %>% filter(grepl("MGS", Name, ignore.case=T)),
       by=c("lunadate", "runno")) %>%
 mutate( image_description=sprintf("run%d", runno))

subjs_mgs_nii <-
   subjs_mgs %>%
   mutate(nii = mapply(get_nii, lunadate, runno, "MS") %>% unlist )
# nothing missing
subjs_mgs_nii %>% filter(!grepl(".nii.gz$", nii)) %>% nrow

# after making these, we should rerun get_nii
make_missing <- F
if (make_missing) {
   cmds <- subjs_mgs_nii %>%
      filter(is.na(nii)) %>%
      mutate(outdir=sprintf("/Volumes/Hera/Raw/NDAR_Cog/MS/%s/%s",
                            lunadate, runno),
             cmd=sprintf("dcm2niix -o %s -f %02d_%%p %s", outdir, runno, dir)
      ) %>%
      select(outdir, cmd)

   lapply(cmds$outdir, dir.create, recursive=T)
   lapply(cmds$cmd, system)
}


mgs_software <-
   lapply(subjs_mgs_nii$dir, img_info_dcmslow) %>%
   lapply(as.data.frame) %>% bind_rows

# and cbind it with the other constants
imgout_mgs <- subjs_to_img(subjs_mgs_nii, 832) %>%
   cbind(mgs_software) %>%
   cbind(img_info_nii(subjs_mgs_nii$nii[1])) %>%
   cbind(img_info_hard()) %>%
   cbind(img_info_dcm(subjs_mgs_nii$dir[nrow(subjs_mgs_nii)]))

# write out
write.upload(imgout_mgs, "image", "03",
             outfile="txt/upload/MS_fmri_upload.csv")

# --- MS eye files
eydout_mgs <-
  subjs_mgs %>%
  mutate(expcond_notes=paste0("run", runno))  %>%
  subjs_to_eye(887)

write.upload(eydout_mgs,
             "et_subject_experiment", "01",
             outfile="txt/upload/MS_eye_upload.csv")
