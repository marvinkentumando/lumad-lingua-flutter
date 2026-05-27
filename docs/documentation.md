LUMAD LINGUA: A GEO-TAGGED DOCUMENTATION PLATFORM WITH GAMIFIED LEARNING MODULES ON SELECTED INDIGENOUS LANGUAGES



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

APRIL 2026
CHAPTER 1
INTRODUCTION

Background of the Study
Language is a fundamental component of cultural identity, heritage, and ancestral knowledge. According to Ethnologue [1], approximately 3,226 languages worldwide—roughly 44% of all living languages—are currently classified as endangered, with the Philippines identified as one of the most linguistically diverse and simultaneously most vulnerable nations in the Asia-Pacific region. In Mindanao, indigenous languages such as Mansaka and Mandaya are facing critical endangerment as the number of fluent speakers continues to decline across generations [2], with the National Commission on Indigenous Peoples (NCIP) noting that intergenerational transmission rates in many Lumad communities have fallen below sustainable levels [3]. The loss of these languages entails far more than the disappearance of words and grammar—it represents the irreversible erasure of oral traditions, ecological knowledge systems, ceremonial practices, and communal identity, as indigenous languages often encode unique conceptual frameworks for understanding the natural world that have no equivalents in dominant languages [4], [5].
Existing efforts to address this crisis remain insufficient. Government initiatives such as the Mother Tongue-Based Multilingual Education (MTB-MLE) policy under DepEd Order No. 16, s.2012 [6] aim to support indigenous languages in early education, yet persistent gaps in instructional materials, teacher training, and centralized digital documentation infrastructure leave preservation efforts fragmented and difficult to sustain [7]. Furthermore, under Republic Act No. 12027, the implementation of MTB-MLE is no longer mandatory for Kindergarten to Grade 3, making its use optional in monolingual classes and potentially further sidelining minority languages like Mansaka in formal school settings. Current documentation tools such as SayMore, while useful, are desktop-based or mobile-only and lack integrated geographic visualization or interactive learning components [8], while the Endangered Languages Project offers no localized modules or community-level geo-tagged data for Philippine indigenous languages [9].
Advancements in mobile technology and Geographic Information Systems (GIS) present a transformative opportunity to bridge this gap. Geo-tagged systems enable the visualization of linguistic data across specific terrains, allowing for the identification of "linguistic deserts" and the mapping of dialectal variations in real-time [10]. Furthermore, gamified learning has emerged as a high-engagement strategy for language acquisition. By integrating levels, feedback loops, and progress tracking, gamification reduces the "affective filter"—the anxiety often associated with learning a language—and sustains motivation among younger users [11]. A centralized mobile platform that merges these spatial documentation tools with interactive pedagogy provides a scalable solution for linguistic preservation [12]. Grounded in the United Nations Sustainable Development Goal 4 (Quality Education), which advocates for inclusive, equitable, and culturally responsive education, this study proposes LUMAD LINGUA: A Geo-Tagged Indigenous Language Documentation Platform with Gamified Learning Modules. By technologizing the Mansaka and Mandaya languages through this platform, this study aims to create a digital stronghold for Mindanao's cultural heritage that is both academically rigorous and community-driven.








Objectives of the Study
The main objective of this study is to develop a cross-platform mobile application that integrates geo-tagged indigenous language documentation with gamified learning modules to support language preservation and community engagement. Specifically, the study aims to:
To identify indigenous vocabulary and phonetic data for Mansaka and Mandaya through community coordination.
To gather audio recordings from native speakers to serve as digital archiving and assessment references.
To collect GPS coordinates and spatial data for the implementation of the geo-tagged documentation system.
To design a digital archiving system that organizes linguistic metadata with role-based accessibility.
To develop an interactive map interface to visualize documentation coverage through heatmaps.
To create gamified learning modules that utilize progress tracking and adaptive quiz algorithms.
To implement an algorithm for pronunciation assessment based on waveform comparison.
To produce a mobile application that features a searchable digital dictionary and interactive modules.
To evaluate the system's performance in terms of usability and technical reliability for local community use.




