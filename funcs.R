require(dplyr)

### find things
cog_fc <- "/Volumes/Phillips/CogRest/"
cog_dm  <- "/Volumes/Phillips/COG/"
bea_res <- "/Volumes/L/bea_res/Data/Tasks"

# find (task) eye files, task might be MGSEncode or AntiState
eydfiles <- function(s, task){
  gsub("_", "/", s) %>%
    sprintf("%s/%s/Basic/%s/Raw/EyeData/*eyd", bea_res, task, .) %>%
    Sys.glob %>% grep("abort", ., invert=T, value=T)
}
# find DM's mr files
mrfiles <- function(s, task, file="functional.nii.gz"){
  gsub("_", "/", s) %>%
    sprintf("%s/%s/%s/%s", cog_dm, ., task, file) %>%
    Sys.glob
}

# find FC's mr files
mrfiles_fc <- function(s, nii="funcs/[0-9]/9VGSANTI_*.nii.gz") {
    sprintf("%s/subjs/%s/%s", cog_fc, s, nii) %>%
    Sys.glob
}
# turn list into comma sep. string
list_csv <- function(l) {
 unname(unlist(lapply(l, paste, sep=",", collapse=",")))
}

# count all commas, ignore lunadate column
cntcommas <- function(d_f) {
  d_f_cnt <-
   d_f %>%
   mutate_at(vars(-lunadate),
             funs(as.character(.) %>%
                  strsplit(split=",") %>%
                  lapply(length) %>%
                  unlist))
}
