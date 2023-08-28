#!/usr/bin/env Rscript
library(dplyr)
library(tidyr)
source('findData.R') # write.upload

#tmpl <- read.csv('template/cantab01_template.csv')
cantab_stat <- read.csv('txt/btc_R03cleaneddata_20220306.outlierremoved.compositeacclat.csv')
# required: subjectkey, src_subject_id, interview_date, interview_age, sex
upload <- read.csv("txt/upload/T1_fmri_upload.csv", skip=1) %>%
   select(subjectkey, src_subject_id, interview_age) %>%
   mutate(scan_age=round(interview_age/12, 1)) %>%
   separate(src_subject_id, c("id", "scan_date")) %>%
   mutate(scan_date = lubridate::ymd(scan_date))

cantab <- read.csv('txt/CogCANTAB_20190128.csv') %>%
   mutate(MOT.Accuracy = 100 - MOT.Mean.error,
          interview_age=Age,
          sex=substr(Gender,1,1),
          interview_date=format(lubridate::mdy_hms(Session.start.time), "%m/%d/%Y"),
          d8=format(lubridate::mdy_hms(Session.start.time), "%Y%m%d"),
          src_subject_id=stringr::str_extract(Subject.ID,'\\d{5}')
   ) %>% 
   merge(upload %>% select(src_subject_id=`id`, subjectkey) %>% distinct,
         by='src_subject_id',
         all=FALSE) %>%
   group_by(src_subject_id, interview_date) %>% filter(Session..==max(Session..)) %>% ungroup() %>%
   merge(cantab_stat %>% select(`id`,d8, matches('SOC')),
         by.x=c("src_subject_id","d8"),
         by.y=c("id","d8"),
         suffixes=c("",".stats"),
         all.x=T) %>%
   mutate(SOC.Overallmeaninitialthinkingtime.sec = SOC.Overallmeaninitialthinkingtime/1000)

# want to populate
#  cantab1 	Float 		Recommended 	Motor Screening: Mean Response Latency 		ms 	
#	cantab2 	Float 		Recommended 	Motor Screening: Accuracy 	0::100 	Percent correctly pointed to 
#
# 	cantab6 	Float 		Recommended 	Spatial memory span: Length of memory span 		longest sequence successfully recalled
#	cantab7 	Integer 		Recommended 	Spatial memory span: Total Errors
#	cantab8 	Integer 		Recommended 	Spatial memory span: Total Usage Errors
#	cantab9 	Float 		Recommended 	Spatial memory span: Mean Latency
#
# 	cantab22 	Integer 		Recommended 	Stockings of Cambridge: Number of moves 			
#	cantab24 	Integer 		Recommended 	Stockings of Cambridge: Problems solved in minimum moves 			
#	cantab25 	Float 		Recommended 	Stockings of Cambridge: Mean initial thinking time 		seconds 	
#	cantab26 	Float 		Recommended 	Stockings of Cambridge: Subsequent thinking time across all levels 		seconds 	
#	cantab27 	Float 		Recommended 	Stockings of Cambridge: Mean subsequent thinking time 
#
# 	dmspc 	Float 		Recommended 	Delated Matching to Sample task (DMS) Percent Correct: The percentage of assessment trials during which the subject chose the correct box on their first box choice. Calculated across all assessed trials (simultaneous presentation and all delays). 

lookup <- c("cantab1"="MOT.Mean.latency",
            "cantab2"="MOT.Accuracy",
            "cantab6"="SSP.Span.length", 
            "cantab7"="SSP.Total.errors",
            "cantab8"="SSP.Total.usage.errors",
            "cantab9"="SSP.Mean.time.to.first.response",
            "cantab22"="", # Number of moves 
            "cantab24"="SOC.Problems.solved.in.minimum.moves",
            "cantab25"="SOC.Overallmeaninitialthinkingtime.sec",
            "cantab26"="", #  Subsequent thinking time across all levels (seconds)
            "cantab27"="SOC.Overallmeansubsequentthinkingtime",
            "dmspc"="DMS.Percent.correct",
            "dmstcad"="DMS.Total.correct..all.delays.")


lookup_have <- Filter(\(x) x!="", lookup)

# named lookup_have will rename columns too!
cantab_upload <- cantab %>% select(subjectkey, interview_age, sex, interview_date, src_subject_id, !!lookup_have)
write.upload(cantab_upload,
             "cantab", "01",
             outfile="txt/upload/cantab01.csv")