Significance of the Study
This study contributes to the intersection of information technology, cultural heritage preservation, and educational innovation. The following stakeholders stand to benefit directly from the platform:
Indigenous Communities (Mansaka, Mandaya, and other Lumad groups). The platform provides a centralized, community-accessible archive where linguistic heritage can be organized, preserved, and made retrievable. Crucially, content development is conducted in coordination with community elders and NCIP-recognized tribal leaders, ensuring that documentation reflects authentic linguistic knowledge and respects indigenous intellectual property rights. This co-creation model positions the platform as a community-owned tool rather than an externally imposed archive.
Youth and Students. Young people in Lumad communities, who currently lack accessible and engaging digital tools for indigenous language learning, will benefit from game-based exercises that reduce the cognitive and motivational barriers of language acquisition. By integrating points, progress tracking, and interactive quizzes, the platform targets the 15–25 age demographic whose declining engagement with indigenous languages is a primary driver of intergenerational transmission breakdown.
Language Educators and Researchers. The digital dictionary and structured lesson modules provide ready-to-use resources for educators implementing MTB-MLE curricula. For researchers and linguists, geo-tagged documentation and spatial visualization tools offer quantitative insights into language distribution and documentation coverage gaps, supporting more targeted revitalization strategies.
Government Agencies (NCIP, DepEd, LGUs). Interactive maps visualizing documentation coverage can inform planning for language revitalization programs, helping agencies identify which communities require priority intervention and where educational resources should be directed.
Scope and Limitations
This study focuses on the development of LUMAD LINGUA as a cross-platform mobile application documentation and learning platform targeting the Mansaka language, with reference to Mandaya as a secondary language, across a minimum of three geographic communities in Davao del Norte, Davao de Oro, and Davao Oriental, aiming to document at least 200 vocabulary entries and 50 audio recordings at the beginner level. The system includes audio upload and storage, metadata tagging, geo-tagging via GPS or community-validated manual input, interactive map visualization with a Leaflet.js-based heatmap layer, a searchable digital dictionary, gamified learning modules with defined game storylines (multiple-choice quizzes, matching tasks, and listening exercises), a Leitner-based spaced repetition algorithm, a pronunciation assessment module using an algorithm to detect and evaluate user pronunciation accuracy during practice activities and quiz sections, progress tracking and points system, contribution version history, role-based user management, pre-test and post-test assessments, and a basic analytics dashboard. The platform uses PostgreSQL with PostGIS for spatial database support and Leaflet.js for geographic visualization. All datasets, including vocabulary entries and audio recordings, shall be verified by a linguistic expert prior to integration into the system. Audio recordings must also undergo a verification process before they are uploaded or saved to ensure accuracy and authenticity. Questions used in the gamified learning modules shall be reviewed and corrected to ensure linguistic accuracy before deployment.
The study operates within several limitations. The system implements an algorithm-based pronunciation assessment feature to evaluate user pronunciation during practice and quiz activities; however, it does not employ advanced deep-learning speech recognition models. Translation relies on structured dictionary entries validated by human contributors and verified by a linguistic expert rather than machine learning models. Geographic accuracy depends on user-provided data, mitigated by a coordinator-level validation step before publication. Finally, the prototype is limited to beginner-level content primarily for the Mansaka language and is intended as a scalable digital support tool rather than a replacement for formal linguistic field research.
Review of Related Literature and Works
Related Literature
The development of LUMAD LINGUA is situated at the intersection of digital humanities, geographic information science, and educational technology. The following literature explores the theories and frameworks that support the integration of these fields for indigenous language revitalization.
The shift toward mobile documentation marks a significant departure from traditional linguistic fieldwork. Modern documentation frameworks emphasize "Digital Vitality," which measures a language's ability to survive by establishing a presence in digital communication ecosystems [13]. Recent literature argues that for indigenous languages to remain relevant, they must be accessible through portable interfaces that support multimedia metadata [14]. The integration of cloud-based relational databases allows for the centralization of fragmented oral histories into a single repository [15]. Furthermore, the adoption of Community-Based Language Research (CBLR) shifts native speakers from passive subjects to active co-creators of the archive [16]. Studies indicate that providing community members with mobile tools increases the volume and authenticity of data collected compared to formal academic interviews [17]. Technological trends suggest that successful archiving systems must prioritize interoperability, ensuring that data recorded on one mobile platform can be easily migrated across global repositories [18], [19].
These studies collectively emphasize that modern archiving is a portable and community-driven process. The literature establishes that successful documentation requires adherence to mobile accessibility standards and collaborative creation to ensure that indigenous knowledge remains functional for future generations in remote areas.
Geographic Information Systems (GIS) have revolutionized the humanities by adding a spatial layer to cultural data. In linguistics, mapping helps researchers understand the ecological and social factors that influence language survival [20]. Mobile-based geo-tagging allows for the real-time recording of GPS coordinates alongside audio data, providing a visual representation of linguistic density through heatmap overlays [21]. These heatmaps are critical for researchers to identify areas where a language has ceased to be spoken, enabling targeted revitalization efforts [22]. Recent advancements in open-source mapping libraries have enabled the development of lightweight mobile GIS applications that function with limited hardware resources [23]. This is particularly relevant in Mindanao, where many indigenous communities reside in remote areas with inconsistent connectivity [24]. Literature suggests that spatial documentation platforms must incorporate offline-first synchronization to ensure that data captured in remote terrains is not lost [25]. By visualizing the "heartlands" of the Mansaka and Mandaya languages, these spatial tools provide a clear roadmap for cultural preservation [26].
The literature on spatial humanities demonstrates that geographic context is inseparable from linguistic data. By integrating mobile GIS tools, researchers create a visual representation of language health directly from the field, providing a necessary spatial framework for revitalization.
Mobile-Assisted Language Learning (MALL) has emerged as a dominant trend for minority languages that lack formal classroom representation [27]. The success of MALL is largely attributed to gamification—the application of game-design elements like levels and points to educational tasks [28]. Recent research demonstrates that gamified learning significantly reduces the "affective filter," which is the psychological barrier of anxiety and fear of failure that often hinders learners [29]. Technical studies in Computer-Assisted Language Learning (CALL) have highlighted the importance of immediate, visual feedback. For example, the use of waveform comparison allows users to see a visual representation of their voice compared to a native speaker’s recording [30]. This visual-acoustic feedback is significantly more effective for phonetic acquisition than simple text-based corrections [31]. Furthermore, the implementation of Spaced Repetition Systems (SRS) within mobile apps ensures that vocabulary is reviewed at optimal intervals, maximizing long-term retention [32]. These gamified strategies are essential for attracting the interest of the 15–25 age demographic, who are the primary drivers of future linguistic survival [33].
In the Philippine context, the implementation of MTB-MLE has faced logistical hurdles, including a lack of localized digital materials [34]. Local studies in the Davao region highlight that indigenous groups have a strong desire for digital representation but lack the technical platforms to achieve it [35]. Research in Mindanao specifically points to the need for "technologizing" indigenous identity through mobile applications that reflect unique cultural nuances [36]. Recent findings emphasize that culturally responsive mobile interventions, such as digital dictionary applications developed with tribal elders, show high satisfaction ratings among native speakers in Mindanao [37]. Effective preservation requires software that respects intellectual property while addressing practical community needs like offline accessibility [38]. Contemporary initiatives suggest that merging digital archiving with interactive pedagogy is the most viable path to prevent language loss in digitally native generations [39], [40].
National and local literature reveals a significant disconnect between educational policy and the availability of localized tools. While there is a strong academic understanding of language endangerment in Mindanao, there is a critical shortage of localized mobile platforms that can bridge traditional knowledge with modern digital learning for the Lumad people.
Despite these developments, significant gaps remain. Most studies focus on documentation for academic research purposes, often neglecting the creation of localized, community-accessible platforms that facilitate interactive learning. Additionally, there is a notable absence of integrated systems that combine spatial analysis with gamified modules specifically designed for the needs of Lumad communities. These identified deficiencies justify the development of LUMAD LINGUA, which merges digital archiving, geographic visualization, and structured interactive learning into a single cohesive platform.

Related Works
Various linguistic documentation and learning systems have been developed to address language endangerment. These platforms typically provide tools for archiving and metadata management, though many lack integrated spatial analysis or interactive pedagogical features. While global projects offer broad accessibility, they often miss the localized community validation and gamified engagement necessary for effective intergenerational transmission.
The following table provides a comparison between existing systems and the proposed platform based on key functional requirements:

System
Mobile app Platform
Digital Archiving
Geo-Tagging & Mapping
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




✓
LUMAD LINGUA (Proposed)
✓
✓
✓
✓
✓
✓
✓

Table 1. Comparison of existing systems vs. the proposed system.
The comparative analysis in Table 1 demonstrates that while established platforms provide robust individual functionalities, none offer a fully integrated solution for the Mansaka and Mandaya languages. Duolingo is the industry leader in Gamified Learning and Pronunciation Assessment, yet it lacks the Digital Archiving and Community Validation required to safeguard endangered languages, nor does it support the specific indigenous dialects of Mindanao.
On the other hand, FirstVoices serves as a modern benchmark for Digital Archiving and Community-Led Metadata, utilizing an interactive map to show language territories. However, it lacks the high-engagement Gamified Modules necessary to sustain the interest of younger learners and does not feature automated Pronunciation Assessment for real-time feedback.
LUMAD LINGUA addresses these gaps by merging the addictive pedagogy of Duolingo with the rigorous archiving and community-centric standards of FirstVoices. Most notably, it introduces Geo-Tagging & Mapping at a granular level to visualize documentation gaps in real-time. This combination ensures that the platform is not only an effective learning tool but also a scientifically sound instrument for the preservation and revitalization of Philippine indigenous heritage.












Definition of Terms
Community Co-Creation. Refers to the collaborative approach used in the platform where indigenous stakeholders, elders, and native speakers participate in the validation and contribution of linguistic content to ensure cultural authenticity.
Cross-Platform Development. Refers to the development approach (e.g., using Flutter or React Native) that allows the application to run on both Android and iOS devices using a single codebase.
Digital Archiving. Refers to the systematic process of storing and preserving digital versions of indigenous linguistic data, including audio recordings and metadata, to prevent the loss of endangered languages.
Digital Dictionary. Refers to the searchable electronic repository within the system that provides translations, definitions, and audio pronunciations for the Mansaka and Mandaya languages.
Gamification. Refers to the integration of game-design elements, such as quizzes, listening exercises, and vocabulary drills, into the learning modules to enhance user engagement and retention.
Geo-tagging. Refers to the process of attaching geographical identification metadata, such as GPS coordinates, to linguistic entries to track where specific dialects or terms are documented.
GIS (Geographic Information System). Refers to the technical framework used within the platform to capture, store, and display spatial data related to the distribution of indigenous languages.
Heatmap. Refers to the data visualization technique used in the platform’s interactive map to represent the density and coverage of documented language data across different geographical areas.
Lumad. Refers to the collective identity of the non-Muslim indigenous peoples of Mindanao, such as the Mansaka and Mandaya, whose languages and cultural heritage are the primary focus of this documentation and revitalization project.
LUMAD LINGUA. Refers to the title of the proposed mobile documentation and learning platform designed specifically for the preservation and revitalization of selected indigenous languages in Mindanao.
Mansaka. Refers to an indigenous group in the Philippines, primarily residing in the Davao Region (Davao de Oro and Davao del Norte) that serves as the primary subjects of the documentation and learning modules.
MTB-MLE (Mother Tongue-Based Multilingual Education). Refers to the Philippine educational policy that promotes the use of a learner's native language as the primary medium of instruction, which this platform aims to support digitally.
Pronunciation Assessment. Refers to the system feature that evaluates a user’s spoken input by comparing it against reference recordings using waveform-based feedback to assist in language acquisition.
Waveform. Refers to the visual representation of an audio signal used in the platform to provide users with a comparative visual guide for improving their pronunciation accuracy.







