# Human pronunciation rating scale (rating_protocol_version RP1.0)

Ratings are integers. Exactly one of:

5 = Pronunciation closely matches the validated reference
4 = Minor differences, but clearly accurate
3 = Noticeable differences, but generally acceptable
2 = Major pronunciation differences
1 = Pronunciation substantially differs from the reference

No decimals, no 0, no ranges, no text values. A blank rating is permitted only when
`validation_status = unratable` and `unratable_reason` is filled.

These ratings are the independent ground truth. They are NOT converted into
Excellent / Good / Needs Improvement at any point in the dataset. Any such mapping belongs
to a later calibration stage and is recorded there, never here.
