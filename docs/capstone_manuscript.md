LUMAD LINGUA: A GAMIFIED LANGUAGE LEARNING PLATFORM WITH SENTIMENT ANALYSIS FOR THE MANSAKA LANGUAGE



Presented to the
Institute of Computing
Davao del Norte State College
Panabo City, Davao del Norte



In Partial Fulfillment
of the Requirements for the Degree
BACHELOR OF SCIENCE IN INFORMATION TECHNOLOGY


AIRES JHOY GIVEROLA
KATHY CLAIRE LAURETO
MARVIN KEN TUMANDO

JUNE 2026
CHAPTER 1
INTRODUCTION

Background of the Study
Language plays a major part in cultural identity, traditions and ancestral knowledge. Ethnologue states [1] that around 3,226 of the total number of languages can be described as endangered being spoken in the world now – which is about 44%. The Philippines is among the countries with the richest linguistic diversity at the same time being one of the most endangered nations in the Asia-Pacific region. In Mindanao indigenous languages, like Mansaka, are seriously endangered as the amount of people speaking the language is decreasing from generation to generation [2]. According to the NCIP, transmission rates are very low in most of the Lumad communities [3]. Language disappearance is not just the disappearance of words and grammar. It means destruction of such things as oral traditions, ecological knowledge systems, customs and traditions. Indigenous languages may present unique cognitive systems that will not be found in the languages of dominant cultures [4], [5].
The ongoing attempts to address the problem are still inadequate. Government steps like Mother Tongue-Based Multilingual Education (MTB-MLE) policy according to DepEd Order No. 16, s.2012 [6] help promote the use of indigenous languages in the education system but still the failure to fill the gaps in instructional resources, training for teachers, and digital documentation leads to the inefficiency of conservation efforts in a fragmented manner [7]. Along with this act, the passage of Republic Act No. 12027 made the use of MTB-MLE compulsory during the period of kindergarten and grades 1-3 no longer mandatory, thus, making it optional for monolingual classes and possibly ignoring minority languages like Mansaka in schools. Existing documentation methods like SayMore are either desktop or mobile while missing the elements like training and interactive learning [8], and the Endangered Languages Project does not have any implementation modules or feedback data on indigenous languages at the community level in the Philippines [9].
Advancements in mobile technology and Sentiment Analysis show a transformative opportunity to bridge this gap. The sentiment analysis of publicly shared social media content enables the assessment of community attitudes toward the Mansaka language, allowing for the identification of "engagement gaps" and the tracking of community sentiment in real-time [10]. Furthermore, gamified learning has emerged as high-engagement strategy for language acquisition.Through integrating levels, feedback loops, and progress tracking, gamified learning reduces the "affective filter", the anxiety often associated with learning a language, and sustains motivation among younger users [11]. A centralized mobile platform that merges these feedback-driven documentation tools with interactive pedagogy creates a scalable solution for linguistic preservation [12].
Grounded in the United Nations Sustainable Development Goal 4 (Quality Education), which advocates for inclusive, equitable, and culturally responsive education, this study proposes LUMAD LINGUA: A Documentation and Gamified Learning Platform for the Mansaka Language. In addition, the proposed system supports the DNSC RDE Agenda 2026–2030 by promoting ICT for Development (ICT4D) and preserving regional heritage through the digital documentation and learning of the Mansaka language. As outlined in the CHED A.C.H.I.E.V.E. Agenda 2030 [13], the study aligns by supporting accessible lifelong learning, research and innovation, and the use of digital technologies in education. Moreover, it is consistent with the DOST Harmonized National R&D Agenda (HNRDA) 2022–2028 by applying sentiment analysis, data analytics, and mobile technologies to preserve indigenous languages and address community needs through digital innovation. By technologizing the Mansaka language through this platform, this study aims to create a digital stronghold for Mindanao's cultural heritage that is both academically rigorous and community-driven.



Objectives of the Study
The main aim of this research is to develop the cross-platform mobile application that is going to integrate indigenous language preservation, sentiment analysis, and gamification in learning systems. The main goals of this research include:
Develop a gamified learning system featuring multiple-choice quizzes, matching tasks, and pronunciation assessments with leaderboards, streaks, and experience points.
Develop a searchable digital dictionary that stores validated Mansaka vocabulary, translations, examples, and native-speaker audio recordings to support language preservation.
Evaluate three algorithms for pronunciation assessment to identify the most suitable model.
Generate descriptive analytics for users' learning progress, quiz performance, experience points, and pronunciation accuracy to assess learning effectiveness.
Integrate sentiment analysis of Mansaka-language Facebook posts with an interactive sentiment dashboard to visualize community sentiment polarity.
Evaluate three sentiment analysis algorithms to determine the most suitable model for classifying community sentiment.









Significance of the Study
This research adds value to the nexus between information technology and cultural heritage preservation and education. Below are some of the beneficiaries of the platform;
Indigenous Communities (Mansaka). The proposed platform will serve as the central repository where the heritage languages can be sorted, saved and made retrievable. Most importantly, the development of the content will involve cooperation between community elders and leaders recognized by the NCIP, which will ensure that the content development reflects linguistic heritage and protects the indigenous intellectual property rights. Through this approach of validation, the proposed platform becomes a community-oriented tool as opposed to an external archive.
Youth and Students. The game based activities will help young people in Lumad communities deal with the cognitive and motivational challenges in learning languages. Currently, there are no digital means of indigenous language learning available to them. Through this platform, the use of points, tracking of progress and interactive quizzes will attract the age group 8-25, whose decreasing interest in indigenous languages has led to the breakdown of intergenerational communication.
Language Educators and Researchers. The digital dictionary and structured lesson modules offer ready-to-use resources for educators. For researchers and linguists, sentiment analysis of Facebook posts in Mansaka language provides a quantitative measure of the community’s attitudes and engagement towards the language which can help in more focused revitalization efforts.
Government Agencies (NCIP, DepEd, LGUs). Interactive sentiment dashboards capturing community sentiment trends from Mansaka-language Facebook activity, thereby informing agencies in identifying communities that require priority intervention and the distribution of educational resources.

Scope and Limitations
This study aims to develop LUMAD LINGUA as a cross-platform mobile application to cater to the Mansaka language in at least three geographic regions in Davao de Oro. This application would be aimed towards documenting the vocabulary entries and audio recordings of the Mansaka language at the beginner level. The system would be designed to include learning games (multiple choice questions, match-the-pair games, and audio listening) on a Leitner-based spaced repetition algorithm along with a pronunciation assessment module, points and tracking system, digital dictionary with search capability, sentiment analysis of public Facebook posts in the Mansaka language, sentiment dashboard utilizing the Flutter charting library, role-based management of users, and a basic descriptive analytics dashboard.
The system is designed to evaluate the performance of three different algorithms for each of its core functionalities such as Naïve Bayes, Support Vector Machine (SVM) and Bi-directional Long Short-Term Memory (BiLSTM) for sentiment classification of the Mansaka-language Facebook posts, based on their accuracy, precision, recall, and F1 score. For pronunciation assessment, the system would be evaluating Dynamic Time Warping (DTW), Hidden Markov Model (HMM) and Cosine Similarity based on MFCC feature extraction algorithm.
The application utilizes an offline-first approach through the use of Firestore's built-in offline persistence, where the app stores locally any previously accessed vocabularies, quizzes, and learners' learning activities. The learners can still be able to access the dictionary entries stored in cache, as well as complete learning activities that were previously downloaded even when operating in offline mode. An offline-first approach becomes especially crucial for our target communities in remote locations in Mindanao where internet connectivity is not very reliable.
In addition, the pronunciation evaluation component records the learner's utterances using the device's microphone, analyzes the MFCCs of the learner's audio recording and the native speaker's audio reference, and uses the alignment algorithm to calculate the similarity score, after which a configurable tolerance level determines the learner's pronunciation result as either Excellent, Good, or Needs Improvement. Audio preprocessing includes the removal of noise and normalization of the volume of the learner and reference audio recordings before computing their MFCC features.
In order to safeguard the linguistic information and learner information, the system implements role-based access controls using Firebase Authentication custom claims, ensuring that only the assigned roles have the write capabilities, and ensuring that learners can only gain access to authorized information. The exchange of information from the mobile app to the Firebase services is secured using HTTPS. The authentication of users' login information is carried out using encryption techniques provided by Firebase Authentication. The indigenous language vocabulary is documented following the community co-creation protocols in collaboration with tribal leaders recognized by NCIP, and acknowledging their intellectual property rights using validators in the digital archive.
There are many limitations that the research is bound to adhere to. For instance, the system uses an algorithm-based pronunciation assessment component to analyze the pronunciation of users while they carry out their practice or quiz exercises; but the system does not make use of deep learning algorithms for speech recognition. The translation process in this case makes use of the dictionaries created and validated by the linguistic Validator and not machine learning algorithms. For sentiment classification, the accuracy of the results will be limited by the availability of publicly available posts in the Mansaka language in Facebook sites. Finally, the prototype focuses on beginner-level materials mainly for the Mansaka language.





Review of Related Literature and Works
Related Literature
The emergence of LUMAD LINGUA is located at the convergence of digital humanities, sentiment analysis and natural language processing, and educational technology. The literature below presents the theoretical bases behind the merging of these disciplines for the purposes of revitalizing indigenous languages.
The move towards mobile documentation is a stark deviation from the conventional linguistic fieldwork. Contemporary documentation paradigms place high importance on "Digital Vitality" – the concept measuring how successfully the language survives in terms of creating its existence in digital environments [14]. Contemporary literature claims that, for the language to remain viable, it needs to be available in a portable interface with multimedia metadata [15]. Cloud-based relational databases provide the means to gather fragmented oral histories in one archive [16]. Moreover, Community-Based Language Research (CBLR) gives an opportunity to turn native speakers into participants rather than mere subjects of documentation.It has been observed that the use of mobile devices by community members for data collection provides increased volumes of authentic data than those collected through academic interviews [18]. It has been noted in current technological trends that the key feature of an archive is its ability to provide data interoperability, whereby the information collected on one device is easily migrated across global archives [19], [20]. Also, it is noted in offline first data synchronization literature that feedback-based documentation services should ensure that no information collected gets lost without internet access [26].
Taken together, the findings mentioned above make the community-coordinated data submission module of LUMAD LINGUA highly relevant to our research problem, where the Validator collects information about Mansaka vocabulary and phonetic data from native speakers. This information is stored in Firestore and versioned accordingly.