CHAPTER 2
METHODOLOGY

The project adopts a Hybrid Project Management Methodology that combines the structured approach of Waterfall and the flexibility of Agile to effectively support the requirements of a capstone project as illustrated in Figure 1. The Waterfall approach is applied during the initial stages, particularly in planning, requirements definition, and documentation, ensuring that all outputs such as proposals and system designs are clearly defined and validated before development begins. Meanwhile, Agile practices are utilized during the implementation and testing phases, allowing iterative development, continuous testing, and incremental improvement of system features such as geo-tagging, gamified learning modules, pronunciation assessment, and content validation. This integration enables a balance between structure and adaptability, making it suitable for systems with both well-defined requirements and evolving components, such as gamification logic and user interface enhancements.
The project begins with the Planning phase, where the proponents defined the project scope, objectives, timeline, and required resources based on the approved concept paper. During this phase, they also established the overall direction of the system and ensured its feasibility within the given timeframe. In the Analysis phase, the proponents gathered and finalized system requirements by reviewing existing language documentation processes, identifying user needs, and determining both functional and non-functional requirements necessary for the system.
In the Design phase, the proponents translated these requirements into a structured system architecture, including the design of the Firestore database schema, user interface mockups, and overall system flow, supported by diagrams and prototypes to visualize how the system will operate. During the Implementation phase, the proponents developed the system using an iterative approach, where coding, integration of Flutter components, and testing were performed incrementally. This allowed them to refine features such as the interactive map with heatmap overlay, gamified learning modules with Leitner spaced repetition, pronunciation assessment using waveform comparison, and validation workflows based on testing results.

Finally, in the Maintenance phase, the proponents conducted system evaluation, identified issues, and applied necessary improvements to enhance system performance and usability. Although limited within the project duration, this phase ensured that the system remains stable, reliable, and ready for future enhancements.

Figure 1. Integrated Hybrid Project Management Approach


SYSTEM PLANNING

Project Team Organization

The project team, as shown in Figure 2, is organized to ensure effective coordination and clear distribution of responsibilities. The Adviser provides overall guidance and ensures that the project meets academic and technical standards. The Project Manager oversees planning, task coordination, and progress monitoring to ensure timely completion of the project. Supporting roles include the Mobile Developer, who handles Firebase backend implementation and Flutter integration, and the UI/UX and Flutter Developer, who is responsible for requirements analysis, interface design, and mobile application development. This structure enables efficient collaboration and balanced management of both technical and documentation aspects of the project.


Figure 2. Project Management Team Organization

Work Breakdown Structure

	The Work Breakdown Structure (WBS) as presented in Figure 3, is a phase-based decomposition of the project aligned with the PADIM framework, clearly outlining the tasks involved in each stage of system development. It organizes activities from Planning, Analysis, Design, Implementation, to Maintenance, allowing the proponents to systematically manage and track project progress. Each phase is broken down into specific tasks such as requirement preparation, system design, development, testing, and evaluation, ensuring that all necessary activities are identified and completed. For the Lumad Lingua project, these tasks include community coordination for vocabulary collection, Firebase project setup, Flutter development, geo-tagging implementation, gamified module development, pronunciation assessment integration, and content validation workflows. This structured approach helps improve task allocation, time management, and overall project organization.




Figure 3. Work Breakdown Structure






Gantt Chart

	The Gantt chart in Figure 4, presents the timeline and schedule of activities for the development of the Lumad Lingua: A Geo-Tagged Documentation Platform with Gamified Learning Modules on Selected Indigenous Languages, aligning tasks with the PADIM framework. It illustrates the sequence and duration of each phase — from Planning and Analysis to Design, Implementation, and Maintenance — ensuring that all activities such as requirement finalization, system design, Firebase project configuration, Flutter development, geo-tagging integration, gamification module coding, content collection, linguistic validation, testing, and deployment are completed within the specified timeframe. The chart helps the proponents monitor progress, manage time effectively, and ensure that each phase is completed on schedule, supporting the timely and organized completion of the capstone project.



















Figure 4. Gantt Chart of the System



SYSTEM ANALYSIS

System Architecture

The system architecture as shown in Figure 5, of the project Lumad Lingua presents a structured framework that illustrates how the different components of the system interact to support digital language documentation, geo-tagging, gamified learning, and content validation. The architecture is composed of three main components: the client layer (Flutter mobile application), the backend layer (Firebase services), and external services (OpenStreet Map SDK and device hardware).

At the client level, the system utilizes a cross-platform mobile application built with Flutter and Dart, deployed on Android and iOS devices. Four primary user roles interact with the system: Contributors, Learners, Validators or Linguistic Experts, and Administrators. Contributors input vocabulary entries and upload audio recordings. Learners access gamified modules, the digital dictionary, and the interactive map. Validators review and validate submitted content before publication. Administrators manage system settings, user accounts, and view analytics dashboards. The Flutter application handles user authentication through Firebase Authentication, renders role-specific interfaces, and maintains local data persistence for offline functionality in remote areas with inconsistent connectivity.

At the backend level, the system integrates several Firebase services. Firebase Authentication manages user accounts and enforces role-based access control through custom claims. Cloud Firestore serves as the NoSQL document database, storing vocabulary entries, user profiles, geo-tag coordinates, validation records, version history, gamification progress, and quiz results. Firebase Storage manages all audio file uploads, storage, and streaming playback. Firebase Cloud Functions, written in Node.js and TypeScript, handle server-side processing including validation workflow triggers, pronunciation scoring calculations, and analytics aggregation.

The external services component includes the OpenStreet Map SDK integrated via the google_maps_flutter plugin, which provides the base map tiles and location services. The device hardware layer includes the GPS receiver for coordinate capture through the geolocator package and the device microphone for audio recording during pronunciation assessment through the flutter_sound package.

The data management component consists of Cloud Firestore for structured data and Firebase Storage for audio files, where all vocabulary entries, user profiles, geo-tags, validation records, and learning progress are stored and managed. This enables efficient data retrieval, spatial queries using geohashes, and report generation. The system supports offline-first synchronization, allowing contributors to record content and learners to complete lessons without internet connectivity.


Figure 5. System Architecture of the Project


Functional and Non-functional Requirements

The functional and non-functional requirements define the expected capabilities and quality attributes of the proposed Lumad Lingua: A Geo-Tagged Documentation Platform with Gamified Learning Modules on Selected Indigenous Languages. The functional requirements specify the core features of the system, including vocabulary documentation, audio recording upload, geo-tagging, digital archiving, map visualization, gamified learning, pronunciation assessment, and role-based access control. Meanwhile, the non-functional requirements describe how well the system performs, focusing on aspects such as reliability, usability, security, and performance efficiency based on ISO/IEC 25010 standards. These requirements ensure that the system operates effectively, delivers accurate linguistic content, and supports both documentation and learning objectives for Lumad communities.

