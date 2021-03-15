#!/usr/bin/env Rscript
library(LNCDR)
library(tidyr)

# 20210315WF - init
#   match WASI to uploaded for Lia Ferschmann
#   see https://www.biorxiv.org/content/10.1101/2021.02.04.429671v1.full

# this is not the file used to actually upload.
# b/c it includes visit date in src id string.
# convenient for matching to behavioral visit
upload <- read.csv("txt/upload/T1_fmri_upload.csv", skip=1) %>%
   select(subjectkey, src_subject_id, interview_age) %>%
   mutate(scan_age=round(interview_age/12, 1)) %>%
   separate(src_subject_id, c("id", "scan_date")) %>%
   mutate(scan_date = lubridate::ymd(scan_date))

wasi <- db_query("
   select id, vtimestamp as wasi_date, age as wasi_age, measures
   from visit_task natural join visit join enroll on visit.pid = enroll.pid
   where etype like 'LunaID' and task like 'WASI'") %>%
  unnestjson() %>%
  select(-matches("measures.[xy]")) %>%
  mutate(wasi_date=as.Date(wasi_date))

wasi_match <- date_match(upload, wasi, "id", "scan_date", "wasi_date", maxdatediff=Inf) %>%
   relocate("datediff.y", .after="wasi_age")

if(!dir.exists("txt/share")) dir.create("txt/share")
write.csv(wasi_match, "txt/share/wasi_coglong.csv", row.names=F)

# some CBCL was collected!
cbcl <- db_query("
   select id, vtimestamp as cbcl_date, age as cbcl_age, measures
   from visit_task natural join visit join enroll on visit.pid = enroll.pid
   where etype like 'LunaID' and task like 'CBCL'") %>%
  unnestjson() %>%
  select(-matches("measures.[xy]")) %>%
  mutate(cbcl_date=as.Date(cbcl_date))

cbcl_match <- date_match(upload, cbcl, "id", "scan_date", "cbcl_date", maxdatediff=Inf) %>%
   relocate("datediff.y", .after="cbcl_age")
# rows: 236/640. unique ids: 48/166
write.csv(cbcl_match, "txt/share/cbcl_coglong.csv", row.names=F)

# cbcl_match %>% select(id, subjectkey, scan_date, scan_age, wasi_date, wasi_age, datediff.y, )#cbclTExternal, cbclTInternal) %>% tail