Sentiment analysis has brought about an innovative development in the field of humanities because of its ability to inject sentiment insights into cultural data. Linguists can use sentiment classification to better comprehend the social and psychological issues that affect language viability [21]. Sentiment analysis using social media platforms will enable the researchers to monitor the sentiment in real-time within public posts and comments, and present community engagement sentiments visually using sentiment dashboards [22] which are important in discovering communities where the language interest has gone down [23]. The recent improvements in open source NLP libraries have facilitated the development of lightweight sentiment analysis applications that operate with minimal hardware constraints [24], which is directly applicable to the various indigenous communities of Mindanao that inhabit regions with unreliable internet connections [25].
At the algorithmic level, the application of Naïve Bayes in the study by Bilog [44], which employed Naïve Bayes to analyze 300,000 Filipino, English, and Taglish Facebook comments and attained 77% accuracy surpassing the results of SentiWordNet and Logistic Regression on the same dataset, is relevant to LUMAD LINGUA's task, in addition to the study by Indriani et al. [46] where Naïve Bayes outperformed KNN, Decision Tree, and Multi-Layer Perceptron in analyzing a small corpus of 200 tweets on Twitter. Moreover, the study by Hasan et al. [45] where classical algorithms like SVM were compared with deep learning and transformer models in Bengali sentiment classification was found to perform competitively, although with significantly less amount of data needed to achieve that than deep learning models require. However, the study by Shanmugavadivel et al. [49], where a CNN+BiLSTM hybrid model was applied to classify Tamil-English code-mixed tweets and attained only 66% accuracy is another indication that neural sequence models are data-intensive.
The studies above serve as references for selecting LUMAD LINGUA's algorithm for sentiment analysis, which classifies publicly available Mansaka-language Facebook posts to extract candidate vocabulary and assess community engagement via sentiment analysis dashboard.
Mobile-Assisted Language Learning (MALL) has become the main trend among the languages which have no official representation in classrooms [28]. It is the gamification – the use of game design elements such as levels and points – that has made the MALL so successful [29]. Studies show that gamification decreases the "affective filter" – the emotional barrier caused by fear of failure [30], and is particularly good at involving the 15-25 age group – future carriers of linguistic tradition [34]. Besides engagement design, the use of Spaced Repetition System (SRS) through mobile applications makes sure that the vocabulary review takes place at the appropriate intervals and thus helps retain the information for longer [33], following the Leitner scheduling system [51].
These sources provide a justification for gamified teaching methods used in the LUMAD LINGUA app – multiple choice test, matching exercise and audio task set up in accordance with the Leitner method of spaced repetition and its scoring system based on points, consecutive successes and some levels specifically designed to attract young learners.
Technical research on Computer-Assisted Language Learning (CALL) emphasizes the significance of visual-acoustic feedback for phonetic learning. The possibility of waveform comparison enables learners to visualize their voice in comparison with a recording from a native speaker [31], and visual-acoustic feedback appears to be much more efficient in phonetic learning than mere text feedback [32]. Tsai [42] proves that explicit directing of learners' attention to computerized visual cues leads to greater intonational success, which proves the efficiency of waveform feedback interface. Moreover, Khaustova et al. [43] confirm that Dynamic Time Warping (DTW) technology still plays its role in pronunciation assessment in spite of the current technological level, especially in combination with accent adaptation technique for non-native speakers.
In fact, such comparative results have been shown before: for instance, according to Kumar [47], DTW performed better in recognizing isolated words in Punjabi language compared to HMM models (accuracy: 94.0% vs. 91.3%), and Miodonska et al. [48] also concluded that DTW provided a better pronunciation error rate and worked faster than HMM models (0.287 vs. 0.473). These findings help to justify the use of the pronunciation assessment functionality in LUMAD LINGUA system, which uses MFCC extraction from learner and target recordings and then uses DTW alignment to calculate similarity and visualize waveforms with Flutter CustomPainter class.
For the Philippines, there have been logistic problems related to MTB-MLE, one of which includes the shortage of localized online material [35]. The literature review from the Davao area has shown that indigenous communities are interested in online representation, but they are lacking platforms that would make it possible [36]. Furthermore, research conducted in Mindanao indicates that there is a need for "technologizing" of the indigenous identity with the help of mobile applications that incorporate specific cultural features [37]. Modern research proves that culturally appropriate mobile interventions, such as digital dictionary applications created with the participation of tribal elders, are appreciated by native speakers of Mindanao [38]. In order to ensure effective preservation, software should take into account the issues related to intellectual property as well as the necessity to meet practical needs of the community, including offline usage [39]. At present, it becomes clear that the only way to preserve language in the digital natives generation is to integrate digital archiving with interactive pedagogy [40], [41]. The Svelmoe and Svelmoe Mansaka Dictionary [50] is currently the most significant linguistic resource on Mansaka, emphasizing its importance and scarcity at the same time.
The aforementioned localized evidence base supports both the community co-creation approach employed by LUMAD LINGUA, whereby content is created and verified through collaboration with NCIP-recognized tribal leaders from at least three Davao de Oro communities, and the offline-first design choice that responds to the problem of limited connectivity highlighted in the Mindanao-specific literature.
From the five aforementioned pieces of literature, a clear pattern can be identified: documentation requires a portable and community-based form of archiving, sentiment analysis proves to work best with light-weight classical models, MALL and gamification provide us with techniques of engaging learners, CALL research proves that DTW-based pronunciation feedback is the most feasible method in a mobile, low-resource environment, and the Mindanao-specific literature shows that there is both a need for and a lack of localized platform available. No other system incorporates all five aspects mentioned above to support an indigenous Philippine language. LUMAD LINGUA solves the above-mentioned problem by incorporating the four aforementioned components into one system that works with the Mansaka language.

Related Works
Due to the endangerment of languages, there have been several language learning and documentation systems developed. These systems normally have capabilities such as archiving and metadata management, but most lack any built-in feature for sentiment analysis or interactive pedagogy. Even though these global platforms are accessible, they lack community validation and gamification which are integral to the process of intergenerational transfer.
The following table is a comparative analysis between the existing system and the new platform.

Table 1. Comparison of existing systems vs. the proposed system.
System
Mobile app Platform
Digital Archiving
Sentiment Analysis
Digital Dictionary
Gamified Learning
Pronunciation Assessment
Community Validation
Manual / Paper Documentation












✓
Duolingo
✓




✓
✓
✓


FirstVoices
✓
✓


✓




✓
LUMAD LINGUA (Proposed)
✓
✓
✓
✓
✓
✓
✓


In light of the comparative analysis of Table 1, although individual functions of various tools exist, there has been no tool created with complete integration for the purposes of the Mansaka language. For instance, Duolingo remains the market leader for the aspects of Gamified Learning and Pronunciation Assessment; however, this tool does not have Digital Archiving and Community Validation needed for preservation of endangered languages. In addition, it does not cover dialects of Mindanao indigenous peoples.
FirstVoices, in turn, has become the representative of Digital Archiving and Community-Centered Metadata with the help of public registration of data for languages documentation; however, this tool does not have important elements, such as gamified modules.
Thus, LUMAD LINGUA combines gamification approach of Duolingo and digital archiving and community-centered standards of FirstVoices. Specifically, Sentiment Analysis is included in order to measure community and learners' engagement. It allows LUMAD LINGUA to be an effective and scientifically justified platform for revitalization of Philippine indigenous heritage.





Definition of Terms
Cross-Platform Development. Describes the approach (such as using Flutter or React Native) whereby the application can be used across Android and iOS devices through one codebase.
Digital Dictionary. The electronic dictionary in the platform used for finding meanings of words and phrases in the Mansaka language and pronunciation of the words.
Educator. This is a qualified individual in teaching the indigenous languages in the platform, which can be an Elder, a linguist of the Mansaka language, or a language learning specialist of Philippine indigenous languages.
Gamification. It is the use of game-design elements in the learning modules, such as quizzes and vocabulary tests.
Learner Feedback. The feedback collected from the users of the platform, who are learners, for usability testing and evaluation of the effectiveness and reliability of the technical aspects of the platform.
Lumad. The collective term used for the non-Muslim indigenous people of Mindanao, such as the Mansaka, whose language is being documented and revitalized through this project.
LUMAD LINGUA. This term is used in relation to the name of the proposed mobile documentation and learning platform that will be created for the preservation and revitalization of certain indigenous languages in Mindanao.
Mansaka. Term that refers to an indigenous population of the Philippines located mainly in the Davao Region (Davao de Oro and Davao del Norte) that is chosen as the main subjects of the documentation and learning modules.
MTB-MLE (Mother Tongue-Based Multilingual Education). Term that refers to the educational policy in the Philippines that aims at using a learner’s native language as the first language of instruction, which will be promoted by means of the proposed platform.
Pronunciation Assessment. This feature refers to a system feature that assesses a user’s pronunciation performance by means of comparing his or her speech sample against reference recordings by means of waveform-based feedback.
Sentiment Analysis. This term refers to the process of classification of public Facebook posts made in the Mansaka language according to the sentiments expressed in the post (positive, negative, or neutral).
Sentiment Dashboard. Data visualization interface used in the platform to demonstrate sentiment trends according to the analyzed Facebook posts in the Mansaka language.
Validator. It refers to the assigned linguistic expert who uploads, documents, and verifies the vocabularies and sound recordings within the system. It is the responsibility of the system to assign a validator so that the content is representative of linguistic standards of the languages.
Waveform. It refers to the visual presentation of an audio signal which is used within the system to help the user in improving his/her pronunciation by comparing it visually.








CHAPTER 2
METHODOLOGY

Project follows the Hybrid Project Management Methodology that mixes both structural and flexible aspects of Waterfall and Agile shown in Figure 1. The structural Waterfall process is employed at early stages to make sure that proper planning and definition and documentation of requirements takes place in order to prepare all outputs before starting the project, such as project proposal and design of the system. Flexible aspects of Agile are applied while implementing and testing the system by repeating iterations of development and testing of the system's functions, including sentiment analysis, gamification and other components. Following the hybrid approach allows to achieve balance between structure and flexibility in managing processes with static and dynamic components.
Project development starts from the Planning phase, during which the scope of the project, objectives, schedule, and resources that should be employed according to the approved project proposal are identified. This phase determines the general direction of the project and its viability. The next phase is the Analysis phase. In this phase, proponents analyze the requirements of the system by studying documentation of the current languages and identifying user requirements.
During the Design stage, the supporters developed the ideals into a system architecture, including the design of the Firestore database, mock-ups of the user interface, and system moments diagrams. In the Implementation stage, the proponents implemented the system according to the Agile process which consisted of two-week sprints that lasted between ten and fourteen days. This process started with a sprint planning session during which deliverables were identified and then continued with development and unit tests and finally a sprint review and sprint retrospective. Sprint cycles were set according to important aspects of the system which included the collection of the data from Facebook, conducting of sentiment analysis, executing gamified learning modules and Leitner technique and pronunciation assessment. It is due to this iterative process that the team managed to develop the features step-by-step and resolve the problems found during the development of the system.
Within the Maintenance phase, the proponents conduct the system assessment, identify any issues and recommend the improvements that can boost the efficiency of the process. As for the Post-deployment maintenance phase, the proponents constantly check Firebase Crashlytics for crash-free session ratio and abnormal rise in errors. The following is done on a quarterly basis: optimization of Firebase Firestore indexes and removal of the old rejected/pending documents. The following is done on a monthly basis: checking of the audio recordings and vocabulary entries for language correctness, updating of the Firebase Security rules, Flutter dependencies update, and Firebase SDK versions update. Feedback from the validators and learners is gathered via post-deployment surveys and serves as a basis for quarterly interface upgrades. All maintenance activities are recorded in the maintenance log which is managed by the project team and reviewed by the academic supervisor on a semesterly basis.








Figure 1. Integrated Hybrid Project Management Approach



SYSTEM PLANNING
Project Team Organization

Project team organization that is necessary for a proper work process organization and task execution is shown in Figure 2. Besides project management, adviser provides participation in a scientific part of the project. The process is supervised by the project manager who is responsible for planning the implementation of the project. Firebase functionality is developed and integrated with Flutter by mobile developer. Requirements for an application are set by UI/UX and Flutter developers.






Figure 2. Project Management Team Organization


Work Breakdown Structure

As illustrated in Figure 3, the WBS (Work Breakdown Structure) is the phase-wise breakdown of the project that adheres to the PADIM model. The tasks related to each phase of the system development process have been outlined clearly. All of Planning, Analysis, Design, Implementation, and Maintenance have been broken down through it and thus, helps in systematically overseeing the progress of the project. In order to ensure that all necessary tasks have been accounted for and accomplished, each of these phases has further been broken down into various tasks including requirement development, system design, development, testing, and evaluation. Community coordination for Mansaka vocabulary collection, setting up Firebase project, Flutter development, Facebook data collection and sentiment analysis processing, gamified module development, and pronunciation assessment have all been included in the Lumad Lingua project.




Figure 3. Work Breakdown Structure



Gantt Chart

A timeline and schedule of activities for the development of Lumad Lingua can be seen in the Gantt chart of Figure 4, which matches the activities using the PADIM model. In order to make sure that all activities, such as requirement formulation, system design, Firebase setup, Flutter application development, sentiment analysis pipeline development, gamification module development, content acquisition and verification, testing, and deployment, are completed within the available timeframe, the Gantt chart illustrates the order and duration of each phase, starting from Planning and Analysis to Design, Implementation, and Maintenance phases. The Gantt chart helps the proponents complete their capstone project efficiently through effective time management and monitoring of their activities.

Figure 4. Gantt Chart of the System








SYSTEM ANALYSIS