The system shall provide the following functionalities:
The system shall allow community contributors to submit indigenous vocabulary entries for Mansaka and Mandaya languages, including terms, translations, and usage context, stored in Cloud Firestore.
The system shall enable users to upload audio recordings from native speakers to Firebase Storage for digital archiving and pronunciation reference.
The system shall attach geographic coordinates to vocabulary entries using the device GPS via the geolocator package or validated manual input, with coordinator-level validation before publication.
The system shall store all documented linguistic data, including metadata, audio file references, and version history, in a centralized digital archive using Firestore and Firebase Storage.
The system shall display an interactive map interface using google_maps_flutter with custom heatmap overlays to visualize documentation coverage and identify linguistic gaps across geographic areas.
The system shall provide gamified learning modules that include multiple-choice quizzes, matching tasks, listening exercises, and a Leitner-based spaced repetition algorithm for vocabulary review scheduling.
The system shall implement a pronunciation assessment algorithm that compares user speech input against reference audio recordings using waveform comparison with dynamic time warping.
The system shall maintain a searchable digital dictionary that allows users to look up indigenous terms, Filipino and English translations, and associated audio samples streamed from Firebase Storage.
The system shall enforce role-based access control using Firebase Authentication custom claims, distinguishing between learners, contributors, validators, and administrators.
The system shall track learner progress through points, levels, quiz results, completion status, and streak mechanics stored in Firestore per user profile.
The system shall require linguistic expert validation for all vocabulary entries, audio recordings, and quiz questions before deployment, enforced through Firestore security rules and Cloud Functions triggers.
The system shall maintain version history for all contributed entries using Firestore document versioning, allowing auditing and restoration of previous versions.
The system shall generate basic analytics and reports for administrators, including documentation coverage metrics and learner performance summaries, using Firestore aggregated data.
The system shall conduct pre-test and post-test assessments to measure learning effectiveness and platform impact on language acquisition.
The system shall support offline data persistence through Firestore's built-in offline capabilities, allowing contributors to record content and learners to complete lessons without internet connectivity.

The following are the system's non-functional requirements:
Performance Efficiency. The system shall process and display dictionary searches and map interactions with minimal latency. Application cold start time shall be less than three seconds on a mid-range Android device.
Reliability. The system shall ensure continuous operation and accurate data storage with minimal downtime. Audio recordings stored in Firebase Storage shall be preserved without corruption.
Usability. The system shall provide a user-friendly mobile interface that is easy to learn and operate for both technical and non-technical users, including community elders.
Security. The system shall protect data through Firebase Authentication, role-based access control, and secure data transmission protocols. Firestore security rules shall enforce that only validated content is readable by learners.
Compatibility. The system shall be accessible across different devices such as Android and iOS smartphones and tablets via the Flutter cross-platform mobile application.
Maintainability. The system shall be designed for easy updates, debugging, and system enhancements through modular Flutter architecture and Firebase console configuration.
Scalability. The system shall support expansion to additional vocabulary entries, audio files, and users without significant performance degradation, accommodating expansion to additional Lumad languages.
Availability. The system shall be accessible to authorized users whenever needed, supported by Firestore's built-in availability and offline persistence.







Use Case Diagram

The primary users as shown in Figure 6, identified in the system are the Administrator, Contributor, Validator or Linguistic Expert, and Learner. The Administrator is responsible for managing and maintaining the system, including managing user accounts, configuring system settings, and viewing reports and analytics. These interactions ensure that the system operates according to the defined parameters and remains aligned with user requirements. The administrator provides configuration and control data to the system, which is then processed and stored for system operation.

The Contributor interacts with the system by submitting vocabulary entries, uploading audio recordings, adding geo-tagged location data, and editing their own submissions. The system processes these contributions as pending content awaiting validation. The Validator or Linguistic Expert reviews pending submissions, validates vocabulary and audio recordings, and approves or rejects content to ensure linguistic accuracy and authenticity before publication.

On the other hand, the Learner interacts with the system by searching the digital dictionary, accessing geo-tagged language records, engaging in gamified learning modules, taking quizzes and exercises, recording pronunciation attempts, and tracking their progress and performance. These interactions enable immediate response and engagement with the language learning content.




Figure 6. Use Case Diagram of the System

Context Flow Diagram

	The Context Flow Diagram shown in Figure 7, presents a high-level view of the Lumad Lingua: A Geo-Tagged Documentation Platform with Gamified Learning Modules on Selected Indigenous Languages, illustrating how the system interacts with external entities and how data flows across the platform. It focuses on the logical flow of business processes, highlighting key inputs, processes, and outputs without detailing the internal system structure.

In the diagram, the main external entities include the Administrator, Community Contributor, Validator or Linguistic Expert, and Learner or Youth User. The Community Contributor serves as the primary source of raw linguistic input by submitting vocabulary entries, uploading audio recordings, and attaching geo-tagged location data to their contributions. This data is transmitted to the system for storage as pending content awaiting review, and the contributor receives submission status updates in return.

The Validator or Linguistic Expert interacts with the system by receiving pending submissions for review. After evaluation, the expert returns approved content and corrections back to the system, ensuring that all vocabulary entries, translations, and audio recordings meet linguistic standards and reflect authentic indigenous knowledge before they are made accessible within the platform.

The Administrator manages the overall operation of the system by providing user and system configuration data as well as content approval decisions. In return, the system furnishes the administrator with analytics and reports as well as system status information to support informed decision-making and platform oversight.

The diagram also shows key data flows such as vocabulary entries, audio recordings, geo-tagged data, validation decisions, quiz responses, and learning module content, which represent the essential interactions between the system and its external entities. These flows demonstrate how data is collected, processed, and transformed into meaningful outputs that support language preservation and interactive learning for Lumad communities.



Figure 7. Context Flow Diagram of the Lumad Lingua System


Data Flow Diagram

	The Level 1 Data Flow Diagram (DFD) in Figure 8 presents a more detailed representation of the Lumad Lingua platform by expanding the processes identified in the Level 0 (Context Diagram). This level breaks down the system into major sub-processes, showing how data flows between components while maintaining the same external entities and data inputs and outputs from the previous diagram.
In this diagram, the system is decomposed into several key processes, including user management, content submission, content validation, archiving and geo-tagging, learning module delivery, and report generation. The Community Contributor remains the primary source of input, submitting vocabulary entries, audio recordings, and geo-tagged data to the system. This data is received and handled by the content submission process, which forwards it as pending content to the validation process for review by linguistic experts.

The Validator or Linguistic Expert continues to interact with the system by providing inputs such as approval decisions, corrections, and validation remarks. These inputs are processed through the content validation module, ensuring that content quality standards are properly maintained and stored for operational use.

The processed data then flows into the archiving and geo-tagging process, where verified vocabulary entries, audio recordings, and geographic coordinates are stored in Firestore and Firebase Storage. Once archived, the data is made available to the learning module delivery process, which serves gamified learning content, dictionary searches, and map visualizations to learners. In addition, the system stores all relevant data in a database, which is used by the report generation process to produce summaries of documentation coverage, learner progress, and system performance for administrators.



Figure 8. Level 1 Data Flow Diagram of the Lumad Lingua System

SYSTEM DESIGN

Entity Relationship Diagram

	The Entity Relationship Diagram (ERD) illustrated in Figure 9, is the structure of the database for the proposed Lumad Lingua platform, showing how data entities are organized and related to one another. In this context, entities represent the major data components of the system, such as Users, Languages, Vocabulary Entries, Audio Recordings, Geo Tags, Contributions, Validations, Version History, Gamified Modules, Quiz Results, and Learning Progress, which are essential for system operation and data management.

The Users entity stores information about system users, including administrators, contributors, validators, and learners, and is linked to roles and access privileges. The Languages entity represents the supported indigenous languages, primarily Mansaka and Mandaya. These languages are associated with Vocabulary Entries, which store documented words, translations, and usage context. Each vocabulary entry can have multiple Audio Recordings associated with it, capturing native speaker pronunciations.

The system processes contributions through the Contributions entity, which tracks submissions from contributors, and the Validations entity, which records review decisions from linguistic experts. The Version History entity maintains an audit trail of changes made to entries. Additionally, the Geo Tags entity stores geographic information associated with vocabulary entries, enabling map visualization and spatial queries.

For the gamified learning component, the Gamified Modules entity stores learning module information, while the Quiz Results entity tracks learner performance. The Learning Progress entity stores accumulated points, levels, and progress data for each learner. Relationships between these entities are defined through references and identifiers, ensuring data integrity and consistency. For example, one user can have multiple contributions (one-to-many relationship), while one vocabulary entry can have multiple audio recordings and multiple validation records.


