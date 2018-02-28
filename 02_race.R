library(dplyr)
source('findData.R')
subjs <- read.csv("txt/goodsubjs.csv")

# get ethnicity
sub_info <- LNCDR::db_query(conn=conn, "
with spit as (
  select pid, vtimestamp, task from visit_task
  natural join visit
  where task ilike '%spit%'
  ),
  eth as (
   select
    pid,
    sum(((measures->'Asian')='-1')::int)>0 as asian,
    sum(((measures->'Black')='-1')::int)>0 as black,
    sum(((measures->'HawaiianPacIsl')='-1')::int)>0 as HawaiianPacIsl,
    sum(((measures->'AmerIndianAlaskan')='-1')::int)>0 as AmerIndianAlaskan,
    sum(((measures->'White')='-1')::int)>0 as White
   from visit_task
   natural join visit
   where task like 'Demographics'
   group by pid
  ),
  bircpeps as (
   select distinct(pid) as pid
   from enroll
   where etype like 'BIRC'
  )
  select
     luna.id as lunaid,
      -- spit.vtimestamp as vtimestamp,
     e.asian, e.black,e.HawaiianPacIsl,e.AmerIndianAlaskan,e.White
   from bircpeps
   natural join enroll as luna
   left join eth e on e.pid=luna.pid
   -- join spit on spit.pid = luna.pid
   where luna.etype = 'LunaID'
")

eths <-
 sub_info %>%
 tidyr::gather(eth, val, -lunaid) %>% #, -vtimestamp) %>%
 filter(val) %>%
 group_by(lunaid) %>%
 summarise(race=paste(eth, collapse=","),
   #vtimestamp=paste(unique(vtimestamp), collapse=",")
 )

# ndar_subject01
# 	More than one race=6; Black or African American=BLACK; More than one race=OTHER RACE; Hawaiian or Pacific Islander=4; American Indian/Alaska Native=1; Indian/Alaska Native=AMERICAN INDIAN/ALASKAN NATIVE; Black or African American=3; White=WHITE; Asian=2; White=5; Unknown or not reported=98; Asian=ASIAN; Hawaiian or Pacific Islander=NATIVE HAWAIIAN/PACIFIC ISLANDER 
eths$race[grepl(",", eths$race)] <- "more"
eths$race[is.na(eths$race)] <- "unkown"
eths$race <- as.character(factor(eths$race,
 levels=c("more", "black", "white", "asian",
          "amerindianalaskan", "hawaiianpacisl",
          "unknown"),
 labels=c("OTHER RACE", "BLACK", "WHITE", "ASIAN",
          "AMERICAN INDIAN/ALASKAN NATIVE", "NATIVE HAWAIIAN/PACIFIC ISLANDER",
          "98") )
)

visits <-
 subjs %>%
 filter(!duplicated(lunadate)) %>%
 select(lunaid, lunadate, GUID, sex, dob) %>%
 merge(eths, by="lunaid", all.x=T) %>%
 mutate(race=ifelse(is.na(race), "98", race)) %>%
 # get interview_age (in months), rename columns
 subjs_to_ndar("") %>%
 select(subjectkey, src_subject_id, gender, interview_date,
        interview_age, race) %>%
 # and new required columns
 mutate(phenotype="Control",
        phenotype_description="no phenotype distinctions; normative sample",
        sibling_study = "No",
        family_study = "No",
)


write.upload(visits, "ndar_subject", 1, "txt/upload/race_upload.csv")