System Architecture
System Architecture illustrated in Figure 5 provides a systematic structure that highlights how different components of Lumad Lingua come together to facilitate gamified learning, sentiment-based vocabulary discovery, digital language documentation, and content validation. In general, the three main layers that constitute the architecture are client layer (Flutter mobile application), backend layer (Firebase and Supabase services), and external services (Facebook Graph API and hardware).
The architecture uses a cross-platform mobile application that is designed using Flutter and Dart on iOS and Android devices as the client layer. Learner, Validator, Administrator, and Educator are the four key user roles in the system. Entering new vocabulary entries and their audio recordings and validating all the entries submitted by learners is the responsibility of the Validator who is either a professional linguist or a community tribal leader that unifies documentation and quality assurance into one community trustable role.
The components that make up the application include Cloud Firestore that is used to store vocabulary terms, user data, validation data, version history data, gamification data, sentiment classification data, and quiz results, Firebase Authentication for role-based access control, and Supabase Storage for audio file management. The processing done on the server side such as sentiment analysis, scoring computations, and analytics collection is done using Firebase Cloud Functions.
Whereas there are pre-compiled secondary sources of Facebook posts with Mansaka terms and phrases made public, the sentiment analysis process uses those posts to retrieve them. To understand what people's sentiments are about the language, the retrieved posts are translated into Filipino and English languages and sorted according to sentiment classification. The digital dictionary's fields for terms, translations, and context are populated with Mansaka terms that have been identified through the retrieval process, their translations, and context.
For the external services, there is the Facebook Graph API for data retrieval of sentiment and device microphone for audio recording for pronunciation assessment using the flutter_sound package.




Figure 5. System Architecture of the Project




Functional and Non-functional Requirements
The functional and non-functional requirements provide the criteria of the expected functionalities and quality characteristics of the proposed Lumad Lingua software platform. The functional requirements identify the basic functions of the system and include functions such as vocabulary documentation, uploading of the audio recordings, finding vocabularies based on sentiments, archiving the information, gamification of learning, pronunciation evaluation, and authorization of users. On the other hand, the non-functional requirements provide the performance criteria and include the criteria such as reliability, usability, security, and performance efficiency according to ISO/IEC 25010 standards.
The system shall provide the following functionalities:
The system must retain the compiled dictionary entries for Mansaka language, which include the word, Filipino meaning, English meaning, and examples, in Cloud Firestore.
The system must store audio files from the native speakers on Supabase storage with a maximum of 10 MB file per recording and a minimum of one second duration per recording.
The system must fetch publicly available Facebook posts that contain Mansaka words or phrases through Facebook Graph API, or from any verified pre-compiled secondary sources of the said Facebook posts.
The system must use sentiment classification algorithm to classify the sentiment of each post into either positive, negative, or neutral.
The system must present a sentiment dashboard that displays the trends of sentiments generated from the analysis of Facebook posts containing Mansaka language.
The system must present gamified learning modules with multiple choice quizzes, matching activities, and listening practice with a Leitner spaced repetition algorithm to schedule the vocabulary reviews at increasing intervals based on learner mastery.
The system shall include a pronunciation assessment feature that computes MFCCs on the recordings of the learner and the authentic reference audio, with dynamic time warping being used for alignment.
The system shall provide a searchable digital dictionary where users will be able to find out indigenous words, Filipino and English translations, as well as audio clips provided by Supabase Storage service, the search results to be returned within 500 milliseconds.
The system shall implement a role-based access control mechanism via Firebase Authentication Custom Claims, namely by assigning roles of Learner, Validator, Educator, and Administrator, with appropriate Firestore security rules.
The system shall monitor the learners' progress in terms of points, levels, scores, completion and streaking information recorded in Firestore per each learner.
The system shall provide offline-first capabilities through Firestore offline support, enabling learners to access the downloaded content without the Internet connection, with automatic synchronisation once it becomes available.
The system shall create an analytics dashboard for the administrators providing information about content coverage and learners' performance summarised from the Firestore database.
The system shall perform the test assessment to evaluate the effectiveness of the learning process with its results stored in Firestore.
The following are the system's non-functional requirements:
Dictionary Search Performance. The online dictionary should produce search results within 500 milliseconds when there is stable network connectivity.
Sentiment Analysis Performance. The sentiment analysis component should analyze a minimum set of 50 Facebook posts in Mansaka language within a reasonable amount of time without interrupting the application’s graphical interface.
Application Startup Performance. The mobile application should perform cold startup within three (3) seconds on Android devices with API level 21 and higher.
Audio Storage Reliability. The audio recordings stored in Supabase Storage will not experience corruption, illegal modifications, and data loss.
Application Stability. The application should maintain a minimum crash-free sessions rate of 95% which will be tracked via Firebase Crashlytics.
Learner Interface Usability. The learners’ interface will score no lower than 4.0 on a scale of 1-5 during a standard usability assessment of community members.
Authentication Security. User authentication shall take place using Firebase Authentication with encryption of credentials and strong password policies.
Dictionary Content Security. Vocabulary terms that are approved by the designated Validator shall be the only ones available to Learner accounts using Firestore security rules.
Secure Data Transmission. Any data transfer between the app, Firebase, and Supabase Storage shall be encrypted using HTTPS protocol.
Device Compatibility. The application shall operate correctly on Android devices running API Level 21 or higher and iOS devices running iOS 13 or later using a single Flutter codebase.
Offline Learning Availability. Previously downloaded vocabulary terms, lessons, quizzes, and learner progression shall remain available for offline use in Firestore offline persistence which shall automatically synchronize with the database once connected to the Internet.
Modular Maintainability. A modular Flutter codebase with proper Firebase configuration shall ensure independent debugging and maintenance of modules without affecting other modules.
Database Scalability. Firestore shall be capable of supporting additional users, vocabulary terms, learning materials, and indigenous languages with minimum deterioration of system performance.
Cloud Storage Scalability. Supabase Storage should support an uninterrupted storage capacity increase for audio files and learning materials with reliable retrieval efficiency.
Analytics Availability. The analytics dashboard will be accessible to the respective administrator when the system is linked to Firebase services, showing the last synced data.

Use Case Diagram
The Administrator, the Learner or Youth User, and the Educator are the three system users identified in the platform, as illustrated in Figure 6. All vocabulary entries, audio recordings, lesson materials, and sentiment-derived insights are validated offline by linguistic experts and tribal leaders before ever reaching the system; there is no in-app validation workflow or validator-type role. The Administrator is responsible for bringing this pre-validated content into the platform, in addition to overseeing user accounts, configuring system parameters, and accessing analytics and reports. Specifically, the Administrator manages user accounts, configures system settings, loads validated content, views all content on the platform, and views analytics and system reports. These functions ensure that only content already confirmed as linguistically and culturally accurate is introduced into the system, while giving the Administrator full oversight of platform operations.
The Learner engages with the system by registering an account, browsing the digital dictionary, viewing lessons, practicing pronunciation, completing quizzes, and monitoring personal progress. Completing a quiz includes viewing the corresponding quiz score as part of the same interaction. The Learner also has access to a sentiment dashboard, allowing them to see community language trends drawn from the pre-validated sentiment insights loaded by the Administrator. These interactions give the Learner an interactive, self-paced way to engage with and track their own progress in learning the Mansaka language.
The Educator interacts with the system in a purely consumptive and supervisory capacity, browsing the digital dictionary alongside the Learner, viewing learner progress, and viewing learner quiz results. Because all lesson materials, vocabulary, and audio content are validated offline and loaded directly by the Administrator, the Educator does not create, upload, or edit any content within the system; their role is limited to referencing already-validated material and monitoring learner performance to inform instructional decisions outside the platform.


Figure 6. Use Case Diagram of the System

Context Flow Diagram

The Context Flow Diagram shown in Figure 7 presents a high-level view of the Lumad Lingua platform, illustrating how the system interacts with external entities and how data flows across the platform as a whole. The diagram's three external entities are the Administrator, the Learner or Youth User, and the Educator. Facebook and any prior validator-type role are no longer represented as direct system entities, since sentiment analysis and all other content validation now take place offline, in person, before any material is introduced into the platform.
The Administrator oversees the system's overall operation by supplying account management data for both administrator and educator accounts, system configuration data, and the platform's core content — validated vocabulary entries, validated audio recordings, validated lesson materials, and validated sentiment insights — all of which have already been confirmed accurate by linguistic experts and tribal leaders offline. In exchange, the system provides the Administrator with full view access to all platform content, descriptive analytics, and system usage reports to support supervision and decision-making.
The Learner engages with the system by submitting registration data, pronunciation input, and quiz responses during gamified learning activities. In return, the Learner receives dictionary results, audio content, lessons, sentiment dashboard content, quiz results, and their own progress data.
The Educator engages with the system to access lessons and dictionary content already validated and loaded by the Administrator, and receives learner quiz results and learner progress data in return, supporting instructional decisions without requiring the Educator to submit or upload any content of their own.

Figure 7. Context Flow Diagram of the Lumad Lingua System


Data Flow Diagram
The Lumad Lingua platform is depicted in greater detail in Figure 8's Level 1 Data Flow Diagram (DFD), which breaks the single process shown in the Context Flow Diagram down into its component sub-processes. This level divides the system into five main processes, illustrating the data flow between them and their interactions with the D1 Lumad Lingua Database, the system's central repository, and its three external entities.
Process 1.0, Manage Accounts & System Settings, receives admin account management, educator account management, and system configuration data from the Administrator, storing this information in the database as account and system configuration data. In exchange, this process retrieves content data from the database and provides the Administrator with full view access to all platform content.
Process 2.0, Load Validated Content, receives validated vocabulary entries, validated audio recordings, validated lesson materials, and validated sentiment insights directly from the Administrator — content that has already been confirmed offline by linguistic experts and tribal leaders — and stores each into the database as vocabulary, audio, lesson, and sentiment data respectively. Because validation occurs entirely outside the system beforehand, no separate in-system review or approval step is required at this stage.
Process 3.0, Deliver Learning Modules, Dictionary, & Lessons, retrieves vocabulary, audio, lesson, and sentiment data from the database to provide the Learner with dictionary results, audio content, lessons, and sentiment dashboard content, while accepting the Learner's pronunciation input in return and storing it in the database as pronunciation data. This process also delivers lessons and dictionary content to the Educator, ensuring that only validated, database-confirmed material reaches both learners and educators.
Process 4.0, Track Learner Progress & Quiz Results, receives the Learner's quiz responses and retrieves progress data from the database, storing updated quiz response, quiz result, and progress data back into the database. In return, it provides the Learner with quiz results and progress data, and supplies the Educator with learner progress data and learner quiz results to support instructional decision-making.
Process 5.0, Generate Reports & Analytics, completes the platform's cycle by retrieving analytics and usage data from the database to generate descriptive analytics and system usage reports for the Administrator, supporting ongoing platform supervision.


Figure 8. Level 1 Data Flow Diagram of the Lumad Lingua System

SYSTEM DESIGN

Entity Relationship Diagram

	The database design of the suggested Lumad Lingua platform is shown below in the ERD illustrated in Figure 9.

The details about the role of account holder (Validator, Learner, Educator or Administrator) are contained in the Users entity. The Sentiment Results entity analyzes the available in public posts extracted using Facebook Graph API. It stores the translation of the Mansaka term, its classified sentiment label and the decision made by the Validator. After the analysis and approval process, a sentiment result is connected to a corresponding record of the Dictionary Entries entity. The Dictionary Entries record includes the source field that distinguishes entries added by the Validator from the ones obtained from sentiment results analysis and the link to the original post.

As the Validator writes and approves all the entries, there can be multiple Audio Recordings corresponding to one Dictionary Entry with a common validator_id field and no separate contributor and validator fields anymore. The Dictionary Entries also serve as the input for the User Cards where Leitner algorithm determines the progress of every learner in spaced repetition, as well as for the Lesson Items and Quiz Questions allowing to include the dictionary entries to the gamified lessons.
Lessons, along with the Lesson Items and the Resources, store learning module data that have been created by teachers for the gamified learning part of the database. The Quiz Questions, Learner Quiz Results, and Answers for those quizzes are stored in the Quizzes entity that is associated with a lesson. The User Progress stores total points and level of each learner for each lesson. Also, there are additional support entities called Analytics Reports that will store the aggregate documentation and performance information generated for Administrators and the Educator Metadata that will store curriculum-specific information for Educator accounts.
In order to ensure data integrity, the relationship between the entities above are made via primary and foreign key references. For example, based on the specific role of a user, one Facebook post can generate many sentiment results, one dictionary entry may contain many audio records and many quiz questions, and one user may generate many lessons, quizzes, and dictionary entries.






