# Exclusion reason codes (manifests/exclusions.csv → reason_code)

| Code | Meaning |
|---|---|
| CORRUPT | File cannot be decoded |
| EMPTY | File has no audio content |
| TOO_SHORT | Recording too short to contain the target |
| CLIPPED | Severe clipping / distortion |
| NOISE | Background noise or third-party speech obscures the target |
| WRONG_ITEM | Learner produced a different item than the target |
| MULTIPLE_ATTEMPTS_IN_ONE_FILE | More than one attempt captured in a single file |
| DUPLICATE | Same content already present under another id |
| UNRATABLE | Validator could not assign a rating (reason in ratings.csv) |
| CONSENT_WITHDRAWN | Participant withdrew consent |
| OTHER | Any other documented reason (detail required) |

`stage` ∈ {collection, quality_probe, validation, preprocessing, experiment}.
`recollection_attempted` ∈ {true, false}. `decided_by` is a role code (RESEARCHER, V01), never a name.
Excluded raw files are never deleted.