Figure 9. Entity Relationship Diagram of the System


JSON Schema Diagram

	Figure 10, JSON schemas are used to represent key data components such as vocabulary entries, user information, audio recordings, geo-tags, and gamification data. For instance, a vocabulary entry schema specifies required fields such as entry ID, indigenous term, Filipino translation, English translation, usage context, language ID, and status, along with their corresponding data types (e.g., string, number, or boolean). Similarly, the geo-tag schema defines the structure of location data associated with vocabulary entries, including latitude, longitude, place name, community, and geohash for spatial queries.

The diagram also illustrates validation rules such as required fields, data types, value constraints, and formatting standards. These rules ensure that incoming data from community contributors and coordinator-validated uploads are properly validated before being processed by the system. This reduces errors, prevents invalid data entry, and enhances system reliability.(number), quiz_type (string, e.g., multiple-choice, matching, listening), and srs_interval (number), which drives the Leitner-based spaced repetition algorithm for vocabulary review scheduling.

Moreover, the use of JSON Schema supports interoperability between different system components and external services. Since the system relies on real-time data transmission between the Flutter mobile application, Firebase services, and external APIs, having a standardized data format ensures seamless communication between components. The schema also includes the gamification object, which stores learning module metadata such as difficulty level, quiz type, and spaced repetition interval, driving the Leitner-based algorithm for vocabulary review scheduling.





Figure 10. JSON Schema Diagram
Data Dictionary

	The Data Dictionary presents a detailed description of all data elements used in the proposed Lumad Lingua: A Geo-Tagged Documentation Platform with Gamified Learning Modules on Selected Indigenous Languages, serving as a reference for the system's Firestore database structure and data organization. It defines the collections, fields, data types, and descriptions to ensure consistency, accuracy, and proper understanding of how data is stored and managed within the system. This section is essential in guiding the implementation of the database and supporting system development, maintenance, and future enhancements.

Table 1 provides an overview of all the database collections utilized in the system, such as Users, Languages, Vocabulary Entries, Audio Recordings, Geo Tags, Contributions, Validations, Version History, Gamified Modules, Quiz Results, and Learning Progress. Each collection represents a specific data component necessary for system functionality. For instance, the Users collection contains account and role information for administrators, contributors, validators, and learners, while the Vocabulary Entries and Audio Recordings collections store information related to documented indigenous words and their associated pronunciations.

Table Name
Description
Users
Stores account information and roles of system users.
Languages
Stores the supported indigenous languages in the platform.
Vocabulary_Entries
Stores documented words, translations, and usage context.
Audio_Recordings
Stores metadata of uploaded or recorded audio files.
Geo_Tags
Stores geographic information associated with entries.
Contributions
Stores contributor submission records.
Validations
Stores content review and approval records.
Version_History
Stores changes made to entries for auditing purposes.
Gamified_Modules
Stores learning module information.
Quiz_Results
Stores learner quiz performance records.
Learning_Progress
Stores points, level, and learner progress data.

Table 1. Database Tables of the System

Field Name
Data Type
Constraint
Description
user_id
Integer
Primary Key
Unique identifier of the user
full_name
Varchar
Not Null
Full name of the user
email
Varchar
Unique, Not Null
Email address used for login
password
Varchar
Not Null
Encrypted user password
role
Varchar
Not Null
User role such as learner, contributor, validator, or administrator
status
Varchar
Not Null
Status of the account

Table 1.1 Users Table

Field Name
Data Type
Constraint
Description
language_id
Integer
Primary Key
Unique identifier of the language
language_name
Varchar
Not Null
Name of the indigenous language
description
Text
Nullable
Description of the language

Table 1.2 Languages Table

Field Name
Data Type
Constraint
Description
entry_id
Integer
Primary Key
Unique identifier of the entry
language_id
Integer
Foreign Key
References the language of the term
term
Varchar
Not Null
Indigenous word or phrase
filipino_translation
Varchar
Not Null
Filipino translation
english_translation
Varchar
Not Null
English translation
usage_context
Text
Nullable
Example usage or meaning context
status
Varchar
Not Null
Entry status such as pending, approved, or rejected

Table 1.3 Vocabulary Entries Table

Field Name
Data Type
Constraint
Description
audio_id
Integer
Primary Key
Unique identifier of the audio file
entry_id
Integer
Foreign Key
References the related vocabulary entry
file_path
Varchar
Not Null
Storage path of the audio file
speaker_name
Varchar
Nullable
Name of the speaker
date_recorded
Date
Nullable
Date when the audio was recorded
verification_status
Varchar
Not Null
Indicates whether the audio is verified

Table 1.4 Audio Recordings Table

Field Name
Data Type
Constraint
Description
geotag_id
Integer
Primary Key
Unique identifier of the geotag
entry_id
Integer
Foreign Key
References the related vocabulary entry
place_name
Varchar
Not Null
Name of the location
latitude
Decimal
Not Null
Latitude coordinate
longitude
Decimal
Not Null
Longitude coordinate
validation_status
Varchar
Not Null
Status of geographic validation

Table 1.5 Geo Tags Table

Field Name
Data Type
Constraint
Description
contribution_id
Integer
Primary Key
Unique identifier of the contribution
user_id
Integer
Foreign Key
References the contributor
entry_id
Integer
Foreign Key
References the submitted entry
submission_date
Date
Not Null
Date of submission
contribution_type
Varchar
Not Null
Type of contribution such as vocabulary, audio, or location

Table 1.6 Contributions Table






Field Name
Data Type
Constraint
Description
validation_id
Integer
Primary Key
Unique identifier of the validation record
user_id
Integer
Foreign Key
References the validator
entry_id
Integer
Foreign Key
References the reviewed entry
decision
Varchar
Not Null
Validation result
remarks
Text
Nullable
Comments of the validator
validation_date
Date
Not Null
Date of validation

Table 1.7 Validations Table

Field Name
Data Type
Constraint
Description
version_id
Integer
Primary Key
Unique identifier of the version record
entry_id
Integer
Foreign Key
References the modified entry
change_summary
Text
Not Null
Summary of changes made
modified_date
Date
Not Null
Date of modification
modified_by
Varchar
Not Null
User who made the change

Table 1.8 Version History Table









Field Name
Data Type
Constraint
Description
module_id
Integer
Primary Key
Unique identifier of the learning module
module_title
Varchar
Not Null
Title of the module
module_type
Varchar
Not Null
Type such as quiz, matching, or listening activity
difficulty_level
Varchar
Not Null
Difficulty level of the module

Table 1.9 Gamified Modules Table

Field Name
Data Type
Constraint
Description
result_id
Integer
Primary Key
Unique identifier of the quiz result
user_id
Integer
Foreign Key
References the learner
module_id
Integer
Foreign Key
References the gamified module
entry_id
Integer
Foreign Key
References the related vocabulary entry
score
Integer
Not Null
Score obtained by the learner
date_taken
Date
Not Null
Date when the quiz was completed

Table 1.10 Quiz Results Table










Field Name
Data Type
Constraint
Description
progress_id
Integer
Primary Key
Unique identifier of progress record
user_id
Integer
Foreign Key
References the learner
points
Integer
Not Null
Accumulated points
level
Varchar
Not Null
Current learner level
status
Varchar
Not Null
Current progress status

Table 1.11 Learning Progress Table

Technologies, Concepts, and Theories

	This section presents the key models, algorithms, and emerging technologies utilized in the development of the Lumad Lingua platform. It explains how data is processed from acquisition to decision-making, as well as the tools and technologies used to implement the system. The discussion follows the major stages of the system workflow, including data collection, pre-processing, feature extraction, and classification.

Data Collection