Figure 9. Entity Relationship Diagram of the System


JSON Schema Diagram

	Figure 10 illustrates the JSON schema diagrams that are utilized in order to denote the main data structures of the Lumad Lingua application, including the vocabulary entry, user profile, sentiment result, lesson, user progress, and quiz answer structures. For each structure, the list of fields, nested objects, and the data types are defined in order to outline the document structure in Cloud Firestore.

All of the information about the entry ID, the native word, translation to Filipino language and English, context, validation status, and source are included in the vocabulary entry schema (Figure 10.1). Furthermore, there is also a validator ID that includes both submission and review as the Validator handles both processes. The source field indicates the difference between the entries that are submitted directly by the Validator and those that are found during sentiment analysis. In case of the former one, there is also an additional field source_post_id indicating the Facebook post to which the entry relates. Additionally, the audio_files field, which denotes the array of pronunciation files, and the nested validator object denoting the user who created the entry are present.
The user account structure including its role, language group, and system access credentials is captured using the user profile schema (Figure 10.2). Only administrator, learner, validator, and educator are the allowed roles to be entered in the role field. Learning progress information and educator metadata of the user is contained in the nested objects.
The data structure created by the sentiment analysis pipeline is captured using the sentiment result schema (Figure 10.3). Mansaka word discovered in the Facebook post, its translation to English and Filipino, sentiment score, sentiment label, and validator review are all included in each sentiment result. To ensure traceability and auditing, a nested source_post object captures the content of the post, source URL, and post information, while a linked_entry_id field connects an approved sentiment result to its corresponding vocabulary entry once published.
Gamified Learning Modules have the structure defined by the Lesson Schema (Figure 10.4) containing quizzes with the corresponding questions, learning resources, and arrays of nested lesson items. Apart from the snapshot of learning analytics and a collection of spaced repetition cards employed by the Leitner algorithm, the User Progress Schema (Figure 10.5) contains information about the experience points, lessons completed, and quiz outcomes. The Quiz Answer Schema (Figure 10.6) keeps records of a learner's answer choice to each quiz question, its correctness, and gained points.
These schemas minimize possible errors and ensure reliable platform synchronization by providing consistent structure for transferring data from the Flutter mobile application to Firebase services and the sentiment analysis pipeline.






Figure 10.1 JSON Schema Diagram — Tree A: vocabulary_entry

Figure 10.2 JSON Schema Diagram — Tree B: user_profile





Figure 10.3 JSON Schema Diagram — Tree C: sentiment_result

Figure 10.4 JSON Schema Diagram — Tree D: lesson

Figure 10.5 JSON Schema Diagram — Tree E: user_progress

Figure 10.6 JSON Schema Diagram — Tree F: quiz_answer

Data Dictionary
The Data Dictionary represents a thorough explanation of all the data components included in the Lumad Lingua framework, and serves as a reference for the Firestore database schema and management. The Data Dictionary identifies all collections, fields, data types, and descriptions to ensure consistency and accuracy in storing and managing the data in the database. It is extremely important to consider this part of the paper in relation to creating and managing the database.
All collections used in the database of the system are presented in Table 2. Every single collection relates to some information required by the system. In particular, the Facebook_Posts and Sentiment_Results collections help in gathering and organizing publicly available Mansaka-language posts for vocabulary acquisition, while the Users collection includes all the relevant account and role-related information for administrators, learners, validators, and educators.

Table 2. Database Tables of the System
Table Name
Description
Users
Stores account information and roles of system users.
Dictionary_Entries
Stores documented Mansaka words, translations, and usage context.
Recordings
Stores metadata of uploaded or recorded audio files.
Facebook_Posts
Stores raw publicly available Facebook posts retrieved for sentiment analysis.
Sentiment_Results
Stores translated terms, sentiment classification, and validator review outcomes derived from Facebook posts.
Lessons
Stores gamified learning module information.
Lesson_Items
Stores the sequence of vocabulary entries included in a lesson.
Resources
Stores supplementary instructional materials uploaded for a lesson.
Quizzes
Stores quiz metadata associated with a lesson.
Quiz_Questions
Stores individual quiz questions and their correct answers.
Quiz_Results
Stores learner quiz performance records.
Quiz_Answers
Stores each learner's selected response to a quiz question.
User_Progress
Stores points, levels, and learner progress data per lesson.
User_Cards
Stores spaced repetition (Leitner) card states for each learner.
Educator_Metadata
Stores curriculum-specific information for educator accounts.
Analytics_Reports
Stores aggregated documentation and performance summaries for administrators.


The Users table serves as the main identity table for the application. This table holds account passwords as well as the role for the respective accounts. Roles include administrator, learner, validator, and educator. It is the role that determines the Firestore collection rules through custom claims using Firebase Authentication, while language_group determines the indigenous language group of the user.





Table 2.1 Users Table
Field Name
Data Type
Constraint
Description
user_id
String
Primary Key
User unique identifier
name
String
Not Null
User full name
email
String
Unique, Not Null
Email ID that can be used to log in
password_hash
String
Not Null
User password (hashed)
role
Enum
Not Null
Role played by the user e.g. admin, learner, validator, educator
language_group
String
Nullable
Community language that is linked to the user
created_at
Timestamp
Not Null
Account creation date


The Dictionary_Entries table is the main storage of Mansaka words that have been documented in this database system. It contains the indigenous word along with its translation in Filipino and English languages as well as the usage context and validation. The field named 'source' categorizes those words which have been entered directly by the Validator and those which were found using sentiment analysis.



Table 2.2 Dictionary_Entries Table
Field Name
Data Type
Constraint
Description
entry_id
String
Primary Key
Unique identifier of the entry
validator_id
String
Foreign Key, Not Null
References the validator responsible for the entry
word
String
Not Null
Indigenous Mansaka term
language
String
Not Null
Language of the term (Mansaka)
dialect
String
Nullable
Regional dialect variation, if applicable
translation_fil
String
Not Null
Filipino translation
translation_en
String
Not Null
English translation
part_of_speech
String
Nullable
Grammatical category of the term
usage_context
Text
Nullable
Example usage or meaning context
source
Enum
Not Null
Indicates whether the entry was submitted manually or through sentiment analysis
source_post_id
String
Foreign Key, Nullable
References the Facebook post where the term originated
status
Enum
Not Null
Entry status such as pending, approved, or rejected
submitted_at
Timestamp
Not Null
Date the entry was submitted
validated_at
Timestamp
Nullable
Date the entry was validated


The Recordings table contains metadata about native speaker recordings of an entry in the dictionary, which includes information about the Supabase Storage file path and dialect information. Every record has a validator_id because the Validator table is the owner of both adding the recording and verifying that the pronouncing recording is genuine.
Table 2.3 Recordings  Table
Field Name
Data Type
Constraint
Description
recording_id
String
Primary Key
Unique identifier of the audio recording
entry_id
String
Foreign Key, Not Null
References the related vocabulary entry
validator_id
String
Foreign Key, Not Null
References the validator responsible for the recording
audio_url
String
Not Null
Storage path of the audio file
dialect
String
Nullable
Regional dialect of the recorded speaker
status
Enum
Not Null
Indicates whether the recording is verified
recorded_at
Timestamp
Not Null
Date the audio was recorded


The Facebook_Posts table has the unaltered content of posts obtained using the Facebook Graph API before processing them through the sentiment analysis pipeline. The source_url and author_page fields allow tracing back to the original post.
Table 2.4 Facebook_Posts Table
Field Name
Data Type
Constraint
Description
post_id
String
Primary Key
Unique identifier of the retrieved post
raw_text
Text
Not Null
Original Facebook post containing Mansaka words or phrases
source_url
String
Not Null
Link to the original Facebook post
author_page
String
Nullable
Name of the public page or group where the post was retrieved
posted_at
Timestamp
Nullable
Date the post was originally published
collected_at
Timestamp
Not Null
Date the post was retrieved by the system


The Sentiment_Results table holds the results from the sentiment classification for each Facebook post, which include the identified Mansaka term, translation, sentiment label and confidence score, and the result reviewed by the Validator. The linked_entry_id links an accepted result to the Dictionary_Entries entry it will create.
Table 2.5 Sentiment_Results Table
Field Name
Data Type
Constraint
Description
sentiment_id
String
Primary Key
Unique identifier of the sentiment analysis result
post_id
String
Foreign Key, Not Null
References the source Facebook post
mansaka_term
String
Not Null
Mansaka word or phrase identified in the post
translation_fil
String
Not Null
Filipino translation of the identified term
translation_en
String
Not Null
English translation of the identified term
sentiment_label
Enum
Not Null
Classified sentiment such as positive, negative, or neutral
sentiment_score
Decimal
Not Null
Confidence score of the sentiment classification
reviewed_by
String
Foreign Key, Nullable
References the validator who reviewed the result
linked_entry_id
String
Foreign Key, Nullable
References the vocabulary entry created after approval
status
Enum
Not Null
Review status such as pending, approved, or rejected
analyzed_at
Timestamp
Not Null
Date the sentiment analysis was performed


The Lessons table holds metadata of gamified learning modules designed by Educators, such as difficulty rating, story plot, and whether the module has been published or not. It is the parent table of the Lesson_Items, Resources, and Quizzes tables associated with that particular module.


Table 2.6 Lessons Table
Field Name
Data Type
Constraint
Description
lesson_id
String
Primary Key
Unique identifier of the lesson
created_by
String
Foreign Key, Not Null
References the educator who created the lesson
title
String
Not Null
Title of the lesson
language
String
Not Null
Language used in the lesson
level
Enum
Not Null
Difficulty level such as beginner, intermediate, or advanced
storyline_text
Text
Nullable
Narrative or thematic content of the lesson
order_index
Integer
Nullable
Lesson sequence
status
Enum
Not Null
Lesson status such as draft, published, or archived
created_at
Timestamp
Not Null
Date the lesson was created


The Lesson_Items table is a join table that sequences which Dictionary_Entries are incorporated into a given lesson, using order_index to control the representation order of vocabulary within the module.

Table 2.7 Lesson_Items Table
Field Name
Data Type
Constraint
Description
item_id
String
Primary Key
Unique identifier of the lesson item
lesson_id
String
Foreign Key, Not Null
References the parent lesson
entry_id
String
Foreign Key, Not Null
References the vocabulary entry included in the lesson
order_index
Integer
Nullable
Sequence position within the lesson


The Resources table is used to store resources uploaded by instructors in relation to particular lessons. Information stored here includes details about the resource such as its name, file path, resource type, status, and the uploading instructor.
Table 2.8 Resources Table
Field Name
Data Type
Constraint
Description
resource_id
String
Primary Key
Unique identifier of the resource
uploaded_by
String
Foreign Key, Not Null
References the educator who uploaded the resource
lesson_id
String
Foreign Key, Not Null
References the associated lesson
title
String
Not Null
Title of the resource
file_url
String
Not Null
Storage path of the resource file
resource_type
Enum
Not Null
Type of resource such as PDF, image, video, or audio
status
Enum
Not Null
Resource status
created_at
Timestamp
Not Null
Date the resource was uploaded


The Quizzes table stores quiz metadata associated with a parent lesson, including quiz type and difficulty level, and serves as the container for its individual Quiz_Questions.
Table 2.9 Quizzes Table
Field Name
Data Type
Constraint
Description
quiz_id
String
Primary Key
Unique identifier of the quiz
lesson_id
String
Foreign Key, Not Null
References the associated lesson
created_by
String
Foreign Key, Not Null
References the educator who created the quiz
title
String
Not Null
Title of the quiz
quiz_type
Enum
Not Null
Type such as multiple choice, pronunciation, or fill-in-the-blank
difficulty
Enum
Not Null
Difficulty level such as easy, medium, or hard
status
Enum
Not Null
Quiz status
created_at
Timestamp
Not Null
Date the quiz was created


