txt/guid_luna.csv: txt/PseudoGUID_Foran_260.csv
	Rscript ./00_GUID_Luna.R

txt/goodsubjs.csv: txt/guid_luna.csv
	Rscript ./01_goodsubjs.R

txt/badruns.txt:
	./remove_badruns.bash

txt/upload/AS_eye_upload.csv txt/upload/AS_fmri_upload.csv: txt/goodsubjs.csv
	Rscript ./02_AS.R

txt/upload/MS_eye_upload.csv txt/upload/MS_fmri_upload.csv: txt/goodsubjs.csv
	Rscript ./02_MGS.R

txt/upload/T1_fmri_upload.csv: txt/goodsubjs.csv
	Rscript ./02_t1.R

txt/upload_no-src-date_visit2+/AS_eye_upload.csv txt/upload_no-src-date_visit2+/AS_fmri_upload.csv txt/upload_no-src-date_visit2+/MS_eye_upload.csv txt/upload_no-src-date_visit2+/MS_fmri_upload.csv txt/upload_no-src-date_visit2+/T1_fmri_upload.csv:  txt/upload/MS_eye_upload.csv txt/upload/MS_fmri_upload.csv txt/upload/AS_eye_upload.csv txt/upload/AS_fmri_upload.csv txt/upload/T1_fmri_upload.csv
	Rscript ./04_redo_submit_no_repeat.R