Data collection is performed through community-driven contribution workflows where native speakers and trained contributors submit vocabulary entries, audio recordings, and geo-tagged location data through the Flutter mobile application. Vocabulary entries include the indigenous term, Filipino translation, English translation, and usage context. Audio recordings capture native speaker pronunciation using the device microphone via the flutter_sound or record package and are stored as compressed audio files in Firebase Storage. Geographic coordinates are collected through the device GPS using the geolocator package or through manually validated input from community coordinators, with coordinates converted to geohashes for efficient spatial queries using GeoFlutterFire2. This process ensures that the system receives authentic, community-sourced linguistic data necessary for documentation and learning.





Data Pre-Processing

Before storage and analysis, the collected data undergoes pre-processing to improve its quality and reliability. For vocabulary entries, this includes checking for duplicate submissions in Cloud Firestore, standardizing spelling variations, and validating that required fields are complete. For audio recordings, pre-processing involves noise reduction, normalization of volume levels, and conversion to a consistent file format suitable for waveform comparison. Geo-tagged coordinates are validated against reasonable geographic bounds for Mindanao and converted to geohash strings for spatial queries. Pre-processing ensures that the input data is clean and suitable for digital archiving, map visualization, and pronunciation assessment, reducing the likelihood of errors in the learning modules.

Feature Extraction

Feature extraction involves identifying relevant attributes from the collected data that contribute to language documentation and pronunciation assessment. Key features for the digital dictionary include the indigenous term, translations, usage context, and associated Firebase Storage audio file reference. For geographic visualization, features include latitude, longitude, geohash, and documentation density metrics. For pronunciation assessment, acoustic features are extracted from audio recordings, including Mel-frequency cepstral coefficients (MFCCs), which represent the short-term power spectrum of sound and are widely used in speech processing. These features are used to represent the current linguistic content and serve as inputs to the pronunciation assessment algorithm. Extracting meaningful features improves the accuracy and efficiency of the system.

Classification

The system utilizes a waveform comparison algorithm with dynamic time warping to assess learner pronunciation accuracy. This approach compares acoustic features extracted from the learner's spoken input against features extracted from a verified reference recording from a native speaker from Firebase Storage. The dynamic time warping algorithm aligns two sequences of feature vectors to account for variations in speaking rate and computes a distance score normalized to a user-friendly percentage or feedback rating. This hybrid approach enhances detection accuracy and provides interpretable visual feedback to learners, allowing them to see a graphical representation of their recording aligned with the reference waveform using Flutter's custom painting capabilities.

The system uses this algorithm because it balances reasonable accuracy with low computational requirements, making it suitable for mobile devices common in rural Philippine communities. Research has established that computerized visualization cues such as waveforms and spectrograms can assist second language pronunciation production when learners' attention is explicitly directed to the visual feedback [41].

Furthermore, a 2023 study on computer-assisted pronunciation training demonstrated that Dynamic Time Warping (DTW) algorithms remain relevant for pronunciation evaluation, with modern systems using DTW to generate assessment scores after adapting learner accents through neural style transfer techniques [42]. This hybrid approach addresses the limitation of traditional automatic speech recognition models trained solely on native speakers, which have been shown to result in lower accuracy when applied to non-native speakers [42]. Table 2 presents a comparison of pronunciation assessment approaches considered for the system.

Approach
Accuracy
Computational Requirement
Interpretable Feedback
Suitability for Offline Use
Waveform Comparison with Dynamic Time Warping
Moderate to High
Low
High
Excellent
Hidden Markov Models
High
Moderate
Low
Moderate
Deep Neural Networks / Advanced ASR
Very High
Very High
Low
Poor
Rule-based Phonetic Matching
Moderate
Very Low
Moderate
Excellent


Table 2. Comparison of Pronunciation Assessment Approaches

	Based on the comparison presented in Table 2, the waveform comparison approach with dynamic time warping was selected as the most appropriate for the Lumad Lingua platform. According to Khaustova et al. [42], DTW-based evaluation remains effective for pronunciation training systems, particularly when integrated with accent recognition technology to provide personalized feedback. Additionally, Tsai [41] demonstrated that explicit direction of learners' attention to computerized visualization cues leads to more significant intonational gain, supporting the system's design choice to provide clear, interpretable visual feedback through waveform displays. This selection prioritizes accessibility, interpretability, and offline functionality — critical features for language preservation tools serving indigenous communities in remote areas with limited connectivity.

Technologies Used in the System

Cross-Platform Mobile Framework (Flutter)

The system primarily relies on Flutter 3.x, Google's cross-platform mobile development framework using the Dart programming language, as shown in Figure 11. Flutter enables the development of native-compiled applications for both Android and iOS from a single codebase, significantly reducing development time and maintenance effort. This approach is particularly suitable for the Lumad Lingua platform because it ensures consistent functionality across both mobile platforms commonly used in rural Philippine communities. Flutter's widget-based architecture allows for highly customizable user interfaces with smooth animations essential for gamified learning experiences, including quiz transitions, level-up animations, and real-time waveform visualizations using Flutter's CustomPainter engine. For state management, the system implements Riverpod, providing a scalable architecture for managing the quiz engine, user session state, and map interactions across the application.



Figure 11. Flutter Framework

Firebase Backend Services

To enhance backend capabilities without managing dedicated server infrastructure, the system integrates Firebase as the primary backend platform, as illustrated in Figure 12. Firebase Authentication manages user accounts with email and password credentials, implementing role-based access control through custom claims that distinguish between Contributors, Validators, and Administrators. Cloud Firestore serves as the NoSQL document database, storing vocabulary entries, user profiles, geo-tag coordinates, validation records, version history, gamification progress, and quiz results. Firestore provides real-time data synchronization and offline persistence support, allowing contributors to record content and learners to complete lessons without internet connectivity — a critical feature for remote Lumad communities where internet access may be inconsistent. Firebase Storage provides scalable, CDN-backed storage for audio file management, with direct Flutter SDK integration for seamless upload and streaming playback. Firebase Cloud Functions, written in Node.js and TypeScript, handle server-side processing including pronunciation scoring calculations, validation workflow triggers, version snapshot creation, and analytics aggregation. This serverless architecture eliminates the need for a dedicated backend server, making it suitable for a capstone team without dedicated DevOps resources while operating within the Firebase Spark free tier.



Figure 12. Firebase Services



Geographic Information System and Mapping

In terms of geographic data management, the system integrates mapping and location services to support geo-tagged language documentation, as shown in Figure 13. The google_maps_flutter plugin provides native Google Maps SDK integration, displaying interactive map tiles and allowing users to explore documented language locations across Davao del Norte, Davao de Oro, and Davao Oriental. For spatial queries, the system implements GeoFlutterFire2, a geohash-based geofire library for Firestore that enables proximity queries to find vocabulary entries near a user's location. This approach replaces the previously considered PostGIS extension and is sufficient for heatmap visualization at the project's geographic scale. Custom heatmap overlays are rendered using Flutter's CustomPainter canvas engine, visualizing documentation density and identifying coverage gaps in real-time. The geolocator package provides native GPS capabilities, capturing device coordinates for each vocabulary entry with community-validated fallback input when GPS is unavailable or inaccurate. Together, these technologies create an interactive map that serves both documentation and learning purposes, allowing researchers to identify linguistic deserts and learners to explore language distribution geographically.


Figure 13. OpenStreet Map Integration

Database Management System (Cloud Firestore)

For data management, the system utilizes Cloud Firestore, Firebase's NoSQL document database, as illustrated in Figure 14. Firestore stores and organizes vocabulary entries, user profiles, geo-tags, validation records, version history, and learning progress data. Unlike traditional relational databases, Firestore's document-based model allows flexible schema design that can evolve as the platform expands to additional Lumad languages. Firestore's real-time capabilities ensure that content updates — such as new approved vocabulary entries — are immediately available to learners without requiring manual refresh. The database also supports offline persistence, allowing users in areas with limited connectivity to continue accessing previously downloaded content and queuing submissions for synchronization when connectivity is restored. Firestore security rules enforce role-based access, ensuring that only validated content is readable by learners while contributors can write to pending collections.