Quiz_Questions will keep track of the question that is part of a quiz, which includes the correct answer to the question, how many points the question is worth, and optionally a reference to the Dictionary_Entries term being tested.
Table 2.10 Quiz_Questions Table
Field Name
Data Type
Constraint
Description
question_id
String
Primary Key
Unique identifier of the quiz question
quiz_id
String
Foreign Key, Not Null
References the parent quiz
entry_id
String
Foreign Key, Nullable
References the vocabulary entry being assessed
question_text
Text
Not Null
Question presented to the learner
question_type
Enum
Not Null
Type of question
options
JSON
Nullable
List of answer choices
correct_answer
String
Not Null
Correct answer to the question
points
Integer
Not Null
Points awarded for a correct answer
order_index
Integer
Nullable
Sequence position within the quiz


Quiz_Results will keep track of the results of a quiz, which includes the total score, total possible points, and whether it was passed or failed. This is the parent table for the Quiz_Answers records.
Table 2.11 Quiz_Results Table
Field Name
Data Type
Constraint
Description
result_id
String
Primary Key
Unique identifier of the quiz result
quiz_id
String
Foreign Key, Not Null
References the completed quiz
user_id
String
Foreign Key, Not Null
References the learner
score
Integer
Not Null
Score obtained by the learner
total_points
Integer
Not Null
Maximum possible score
passed
Boolean
Not Null
Indicates whether the learner passed the quiz
completed_at
Timestamp
Not Null
Date the quiz was completed


The Quiz_Answers table contains details of the learner’s chosen answer for the particular question in a quiz, whether the answer is correct, and the points scored from the chosen answer.
Table 2.12 Quiz_Answers Table
Field Name
Data Type
Constraint
Description
answer_id
String
Primary Key
Unique identifier of the quiz answer
result_id
String
Foreign Key, Not Null
References the associated quiz result
question_id
String
Foreign Key, Not Null
References the answered question
user_id
String
Foreign Key, Not Null
References the learner
selected_answer
String
Not Null
Answer selected by the learner
is_correct
Boolean
Not Null
Indicates whether the answer is correct
points_earned
Integer
Not Null
Points earned for the answer
answered_at
Timestamp
Not Null
Date the question was answered


The User_Progress table contains information about the learner’s completion of the particular lesson as well as points earned from the lesson, serving as the foundation for the points/leveling system mentioned in the gamification design.
Table 2.13 User_Progress Table
Field Name
Data Type
Constraint
Description
progress_id
String
Primary Key
Unique identifier of the progress record
user_id
String
Foreign Key, Not Null
References the learner
lesson_id
String
Foreign Key, Not Null
References the associated lesson
xp_earned
Integer
Not Null
Experience points earned
score
Integer
Nullable
Lesson score
completed
Boolean
Not Null
Indicates whether the lesson was completed
completed_at
Timestamp
Nullable
Date the lesson was completed


The User_Cards table stores the spaced-repetition state of each vocabulary entry per learner under the Leitner algorithm, including the current box level, review count, and the next scheduled review date.
Table 2.14 User_Cards Table
Field Name
Data Type
Constraint
Description
card_id
String
Primary Key
Unique identifier of the spaced repetition card
user_id
String
Foreign Key, Not Null
References the learner
entry_id
String
Foreign Key, Not Null
References the vocabulary entry being studied
leitner_box
Integer
Not Null
Current Leitner box level
next_review_at
Timestamp
Not Null
Scheduled next review date
review_count
Integer
Not Null
Number of reviews completed


The Educator_Metadata table stores curriculum-specific information for Educator accounts, such as assigned curriculum tags and target learner groups, extending the base Users record for this role.
Table 2.15 Educator_Metadata Table
Field Name
Data Type
Constraint
Description
meta_id
String
Primary Key
Unique identifier of the metadata record
user_id
String
Foreign Key, Not Null
References the educator account
assigned_by
String
Nullable
Administrator who assigned the educator role
curriculum_tag
String
Nullable
Curriculum classification
target_group
String
Nullable
Intended learner group
is_lesson_creator
Boolean
Not Null
Indicates whether the educator is authorized to create lessons


The Analytics_Reports table stores aggregated documentation and performance summaries generated for Administrators, including the reporting period and a JSON snapshot of summary data used to populate the analytics dashboard.


Table 2.16 Analytics_Reports Table
Field Name
Data Type
Constraint
Description
report_id
String
Primary Key
Unique identifier of the report
generated_by
String
Foreign Key, Not Null
References the administrator who generated the report
report_type
Enum
Not Null
Type of generated report
target_scope
String
Nullable
Scope of the report
summary_data
JSON
Not Null
Aggregated report data
generated_at
Timestamp
Not Null
Date the report was generated
period_start
Timestamp
Nullable
Start of the reporting period
period_end
Timestamp
Nullable
End of the reporting period



Technologies, Concepts, and Theories

The main models, algorithms, and technologies used in the creation of the Lumad Lingua platform are presented in this section, arranged in accordance with the four main phases of the system workflow: data collection, pre-processing, feature extraction, and classification. Each step advances the platform's fundamental functions in sentiment-driven vocabulary discovery, pronunciation evaluation, and language documentation.

Data Collection

Collection of data on the Lumad Lingua platform is done through two streams that serve specific purposes within the entire workflow of the platform. First of all, the workflow in question is community-led in nature and the validator uploads vocabulary items and audio recordings via the Flutter app as the designated linguistic authority. Vocabulary items are recorded in Cloud Firestore database as JSON documents with fields for the native Mansaka word, its translations in English and Filipino languages as well as the context. flutter_sound package helps to record native speakers' pronunciations of the word using the device microphone while audio recordings are saved as audio files in Supabase Storage. Each and every vocabulary item uploaded by the validator is taken as the authoritative one since they have linguistic and cultural authority over the Mansaka language. The aim of the current stream dataset is to collect an infinite number of audio files and vocabulary at beginner level from at least three different geographic locations of Davao de Oro communities. The Validator is allowed to add an unlimited number of entries depending on the linguistic data available in the community since the system is built in a way that allows for limitless growth rather than setting up the minimal threshold. Every entry comes with metadata such as the validator id, timestamp, and history of versions and the maximum audio file size cannot exceed 10 MB but should not be less than one second.
Stream two harvests Facebook posts that are available in the public domain with the use of Mansaka words/phrases through the Facebook Graph API or, if available, pre-prepared secondary sources that are already validated. These posts act as the raw inputs for the sentiment analysis process that identifies potential vocabulary terms, translations of these terms, and the sentiment expressed through these terms. In the case of the Facebook post dataset, where the raw data comes in the form of unstructured/semi-structured text in a code-mixed language environment, the Mansaka language terms are mixed together with Filipino, English, or Cebuano. Each set of harvested Facebook posts will try to reach up to 50 posts for ensuring that there is enough data to classify the sentiment. Only those posts containing Mansaka language are tokenized and filtered after the filtering out of any formatting characters and other non-language characters. The sentiment results are recorded separately on Cloud Firestore and include the extracted Mansaka term, its translation in Filipino and English languages, sentiment label with confidence score, and review status. The digital dictionary allows for a community-supported vocabulary discovery tool by populating the term, translation, and usage context fields with sentiment-sourced and approved entries. Both of these streams, that is, the authority and expert-backed information and the organic and community-sourced linguistic information, allow the platform to acquire culturally validated and constantly evolving linguistic material for the Mansaka language. Apart from allowing for the completion of the digital dictionary, learners have access to the approved sentiment-sourced entries and their emotional context categorization as additional usage examples. This way, learners will be able to see how the meaning of a certain Mansaka word changes emotionally depending on the context in which it is used.

Data Pre-Processing

The data is pre-processed to improve its quality and reliability prior to storage and analysis. As for the vocabulary entries, it means checking if all required fields have been filled in, normalizing variations in the spelling, and checking for duplicates in Cloud Firestore.
Pre-processing of the audio recordings involves a set of steps that should be taken to prepare the recording for MFCC feature extraction and waveform comparison. First, the recording is resampled to a standard 16,000 Hz sampling rate to provide uniform dimensions of features irrespective of microphone settings of the device used as the origin of the recording. It is common practice when it comes to using MFCC in speech processing due to the fact that the critical frequency content of human speech does not exceed approximately 8,000 Hz and thus satisfies the Nyquist-Shannon criterion for the sampling rate. The chosen rate coincides with the 16,000 Hz sampling rate, suggested by ITU-T G.722 wideband speech standard [53] as required to cover the frequency range of 50–7,000 Hz necessary for intelligible speech. Then, noise reduction and equalization of the sound wave’s amplitude to have a uniform amplitude regardless of the conditions under which the recording is made are carried out. The recording is then converted to a uniform file type. Pre-emphasis filtering is performed to enhance the higher frequencies in comparison to the lower ones due to the natural roll off in energy in human speech. This pre-emphasized recording is segmented into short time periods known as frames which last for around 20 to 25 milliseconds and have a stride of 10 milliseconds between them since speech is not stationary and can only be considered to be stationary for such a small period of time. These frames allow the analysis to be done on shorter sections of the recording rather than the whole recording. However, segmentation of the recording in frames causes a sudden cutting of the recording which creates distortion in the frequency analysis and is known as spectral leakage. Therefore, a windowing function, the Hamming Window, is applied to these frames. It creates a sequence of clean segments of short duration from which the MFC coefficients are then extracted, as explained in the Feature Extraction section.
To prepare the Facebook posts for sentiment analysis, pre-processing includes eliminating any formatting or non-linguistic characters from the text, excluding posts that do not have any content in Mansaka language, and tokenization of the text. This will reduce any chances of errors in the learning modules since the input data will be clean and appropriate for sentiment analysis, digital archiving, and pronunciation assessment

Feature Extraction

Feature extraction refers to the process of identifying appropriate features from the collected data in order to facilitate sentiment analysis, pronunciation analysis, and language documentation. The indigenous term, translations, usage context, and audio file from the Supabase Storage database are some of the important elements of the digital dictionary. Word and n-gram frequencies and TF-IDF weighted vectors obtained from the text of Facebook posts are some of the features utilized in sentiment analysis algorithms. Mel-frequency cepstral coefficients (MFCCs) are one of the acoustic features that are extracted from the audio files to assess pronunciation. The above process is carried out using the fundamental parametrization defined by Davis and Mermelstein [55], whose comparative analysis of acoustic representations showed that MFCCs performed better than other types of parametrization in the recognition of words. The three pronunciation assessment algorithms to be covered in the following subsection, Dynamic Time Warping, Hidden Markov Model, and Cosine Similarity, all use the same feature representation, i.e., MFCCs; for convenience purposes only, we refer to them henceforth as DTW, HMM, and Cosine Similarity without the MFCC label. Feature extraction enhances the performance of the system.


Classification – Sentiment Analysis Algorithms

The three algorithms used for the classification of the sentiment of Facebook posts written in Mansaka language include: Naïve Bayes algorithm, Support Vector Machine algorithm, and Bidirectional Long Short-Term Memory algorithm. Whole sentences or phrases within the posts on Facebook are the units being collected and annotated based on the way the system consumes the data. As counting at the word level or unigram level is statistically valid even with a limited number of data points, but phrase level patterns would never repeat themselves enough times to become recognized due to lack of data sparsity, which becomes a problem for BiLSTM later in the process, phrases are divided into their constituent words for the classical algorithms.

Naïve Bayes
Naïve Bayes applies Bayes' theorem, assuming conditional independence between words in a post:

Figure 11. Naïve Bayes Formula
In this formula, C denotes the sentiment class to be analyzed (Positive, Negative, or Neutral), while X denotes the set of words in a phrase. P(C|X) is the probability of a class C given X, P(X|C) is the probability of observing X given C, and P(C) is the prior probability of occurrence of class C in the training set. The class that produces the highest probability is chosen as the sentiment prediction.
Bilog [44] used the Naïve Bayes Classifier on 300,000 Facebook posts from Filipino, English, and Taglish languages and obtained an accuracy of 77%, which surpassed that of SentiWordNet and Logistic Regression for the same data set. In Indriani et al.'s study [46], Naïve Bayes, K-Nearest Neighbor, Decision Tree, and Multi-Layer Perceptron were analyzed on 200 labeled tweets of a low-resourced Twitter corpus; Naïve Bayes proved to be better than the other non-neural approaches in 11 experiments.

