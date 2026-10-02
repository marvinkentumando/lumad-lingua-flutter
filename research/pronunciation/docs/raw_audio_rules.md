raw/ is write-once. Files here are byte-for-byte copies of the source recordings.
Never transcode, normalise, trim, rename in place, or overwrite anything in this tree.
Corrupt files stay here and are recorded in manifests/exclusions.csv.
Reference files: raw/reference/REF_nnn.<original extension>  (every validated recording; provenance in metadata/reference_recordings.csv)
Learner files:   raw/learner/Sxxx/Sxxx_Wnnn.<original extension>  (retake after a documented technical failure: Sxxx_Wnnn_T02.<ext>, then _T03 …; the failed take stays)
Accepted learner formats (config/corpus.yaml): wav, flac (preferred); m4a, aac, mp4, 3gp, ogg, opus, mp3, amr preserved exactly as produced.
Only scripts/import_learner_audio.py writes here (copy + sha256 verification + read-only); it never overwrites an existing file.
