"""LUMAD LINGUA pronunciation research pipeline: deterministic preprocessing (PP) and MFCC features (FE).

Single implementation reused by the dataset scripts, the automated tests and the future Colab experiment notebook.
Import as `from pipeline import audio_io, preprocess, features`. Never modifies raw audio.
"""
PIPELINE_VERSION = "0.1.0"