Support Vector Machine (SVM)
SVM separates sentiment classes by finding the maximum-margin hyperplane:

Figure 12. Support Vector Machine Decision Function

In this case, x represents the feature vector of the phrase (e.g., frequencies of words or n-grams), w represents the weight vector learned during the training process, and b represents the bias component. The value of f(x) is the indicator of whether the result falls into a positive or negative class while its magnitude shows how much confidence the model has about it.
Hasan et al. [45] have directly benchmarked classical algorithms including SVM against deep learning models and transformers in classifying sentiments of Bangla language, where the classical models turned out to be competitive against the deep learning methods but needed far less time-resource complexity.

Bidirectional Long Short-Term Memory (BiLSTM)
The BiLSTM architecture, on the other hand, is a neural network model that processes input in two directions and therefore takes into consideration not only word order but also negations, which are ignored by Naïve Bayes and SVM approaches that treat individual words separately. Nonetheless, BiLSTM depends heavily on the amount of the training data used as well as the monolinguality of the input texts. In particular, Shanmugavadivel et al. [49] applied the sentiment classification to the code-mixed Tamil-English tweets taken from DravidianLangTech@ACL2022 shared task and achieved 66% accuracy of the hybrid CNN+BiLSTM model, which combines the benefits of the convolutional features extraction and the sequential modeling in BiLSTM. As the hybrid model that includes an extra layer of convolution will always perform better than a plain BiLSTM model, 66% is a conservative upper estimate of the BiLSTM's possible performance on small code-mixed Mansaka corpus. Hence, this experiment demonstrates the limitation of the proposed approach that requires large amounts of data in order to be effective.


Evaluation Metrics
In light of the fact that sentiment analysis is a problem in which classes are discrete (Positive, Negative, Neutral), this research utilizes Accuracy, Precision, Recall, and F1-Score metrics for assessment of candidate algorithms, based on the approach proposed by Sokolova and Lapalme [52]. Each of the above measures is related to classification performance from a unique angle and is expressed in terms of TP (true positives), TN (true negatives), FP (false positives), and FN (false negatives).Accuracy determines the general correctness of all the classifications made, though accuracy can be very misleading if there’s an imbalance in the class distribution, which is true because posts classified as Positive, Negative, and Neutral won’t occur in equal number in a Facebook corpus. Precision determines how many of those phrases predicted to belong to a certain class actually belong to that class, which will reduce the number of false alerts in the sentiment analysis interface. Recall determines how many of the actual phrases belonging to a certain class were actually classified, which is necessary to ensure that negative or positive sentiments are not overlooked in the community. F1-score takes into account both precision and recall scores.


Figure 13. Accuracy Formula


Figure 14. Precision Formula

Figure 15. Recall Formula


Figure 16. F1-Score Formula

For multi-class problems, these metrics are computed per class and macro-averaged, consistent with Sokolova and Lapalme's [52] recommendation.

Table 4. Literature Evidence – Sentiment Analysis Algorithms
Algorithm
Study
Dataset Type
Reported Accuracy
Naïve Bayes
[44]
300,000 Filipino/English/Taglish Facebook comments
77%
Naïve Bayes
[46]
200 labeled tweets, low-resource
Outperformed KNN & Decision Tree
Support Vector Machine (SVM)
[45]
Bangla sentiment corpora, multiple datasets
Competitive with deep learning, lower complexity
CNN + BiLSTM
[49]
Tamil-English code-mixed (DravidianLangTech)
66%


It should be noted that the performance measure provided for [49] actually refers to a CNN-BiLSTM hybrid model and not just a BiLSTM system. This is provided as an example of evidence since the inclusion of a CNN into the system will definitely provide results no less effective than those obtained by BiLSTM alone.
Decision Matrix Framing

The criteria below have been borrowed from the ISO/IEC 25010 software quality characteristics that are being applied to the performance, reliability and compatibility aspects of the NFRs in the current study. The study also follows a comparative evaluation approach where candidate algorithms are compared under identical circumstances using identical criteria.


Table 5. Decision Matrix – Sentiment Analysis
Criteria (ISO/IEC 25010 Basis)
Naïve Bayes
SVM
BiLSTM
Reliability – accuracy on small/code-mixed data
Moderate (~77%)
High, competitive with deep learning
Low on code-mixed data (66%)
Performance Efficiency – data & training cost
Low
Low–Moderate
High
Compatibility – feasible as offline/batch backend process
Yes
Yes
Yes, but slow to train
Suitability for Mansaka Facebook corpus
Good
Best
Poor – data-starved


One common disadvantage is with Naïve Bayes and SVM, where bag-of-words approach at word level does not inherently recognize negation ("good" versus "not good") because of lack of consideration for context in which the words occur. However, it is a known tradeoff made considering the small number of entries available in Mansaka corpus, rather than an oversight, which is also why the aforementioned BiLSTM fails above.
Support Vector Machine (SVM) is chosen for the sentiment classification of Facebook posts associated with Mansaka because of competitive results obtained by SVM on similar smaller and code-mixed datasets, less data needed for SVM compared to BiLSTM, and reasonable implementation difficulty considering our capstone team's lack of substantial labeled corpus.

Classification – Pronunciation Assessment
The method employs a waveform comparison technique with dynamic time warping to measure the accuracy of pronunciations made by the learner. In this technique, acoustic features of the spoken input from the learner are compared to those of the reference recording that has been confirmed by the native speaker of the language from Supabase Storage. The distance between the two sequences of feature vectors is calculated by employing dynamic time warping method which takes into consideration differences in speech rates and returns a result normalized to a friendly percentage or rating for the user. The combination of these techniques improves detection accuracy and allows visualizing results in an understandable way for learners.
This algorithm has been chosen since it is reasonably accurate yet does not involve high computational cost and therefore is compatible with mobile devices widely used in rural areas of the Philippines. It has been proven that computer-based visualization aids like waveforms and spectrograms can aid in pronunciation in a second language if learners’ attention is deliberately drawn to the visual prompts [42]. Moreover, the 2023 study about computer-assisted pronunciation training proves that the Dynamic Time Warping algorithms are still applicable for pronunciation assessments as modern systems apply DTW to evaluate pronunciation after accent adaptation using neural style transfer [43]. This combination solves the problem of conventional automatic speech recognition models, which have been trained only on native speakers and proved to be less accurate in relation to non-native ones [43].



Algorithm Selection Rationale

As can be seen from Table 6, waveform comparison method with dynamic time warping was chosen as the one which is best suited for use in the Lumad Lingua system. According to Khaustova et al. [43], the effectiveness of such assessment continues to be applicable to pronunciation training systems, especially when it is combined with accent recognition technology to give personalized feedback to users. Moreover, Tsai [42] showed that explicit instruction to focus on computerized feedback resulted in greater intonation gains, which makes waveform visual feedback a good fit for this system. Such approach focuses on accessibility, interpretability, and offline usability, which is important for language preservation systems used in remote locations with poor internet access.


Dynamic Time Warping


Dynamic Time Warping aligns two sequences of feature vectors by minimizing cumulative distance:

Figure 17. Dynamic Time Warping Formula
Here, d(i,j) is the local distance between frame i of the reference and frame j of the learner recording.


Hidden Markov Models
In Hidden Markov Models, pronunciations are modelled in terms of hidden states that are connected by means of transition probabilities A and emission probabilities B in the following way:

Figure 18. Hidden Markov Formula

Where α_t(j) refers to the forward probability for being in state j at time t, N stands for the number of all hidden states, A_ij represents the probability of transitioning from state i to state j, and B_j(O_t) denotes the probability of observing O_t in state j.

Cosine Similarity
Cosine Similarity compares two feature vectors directly without alignment:

Figure 19. Cosine Similarity Formula
In this case, R and T refer to the feature vectors of the reference and learner recordings, respectively, R·T is the dot product of the two feature vectors, and ‖R‖ and ‖T‖ are the Euclidean norms (magnitudes) of R and T, respectively.
The present research will use the comparative evaluation methodology employed in [47] and [48] where the algorithms will be evaluated under the same feature extraction scenario.

Table 6. Literature Evidence – Pronunciation Assessment Algorithms
Algorithm
Study
Context
Result
DTW vs. HMM
[47]
Isolated word recognition, Punjabi, 500-word vocabulary
DTW 94.0% vs. HMM 91.3%
DTW vs. HMM
[48]
Pronunciation error detection, Polish, <20 patterns/word
DTW average error rate 0.287 vs. HMM (best) 0.473; DTW also faster


Decision Matrix Framing
The comparative criteria below are adapted from the ISO/IEC 25010 attributes already governing this study's Non-Functional Requirements.

Table 7. Decision Matrix – Pronunciation Assessment
Criteria (ISO/IEC 25010 Basis)
DTW
HMM
Cosine Similarity
Reliability – accuracy
94.0%
91.3%
Not benchmarked for this task in cited literature
Performance Efficiency – data requirement
Very low
Higher (per-phoneme training)
None
Compatibility – offline/mobile feasibility
Excellent
Moderate
Excellent, but discards timing


The combination of Mel-Frequency Cepstral Coefficients and Dynamic Time Warping has been selected as the algorithm of choice and this is also in accordance with the design of this study, with accuracy figures of 94.0% vs. 91.3%, and error rates of 0.287 vs. 0.473 from a matched comparative testing design.

Technologies Used in the System

Cross-Platform Mobile Framework (Flutter)
This system mostly uses Flutter 3.x, which is Google's cross-platform mobile development framework based on the Dart programming language, as illustrated in Figure 11. The main advantage of Flutter is that native compiled applications can be developed for Android and iOS systems from a common code base, thus making development more effective. Such an approach is applicable to Lumad Lingua system because it provides a uniform application functionality for both platforms widely used in rural areas of Philippines. Due to the use of widgets in Flutter, a custom interface can be created, along with animations required for the gamification of the learning process, such as quizzes' transitions, levels up animations, and real-time wave form visualization using Flutter CustomPainter. For the state management, Riverpod is utilized.

Figure 20. Flutter Framework

Firebase Backend Services
In order to augment the functionality of the backend without dealing with the dedicated server infrastructure, Firebase is incorporated as the main backend platform of the system as depicted in Figure 12. Firebase Authentication takes care of managing user accounts using email and password authentication, with role-based access control implemented via custom claims which separate Validators, Learners, Educators, and Administrators. Cloud Firestore acts as the NoSQL document database where vocabulary entries, user profiles, sentiment analysis logs, validation logs, version history, gamification logs, and quiz scores are stored. Real-time synchronization of data and offline capability offered by Firestore allow Validator to log in content and learners to go through lessons even without an internet connection which is important when dealing with remote Lumad tribes who do not have stable internet connection. Supabase Storage acts as the backend for the storage of audio files, and it has a perfect compatibility with Flutter through the supabase_flutter package for uploading and playing audio files. Firebase Cloud Functions written in Node.js and TypeScript perform server-side computations such as the sentiment analysis process, scoring of pronunciation, triggering of validation process, version snapshots creation, and analytics generation.

Figure 21. Firebase Services


Sentiment Analysis Processing (Facebook Graph API and Support Vector Machine)
In order to help with the process of vocabulary discovery based on sentiment, the system makes use of the Facebook Graph API, which provides the ability to obtain publicly available posts with Mansaka words or phrases from public community pages and groups (Figure 13), according to the policy of Facebook and the requirements for its API access. Obtained posts undergo preprocessing in a Cloud Function that performs raw text cleaning, filtration of non-Mansaka content, and tokenization of the remaining text in order to prepare it for classification.
Classification is carried out by means of a Support Vector Machine (SVM) model implemented in Python via the scikit-learn library and launched as an independent Cloud Function that receives its requests via HTTP from the main backend. In this way, the hybrid approach is implemented so that the system could utilize Python libraries in terms of the classification task but keep the rest of the Cloud Functions implemented in Node.js and TypeScript. The results of classification – including the detected Mansaka term, translations into Filipino and English, sentiment classification, and confidence level – are saved in Cloud Firestore as the analysis records awaiting validation by the Validator before publication.


Figure 22. Sentiment Analysis Technology Stack




