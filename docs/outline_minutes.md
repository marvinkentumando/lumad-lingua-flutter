
OUTLINE DEFENSE MINUTES
Title: “LUMAD LINGUA: A DOCUMENTATION AND GAMIFIED LEARNING PLATFORM FOR THE MANSAKA LANGUAGE”
Program: BSIT  				Date of Defense:JUNE 1, 2026
Members: AIRES JHOY J. GIVEROLA, KATHY CLAIRE S. LAURETO, MARVIN KEN P. TUMANDO

Panelists
Page No.
Comments/Suggestions/
Recommendations
Action/s Taken
HAZEL GAMENG, DIT
Panel Chairman

Signature:
Date Signed:
1
The title must be revised since the GIS component has been removed, as the current title no longer accurately represents the scope and direction of the system.
The project title has been updated from "Lumad Lingua: A Geo-Tagged Documentation Platform with Gamified Learning Modules on Selected Indigenous Languages" to "Lumad Lingua: A Documentation and Gamified Learning Platform for the Mansaka Language." All references to the old title throughout the paper have been updated accordingly.
3
Replace the GIS component with Sentiment Analysis as a more relevant analytical feature for the system.
The GIS component has been replaced with Sentiment Analysis throughout the study. The Background of the Study, Objectives, Significance, Scope and Limitations, System Architecture, Context Flow Diagram, Data Flow Diagram, and Entity Relationship Diagram now reflect a Facebook-based Mansaka sentiment analysis pipeline (Facebook Graph API retrieval, translation, and sentiment classification) in place of geo-tagged mapping, including a new interactive sentiment dashboard and the corresponding Facebook_Posts and Sentiment_Results data structures.


7



Focus on the Mansaka language for a non-limited vocabulary. Vocabulary entries should not be limited to only 200.
The scope of the study has been updated to focus solely on the Mansaka language, with Mandaya removed as a secondary language. The limitation of 200 vocabulary entries has been removed from the scope section, and the system now targets an unlimited and expandable vocabulary archive for the Mansaka language, constrained only by the availability of validated community contributions and linguistic expert review. All references to the 200-entry limit and dual-language scope throughout the paper have been updated accordingly.


61
For sentiment analysis, there should also be three algorithms.
Three candidate sentiment analysis algorithms — Naïve Bayes, Support Vector Machine (SVM), and Bidirectional LSTM (BiLSTM) — are now evaluated in Chapter 2 under "Classification – Sentiment Analysis Algorithms," each demonstrated with a worked example on sample Mansaka phrases and supported by literature evidence (Table 4) and a decision matrix (Table 5). SVM was selected for the system based on its demonstrated competitiveness on small and code-mixed datasets, lower data requirements relative to BiLSTM, and manageable implementation complexity.
HANNAH MAE LOLONG
Panel Member

Signature:
Date Signed:
23
Remove the GIS component from the capstone project. There is no more Contributor role in the system.
The GIS component has been removed from the system architecture, methodology, scope, and all relevant sections of the paper. The Contributor role has been eliminated from all diagrams, descriptions, and user role discussions throughout Chapter 1 and Chapter 2. Responsibilities previously assigned to Contributors have been redistributed to the Validator role.
29
For the Use Case Diagram, remove the Contributor and add the tasks to the Validator instead.
The Use Case Diagram has been revised to remove the Contributor actor. All tasks previously assigned to Contributors, including submitting vocabulary entries, uploading audio recordings, and editing submissions, have been reassigned to the Validator role. The Use Case Diagram description in the paper has been updated to reflect this change, and the Validator role now encompasses both content submission and content validation responsibilities.
61-66
For the audio comparison table, include literature or testing methods that are mathematical for better understanding, not just words.
The pronunciation/audio comparison section now includes worked mathematical demonstrations for each candidate algorithm — a Dynamic Time Warping (DTW) cumulative-distance calculation, a Hidden Markov Model (HMM) forward-algorithm probability computation, and a cosine similarity computation — using illustrative reference and learner value sequences, in addition to literature-based accuracy and error-rate figures (Table 7: DTW 94.0% vs. HMM 91.3%; DTW average error rate 0.287 vs. HMM 0.473).


66-71
There should be three algorithms for the audio comparison.
Three candidate pronunciation assessment algorithms — Dynamic Time Warping (DTW) with MFCC, Hidden Markov Models (HMM) with MFCC, and Cosine Similarity with MFCC — are now compared side by side with a decision matrix (Table 8) based on ISO/IEC 25010 criteria (reliability, performance efficiency, and compatibility). MFCC + DTW was retained as the selected algorithm, supported by head-to-head accuracy figures (94.0% vs. 91.3%) and error-rate data (0.287 vs. 0.473) drawn from a matched comparative testing design (Table 7).
ANALYN CASIPE, MIT
Panel Member

Signature:
Date Signed:
11
Follow the format provided, especially in labeling the tables and figures.
All tables and figures throughout the paper have been reviewed and relabeled following the prescribed formatting guidelines. Table labels, figure captions, numbering sequences, and placement have been standardized and verified for consistency across all sections of Chapter 1 and Chapter 2.



ARIEL O. GAMAO, DIT
Adviser
Date Signed: 


