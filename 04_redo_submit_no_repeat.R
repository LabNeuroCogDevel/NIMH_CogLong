library(dplyr)

toredo <-c(
# "txt/upload/AS_fmri_upload.csv",
# "txt/upload/MS_fmri_upload.csv",
# "txt/upload/T1_fmri_upload.csv",
 "txt/upload/AS_eye_upload.csv",
 "txt/upload/MS_eye_upload.csv")

# src id doesnt match GUID beause src has date in it
# 1.src_subject_id remove '_.*'
# -- and becaues we already uploaded the first ---
# 2.rank by subjectkey,inteview_date
# 3.remove rank 1

redo <- function(fname) {
    odir <- "txt/upload_no-src-date_visit2+"
    if(! dir.exists(odir)) dir.create(odir)
    outfile <- file.path(odir,basename(fname))

    header <- readLines(fname,1)
    keep <-
       read.table(fname, skip=1, sep=",", header=T) %>%
       mutate(src_subject_id = gsub("_.*","", src_subject_id)) %>%
       group_by(subjectkey) %>%
       mutate(r=rank(interview_age,ties.method='min')) %>%
        filter(r<2) %>% select(-r) 

    if( 'data_file1' %in% names(keep) )
      keep$data_file1 = gsub('/bea_res/','/',keep$data_file1)
    
    sink(outfile)
    cat(sep="",header,"\n")
    write.csv(keep, row.names=F) # todo, NA should be "" for t1
    sink()
    return(outfile)
}

sapply(toredo,redo)