Database Management System (Cloud Firestore)
The system manages data using Cloud Firestore, Firebase's NoSQL document database, as seen in Figure 14. Firestore stores and organizes vocabulary entries, user profiles, sentiment analysis records, validation records, version history, and learning progress data. Unlike traditional relational databases, Firestore's document-based architecture allows for flexible schema design that can adapt as the platform expands. Learners can instantly access content updates, such as recently approved vocabulary entries, without having to manually refresh thanks to Firestore's real-time capabilities.  When connectivity is restored, the database also enables users to continue accessing previously downloaded content and queuing submissions for synchronization. We call this feature offline persistence. Firestore security rules enforce role-based access, ensuring that learners can only access content that has been validated, even though the Validator can write directly to content collections. The data management component, which ensures efficient data retrieval and organized storage of all vocabulary entries, user profiles, validation records, sentiment analysis records, and learning progress throughout the platform, consists of Cloud Firestore for structured data and Supabase Storage for audio files and media assets.
Figure 23. Cloud Firestore Database

Supplementary Storage (Supabase)

	The system uses Supabase Storage as a dedicated storage backend to handle media assets and audio recordings, as seen in Figure 15. Supabase is an open-source backend-as-a-service platform built on PostgreSQL that offers S3-compatible object storage with fine-grained access policies and a RESTful API compatible with Flutter via the supabase_flutter package. Both native speaker audio recordings and media assets uploaded by Validators are stored in Supabase Storage buckets. These buckets are arranged by language and entry ID for structured retrieval. Supabase Row Level Security (RLS) policies regulate access to stored media, guaranteeing that files can only be uploaded, updated, or deleted by authenticated users with the proper roles. In addition to distributing storage load and lowering reliance on a single provider, this dual-storage strategy offers an affordable way to handle the platform's increasing demand for audio and image assets. 

Figure 24. Supplementary Storage (Supabase)



Audio Processing and Pronunciation Assessment

The system implements audio recording capabilities using the flutter_sound package, as shown in Figure 16, capturing device microphone input for pronunciation assessment. Reference audio recordings from verified native speakers are stored in Supabase Storage and streamed using the just_audio package. For pronunciation scoring, the system extracts Mel-frequency cepstral coefficients (MFCCs) from both the learner's recording and the reference recording, then applies dynamic time warping to align the sequences and compute a similarity score. According to Tsai [41], explicit direction of learners' attention to computerized visualization cues leads to more significant intonational gain. Therefore, the system provides visual feedback showing the alignment of the learner's waveform against the reference waveform using Flutter's CustomPainter, enabling self-correction and iterative improvement. This lightweight approach operates entirely on the device without requiring cloud processing, making it suitable for offline use in remote areas.

Figure 25. Audio Recording and Waveform Visualization

Gamification and Spaced Repetition (Leitner System)
The gamified learning modules are created using pedagogical techniques incorporated into the Flutter application, as shown in Figure 17 [51]. According to the learner's level of proficiency, the Leitner system, a spaced repetition algorithm, arranges vocabulary reviews at progressively longer intervals. The states of each user's card deck are stored in Firestore. Correct answers lead to higher-level boxes with longer review times, while incorrect answers cause words to be reviewed more frequently. Multiple-choice, matching, and listening exercises are just a few of the question types that the quiz engine supports. Scores saved in Firestore are used to track progress.  Completing modules earns users points, and maintaining streaks and getting perfect scores earn them extra points. XP points and streak mechanics are stored in each user profile, and Flutter Lottie is used to create level-up animations that offer interesting visual feedback. In order to lower the affective filter and sustain motivation among the target audience of 15 to 25 years old, the game's storyline interface employs a metaphor of mountain climbing for character progression screens.


Figure 26. Leitner Spaced Repetition System [51]


SYSTEM TESTING AND IMPLEMENTATION
Ensuring the successful functioning and compliance of the Lumad Lingua mobile application with all the requirements would be the primary objective of the system testing and implementation phase. All the system components, such as the submission of vocabulary, uploading of audio recording, digital dictionary, learning gamification, pronunciation assessment, content validation process, and role-based access control would be tested in this phase. Important performance measures such as the rate of success of submission, audio play, score evaluation of quizzes, and feedback on pronunciation would be used for testing each function of the system. Test cases, such as submissions done in offline conditions in places with limited connectivity, poor audio input data, incomplete metadata submission, and access by multiple users at the same time, would be developed to simulate typical and edge case usage of the application.
Table 8 would give an idea of the outcomes of the testing and how well each system component is performing. It would be helpful in identifying any problems with the components as well as ensuring that all the features meet the necessary requirements before implementation.



Table 8. System Testing Summary
Test Component
Test Description
Expected Result
Status
Vocabulary Entry Submission
Validator submits new words with Filipino and English translations.
Entry stored on Firestore as "pending" with proper metadata.


Pending
Audio Recording Upload
User records and uploads audio to Supabase Storage.
File stored; metadata document stored in Firestore.


Pending
Digital Dictionary Search
User searches for indigenous term.
Query on Firestore returns entries that match within 500 milliseconds.


Pending
Facebook Post Retrieval
System retrieves public posts containing Mansaka words/phrases via Facebook Graph API.
Posts fetched and stored on Facebook_Posts collection with the source URL and timestamp.


Pending
Sentiment Classification
SVM model classifies retrieved posts as positive, negative, or neutral.
Sentiment label and confidence level stored in Sentiment_Results within acceptable processing time for a 50 post batch.
Pending
Candidate Vocabulary Generation
System generates candidate dictionary entries from classified posts.
Candidate entry stored with term, its translation, and usage context; marked as "pending" for Validator.


Pending
Sentiment Dashboard Rendering
Administrator/researcher views sentiment dashboard.
Dashboard shows proper sentiment trends based on Sentiment_Results stored.


Pending
Gamified Quiz
Learner completes multiple-choice quiz.
Score recorded; points credited to the user profile.


Pending
Leitner Spaced Repetition
System schedules vocabulary review based on mastery.
Correct entries move cards to next intervals.


Pending
Pronunciation Assessment
Learner speaks word; system compares with reference recording.
Similarity score produced with waveform visualization feedback.


Pending
Offline Submission
Validator submits entry without internet.
Data stored locally; synchs automatically once connected online.


Pending
Role-Based Access
Validator approves content; learner views only approved content.
Firewall access control provided using Firestore Security Rules.


Pending
Version History
Validator edits existing entry.
Previous version stored to the version_history subcollection.


Pending
Pre-test/Post-test
Learner completes assessments before and after modules.
Scores recorded for comparison and analysis.


Pending


A System Test Plan, which outlines the objectives, scope, test environment, test cases, and acceptance criteria as shown in Table 10, will be created to direct the validation process. This strategy will guarantee that testing is structured, methodical, and compliant with system requirements.

Table 10. System Test Plan
Aspect
Description
Objectives
Verify all functional and non-functional requirements; ensure the stability, reliability and usability of the application by community users.


Scope
Testing of the entire Flutter mobile application, Firebase services (Firestore, Storage, Authentication, Functions), offline storage capability and gamified features.


Test Environment
Android devices (API 21+), iOS devices (13+), Firebase Emulator Suite, various network conditions (offline, online, poor network).


Test Data
200+ vocabulary items, 50+ audio items, test accounts for all user roles.


Acceptance Criteria
No failed test case, no critical crashes, app cold start < 3 seconds, Firestore queries < 500ms, user satisfaction >= 4.0/5.0.




The implementation phase will begin after the testing is successful. This will entail creating the Flutter application for iOS (IPA) and Android (APK/AAB), setting up the Firebase project with the appropriate security rules and indexes, and distributing the system to the intended communities. Following deployment, a final validation will be carried out to verify that the system functions properly in real-world Davao de Oro community settings. To guarantee efficient system use, users like administrators, teachers, learners, and linguistic validators will also receive the appropriate training. The user training plan is shown in Table 11.

Table 11. User Training Plan

User Group
Training Content
Delivery Method
Duration
Validators
Vocabulary submission, Audio submission, Geo-tagging, Pending submissions, Approval/Rejection of content (sentiment based content included)


In-person workshop, video tutorial, and written guide.
3 hours.
Learners
Dictionary lookup, taking quiz, practicing pronunciation


In-app tutorial and quick start guide.
1 hour
Educators
Integration into MTB-MLE curriculum, using the dictionary in class, monitoring learner progress


In-person workshop and teacher's guide
2 hours
Administrators
Users management, looking at stats and managing content
Admin dashboard walkthrough and documentation.
2 hours



Finally, to evaluate system performance and pinpoint areas for improvement, ongoing monitoring and assessment will be carried out. In order to support the system's long-term use in improving indigenous language learning and preservation within Lumad communities, this phase will guarantee that the system remains dependable, functional, and flexible.


SYSTEM MAINTENANCE

The continuity, reliability, and development of the Lumad Lingua platform after its implementation are the core objectives of the System Maintenance phase. The maintenance phase involves the monitoring of system performance, problem identification and solving, and implementing necessary updates to increase flexibility and functionality. The regular checks of the system, updating Firebase security rules, optimization of Firestore queries and indexes, monitoring of Firebase and Supabase Storage usage, evaluation and validation of new content submissions, and development of system features in response to the structured feedback from community validators and learners are examples of maintenance activities.

	The project team maintains a Maintenance Log where all maintenance activities are documented. The Maintenance Log includes the date, the type of maintenance activity (either corrective, adaptive, or perfective), the affected system component, actions taken, the individuals responsible, and the result of the issue resolution. Each semester, the Maintenance Log is checked by the academic advisor and saved in the repository of the project for future use. Any significant changes in the system including changes to Flutter dependencies, Firestore security rules, or pronunciation assessment algorithm are documented in a Change Request Record.

The automatic export feature that comes with Firebase can be utilized in order to export the data from Firestore to a specific bucket of Google Cloud Storage on a weekly basis. The backup tool offered by Supabase can be used to take backups of the data stored in the storage buckets of Supabase once in a month. All backups will be done giving priority to the significant collections in Firestore, such as Vocabulary Entries, Audio Recording, Validations, and Learning Progress.


System Security Plan
An extensive System Security Plan is set up in order to ensure the protection of the system’s resources and information. In terms of the Administrator and Validator accounts, the system uses Firebase Authentication and enables Multi-Factor Authentication (MFA) by requiring both TOTP, generated through an authenticator app, and verified email account credentials. Password enforcement and email authentication are employed in relation to regular Learner and Validator accounts. Custom claims of Firebase Authentication are utilized to facilitate role-based access control. The native platform encryption methods and HTTPS protocol are used to secure the transfer of all data from the Flutter mobile application to Firebase and Supabase services. The stored data is protected by the Firestore security rules and Supabase Row Level Security policies. Quarterly vulnerability assessments are conducted in order to detect and patch any security vulnerabilities. This includes Supabase access policy review, Flutter dependencies scan for known CVEs, and Firestore security rules audit using Firebase Emulator Suite. To establish whether it is possible to restore Firestore export and Supabase Storage backup successfully into a staging environment with an acceptable recovery time objective, the disaster recovery process is carried out every six months using data loss simulations. In order to ensure compliance with the requirements of the Data Privacy Act of 2012 (RA 10173), security upgrades and incident response plan is updated on a regular basis.
System Security Plan based on ISO/IEC 27001 standard is presented in Table 12, which ensures that the proposed system will utilize well-established and internationally recognized security controls. Such measures will ensure data security and integrity and proper operation of the Lumad Lingua platform.





Table 12. System Security Plan

Security Domain (ISO 27001)
Control Area
Description / Implementation in the System
A.5 Information Security Policies
Security Policy
The implementation of formal security policies will be carried out for data protection, access control, and general use of the system.


A.6 Organization of Information Security
Roles and Responsibilities
The roles (Administrator, Validator, Learner, Educator) will be clearly defined and have specific access rights.


A.9 Access Control
User Access Management
Role-based access control (RBAC) with Firebase custom claims; login credentials for secure authentication will be used.


A.9 Access Control
Authentication Mechanism
Authentication with email/password and strict password policies will be implemented with Firebase Authentication.


