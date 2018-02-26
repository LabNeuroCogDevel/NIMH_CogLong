# R03MH113090-01 Collection for NIHM Data Archive
Longitudinal Profiles of Neurocognitive Development Through Adolescence 

collection: https://ndar.nih.gov/edit_collection.html?id=2831

## Upload
### data templates
  * MR (fmri, mprage) - [image03](https://ndar.nih.gov/data_structure.html?short_name=image03)
  * Eyetracking - [et_subject_experiment01](https://ndar.nih.gov/data_structure.html?short_name=et_subject_experiment01)

### tasks

 * MGS Encode ([mri](https://ndar.nih.gov/experiment.html?id=832&collectionId=2831), [eyetracking](https://ndar.nih.gov/experiment.html?id=887&collectionId=2831))
 * AntiState ([mri](https://ndar.nih.gov/experiment.html?id=831&collectionId=2831), [eyetracking](https://ndar.nih.gov/experiment.html?id=876&collectionId=2831))

## Local

example file locations
```
# Antistate
/Volumes/L/bea_res/Data/Tasks/AntiState/Basic/10125/20091123/Raw/EyeData/10125_2658_run4_05AV.eyd
/Volumes/Phillips/CogRest/subjs/10124_20060803/funcs/1/9VGSANTI_1.nii.gz
# MGS
/Volumes/L/bea_res/Data/Tasks/MGSEncode/Basic/10124/20060803/Raw/EyeData/10124_3400_mgsencode1.eyd
/Volumes/Phillips/COG/10124/20060803/MS1/functional.nii.gz

# Mprage
/Volumes/Phillips/COG/10124/20060803/MPR/mprage.nii.gz
/Volumes/Phillips/CogRest/subjs/10124_20060803/t1_mprage_sag_ns_tilt_dcm224_011/mprage.nii.gz

# directly from dicom (for missing)
/Volumes/Hera/Raw/NDAR_Cog/MS/1*_2*/{AS,MS,T1}/[1-4]/*.nii.gz
```

## Pubs

### MGS
* Montez, et al -- PMID: 28826493;  [10.7554/eLife.25606](https://doi.org/10.7554/eLife.25606)
* Simmonds, et al -- PMID: 28456583; [10.1016/j.neuroimage.2017.01.016](https://doi.org/10.1016/j.neuroimage.2017.01.016)

### Anti
