#!/usr/bin/env Rscript
library(dplyr)
library(stringr)
library(lubridate)
source("funcs.R")
source("findData.R") # also source getinfo.R

subjs <- read.table("txt/goodsubjs.csv", sep=",", header=T)

subjs_t1_nii <-
   subjs %>%
   filter(grepl("t1_mprage", Name)) %>%
   mutate(nii = mapply(get_nii, lunadate, runno, "T1") %>% unlist,
          image_description = "structural")
# nothing missing
subjs_t1_nii %>% filter(!grepl(".nii.gz$", nii)) %>% nrow

# after making these, we should rerun get_nii
# make_missing_nii(subjs_t1_nii,'T1')

t1_software <-
   lapply(subjs_t1_nii$dir, img_info_dcmslow) %>%
   lapply(as.data.frame) %>% bind_rows

img_hard_coded <- list(
     image_orientation="Axial",
     image_num_dimensions=3
   )

# and cbind it with the other constants
imgout_t1 <-
   subjs_to_img(subjs_t1_nii, "", scan_type="MR structural (MPRAGE)") %>%
   cbind(t1_software) %>%
   cbind(img_info_nii(subjs_t1_nii$nii[1])) %>%
   cbind(img_hard_coded) %>%
   cbind(img_info_dcm(subjs_t1_nii$dir[nrow(subjs_t1_nii)]))

# write out
write.upload(imgout_t1, "image", "03",
             outfile="txt/upload/T1_fmri_upload.csv")