A.10 Cryptography
Data Encryption
Secure data transfer will be ensured using HTTPS and Firebase encryption; encryption will also be applied to audio files in Storage.


A.9 Access Control
Multi-Factor Authentication
Two-Factor Authentication with TOTP will be enabled for Administrator and Validator roles with Firebase Authentication.


A.12 Operations Security
Data Processing Integrity
Input validation and error handling will be implemented in Flutter and Cloud Functions; firestore security rules will validate data structure.


A.12 Operations Security
Logging and Monitoring
Log audit will be performed using Firebase Console and version_history subcollection for tracking user actions and changes in content.


A.12 Operations Security
Vulnerability Assessment
Quarterly security assessment, Firebase Emulator based firestore rule audit, Flutter dependency CVE scan, and Supabase access policy review.


A.13 Communications Security
Network Security
Secure protocols for communication (HTTPS, Firebase SDKs) will be used; Firestore security rules will prohibit unauthorized access.


A.11 Physical and Environmental Security
Device Protection
No sensitive data will be saved on a local machine except for Firestore offline cache (encrypted).
A.17 Information Security Aspects of Business Continuity
Data Backup and Recovery
Automatic backups via Firebase will be turned on, while routine exportation of the important Firestore collections will take place.


A.16 Information Security Incident Management
Incident Response
Procedures for identifying, reporting, and responding to security breaches will be developed.


A.14 System Acquisition, Development, and Maintenance
Secure Development
Input validation, safe coding techniques, and testing of Firebase security rules using Emulator Suite will be carried out.


A.17 Business Continuity
Disaster Recovery Testing
Semi-annual disaster recovery tests ensure that Firestore data exports and Supabase Storage backups are restored within Recovery Time Objectives.


A.18 Compliance
Legal and Regulatory Compliance
The system will comply with the requirements of Data Privacy Act (RA 10173), indigenous intellectual property laws, and DNSC guidelines.





System Maintenance Plan

	In addition, the execution of the System Maintenance Plan is scheduled to be undertaken to address issues on the management and maintenance of support for the system, which include regular maintenance of the system through system updating, database optimization, and performance measurement. Problem solving and corrections will also be undertaken under the System Maintenance Plan. Moreover, documentation of maintenance and system updates will be made to improve the system in the future.

Through the maintenance of the system following the quality attributes of ISO/IEC 25010, the System Maintenance Plan as shown in Table 13 below will ensure the sustainability of the LUMAD LINGUA: A GAMIFIED LANGUAGE LEARNING PLATFORM WITH SENTIMENT ANALYSIS FOR THE MANSAKA LANGUAGE.

Table 13. System Maintenance Plan

ISO 25010 Attribute
Maintenance Activity
Description
Frequency
Reliability
System Monitoring
Monitoring Firebase Crashlytics for crash-free session percentage, Firestore queries performance, Firebase Functions logging.
Daily
Performance Efficiency
Performance Optimization
Improvement of Firestore query performance time, audio compression improvement.


As needed
Usability
Interface Improvement
Upgrading UI design for Flutter app according to user feedback; enhancement of gamification animation and pronunciation visualization.


Periodically
Security
Security Updates
Updating Firebase security rules, Flutter dependencies, Firebase SDK versions.


Regularly (Monthly)
Maintainability
Code Refactoring & Debugging
Bugs fixing according to Firebase Crashlytics and user feedback; code optimization for Flutter app.


As needed
Compatibility
System Updates
Compatibility check of the application with new versions of Android and iOS, Firebase SDK, Flutter packages.


Periodically (Quarterly)
Reliability
Content Validation
Periodic checking of vocabulary words and audio recording for accuracy of linguistic information.


Monthly
Performance Efficiency
Database Optimization
Firestore composite indexes analysis, removal of rejected/pending entries older than 6 months.


Weekly
Reliability
Storage Clean-up
Orphaned audio files deletion (not linked with approved vocabulary).


Monthly
Security
Security Rule Testing
Testing Firestore security rules using Firebase Emulator Suite.


After each rule change








REFERENCES
[1]	Ethnologue, "How many languages are endangered?" Ethnologue Insights,
2024.

[2]	T. N. Headland, "Thirty endangered languages in the Philippines," Work Papers
of the Summer Institute of Linguistics, University of North Dakota Session, vol.
47, no. 1, 2016.

[3]	National Commission on Indigenous Peoples, “Indigenous peoples in the     
Philippines,” NCIP, 2023. [Online]. Available: https://ncip.gov.ph

[4] 	K. D. Harrison, When Languages Die: The Extinction of the World’s Languages,
Oxford Univ. Press, 2017.

[5] 	D. Nettle and S. Romaine, Vanishing Voices: The Extinction of the World's
Languages, Oxford Univ. Press, 2018.

[6] 	Republic of the Philippines, Republic Act No. 12027: An Act Discontinuing the
Use of the Mother Tongue as Medium of Instruction, 2024.

[7] 	S. L. Walter and D. E. Dekker, "Mother tongue instruction in Lubuagan: A case
study from the Philippines," Int. Rev. Educ., 2019.

[8] 	S. Bird, "Decoupling Language Documentation and Language Revitalization,"
Language Documentation and Conservation, 2020.

[9] 	K. Richards, "Digitizing Endangered Languages: Challenges and Opportunities,"
Digital Humanities Quarterly, 2019.

[10] 	D. J. Bodenhamer et al., The Spatial Humanities: GIS and the Future of
Humanities Scholarship, Indiana Univ. Press, 2016.

[11] 	S. Deterding, "The Gamification of Learning and Instruction," CHI Workshop,
2016.

[12] 	J. Hamari and K. Keronen, "Why do people play games? A meta-analysis," Int. J.
Inf. Manage., 2017.

[13] Commission on Higher Education (CHED), CHED ACHIEVE Agenda 2030 Brochure, CHED, Quezon City, Philippines, 2025. Accessed: Jul. 28, 2026. [Online]. Available: https://legacy.ched.gov.ph/wp-content/uploads/CHED-ACHIEVE-Agenda-2030-Brochure.pdf

[14] 	M. Turin, "New media, old messages," Oral Tradition, 2018.

[15] 	P. K. Austin, "Current issues in language documentation," Language
Documentation and Description, 2017.

[16] 	A. Kornai, "Digital language death," PLOS ONE, 2016.

[17] 	G. L. Simons, "The Open Language Archives Community," Literary and Linguistic
Computing, 2018.

[18]	S. Bird, "Aikuma: A mobile app for collaborative language documentation,"
LREC, 2017.

[19]	J. S. Lamidi, "The role of GIS in the preservation of indigenous languages," J.
Multilingual Dev., 2021.

[20]	A. Falsaperla, "Open source software in cultural heritage," CIT Journal, 2016.

[21]	N. Ostler, The last lingua franca: English until the return of Babel, Penguin, 2018.

[22] 	D. J. Bodenhamer, "The potential of spatial humanities," IJHAC, 2018.

[23]	T. N. Headland, "Thirty endangered languages in the Philippines," SIL, 2017.

[24] 	L. A. Reid, "The Philippine national language map project," Univ. Hawaii, 2018.

[25]	B. Dumigsi and G. Diez, "The implementation of mother tongue-based
multilingual education in the Philippines," Philippine Journal of Science, 2021.

[26] 	J. M. Sancada, "Phonetic variations in Southern Mindanao languages," Journal
of South Asian Studies, 2022.

[27] 	R. P. Magno, "Heritage and high-tech: The digitalization of Lumad oral traditions,"
Davao Cultural Studies Journal, 2020.

[28] 	P. Rogerson-Revell, "Computer-based pronunciation tools," IJCALLT, 2018.

[29] 	Local Government Davao, "Indigenous knowledge systems and practices (IKSP)
report," 2019.

[30] 	J. Hamari et al., "Does gamification work? A literature review," HICSS, 2017.

[31]	K. Richards, "Visual acoustics in language learning," Journal of MALL, 2019.

[32]  	M. T. Garcia, "Phonetic accuracy in mobile environments," Phil. IT Journal, 2022.

[33] 	R. Cruz, "Spaced repetition and minority languages," MIND Journal, 2020.

[34]	D. Lopez, "Gamified revitalisation strategies for youth," Cultures of Mindanao,
2021.

[35]  	G. Santos, "Digital gaps in the MTB-MLE policy," DepEd Research Journal, 2022.

[36] 	H. Ramos, "Relational databases for cultural archives," IT Heritage, 2019.

[37]  	M. B. Macapagal et al., "Psychosocial impacts of cultural preservation on Lumad
youth," Mindanao Ethnology, 2023.

[38] 	V. C. Cajetas, "Digitizing the Higaonon Language: A Mobile Application for
Indigenous Preservation in the Philippines," ResearchGate, 2025.

[39] 	R. P. Magno, "Digital revitalization of indigenous languages in the Philippines,"
Journal of Language Preservation, 2024.

[40]  	B. Reyes, "Static vs Interactive Archives in Mindanao," Mindanao Tech, 2024.

[41] 	S. Almeda, "Offline-first design for remote regions," Global Dev Tech, 2025.

[42]  	P. H. Tsai, "Optimal implementation setting for computerized visualization cues in
assisting L2 intonation production," System, vol. 87, 102145, Dec. 2019. doi: 10.1016/j.system.2019.102145

[43] 	V. Khaustova, E. Pyshkin, V. Khaustov, J. Blake, and N. Bogach, "CAPTuring
accents: An approach to personalize pronunciation training for learners with different L1 backgrounds," in Speech and Computer, Lecture Notes in Computer Science, Springer, 2023, vol. 14338, pp. 58-72. doi: 10.1007/978-3-031-48312-7_5

[44] 	R. J. Bilog, "Application of Naïve Bayes algorithm in sentiment analysis of
Filipino, English and Taglish Facebook comments," International Journal of Management and Humanities, vol. 4, no. 5, pp. 73–77, 2020.

[45]	M. A. Hasan, J. Tajrin, S. A. Chowdhury, and F. Alam, "Sentiment classification in
Bangla textual content: A comparative study," in Proc. 2020 23rd Int. Conf. Computer and Information Technology (ICCIT), 2020.

[46]	D. Indriani, A. H. Nasution, W. Monika, and S. Nasution, "Towards a sentiment
analyzer for low-resource languages," arXiv, 2020. [Online]. Available: https://arxiv.org/abs/2011.06382

[47]	R. Kumar, "Comparison of HMM and DTW for isolated word recognition system
of Punjabi language," in Proc. 15th Iberoamerican Congress on Pattern Recognition, Springer, 2010, pp. 244–252.

[48]	Z. Miodonska, M. D. Bugdol, and M. Krecichwost, "Dynamic time warping in
phoneme modeling for fast pronunciation error detection," Computers in Biology and Medicine, vol. 69, pp. 277–285, 2016.

[49]	K. Shanmugavadivel, V. E. Sathishkumar, S. Raja, T. B. Lingaiah, S.
Neelakandan, and M. Subramanian, "Deep learning based sentiment analysis and offensive language identification on multilingual code-mixed data," Scientific Reports, vol. 12, no. 1, art. 21557, 2022.

[50]	G. Svelmoe and T. Svelmoe, Mansaka Dictionary (Language Data, Asia-Pacific
Series No. 16). Dallas: Summer Institute of Linguistics, 1990.

[51]	Mountain Math/Language, LLC, "Research Supporting Mountain Math/Language
Educational Review Programs," Mountain Math/Language, 2026. [Online].

[52] 	M. Sokolova and G. Lapalme, "A systematic analysis of performance measures for
classification tasks," Information Processing & Management, vol. 45, no. 4, pp. 427–437, 2009.

[53]	 International Telecommunication Union, Recommendation ITU-T G.722: 7 kHz
audio-coding within 64 kbit/s, ITU-T, 1988.

[54]	C.-I. Lai, "Contrastive predictive coding based feature for automatic speaker
verification," undergraduate thesis, Johns Hopkins University, arXiv preprint arXiv:1904.01575, 2019.
[55] 	 S. Davis and P. Mermelstein, "Comparison of parametric representations for
monosyllabic word recognition in continuously spoken sentences," IEEE Transactions on Acoustics, Speech and Signal Processing, vol. 28, no. 4, pp. 357–366, 1980.



