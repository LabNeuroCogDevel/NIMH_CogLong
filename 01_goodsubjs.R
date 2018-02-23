#!/usr/bin/env Rscript

#
# create goodsubjs.csv
# - IDs: bircid, lunaid, lunadate, GUID
# - subjects with t1 dicoms
# - dicom folder (task or t1) per sequence

conn <- lncd_pgconn()
# luna id (xxxxx) vs scan (birc) id (yymmdd)
sub_info <- LNCDR::db_query(conn=conn, "
               select
                 luna.id as lunaid,
                 birc.id as bircid,
                 sex,
                 dob
               from enroll luna
               join enroll birc on
                  birc.pid=luna.pid and
                  luna.etype = 'LunaID' and
                  birc.etype ilike '%BIRC%'
               join person p on p.pid = luna.pid")

# find all cog long dicoms that might be useful
mrcon <- DBI::dbConnect(RSQLite::SQLite(), "/Volumes/Zeus/mr_sqlite/db")
mrinfo <- data.frame(tbl(mrcon, "mrinfo")) %>%
    filter(grepl("cog", study),
           grepl("antivgs|vgsanti|MGS|t1_mprage", Name, ignore.case=T) ) %>%
    filter(ndcm > 150 )

allsubj <-
   merge(mrinfo, sub_info, by.x="patname", by.y="bircid") %>%
   mutate(lunadate=paste(sep="_", lunaid, Date)) %>%
   filter(!duplicated(paste(patname, seqno, Name)))

allsubj.mrcounts <-
   allsubj %>%
   select(lunadate, lunaid, bircid=patname,
          seqno, ndcm,
          Birthdate, dob,
          sex, Name, Spacing,
          PhaseEncodingDirection, RT, ET, Flip, nRows, nColumns,
          PhaseEncodingSteps, Matrix, dir) %>%
   filter(ndcm %in% c(193, 224, 225, 229, 230, 244, 245)) %>%
   group_by(lunadate, Name) %>%
   arrange(lunadate, Name, seqno) %>%
   mutate(runno=rank(seqno), total.task=n()) %>%
   group_by(lunadate) %>%
   mutate(total.mr=n(),
          has.t1=any(grepl("t1", Name)),
          has.MGS=length(grep("MGS", Name)) == 3,
          has.AS=length(grep("Anti", Name, ignore.case=T)) == 4)

# add guid, limit to lunaids we have guids for
goodsubj <-
   read.table("txt/guid_luna.csv", sep=",", header=T) %>%
   select(lunaid, GUID=GUID.ID) %>%
   merge(allsubj.mrcounts, by="lunaid")
# will drop "10210_20060216" "10278_20060330" from guid_luna

subjs <- goodsubj %>% filter(has.t1)
# drop 10 without t1s

write.table(subjs, "txt/goodsubjs.csv", row.names=F, quote=T, sep=",")