Figure 14. Cloud Firestore Database

Audio Processing and Pronunciation Assessment

The system implements audio recording capabilities using the flutter_sound package, as shown in Figure 15, capturing device microphone input for pronunciation assessment. Reference audio recordings from verified native speakers are stored in Firebase Storage and streamed using the just_audio package. For pronunciation scoring, the system extracts Mel-frequency cepstral coefficients (MFCCs) from both the learner's recording and the reference recording, then applies dynamic time warping to align the sequences and compute a similarity score. According to Tsai [41], explicit direction of learners' attention to computerized visualization cues leads to more significant intonational gain. Therefore, the system provides visual feedback showing the alignment of the learner's waveform against the reference waveform using Flutter's CustomPainter, enabling self-correction and iterative improvement. This lightweight approach operates entirely on the device without requiring cloud processing, making it suitable for offline use in remote areas.

Figure 15. Audio Recording and Waveform Visualization

Gamification and Spaced Repetition (Leitner System)

The gamified learning modules are built around pedagogical strategies implemented within the Flutter application, as illustrated in Figure 16. The Leitner system, a spaced repetition algorithm, schedules vocabulary reviews at increasing intervals based on learner mastery, with card deck states stored in Firestore per user profile. Words that a learner answers correctly are moved to higher-level boxes with longer review intervals, while incorrect answers return words to more frequent review. The quiz engine supports multiple-choice questions, matching tasks, and listening exercises, with scores recorded in Firestore to track progress. Points are awarded for completing modules, with bonus points for maintaining streaks and achieving perfect scores. XP points and streak mechanics are stored per user profile, with level-up animations implemented using Flutter Lottie for engaging visual feedback. The game storyline UI follows a mountain climb metaphor with character progression screens, designed to reduce the affective filter and sustain motivation among the target demographic of 15-25 year olds.



Figure 16. Leitner Spaced Repetition System

SYSTEM TESTING AND IMPLEMENTATION

The system testing and implementation phase will focus on ensuring that the Lumad Lingua mobile application operates correctly and meets all specified requirements. During this phase, comprehensive testing will be conducted to validate the integration of all system components, including vocabulary submission, audio recording upload, geo-tagging, map visualization, digital dictionary, gamified learning modules, pronunciation assessment, content validation workflows, and role-based access control. The testing process will evaluate each feature using key metrics such as submission success rate, audio playback quality, map rendering speed, quiz scoring accuracy, and pronunciation feedback reliability. Test cases will be designed to simulate both normal usage scenarios and edge cases, including offline submissions in areas with poor connectivity, poor audio quality inputs, incomplete metadata entries, and concurrent user access.

A summary of the testing results will be presented in Table 3, highlighting the performance and status of each system component. This will help in identifying any issues and confirming that all functionalities meet the expected standards before deployment.

Test Component
Test Description
Expected Result
Status
Vocabulary Entry Submission
Contributor submits new words with Filipino and English translations.
Entry saved to Firestore as "pending" with correct metadata.
Pending
Audio Recording Upload
User records and uploads audio to Firebase Storage.
File stored; metadata reference saved to Firestore.
Pending
GPS Geo-tagging
Device captures coordinates for vocabulary entry.
Latitude, longitude, and geohash saved to Geo_Tags collection.
Pending
Interactive Map
Map loads with geo-tagged markers and heatmap overlay.
Heatmap renders within 2 seconds for 200+ data points.
Pending
Digital Dictionary Search
User searches for indigenous term.
Firestore query returns matching entries within 500ms.
Pending
Gamified Quiz
Learner completes multiple-choice quiz.
Score recorded; points awarded to user profile.
Pending
Leitner Spaced Repetition
System schedules vocabulary review based on mastery.
Correct answers move cards to higher intervals.
Pending
Pronunciation Assessment
Learner speaks word; system compares with reference recording.
Similarity score generated with waveform visual feedback.
Pending
Offline Submission
Contributor submits entry without internet.
Data saved locally; syncs automatically when online.
Pending
Role-Based Access
Validator approves content; learner views only approved content.
Access control enforced by Firestore security rules.
Pending
Version History
Contributor edits existing entry.
Previous version saved to version_history subcollection.
Pending
Pre-test/Post-test
Learner completes assessments before and after modules.
Scores recorded and compared for improvement analysis.
Pending


Table 3. System Testing Summary

	To guide the validation process, a System Test Plan will be prepared, outlining the objectives, scope, test environment, test cases, and acceptance criteria as presented in Table 4. This plan will ensure that testing is systematic, organized, and aligned with the system requirements.

Aspect
Description
Objectives
Validate all functional and non-functional requirements; ensure system stability, data integrity, and usability for community users.
Scope
Full testing of Flutter mobile app, Firebase services (Firestore, Storage, Auth, Functions), OpenStreet Map integration, offline persistence, and all gamified modules.
Test Environment
Android devices (API 21+), iOS devices (13+), Firebase Emulator Suite, various network conditions (online, offline, poor connectivity).
Test Data
200+ vocabulary entries, 50+ audio recordings, geo-tagged coordinates from three communities, test accounts for all user roles.
Acceptance Criteria
All test cases pass; no critical crashes; app cold start < 3 seconds; map heatmap render < 2 seconds; Firestore queries < 500ms; user satisfaction ≥ 4.0/5.0.


Table 4. System Test Plan

Following successful testing, the implementation phase will be carried out. This will include configuring the Firebase project with proper security rules and indexes, building the Flutter application for Android (APK/AAB) and iOS (IPA), and deploying the system to target communities. After deployment, final validation will be performed to confirm that the system operates correctly in actual community settings within Davao del Norte, Davao de Oro, and Davao Oriental. Additionally, users such as community contributors, linguistic validators, and learners will be provided with proper training to ensure effective system usage. Table 5 outlines the user training plan.

User Group
Training Content
Delivery Method
Duration
Contributors
Submitting vocabulary, recording audio, adding geo-tags.
In-person workshop and  video tutorial.
2 hours.
Validators
Reviewing pending submissions, approving/rejecting content.
One-on-one session and  written guide.
1.5 hours
Learners
Using dictionary, map, quizzes, pronunciation practice.
In-app tutorial and quick start guide.
1 hour
Educators
Integrating Lumad Lingua into MTB-MLE curriculum, accessing dictionary and map for classroom use, tracking learner progress
In-person workshop + teacher's guide
2 hours
Administrators
Managing users, viewing analytics, overseeing content
Admin dashboard walkthrough and documentation.
2 hours


Table 5. User Training Plan

Finally, continuous monitoring and evaluation will be conducted to assess system performance and identify areas for improvement. This phase will ensure that the system remains reliable, functional, and adaptable, supporting its long-term use in enhancing indigenous language preservation and learning within Lumad communities.


SYSTEM MAINTENANCE

	The System Maintenance phase focuses on ensuring the continuous operation, reliability, and improvement of the Lumad Lingua platform after deployment. This phase involves monitoring system performance, identifying and resolving issues, and implementing necessary updates to enhance functionality and adaptability. Maintenance activities include regular system checks, updating Firebase security rules, optimizing Firestore queries and indexes, monitoring Firebase Storage usage, reviewing and validating new content submissions, and improving system features based on user feedback from community contributors, validators, and learners.



System Security Plan

	To ensure the protection of system data and resources, a System Security Plan will be implemented. The system will enforce user authentication through Firebase Authentication and role-based access control using custom claims to restrict unauthorized access. Data transmitted between the Flutter mobile application and Firebase services will be secured using HTTPS and Firebase's built-in security mechanisms. Stored data will be protected through Firestore security rules and Firebase Storage access rules. Regular security assessments and updates will be conducted to address potential vulnerabilities and ensure compliance with data privacy and security standards.

