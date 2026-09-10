The following specific objectives, scope and limitations, and functional and non-functional requirements are as follows:

Objectives:
Develop a gamified learning system featuring multiple-choice quizzes, matching tasks, and pronunciation assessments with leaderboards, streaks, and experience points.
Develop a searchable digital dictionary that stores validated Mansaka vocabulary, translations, examples, and native-speaker audio recordings to support language preservation.
Evaluate three algorithms for pronunciation assessment to identify the most suitable model.
Generate descriptive analytics for users' learning progress, quiz performance, experience points, and pronunciation accuracy to assess learning effectiveness.
Integrate sentiment analysis of Mansaka-language Facebook posts with an interactive sentiment dashboard to visualize community sentiment polarity.
Evaluate three sentiment analysis algorithms to determine the most suitable model for classifying community sentiment.







Scope and Limitation
This study focuses on the development of LUMAD LINGUA as a cross-platform mobile application targeting the Mansaka language across a minimum of three geographic communities in Davao de Oro, aiming to document vocabulary entries and audio recordings at the beginner level. The system includes gamified learning modules with defined games (multiple-choice quizzes, matching tasks, and listening exercises), a Leitner-based spaced repetition algorithm, a pronunciation assessment module, progress tracking and points system, a searchable digital dictionary, sentiment analysis of publicly available Facebook posts written in the Mansaka language, an interactive sentiment dashboard built with a Flutter charting library, role-based user management, and a basic descriptive analytics dashboard.

The system will evaluate three algorithms for each core function: Naïve Bayes, Support Vector Machine (SVM), and Bidirectional LSTM (BiLSTM) for sentiment classification of Mansaka-language Facebook posts, with the best-performing model selected based on accuracy, precision, recall, and F1-score. For pronunciation assessment, the system will compare Dynamic Time Warping (DTW), Hidden Markov Models (HMM), and Cosine Similarity using MFCC feature extraction, selecting the optimal algorithm for mobile deployment.

The system implements an offline-first architecture using Firestore's built-in offline persistence, which locally caches previously accessed vocabulary entries, quiz content, and learning progress on the device. Learners may continue accessing cached dictionary entries and completing previously downloaded learning modules in offline mode. This offline-first behavior is particularly critical for target communities in remote areas of Mindanao where internet access is inconsistent.

The pronunciation assessment module captures the learner's spoken input via the device microphone, extracts Mel-frequency cepstral coefficients (MFCCs) from both the learner's recording and the verified native speaker reference audio, and applies the selected alignment algorithm to generate a similarity score, with a configurable tolerance threshold determining whether a learner's pronunciation is rated as Excellent, Good, or Needs Improvement. Waveform preprocessing steps include noise reduction and volume normalization applied to both the learner and reference recordings prior to feature extraction, ensuring consistent comparison results regardless of recording environment variability.

To protect linguistic content and user data, the system enforces role-based access control through Firebase Authentication custom claims, restricting write access to the designated roles and ensuring learners may only access approved content. All data transmissions between the mobile application and Firebase services are secured via HTTPS. User account credentials are encrypted through Firebase Authentication's built-in security mechanisms. Indigenous vocabulary content is documented with community co-creation protocols coordinated with NCIP-recognized tribal leaders, with intellectual property rights acknowledged through validator attribution fields within the digital archive. The system complies with the Data Privacy Act of 2012 (RA 10173) and DNSC institutional data governance policies.

The study operates within several limitations. The system implements an algorithm-based pronunciation assessment feature to evaluate user pronunciation during practice and quiz activities; however, it does not employ advanced deep-learning speech recognition models. Translation relies on structured dictionary entries uploaded and verified by the designated linguistic Validator rather than machine learning models. Sentiment classification accuracy depends on the availability and quality of publicly accessible Mansaka-language Facebook posts, mitigated by periodic review of classifier outputs by the linguistic Validator. Finally, the prototype is limited to beginner-level content primarily for the Mansaka language and is intended as a scalable digital support tool rather than a replacement for formal linguistic field research.



Functional and Non-Functional Requirements

Functional Requirements — the system shall:
The system shall persist compiled indigenous vocabulary entries for Mansaka, including the term, Filipino translation, English translation, and usage context, stored in Cloud Firestore.
The system shall host and archive audio recordings from a tribal leader to Supabase Storage, supporting digital archiving and pronunciation reference, with a maximum file size of 10 MB per recording and a minimum accepted duration of one second.
The system shall retrieve publicly available Facebook posts containing Mansaka words or phrases through the Facebook Graph API, or from verified pre-compiled secondary sources of such posts.
The system shall classify the sentiment of each post as positive, negative, or neutral using a sentiment classification algorithm.
The system shall display an interactive sentiment dashboard visualizing sentiment trends derived from analyzed Mansaka-language Facebook posts over time.
The system shall provide gamified learning modules including multiple-choice quizzes, matching tasks, and listening exercises, with a Leitner-based spaced repetition algorithm that schedules vocabulary review at increasing intervals based on learner mastery.
The system shall implement a pronunciation assessment module that extracts MFCCs from both the learner's recording and a verified reference audio, and applies dynamic time warping for alignment.
The system shall maintain a searchable digital dictionary allowing users to retrieve indigenous terms, Filipino and English translations, and associated audio samples streamed from Supabase Storage, with Firestore query results returned within 500 milliseconds under normal connectivity.
The system shall enforce role-based access control through Firebase Authentication custom claims, distinguishing between Learner, Validator, Educator, and Administrator roles, with Firestore security rules restricting access accordingly.
The system shall track learner progress through points, levels, quiz scores, completion status, and streak mechanics, stored per user profile in Firestore.
The system shall support offline-first functionality through Firestore's built-in local cache, allowing learners to access previously downloaded content without internet connectivity, with automatic synchronization upon reconnection.
The system shall generate an analytics dashboard for administrators displaying content coverage metrics and learner performance summaries aggregated from Firestore data.
The system shall conduct test assessments to measure learning effectiveness, with results stored in Firestore and accessible to administrators.


Non-Functional Requirements:
Performance. Dictionary searches shall return results within 500 milliseconds. Sentiment classification of a batch of at least 50 retrieved Facebook posts shall complete within an acceptable processing window without blocking the mobile application's user interface. Application cold start time shall not exceed three seconds on a mid-range Android device (API 21+).
Reliability. The system shall maintain a crash-free session rate of at least 95%, monitored via Firebase Crashlytics. Audio recordings stored in Supabase Storage shall be preserved without corruption or data loss.
Usability. The system shall achieve a mean usability score of at least 4.0 out of 5.0 on a standardized evaluation instrument administered to community users, including non-technical participants such as community elders and youth learners.
Security. All data transmissions shall use HTTPS. Firestore security rules shall enforce that only validated vocabulary content is accessible to Learner accounts. User credentials shall be managed through Firebase Authentication with strong password enforcement.
Compatibility. The application shall function correctly on Android devices running API level 21 and above, and on iOS devices running iOS 13 and above, using the Flutter cross-platform framework.
Maintainability. The system shall be structured using a modular Flutter architecture and Firebase console configuration to support independent updates, debugging, and feature additions without affecting unrelated system components.
Scalability. The system shall accommodate expansion to additional vocabulary entries, audio files, languages, and user accounts without significant performance degradation, leveraging Firestore's scalable document model and Supabase Storage capacity.
Availability. The system shall support offline access to cached content through Firestore's offline persistence, with online availability maintained by Firebase's managed infrastructure.




