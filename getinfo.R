# hard coded values (slice timing and orientation)
img_info_hard <- function() {
   outv <- list(
     slice_acquisition=4,
     image_orientation="Axial",
     image_num_dimensions=4,
     slice_timing=gen_slice_time(29, tr=2)
   )
   return(outv)
}

img_info_dcm <- function(dcmdir, dcmpatt="/*.dcm") {
   dcm <- Sys.glob(paste0(dcmdir, dcmpatt))[[1]]
   cmd <- "dicom_hinfo -no_name -tag "
   tags <- c(
     scanner_manufacturer_pd="0008,0070",
     scanner_type_pd        ="0008,1090",
     magnetic_field_strength="0018,0087",
     mri_repetition_time_pd ="0018,0080",
     mri_echo_time_pd       ="0018,0081",
     flip_angle             ="0018,1314",
     mri_field_of_view_pd   ="0018,0094",
     patient_position       ="0018,5100",
     photomet_interpret     ="0028,0004",
     image_slice_thickness  ="0018,0050"
   )
   fullcmd <- paste(sep=" ", cmd, paste(tags, collapse=" "), dcm)
   out <- system(fullcmd, intern=T)
   outv <- as.list(strsplit(out," ")[[1]])
   nidx <- c(3:7, 10)
   outv[nidx] <- as.numeric(outv[nidx])
   names(outv) <- names(tags)
   return(outv)
}

img_info_dcmslow <- function(dcmdir, dcmpatt="/*.dcm") {
   #  scanner_software_versions_pd # 0018,1020
   #  acquisition_matrix     # 0018,1310
   dcm <- Sys.glob(paste0(dcmdir, dcmpatt))[[1]]
   cmd <- sprintf("dicom_hdr '%s'", dcm)
   res <-
    system(cmd, intern=T) %>%
    grep("Matrix|Software", ., value=T) %>%
    strsplit("//") %>%
    lapply("[", 3) %>%
    lapply(gsub, pattern="^ | $", replace="") %>%
    `names<-`(c("scanner_software_versions_pd", "acquisition_matrix"))
}


# nifti info
img_info_nii <- function(nii){
   cmd <- sprintf('3dinfo -d3 -tr "%s"', nii)
   res <- system(cmd, intern=T) %>%
          strsplit("\\t") %>%
          unlist %>% as.list %>%
   `names<-`( paste("image_resolution", 1:4, sep="") ) %>%
   append(
    list(
      image_unit1 = "Millimeters",
      image_unit2 = "Millimeters",
      image_unit3 = "Millimeters",
      image_unit4 = "Seconds"
    )
  )
}

info_all <- function(dcmdir, nii) {
 res <- Reduce(append, list(
         img_info_hard(),
         img_info_dcm(dcmdir),
         img_info_dcmslow(dcmdir),
         img_info_nii(nii)))
}


# not used -- could add all expected fields
add_missing_image03_fields <- function(d) {
   ## add missing names
   # read in all column names from template
   allnames <- names(read.csv("template/image03_template.csv", skip=1))
   missingcols <- setdiff(allnames, names(d))
   d[, missingcols] <- ""
   return(d)
}