Table 6 presents the System Security Plan aligned with ISO/IEC 27001 standards, ensuring that the proposed system implements structured and internationally recognized security controls. These measures will help protect system data, maintain integrity, and ensure secure and reliable operation of the Lumad Lingua platform.

Security Domain (ISO 27001)
Control Area
Description / Implementation in the System
A.5 Information Security Policies
Security Policy
The system will implement formal security policies to guide data protection, access control, and system usage.
A.6 Organization of Information Security
Roles and Responsibilities
Roles (Administrator, Validator, Contributor, Learner) will be clearly defined with corresponding access privileges.
A.9 Access Control
User Access Management
Role-based access control (RBAC) using Firebase custom claims; secure login credentials will be required.
A.9 Access Control
Authentication Mechanism
Firebase Authentication with email/password and strong password policies will be implemented.
A.10 Cryptography
Data Encryption
HTTPS and Firebase built-in encryption will be used for data transmission; audio files will be encrypted at rest in Storage.
A.12 Operations Security
Data Processing Integrity
Input validation and error handling will be implemented in Flutter and Cloud Functions; Firestore security rules will enforce data structure.
A.12 Operations Security
Logging and Monitoring
Audit logs will be maintained through Firebase Console and version_history subcollection to track user activities and content changes.
A.13 Communications Security
Network Security
Secure communication protocols (HTTPS, Firebase SDKs) will be used; Firestore security rules will restrict unauthorized access.
A.11 Physical and Environmental Security
Device Protection
No sensitive data will be permanently stored locally beyond Firestore offline cache (encrypted by device).
A.17 Information Security Aspects of Business Continuity
Data Backup and Recovery
Firebase automatic backups will be enabled; regular exports of critical Firestore collections will be performed.
A.16 Information Security Incident Management
Incident Response
Procedures will be established to detect, report, and respond to security incidents.
A.14 System Acquisition, Development, and Maintenance
Secure Development
Input validation, secure coding practices, and Firebase security rule testing using Emulator Suite will be applied.
A.18 Compliance
Legal and Regulatory Compliance
The system will comply with Data Privacy Act (RA 10173), indigenous intellectual property rights, and DNSC policies.


Table 6. System Security Plan


System Maintenance Plan

	In addition, a System Maintenance Plan will be established to guide ongoing support and system improvements. This plan will include scheduled maintenance activities such as system updates, database optimization, and performance monitoring. It will also define procedures for troubleshooting, bug fixing, and handling system errors. Furthermore, documentation will be maintained to record system changes, updates, and maintenance activities, ensuring continuity and ease of future enhancements.

The System Maintenance Plan as shown in table 5, ensures the continuous operation, improvement, and sustainability of the AI-Assisted Smart Campus Fire Detection and Monitoring System by aligning maintenance activities with ISO/IEC 25010 quality attributes. This approach guarantees that the system remains reliable, efficient, secure, and adaptable over time.


ISO 25010 Attribute
Maintenance Activity
Description
Frequency
Reliability
System Monitoring
Monitoring Firebase Crashlytics for crash-free session rates, Firestore query performance, Cloud Functions logs.
Daily
Performance Efficiency
Performance Optimization
Improving Firestore query response times, optimizing audio compression, reducing map heatmap latency.
As needed
Usability
Interface Improvement
Updating Flutter UI based on user feedback; improving gamification animations and pronunciation visualization.
Periodically
Security
Security Updates
Applying Firebase security rule updates, Flutter dependency updates, Firebase SDK version upgrades.
Regularly (Monthly)
Maintainability
Code Refactoring & Debugging
Fixing bugs from Crashlytics and user feedback; improving Flutter code structure.
As needed
Compatibility
System Updates
Ensuring compatibility with new Android/iOS versions, Firebase SDK updates, OpenStreet Map SDK updates.
Periodically (Quarterly)
Reliability
Content Validation
Periodic review of vocabulary entries and audio recordings for continued linguistic accuracy.
Monthly
Performance Efficiency
Database Optimization
Firestore composite index review, data cleanup of rejected/pending entries older than 6 months.
Weekly
Reliability
Storage Clean-up
Removal of orphaned audio files not referenced by approved vocabulary entries.
Monthly
Security
Security Rule Testing
Testing Firestore security rules using Firebase Emulator Suite.
After each rule change


Table 7. System Maintenance Plan







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

[13] 	M. Turin, "New media, old messages," Oral Tradition, 2018.

[14] 	P. K. Austin, "Current issues in language documentation," Language
Documentation and Description, 2017.

[15] 	A. Kornai, "Digital language death," PLOS ONE, 2016.

[16] 	G. L. Simons, "The Open Language Archives Community," Literary and Linguistic
Computing, 2018.

[17] 	S. Bird, "Aikuma: A mobile app for collaborative language documentation,"
LREC, 2017.

[18] 	J. S. Lamidi, "The role of GIS in the preservation of indigenous languages," J.
Multilingual Dev., 2021.

[19] 	A. Falsaperla, "Open source software in cultural heritage," CIT Journal, 2016.

[20] 	N. Ostler, The last lingua franca: English until the return of Babel, Penguin, 2018.

[21] 	D. J. Bodenhamer, "The potential of spatial humanities," IJHAC, 2018.

[22] 	T. N. Headland, "Thirty endangered languages in the Philippines," SIL, 2017.

[23] 	L. A. Reid, "The Philippine national language map project," Univ. Hawaii, 2018.

[24] 	B. Dumigsi and G. Diez, "The implementation of mother tongue-based
multilingual education in the Philippines," Philippine Journal of Science, 2021.

[25] 	J. M. Sancada, "Phonetic variations in Southern Mindanao languages," Journal
of South Asian Studies, 2022.

[26] 	R. P. Magno, "Heritage and high-tech: The digitalization of Lumad oral traditions,"
Davao Cultural Studies Journal, 2020.

[27] 	P. Rogerson-Revell, "Computer-based pronunciation tools," IJCALLT, 2018.

[28] 	Local Government Davao, "Indigenous knowledge systems and practices (IKSP)
report," 2019.

[29] 	J. Hamari et al., "Does gamification work? A literature review," HICSS, 2017.

[30] 	K. Richards, "Visual acoustics in language learning," Journal of MALL, 2019.

[31] 	M. T. Garcia, "Phonetic accuracy in mobile environments," Phil. IT Journal, 2022.

[32] 	R. Cruz, "Spaced repetition and minority languages," MIND Journal, 2020.

[33] 	D. Lopez, "Gamified revitalisation strategies for youth," Cultures of Mindanao,
2021.

[34] 	G. Santos, "Digital gaps in the MTB-MLE policy," DepEd Research Journal, 2022.

[35] 	H. Ramos, "Relational databases for cultural archives," IT Heritage, 2019.

[36] 	M. B. Macapagal et al., "Psychosocial impacts of cultural preservation on Lumad
youth," Mindanao Ethnology, 2023.

[37] 	V. C. Cajetas, "Digitizing the Higaonon Language: A Mobile Application for
Indigenous Preservation in the Philippines," ResearchGate, 2025.

[38] 	R. P. Magno, "Digital revitalization of indigenous languages in the Philippines,"
Journal of Language Preservation, 2024.

[39] 	B. Reyes, "Static vs Interactive Archives in Mindanao," Mindanao Tech, 2024.

[40] 	S. Almeda, "Offline-first design for remote regions," Global Dev Tech, 2025.

[41] 	P. H. Tsai, "Optimal implementation setting for computerized visualization cues in
assisting L2 intonation production," System, vol. 87, 102145, Dec. 2019. doi: 10.1016/j.system.2019.102145

[42] 	V. Khaustova, E. Pyshkin, V. Khaustov, J. Blake, and N. Bogach, "CAPTuring
accents: An approach to personalize pronunciation training for learners with different L1 backgrounds," in Speech and Computer, Lecture Notes in Computer Science, Springer, 2023, vol. 14338, pp. 58-72. doi: 10.1007/978-3-031-48312-7_5
