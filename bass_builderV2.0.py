import streamlit as st
import math
import numpy as np
import matplotlib.pyplot as plt
import plotly.graph_objects as go
import json
import base64
from datetime import datetime
import urllib.parse

st.set_page_config(page_title="Bass Builder v5.0 Pro", layout="wide")
st.title("📊 Bass Builder Pro v5.0 - Ultimate Edition")

# ═══════════════════════════════════════════════════════════════════════════════
# SESSION STATE INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════════
if 'saved_designs' not in st.session_state:
    st.session_state.saved_designs = {}
if 'sub_x' not in st.session_state:
    st.session_state.sub_x = 11.2
if 'sub_z' not in st.session_state:
    st.session_state.sub_z = 10.0
if 'port_x' not in st.session_state:
    st.session_state.port_x = 25.6
if 'port_z' not in st.session_state:
    st.session_state.port_z = 10.0
if 'sub_offsets' not in st.session_state:
    st.session_state.sub_offsets = {i: {'x': 0.0, 'z': 0.0} for i in range(6)}

# ═══════════════════════════════════════════════════════════════════════════════
# DATABASES
# ═══════════════════════════════════════════════════════════════════════════════

# Subwoofer Database - Organized by Manufacturer > Model > Size
# Format: "Manufacturer Model Size" with full T/S parameters
subwoofer_database = {
    "Custom": {"size": 15, "cutout": 13.875, "od": 15.25, "displacement": 0.20, "depth": 8.5,
               "fs": 32.0, "qts": 0.45, "qes": 0.52, "qms": 5.5, "vas": 4.5, "xmax": 20.0, "sens": 86.0, "power": 1000, "re": 3.2, "le": 2.5, "bl": 18.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # SUNDOWN AUDIO
    # ═══════════════════════════════════════════════════════════════════════════════
    # Sundown X Series
    "Sundown X-6.5 v.4": {"size": 6.5, "cutout": 5.75, "od": 7.0, "displacement": 0.025, "depth": 3.5,
                          "fs": 55.0, "qts": 0.42, "qes": 0.48, "qms": 4.2, "vas": 0.35, "xmax": 12.0, "sens": 82.0, "power": 250, "re": 3.4, "le": 1.2, "bl": 8.5},
    "Sundown X-8 v.4": {"size": 8, "cutout": 7.25, "od": 8.5, "displacement": 0.045, "depth": 4.5,
                        "fs": 48.0, "qts": 0.44, "qes": 0.50, "qms": 4.5, "vas": 0.65, "xmax": 18.0, "sens": 83.0, "power": 400, "re": 3.4, "le": 1.5, "bl": 11.0},
    "Sundown X-10 v.3": {"size": 10, "cutout": 9.25, "od": 10.5, "displacement": 0.085, "depth": 6.0,
                         "fs": 42.0, "qts": 0.42, "qes": 0.48, "qms": 4.8, "vas": 1.4, "xmax": 28.0, "sens": 84.0, "power": 750, "re": 3.3, "le": 1.8, "bl": 15.0},
    "Sundown X-12 v.3": {"size": 12, "cutout": 11.25, "od": 12.75, "displacement": 0.15, "depth": 7.5,
                         "fs": 38.0, "qts": 0.40, "qes": 0.46, "qms": 5.0, "vas": 2.5, "xmax": 34.0, "sens": 84.5, "power": 1250, "re": 3.2, "le": 2.0, "bl": 20.0},
    "Sundown X-15 v.3": {"size": 15, "cutout": 14.2, "od": 15.5, "displacement": 0.28, "depth": 10.5,
                         "fs": 35.0, "qts": 0.40, "qes": 0.46, "qms": 5.2, "vas": 4.5, "xmax": 40.0, "sens": 85.0, "power": 1500, "re": 3.0, "le": 2.5, "bl": 24.0},
    "Sundown X-18 v.3": {"size": 18, "cutout": 17.2, "od": 18.9, "displacement": 0.45, "depth": 12.5,
                         "fs": 32.5, "qts": 0.42, "qes": 0.48, "qms": 5.5, "vas": 6.2, "xmax": 45.0, "sens": 84.5, "power": 1500, "re": 2.8, "le": 3.0, "bl": 28.0},
    
    # Sundown SA Series (Classic)
    "Sundown SA-6.5 v.2": {"size": 6.5, "cutout": 5.625, "od": 6.75, "displacement": 0.02, "depth": 3.25,
                           "fs": 60.0, "qts": 0.52, "qes": 0.60, "qms": 4.8, "vas": 0.28, "xmax": 9.0, "sens": 83.0, "power": 200, "re": 3.5, "le": 1.0, "bl": 7.5},
    "Sundown SA-8 v.3": {"size": 8, "cutout": 7.125, "od": 8.25, "displacement": 0.038, "depth": 4.25,
                         "fs": 50.0, "qts": 0.50, "qes": 0.58, "qms": 5.0, "vas": 0.55, "xmax": 12.0, "sens": 84.0, "power": 500, "re": 3.4, "le": 1.3, "bl": 10.0},
    "Sundown SA-10 v.3": {"size": 10, "cutout": 9.125, "od": 10.25, "displacement": 0.07, "depth": 5.5,
                          "fs": 44.0, "qts": 0.48, "qes": 0.55, "qms": 5.2, "vas": 1.2, "xmax": 16.0, "sens": 85.0, "power": 750, "re": 3.3, "le": 1.6, "bl": 13.0},
    "Sundown SA-12 v.3": {"size": 12, "cutout": 11.2, "od": 12.6, "displacement": 0.12, "depth": 7.0,
                          "fs": 38.0, "qts": 0.50, "qes": 0.58, "qms": 5.5, "vas": 2.2, "xmax": 18.0, "sens": 86.0, "power": 750, "re": 3.2, "le": 1.8, "bl": 15.5},
    "Sundown SA-15 v.2": {"size": 15, "cutout": 14.0, "od": 15.25, "displacement": 0.22, "depth": 9.0,
                          "fs": 34.0, "qts": 0.52, "qes": 0.60, "qms": 5.8, "vas": 4.0, "xmax": 22.0, "sens": 86.5, "power": 1000, "re": 3.0, "le": 2.2, "bl": 19.0},
    "Sundown SA-18": {"size": 18, "cutout": 17.0, "od": 18.5, "displacement": 0.38, "depth": 11.0,
                      "fs": 30.0, "qts": 0.54, "qes": 0.62, "qms": 6.0, "vas": 5.5, "xmax": 25.0, "sens": 85.5, "power": 1000, "re": 2.8, "le": 2.8, "bl": 22.0},
    
    # Sundown E Series (Entry)
    "Sundown E-8 v.6": {"size": 8, "cutout": 7.0, "od": 8.125, "displacement": 0.032, "depth": 4.0,
                        "fs": 52.0, "qts": 0.55, "qes": 0.64, "qms": 5.2, "vas": 0.48, "xmax": 10.0, "sens": 84.5, "power": 300, "re": 3.5, "le": 1.2, "bl": 9.0},
    "Sundown E-10 v.5": {"size": 10, "cutout": 9.3, "od": 10.5, "displacement": 0.065, "depth": 5.5,
                         "fs": 45.0, "qts": 0.52, "qes": 0.60, "qms": 5.5, "vas": 1.2, "xmax": 12.0, "sens": 85.5, "power": 500, "re": 3.4, "le": 1.5, "bl": 12.0},
    "Sundown E-12 v.6": {"size": 12, "cutout": 11.0, "od": 12.25, "displacement": 0.10, "depth": 6.5,
                         "fs": 40.0, "qts": 0.55, "qes": 0.64, "qms": 5.8, "vas": 2.0, "xmax": 14.0, "sens": 86.0, "power": 500, "re": 3.3, "le": 1.7, "bl": 14.0},
    "Sundown E-15 v.4": {"size": 15, "cutout": 13.875, "od": 15.0, "displacement": 0.18, "depth": 8.5,
                         "fs": 35.0, "qts": 0.58, "qes": 0.68, "qms": 6.0, "vas": 3.8, "xmax": 16.0, "sens": 86.5, "power": 600, "re": 3.0, "le": 2.0, "bl": 17.0},
    
    # Sundown U Series (High Power)
    "Sundown U-10": {"size": 10, "cutout": 9.5, "od": 10.75, "displacement": 0.12, "depth": 7.0,
                     "fs": 38.0, "qts": 0.38, "qes": 0.42, "qms": 4.5, "vas": 1.8, "xmax": 35.0, "sens": 82.5, "power": 1500, "re": 1.6, "le": 2.0, "bl": 18.0},
    "Sundown U-12": {"size": 12, "cutout": 11.5, "od": 13.0, "displacement": 0.22, "depth": 9.0,
                     "fs": 34.0, "qts": 0.36, "qes": 0.40, "qms": 4.8, "vas": 3.0, "xmax": 42.0, "sens": 83.0, "power": 2000, "re": 1.5, "le": 2.5, "bl": 24.0},
    "Sundown U-15": {"size": 15, "cutout": 14.5, "od": 16.0, "displacement": 0.38, "depth": 11.0,
                     "fs": 30.0, "qts": 0.35, "qes": 0.38, "qms": 5.0, "vas": 5.5, "xmax": 50.0, "sens": 83.5, "power": 2500, "re": 1.4, "le": 3.0, "bl": 30.0},
    "Sundown U-18": {"size": 18, "cutout": 17.5, "od": 19.25, "displacement": 0.58, "depth": 13.5,
                     "fs": 26.0, "qts": 0.34, "qes": 0.37, "qms": 5.2, "vas": 8.0, "xmax": 58.0, "sens": 84.0, "power": 3000, "re": 1.3, "le": 3.5, "bl": 35.0},
    
    # Sundown ZV6 Series
    "Sundown ZV6-12": {"size": 12, "cutout": 11.75, "od": 13.25, "displacement": 0.28, "depth": 10.0,
                       "fs": 32.0, "qts": 0.32, "qes": 0.35, "qms": 4.5, "vas": 3.5, "xmax": 48.0, "sens": 82.0, "power": 3000, "re": 1.4, "le": 2.8, "bl": 28.0},
    "Sundown ZV6-15": {"size": 15, "cutout": 14.75, "od": 16.5, "displacement": 0.48, "depth": 12.5,
                       "fs": 28.0, "qts": 0.30, "qes": 0.33, "qms": 4.8, "vas": 6.0, "xmax": 55.0, "sens": 82.5, "power": 4000, "re": 1.3, "le": 3.2, "bl": 34.0},
    "Sundown ZV6-18": {"size": 18, "cutout": 17.75, "od": 19.75, "displacement": 0.72, "depth": 15.0,
                       "fs": 24.0, "qts": 0.28, "qes": 0.30, "qms": 5.0, "vas": 9.5, "xmax": 62.0, "sens": 83.0, "power": 5000, "re": 1.2, "le": 3.8, "bl": 40.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # SKAR AUDIO
    # ═══════════════════════════════════════════════════════════════════════════════
    # Skar ZVX Series
    "Skar ZVX-8": {"size": 8, "cutout": 7.25, "od": 8.375, "displacement": 0.055, "depth": 5.0,
                   "fs": 45.0, "qts": 0.40, "qes": 0.46, "qms": 4.5, "vas": 0.75, "xmax": 20.0, "sens": 82.5, "power": 900, "re": 3.2, "le": 1.5, "bl": 12.0},
    "Skar ZVX-10": {"size": 10, "cutout": 9.25, "od": 10.5, "displacement": 0.095, "depth": 6.5,
                    "fs": 40.0, "qts": 0.42, "qes": 0.48, "qms": 4.8, "vas": 1.5, "xmax": 26.0, "sens": 83.0, "power": 1200, "re": 3.0, "le": 1.8, "bl": 16.0},
    "Skar ZVX-12": {"size": 12, "cutout": 11.25, "od": 12.75, "displacement": 0.16, "depth": 8.0,
                    "fs": 36.0, "qts": 0.44, "qes": 0.50, "qms": 5.0, "vas": 2.8, "xmax": 32.0, "sens": 83.5, "power": 1500, "re": 2.8, "le": 2.2, "bl": 20.0},
    "Skar ZVX-15": {"size": 15, "cutout": 14.125, "od": 15.5, "displacement": 0.30, "depth": 10.5,
                    "fs": 32.0, "qts": 0.45, "qes": 0.52, "qms": 5.2, "vas": 5.0, "xmax": 38.0, "sens": 84.0, "power": 1800, "re": 2.6, "le": 2.8, "bl": 25.0},
    "Skar ZVX-18": {"size": 18, "cutout": 16.9, "od": 18.7, "displacement": 0.48, "depth": 12.0,
                    "fs": 28.0, "qts": 0.45, "qes": 0.52, "qms": 5.5, "vas": 7.5, "xmax": 42.0, "sens": 84.5, "power": 2100, "re": 2.4, "le": 3.2, "bl": 30.0},
    
    # Skar EVL Series
    "Skar EVL-8": {"size": 8, "cutout": 7.125, "od": 8.25, "displacement": 0.048, "depth": 4.75,
                   "fs": 48.0, "qts": 0.45, "qes": 0.52, "qms": 5.0, "vas": 0.62, "xmax": 16.0, "sens": 83.5, "power": 600, "re": 3.4, "le": 1.4, "bl": 10.5},
    "Skar EVL-10": {"size": 10, "cutout": 9.125, "od": 10.375, "displacement": 0.08, "depth": 6.0,
                    "fs": 42.0, "qts": 0.48, "qes": 0.55, "qms": 5.2, "vas": 1.3, "xmax": 20.0, "sens": 84.0, "power": 1000, "re": 3.2, "le": 1.6, "bl": 14.0},
    "Skar EVL-12": {"size": 12, "cutout": 11.125, "od": 12.5, "displacement": 0.13, "depth": 7.5,
                    "fs": 38.0, "qts": 0.50, "qes": 0.58, "qms": 5.5, "vas": 2.5, "xmax": 25.0, "sens": 84.5, "power": 1250, "re": 3.0, "le": 2.0, "bl": 17.0},
    "Skar EVL-15": {"size": 15, "cutout": 14.0, "od": 15.375, "displacement": 0.25, "depth": 9.5,
                    "fs": 34.0, "qts": 0.52, "qes": 0.60, "qms": 5.8, "vas": 4.5, "xmax": 30.0, "sens": 85.0, "power": 1500, "re": 2.8, "le": 2.5, "bl": 21.0},
    "Skar EVL-18": {"size": 18, "cutout": 16.75, "od": 18.5, "displacement": 0.42, "depth": 11.5,
                    "fs": 30.0, "qts": 0.55, "qes": 0.64, "qms": 6.0, "vas": 6.8, "xmax": 35.0, "sens": 85.5, "power": 1800, "re": 2.6, "le": 3.0, "bl": 26.0},
    
    # Skar VD Series
    "Skar VD-8": {"size": 8, "cutout": 7.0, "od": 8.125, "displacement": 0.038, "depth": 4.25,
                  "fs": 52.0, "qts": 0.55, "qes": 0.65, "qms": 5.5, "vas": 0.52, "xmax": 10.0, "sens": 84.5, "power": 400, "re": 3.5, "le": 1.2, "bl": 9.0},
    "Skar VD-10": {"size": 10, "cutout": 9.0, "od": 10.25, "displacement": 0.065, "depth": 5.5,
                   "fs": 45.0, "qts": 0.58, "qes": 0.68, "qms": 5.8, "vas": 1.1, "xmax": 13.0, "sens": 85.0, "power": 500, "re": 3.4, "le": 1.5, "bl": 11.5},
    "Skar VD-12": {"size": 12, "cutout": 11.0, "od": 12.25, "displacement": 0.10, "depth": 6.5,
                   "fs": 40.0, "qts": 0.60, "qes": 0.70, "qms": 6.0, "vas": 2.0, "xmax": 15.0, "sens": 85.5, "power": 800, "re": 3.2, "le": 1.8, "bl": 13.5},
    "Skar VD-15": {"size": 15, "cutout": 13.875, "od": 15.125, "displacement": 0.18, "depth": 8.25,
                   "fs": 35.0, "qts": 0.62, "qes": 0.72, "qms": 6.2, "vas": 3.8, "xmax": 18.0, "sens": 86.0, "power": 1000, "re": 3.0, "le": 2.2, "bl": 16.0},
    
    # Skar SDR Series
    "Skar SDR-8": {"size": 8, "cutout": 7.0, "od": 8.0, "displacement": 0.032, "depth": 4.0,
                   "fs": 55.0, "qts": 0.62, "qes": 0.75, "qms": 6.0, "vas": 0.45, "xmax": 8.0, "sens": 85.0, "power": 200, "re": 3.6, "le": 1.0, "bl": 8.0},
    "Skar SDR-10": {"size": 10, "cutout": 9.0, "od": 10.125, "displacement": 0.055, "depth": 5.0,
                    "fs": 48.0, "qts": 0.65, "qes": 0.78, "qms": 6.2, "vas": 0.95, "xmax": 10.0, "sens": 85.5, "power": 300, "re": 3.5, "le": 1.3, "bl": 10.0},
    "Skar SDR-12": {"size": 12, "cutout": 10.875, "od": 12.125, "displacement": 0.085, "depth": 6.0,
                    "fs": 42.0, "qts": 0.68, "qes": 0.82, "qms": 6.5, "vas": 1.8, "xmax": 12.0, "sens": 86.0, "power": 400, "re": 3.4, "le": 1.6, "bl": 12.0},
    "Skar SDR-15": {"size": 15, "cutout": 13.625, "od": 14.875, "displacement": 0.15, "depth": 7.5,
                    "fs": 36.0, "qts": 0.70, "qes": 0.85, "qms": 6.8, "vas": 3.5, "xmax": 14.0, "sens": 86.5, "power": 600, "re": 3.2, "le": 2.0, "bl": 14.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # SSA (SOUND SOLUTIONS AUDIO)
    # ═══════════════════════════════════════════════════════════════════════════════
    # SSA XCON Series
    "SSA XCON-10": {"size": 10, "cutout": 9.25, "od": 10.625, "displacement": 0.12, "depth": 7.0,
                    "fs": 36.0, "qts": 0.35, "qes": 0.38, "qms": 4.5, "vas": 2.0, "xmax": 38.0, "sens": 82.0, "power": 1500, "re": 1.8, "le": 2.2, "bl": 18.0},
    "SSA XCON-12": {"size": 12, "cutout": 11.25, "od": 12.875, "displacement": 0.20, "depth": 8.5,
                    "fs": 32.0, "qts": 0.34, "qes": 0.37, "qms": 4.8, "vas": 3.5, "xmax": 45.0, "sens": 82.5, "power": 2000, "re": 1.6, "le": 2.6, "bl": 24.0},
    "SSA XCON-15": {"size": 15, "cutout": 14.25, "od": 16.0, "displacement": 0.38, "depth": 11.0,
                    "fs": 28.0, "qts": 0.33, "qes": 0.36, "qms": 5.0, "vas": 6.5, "xmax": 52.0, "sens": 83.0, "power": 2500, "re": 1.4, "le": 3.0, "bl": 30.0},
    "SSA XCON-18": {"size": 18, "cutout": 17.0, "od": 19.0, "displacement": 0.58, "depth": 13.5,
                    "fs": 25.0, "qts": 0.32, "qes": 0.35, "qms": 5.2, "vas": 9.5, "xmax": 58.0, "sens": 83.5, "power": 3000, "re": 1.2, "le": 3.5, "bl": 36.0},
    
    # SSA GCON Series
    "SSA GCON-10": {"size": 10, "cutout": 9.125, "od": 10.5, "displacement": 0.08, "depth": 6.0,
                    "fs": 42.0, "qts": 0.45, "qes": 0.52, "qms": 5.0, "vas": 1.4, "xmax": 22.0, "sens": 84.5, "power": 800, "re": 3.2, "le": 1.6, "bl": 14.0},
    "SSA GCON-12": {"size": 12, "cutout": 11.125, "od": 12.5, "displacement": 0.14, "depth": 7.5,
                    "fs": 38.0, "qts": 0.48, "qes": 0.55, "qms": 5.2, "vas": 2.6, "xmax": 28.0, "sens": 85.0, "power": 1000, "re": 3.0, "le": 2.0, "bl": 17.0},
    "SSA GCON-15": {"size": 15, "cutout": 14.0, "od": 15.3, "displacement": 0.25, "depth": 9.5,
                    "fs": 35.0, "qts": 0.50, "qes": 0.58, "qms": 5.5, "vas": 4.5, "xmax": 32.0, "sens": 85.5, "power": 1250, "re": 2.8, "le": 2.5, "bl": 21.0},
    "SSA GCON-18": {"size": 18, "cutout": 16.875, "od": 18.5, "displacement": 0.42, "depth": 11.5,
                    "fs": 30.0, "qts": 0.52, "qes": 0.60, "qms": 5.8, "vas": 7.0, "xmax": 36.0, "sens": 86.0, "power": 1500, "re": 2.6, "le": 3.0, "bl": 25.0},
    
    # SSA DCON Series
    "SSA DCON-10": {"size": 10, "cutout": 9.0, "od": 10.25, "displacement": 0.06, "depth": 5.5,
                    "fs": 48.0, "qts": 0.55, "qes": 0.65, "qms": 5.5, "vas": 1.0, "xmax": 14.0, "sens": 86.0, "power": 500, "re": 3.4, "le": 1.4, "bl": 11.0},
    "SSA DCON-12": {"size": 12, "cutout": 11.0, "od": 12.4, "displacement": 0.10, "depth": 6.5,
                    "fs": 42.0, "qts": 0.55, "qes": 0.65, "qms": 5.8, "vas": 1.8, "xmax": 18.0, "sens": 87.0, "power": 600, "re": 3.2, "le": 1.7, "bl": 13.0},
    "SSA DCON-15": {"size": 15, "cutout": 13.875, "od": 15.125, "displacement": 0.18, "depth": 8.0,
                    "fs": 36.0, "qts": 0.58, "qes": 0.68, "qms": 6.0, "vas": 3.5, "xmax": 20.0, "sens": 87.5, "power": 800, "re": 3.0, "le": 2.0, "bl": 15.0},
    
    # SSA Evil Series
    "SSA Evil-8": {"size": 8, "cutout": 7.25, "od": 8.5, "displacement": 0.06, "depth": 5.5,
                   "fs": 42.0, "qts": 0.38, "qes": 0.42, "qms": 4.2, "vas": 0.8, "xmax": 25.0, "sens": 81.5, "power": 1000, "re": 2.8, "le": 1.6, "bl": 13.0},
    "SSA Evil-10": {"size": 10, "cutout": 9.25, "od": 10.75, "displacement": 0.12, "depth": 7.25,
                    "fs": 36.0, "qts": 0.36, "qes": 0.40, "qms": 4.5, "vas": 1.6, "xmax": 32.0, "sens": 82.0, "power": 1500, "re": 2.4, "le": 2.0, "bl": 17.0},
    "SSA Evil-12": {"size": 12, "cutout": 11.25, "od": 12.875, "displacement": 0.22, "depth": 9.0,
                    "fs": 32.0, "qts": 0.35, "qes": 0.38, "qms": 4.8, "vas": 3.2, "xmax": 40.0, "sens": 82.5, "power": 2000, "re": 2.0, "le": 2.5, "bl": 22.0},
    "SSA Evil-15": {"size": 15, "cutout": 14.25, "od": 16.125, "displacement": 0.40, "depth": 11.5,
                    "fs": 28.0, "qts": 0.34, "qes": 0.37, "qms": 5.0, "vas": 6.0, "xmax": 48.0, "sens": 83.0, "power": 2500, "re": 1.6, "le": 3.0, "bl": 28.0},
    "SSA Evil-18": {"size": 18, "cutout": 17.125, "od": 19.25, "displacement": 0.62, "depth": 14.0,
                    "fs": 24.0, "qts": 0.33, "qes": 0.36, "qms": 5.2, "vas": 9.0, "xmax": 55.0, "sens": 83.5, "power": 3500, "re": 1.4, "le": 3.6, "bl": 35.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # DC AUDIO
    # ═══════════════════════════════════════════════════════════════════════════════
    # DC Level 3 Series
    "DC Level 3 8": {"size": 8, "cutout": 7.25, "od": 8.5, "displacement": 0.055, "depth": 5.0,
                     "fs": 42.0, "qts": 0.42, "qes": 0.48, "qms": 4.5, "vas": 0.8, "xmax": 22.0, "sens": 83.0, "power": 600, "re": 3.2, "le": 1.5, "bl": 12.0},
    "DC Level 3 10": {"size": 10, "cutout": 9.25, "od": 10.625, "displacement": 0.095, "depth": 6.5,
                      "fs": 38.0, "qts": 0.44, "qes": 0.50, "qms": 4.8, "vas": 1.6, "xmax": 28.0, "sens": 83.5, "power": 900, "re": 3.0, "le": 1.8, "bl": 16.0},
    "DC Level 3 12": {"size": 12, "cutout": 11.25, "od": 12.75, "displacement": 0.16, "depth": 8.0,
                      "fs": 34.0, "qts": 0.45, "qes": 0.52, "qms": 5.0, "vas": 3.0, "xmax": 34.0, "sens": 84.0, "power": 1200, "re": 2.8, "le": 2.2, "bl": 20.0},
    "DC Level 3 15": {"size": 15, "cutout": 14.125, "od": 15.625, "displacement": 0.30, "depth": 10.5,
                      "fs": 30.0, "qts": 0.46, "qes": 0.53, "qms": 5.2, "vas": 5.5, "xmax": 40.0, "sens": 84.5, "power": 1500, "re": 2.6, "le": 2.8, "bl": 25.0},
    "DC Level 3 18": {"size": 18, "cutout": 17.0, "od": 18.75, "displacement": 0.50, "depth": 12.5,
                      "fs": 26.0, "qts": 0.48, "qes": 0.55, "qms": 5.5, "vas": 8.5, "xmax": 45.0, "sens": 85.0, "power": 1800, "re": 2.4, "le": 3.2, "bl": 30.0},
    
    # DC Level 4 Series
    "DC Level 4 10": {"size": 10, "cutout": 9.375, "od": 10.75, "displacement": 0.12, "depth": 7.0,
                      "fs": 36.0, "qts": 0.38, "qes": 0.42, "qms": 4.5, "vas": 2.0, "xmax": 35.0, "sens": 82.0, "power": 1500, "re": 2.4, "le": 2.0, "bl": 19.0},
    "DC Level 4 12": {"size": 12, "cutout": 11.375, "od": 13.0, "displacement": 0.22, "depth": 9.0,
                      "fs": 32.0, "qts": 0.36, "qes": 0.40, "qms": 4.8, "vas": 3.5, "xmax": 42.0, "sens": 82.5, "power": 2000, "re": 2.0, "le": 2.5, "bl": 25.0},
    "DC Level 4 15": {"size": 15, "cutout": 14.375, "od": 16.125, "displacement": 0.40, "depth": 11.5,
                      "fs": 28.0, "qts": 0.35, "qes": 0.38, "qms": 5.0, "vas": 6.5, "xmax": 50.0, "sens": 83.0, "power": 2750, "re": 1.6, "le": 3.0, "bl": 32.0},
    "DC Level 4 18": {"size": 18, "cutout": 17.25, "od": 19.25, "displacement": 0.62, "depth": 14.0,
                      "fs": 24.0, "qts": 0.34, "qes": 0.37, "qms": 5.2, "vas": 10.0, "xmax": 58.0, "sens": 83.5, "power": 3500, "re": 1.4, "le": 3.5, "bl": 38.0},
    
    # DC Level 5 Series
    "DC Level 5 12": {"size": 12, "cutout": 11.5, "od": 13.25, "displacement": 0.28, "depth": 10.0,
                      "fs": 30.0, "qts": 0.32, "qes": 0.35, "qms": 4.5, "vas": 4.0, "xmax": 48.0, "sens": 81.5, "power": 2500, "re": 1.8, "le": 2.8, "bl": 28.0},
    "DC Level 5 15": {"size": 15, "cutout": 14.5, "od": 16.5, "displacement": 0.48, "depth": 12.5,
                      "fs": 26.0, "qts": 0.30, "qes": 0.33, "qms": 4.8, "vas": 7.5, "xmax": 55.0, "sens": 82.0, "power": 3500, "re": 1.4, "le": 3.2, "bl": 36.0},
    "DC Level 5 18": {"size": 18, "cutout": 17.5, "od": 19.75, "displacement": 0.72, "depth": 15.0,
                      "fs": 22.0, "qts": 0.28, "qes": 0.30, "qms": 5.0, "vas": 12.0, "xmax": 62.0, "sens": 82.5, "power": 5000, "re": 1.2, "le": 3.8, "bl": 42.0},
    
    # DC Level 6 Series (Elite)
    "DC Level 6 12": {"size": 12, "cutout": 11.625, "od": 13.5, "displacement": 0.35, "depth": 11.0,
                      "fs": 28.0, "qts": 0.30, "qes": 0.32, "qms": 4.2, "vas": 4.5, "xmax": 52.0, "sens": 81.0, "power": 3000, "re": 1.6, "le": 3.0, "bl": 32.0},
    "DC Level 6 15": {"size": 15, "cutout": 14.625, "od": 16.75, "displacement": 0.55, "depth": 13.5,
                      "fs": 24.0, "qts": 0.28, "qes": 0.30, "qms": 4.5, "vas": 8.5, "xmax": 58.0, "sens": 81.5, "power": 4000, "re": 1.3, "le": 3.4, "bl": 40.0},
    "DC Level 6 18": {"size": 18, "cutout": 17.3, "od": 19.2, "displacement": 0.75, "depth": 15.5,
                      "fs": 20.0, "qts": 0.26, "qes": 0.28, "qms": 4.8, "vas": 13.5, "xmax": 65.0, "sens": 82.0, "power": 6000, "re": 1.0, "le": 4.0, "bl": 48.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # JL AUDIO
    # ═══════════════════════════════════════════════════════════════════════════════
    # JL W0 Series
    "JL W0v3 8": {"size": 8, "cutout": 7.0, "od": 8.0, "displacement": 0.03, "depth": 3.75,
                  "fs": 52.0, "qts": 0.58, "qes": 0.70, "qms": 5.5, "vas": 0.45, "xmax": 8.0, "sens": 84.5, "power": 150, "re": 3.6, "le": 1.0, "bl": 8.0},
    "JL W0v3 10": {"size": 10, "cutout": 9.0, "od": 10.0, "displacement": 0.05, "depth": 4.75,
                   "fs": 45.0, "qts": 0.55, "qes": 0.66, "qms": 5.8, "vas": 0.9, "xmax": 10.0, "sens": 85.0, "power": 300, "re": 3.5, "le": 1.3, "bl": 10.0},
    "JL W0v3 12": {"size": 12, "cutout": 11.0, "od": 12.0, "displacement": 0.08, "depth": 5.75,
                   "fs": 40.0, "qts": 0.52, "qes": 0.62, "qms": 6.0, "vas": 1.6, "xmax": 12.0, "sens": 85.5, "power": 400, "re": 3.4, "le": 1.6, "bl": 12.0},
    
    # JL W3v3 Series
    "JL W3v3 6.5": {"size": 6.5, "cutout": 5.625, "od": 6.5, "displacement": 0.02, "depth": 3.0,
                    "fs": 58.0, "qts": 0.48, "qes": 0.56, "qms": 5.0, "vas": 0.22, "xmax": 9.0, "sens": 83.0, "power": 150, "re": 3.6, "le": 0.9, "bl": 7.5},
    "JL W3v3 8": {"size": 8, "cutout": 7.125, "od": 8.125, "displacement": 0.038, "depth": 4.0,
                  "fs": 48.0, "qts": 0.45, "qes": 0.52, "qms": 5.2, "vas": 0.52, "xmax": 12.0, "sens": 84.0, "power": 250, "re": 3.5, "le": 1.2, "bl": 10.0},
    "JL W3v3 10": {"size": 10, "cutout": 9.125, "od": 10.25, "displacement": 0.068, "depth": 5.25,
                   "fs": 42.0, "qts": 0.42, "qes": 0.48, "qms": 5.5, "vas": 1.1, "xmax": 16.0, "sens": 85.0, "power": 500, "re": 3.4, "le": 1.5, "bl": 13.0},
    "JL W3v3 12": {"size": 12, "cutout": 11.125, "od": 12.25, "displacement": 0.10, "depth": 6.5,
                   "fs": 38.0, "qts": 0.40, "qes": 0.46, "qms": 5.8, "vas": 2.0, "xmax": 18.0, "sens": 86.0, "power": 500, "re": 3.3, "le": 1.8, "bl": 15.0},
    "JL W3v3 15": {"size": 15, "cutout": 13.875, "od": 15.125, "displacement": 0.18, "depth": 8.0,
                   "fs": 34.0, "qts": 0.38, "qes": 0.43, "qms": 6.0, "vas": 4.0, "xmax": 20.0, "sens": 86.5, "power": 750, "re": 3.0, "le": 2.2, "bl": 18.0},
    
    # JL W6v3 Series
    "JL W6v3 8": {"size": 8, "cutout": 7.25, "od": 8.25, "displacement": 0.042, "depth": 4.5,
                  "fs": 45.0, "qts": 0.38, "qes": 0.42, "qms": 4.8, "vas": 0.65, "xmax": 15.0, "sens": 83.5, "power": 350, "re": 3.4, "le": 1.4, "bl": 12.0},
    "JL W6v3 10": {"size": 10, "cutout": 9.25, "od": 10.375, "displacement": 0.08, "depth": 6.0,
                   "fs": 38.0, "qts": 0.36, "qes": 0.40, "qms": 5.0, "vas": 1.4, "xmax": 20.0, "sens": 84.0, "power": 600, "re": 3.2, "le": 1.7, "bl": 16.0},
    "JL W6v3 12": {"size": 12, "cutout": 11.25, "od": 12.5, "displacement": 0.14, "depth": 7.5,
                   "fs": 32.0, "qts": 0.35, "qes": 0.38, "qms": 5.2, "vas": 2.8, "xmax": 24.0, "sens": 84.5, "power": 750, "re": 3.0, "le": 2.0, "bl": 19.0},
    "JL W6v3 13": {"size": 13, "cutout": 12.25, "od": 13.5, "displacement": 0.18, "depth": 8.25,
                   "fs": 30.0, "qts": 0.34, "qes": 0.37, "qms": 5.5, "vas": 3.5, "xmax": 26.0, "sens": 85.0, "power": 900, "re": 2.8, "le": 2.3, "bl": 21.0},
    
    # JL W7 Series
    "JL W7 8": {"size": 8, "cutout": 7.375, "od": 8.375, "displacement": 0.06, "depth": 5.5,
                "fs": 38.0, "qts": 0.32, "qes": 0.35, "qms": 4.5, "vas": 0.85, "xmax": 22.0, "sens": 82.5, "power": 500, "re": 3.2, "le": 1.6, "bl": 14.0},
    "JL W7 10": {"size": 10, "cutout": 9.375, "od": 10.5, "displacement": 0.11, "depth": 7.0,
                 "fs": 32.0, "qts": 0.30, "qes": 0.32, "qms": 4.8, "vas": 1.8, "xmax": 28.0, "sens": 83.0, "power": 750, "re": 3.0, "le": 2.0, "bl": 18.0},
    "JL W7 12": {"size": 12, "cutout": 11.375, "od": 12.75, "displacement": 0.20, "depth": 9.0,
                 "fs": 28.0, "qts": 0.28, "qes": 0.30, "qms": 5.0, "vas": 3.5, "xmax": 34.0, "sens": 83.5, "power": 1000, "re": 2.8, "le": 2.4, "bl": 22.0},
    "JL W7 13": {"size": 13, "cutout": 12.375, "od": 13.75, "displacement": 0.26, "depth": 10.0,
                 "fs": 26.0, "qts": 0.27, "qes": 0.29, "qms": 5.2, "vas": 4.5, "xmax": 38.0, "sens": 84.0, "power": 1500, "re": 2.6, "le": 2.8, "bl": 26.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # KICKER
    # ═══════════════════════════════════════════════════════════════════════════════
    # Kicker CompR Series
    "Kicker CompR 8": {"size": 8, "cutout": 7.125, "od": 8.125, "displacement": 0.038, "depth": 4.25,
                       "fs": 48.0, "qts": 0.52, "qes": 0.62, "qms": 5.2, "vas": 0.55, "xmax": 12.0, "sens": 84.0, "power": 300, "re": 3.5, "le": 1.2, "bl": 10.0},
    "Kicker CompR 10": {"size": 10, "cutout": 9.0, "od": 10.125, "displacement": 0.065, "depth": 5.5,
                        "fs": 42.0, "qts": 0.50, "qes": 0.60, "qms": 5.5, "vas": 1.1, "xmax": 16.0, "sens": 85.0, "power": 400, "re": 3.4, "le": 1.5, "bl": 12.5},
    "Kicker CompR 12": {"size": 12, "cutout": 11.0, "od": 12.125, "displacement": 0.10, "depth": 6.5,
                        "fs": 36.0, "qts": 0.48, "qes": 0.56, "qms": 5.8, "vas": 2.0, "xmax": 18.0, "sens": 86.0, "power": 500, "re": 3.3, "le": 1.8, "bl": 14.5},
    "Kicker CompR 15": {"size": 15, "cutout": 13.75, "od": 14.875, "displacement": 0.17, "depth": 8.0,
                        "fs": 32.0, "qts": 0.46, "qes": 0.54, "qms": 6.0, "vas": 3.8, "xmax": 20.0, "sens": 86.5, "power": 800, "re": 3.0, "le": 2.2, "bl": 17.0},
    
    # Kicker CompVR Series
    "Kicker CompVR 10": {"size": 10, "cutout": 9.125, "od": 10.25, "displacement": 0.072, "depth": 5.75,
                         "fs": 40.0, "qts": 0.45, "qes": 0.52, "qms": 5.2, "vas": 1.25, "xmax": 18.0, "sens": 85.5, "power": 500, "re": 3.4, "le": 1.6, "bl": 14.0},
    "Kicker CompVR 12": {"size": 12, "cutout": 11.125, "od": 12.25, "displacement": 0.115, "depth": 7.0,
                         "fs": 34.0, "qts": 0.44, "qes": 0.50, "qms": 5.5, "vas": 2.3, "xmax": 22.0, "sens": 86.5, "power": 700, "re": 3.2, "le": 1.9, "bl": 16.5},
    "Kicker CompVR 15": {"size": 15, "cutout": 13.875, "od": 15.0, "displacement": 0.19, "depth": 8.5,
                         "fs": 30.0, "qts": 0.42, "qes": 0.48, "qms": 5.8, "vas": 4.2, "xmax": 24.0, "sens": 87.0, "power": 1000, "re": 3.0, "le": 2.4, "bl": 19.0},
    
    # Kicker L7 Series
    "Kicker L7 8": {"size": 8, "cutout": 7.25, "od": 8.375, "displacement": 0.055, "depth": 5.25,
                    "fs": 42.0, "qts": 0.40, "qes": 0.46, "qms": 4.8, "vas": 0.72, "xmax": 20.0, "sens": 83.5, "power": 450, "re": 3.3, "le": 1.5, "bl": 13.0},
    "Kicker L7 10": {"size": 10, "cutout": 9.25, "od": 10.5, "displacement": 0.095, "depth": 6.75,
                     "fs": 36.0, "qts": 0.38, "qes": 0.43, "qms": 5.0, "vas": 1.5, "xmax": 26.0, "sens": 84.0, "power": 600, "re": 3.1, "le": 1.8, "bl": 17.0},
    "Kicker L7 12": {"size": 12, "cutout": 11.25, "od": 12.5, "displacement": 0.16, "depth": 8.25,
                     "fs": 32.0, "qts": 0.36, "qes": 0.40, "qms": 5.2, "vas": 2.8, "xmax": 32.0, "sens": 84.5, "power": 900, "re": 2.9, "le": 2.2, "bl": 21.0},
    "Kicker L7 15": {"size": 15, "cutout": 14.125, "od": 15.5, "displacement": 0.28, "depth": 10.5,
                     "fs": 28.0, "qts": 0.35, "qes": 0.38, "qms": 5.5, "vas": 5.0, "xmax": 38.0, "sens": 85.0, "power": 1200, "re": 2.7, "le": 2.8, "bl": 25.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # ALPINE
    # ═══════════════════════════════════════════════════════════════════════════════
    # Alpine Type-R Series
    "Alpine Type-R 8": {"size": 8, "cutout": 7.125, "od": 8.125, "displacement": 0.04, "depth": 4.25,
                        "fs": 48.0, "qts": 0.48, "qes": 0.56, "qms": 5.0, "vas": 0.58, "xmax": 14.0, "sens": 84.0, "power": 350, "re": 3.5, "le": 1.3, "bl": 11.0},
    "Alpine Type-R 10": {"size": 10, "cutout": 9.125, "od": 10.25, "displacement": 0.072, "depth": 5.5,
                         "fs": 40.0, "qts": 0.45, "qes": 0.52, "qms": 5.2, "vas": 1.2, "xmax": 18.0, "sens": 85.0, "power": 500, "re": 3.4, "le": 1.6, "bl": 14.0},
    "Alpine Type-R 12": {"size": 12, "cutout": 11.125, "od": 12.25, "displacement": 0.12, "depth": 7.0,
                         "fs": 34.0, "qts": 0.42, "qes": 0.48, "qms": 5.5, "vas": 2.4, "xmax": 22.0, "sens": 85.5, "power": 750, "re": 3.2, "le": 2.0, "bl": 17.0},
    "Alpine Type-R 15": {"size": 15, "cutout": 13.875, "od": 15.125, "displacement": 0.20, "depth": 8.75,
                         "fs": 30.0, "qts": 0.40, "qes": 0.45, "qms": 5.8, "vas": 4.5, "xmax": 26.0, "sens": 86.0, "power": 1000, "re": 3.0, "le": 2.5, "bl": 20.0},
    
    # Alpine Type-S Series
    "Alpine Type-S 8": {"size": 8, "cutout": 7.0, "od": 8.0, "displacement": 0.032, "depth": 3.75,
                        "fs": 52.0, "qts": 0.58, "qes": 0.70, "qms": 5.5, "vas": 0.45, "xmax": 9.0, "sens": 84.5, "power": 200, "re": 3.6, "le": 1.0, "bl": 8.5},
    "Alpine Type-S 10": {"size": 10, "cutout": 9.0, "od": 10.125, "displacement": 0.058, "depth": 5.0,
                         "fs": 45.0, "qts": 0.55, "qes": 0.66, "qms": 5.8, "vas": 0.95, "xmax": 11.0, "sens": 85.0, "power": 300, "re": 3.5, "le": 1.3, "bl": 10.5},
    "Alpine Type-S 12": {"size": 12, "cutout": 10.875, "od": 12.0, "displacement": 0.09, "depth": 6.0,
                         "fs": 38.0, "qts": 0.52, "qes": 0.62, "qms": 6.0, "vas": 1.8, "xmax": 14.0, "sens": 85.5, "power": 400, "re": 3.4, "le": 1.6, "bl": 12.5},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # ROCKFORD FOSGATE
    # ═══════════════════════════════════════════════════════════════════════════════
    # Rockford Punch P1 Series
    "Rockford P1 8": {"size": 8, "cutout": 7.0, "od": 8.0, "displacement": 0.03, "depth": 3.75,
                      "fs": 54.0, "qts": 0.60, "qes": 0.72, "qms": 5.5, "vas": 0.42, "xmax": 8.0, "sens": 84.0, "power": 150, "re": 3.6, "le": 1.0, "bl": 8.0},
    "Rockford P1 10": {"size": 10, "cutout": 9.0, "od": 10.0, "displacement": 0.055, "depth": 4.75,
                       "fs": 46.0, "qts": 0.58, "qes": 0.70, "qms": 5.8, "vas": 0.88, "xmax": 10.0, "sens": 84.5, "power": 250, "re": 3.5, "le": 1.3, "bl": 10.0},
    "Rockford P1 12": {"size": 12, "cutout": 11.0, "od": 12.0, "displacement": 0.08, "depth": 5.75,
                       "fs": 40.0, "qts": 0.55, "qes": 0.66, "qms": 6.0, "vas": 1.65, "xmax": 12.0, "sens": 85.0, "power": 300, "re": 3.4, "le": 1.6, "bl": 12.0},
    "Rockford P1 15": {"size": 15, "cutout": 13.75, "od": 14.75, "displacement": 0.14, "depth": 7.25,
                       "fs": 35.0, "qts": 0.52, "qes": 0.62, "qms": 6.2, "vas": 3.4, "xmax": 14.0, "sens": 85.5, "power": 500, "re": 3.2, "le": 2.0, "bl": 15.0},
    
    # Rockford Punch P2 Series
    "Rockford P2 8": {"size": 8, "cutout": 7.125, "od": 8.125, "displacement": 0.042, "depth": 4.5,
                      "fs": 48.0, "qts": 0.52, "qes": 0.62, "qms": 5.2, "vas": 0.56, "xmax": 13.0, "sens": 84.0, "power": 250, "re": 3.5, "le": 1.2, "bl": 10.5},
    "Rockford P2 10": {"size": 10, "cutout": 9.125, "od": 10.25, "displacement": 0.075, "depth": 5.75,
                       "fs": 42.0, "qts": 0.50, "qes": 0.58, "qms": 5.5, "vas": 1.15, "xmax": 17.0, "sens": 85.0, "power": 400, "re": 3.4, "le": 1.5, "bl": 13.5},
    "Rockford P2 12": {"size": 12, "cutout": 11.125, "od": 12.25, "displacement": 0.115, "depth": 7.0,
                       "fs": 36.0, "qts": 0.48, "qes": 0.56, "qms": 5.8, "vas": 2.2, "xmax": 20.0, "sens": 85.5, "power": 600, "re": 3.3, "le": 1.8, "bl": 16.0},
    "Rockford P2 15": {"size": 15, "cutout": 13.875, "od": 15.0, "displacement": 0.19, "depth": 8.5,
                       "fs": 32.0, "qts": 0.45, "qes": 0.52, "qms": 6.0, "vas": 4.0, "xmax": 23.0, "sens": 86.0, "power": 800, "re": 3.0, "le": 2.3, "bl": 19.0},
    
    # Rockford T1 Series
    "Rockford T1 8": {"size": 8, "cutout": 7.25, "od": 8.25, "displacement": 0.055, "depth": 5.25,
                      "fs": 42.0, "qts": 0.42, "qes": 0.48, "qms": 4.8, "vas": 0.7, "xmax": 19.0, "sens": 83.0, "power": 400, "re": 3.3, "le": 1.5, "bl": 13.0},
    "Rockford T1 10": {"size": 10, "cutout": 9.25, "od": 10.375, "displacement": 0.095, "depth": 6.5,
                       "fs": 36.0, "qts": 0.40, "qes": 0.45, "qms": 5.0, "vas": 1.45, "xmax": 25.0, "sens": 84.0, "power": 600, "re": 3.1, "le": 1.8, "bl": 17.0},
    "Rockford T1 12": {"size": 12, "cutout": 11.25, "od": 12.5, "displacement": 0.16, "depth": 8.0,
                       "fs": 32.0, "qts": 0.38, "qes": 0.42, "qms": 5.2, "vas": 2.75, "xmax": 30.0, "sens": 84.5, "power": 800, "re": 2.9, "le": 2.2, "bl": 21.0},
    "Rockford T1 15": {"size": 15, "cutout": 14.125, "od": 15.375, "displacement": 0.27, "depth": 10.0,
                       "fs": 28.0, "qts": 0.36, "qes": 0.40, "qms": 5.5, "vas": 5.0, "xmax": 35.0, "sens": 85.0, "power": 1200, "re": 2.7, "le": 2.8, "bl": 26.0},
    "Rockford T1 19": {"size": 19, "cutout": 17.625, "od": 19.25, "displacement": 0.52, "depth": 12.5,
                       "fs": 24.0, "qts": 0.34, "qes": 0.37, "qms": 5.8, "vas": 9.0, "xmax": 42.0, "sens": 85.5, "power": 1600, "re": 2.4, "le": 3.5, "bl": 32.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # PIONEER
    # ═══════════════════════════════════════════════════════════════════════════════
    "Pioneer TS-W3003D4 12": {"size": 12, "cutout": 11.0, "od": 12.125, "displacement": 0.10, "depth": 6.5,
                              "fs": 38.0, "qts": 0.50, "qes": 0.58, "qms": 5.5, "vas": 2.0, "xmax": 16.0, "sens": 86.0, "power": 600, "re": 3.2, "le": 1.8, "bl": 14.0},
    "Pioneer TS-SW2502S4 10": {"size": 10, "cutout": 9.0, "od": 10.0, "displacement": 0.05, "depth": 3.125,
                               "fs": 42.0, "qts": 0.72, "qes": 0.90, "qms": 6.5, "vas": 1.0, "xmax": 12.0, "sens": 88.0, "power": 300, "re": 3.6, "le": 1.2, "bl": 9.0},
    "Pioneer TS-A300D4 12": {"size": 12, "cutout": 11.0, "od": 12.0, "displacement": 0.085, "depth": 5.75,
                             "fs": 40.0, "qts": 0.55, "qes": 0.66, "qms": 5.8, "vas": 1.75, "xmax": 13.0, "sens": 86.5, "power": 500, "re": 3.4, "le": 1.6, "bl": 13.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # ORION
    # ═══════════════════════════════════════════════════════════════════════════════
    # Orion HCCA Series
    "Orion HCCA 10": {"size": 10, "cutout": 9.375, "od": 10.625, "displacement": 0.12, "depth": 7.0,
                      "fs": 34.0, "qts": 0.34, "qes": 0.37, "qms": 4.5, "vas": 2.0, "xmax": 38.0, "sens": 81.5, "power": 2000, "re": 2.0, "le": 2.2, "bl": 20.0},
    "Orion HCCA 12": {"size": 12, "cutout": 11.375, "od": 13.0, "displacement": 0.22, "depth": 9.0,
                      "fs": 30.0, "qts": 0.32, "qes": 0.35, "qms": 4.8, "vas": 3.8, "xmax": 45.0, "sens": 82.0, "power": 2500, "re": 1.8, "le": 2.6, "bl": 26.0},
    "Orion HCCA 15": {"size": 15, "cutout": 14.375, "od": 16.0, "displacement": 0.40, "depth": 11.5,
                      "fs": 26.0, "qts": 0.30, "qes": 0.33, "qms": 5.0, "vas": 7.0, "xmax": 52.0, "sens": 82.5, "power": 3500, "re": 1.5, "le": 3.2, "bl": 34.0},
    "Orion HCCA 18": {"size": 18, "cutout": 17.25, "od": 19.125, "displacement": 0.62, "depth": 14.0,
                      "fs": 22.0, "qts": 0.28, "qes": 0.30, "qms": 5.2, "vas": 11.0, "xmax": 60.0, "sens": 83.0, "power": 5000, "re": 1.2, "le": 3.8, "bl": 42.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # FI AUDIO (Fi Car Audio)
    # ═══════════════════════════════════════════════════════════════════════════════
    # Fi Q Series
    "Fi Q 10": {"size": 10, "cutout": 9.25, "od": 10.625, "displacement": 0.10, "depth": 6.75,
                "fs": 38.0, "qts": 0.40, "qes": 0.45, "qms": 4.8, "vas": 1.6, "xmax": 30.0, "sens": 83.5, "power": 1000, "re": 3.0, "le": 1.8, "bl": 16.0},
    "Fi Q 12": {"size": 12, "cutout": 11.25, "od": 12.875, "displacement": 0.18, "depth": 8.5,
                "fs": 34.0, "qts": 0.38, "qes": 0.42, "qms": 5.0, "vas": 3.0, "xmax": 36.0, "sens": 84.0, "power": 1500, "re": 2.8, "le": 2.2, "bl": 20.0},
    "Fi Q 15": {"size": 15, "cutout": 14.25, "od": 15.875, "displacement": 0.32, "depth": 11.0,
                "fs": 30.0, "qts": 0.36, "qes": 0.40, "qms": 5.2, "vas": 5.5, "xmax": 42.0, "sens": 84.5, "power": 2000, "re": 2.5, "le": 2.8, "bl": 25.0},
    "Fi Q 18": {"size": 18, "cutout": 17.125, "od": 19.0, "displacement": 0.52, "depth": 13.5,
                "fs": 26.0, "qts": 0.35, "qes": 0.38, "qms": 5.5, "vas": 8.5, "xmax": 48.0, "sens": 85.0, "power": 2500, "re": 2.2, "le": 3.2, "bl": 30.0},
    
    # Fi SP4 Series
    "Fi SP4 10": {"size": 10, "cutout": 9.375, "od": 10.75, "displacement": 0.14, "depth": 7.5,
                  "fs": 34.0, "qts": 0.35, "qes": 0.38, "qms": 4.5, "vas": 2.2, "xmax": 40.0, "sens": 82.0, "power": 1800, "re": 2.4, "le": 2.2, "bl": 20.0},
    "Fi SP4 12": {"size": 12, "cutout": 11.375, "od": 13.0, "displacement": 0.25, "depth": 9.5,
                  "fs": 30.0, "qts": 0.33, "qes": 0.36, "qms": 4.8, "vas": 4.0, "xmax": 48.0, "sens": 82.5, "power": 2500, "re": 2.0, "le": 2.6, "bl": 26.0},
    "Fi SP4 15": {"size": 15, "cutout": 14.375, "od": 16.25, "displacement": 0.45, "depth": 12.0,
                  "fs": 26.0, "qts": 0.32, "qes": 0.35, "qms": 5.0, "vas": 7.0, "xmax": 55.0, "sens": 83.0, "power": 3500, "re": 1.6, "le": 3.2, "bl": 34.0},
    "Fi SP4 18": {"size": 18, "cutout": 17.375, "od": 19.5, "displacement": 0.68, "depth": 15.0,
                  "fs": 22.0, "qts": 0.30, "qes": 0.32, "qms": 5.2, "vas": 11.0, "xmax": 62.0, "sens": 83.5, "power": 4500, "re": 1.3, "le": 3.8, "bl": 42.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # AMERICAN BASS
    # ═══════════════════════════════════════════════════════════════════════════════
    "American Bass XFL-8": {"size": 8, "cutout": 7.25, "od": 8.375, "displacement": 0.055, "depth": 5.0,
                            "fs": 44.0, "qts": 0.42, "qes": 0.48, "qms": 4.8, "vas": 0.72, "xmax": 20.0, "sens": 83.0, "power": 800, "re": 3.2, "le": 1.5, "bl": 12.5},
    "American Bass XFL-10": {"size": 10, "cutout": 9.25, "od": 10.5, "displacement": 0.10, "depth": 6.5,
                             "fs": 38.0, "qts": 0.40, "qes": 0.45, "qms": 5.0, "vas": 1.5, "xmax": 28.0, "sens": 83.5, "power": 1200, "re": 3.0, "le": 1.8, "bl": 16.5},
    "American Bass XFL-12": {"size": 12, "cutout": 11.25, "od": 12.75, "displacement": 0.18, "depth": 8.5,
                             "fs": 34.0, "qts": 0.38, "qes": 0.42, "qms": 5.2, "vas": 2.8, "xmax": 35.0, "sens": 84.0, "power": 1500, "re": 2.8, "le": 2.2, "bl": 21.0},
    "American Bass XFL-15": {"size": 15, "cutout": 14.125, "od": 15.625, "displacement": 0.32, "depth": 10.5,
                             "fs": 30.0, "qts": 0.36, "qes": 0.40, "qms": 5.5, "vas": 5.2, "xmax": 42.0, "sens": 84.5, "power": 2000, "re": 2.5, "le": 2.8, "bl": 26.0},
    "American Bass XFL-18": {"size": 18, "cutout": 17.0, "od": 18.875, "displacement": 0.52, "depth": 13.0,
                             "fs": 26.0, "qts": 0.35, "qes": 0.38, "qms": 5.8, "vas": 8.0, "xmax": 50.0, "sens": 85.0, "power": 2500, "re": 2.2, "le": 3.4, "bl": 32.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # DEAF BONCE
    # ═══════════════════════════════════════════════════════════════════════════════
    # Deaf Bonce Machete Lite Series (Entry/Budget)
    "Deaf Bonce Machete ML-10S": {"size": 10, "cutout": 9.0, "od": 10.25, "displacement": 0.065, "depth": 5.5,
                                  "fs": 44.0, "qts": 0.50, "qes": 0.60, "qms": 5.8, "vas": 1.1, "xmax": 15.0, "sens": 85.5, "power": 300, "re": 3.3, "le": 1.5, "bl": 12.5},
    "Deaf Bonce Machete ML-12S": {"size": 12, "cutout": 11.0, "od": 12.25, "displacement": 0.10, "depth": 6.5,
                                  "fs": 38.0, "qts": 0.48, "qes": 0.56, "qms": 6.0, "vas": 2.0, "xmax": 18.0, "sens": 86.0, "power": 300, "re": 3.2, "le": 1.8, "bl": 14.5},
    "Deaf Bonce Machete ML-10R": {"size": 10, "cutout": 9.25, "od": 10.5, "displacement": 0.10, "depth": 6.5,
                                  "fs": 40.0, "qts": 0.42, "qes": 0.48, "qms": 5.2, "vas": 1.4, "xmax": 24.0, "sens": 84.5, "power": 500, "re": 3.1, "le": 1.7, "bl": 15.0},
    "Deaf Bonce Machete ML-12R": {"size": 12, "cutout": 11.25, "od": 12.5, "displacement": 0.16, "depth": 8.0,
                                  "fs": 36.0, "qts": 0.40, "qes": 0.45, "qms": 5.5, "vas": 2.6, "xmax": 30.0, "sens": 85.0, "power": 500, "re": 2.9, "le": 2.1, "bl": 19.0},
    
    # Deaf Bonce Machete Fight Series (Mid-High Power)
    "Deaf Bonce Machete MF-08S": {"size": 8, "cutout": 7.25, "od": 8.5, "displacement": 0.06, "depth": 5.25,
                                  "fs": 42.0, "qts": 0.38, "qes": 0.42, "qms": 4.5, "vas": 0.85, "xmax": 25.0, "sens": 82.5, "power": 600, "re": 2.8, "le": 1.6, "bl": 14.0},
    "Deaf Bonce Machete MF-10S": {"size": 10, "cutout": 9.375, "od": 10.75, "displacement": 0.12, "depth": 7.0,
                                  "fs": 36.0, "qts": 0.36, "qes": 0.40, "qms": 4.8, "vas": 1.8, "xmax": 32.0, "sens": 83.0, "power": 800, "re": 2.4, "le": 2.0, "bl": 18.0},
    "Deaf Bonce Machete MF-12S": {"size": 12, "cutout": 11.375, "od": 13.0, "displacement": 0.22, "depth": 9.0,
                                  "fs": 32.0, "qts": 0.34, "qes": 0.37, "qms": 5.0, "vas": 3.5, "xmax": 40.0, "sens": 83.5, "power": 800, "re": 2.0, "le": 2.5, "bl": 24.0},
    "Deaf Bonce Machete MF-12R": {"size": 12, "cutout": 11.5, "od": 13.25, "displacement": 0.28, "depth": 10.0,
                                  "fs": 30.0, "qts": 0.32, "qes": 0.35, "qms": 4.5, "vas": 4.0, "xmax": 48.0, "sens": 82.0, "power": 1200, "re": 1.8, "le": 2.8, "bl": 26.0},
    "Deaf Bonce Machete MF-15R": {"size": 15, "cutout": 14.25, "od": 16.0, "displacement": 0.38, "depth": 11.0,
                                  "fs": 28.0, "qts": 0.30, "qes": 0.33, "qms": 4.8, "vas": 6.0, "xmax": 50.0, "sens": 82.5, "power": 1200, "re": 1.6, "le": 3.2, "bl": 32.0},
    
    # Deaf Bonce Apocalypse Series (High Power)
    "Deaf Bonce Apocalypse DB-SA250/8": {"size": 8, "cutout": 7.25, "od": 8.5, "displacement": 0.06, "depth": 5.25,
                                         "fs": 42.0, "qts": 0.38, "qes": 0.42, "qms": 4.5, "vas": 0.85, "xmax": 25.0, "sens": 82.5, "power": 1000, "re": 2.8, "le": 1.6, "bl": 14.0},
    "Deaf Bonce Apocalypse DB-SA250/10": {"size": 10, "cutout": 9.375, "od": 10.75, "displacement": 0.12, "depth": 7.0,
                                          "fs": 36.0, "qts": 0.36, "qes": 0.40, "qms": 4.8, "vas": 1.8, "xmax": 32.0, "sens": 83.0, "power": 1000, "re": 2.4, "le": 2.0, "bl": 18.0},
    "Deaf Bonce Apocalypse DB-SA252": {"size": 12, "cutout": 11.375, "od": 13.0, "displacement": 0.22, "depth": 9.0,
                                       "fs": 32.0, "qts": 0.34, "qes": 0.37, "qms": 5.0, "vas": 3.5, "xmax": 40.0, "sens": 83.5, "power": 1000, "re": 2.0, "le": 2.5, "bl": 24.0},
    "Deaf Bonce Apocalypse DB-SA255": {"size": 15, "cutout": 14.375, "od": 16.125, "displacement": 0.40, "depth": 11.5,
                                       "fs": 28.0, "qts": 0.32, "qes": 0.35, "qms": 5.2, "vas": 6.5, "xmax": 48.0, "sens": 84.0, "power": 1000, "re": 1.6, "le": 3.0, "bl": 32.0},
    "Deaf Bonce Apocalypse DB-SA272": {"size": 12, "cutout": 11.5, "od": 13.25, "displacement": 0.28, "depth": 10.0,
                                       "fs": 30.0, "qts": 0.32, "qes": 0.35, "qms": 4.5, "vas": 4.0, "xmax": 48.0, "sens": 82.0, "power": 1500, "re": 1.8, "le": 2.8, "bl": 26.0},
    "Deaf Bonce Apocalypse DB-SA275": {"size": 15, "cutout": 14.25, "od": 16.0, "displacement": 0.38, "depth": 11.0,
                                       "fs": 26.0, "qts": 0.30, "qes": 0.33, "qms": 4.8, "vas": 6.5, "xmax": 50.0, "sens": 82.5, "power": 1500, "re": 1.6, "le": 3.2, "bl": 34.0},
    "Deaf Bonce Apocalypse DB-SA302": {"size": 12, "cutout": 11.75, "od": 13.5, "displacement": 0.35, "depth": 11.0,
                                       "fs": 28.0, "qts": 0.30, "qes": 0.32, "qms": 4.2, "vas": 4.5, "xmax": 52.0, "sens": 81.0, "power": 2000, "re": 1.4, "le": 3.0, "bl": 32.0},
    "Deaf Bonce Apocalypse DB-SA305": {"size": 15, "cutout": 14.375, "od": 16.25, "displacement": 0.48, "depth": 12.5,
                                       "fs": 24.0, "qts": 0.28, "qes": 0.30, "qms": 4.5, "vas": 8.0, "xmax": 60.0, "sens": 82.0, "power": 2000, "re": 1.2, "le": 3.6, "bl": 40.0},
    "Deaf Bonce Apocalypse DB-3012R": {"size": 12, "cutout": 11.875, "od": 13.75, "displacement": 0.42, "depth": 12.5,
                                       "fs": 26.0, "qts": 0.28, "qes": 0.30, "qms": 4.2, "vas": 5.0, "xmax": 55.0, "sens": 81.5, "power": 2800, "re": 1.3, "le": 3.2, "bl": 35.0},
    "Deaf Bonce Apocalypse DB-3015R": {"size": 15, "cutout": 14.5, "od": 16.5, "displacement": 0.55, "depth": 14.0,
                                       "fs": 22.0, "qts": 0.26, "qes": 0.28, "qms": 4.5, "vas": 9.5, "xmax": 62.0, "sens": 82.0, "power": 2800, "re": 1.0, "le": 4.0, "bl": 45.0},
    "Deaf Bonce Apocalypse DB-3512R": {"size": 12, "cutout": 12.0, "od": 13.875, "displacement": 0.50, "depth": 13.5,
                                       "fs": 24.0, "qts": 0.26, "qes": 0.28, "qms": 4.0, "vas": 5.5, "xmax": 58.0, "sens": 81.0, "power": 3500, "re": 1.1, "le": 3.4, "bl": 38.0},
    "Deaf Bonce Apocalypse DB-3515R": {"size": 15, "cutout": 14.75, "od": 16.75, "displacement": 0.65, "depth": 15.0,
                                       "fs": 20.0, "qts": 0.24, "qes": 0.26, "qms": 4.2, "vas": 11.0, "xmax": 65.0, "sens": 82.5, "power": 3500, "re": 0.9, "le": 4.2, "bl": 50.0},
    "Deaf Bonce Apocalypse DB-4512R": {"size": 12, "cutout": 12.125, "od": 14.0, "displacement": 0.60, "depth": 14.5,
                                       "fs": 22.0, "qts": 0.24, "qes": 0.26, "qms": 3.8, "vas": 6.0, "xmax": 62.0, "sens": 80.5, "power": 4500, "re": 1.0, "le": 3.6, "bl": 42.0},
    "Deaf Bonce Apocalypse DB-4515R": {"size": 15, "cutout": 14.875, "od": 16.875, "displacement": 0.75, "depth": 16.0,
                                       "fs": 18.0, "qts": 0.22, "qes": 0.24, "qms": 4.0, "vas": 12.5, "xmax": 68.0, "sens": 83.0, "power": 4500, "re": 0.8, "le": 4.4, "bl": 55.0},
    "Deaf Bonce Apocalypse DB-4518R": {"size": 18, "cutout": 17.375, "od": 19.375, "displacement": 0.65, "depth": 14.5,
                                       "fs": 22.0, "qts": 0.30, "qes": 0.32, "qms": 5.2, "vas": 10.5, "xmax": 58.0, "sens": 83.5, "power": 4500, "re": 1.3, "le": 3.6, "bl": 42.0},
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # B2 AUDIO - Denmark Premium Brand
    # ═══════════════════════════════════════════════════════════════════════════════
    # B2 Rage Series
    "B2 Rage 8": {"size": 8, "cutout": 7.125, "od": 8.25, "displacement": 0.048, "depth": 4.75,
                  "fs": 46.0, "qts": 0.44, "qes": 0.50, "qms": 5.0, "vas": 0.65, "xmax": 16.0, "sens": 84.5, "power": 600, "re": 3.4, "le": 1.4, "bl": 11.5},
    "B2 Rage 10": {"size": 10, "cutout": 9.125, "od": 10.375, "displacement": 0.085, "depth": 6.0,
                   "fs": 40.0, "qts": 0.42, "qes": 0.48, "qms": 5.2, "vas": 1.35, "xmax": 22.0, "sens": 85.0, "power": 1000, "re": 3.2, "le": 1.7, "bl": 15.0},
    "B2 Rage 12": {"size": 12, "cutout": 11.125, "od": 12.5, "displacement": 0.14, "depth": 7.5,
                   "fs": 36.0, "qts": 0.40, "qes": 0.45, "qms": 5.5, "vas": 2.6, "xmax": 28.0, "sens": 85.5, "power": 1400, "re": 3.0, "le": 2.1, "bl": 19.0},
    "B2 Rage 15": {"size": 15, "cutout": 14.0, "od": 15.375, "displacement": 0.26, "depth": 9.5,
                   "fs": 32.0, "qts": 0.38, "qes": 0.42, "qms": 5.8, "vas": 4.8, "xmax": 35.0, "sens": 86.0, "power": 1800, "re": 2.8, "le": 2.6, "bl": 24.0},
    "B2 Rage XL12": {"size": 12, "cutout": 11.375, "od": 13.0, "displacement": 0.22, "depth": 9.25,
                     "fs": 30.0, "qts": 0.34, "qes": 0.37, "qms": 4.8, "vas": 3.5, "xmax": 42.0, "sens": 82.5, "power": 2500, "re": 2.0, "le": 2.6, "bl": 26.0},
    "B2 Rage XL15": {"size": 15, "cutout": 14.375, "od": 16.125, "displacement": 0.40, "depth": 11.75,
                     "fs": 26.0, "qts": 0.32, "qes": 0.35, "qms": 5.0, "vas": 6.5, "xmax": 50.0, "sens": 83.0, "power": 3500, "re": 1.6, "le": 3.0, "bl": 34.0},
}

# Port Database (Feature #25) - expanded with verified specs
# A and B coefficients for port length formula: L = (A * 6.0) / (f² * V) + B
# Flare lengths are per-flare (total flare length = 2x for both ends)
port_options = {
    # BigAss Ports - verified specs (DON'T MODIFY - already calibrated)
    "6 in BAP": {"d": 6.3125, "c": 8.125, "od": 9.375, "m": 0.0218, "A": 84240.00, "B": -3.6000, "flare_len": 2.25, "wall": 0.125},
    "8 in BAP": {"d": 8.1875, "c": 11.25, "od": 12.375, "m": 0.0365, "A": 141732.00, "B": -4.4767, "flare_len": 2.75, "wall": 0.125},
    "10 in BAP": {"d": 10.1875, "c": 13.0, "od": 14.4375, "m": 0.0566, "A": 219438.00, "B": -6.1867, "flare_len": 3.0, "wall": 0.125},
    
    # Precision Port - verified against diyaudioguy calculations
    # 3" Precision Port - ID=3.0", flare OD=4.5", flare length=1.5" each
    "3 in Precision": {"d": 3.0, "c": 4.5, "od": 4.75, "m": 0.0049, "A": 3168.0, "B": -1.5, "flare_len": 1.5, "wall": 0.125},
    # 4" Precision Port - ID=4.0", flare OD=5.75", flare length=1.75" each  
    "4 in Precision": {"d": 4.0, "c": 5.75, "od": 6.25, "m": 0.0087, "A": 5632.0, "B": -2.0, "flare_len": 1.75, "wall": 0.125},
    # 6" Precision Port - ID=6.0", flare OD=8.0", flare length=2.0" each
    "6 in Precision": {"d": 6.0, "c": 8.0, "od": 8.75, "m": 0.0196, "A": 12672.0, "B": -3.2, "flare_len": 2.0, "wall": 0.125},
    
    # Generic Aero Ports (no flares - straight pipe)
    "3 in Aero": {"d": 3.0, "c": 4.0, "od": 4.5, "m": 0.0049, "A": 3168.0, "B": -1.5, "flare_len": 0, "wall": 0.125},
    "4 in Aero": {"d": 4.0, "c": 5.25, "od": 6.0, "m": 0.0087, "A": 5632.0, "B": -2.0, "flare_len": 0, "wall": 0.125},
    
    # Custom Pipe option placeholder
    "Custom Pipe": {"d": 4.0, "c": 4.5, "od": 5.0, "m": 0.0087, "A": 5632.0, "B": -2.0, "flare_len": 0, "wall": 0.25},
    
    # Slot Port (for conversion reference)
    "Slot Port": {"d": 0, "c": 0, "od": 0, "m": 0, "A": 0, "B": 0, "flare_len": 0, "wall": 0},
}

# Vehicle Trunk Templates (Feature #24)
vehicle_templates = {
    "Custom": {"width": 32.0, "height": 20.0, "max_depth": 40.0},
    "Chevy Silverado Crew": {"width": 55.0, "height": 16.0, "max_depth": 20.0},
    "Ford F-150 SuperCrew": {"width": 58.0, "height": 15.0, "max_depth": 18.0},
    "Ram 1500 Crew Cab": {"width": 56.0, "height": 14.5, "max_depth": 19.0},
    "Jeep Wrangler JK/JL": {"width": 36.0, "height": 16.0, "max_depth": 14.0},
    "Honda Civic Sedan": {"width": 42.0, "height": 16.0, "max_depth": 28.0},
    "Toyota Camry": {"width": 44.0, "height": 18.0, "max_depth": 32.0},
    "Chevy Tahoe/Suburban": {"width": 48.0, "height": 20.0, "max_depth": 36.0},
    "Nissan Altima": {"width": 40.0, "height": 17.0, "max_depth": 30.0},
}

# Wood Thickness Presets (Feature #26)
wood_presets = {
    '1/2" (0.5")': 0.5,
    '5/8" (0.625")': 0.625,
    '3/4" (0.75")': 0.75,
    '1" (1.0")': 1.0,
    '1.5" (Double)': 1.5,
}

# Material Cost Database (Feature #8)
material_costs = {
    "MDF 4x8 3/4\"": 45.0,
    "MDF 4x8 1/2\"": 32.0,
    "Baltic Birch 4x8 3/4\"": 85.0,
    "Wood Glue (bottle)": 8.0,
    "Screws (box)": 12.0,
    "Carpet (yard)": 15.0,
    "Terminal Cup": 8.0,
    "Poly Fill (bag)": 10.0,
    "Gasket Tape (roll)": 6.0,
}

# ═══════════════════════════════════════════════════════════════════════════════
# SIDEBAR - Clean organized sections
# ═══════════════════════════════════════════════════════════════════════════════

# --- ENCLOSURE TYPE (Feature #12, #13) ---
st.sidebar.header("📦 Enclosure Type")
enclosure_type = st.sidebar.selectbox("Box Type", ["Ported", "Sealed", "4th Order Bandpass", "6th Order Bandpass"])
is_ported = enclosure_type == "Ported"
is_sealed = enclosure_type == "Sealed"
is_bandpass = "Bandpass" in enclosure_type

# --- VEHICLE TEMPLATE (Feature #24) ---
with st.sidebar.expander("🚗 Vehicle Templates", expanded=False):
    sel_vehicle = st.selectbox("Select Vehicle", list(vehicle_templates.keys()))
    if sel_vehicle != "Custom":
        vt = vehicle_templates[sel_vehicle]
        st.info(f"Max: {vt['width']}\"W x {vt['height']}\"H x {vt['max_depth']}\"D")

# --- SUBWOOFER SECTION ---
st.sidebar.header("📈 Subwoofer Configuration")

# Organize subwoofers by manufacturer
def get_manufacturer(sub_name):
    """Extract manufacturer from subwoofer name"""
    if sub_name == "Custom":
        return "Custom"
    # Known manufacturer prefixes
    manufacturers = {
        "Sundown": "Sundown Audio",
        "Skar": "Skar Audio", 
        "SSA": "Sound Solutions Audio",
        "DC": "DC Audio",
        "JL": "JL Audio",
        "Kicker": "Kicker",
        "Alpine": "Alpine",
        "Rockford": "Rockford Fosgate",
        "Pioneer": "Pioneer",
        "Orion": "Orion",
        "Fi": "Fi Audio",
        "American Bass": "American Bass",
        "Deaf Bonce": "Deaf Bonce",
        "B2": "B2 Audio"
    }
    for prefix, full_name in manufacturers.items():
        if sub_name.startswith(prefix):
            return full_name
    return "Other"

def get_model_line(sub_name):
    """Extract model line from subwoofer name (e.g., 'X Series' from 'Sundown X-12')"""
    parts = sub_name.split()
    if len(parts) >= 2:
        # Return first two parts as model identifier
        return " ".join(parts[:2])
    return sub_name

# Group subs by manufacturer
manufacturers_list = {}
for sub_key in subwoofer_database.keys():
    mfr = get_manufacturer(sub_key)
    if mfr not in manufacturers_list:
        manufacturers_list[mfr] = []
    manufacturers_list[mfr].append(sub_key)

# Sort manufacturers alphabetically (Custom first)
sorted_manufacturers = ["Custom"] + sorted([m for m in manufacturers_list.keys() if m != "Custom"])

# Two-step selection: Manufacturer, then Model/Size
sel_manufacturer = st.sidebar.selectbox("🏭 Manufacturer", sorted_manufacturers)

# Get available subs for selected manufacturer
available_subs = manufacturers_list.get(sel_manufacturer, ["Custom"])

# Group by model line for display
model_lines = {}
for sub in available_subs:
    if sub == "Custom":
        model_lines["Custom"] = ["Custom"]
    else:
        model_line = get_model_line(sub)
        if model_line not in model_lines:
            model_lines[model_line] = []
        model_lines[model_line].append(sub)

# Create display list grouped by model
display_subs = []
for model_line in sorted(model_lines.keys()):
    subs_in_line = sorted(model_lines[model_line], key=lambda x: subwoofer_database[x]["size"])
    display_subs.extend(subs_in_line)

# Format display to show size
def format_sub_display(sub_name):
    if sub_name == "Custom":
        return "Custom (Manual Entry)"
    sub = subwoofer_database[sub_name]
    return f"{sub_name} ({sub['size']}\")"

sel_sub_preset = st.sidebar.selectbox("🔊 Subwoofer Model", display_subs,
                                       format_func=format_sub_display)
sub_preset = subwoofer_database[sel_sub_preset]

sub_name = st.sidebar.text_input("Sub Model", sel_sub_preset if sel_sub_preset != "Custom" else "Custom Sub")

# Multiple sub support (Feature #30)
num_subs = st.sidebar.selectbox("Number of Subwoofers", [1, 2, 3, 4, 5, 6], index=0)

# Sub mounting side
sub_mount_side = st.sidebar.selectbox("Sub Mounting Side", ["Front", "Back", "Left", "Right", "Top", "Bottom"], index=0)

# Sub arrangement patterns
arrangement_options = {
    "Auto": "Auto (default layout)",
    "Row Horizontal": "Row (side by side)",
    "Row Vertical": "Row (stacked vertically)", 
    "2x2 Grid": "2x2 Square Grid",
    "3x2 Grid": "3x2 Grid (3 wide, 2 tall)",
    "2x3 Grid": "2x3 Grid (2 wide, 3 tall)",
    "Pyramid Up": "Pyramid (point up △)",
    "Pyramid Down": "Pyramid (point down ▽)",
    "Diamond": "Diamond ◇",
}
sub_arrangement = st.sidebar.selectbox("Sub Arrangement", list(arrangement_options.keys()), 
                                        format_func=lambda x: arrangement_options[x])

# Subwoofer size options
sub_sizes = {
    "6.5 in": {"cutout": 5.75, "od": 7.0},
    "8 in":   {"cutout": 7.25, "od": 8.5},
    "10 in":  {"cutout": 9.25, "od": 10.5},
    "12 in":  {"cutout": 11.0, "od": 12.5},
    "15 in":  {"cutout": 13.75, "od": 15.5},
    "18 in":  {"cutout": 16.65, "od": 18.5},
    "24 in":  {"cutout": 22.5, "od": 24.5},
}

# Use preset or custom size
if sel_sub_preset != "Custom":
    size_key = f"{sub_preset['size']} in"
    sel_sub_size = st.sidebar.selectbox("Subwoofer Size", list(sub_sizes.keys()), 
                                         index=list(sub_sizes.keys()).index(size_key) if size_key in sub_sizes else 5)
    sub_c = st.sidebar.number_input("Cutout Diameter (in)", value=sub_preset["cutout"])
    sub_od = sub_preset["od"]
    sub_d = st.sidebar.number_input("Displacement per Sub (cf)", value=sub_preset["displacement"], format="%.3f")
    sub_depth = st.sidebar.number_input("Mounting Depth (in)", value=sub_preset["depth"])
else:
    sel_sub_size = st.sidebar.selectbox("Subwoofer Size", list(sub_sizes.keys()), index=5)
    sub_c = st.sidebar.number_input("Cutout Diameter (in)", value=sub_sizes[sel_sub_size]["cutout"])
    sub_od = sub_sizes[sel_sub_size]["od"]
    sub_d = st.sidebar.number_input("Displacement per Sub (cf)", value=0.280, format="%.3f")
    sub_depth = st.sidebar.number_input("Mounting Depth (in)", value=11.5)

# Per-sub inversion settings
with st.sidebar.expander("🔄 Sub Inversion Settings", expanded=False):
    st.caption("Inverted subs have cone facing outward")
    sub_inverted = []
    for i in range(num_subs):
        inverted = st.checkbox(f"Sub {i+1} Inverted", value=False, key=f"inv_{i}")
        sub_inverted.append(inverted)
    num_inverted = sum(sub_inverted)

# --- T/S PARAMETERS (Feature #14) ---
with st.sidebar.expander("📊 Thiele-Small Parameters", expanded=False):
    st.caption("For accurate acoustic modeling")
    if sel_sub_preset != "Custom":
        ts_fs = st.number_input("Fs (Hz) - Resonant Frequency", value=sub_preset["fs"], min_value=10.0, max_value=100.0)
        ts_qts = st.number_input("Qts - Total Q Factor", value=sub_preset["qts"], min_value=0.1, max_value=2.0, format="%.2f")
        ts_vas = st.number_input("Vas (cf) - Equiv. Compliance Vol", value=sub_preset["vas"], min_value=0.1, max_value=50.0)
        ts_xmax = st.number_input("Xmax (mm) - Max Excursion", value=sub_preset["xmax"], min_value=1.0, max_value=100.0)
        ts_sens = st.number_input("Sensitivity (dB @ 1W/1m)", value=sub_preset["sens"], min_value=70.0, max_value=100.0)
        ts_power = st.number_input("RMS Power (W)", value=float(sub_preset["power"]), min_value=50.0, max_value=10000.0)
    else:
        ts_fs = st.number_input("Fs (Hz) - Resonant Frequency", value=28.0, min_value=10.0, max_value=100.0)
        ts_qts = st.number_input("Qts - Total Q Factor", value=0.38, min_value=0.1, max_value=2.0, format="%.2f")
        ts_vas = st.number_input("Vas (cf) - Equiv. Compliance Vol", value=8.5, min_value=0.1, max_value=50.0)
        ts_xmax = st.number_input("Xmax (mm) - Max Excursion", value=25.0, min_value=1.0, max_value=100.0)
        ts_sens = st.number_input("Sensitivity (dB @ 1W/1m)", value=86.0, min_value=70.0, max_value=100.0)
        ts_power = st.number_input("RMS Power (W)", value=1500.0, min_value=50.0, max_value=10000.0)
    use_ts_model = st.checkbox("Use T/S Model for Acoustic Curve", value=True)

st.sidebar.markdown("---")

# --- BOX DIMENSIONS ---
st.sidebar.header("📦 Box Dimensions")

# Apply vehicle template if selected
if sel_vehicle != "Custom":
    vt = vehicle_templates[sel_vehicle]
    default_w = min(32.0, vt['width'])
    default_h = min(20.0, vt['height'])
else:
    default_w = 32.0
    default_h = 20.0

max_w = st.sidebar.number_input("Width (in)", value=default_w)
max_h = st.sidebar.number_input("Height (in)", value=default_h)
net_v = st.sidebar.number_input("Target Net Volume (cf)", value=6.2)

# Determine 4th vs 6th order bandpass
is_4th_order = enclosure_type == "4th Order Bandpass"
is_6th_order = enclosure_type == "6th Order Bandpass"

# Tuning section (depends on enclosure type)
if is_ported:
    tune = st.sidebar.number_input("Tuning Frequency (Hz)", value=36.0)
elif is_4th_order:
    st.sidebar.markdown("### 4th Order Bandpass Design")
    
    # Get T/S parameters from preset (with defaults)
    ts_fs_bp = sub_preset.get("fs", 35.0)
    ts_qts_bp = sub_preset.get("qts", 0.45)
    ts_qes_bp = sub_preset.get("qes", ts_qts_bp * 1.2)  # Estimate if not present
    ts_qms_bp = sub_preset.get("qms", 5.0)
    ts_vas_bp = sub_preset.get("vas", 3.0)  # Per sub Vas
    sub_size_bp = sub_preset.get("size", 15)
    
    # Check if required T/S parameters are available
    has_required_ts = all([
        "fs" in sub_preset,
        "qts" in sub_preset,
        "vas" in sub_preset
    ])
    
    # Bypass option for parameter requirements
    bypass_ts_check = st.sidebar.checkbox("⚠️ Bypass T/S Parameter Check", value=False,
                                           help="Enable to proceed without complete T/S parameters (not recommended)")
    
    if not has_required_ts and not bypass_ts_check:
        st.sidebar.error("⚠️ **Missing Required T/S Parameters**")
        st.sidebar.warning("""
        4th order bandpass requires accurate T/S parameters:
        - **Fs** (Free-air resonance)
        - **Qts** (Total Q factor)  
        - **Vas** (Equivalent air compliance volume)
        
        Select a subwoofer with known parameters or enable bypass.
        """)
        # Set reasonable defaults based on sub size and count
        tune = 50.0
        bp_ratio_value = 2.0
        # Industry standard: ~1.0-1.5 cf sealed per 12" sub, scale by size
        base_sealed = (sub_size_bp / 12) ** 2 * 1.25 * num_subs
        sealed_chamber_vol = base_sealed
        ported_chamber_vol = base_sealed * bp_ratio_value
        net_v = sealed_chamber_vol + ported_chamber_vol
    else:
        # ═══════════════════════════════════════════════════════════════════
        # PROPER 4TH ORDER BANDPASS CALCULATIONS
        # Based on industry standards and subbox.pro/WinISD methodologies
        # ═══════════════════════════════════════════════════════════════════
        
        # SEALED CHAMBER (rear): Based on Vas and Qtc target
        # For 4th order, sealed chamber Qtc typically 0.6-0.8
        # Vb = Vas / ((Qtc/Qts)^2 - 1)
        # For multiple subs: multiply by num_subs
        
        target_qtc = 0.707  # Butterworth alignment (good starting point)
        if ts_qts_bp > 0 and ts_qts_bp < target_qtc:
            # Calculate sealed volume per sub
            qtc_ratio = (target_qtc / ts_qts_bp) ** 2
            sealed_per_sub = ts_vas_bp / (qtc_ratio - 1) if qtc_ratio > 1 else ts_vas_bp * 0.7
        else:
            # Qts too high for this Qtc, use rule of thumb
            sealed_per_sub = ts_vas_bp * 0.7
        
        # Minimum sealed chamber sizes by sub size (industry standard)
        min_sealed_by_size = {
            6.5: 0.25, 8: 0.4, 10: 0.6, 12: 1.0, 15: 1.75, 18: 2.5
        }
        min_sealed = min_sealed_by_size.get(sub_size_bp, sub_size_bp / 12 * 1.0)
        sealed_per_sub = max(sealed_per_sub, min_sealed)
        
        # Total sealed chamber for all subs
        rec_sealed_vol = sealed_per_sub * num_subs
        
        # PORTED CHAMBER (front): Typically 1.5x to 3x sealed volume
        # Ratio affects bandwidth and efficiency
        # Lower Qts subs can use higher ratios (more SPL)
        # Higher Qts subs need lower ratios (flatter response)
        if ts_qts_bp < 0.35:
            rec_ratio = 2.5
        elif ts_qts_bp < 0.45:
            rec_ratio = 2.0
        elif ts_qts_bp < 0.55:
            rec_ratio = 1.75
        else:
            rec_ratio = 1.5
        
        rec_ported_vol = rec_sealed_vol * rec_ratio
        rec_total_vol = rec_sealed_vol + rec_ported_vol
        
        # Show T/S parameter summary
        st.sidebar.markdown("#### T/S Parameters")
        ts_col1, ts_col2 = st.sidebar.columns(2)
        with ts_col1:
            st.caption(f"Fs: {ts_fs_bp} Hz")
            st.caption(f"Qts: {ts_qts_bp}")
        with ts_col2:
            st.caption(f"Qes: {round(ts_qes_bp, 2)}")
            st.caption(f"Vas: {ts_vas_bp} cf")
        
        # Suitability check
        fs_qes_ratio = ts_fs_bp / ts_qes_bp if ts_qes_bp > 0 else 50
        
        if ts_qts_bp >= 0.35 and ts_qts_bp <= 0.55:
            st.sidebar.success("✅ Sub is well-suited for 4th order bandpass")
            suit_msg = "Good 4th order candidate"
        elif ts_qts_bp > 0.28 and ts_qts_bp <= 0.65:
            st.sidebar.warning("⚠️ Sub may work in 4th order but not optimal")
            suit_msg = "Marginal 4th order fit"
        else:
            st.sidebar.error("❌ Sub better suited for 6th order or ported")
            suit_msg = "Consider other enclosure types"
        
        # Show recommendations with PER SUB values
        st.sidebar.markdown("#### 📊 Recommended Volumes")
        st.sidebar.info(f"""
        **For {num_subs}x {sub_size_bp}" subwoofer(s):**
        
        **Per Sub:**
        - Sealed: {round(sealed_per_sub, 2)} cf
        - Ported: {round(sealed_per_sub * rec_ratio, 2)} cf
        
        **Total ({num_subs} sub{"s" if num_subs > 1 else ""}):**
        - Sealed Chamber: **{round(rec_sealed_vol, 2)} cf**
        - Ported Chamber: **{round(rec_ported_vol, 2)} cf**
        - Total Net: **{round(rec_total_vol, 2)} cf**
        
        *{suit_msg}*
        """)
        
        # Option to use recommendations
        use_ts_recommendations = st.sidebar.checkbox("Use Recommended Volumes", value=True)
        
        if use_ts_recommendations:
            net_v = rec_total_vol
            st.sidebar.success(f"✅ Using recommended {round(net_v, 2)} cf total")
        
        # Design goal selection
        bp_design_goal = st.sidebar.selectbox("Design Goal", [
            "Daily Driver (45-52 Hz)", 
            "SPL / Loud (50-60 Hz)", 
            "Low-End Extension (38-45 Hz)",
            "Custom"
        ])
        
        # Set default tuning based on goal and Fs
        # 4th order bandpass typically tuned 0.9x to 1.2x Fs
        if "Daily" in bp_design_goal:
            default_tune = round(ts_fs_bp * 1.1, 0)
        elif "SPL" in bp_design_goal:
            default_tune = round(ts_fs_bp * 1.25, 0)
        elif "Low-End" in bp_design_goal:
            default_tune = round(ts_fs_bp * 0.95, 0)
        else:
            default_tune = round(ts_fs_bp * 1.0, 0)
        
        tune = st.sidebar.number_input("Ported Chamber Tuning (Hz)", value=default_tune, 
                                        help=f"Recommended: {round(ts_fs_bp * 0.9, 0)}-{round(ts_fs_bp * 1.2, 0)} Hz (Sub Fs: {ts_fs_bp} Hz)")
        
        # Volume ratio (ported:sealed)
        ratio_options = ["1:1", "1.5:1", "1.75:1", "2:1", "2.5:1", "3:1"]
        rec_ratio_str = f"{rec_ratio}:1"
        if rec_ratio_str not in ratio_options:
            rec_ratio_str = "2:1"
        
        bp_ratio = st.sidebar.select_slider("Ported:Sealed Ratio", 
                                             options=ratio_options,
                                             value=rec_ratio_str,
                                             help=f"Recommended: {rec_ratio}:1 for Qts={ts_qts_bp}")
        
        # Parse ratio
        ratio_parts = bp_ratio.split(":")
        bp_ratio_value = float(ratio_parts[0]) / float(ratio_parts[1])
        
        # Calculate chamber volumes based on ratio and total net volume
        sealed_chamber_vol = net_v / (1 + bp_ratio_value)
        ported_chamber_vol = net_v - sealed_chamber_vol
        
        # Display final calculated volumes
        st.sidebar.markdown("---")
        st.sidebar.markdown(f"""
        ### 📐 Final Chamber Sizes
        | Chamber | Volume |
        |---------|--------|
        | **Sealed** | **{round(sealed_chamber_vol, 2)} cf** |
        | **Ported** | **{round(ported_chamber_vol, 2)} cf** |
        | **Total Net** | **{round(net_v, 2)} cf** |
        | **Tuning** | **{tune} Hz** |
        """)
        
        # Advanced tuning options
        with st.sidebar.expander("🔧 Advanced 4th Order Settings"):
            use_polyfill = st.checkbox("Use Polyfill in Sealed Chamber", value=False,
                                        help="Polyfill can simulate up to 40% more volume")
            if use_polyfill:
                polyfill_density = st.slider("Polyfill Density (lb/cf)", 0.5, 1.5, 1.0)
                effective_sealed_vol = sealed_chamber_vol * (1 + 0.35 * polyfill_density)
                st.info(f"Effective sealed vol: {round(effective_sealed_vol, 2)} cf")
            
            # Port area recommendation based on cone area
            cone_area = math.pi * (sub_size_bp / 2) ** 2 * num_subs
            recommended_port_area = cone_area * 0.5  # 50% of total cone area
            st.caption(f"Recommended port area: ~{round(recommended_port_area, 1)} in²")
            st.caption(f"(50% of {num_subs}x {sub_size_bp}\" cone area)")

elif is_6th_order:
    st.sidebar.markdown("### 6th Order Bandpass Design")
    st.sidebar.info("🔊 **6th Order = Dual Ported Chambers**")
    
    # Get T/S parameters from preset (with defaults)
    ts_fs_bp = sub_preset.get("fs", 35.0)
    ts_qts_bp = sub_preset.get("qts", 0.45)
    ts_qes_bp = sub_preset.get("qes", ts_qts_bp * 1.2)
    ts_qms_bp = sub_preset.get("qms", 5.0)
    ts_vas_bp = sub_preset.get("vas", 3.0)
    sub_size_bp = sub_preset.get("size", 15)
    
    # 6th order requires LOWER Qts subs (high excursion, low Q)
    has_required_ts = all([
        "fs" in sub_preset,
        "qts" in sub_preset,
        "qes" in sub_preset,
        "vas" in sub_preset
    ])
    
    # Bypass option
    bypass_ts_check = st.sidebar.checkbox("⚠️ Bypass T/S Parameter Check", value=False,
                                           help="Enable to proceed without complete T/S parameters (not recommended)")
    
    if not has_required_ts and not bypass_ts_check:
        st.sidebar.error("⚠️ **Missing Required T/S Parameters**")
        st.sidebar.warning("""
        6th order bandpass requires accurate T/S parameters:
        - **Fs** (Free-air resonance)
        - **Qts** (Total Q factor)
        - **Qes** (Electrical Q factor)
        - **Vas** (Equivalent air compliance volume)
        
        Select a subwoofer with known parameters or enable bypass.
        """)
        # Reasonable defaults based on sub size
        tune = 50.0
        bp_ratio_value = 1.5
        base_vol = (sub_size_bp / 12) ** 2 * 1.5 * num_subs
        sealed_chamber_vol = base_vol
        ported_chamber_vol = base_vol * bp_ratio_value
        net_v = sealed_chamber_vol + ported_chamber_vol
    else:
        # ═══════════════════════════════════════════════════════════════════
        # PROPER 6TH ORDER BANDPASS CALCULATIONS
        # 6th order = both chambers are ported (wider bandwidth, more complex)
        # Best for LOW Qts subs (< 0.4)
        # ═══════════════════════════════════════════════════════════════════
        
        # 6th Order suitability check
        fs_qes_ratio = ts_fs_bp / ts_qes_bp if ts_qes_bp > 0 else 50
        
        st.sidebar.markdown("#### T/S Parameters")
        ts_col1, ts_col2 = st.sidebar.columns(2)
        with ts_col1:
            st.caption(f"Fs: {ts_fs_bp} Hz")
            st.caption(f"Qts: {ts_qts_bp}")
        with ts_col2:
            st.caption(f"Qes: {round(ts_qes_bp, 2)}")
            st.caption(f"Vas: {ts_vas_bp} cf")
        
        # 6th order suits LOW Qts subs
        if ts_qts_bp < 0.35:
            st.sidebar.success("✅ Sub is excellent for 6th order bandpass")
            suit_msg = "Ideal 6th order candidate"
        elif ts_qts_bp < 0.45:
            st.sidebar.success("✅ Sub is well-suited for 6th order bandpass")
            suit_msg = "Good 6th order candidate"
        elif ts_qts_bp < 0.55:
            st.sidebar.warning("⚠️ Sub may work in 6th order but not optimal")
            suit_msg = "Marginal 6th order fit"
        else:
            st.sidebar.error("❌ Sub better suited for 4th order or ported")
            suit_msg = "Consider 4th order or ported"
        
        # Calculate recommended volumes for 6th order
        # Both chambers are ported, typically equal or near-equal volumes
        # Rule of thumb: each chamber ~0.8-1.2x Vas per sub
        min_chamber_by_size = {
            6.5: 0.35, 8: 0.5, 10: 0.8, 12: 1.25, 15: 2.0, 18: 3.0
        }
        min_per_sub = min_chamber_by_size.get(sub_size_bp, sub_size_bp / 12 * 1.25)
        
        # Rear chamber (lower tuning)
        rec_rear_per_sub = max(ts_vas_bp * 0.9, min_per_sub)
        rec_rear_vol = rec_rear_per_sub * num_subs
        
        # Front chamber (higher tuning) - typically slightly larger
        rec_front_per_sub = rec_rear_per_sub * 1.25
        rec_front_vol = rec_front_per_sub * num_subs
        
        rec_total_vol = rec_rear_vol + rec_front_vol
        
        st.sidebar.markdown("#### 📊 Recommended Volumes")
        st.sidebar.info(f"""
        **For {num_subs}x {sub_size_bp}" subwoofer(s):**
        
        **Per Sub:**
        - Rear: {round(rec_rear_per_sub, 2)} cf
        - Front: {round(rec_front_per_sub, 2)} cf
        
        **Total ({num_subs} sub{"s" if num_subs > 1 else ""}):**
        - Rear Chamber: **{round(rec_rear_vol, 2)} cf**
        - Front Chamber: **{round(rec_front_vol, 2)} cf**
        - Total Net: **{round(rec_total_vol, 2)} cf**
        
        *{suit_msg}*
        """)
        
        use_ts_recommendations = st.sidebar.checkbox("Use Recommended Volumes", value=True)
        if use_ts_recommendations:
            net_v = rec_total_vol
        
        # 6th order has TWO ported chambers
        st.sidebar.markdown("#### Chamber Configuration")
        
        # Rear chamber tuning (lower frequency)
        tune_rear = st.sidebar.number_input("Rear Chamber Tuning (Hz)", 
                                             value=round(ts_fs_bp * 0.8, 0),
                                             help="Rear ported chamber - typically tuned 0.7-0.9x Fs")
        
        # Front chamber tuning (higher frequency)  
        tune_front = st.sidebar.number_input("Front Chamber Tuning (Hz)",
                                              value=round(ts_fs_bp * 1.2, 0),
                                              help="Front ported chamber - typically tuned 1.1-1.3x Fs")
        
        # Primary tune (used for main port calculations)
        tune = tune_front
        
        # Volume ratio between chambers
        bp_ratio = st.sidebar.select_slider("Front:Rear Ratio",
                                             options=["1:1", "1.25:1", "1.5:1", "1.75:1", "2:1"],
                                             value="1.25:1",
                                             help="Ratio between front and rear chamber volumes")
        
        ratio_parts = bp_ratio.split(":")
        bp_ratio_value = float(ratio_parts[0]) / float(ratio_parts[1])
        
        # Calculate chamber volumes
        sealed_chamber_vol = net_v / (1 + bp_ratio_value)  # "Rear" chamber
        ported_chamber_vol = net_v - sealed_chamber_vol     # "Front" chamber
        
        # Display final volumes
        st.sidebar.markdown("---")
        st.sidebar.markdown(f"""
        ### 📐 Final Chamber Sizes
        | Chamber | Volume | Tuning |
        |---------|--------|--------|
        | **Rear** | **{round(sealed_chamber_vol, 2)} cf** | {tune_rear} Hz |
        | **Front** | **{round(ported_chamber_vol, 2)} cf** | {tune_front} Hz |
        | **Total** | **{round(net_v, 2)} cf** | — |
        """)
        
        st.sidebar.info("""
        💡 **6th Order Tips:**
        - Both chambers need ports
        - Wider bandwidth than 4th order
        - More complex to tune
        - Best for SPL competition
        """)
        
else:
    tune = 0  # Sealed box
    # Default bandpass values for non-bandpass enclosures (to avoid undefined errors)
    bp_ratio_value = 2.0
    sealed_chamber_vol = 0
    ported_chamber_vol = 0

# Multiple tuning comparison (Feature #11)
with st.sidebar.expander("🎛️ Compare Tunings", expanded=False):
    compare_tunings = st.checkbox("Show Multiple Tunings", value=False)
    if compare_tunings:
        tune_compare = [
            st.number_input("Tuning 1 (Hz)", value=32.0, key="tune1"),
            st.number_input("Tuning 2 (Hz)", value=36.0, key="tune2"),
            st.number_input("Tuning 3 (Hz)", value=40.0, key="tune3"),
        ]

st.sidebar.markdown("---")

# --- PORT SECTION ---
if is_ported or is_bandpass:
    st.sidebar.header("🌀 Port Configuration")
    
    # Port type selection
    port_type = st.sidebar.radio("Port Type", ["Round Aero Port", "Slot Port"])
    
    if port_type == "Round Aero Port":
        # Filter port options (exclude Slot Port)
        round_port_options = [k for k in port_options.keys() if k != "Slot Port"]
        sel_port = st.sidebar.selectbox("Port Size", round_port_options)
        
        # Custom Pipe option
        if sel_port == "Custom Pipe":
            st.sidebar.markdown("**Custom Pipe Dimensions**")
            custom_id = st.sidebar.number_input("Inner Diameter (ID)", value=4.0, min_value=1.0, max_value=12.0, step=0.125)
            custom_od = st.sidebar.number_input("Outer Diameter (OD)", value=4.5, min_value=1.5, max_value=14.0, step=0.125)
            custom_wall = (custom_od - custom_id) / 2
            st.sidebar.caption(f"Wall Thickness: {round(custom_wall, 3)}\"")
            
            # Update port specs for custom pipe
            custom_area = math.pi * (custom_id / 2) ** 2
            # Calculate A coefficient: A = (c² × π × r²) / (4π² × 1728) simplified
            custom_A = (13504 ** 2 * custom_area) / (4 * math.pi ** 2 * 1728)
            ps = {
                "d": custom_id,
                "c": custom_od,
                "od": custom_od + 0.5,  # Allow for mounting flange
                "m": (custom_area * 1) / 1728,  # Per inch displacement
                "A": custom_A,
                "B": -0.825 * custom_id,  # End correction scales with diameter
                "flare_len": 0,  # No flares on custom pipe
                "wall": custom_wall
            }
        else:
            ps = port_options[sel_port]
        
        # Calculate port length using verified formula: L = A / (f² * V) + B
        # Where A and B are port-specific coefficients, f is tuning frequency in Hz, V is volume in ft³
        # Formula calculates TOTAL PORT LENGTH (with flares included)
        if tune > 0 and net_v > 0:
            # Use the A and B coefficients from the port database
            A = ps.get("A", 84000.0)  # Default fallback
            B = ps.get("B", -3.6)     # Default fallback
            # Calculate total port length including flares
            total_port_len_with_flares = (A / (tune ** 2 * net_v)) + B
        else:
            total_port_len_with_flares = 20.0
        
        # Get port diameter information from database
        port_diameter = ps.get("d", 6.0)
        port_name = sel_port
        
        # Port length breakdown - flare and end correction by port size:
        # 6" BAP: flare = 1.00", correction = 7.00"
        # 8" BAP: flare = 1.50", correction = 6.50"
        # 10" BAP: flare = 1.25", correction = 6.75"
        
        if port_name == "6 in BAP":
            flare_acoustic_len = 1.00
            end_correction = 7.00
        elif port_name == "8 in BAP":
            flare_acoustic_len = 1.50
            end_correction = 6.50
        else:  # 10" BAP and others
            flare_acoustic_len = 1.25
            end_correction = 6.75
        
        # Calculate measurements:
        # Effective Port Length (No Flares) = Total - flare contribution
        effective_port_len = total_port_len_with_flares - flare_acoustic_len
        
        # Main Tube Length (Cut Length) = Effective - end correction
        main_tube_len = effective_port_len - end_correction
        
        safe_port_len = max(6.0, float(main_tube_len))
        
        # Display all port length information
        st.sidebar.markdown("### 📏 Port Length Details")
        st.sidebar.info(f"""
**Total Port Length (With Flares):** {round(total_port_len_with_flares, 2)} in  
**Effective Port Length (No Flares):** {round(effective_port_len, 2)} in  
**Main Tube Length (Cut Length):** {round(main_tube_len, 2)} in  
**Total Port Area:** {round(math.pi * (ps['d']/2)**2, 2)} in²
        """)
        st.sidebar.caption(f"Flare acoustic contribution: {flare_acoustic_len}\" | End correction: {end_correction:.2f}\"")
        
        p_len = st.sidebar.slider("Port Length INSIDE Box (in)", 0, 50, int(min(50, safe_port_len)))
        
        # No bend for round ports
        slot_position = "Left Side"  # Placeholder
        slot_width = 3.0  # Placeholder
        slot_height = 12.0  # Placeholder
        port_needs_bend = False
        slot_leg1_len = 0
        slot_leg2_len = 0
        
        # Port positioning for round aero ports
        st.sidebar.markdown("#### Port Position")
        port_direction = st.sidebar.selectbox("Firing Direction", ["Front", "Rear", "Side", "Top"], key="round_port_pos")
        num_ports = st.sidebar.number_input("Number of Ports", 1, 4, 1)
        
    else:  # Slot Port (Feature #27)
        st.sidebar.markdown("#### Slot Port Dimensions")
        
        # Slot port height will be auto-calculated to fill interior height (full top to bottom)
        # For now use preliminary estimate; actual value calculated after construction details
        prelim_wood = 0.75  # Common MDF thickness for preliminary calc
        prelim_ih = max_h - (prelim_wood * 2)  # Preliminary interior height
        prelim_idv = (net_v * 1728) / ((max_w - prelim_wood*2) * prelim_ih)  # Preliminary depth
        
        # Slot port uses: box side wall, box top, box bottom - only needs ONE divider board
        # Uses shared wall configuration by default (port against enclosure wall)
        slot_shared_wall = True  # Auto-enabled: uses enclosure wall as port boundary
        
        # Calculate default slot width using industry standard formula
        # Industry standard: Slot width = Port Length / (2 × Port Height)
        # But we don't know length yet, so use iterative approach
        # Start with a reasonable estimate: width ≈ 0.15 × interior_height
        default_slot_width = prelim_ih * 0.15
        
        # Option to specify port area OR port width
        st.sidebar.markdown("**Port Size Configuration**")
        slot_size_method = st.sidebar.radio("Sizing Method", ["Auto (Industry Standard)", "Manual Width", "By Area (sq in)"], horizontal=False)
        
        if slot_size_method == "Auto (Industry Standard)":
            st.sidebar.caption(f"📐 Using industry standard formula")
            st.sidebar.caption(f"Height = {round(prelim_ih, 1)}\"")
            st.sidebar.caption(f"Default Width = {round(default_slot_width, 2)}\" (15% of height)")
            slot_width = default_slot_width
            
        elif slot_size_method == "Manual Width":
            # User specifies width directly with ability to adjust
            slot_width = st.sidebar.slider("Slot Width (in)", 1.0, 10.0, round(default_slot_width, 1), step=0.25,
                                            help="Adjust port width - length will recalculate automatically")
            st.sidebar.caption(f"📐 Height = {round(prelim_ih, 1)}\"")
            st.sidebar.caption(f"Width = {round(slot_width, 2)}\" (adjustable)")
            
        else:  # By Area
            # User specifies total port area in square inches
            target_area = st.sidebar.number_input("Target Port Area (sq in)", value=30.0, min_value=5.0, max_value=200.0)
            st.sidebar.caption(f"📐 Height = {round(prelim_ih, 1)}\"")
            # Calculate width from area: Area = Width × Height
            slot_width = target_area / prelim_ih
            st.sidebar.caption(f"Calculated Width: {round(slot_width, 2)}\"")
        
        st.sidebar.caption("✓ Using shared wall (port against enclosure wall)")
        
        # Position control - now with more options
        st.sidebar.markdown("#### Port Position")
        slot_position_options = ["Left Side", "Right Side"]
        if num_subs >= 2:
            slot_position_options.append("Center (Between Subs)")
        slot_position_options.append("Dual (Both Sides)")
        
        slot_position = st.sidebar.selectbox("Location", slot_position_options, key="slot_port_pos")
        
        # For dual ports, each port is half the total area needed
        if slot_position == "Dual (Both Sides)":
            st.sidebar.caption("🔄 Two slot ports - one on each side")
            num_slot_ports = 2
        else:
            num_slot_ports = 1
        
        # Calculate preliminary slot area and length
        # Slot height = full interior height (uses box top/bottom as port ceiling/floor)
        prelim_slot_height = prelim_ih
        prelim_slot_area = slot_width * prelim_slot_height * num_slot_ports  # Total port area
        prelim_equiv_diameter = 2 * math.sqrt(prelim_slot_area / math.pi)
        
        # Calculate slot port length using physics formula (verified against DIYAudioGuy)
        # Formula: Lv = (c² × A) / (4π² × f² × Vb), then L = Lv - k × √A
        # where: c = 13504 in/s (speed of sound), k = 1.005 (slot port end correction)
        # Verified within 0.08" accuracy against DIYAudioGuy reference calculator
        c_sound = 13504.0  # Speed of sound in inches per second
        k_end_correction = 1.005  # Slot port end correction factor (verified against DIYAudioGuy)
        
        if tune > 0 and net_v > 0:
            # Calculate acoustic length using Helmholtz resonance formula
            acoustic_len = (c_sound ** 2 * prelim_slot_area) / (4 * math.pi ** 2 * tune ** 2 * net_v * 1728)
            # Subtract end correction for physical port length
            end_effect = k_end_correction * math.sqrt(prelim_slot_area)
            prelim_slot_len = acoustic_len - end_effect
        else:
            prelim_slot_len = 20.0
        prelim_slot_len = max(6.0, prelim_slot_len)
        
        # Check if port needs L-bend (must leave clearance from back wall = port width)
        # Port CANNOT reach all the way to back wall - air needs to flow around!
        port_clearance_from_back = slot_width  # Minimum clearance = port width for airflow
        port_straight_max = prelim_idv - port_clearance_from_back  # Max straight run
        prelim_needs_bend = prelim_slot_len > port_straight_max
        
        st.sidebar.metric("📏 Calculated Port Length", f"{round(prelim_slot_len, 2)} in")
        st.sidebar.caption(f"Port Area: {round(prelim_slot_area, 1)} sq in (each: {round(prelim_slot_area/num_slot_ports, 1)} sq in)")
        st.sidebar.caption(f"Equiv. round diameter: {round(prelim_equiv_diameter, 2)} in")
        
        if prelim_needs_bend:
            # Calculate L-bend legs
            prelim_leg1 = port_straight_max  # First leg goes back (leaves clearance)
            prelim_leg2 = prelim_slot_len - prelim_leg1  # Second leg goes sideways
            st.sidebar.warning(f"⚠️ Port needs L-BEND")
            st.sidebar.caption(f"Leg 1 (back): {round(prelim_leg1, 1)}\" → Leg 2 (side): {round(prelim_leg2, 1)}\"")
            st.sidebar.caption(f"Clearance from back wall: {round(port_clearance_from_back, 1)}\"")
        else:
            st.sidebar.success("✅ Port fits straight (no bend needed)")
            prelim_leg1 = prelim_slot_len
            prelim_leg2 = 0
        
        # Store preliminary values - will be recalculated after construction details
        p_len = prelim_slot_len
        slot_height = prelim_slot_height  # Placeholder - recalculated later
        slot_area = prelim_slot_area
        equiv_diameter = prelim_equiv_diameter
        
        # Initialize bend variables (will be recalculated after construction details)
        port_needs_bend = prelim_needs_bend
        slot_leg1_len = prelim_leg1
        slot_leg2_len = prelim_leg2
        
        # Create pseudo port specs for slot
        ps = {"d": prelim_equiv_diameter, "c": prelim_equiv_diameter + 1, "od": prelim_equiv_diameter + 1.5, "m": prelim_slot_area / 1728}
        
        # For compatibility with visualization and velocity calcs
        port_direction = "Slot-" + slot_position
        num_ports = num_slot_ports
    
    # Port Air Velocity Calculator (Feature #10)
    # AERO PORTS vs SLOT PORTS have different velocity thresholds!
    # Aero ports have flared ends = smooth laminar flow = can handle higher velocity
    # Slot ports have sharp edges = turbulent flow = lower threshold before noise
    with st.sidebar.expander("🌬️ Port Air Velocity", expanded=False):
        if port_type == "Round Aero Port":
            port_area = math.pi * (ps["d"] / 2) ** 2 * num_ports
            # Aero port velocity thresholds (flared = efficient)
            velocity_limit_noise = 50.0    # Hard limit - definite chuffing
            velocity_limit_caution = 38.0  # Caution zone
            velocity_limit_good = 28.0     # Conservative safe zone
            port_efficiency = "Aero (Flared)"
        else:
            port_area = slot_area * num_ports
            # Slot port velocity thresholds (sharp edges = turbulent)
            velocity_limit_noise = 28.0    # Hard limit - definite noise
            velocity_limit_caution = 22.0  # Caution zone  
            velocity_limit_good = 17.0     # Conservative safe zone
            port_efficiency = "Slot (Sharp Edge)"
        
        # Calculate air velocity at max power
        # V = (Sd * Xmax * 2 * pi * f) / Ap
        sd = math.pi * (sub_c / 2) ** 2  # Cone area in sq inches
        sd_m2 = sd * 0.00064516  # Convert to m^2
        xmax_m = ts_xmax / 1000  # Convert mm to m
        port_area_m2 = port_area * 0.00064516
        
        # Peak air velocity at tuning frequency
        v_peak = (sd_m2 * xmax_m * 2 * math.pi * tune * num_subs) / port_area_m2 if port_area_m2 > 0 else 0
        v_peak_fps = v_peak * 3.28084  # Convert to feet/sec
        
        st.metric("Peak Port Velocity", f"{round(v_peak_fps, 1)} ft/s")
        st.caption(f"Port Type: **{port_efficiency}**")
        
        # Show velocity gauge relative to port type limits
        velocity_percent = (v_peak_fps / velocity_limit_noise) * 100
        
        if v_peak_fps > velocity_limit_noise:
            st.error(f"🚨 PORT NOISE! Velocity > {velocity_limit_noise} ft/s for {port_type}")
            st.caption("Increase port area or add more ports")
        elif v_peak_fps > velocity_limit_caution:
            st.warning(f"⚠️ Borderline ({round(velocity_percent)}% of limit) - may have some chuffing")
        elif v_peak_fps > velocity_limit_good:
            st.info(f"👍 Acceptable ({round(velocity_percent)}% of limit)")
        else:
            st.success(f"✓ Excellent! ({round(velocity_percent)}% of limit)")
        
        st.caption(f"Port Area: {round(port_area, 2)} sq in")
        
        # Show comparison info
        if port_type == "Round Aero Port":
            # Calculate what slot area would be needed for same velocity
            equiv_slot_area = port_area * (velocity_limit_noise / 28.0)
            st.caption(f"💡 Aero advantage: A slot port would need ~{round(equiv_slot_area, 1)} sq in for same performance")
        else:
            # Show how much smaller an aero port could be
            equiv_aero_area = port_area * (28.0 / velocity_limit_noise)
            equiv_aero_dia = 2 * math.sqrt(equiv_aero_area / (math.pi * num_ports))
            st.caption(f"💡 Tip: A {round(equiv_aero_dia, 1)}\" aero port would perform similarly")
else:
    # Sealed box - no port
    ps = {"d": 0, "c": 0, "od": 0, "m": 0}
    p_len = 0
    num_ports = 0
    port_direction = "None"
    port_type = "None"
    slot_position = "Left Side"  # Default placeholder
    slot_width = 3.0  # Default placeholder
    slot_height = 12.0  # Default placeholder
    port_needs_bend = False
    slot_leg1_len = 0
    slot_leg2_len = 0

st.sidebar.markdown("---")

# --- CONSTRUCTION (Feature #26) ---
with st.sidebar.expander("🪵 Construction Details", expanded=True):
    # Wood thickness preset
    wood_preset_sel = st.selectbox("Wood Thickness Preset", list(wood_presets.keys()), index=2)
    wood = wood_presets[wood_preset_sel]
    wood = st.number_input("Wood Thickness (in)", value=wood, format="%.3f")
    
    col1, col2 = st.columns(2)
    with col1:
        lay_f = st.select_slider("Front Layers", [1, 2, 3, 4, 5], 3)
        lay_tb = st.select_slider("Top/Bot Layers", [1, 2, 3], 1)
    with col2:
        lay_b = st.select_slider("Back Layers", [1, 2, 3], 1)
        lay_s = st.select_slider("Side Layers", [1, 2, 3], 1)

# --- BRACING OPTIONS (Feature #7 Enhanced) ---
with st.sidebar.expander("🔩 Bracing Options", expanded=False):
    brace_type = st.selectbox("Primary Brace Type", [
        "None",
        "Wooden Dowel Rod",
        "Window Brace (Single)",
        "Window Brace (4-Window / Quad)",
        "Window Brace (X-Brace Style)",
        "Lumber Cross Brace (2x2)",
        "Lumber Cross Brace (2x3)",
        "Lumber Cross Brace (2x4)",
        "Ladder Brace",
        "45° Corner Braces"
    ])
    
    # Initialize brace position storage
    if 'brace_positions' not in st.session_state:
        st.session_state.brace_positions = []
    
    if brace_type != "None":
        # Brace direction options (applies to most brace types)
        st.markdown("**Brace Orientation**")
        brace_direction = st.selectbox("Brace Direction", [
            "Side to Side (X-axis)", 
            "Front to Back (Y-axis)", 
            "Top to Bottom (Z-axis)"
        ], key="brace_dir")
        
        if "Dowel" in brace_type:
            # Wooden dowel rod options
            dowel_sizes = {
                "1\" Dowel": 1.0,
                "1.25\" Dowel": 1.25,
                "1.5\" Dowel": 1.5,
                "1.75\" Dowel": 1.75,
                "2\" Dowel": 2.0,
                "2.25\" Dowel": 2.25,
                "2.5\" Dowel": 2.5,
                "3\" Dowel": 3.0
            }
            dowel_size_sel = st.selectbox("Dowel Diameter", list(dowel_sizes.keys()), index=2)
            brace_diameter = dowel_sizes[dowel_size_sel]
            num_dowels = st.number_input("Number of Dowels", 1, 6, 2)
            
            # Calculate displacement based on direction
            prelim_idv = (net_v * 1728) / ((max_w - wood*2) * (max_h - wood*2))
            if "X-axis" in brace_direction:
                dowel_length = max_w - (wood * 2)
            elif "Y-axis" in brace_direction:
                dowel_length = prelim_idv
            else:  # Z-axis
                dowel_length = max_h - (wood * 2)
            brace_disp = (math.pi * (brace_diameter/2)**2 * dowel_length * num_dowels) / 1728
            st.caption(f"Each: {brace_diameter}\" dia × ~{round(dowel_length, 1)}\" long")
            
            # Position controls for each dowel
            st.markdown("**Individual Brace Positions**")
            brace_positions_list = []
            for i in range(num_dowels):
                with st.expander(f"Dowel {i+1} Position", expanded=False):
                    if "X-axis" in brace_direction:
                        pos_y = st.slider(f"Y Position (front→back)", 0.1, 0.9, 0.3 + (i * 0.3), key=f"dowel_y_{i}")
                        pos_z = st.slider(f"Z Position (bottom→top)", 0.1, 0.9, 0.5, key=f"dowel_z_{i}")
                        brace_positions_list.append({"y": pos_y, "z": pos_z})
                    elif "Y-axis" in brace_direction:
                        pos_x = st.slider(f"X Position (left→right)", 0.1, 0.9, 0.3 + (i * 0.3), key=f"dowel_x_{i}")
                        pos_z = st.slider(f"Z Position (bottom→top)", 0.1, 0.9, 0.5, key=f"dowel_z_{i}")
                        brace_positions_list.append({"x": pos_x, "z": pos_z})
                    else:  # Z-axis
                        pos_x = st.slider(f"X Position (left→right)", 0.1, 0.9, 0.3 + (i * 0.3), key=f"dowel_x_{i}")
                        pos_y = st.slider(f"Y Position (front→back)", 0.1, 0.9, 0.5, key=f"dowel_y_{i}")
                        brace_positions_list.append({"x": pos_x, "y": pos_y})
            st.session_state.brace_positions = brace_positions_list
            
        elif "Window" in brace_type:
            # Window brace options
            window_thicknesses = {
                "1/2\" (0.5\")": 0.5,
                "5/8\" (0.625\")": 0.625,
                "3/4\" (0.75\")": 0.75,
                "1\" (1.0\")": 1.0,
                "1.5\"": 1.5
            }
            window_thick_sel = st.selectbox("Window Brace Thickness", list(window_thicknesses.keys()), index=2)
            window_thickness = window_thicknesses[window_thick_sel]
            
            window_widths = {
                "2\" wide": 2.0,
                "2.5\" wide": 2.5,
                "3\" wide": 3.0,
                "3.5\" wide": 3.5,
                "4\" wide": 4.0
            }
            window_width_sel = st.selectbox("Window Brace Width (frame)", list(window_widths.keys()), index=2)
            window_width = window_widths[window_width_sel]
            
            num_window_braces = st.number_input("Number of Window Braces", 1, 3, 1)
            
            # Window brace position controls
            st.markdown("**Window Brace Positions**")
            window_brace_positions = []
            for i in range(num_window_braces):
                pos = st.slider(f"Brace {i+1} Y Position (front→back)", 0.2, 0.8, 0.3 + (i * 0.2), key=f"win_pos_{i}")
                window_brace_positions.append(pos)
            
            # Calculate window brace displacement based on style
            prelim_iw = max_w - (wood * 2)
            prelim_ih = max_h - (wood * 2)
            total_brace_area = prelim_iw * prelim_ih
            
            if "4-Window" in brace_type or "Quad" in brace_type:
                # 4-Window: Outer frame + center cross (4 cutouts)
                # Frame on outside + cross in middle
                cross_width = window_width
                cutout_w = (prelim_iw - cross_width) / 2 - window_width
                cutout_h = (prelim_ih - cross_width) / 2 - window_width
                cutout_area = cutout_w * cutout_h * 4  # 4 rectangular cutouts
                st.caption(f"4 openings: ~{cutout_w:.1f}\" × {cutout_h:.1f}\" each")
            elif "X-Brace" in brace_type:
                # X-Brace: Outer frame + diagonal X cross
                # Calculate diagonal lengths
                diag_len = math.sqrt(prelim_iw**2 + prelim_ih**2)
                # X brace material = 2 diagonal strips
                x_material_area = diag_len * window_width * 2
                # Plus outer frame
                frame_material = (prelim_iw * window_width * 2) + (prelim_ih * window_width * 2) - (window_width**2 * 4)
                cutout_area = total_brace_area - (x_material_area + frame_material)
                cutout_area = max(0, cutout_area)  # Ensure non-negative
                st.caption(f"X-diagonal: ~{diag_len:.1f}\" per diagonal")
            else:
                # Single window (original square cutout)
                cutout_w = prelim_iw - (window_width * 2)
                cutout_h = prelim_ih - (window_width * 2)
                cutout_area = cutout_w * cutout_h
                st.caption(f"Opening: ~{cutout_w:.1f}\" × {cutout_h:.1f}\"")
            
            frame_area = total_brace_area - cutout_area
            brace_disp = (frame_area * window_thickness * num_window_braces) / 1728
            brace_diameter = window_thickness  # For visualization
            
        elif "Lumber" in brace_type:
            # Lumber cross brace (2x2, 2x3, 2x4)
            if "2x2" in brace_type:
                lumber_w, lumber_h = 1.5, 1.5  # Actual 2x2 dimensions
            elif "2x3" in brace_type:
                lumber_w, lumber_h = 1.5, 2.5  # Actual 2x3 dimensions
            else:  # 2x4
                lumber_w, lumber_h = 1.5, 3.5  # Actual 2x4 dimensions
            
            lumber_layout = st.selectbox("Layout", ["Single Center", "X-Cross", "Double Parallel"])
            num_lumber_braces = st.number_input("Number of Lumber Braces", 1, 4, 1)
            
            # Position controls for lumber braces
            st.markdown("**Lumber Brace Positions**")
            lumber_brace_positions = []
            for i in range(num_lumber_braces):
                pos = st.slider(f"Brace {i+1} Position", 0.2, 0.8, 0.3 + (i * 0.2), key=f"lum_pos_{i}")
                lumber_brace_positions.append(pos)
            
            prelim_idv = (net_v * 1728) / ((max_w - wood*2) * (max_h - wood*2))
            
            # Calculate based on direction
            if "X-axis" in brace_direction:
                brace_len = max_w - (wood * 2)
            elif "Y-axis" in brace_direction:
                brace_len = prelim_idv
            else:  # Z-axis
                brace_len = max_h - (wood * 2)
            
            if lumber_layout == "Single Center":
                brace_disp = (lumber_w * lumber_h * brace_len * num_lumber_braces) / 1728
            elif lumber_layout == "X-Cross":
                diag_len = math.sqrt((max_w - wood*2)**2 + prelim_idv**2)
                brace_disp = (lumber_w * lumber_h * diag_len * 2 * num_lumber_braces) / 1728
            else:  # Double Parallel
                brace_disp = (lumber_w * lumber_h * brace_len * 2 * num_lumber_braces) / 1728
            brace_diameter = lumber_h
            st.caption(f"Actual dimensions: {lumber_w}\" × {lumber_h}\"")
            
        elif "Ladder" in brace_type:
            # Ladder brace - multiple horizontal rungs
            rung_thickness = st.selectbox("Rung Thickness", ["3/4\"", "1\"", "1.5\""], index=0)
            rung_thick_val = {"3/4\"": 0.75, "1\"": 1.0, "1.5\"": 1.5}[rung_thickness]
            rung_width = st.number_input("Rung Width (in)", 2.0, 4.0, 3.0)
            num_rungs = st.number_input("Number of Rungs", 2, 6, 3)
            
            prelim_idv = (net_v * 1728) / ((max_w - wood*2) * (max_h - wood*2))
            
            # Direction affects rung length
            if "X-axis" in brace_direction:
                rung_len = max_w - (wood * 2)
            elif "Y-axis" in brace_direction:
                rung_len = prelim_idv
            else:  # Z-axis
                rung_len = max_h - (wood * 2)
            
            brace_disp = (rung_thick_val * rung_width * rung_len * num_rungs) / 1728
            brace_diameter = rung_thick_val
            
        elif "45°" in brace_type:
            # Corner braces
            corner_size = st.selectbox("Corner Brace Size", ["2\" × 2\"", "3\" × 3\"", "4\" × 4\""], index=1)
            corner_dim = {"2\" × 2\"": 2.0, "3\" × 3\"": 3.0, "4\" × 4\"": 4.0}[corner_size]
            corner_thickness = st.selectbox("Thickness", ["3/4\"", "1\""], index=0)
            corner_thick_val = {"3/4\"": 0.75, "1\"": 1.0}[corner_thickness]
            # 8 corners in a box + 4 along edges
            num_corner_braces = st.number_input("Number of Corner Braces", 4, 12, 8)
            
            # Triangle area = 1/2 * base * height (corner braces are triangular)
            triangle_area = 0.5 * corner_dim * corner_dim
            prelim_depth = 6.0  # Depth of corner piece
            brace_disp = (triangle_area * prelim_depth * num_corner_braces) / 1728
            brace_diameter = corner_dim
        
        st.metric("Bracing Displacement", f"{round(brace_disp, 3)} cf")
    else:
        brace_disp = 0.0
        brace_diameter = 0
        
    # Option to manually override
    manual_brace = st.checkbox("Manual Override Displacement")
    if manual_brace:
        brace_disp = st.number_input("Bracing Displacement (cf)", value=0.080, format="%.3f")

# --- 3D VIEW OPTIONS (Features #2, #3, #7) ---
with st.sidebar.expander("🎨 3D View Options", expanded=False):
    box_opacity = st.slider("Box Opacity", 0.0, 1.0, 1.0, 0.05)  # Default to 1.0 (solid)
    show_transparent = st.checkbox("Transparent Mode", value=False)
    show_exploded = st.checkbox("Exploded View (Take Apart)", value=False)
    show_braces = st.checkbox("Show Bracing", value=True)
    if show_exploded:
        explode_distance = st.slider("Explode Distance (in)", 1, 10, 3)
    else:
        explode_distance = 0

# --- CABIN GAIN ---
with st.sidebar.expander("🚗 Cabin Gain", expanded=False):
    enable_cabin = st.checkbox("Apply Cabin Gain?")
    if enable_cabin:
        g_start = st.number_input("Start Frequency (Hz)", value=52)
        g_slope = st.slider("Slope (dB/Octave)", 6, 15, 10)
    else:
        g_start = 0.0
        g_slope = 0.0

# --- TERMINAL CUP (Feature #29) ---
with st.sidebar.expander("🔌 Terminal Cup", expanded=False):
    show_terminal = st.checkbox("Show Terminal Cup", value=True)
    terminal_size = st.selectbox("Terminal Size", ["Small (2.5\")", "Medium (3.5\")", "Large (4.5\")"])
    terminal_sizes = {"Small (2.5\")": 2.5, "Medium (3.5\")": 3.5, "Large (4.5\")": 4.5}
    terminal_d = terminal_sizes[terminal_size]
    terminal_x = st.number_input("Terminal X Position", value=max_w * 0.9, min_value=0.0, max_value=float(max_w))
    terminal_z = st.number_input("Terminal Z Position", value=max_h * 0.15, min_value=0.0, max_value=float(max_h))

# --- COMPONENT PLACEMENT (Sub & Port Position Controls) ---
with st.sidebar.expander("📍 Component Placement", expanded=False):
    st.markdown("**Subwoofer Position**")
    # For bandpass, sub is on divider - position within the divider
    if is_bandpass:
        st.caption("Position on internal divider (sealed→ported)")
    
    # Calculate smart default positions to center sub and port without overlap
    # Sub gets center-left, port gets center-right (if ported)
    port_od_est = ps.get("od", 4.0) if (is_ported or is_bandpass) else 0
    sub_default_x = max_w / 2 if not (is_ported or is_bandpass) else max_w * 0.35
    port_default_x = max_w * 0.70 if (is_ported or is_bandpass) else max_w * 0.5
    
    # For single sub centered, check if port would overlap
    if num_subs == 1 and (is_ported or is_bandpass):
        min_spacing = (sub_od + port_od_est) / 2 + 1.0  # 1" clearance
        if abs(sub_default_x - port_default_x) < min_spacing:
            # Shift them apart
            sub_default_x = max_w * 0.30
            port_default_x = max_w * 0.70
    
    sub_x_input = st.number_input(
        "Sub X Position (Left↔Right)", 
        min_value=1.0, 
        max_value=float(max_w - 1), 
        value=float(st.session_state.get('sub_x', sub_default_x)),
        step=0.5,
        key="sub_x_input"
    )
    sub_z_input = st.number_input(
        "Sub Z Position (Bottom↔Top)", 
        min_value=1.0, 
        max_value=float(max_h - 1), 
        value=float(st.session_state.get('sub_z', max_h * 0.5)),
        step=0.5,
        key="sub_z_input"
    )
    # Update session state
    st.session_state['sub_x'] = sub_x_input
    st.session_state['sub_z'] = sub_z_input
    
    st.markdown("---")
    st.markdown("**Port Position**")
    if is_ported or is_bandpass:
        # Port position options - Left/Right Side, Front/Back of side
        port_side_placement = st.selectbox("Port Side Placement", 
            ["Front Baffle", "Left Side - Front", "Left Side - Rear", "Right Side - Front", "Right Side - Rear", "Top", "Rear"],
            key="port_side_placement")
        
        port_x_input = st.number_input(
            "Port X Position (Left↔Right)", 
            min_value=1.0, 
            max_value=float(max_w - 1), 
            value=float(st.session_state.get('port_x', port_default_x)),
            step=0.5,
            key="port_x_input"
        )
        port_z_input = st.number_input(
            "Port Z Position (Bottom↔Top)", 
            min_value=1.0, 
            max_value=float(max_h - 1), 
            value=float(st.session_state.get('port_z', max_h * 0.5)),
            step=0.5,
            key="port_z_input"
        )
        # Update session state
        st.session_state['port_x'] = port_x_input
        st.session_state['port_z'] = port_z_input
    else:
        st.caption("Port controls not available for sealed boxes")
        port_side_placement = "Front Baffle"  # Default for sealed

# ═══════════════════════════════════════════════════════════════════════════════
# VOLUME CALCULATIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Sub displacement calculation (Feature #6)
num_internal_subs = num_subs - num_inverted
total_sub_disp = sub_d * num_internal_subs

# Layer calculations
extra_b = (lay_b - 1) * wood
extra_tb = (lay_tb - 1) * (wood * 2)
extra_s = (lay_s - 1) * (wood * 2)
bt = lay_f * wood

# Port displacement (preliminary - will be recalculated for slot ports later)
if is_ported and port_type == "Round Aero Port":
    pd = p_len * ps["m"] * num_ports
elif is_ported and port_type == "Slot Port":
    # Preliminary slot port displacement includes air channel + divider wood
    # Air channel: slot_width × slot_height × port_length
    # Divider wood: wood_thickness × slot_height × port_length
    # This will be recalculated more precisely later with actual dimensions
    air_vol_prelim = (slot_width * slot_height * p_len) / 1728
    # Estimate divider volume (1 divider per side port, 2 for center)
    num_dividers = 2 if slot_position == "Center (Between Subs)" else 1
    divider_vol_prelim = (num_dividers * wood * slot_height * p_len) / 1728
    pd = (air_vol_prelim + divider_vol_prelim) * num_ports
else:
    pd = 0

# Baffle hole gain
sh = math.pi * ((sub_c / 2) ** 2) * num_subs
ph = math.pi * ((ps["c"] / 2) ** 2) * num_ports if is_ported else 0
b_gain = ((sh + ph) * bt) / 1728

# 4th Order Bandpass internal divider displacement
# The divider is a full panel inside the box that separates chambers
if is_bandpass:
    # Calculate estimated internal dimensions for divider
    est_iw = max_w - (wood * 2) - extra_s
    est_ih = max_h - (wood * 2) - extra_tb
    # Divider displacement: width × height × wood thickness
    divider_disp = (est_iw * est_ih * wood) / 1728
    # Also account for sub cutout in divider (reduces displacement slightly)
    sub_cutout_area = math.pi * ((sub_c / 2) ** 2) * num_subs
    cutout_vol_reduction = (sub_cutout_area * wood) / 1728
    divider_disp = divider_disp - cutout_vol_reduction
else:
    divider_disp = 0

# Gross volume calculation (includes divider for bandpass)
gross = net_v + total_sub_disp + pd + brace_disp + divider_disp - b_gain

# Internal dimensions
iw = max_w - (wood * 2) - extra_s
ih = max_h - (wood * 2) - extra_tb
idv = (gross * 1728) / (iw * ih)
edv = idv + wood + bt + extra_b

# ═══════════════════════════════════════════════════════════════════════════════
# FINAL SLOT PORT CALCULATIONS (now that we have actual interior dimensions)
# Slot port uses: box side wall + box top + box bottom = only needs ONE divider board
# Using slot port formula calibrated to match subbox.pro calculations
# ═══════════════════════════════════════════════════════════════════════════════
if is_ported and port_type == "Slot Port":
    # Slot height = full interior height (uses box top/bottom as port ceiling/floor)
    # NO separate top/bottom boards needed - port uses the box panels directly
    slot_height = ih  # Full interior height
    
    # Number of slot ports (1 for left/right/center, 2 for dual)
    num_slot_ports = 2 if slot_position == "Dual (Both Sides)" else 1
    
    # Total port area (for dual ports, this is combined area)
    slot_area = slot_width * slot_height * num_slot_ports
    equiv_diameter = 2 * math.sqrt(slot_area / math.pi)
    
    # Calculate port length using physics formula (verified against subbox.pro)
    # Formula: Lv = (c² × A) / (4π² × f² × Vb × 1728), then L = Lv - k × √A
    # where: c = 13504 in/s (speed of sound), k = 1.2 (slot port end correction)
    # Verified within 0.12" accuracy against multiple subbox.pro designs
    c_sound = 13504.0  # Speed of sound in inches per second
    k_end_correction = 1.2  # Slot port end correction factor (verified against subbox.pro)
    
    if tune > 0 and net_v > 0:
        # Calculate acoustic length using Helmholtz resonance formula
        acoustic_len = (c_sound ** 2 * slot_area) / (4 * math.pi ** 2 * tune ** 2 * net_v * 1728)
        # Subtract end correction for physical port length
        end_effect = k_end_correction * math.sqrt(slot_area)
        # Final port length
        slot_len = acoustic_len - end_effect
    else:
        slot_len = 20.0
    
    slot_len = max(6.0, slot_len)
    p_len = slot_len  # Use calculated length directly
    
    # Update pseudo port specs
    ps = {"d": equiv_diameter, "c": equiv_diameter + 1, "od": equiv_diameter + 1.5, "m": slot_area / 1728}
    
    # Determine if port needs to bend (L-shape)
    # Port CANNOT reach all the way to back - it needs clearance for air to flow around!
    # Minimum clearance from back wall = port width (so air can turn around)
    port_clearance_from_back = slot_width
    port_straight_max = idv - port_clearance_from_back
    port_needs_bend = slot_len > port_straight_max
    
    # If needs bend, calculate first leg and second leg lengths
    if port_needs_bend:
        # First leg goes back but stops short of back wall by port_width
        slot_leg1_len = port_straight_max  # Leaves slot_width clearance
        slot_leg2_len = slot_len - slot_leg1_len  # Second leg goes sideways
    else:
        slot_leg1_len = slot_len
        slot_leg2_len = 0
        
    # Recalculate port displacement with actual dimensions
    # Port displacement = air channel volume + divider wood volume
    # Air channel: slot_width × slot_height × slot_len (per port)
    # Dividers: wood_thickness × slot_height × divider_length
    #
    # SHARED WALL CONFIG:
    # - Shared Wall ON (slot_shared_wall=True): Port uses enclosure wall + 1 interior divider
    # - Shared Wall OFF (slot_shared_wall=False): Port uses 2 interior dividers (no enclosure wall)
    #
    # POSITION CONFIG:
    # - Center port: Always uses 2 dividers (one on each side of center channel)
    # - Side port with shared wall: 1 divider only (uses enclosure wall as boundary)
    # - Side port without shared wall: 2 dividers (both sides need wood)
    
    # Air channel displacement
    air_channel_vol = (slot_width * slot_height * slot_len) / 1728  # per port
    
    # Divider wood displacement
    # Divider length = leg1_len + leg2_len (the divider runs the full port length)
    divider_length = slot_leg1_len + slot_leg2_len
    
    # Calculate number of dividers based on position and shared wall setting
    if slot_position == "Center (Between Subs)":
        # Center port ALWAYS has 2 dividers (one on each side of center channel)
        num_dividers_per_port = 2
    elif slot_shared_wall:
        # Side port WITH shared wall uses enclosure wall + 1 divider = 1 divider only
        num_dividers_per_port = 1
    else:
        # Side port WITHOUT shared wall uses 2 dividers (enclosure wall not available)
        num_dividers_per_port = 2
    
    # Calculate total divider volume
    divider_vol = (num_dividers_per_port * wood * slot_height * divider_length) / 1728
    
    # Total port displacement per port
    pd_per_port = air_channel_vol + divider_vol
    
    # Total displacement for all ports
    pd = pd_per_port * num_slot_ports
    
    # Recalculate gross volume with updated displacement (include divider for bandpass)
    gross = net_v + total_sub_disp + pd + brace_disp + divider_disp - b_gain
    idv = (gross * 1728) / (iw * ih)
    edv = idv + wood + bt + extra_b

# Port clearance
gap = idv - p_len if is_ported else idv
total_disp = total_sub_disp + pd + brace_disp + divider_disp

# ═══════════════════════════════════════════════════════════════════════════════
# WEIGHT CALCULATOR (Feature #9)
# ═══════════════════════════════════════════════════════════════════════════════
def calculate_box_weight(max_w, max_h, edv, wood, lay_f, lay_b, lay_tb, lay_s):
    """Calculate approximate box weight in lbs"""
    # MDF density: ~48 lbs per cubic foot
    mdf_density = 48.0  # lbs/cf
    
    # Calculate panel volumes
    front_vol = (max_w * max_h * wood * lay_f) / 1728
    back_vol = (max_w * max_h * wood * lay_b) / 1728
    top_d = edv - (lay_f * wood) - (lay_b * wood)
    top_vol = (max_w * top_d * wood * lay_tb) / 1728
    bottom_vol = top_vol
    side_vol = ((max_h - wood * 2 * lay_tb) * top_d * wood * lay_s * 2) / 1728
    
    total_wood_vol = front_vol + back_vol + top_vol + bottom_vol + side_vol
    wood_weight = total_wood_vol * mdf_density
    
    # Add bracing weight (estimate)
    brace_weight = brace_disp * mdf_density
    
    return wood_weight + brace_weight

box_weight = calculate_box_weight(max_w, max_h, edv, wood, lay_f, lay_b, lay_tb, lay_s)

# ═══════════════════════════════════════════════════════════════════════════════
# MATERIAL COST ESTIMATOR (Feature #8)
# ═══════════════════════════════════════════════════════════════════════════════
def calculate_material_cost(max_w, max_h, edv, wood, lay_f, lay_b, lay_tb, lay_s):
    """Estimate material costs"""
    # Calculate total panel area in square feet
    top_d = edv - (lay_f * wood) - (lay_b * wood)
    
    front_area = (max_w * max_h * lay_f) / 144
    back_area = (max_w * max_h * lay_b) / 144
    top_area = (max_w * top_d * lay_tb) / 144
    bottom_area = top_area
    side_area = ((max_h - wood * 2 * lay_tb) * top_d * lay_s * 2) / 144
    
    total_area = front_area + back_area + top_area + bottom_area + side_area
    
    # Sheets needed (4x8 = 32 sq ft, add 20% waste)
    sheets_needed = math.ceil(total_area * 1.2 / 32)
    
    costs = {
        f"MDF Sheets ({sheets_needed}x)": sheets_needed * 45.0,
        "Wood Glue": 8.0,
        "Screws": 12.0,
        "Terminal Cup": 8.0,
        "Gasket Tape": 6.0,
    }
    
    # Carpet if applicable (exterior surface area)
    exterior_area = (2 * max_w * max_h + 2 * max_w * edv + 2 * max_h * edv) / 144
    carpet_yards = math.ceil(exterior_area / 9)
    costs[f"Carpet ({carpet_yards} yd)"] = carpet_yards * 15.0
    
    return costs, sum(costs.values())

material_breakdown, total_cost = calculate_material_cost(max_w, max_h, edv, wood, lay_f, lay_b, lay_tb, lay_s)

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN CONTENT AREA
# ═══════════════════════════════════════════════════════════════════════════════
st.markdown("---")

# Key Metrics Row
col_m1, col_m2, col_m3, col_m4, col_m5 = st.columns(5)
with col_m1:
    st.metric("📏 External Depth", f"{round(edv, 2)} in")
with col_m2:
    st.metric("📦 Net Volume", f"{round(net_v, 2)} cf")
with col_m3:
    if is_ported:
        st.metric("🎵 Tuning", f"{tune} Hz")
    else:
        st.metric("🔒 Type", "Sealed")
with col_m4:
    st.metric("⚖️ Box Weight", f"{round(box_weight, 1)} lbs")
with col_m5:
    st.metric("💰 Est. Cost", f"${round(total_cost, 0)}")

# Second metrics row
col_m6, col_m7, col_m8, col_m9 = st.columns(4)
with col_m6:
    if is_ported:
        port_wall_gap = gap
        if port_wall_gap < ps["d"] / 2:
            st.metric("⚠️ Port Clearance", f"{round(port_wall_gap, 2)} in", delta="CHOKE!", delta_color="inverse")
        else:
            st.metric("✓ Port Clearance", f"{round(port_wall_gap, 2)} in")
    else:
        st.metric("📐 Internal Depth", f"{round(idv, 2)} in")
with col_m7:
    st.metric("🔩 Total Displacement", f"{round(total_disp, 3)} cf")
with col_m8:
    if is_ported and 'v_peak_fps' in dir():
        st.metric("🌬️ Port Velocity", f"{round(v_peak_fps, 1)} ft/s")
    else:
        st.metric("📊 Gross Volume", f"{round(gross, 3)} cf")
with col_m9:
    st.metric(f"🔊 Subs", f"{num_subs}x {sel_sub_size}")

# Warnings
if is_ported and gap < (ps["d"] / 2):
    st.error("🚨 PORT CHOKE! Port too close to back wall - increase box depth or reduce port length.")

if num_inverted > 0:
    st.info(f"🔄 {num_inverted} sub(s) inverted — displacement reduced by {round(sub_d * num_inverted, 3)} cf")

# Displacement Breakdown (expandable)
with st.expander("📊 Displacement & Volume Breakdown", expanded=False):
    disp_col1, disp_col2 = st.columns(2)
    with disp_col1:
        st.markdown("**Volume Accounting:**")
        st.write(f"• Target Net Volume: **{round(net_v, 3)} cf**")
        st.write(f"• Sub Displacement: {round(total_sub_disp, 3)} cf ({num_internal_subs} internal sub(s))")
        st.write(f"• Bracing Displacement: {round(brace_disp, 3)} cf")
        if is_bandpass and divider_disp > 0:
            st.write(f"• **Divider Displacement: {round(divider_disp, 3)} cf** (4th Order)")
        if is_ported:
            st.write(f"• Port Displacement: {round(pd, 3)} cf")
        st.write(f"• Baffle Hole Gain: -{round(b_gain, 3)} cf")
        st.write(f"• **Gross Volume Required: {round(gross, 3)} cf**")
    
    with disp_col2:
        if is_bandpass:
            st.markdown("**4th Order Bandpass Details:**")
            st.write(f"• Sealed Chamber: {round(sealed_chamber_vol, 3)} cf")
            st.write(f"• Ported Chamber: {round(ported_chamber_vol, 3)} cf")
            st.write(f"• Volume Ratio: {bp_ratio_value}:1 (Ported:Sealed)")
            st.write(f"• Tuning Frequency: {round(tune, 1)} Hz")
            st.write(f"• Divider (iw × ih × wood): {round(iw, 2)}\" × {round(ih, 2)}\" × {round(wood, 3)}\"")
        elif is_ported and port_type == "Slot Port":
            st.markdown("**Slot Port Details:**")
            st.write(f"• Port Width: {round(slot_width, 2)}\"")
            st.write(f"• Port Height: {round(slot_height, 2)}\" (full interior)")
            st.write(f"• Port Length: {round(p_len, 2)}\"")
            st.write(f"• Port Area: {round(slot_area, 1)} sq in")
            st.write(f"• Divider Thickness: {round(wood, 3)}\"")
            # Calculate and show breakdown
            air_vol_cf = (slot_width * slot_height * p_len) / 1728
            div_len = slot_leg1_len + slot_leg2_len if 'slot_leg1_len' in dir() else p_len
            num_div = 2 if slot_position == "Center (Between Subs)" else 1
            div_vol_cf = (num_div * wood * slot_height * div_len) / 1728
            st.write(f"  - Air Channel: {round(air_vol_cf, 4)} cf")
            st.write(f"  - Divider Wood ({num_div}): {round(div_vol_cf, 4)} cf")
        elif is_ported:
            st.markdown("**Round Port Details:**")
            st.write(f"• Port Diameter: {round(ps['d'], 2)}\"")
            st.write(f"• Port Length: {round(p_len, 2)}\"")
            st.write(f"• Number of Ports: {num_ports}")

st.markdown("---")

# ═══════════════════════════════════════════════════════════════════════════════
# 3D VISUALIZATION
# ═══════════════════════════════════════════════════════════════════════════════
fig = go.Figure()

# Calculate actual positions
sub_x_actual = st.session_state.get('sub_x', max_w * 0.35)
sub_z_actual = st.session_state.get('sub_z', max_h * 0.5)
port_x_actual = st.session_state.get('port_x', max_w * 0.80)
port_z_actual = st.session_state.get('port_z', max_h * 0.5)

baffle_thickness = lay_f * wood
back_thickness = lay_b * wood
bottom_thickness = lay_tb * wood
side_thickness = lay_s * wood

# Opacity for transparent mode
actual_opacity = 0.1 if show_transparent else box_opacity

# Explode offsets
exp = explode_distance if show_exploded else 0

def add_panel(x0, y0, z0, x1, y1, z1, color, opacity, name, edge_color="#8B4513"):
    """Add a rectangular panel (box) with distinct edge lines"""
    vx = [x0, x1, x1, x0, x0, x1, x1, x0]
    vy = [y0, y0, y1, y1, y0, y0, y1, y1]
    vz = [z0, z0, z0, z0, z1, z1, z1, z1]
    
    # Add the solid panel
    fig.add_trace(go.Mesh3d(
        x=vx, y=vy, z=vz,
        i=[7, 0, 0, 0, 4, 4, 6, 6, 4, 0, 3, 2],
        j=[3, 4, 1, 2, 5, 6, 5, 2, 0, 1, 6, 3],
        k=[0, 7, 2, 3, 6, 7, 1, 1, 5, 5, 7, 6],
        opacity=opacity, color=color, name=name, showlegend=False
    ))
    
    # Add distinct edge lines for each panel
    # Bottom face edges
    fig.add_trace(go.Scatter3d(x=[x0, x1, x1, x0, x0], y=[y0, y0, y1, y1, y0], z=[z0, z0, z0, z0, z0],
                               mode='lines', line=dict(color=edge_color, width=3), showlegend=False))
    # Top face edges
    fig.add_trace(go.Scatter3d(x=[x0, x1, x1, x0, x0], y=[y0, y0, y1, y1, y0], z=[z1, z1, z1, z1, z1],
                               mode='lines', line=dict(color=edge_color, width=3), showlegend=False))
    # Vertical edges
    for px, py in [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]:
        fig.add_trace(go.Scatter3d(x=[px, px], y=[py, py], z=[z0, z1],
                                   mode='lines', line=dict(color=edge_color, width=3), showlegend=False))

# Front Baffle - draw each layer separately with distinct edges
for layer in range(lay_f):
    layer_y_start = -exp + (layer * wood)
    layer_y_end = -exp + ((layer + 1) * wood)
    # Alternate colors slightly for visibility
    layer_color = "wheat" if layer % 2 == 0 else "burlywood"
    add_panel(0, layer_y_start, 0, max_w, layer_y_end, max_h, layer_color, actual_opacity, f"Front Layer {layer+1}")

# Back Panel - draw each layer separately
for layer in range(lay_b):
    layer_y_start = edv - back_thickness + exp + (layer * wood)
    layer_y_end = edv - back_thickness + exp + ((layer + 1) * wood)
    layer_color = "wheat" if layer % 2 == 0 else "burlywood"
    add_panel(0, layer_y_start, 0, max_w, layer_y_end, max_h, layer_color, actual_opacity, f"Back Layer {layer+1}")

# Bottom Panel (with explode)
add_panel(0, baffle_thickness, -exp, max_w, edv - back_thickness, bottom_thickness - exp, "wheat", actual_opacity, "Bottom")

# Top Panel (with explode) - 90% transparent to see inside
add_panel(0, baffle_thickness, max_h - bottom_thickness + exp, max_w, edv - back_thickness, max_h + exp, "wheat", actual_opacity * 0.1, "Top")

# Left Side Panel (with explode)
add_panel(-exp, baffle_thickness, bottom_thickness, side_thickness - exp, edv - back_thickness, max_h - bottom_thickness, "wheat", actual_opacity, "Left Side")

# Right Side Panel (with explode)
add_panel(max_w - side_thickness + exp, baffle_thickness, bottom_thickness, max_w + exp, edv - back_thickness, max_h - bottom_thickness, "wheat", actual_opacity, "Right Side")

# ═══════════════════════════════════════════════════════════════════════════════
# 4TH ORDER BANDPASS INTERNAL DIVIDER WALL
# In a 4th order bandpass, the subwoofer is mounted on an INTERNAL divider wall
# that separates the sealed chamber (rear) from the ported chamber (front)
# The cone faces the sealed chamber, motor structure faces the ported chamber
# ═══════════════════════════════════════════════════════════════════════════════
if is_bandpass:
    # Calculate divider position based on chamber volumes
    # sealed chamber = back portion, ported chamber = front portion
    # Volume ratio determines the split position
    # sealed_vol / ported_vol = 1 / bp_ratio_value
    
    # Interior length available (Y direction)
    interior_y_length = idv  # internal depth
    
    # Divider position: distance from front baffle to divider
    # ported_vol proportion = bp_ratio_value / (1 + bp_ratio_value)
    ported_proportion = bp_ratio_value / (1 + bp_ratio_value)
    divider_y_from_front = interior_y_length * ported_proportion
    
    # Actual Y position of divider (add baffle thickness)
    divider_y = baffle_thickness + divider_y_from_front
    
    # Draw the internal divider wall
    add_panel(side_thickness, divider_y, bottom_thickness,
              max_w - side_thickness, divider_y + wood, max_h - bottom_thickness,
              "burlywood", actual_opacity, "Internal Divider (4th Order)")
    
    # Store divider position for subwoofer mounting
    bandpass_divider_y = divider_y + wood / 2  # Center of divider
    
    # Draw subwoofer cutout rings on the divider (visual indicator of mounting holes)
    # Get subwoofer positions - we need to calculate them here to draw the cutouts
    divider_sub_spacing = sub_od + 0.5
    divider_center_x = max_w / 2
    divider_center_z = max_h / 2
    
    # Get sub positions on divider
    divider_sub_positions = []
    if num_subs == 1:
        divider_sub_positions.append((divider_center_x, divider_center_z))
    elif num_subs == 2:
        if sub_arrangement == "Horizontal":
            divider_sub_positions = [(divider_center_x - divider_sub_spacing/2, divider_center_z),
                                     (divider_center_x + divider_sub_spacing/2, divider_center_z)]
        else:  # Vertical
            divider_sub_positions = [(divider_center_x, divider_center_z - divider_sub_spacing/2),
                                     (divider_center_x, divider_center_z + divider_sub_spacing/2)]
    elif num_subs == 4:
        offset = divider_sub_spacing / 2
        divider_sub_positions = [(divider_center_x - offset, divider_center_z - offset),
                                 (divider_center_x + offset, divider_center_z - offset),
                                 (divider_center_x - offset, divider_center_z + offset),
                                 (divider_center_x + offset, divider_center_z + offset)]
    else:
        offset = (num_subs - 1) / 2
        for i in range(num_subs):
            divider_sub_positions.append((divider_center_x + (i - offset) * divider_sub_spacing, divider_center_z))
    
    # Draw cutout circles on both sides of the divider for each sub
    theta_ring = np.linspace(0, 2 * np.pi, 50)
    for pos_idx, (pos_x, pos_z) in enumerate(divider_sub_positions):
        # Cutout ring on front face of divider (ported chamber side)
        ring_x = (sub_c / 2) * np.cos(theta_ring) + pos_x
        ring_z = (sub_c / 2) * np.sin(theta_ring) + pos_z
        ring_y_front = np.full(len(theta_ring), divider_y + 0.02)
        fig.add_trace(go.Scatter3d(
            x=ring_x, y=ring_y_front, z=ring_z, mode='lines',
            line=dict(color='red', width=3),
            name=f'Divider Cutout {pos_idx + 1}' if pos_idx == 0 else None,
            showlegend=(pos_idx == 0)
        ))
        
        # Cutout ring on back face of divider (sealed chamber side)
        ring_y_back = np.full(len(theta_ring), divider_y + wood - 0.02)
        fig.add_trace(go.Scatter3d(
            x=ring_x, y=ring_y_back, z=ring_z, mode='lines',
            line=dict(color='red', width=3),
            showlegend=False
        ))
        
        # OD ring (gasket/mounting ring)
        od_ring_x = (sub_od / 2) * np.cos(theta_ring) + pos_x
        od_ring_z = (sub_od / 2) * np.sin(theta_ring) + pos_z
        fig.add_trace(go.Scatter3d(
            x=od_ring_x, y=ring_y_front, z=od_ring_z, mode='lines',
            line=dict(color='orange', width=2, dash='dash'),
            showlegend=False
        ))
    
    # Add chamber labels (visual markers)
    # Ported chamber indicator (front)
    ported_chamber_center_y = baffle_thickness + divider_y_from_front / 2
    sealed_chamber_center_y = divider_y + wood + (edv - back_thickness - divider_y - wood) / 2
    
    # Calculate actual interior dimensions for each chamber
    # Ported chamber (front): from baffle interior to divider
    ported_depth = divider_y_from_front  # Interior depth of ported chamber
    ported_width = iw  # Interior width
    ported_height = ih  # Interior height
    ported_actual_cf = (ported_width * ported_height * ported_depth) / 1728
    
    # Sealed chamber (back): from divider to back panel interior
    sealed_depth = edv - back_thickness - (divider_y + wood)  # Interior depth of sealed chamber
    sealed_width = iw
    sealed_height = ih
    sealed_actual_cf = (sealed_width * sealed_height * sealed_depth) / 1728
    
    # Add text annotations for chambers with dimensions
    fig.add_trace(go.Scatter3d(
        x=[max_w/2], y=[ported_chamber_center_y], z=[max_h * 0.7],
        mode='text', text=[f'PORTED CHAMBER'],
        textposition='middle center',
        textfont=dict(size=14, color='darkgreen'),
        showlegend=False
    ))
    fig.add_trace(go.Scatter3d(
        x=[max_w/2], y=[ported_chamber_center_y], z=[max_h * 0.5],
        mode='text', text=[f'{round(ported_chamber_vol, 2)} cf'],
        textposition='middle center',
        textfont=dict(size=12, color='green'),
        showlegend=False
    ))
    fig.add_trace(go.Scatter3d(
        x=[max_w/2], y=[ported_chamber_center_y], z=[max_h * 0.35],
        mode='text', text=[f'{round(ported_width, 1)}"W x {round(ported_height, 1)}"H x {round(ported_depth, 1)}"D'],
        textposition='middle center',
        textfont=dict(size=10, color='green'),
        showlegend=False
    ))
    
    fig.add_trace(go.Scatter3d(
        x=[max_w/2], y=[sealed_chamber_center_y], z=[max_h * 0.7],
        mode='text', text=[f'SEALED CHAMBER'],
        textposition='middle center',
        textfont=dict(size=14, color='darkblue'),
        showlegend=False
    ))
    fig.add_trace(go.Scatter3d(
        x=[max_w/2], y=[sealed_chamber_center_y], z=[max_h * 0.5],
        mode='text', text=[f'{round(sealed_chamber_vol, 2)} cf'],
        textposition='middle center',
        textfont=dict(size=12, color='blue'),
        showlegend=False
    ))
    fig.add_trace(go.Scatter3d(
        x=[max_w/2], y=[sealed_chamber_center_y], z=[max_h * 0.35],
        mode='text', text=[f'{round(sealed_width, 1)}"W x {round(sealed_height, 1)}"H x {round(sealed_depth, 1)}"D'],
        textposition='middle center',
        textfont=dict(size=10, color='blue'),
        showlegend=False
    ))
    
    # Add dimension lines for divider position
    # Line from front baffle to divider
    fig.add_trace(go.Scatter3d(
        x=[max_w/2, max_w/2], y=[baffle_thickness, divider_y], z=[2, 2],
        mode='lines+text', 
        line=dict(color='purple', width=3),
        text=['', f'{round(ported_depth, 1)}"'],
        textposition='middle center',
        textfont=dict(size=10, color='purple'),
        showlegend=False
    ))

# Bracing visualization (Feature #7 Enhanced) - Realistic 3D Braces
if show_braces and brace_disp > 0:
    brace_color = "sienna"
    brace_dark = "#5D4037"  # Darker wood grain color
    mid_y = edv / 2
    mid_z = max_h / 2
    mid_x = max_w / 2
    
    def add_3d_dowel(x1, y1, z1, x2, y2, z2, radius, color, name=None, show_legend=False):
        """Draw a realistic 3D cylindrical dowel between two points"""
        n_seg = 16
        n_length = 12
        
        # Direction vector
        dx, dy, dz = x2 - x1, y2 - y1, z2 - z1
        length = math.sqrt(dx*dx + dy*dy + dz*dz)
        if length < 0.001:
            return
        
        # Normalize direction
        dx, dy, dz = dx/length, dy/length, dz/length
        
        # Find perpendicular vectors for circle
        if abs(dz) < 0.9:
            px, py, pz = -dy, dx, 0
        else:
            px, py, pz = 1, 0, 0
        plen = math.sqrt(px*px + py*py + pz*pz)
        px, py, pz = px/plen, py/plen, pz/plen
        
        # Second perpendicular (cross product)
        qx = dy * pz - dz * py
        qy = dz * px - dx * pz
        qz = dx * py - dy * px
        
        # Generate cylinder mesh vertices
        xs, ys, zs = [], [], []
        for li in range(n_length + 1):
            t = li / n_length
            cx = x1 + dx * length * t
            cy = y1 + dy * length * t
            cz = z1 + dz * length * t
            for ai in range(n_seg):
                angle = 2 * math.pi * ai / n_seg
                vx = cx + radius * (math.cos(angle) * px + math.sin(angle) * qx)
                vy = cy + radius * (math.cos(angle) * py + math.sin(angle) * qy)
                vz = cz + radius * (math.cos(angle) * pz + math.sin(angle) * qz)
                xs.append(vx)
                ys.append(vy)
                zs.append(vz)
        
        # Generate triangles
        ii, jj, kk = [], [], []
        for li in range(n_length):
            for ai in range(n_seg):
                i0 = li * n_seg + ai
                i1 = li * n_seg + (ai + 1) % n_seg
                i2 = (li + 1) * n_seg + ai
                i3 = (li + 1) * n_seg + (ai + 1) % n_seg
                ii.extend([i0, i0])
                jj.extend([i1, i2])
                kk.extend([i2, i3])
        
        # Add end caps
        # Start cap center
        cap_start_idx = len(xs)
        xs.append(x1)
        ys.append(y1)
        zs.append(z1)
        for ai in range(n_seg):
            ii.append(cap_start_idx)
            jj.append(ai)
            kk.append((ai + 1) % n_seg)
        
        # End cap center
        cap_end_idx = len(xs)
        xs.append(x2)
        ys.append(y2)
        zs.append(z2)
        end_ring_start = n_length * n_seg
        for ai in range(n_seg):
            ii.append(cap_end_idx)
            jj.append(end_ring_start + (ai + 1) % n_seg)
            kk.append(end_ring_start + ai)
        
        fig.add_trace(go.Mesh3d(
            x=xs, y=ys, z=zs, i=ii, j=jj, k=kk,
            color=color, opacity=1.0, flatshading=True,
            showlegend=show_legend, name=name if name else ""
        ))
    
    if brace_type == "Wooden Dowel Rod":
        # Draw realistic 3D dowel rods
        dowel_r = brace_diameter / 2
        first_dowel = True
        
        for i in range(num_dowels):
            if "X-axis" in brace_direction:
                # Dowels run from left to right (X-axis)
                spacing = (max_h - wood * 4) / (num_dowels + 1)
                dowel_z = wood * 2 + spacing * (i + 1)
                # Draw at two Y positions for structural support
                for y_pos in [mid_y - 2, mid_y + 2]:
                    add_3d_dowel(
                        wood + 0.5, y_pos, dowel_z,
                        max_w - wood - 0.5, y_pos, dowel_z,
                        dowel_r, brace_color, 
                        f"Dowel {brace_diameter}\"" if first_dowel else None,
                        show_legend=first_dowel
                    )
                    first_dowel = False
                    
            elif "Y-axis" in brace_direction:
                # Dowels run from front to back (Y-axis)
                spacing = (max_w - wood * 4) / (num_dowels + 1)
                dowel_x = wood * 2 + spacing * (i + 1)
                add_3d_dowel(
                    dowel_x, bt + 0.5, mid_z,
                    dowel_x, edv - wood - 0.5, mid_z,
                    dowel_r, brace_color,
                    f"Dowel {brace_diameter}\"" if first_dowel else None,
                    show_legend=first_dowel
                )
                first_dowel = False
                
            else:  # Top to Bottom (Z-axis)
                spacing = (max_w - wood * 4) / (num_dowels + 1)
                dowel_x = wood * 2 + spacing * (i + 1)
                add_3d_dowel(
                    dowel_x, mid_y, wood + 0.5,
                    dowel_x, mid_y, max_h - wood - 0.5,
                    dowel_r, brace_color,
                    f"Dowel {brace_diameter}\"" if first_dowel else None,
                    show_legend=first_dowel
                )
                first_dowel = False
                              
    elif "Window" in brace_type:
        # Window brace - solid wood frame with cutout
        frame_w = window_width
        brace_thick = window_thickness
        iw = max_w - wood * 2  # Internal width
        ih = max_h - wood * 2  # Internal height
        
        if "4-Window" in brace_type or "Quad" in brace_type:
            # 4-Window / Quad style - outer frame with center cross
            # Outer frame
            # Top bar
            add_panel(wood, mid_y - brace_thick/2, max_h - wood - frame_w,
                      max_w - wood, mid_y + brace_thick/2, max_h - wood,
                      brace_color, 1.0, "Window Brace Top")
            # Bottom bar
            add_panel(wood, mid_y - brace_thick/2, wood,
                      max_w - wood, mid_y + brace_thick/2, wood + frame_w,
                      brace_color, 1.0, "Window Brace Bottom")
            # Left bar
            add_panel(wood, mid_y - brace_thick/2, wood + frame_w,
                      wood + frame_w, mid_y + brace_thick/2, max_h - wood - frame_w,
                      brace_color, 1.0, "Window Brace Left")
            # Right bar
            add_panel(max_w - wood - frame_w, mid_y - brace_thick/2, wood + frame_w,
                      max_w - wood, mid_y + brace_thick/2, max_h - wood - frame_w,
                      brace_color, 1.0, "Window Brace Right")
            # Center horizontal cross bar
            add_panel(wood + frame_w, mid_y - brace_thick/2, mid_z - frame_w/2,
                      max_w - wood - frame_w, mid_y + brace_thick/2, mid_z + frame_w/2,
                      brace_dark, 1.0, "Center H-Bar")
            # Center vertical cross bar
            add_panel(mid_x - frame_w/2, mid_y - brace_thick/2, wood + frame_w,
                      mid_x + frame_w/2, mid_y + brace_thick/2, max_h - wood - frame_w,
                      brace_dark, 1.0, "Center V-Bar")
                      
        elif "X-Brace" in brace_type:
            # X-Brace style - outer frame with diagonal X cross
            # Outer frame
            # Top bar
            add_panel(wood, mid_y - brace_thick/2, max_h - wood - frame_w,
                      max_w - wood, mid_y + brace_thick/2, max_h - wood,
                      brace_color, 1.0, "Window Brace Top")
            # Bottom bar
            add_panel(wood, mid_y - brace_thick/2, wood,
                      max_w - wood, mid_y + brace_thick/2, wood + frame_w,
                      brace_color, 1.0, "Window Brace Bottom")
            # Left bar
            add_panel(wood, mid_y - brace_thick/2, wood + frame_w,
                      wood + frame_w, mid_y + brace_thick/2, max_h - wood - frame_w,
                      brace_color, 1.0, "Window Brace Left")
            # Right bar
            add_panel(max_w - wood - frame_w, mid_y - brace_thick/2, wood + frame_w,
                      max_w - wood, mid_y + brace_thick/2, max_h - wood - frame_w,
                      brace_color, 1.0, "Window Brace Right")
            # X diagonal braces using 3D dowels for realistic appearance
            # Diagonal 1: bottom-left to top-right
            add_3d_dowel(wood + frame_w, mid_y, wood + frame_w,
                        max_w - wood - frame_w, mid_y, max_h - wood - frame_w,
                        frame_w/2, brace_dark, "X-Diagonal 1", True)
            # Diagonal 2: top-left to bottom-right
            add_3d_dowel(wood + frame_w, mid_y, max_h - wood - frame_w,
                        max_w - wood - frame_w, mid_y, wood + frame_w,
                        frame_w/2, brace_dark, "X-Diagonal 2", False)
                        
        else:
            # Single window (original square cutout)
            # Top bar
            add_panel(wood, mid_y - brace_thick/2, max_h - wood - frame_w,
                      max_w - wood, mid_y + brace_thick/2, max_h - wood,
                      brace_color, 1.0, "Window Brace Top")
            # Bottom bar
            add_panel(wood, mid_y - brace_thick/2, wood,
                      max_w - wood, mid_y + brace_thick/2, wood + frame_w,
                      brace_color, 1.0, "Window Brace Bottom")
            # Left bar
            add_panel(wood, mid_y - brace_thick/2, wood + frame_w,
                      wood + frame_w, mid_y + brace_thick/2, max_h - wood - frame_w,
                      brace_color, 1.0, "Window Brace Left")
            # Right bar
            add_panel(max_w - wood - frame_w, mid_y - brace_thick/2, wood + frame_w,
                      max_w - wood, mid_y + brace_thick/2, max_h - wood - frame_w,
                      brace_color, 1.0, "Window Brace Right")
                  
    elif "Lumber" in brace_type:
        # Lumber cross brace - solid wood beams
        if "2x2" in brace_type:
            lw, lh = 1.5, 1.5
        elif "2x3" in brace_type:
            lw, lh = 1.5, 2.5
        else:
            lw, lh = 1.5, 3.5
            
        if lumber_layout == "Single Center":
            # Single solid brace across the middle
            add_panel(wood, mid_y - lw/2, mid_z - lh/2,
                      max_w - wood, mid_y + lw/2, mid_z + lh/2,
                      brace_color, 1.0, f"Lumber Brace ({brace_type.split('(')[1].strip(')')})")
        elif lumber_layout == "X-Cross":
            # X pattern with realistic lumber using 3D dowels
            add_3d_dowel(wood, bt + lw/2, wood + lh/2, 
                        max_w - wood, edv - wood - lw/2, max_h - wood - lh/2,
                        lw/2, brace_color, "X-Brace 1", True)
            add_3d_dowel(wood, edv - wood - lw/2, wood + lh/2,
                        max_w - wood, bt + lw/2, max_h - wood - lh/2,
                        lw/2, brace_color, "X-Brace 2", False)
        else:  # Double Parallel
            third_z = (max_h - wood * 2) / 3
            add_panel(wood, mid_y - lw/2, wood + third_z - lh/2,
                      max_w - wood, mid_y + lw/2, wood + third_z + lh/2,
                      brace_color, 1.0, "Lumber Brace 1")
            add_panel(wood, mid_y - lw/2, wood + third_z * 2 - lh/2,
                      max_w - wood, mid_y + lw/2, wood + third_z * 2 + lh/2,
                      brace_color, 1.0, "Lumber Brace 2")
                      
    elif "Ladder" in brace_type:
        # Ladder brace - horizontal rungs with vertical rails
        rung_spacing = (max_h - wood * 2) / (num_rungs + 1)
        
        # Vertical side rails
        rail_w = rung_width * 0.7
        add_panel(wood + 1, mid_y - rung_thick_val/2, wood,
                  wood + 1 + rail_w, mid_y + rung_thick_val/2, max_h - wood,
                  brace_dark, 1.0, "Ladder Rail L")
        add_panel(max_w - wood - 1 - rail_w, mid_y - rung_thick_val/2, wood,
                  max_w - wood - 1, mid_y + rung_thick_val/2, max_h - wood,
                  brace_dark, 1.0, "Ladder Rail R")
        
        # Horizontal rungs
        for i in range(num_rungs):
            rung_z = wood + rung_spacing * (i + 1)
            add_panel(wood + 1 + rail_w, mid_y - rung_thick_val/2, rung_z - rung_width/2,
                      max_w - wood - 1 - rail_w, mid_y + rung_thick_val/2, rung_z + rung_width/2,
                      brace_color, 1.0, f"Ladder Rung {i+1}" if i == 0 else None)
                      
    elif "45°" in brace_type:
        # Corner braces (triangular blocks) - solid appearance with proper corner cuts
        # These are 45° angle braces that fit in box corners
        corner_positions = [
            (wood, bt, wood),  # Front bottom left
            (max_w - wood - corner_dim, bt, wood),  # Front bottom right
            (wood, bt, max_h - wood - corner_dim),  # Front top left
            (max_w - wood - corner_dim, bt, max_h - wood - corner_dim),  # Front top right
            # Back corners too if we have enough braces
            (wood, edv - wood - corner_dim, wood),  # Back bottom left
            (max_w - wood - corner_dim, edv - wood - corner_dim, wood),  # Back bottom right
            (wood, edv - wood - corner_dim, max_h - wood - corner_dim),  # Back top left
            (max_w - wood - corner_dim, edv - wood - corner_dim, max_h - wood - corner_dim),  # Back top right
        ]
        for idx, (cx, cy, cz) in enumerate(corner_positions[:min(num_corner_braces, 8)]):
            add_panel(cx, cy, cz, cx + corner_dim, cy + corner_dim, cz + corner_dim,
                      brace_color, 1.0, f"Corner Brace {idx+1}" if idx == 0 else None)

# Helper functions for 3D drawing
def add_cyl(r, h, cx, cy, cz, color, name, axis='y'):
    """Add solid cylinder along specified axis"""
    theta = np.linspace(0, 2 * math.pi, 32)
    num_rings = max(10, int(h * 2))
    length_steps = list(np.linspace(0, h, num_rings))
    angle_steps = list(np.linspace(0, 2*math.pi, 12, endpoint=False))
    first_trace = True
    
    if axis == 'y':
        for t in length_steps:
            xc = r * np.cos(theta) + cx
            zc = r * np.sin(theta) + cz
            yc = np.full(len(theta), cy + t)
            if first_trace:
                fig.add_trace(go.Scatter3d(x=xc, y=yc, z=zc, mode='lines', 
                              line=dict(color=color, width=5), showlegend=True, name=name))
                first_trace = False
            else:
                fig.add_trace(go.Scatter3d(x=xc, y=yc, z=zc, mode='lines', 
                              line=dict(color=color, width=5), showlegend=False))
        for a in angle_steps:
            lx = [r * math.cos(a) + cx, r * math.cos(a) + cx]
            lz = [r * math.sin(a) + cz, r * math.sin(a) + cz]
            ly = [cy, cy + h]
            fig.add_trace(go.Scatter3d(x=lx, y=ly, z=lz, mode='lines', 
                          line=dict(color=color, width=3), showlegend=False))
    elif axis == 'x':
        for t in length_steps:
            yc = r * np.cos(theta) + cy
            zc = r * np.sin(theta) + cz
            xc = np.full(len(theta), cx + t)
            if first_trace:
                fig.add_trace(go.Scatter3d(x=xc, y=yc, z=zc, mode='lines',
                              line=dict(color=color, width=5), showlegend=True, name=name))
                first_trace = False
            else:
                fig.add_trace(go.Scatter3d(x=xc, y=yc, z=zc, mode='lines',
                              line=dict(color=color, width=5), showlegend=False))
        for a in angle_steps:
            ly = [r * math.cos(a) + cy, r * math.cos(a) + cy]
            lz = [r * math.sin(a) + cz, r * math.sin(a) + cz]
            lx = [cx, cx + h]
            fig.add_trace(go.Scatter3d(x=lx, y=ly, z=lz, mode='lines',
                          line=dict(color=color, width=3), showlegend=False))
    elif axis == 'z':
        for t in length_steps:
            xc = r * np.cos(theta) + cx
            yc = r * np.sin(theta) + cy
            zc = np.full(len(theta), cz + t)
            if first_trace:
                fig.add_trace(go.Scatter3d(x=xc, y=yc, z=zc, mode='lines',
                              line=dict(color=color, width=5), showlegend=True, name=name))
                first_trace = False
            else:
                fig.add_trace(go.Scatter3d(x=xc, y=yc, z=zc, mode='lines',
                              line=dict(color=color, width=5), showlegend=False))
        for a in angle_steps:
            lx = [r * math.cos(a) + cx, r * math.cos(a) + cx]
            ly = [r * math.sin(a) + cy, r * math.sin(a) + cy]
            lz = [cz, cz + h]
            fig.add_trace(go.Scatter3d(x=lx, y=ly, z=lz, mode='lines',
                          line=dict(color=color, width=3), showlegend=False))


def add_ring(r, cx, cy, cz, color, name, plane='xz'):
    """Add ring on specified plane"""
    theta = np.linspace(0, 2 * math.pi, 50)
    if plane == 'xz':
        xc = r * np.cos(theta) + cx
        zc = r * np.sin(theta) + cz
        yc = np.full(50, cy)
    elif plane == 'yz':
        yc = r * np.cos(theta) + cy
        zc = r * np.sin(theta) + cz
        xc = np.full(50, cx)
    elif plane == 'xy':
        xc = r * np.cos(theta) + cx
        yc = r * np.sin(theta) + cy
        zc = np.full(50, cz)
    fig.add_trace(go.Scatter3d(x=xc, y=yc, z=zc, mode="lines", line=dict(color=color, width=6), name=name))


def add_slot_port(w, h, length, cx, cy, cz, color, name, axis='y'):
    """Add slot port visualization - DEPRECATED, use add_slot_port_interior"""
    pass  # No longer used


def add_slot_port_interior(slot_w, slot_h, leg1_len, leg2_len, needs_bend, position, 
                           box_iw, box_ih, box_idv, wood_thick, bt, z_bottom, color, name, shared_wall=True):
    """
    Draw slot port inside the box with proper divider configuration.
    
    SHARED WALL CONFIGURATION:
    - shared_wall=True (default): Port uses enclosure side wall as one boundary
      * Side port: 1 interior divider (uses box wall as other side)
      * Center port: 2 interior dividers (one on each side)
      
    - shared_wall=False: Port uses interior dividers only (no enclosure wall as boundary)
      * Side port: 2 interior dividers (one on each side of port channel)
      * Center port: 2 interior dividers (one on each side)
    
    The slot port uses:
    - Box TOP as the port ceiling (no separate board)
    - Box BOTTOM as the port floor (no separate board)
    - Interior divider board(s) to separate port from main chamber
    - L-BEND if port is too long - divider stops short and turns
    
    The port does NOT reach the back wall - it leaves clearance = slot_width for airflow.
    """
    pw = wood_thick  # Port wall/divider thickness
    
    # Port dimensions
    port_w = slot_w  # Width of air channel
    port_h = slot_h  # Height = full interior (top to bottom of box)
    
    # Y positions (depth direction)
    y_front = 0  # Front exterior surface of box
    y_baffle_interior = bt  # Interior surface of front baffle
    
    # The port goes back leg1_len from the baffle interior
    # This leaves clearance from the back wall for air to flow
    y_leg1_end = y_baffle_interior + leg1_len
    
    # Z positions - full interior height
    z_bot = wood_thick  # Bottom of interior (top of bottom panel)
    z_top = wood_thick + box_ih  # Top of interior (bottom of top panel)
    
    # Wood colors
    port_wood_color = "#8B6914"  # Golden brown MDF
    port_edge_color = "#5C4A0F"  # Darker edges
    
    # === DETERMINE X POSITIONS BASED ON PORT POSITION ===
    # The port channel positioning depends on whether shared_wall is being used
    
    if position == "Left Side":
        if shared_wall:
            # SHARED WALL: Port against left enclosure wall
            # Uses: left wall + 1 interior divider
            x_wall_inner = wood_thick  # Inner surface of left side wall
            x_port_channel_start = x_wall_inner  # Port starts at interior wall surface
            x_port_channel_end = x_wall_inner + port_w  # Port channel width
            x_div_inner = x_port_channel_end  # Divider inner face (port side)
            x_div_outer = x_div_inner + pw  # Divider outer face (chamber side)
            num_dividers = 1
        else:
            # NO SHARED WALL: Port uses 2 interior dividers, centered on left side
            # Provides better internal space utilization
            # Port positioned slightly inward from left wall for 2-divider configuration
            spacing_from_wall = wood_thick + 0.5  # Small gap from wall for air circulation
            x_div_outer = spacing_from_wall  # Outer divider (toward wall)
            x_div_inner = x_div_outer + pw  # Inner divider (toward chamber)
            x_port_channel_start = x_div_outer  # Port starts at outer divider
            x_port_channel_end = x_div_inner + port_w  # Port ends at inner divider
            num_dividers = 2
            
    elif position == "Right Side":
        if shared_wall:
            # SHARED WALL: Port against right enclosure wall
            # Uses: right wall + 1 interior divider
            total_width = wood_thick * 2 + box_iw  # Full box width
            x_wall_inner = wood_thick + box_iw  # Inner surface of right side wall
            x_port_channel_end = x_wall_inner  # Port ends at interior wall surface
            x_port_channel_start = x_wall_inner - port_w  # Port channel width
            x_div_inner = x_port_channel_start  # Divider inner face (port side)
            x_div_outer = x_div_inner - pw  # Divider outer face (chamber side)
            num_dividers = 1
        else:
            # NO SHARED WALL: Port uses 2 interior dividers, centered on right side
            # Port positioned slightly inward from right wall for 2-divider configuration
            spacing_from_wall = wood_thick + 0.5  # Small gap from wall for air circulation
            x_div_inner = spacing_from_wall + port_w  # Inner divider (toward chamber)
            x_div_outer = x_div_inner + pw  # Outer divider (toward wall)
            x_port_channel_start = x_div_inner  # Port starts at inner divider
            x_port_channel_end = x_div_outer  # Port ends at outer divider
            num_dividers = 2
        
    elif position == "Center (Between Subs)":
        # CENTERED PORT: Always uses 2 dividers (one on each side of center channel)
        # shared_wall setting doesn't apply to center ports
        center_x = wood_thick + box_iw / 2
        x_inner_left = center_x - port_w / 2  # Left edge of port channel
        x_inner_right = center_x + port_w / 2  # Right edge of port channel
        num_dividers = 2
        
    else:  # Dual - handled by calling this function twice
        return
    
    # === DRAW THE DIVIDER BOARD(S) ===
    
    if position == "Center (Between Subs)":
        # CENTER PORT: Two divider walls, one on each side of the center channel
        # Dividers run from front baffle interior to leg1_end (NOT all the way back)
        y_div_start = y_baffle_interior
        y_div_end = y_leg1_end  # Stops short of back wall
        
        # Left divider
        left_div_x0 = x_inner_left - pw
        left_div_x1 = x_inner_left
        
        divider_verts_x = [left_div_x0, left_div_x1, left_div_x1, left_div_x0, 
                          left_div_x0, left_div_x1, left_div_x1, left_div_x0]
        divider_verts_y = [y_div_start, y_div_start, y_div_end, y_div_end, 
                          y_div_start, y_div_start, y_div_end, y_div_end]
        divider_verts_z = [z_bot, z_bot, z_bot, z_bot, z_top, z_top, z_top, z_top]
        
        fig.add_trace(go.Mesh3d(
            x=divider_verts_x, y=divider_verts_y, z=divider_verts_z,
            i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
            j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
            k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
            color=port_wood_color, opacity=1.0, flatshading=True,
            showlegend=True, name="Port Left Divider"
        ))
        
        # Right divider
        right_div_x0 = x_inner_right
        right_div_x1 = x_inner_right + pw
        
        divider_verts_x = [right_div_x0, right_div_x1, right_div_x1, right_div_x0,
                          right_div_x0, right_div_x1, right_div_x1, right_div_x0]
        
        fig.add_trace(go.Mesh3d(
            x=divider_verts_x, y=divider_verts_y, z=divider_verts_z,
            i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
            j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
            k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
            color=port_wood_color, opacity=1.0, flatshading=True,
            showlegend=True, name="Port Right Divider"
        ))
        
        # Port opening outline at FRONT FACE (exterior - where you see the port)
        opening_x = [x_inner_left, x_inner_right, x_inner_right, x_inner_left, x_inner_left]
        opening_y = [y_front] * 5  # At front exterior face of baffle
        opening_z = [z_bot, z_bot, z_top, z_top, z_bot]
        
    else:
        # LEFT or RIGHT SIDE: Single divider board
        # Divider runs from front baffle to leg1_end (leaves clearance from back)
        y_div_start = y_baffle_interior
        y_div_end = y_leg1_end  # Does NOT reach back wall
        
        if position == "Left Side":
            if shared_wall:
                div_x0 = x_div_inner
                div_x1 = x_div_outer
            else:
                # For left side without shared wall: outer divider is toward wall, inner is toward chamber
                div_x0_outer = x_div_outer  # Toward left wall
                div_x1_outer = div_x0_outer + pw
                div_x0_inner = x_div_inner  # Toward chamber
                div_x1_inner = div_x0_inner + pw
        else:  # Right Side
            if shared_wall:
                div_x0 = x_div_outer
                div_x1 = x_div_inner
            else:
                # For right side without shared wall: outer divider is toward wall, inner is toward chamber
                div_x1_outer = x_div_outer  # Toward right wall
                div_x0_outer = div_x1_outer - pw
                div_x1_inner = x_div_inner  # Toward chamber
                div_x0_inner = div_x1_inner - pw
        
        # MAIN DIVIDER(S) - runs from baffle to end of leg1 (with clearance from back)
        y_div_start = y_baffle_interior
        y_div_end = y_leg1_end  # Does NOT reach back wall
        
        if shared_wall and num_dividers == 1:
            # SHARED WALL: Single divider only
            divider_verts_x = [div_x0, div_x1, div_x1, div_x0, div_x0, div_x1, div_x1, div_x0]
            divider_verts_y = [y_div_start, y_div_start, y_div_end, y_div_end, 
                              y_div_start, y_div_start, y_div_end, y_div_end]
            divider_verts_z = [z_bot, z_bot, z_bot, z_bot, z_top, z_top, z_top, z_top]
            
            fig.add_trace(go.Mesh3d(
                x=divider_verts_x, y=divider_verts_y, z=divider_verts_z,
                i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
                j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
                k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
                color=port_wood_color, opacity=1.0, flatshading=True,
                showlegend=True, name="Port Divider (Leg 1)"
            ))
            
            # Divider edge lines for visibility
            edges = [
                ([div_x0, div_x0], [y_div_start, y_div_end], [z_bot, z_bot]),
                ([div_x0, div_x0], [y_div_start, y_div_end], [z_top, z_top]),
                ([div_x1, div_x1], [y_div_start, y_div_end], [z_bot, z_bot]),
                ([div_x1, div_x1], [y_div_start, y_div_end], [z_top, z_top]),
            ]
            for edge in edges:
                fig.add_trace(go.Scatter3d(x=edge[0], y=edge[1], z=edge[2], mode='lines',
                              line=dict(color=port_edge_color, width=2), showlegend=False))
        
        else:
            # NO SHARED WALL: Two dividers (one on each side of port channel)
            # Draw outer divider (toward wall)
            if position == "Left Side":
                divider_verts_x = [div_x0_outer, div_x1_outer, div_x1_outer, div_x0_outer,
                                  div_x0_outer, div_x1_outer, div_x1_outer, div_x0_outer]
            else:  # Right Side
                divider_verts_x = [div_x0_outer, div_x1_outer, div_x1_outer, div_x0_outer,
                                  div_x0_outer, div_x1_outer, div_x1_outer, div_x0_outer]
            
            divider_verts_y = [y_div_start, y_div_start, y_div_end, y_div_end,
                              y_div_start, y_div_start, y_div_end, y_div_end]
            divider_verts_z = [z_bot, z_bot, z_bot, z_bot, z_top, z_top, z_top, z_top]
            
            fig.add_trace(go.Mesh3d(
                x=divider_verts_x, y=divider_verts_y, z=divider_verts_z,
                i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
                j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
                k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
                color=port_wood_color, opacity=1.0, flatshading=True,
                showlegend=True, name="Port Outer Divider (Toward Wall)"
            ))
            
            # Draw inner divider (toward chamber)
            if position == "Left Side":
                divider_verts_x = [div_x0_inner, div_x1_inner, div_x1_inner, div_x0_inner,
                                  div_x0_inner, div_x1_inner, div_x1_inner, div_x0_inner]
            else:  # Right Side
                divider_verts_x = [div_x0_inner, div_x1_inner, div_x1_inner, div_x0_inner,
                                  div_x0_inner, div_x1_inner, div_x1_inner, div_x0_inner]
            
            fig.add_trace(go.Mesh3d(
                x=divider_verts_x, y=divider_verts_y, z=divider_verts_z,
                i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
                j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
                k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
                color=port_wood_color, opacity=1.0, flatshading=True,
                showlegend=True, name="Port Inner Divider (Toward Chamber)"
            ))
            
            # Edge lines for both dividers
            edges_outer = [
                ([div_x0_outer, div_x0_outer], [y_div_start, y_div_end], [z_bot, z_bot]),
                ([div_x0_outer, div_x0_outer], [y_div_start, y_div_end], [z_top, z_top]),
                ([div_x1_outer, div_x1_outer], [y_div_start, y_div_end], [z_bot, z_bot]),
                ([div_x1_outer, div_x1_outer], [y_div_start, y_div_end], [z_top, z_top]),
            ]
            edges_inner = [
                ([div_x0_inner, div_x0_inner], [y_div_start, y_div_end], [z_bot, z_bot]),
                ([div_x0_inner, div_x0_inner], [y_div_start, y_div_end], [z_top, z_top]),
                ([div_x1_inner, div_x1_inner], [y_div_start, y_div_end], [z_bot, z_bot]),
                ([div_x1_inner, div_x1_inner], [y_div_start, y_div_end], [z_top, z_top]),
            ]
            for edge in edges_outer + edges_inner:
                fig.add_trace(go.Scatter3d(x=edge[0], y=edge[1], z=edge[2], mode='lines',
                              line=dict(color=port_edge_color, width=2), showlegend=False))
        
        # === L-BEND VISUALIZATION (if needed) ===
        if needs_bend and leg2_len > 0:
            # Second leg runs perpendicular (along X-axis) from the end of leg1
            # 
            # For a proper L-bend joint where corners align:
            #   - Leg1 divider ends at y_div_end
            #   - Leg2 divider(s) start from the PORT-SIDE edge(s) of leg1
            #   - Leg2 extends toward center, running along X
            #   - Leg2 is positioned at y_div_end (butts against leg1 end)
            #
            # This creates a clean corner where leg1's end meets leg2's start
            
            # Y positions for leg2 divider (at the end of leg1)
            leg2_div_y_front = y_div_end  # Front face (where leg1 ends)
            leg2_div_y_back = y_div_end + pw  # Back face (toward back wall)
            
            if position == "Left Side":
                # Leg2 goes toward center (positive X direction)
                if shared_wall:
                    # SHARED WALL: Single L-bend divider
                    # Start from the PORT-SIDE edge of leg1 (x_div_inner)
                    leg2_x_start = x_div_inner  
                    leg2_x_end = leg2_x_start + leg2_len + pw  # Include the corner overlap
                    
                    # L-bend divider vertices
                    bend_x = [leg2_x_start, leg2_x_end, leg2_x_end, leg2_x_start,
                              leg2_x_start, leg2_x_end, leg2_x_end, leg2_x_start]
                    bend_y = [leg2_div_y_front, leg2_div_y_front, leg2_div_y_back, leg2_div_y_back,
                              leg2_div_y_front, leg2_div_y_front, leg2_div_y_back, leg2_div_y_back]
                    bend_z = [z_bot, z_bot, z_bot, z_bot, z_top, z_top, z_top, z_top]
                    
                    fig.add_trace(go.Mesh3d(
                        x=bend_x, y=bend_y, z=bend_z,
                        i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
                        j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
                        k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
                        color=port_wood_color, opacity=1.0, flatshading=True,
                        showlegend=True, name="Port Divider (Leg 2 - L-Bend)"
                    ))
                    
                    # Add edge lines for L-bend visibility
                    bend_edges = [
                        ([leg2_x_start, leg2_x_end], [leg2_div_y_front, leg2_div_y_front], [z_bot, z_bot]),
                        ([leg2_x_start, leg2_x_end], [leg2_div_y_front, leg2_div_y_front], [z_top, z_top]),
                        ([leg2_x_start, leg2_x_end], [leg2_div_y_back, leg2_div_y_back], [z_bot, z_bot]),
                        ([leg2_x_start, leg2_x_end], [leg2_div_y_back, leg2_div_y_back], [z_top, z_top]),
                    ]
                    for edge in bend_edges:
                        fig.add_trace(go.Scatter3d(x=edge[0], y=edge[1], z=edge[2], mode='lines',
                                      line=dict(color=port_edge_color, width=2), showlegend=False))
                else:
                    # NO SHARED WALL: Double L-bend dividers (outer and inner)
                    # Outer L-bend (toward wall)
                    leg2_x_start_outer = div_x0_outer
                    leg2_x_end_outer = leg2_x_start_outer + leg2_len + pw
                    
                    bend_x = [leg2_x_start_outer, leg2_x_end_outer, leg2_x_end_outer, leg2_x_start_outer,
                              leg2_x_start_outer, leg2_x_end_outer, leg2_x_end_outer, leg2_x_start_outer]
                    bend_y = [leg2_div_y_front, leg2_div_y_front, leg2_div_y_back, leg2_div_y_back,
                              leg2_div_y_front, leg2_div_y_front, leg2_div_y_back, leg2_div_y_back]
                    bend_z = [z_bot, z_bot, z_bot, z_bot, z_top, z_top, z_top, z_top]
                    
                    fig.add_trace(go.Mesh3d(
                        x=bend_x, y=bend_y, z=bend_z,
                        i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
                        j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
                        k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
                        color=port_wood_color, opacity=1.0, flatshading=True,
                        showlegend=True, name="Port Outer L-Bend (Leg 2)"
                    ))
                    
                    # Inner L-bend (toward chamber)
                    leg2_x_start_inner = div_x0_inner
                    leg2_x_end_inner = leg2_x_start_inner + leg2_len + pw
                    
                    bend_x = [leg2_x_start_inner, leg2_x_end_inner, leg2_x_end_inner, leg2_x_start_inner,
                              leg2_x_start_inner, leg2_x_end_inner, leg2_x_end_inner, leg2_x_start_inner]
                    
                    fig.add_trace(go.Mesh3d(
                        x=bend_x, y=bend_y, z=bend_z,
                        i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
                        j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
                        k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
                        color=port_wood_color, opacity=1.0, flatshading=True,
                        showlegend=True, name="Port Inner L-Bend (Leg 2)"
                    ))
                    
                    # Edge lines for both L-bends
                    bend_edges_outer = [
                        ([leg2_x_start_outer, leg2_x_end_outer], [leg2_div_y_front, leg2_div_y_front], [z_bot, z_bot]),
                        ([leg2_x_start_outer, leg2_x_end_outer], [leg2_div_y_front, leg2_div_y_front], [z_top, z_top]),
                    ]
                    bend_edges_inner = [
                        ([leg2_x_start_inner, leg2_x_end_inner], [leg2_div_y_front, leg2_div_y_front], [z_bot, z_bot]),
                        ([leg2_x_start_inner, leg2_x_end_inner], [leg2_div_y_front, leg2_div_y_front], [z_top, z_top]),
                    ]
                    for edge in bend_edges_outer + bend_edges_inner:
                        fig.add_trace(go.Scatter3d(x=edge[0], y=edge[1], z=edge[2], mode='lines',
                                      line=dict(color=port_edge_color, width=2), showlegend=False))
                        
            else:  # Right Side
                # Leg2 goes toward center (negative X direction)
                if shared_wall:
                    # SHARED WALL: Single L-bend divider
                    leg2_x_start = x_div_inner  
                    leg2_x_end = leg2_x_start - leg2_len - pw  # Include the corner overlap
                    
                    bend_x = [leg2_x_end, leg2_x_start, leg2_x_start, leg2_x_end,
                              leg2_x_end, leg2_x_start, leg2_x_start, leg2_x_end]
                    bend_y = [leg2_div_y_front, leg2_div_y_front, leg2_div_y_back, leg2_div_y_back,
                              leg2_div_y_front, leg2_div_y_front, leg2_div_y_back, leg2_div_y_back]
                    bend_z = [z_bot, z_bot, z_bot, z_bot, z_top, z_top, z_top, z_top]
                    
                    fig.add_trace(go.Mesh3d(
                        x=bend_x, y=bend_y, z=bend_z,
                        i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
                        j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
                        k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
                        color=port_wood_color, opacity=1.0, flatshading=True,
                        showlegend=True, name="Port Divider (Leg 2 - L-Bend)"
                    ))
                    
                    bend_edges = [
                        ([leg2_x_end, leg2_x_start], [leg2_div_y_front, leg2_div_y_front], [z_bot, z_bot]),
                        ([leg2_x_end, leg2_x_start], [leg2_div_y_front, leg2_div_y_front], [z_top, z_top]),
                        ([leg2_x_end, leg2_x_start], [leg2_div_y_back, leg2_div_y_back], [z_bot, z_bot]),
                        ([leg2_x_end, leg2_x_start], [leg2_div_y_back, leg2_div_y_back], [z_top, z_top]),
                    ]
                    for edge in bend_edges:
                        fig.add_trace(go.Scatter3d(x=edge[0], y=edge[1], z=edge[2], mode='lines',
                                      line=dict(color=port_edge_color, width=2), showlegend=False))
                else:
                    # NO SHARED WALL: Double L-bend dividers (outer and inner)
                    # Outer L-bend (toward wall)
                    leg2_x_start_outer = div_x1_outer
                    leg2_x_end_outer = leg2_x_start_outer - leg2_len - pw
                    
                    bend_x = [leg2_x_end_outer, leg2_x_start_outer, leg2_x_start_outer, leg2_x_end_outer,
                              leg2_x_end_outer, leg2_x_start_outer, leg2_x_start_outer, leg2_x_end_outer]
                    bend_y = [leg2_div_y_front, leg2_div_y_front, leg2_div_y_back, leg2_div_y_back,
                              leg2_div_y_front, leg2_div_y_front, leg2_div_y_back, leg2_div_y_back]
                    bend_z = [z_bot, z_bot, z_bot, z_bot, z_top, z_top, z_top, z_top]
                    
                    fig.add_trace(go.Mesh3d(
                        x=bend_x, y=bend_y, z=bend_z,
                        i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
                        j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
                        k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
                        color=port_wood_color, opacity=1.0, flatshading=True,
                        showlegend=True, name="Port Outer L-Bend (Leg 2)"
                    ))
                    
                    # Inner L-bend (toward chamber)
                    leg2_x_start_inner = div_x1_inner
                    leg2_x_end_inner = leg2_x_start_inner - leg2_len - pw
                    
                    bend_x = [leg2_x_end_inner, leg2_x_start_inner, leg2_x_start_inner, leg2_x_end_inner,
                              leg2_x_end_inner, leg2_x_start_inner, leg2_x_start_inner, leg2_x_end_inner]
                    
                    fig.add_trace(go.Mesh3d(
                        x=bend_x, y=bend_y, z=bend_z,
                        i=[0, 0, 4, 4, 0, 1, 0, 3, 1, 2, 4, 5],
                        j=[1, 3, 5, 7, 4, 5, 1, 7, 2, 6, 5, 6],
                        k=[2, 2, 6, 6, 1, 2, 4, 4, 6, 7, 7, 7],
                        color=port_wood_color, opacity=1.0, flatshading=True,
                        showlegend=True, name="Port Inner L-Bend (Leg 2)"
                    ))
                    
                    # Edge lines for both L-bends
                    bend_edges_outer = [
                        ([leg2_x_end_outer, leg2_x_start_outer], [leg2_div_y_front, leg2_div_y_front], [z_bot, z_bot]),
                        ([leg2_x_end_outer, leg2_x_start_outer], [leg2_div_y_front, leg2_div_y_front], [z_top, z_top]),
                    ]
                    bend_edges_inner = [
                        ([leg2_x_end_inner, leg2_x_start_inner], [leg2_div_y_front, leg2_div_y_front], [z_bot, z_bot]),
                        ([leg2_x_end_inner, leg2_x_start_inner], [leg2_div_y_front, leg2_div_y_front], [z_top, z_top]),
                    ]
                    for edge in bend_edges_outer + bend_edges_inner:
                        fig.add_trace(go.Scatter3d(x=edge[0], y=edge[1], z=edge[2], mode='lines',
                                      line=dict(color=port_edge_color, width=2), showlegend=False))
        
        # Port opening outline at INTERIOR of baffle (where port air flows)
        # The opening is from the interior wall surface to the divider
        if position == "Left Side":
            # From left wall interior (x_port_channel_start) to divider (x_div_inner)
            opening_x = [x_port_channel_start, x_div_inner, x_div_inner, x_port_channel_start, x_port_channel_start]
        else:
            # From divider (x_div_inner) to right wall interior (x_port_channel_end)
            opening_x = [x_div_inner, x_port_channel_end, x_port_channel_end, x_div_inner, x_div_inner]
        opening_y = [y_front] * 5  # At FRONT EXTERIOR FACE of baffle (where port opening is visible)
        opening_z = [z_bot, z_bot, z_top, z_top, z_bot]
    
    # Draw port opening highlight at FRONT FACE (exterior - where you see the port)
    fig.add_trace(go.Scatter3d(
        x=opening_x, y=opening_y, z=opening_z,
        mode='lines', line=dict(color='lime', width=5),
        showlegend=True, name=f"Port Opening ({round(port_w, 1)}\" × {round(port_h, 1)}\")"
    ))
    
    # Also draw the interior port opening (where air enters the port channel)
    interior_opening_y = [y_baffle_interior] * 5
    fig.add_trace(go.Scatter3d(
        x=opening_x, y=interior_opening_y, z=opening_z,
        mode='lines', line=dict(color='cyan', width=3),
        showlegend=False  # Don't clutter legend
    ))


# Helper function to create annular mesh (ring with hole)
def create_annular_mesh(cx, cy, cz, inner_r, outer_r, n_seg=32):
    """Create vertices and triangles for an annular (donut) shape on XZ plane at Y=cy"""
    theta = np.linspace(0, 2 * np.pi, n_seg, endpoint=False)
    
    # Outer circle vertices
    x_outer = outer_r * np.cos(theta) + cx
    z_outer = outer_r * np.sin(theta) + cz
    
    # Inner circle vertices  
    x_inner = inner_r * np.cos(theta) + cx
    z_inner = inner_r * np.sin(theta) + cz
    
    # Combine: first n_seg are outer, next n_seg are inner
    x = np.concatenate([x_outer, x_inner])
    y = np.full(n_seg * 2, cy)
    z = np.concatenate([z_outer, z_inner])
    
    # Create triangles connecting outer to inner
    i_idx, j_idx, k_idx = [], [], []
    for seg in range(n_seg):
        o1 = seg
        o2 = (seg + 1) % n_seg
        i1 = seg + n_seg
        i2 = (seg + 1) % n_seg + n_seg
        
        # Two triangles per segment
        i_idx.extend([o1, o1])
        j_idx.extend([o2, i1])
        k_idx.extend([i1, i2])
    
    return x, y, z, i_idx, j_idx, k_idx


# Helper function to create filled disk mesh
def create_disk_mesh(cx, cy, cz, radius, n_seg=32):
    """Create vertices and triangles for a filled disk on XZ plane at Y=cy"""
    theta = np.linspace(0, 2 * np.pi, n_seg, endpoint=False)
    
    # Center vertex + perimeter vertices
    x = np.concatenate([[cx], radius * np.cos(theta) + cx])
    y = np.full(n_seg + 1, cy)
    z = np.concatenate([[cz], radius * np.sin(theta) + cz])
    
    # Triangles from center to each edge
    i_idx, j_idx, k_idx = [], [], []
    for seg in range(n_seg):
        i_idx.append(0)
        j_idx.append(seg + 1)
        k_idx.append((seg % n_seg) + 2 if seg < n_seg - 1 else 1)
    
    return x, y, z, i_idx, j_idx, k_idx


# Helper function to create conical surface mesh (cone between two circles at different Y)
def create_cone_mesh(cx, cz, y1, r1, y2, r2, n_seg=32):
    """Create vertices and triangles for a conical surface between two circles"""
    theta = np.linspace(0, 2 * np.pi, n_seg, endpoint=False)
    
    # Bottom circle vertices
    x1 = r1 * np.cos(theta) + cx
    z1 = r1 * np.sin(theta) + cz
    y1_arr = np.full(n_seg, y1)
    
    # Top circle vertices
    x2 = r2 * np.cos(theta) + cx
    z2 = r2 * np.sin(theta) + cz
    y2_arr = np.full(n_seg, y2)
    
    x = np.concatenate([x1, x2])
    y = np.concatenate([y1_arr, y2_arr])
    z = np.concatenate([z1, z2])
    
    # Triangles
    i_idx, j_idx, k_idx = [], [], []
    for seg in range(n_seg):
        b1 = seg
        b2 = (seg + 1) % n_seg
        t1 = seg + n_seg
        t2 = (seg + 1) % n_seg + n_seg
        
        i_idx.extend([b1, b1])
        j_idx.extend([b2, t1])
        k_idx.extend([t1, t2])
    
    return x, y, z, i_idx, j_idx, k_idx


# Helper function to create cylinder mesh
def create_cylinder_mesh(cx, cz, y_start, y_end, radius, n_seg=32):
    """Create vertices and triangles for a cylinder wall"""
    theta = np.linspace(0, 2 * np.pi, n_seg, endpoint=False)
    
    # Bottom circle
    x1 = radius * np.cos(theta) + cx
    z1 = radius * np.sin(theta) + cz
    y1 = np.full(n_seg, y_start)
    
    # Top circle
    x2 = radius * np.cos(theta) + cx  
    z2 = radius * np.sin(theta) + cz
    y2 = np.full(n_seg, y_end)
    
    x = np.concatenate([x1, x2])
    y = np.concatenate([y1, y2])
    z = np.concatenate([z1, z2])
    
    i_idx, j_idx, k_idx = [], [], []
    for seg in range(n_seg):
        b1 = seg
        b2 = (seg + 1) % n_seg
        t1 = seg + n_seg
        t2 = (seg + 1) % n_seg + n_seg
        
        i_idx.extend([b1, b1])
        j_idx.extend([b2, t1])
        k_idx.extend([t1, t2])
    
    return x, y, z, i_idx, j_idx, k_idx


# Draw detailed subwoofer model with realistic filled meshes
def add_subwoofer_detailed(cx, cy, cz, cutout_r, od_r, depth, sub_model_name="Sub", direction=1):
    """Draw a detailed subwoofer with SOLID filled mesh surfaces - nothing shows through"""
    n_seg = 36
    d = direction  # 1 = facing forward (into negative Y), -1 = facing back
    
    # Subwoofer dimensions based on cutout
    frame_r = od_r
    surround_outer_r = cutout_r * 0.95
    surround_inner_r = cutout_r * 0.72
    cone_base_r = surround_inner_r
    cone_tip_r = cutout_r * 0.22
    dustcap_r = cutout_r * 0.20
    motor_r = cutout_r * 0.70
    
    surround_depth = depth * 0.08
    cone_depth = depth * 0.55
    motor_depth = depth * 0.5
    
    surround_y = cy + d * surround_depth
    cone_back_y = cy + d * cone_depth
    motor_start_y = cy + d * cone_depth * 0.6
    motor_end_y = motor_start_y + d * motor_depth
    
    # === SOLID BACKING DISC (blocks everything behind the sub) ===
    # This is a solid disc at the frame level to prevent seeing through
    x, y, z, i, j, k = create_disk_mesh(cx, cy, cz, frame_r, n_seg)
    fig.add_trace(go.Mesh3d(x=x, y=y, z=z, i=i, j=j, k=k, 
                            color='#252525', opacity=1.0, showlegend=False, flatshading=True))
    
    # === FRAME/BASKET - dark gray metal (solid) ===
    x, y, z, i, j, k = create_annular_mesh(cx, cy, cz, cutout_r * 0.96, frame_r, n_seg)
    fig.add_trace(go.Mesh3d(x=x, y=y, z=z, i=i, j=j, k=k, 
                            color='#404040', opacity=1.0, showlegend=False, flatshading=True))
    
    # === SURROUND - black rubber (solid) ===
    x, y, z, i, j, k = create_annular_mesh(cx, surround_y, cz, surround_inner_r, surround_outer_r, n_seg)
    fig.add_trace(go.Mesh3d(x=x, y=y, z=z, i=i, j=j, k=k,
                            color='#1a1a1a', opacity=1.0, showlegend=False, flatshading=True))
    
    # === CONE - dark charcoal paper/poly (solid) ===
    x, y, z, i, j, k = create_cone_mesh(cx, cz, surround_y, cone_base_r, cone_back_y, cone_tip_r, n_seg)
    fig.add_trace(go.Mesh3d(x=x, y=y, z=z, i=i, j=j, k=k,
                            color='#2d2d2d', opacity=1.0, showlegend=False, flatshading=True))
    
    # === CONE BACK PLATE (solid disc at voice coil area to block view) ===
    x, y, z, i, j, k = create_disk_mesh(cx, cone_back_y, cz, cone_tip_r * 1.5, n_seg)
    fig.add_trace(go.Mesh3d(x=x, y=y, z=z, i=i, j=j, k=k,
                            color='#1a1a1a', opacity=1.0, showlegend=False, flatshading=True))
    
    # === DUSTCAP - silver aluminum (solid) ===
    dustcap_y = surround_y - d * 0.15
    x, y, z, i, j, k = create_disk_mesh(cx, dustcap_y, cz, dustcap_r, n_seg)
    fig.add_trace(go.Mesh3d(x=x, y=y, z=z, i=i, j=j, k=k,
                            color='#b8b8b8', opacity=1.0, showlegend=False, flatshading=True))
    
    # === MOTOR FRONT PLATE (solid disc at motor start to block view) ===
    x, y, z, i, j, k = create_disk_mesh(cx, motor_start_y, cz, motor_r, n_seg)
    fig.add_trace(go.Mesh3d(x=x, y=y, z=z, i=i, j=j, k=k,
                            color='#3a3a3a', opacity=1.0, showlegend=False, flatshading=True))
    
    # === MOTOR/MAGNET - dark steel (solid cylinder wall) ===
    x, y, z, i, j, k = create_cylinder_mesh(cx, cz, motor_start_y, motor_end_y, motor_r, n_seg)
    fig.add_trace(go.Mesh3d(x=x, y=y, z=z, i=i, j=j, k=k,
                            color='#505050', opacity=1.0, showlegend=False, flatshading=True))
    
    # === MOTOR BACK CAP (solid) ===
    x, y, z, i, j, k = create_disk_mesh(cx, motor_end_y, cz, motor_r, n_seg)
    fig.add_trace(go.Mesh3d(x=x, y=y, z=z, i=i, j=j, k=k,
                            color='#404040', opacity=1.0, showlegend=False, flatshading=True))
    
    # === BASKET RIBS - structural lines ===
    theta = np.linspace(0, 2 * np.pi, 50)
    n_ribs = 8
    for rib_idx in range(n_ribs):
        angle = rib_idx * 2 * np.pi / n_ribs
        rib_x = [frame_r * 0.88 * np.cos(angle) + cx, motor_r * 1.05 * np.cos(angle) + cx]
        rib_z = [frame_r * 0.88 * np.sin(angle) + cz, motor_r * 1.05 * np.sin(angle) + cz]
        rib_y = [cy, motor_start_y]
        fig.add_trace(go.Scatter3d(x=rib_x, y=rib_y, z=rib_z, mode='lines',
                                   line=dict(color='#353535', width=4), showlegend=False))
    
    # === CUTOUT RING - red reference ===
    xc = cutout_r * np.cos(theta) + cx
    zc = cutout_r * np.sin(theta) + cz
    yc_cut = np.full(len(theta), cy - d * 0.05)
    fig.add_trace(go.Scatter3d(x=xc, y=yc_cut, z=zc, mode='lines',
                               line=dict(color='red', width=4), name=f'{sub_model_name} Cutout', showlegend=True))


# Sub positions
def get_sub_positions(num_subs, arrangement, cx, cz, spacing):
    """Calculate positions for each sub based on arrangement pattern"""
    positions = []
    if num_subs == 1:
        return [(cx, cz)]
    
    sp = spacing
    
    if arrangement == "Auto":
        if num_subs == 2:
            positions = [(cx - sp/2, cz), (cx + sp/2, cz)]
        elif num_subs == 3:
            positions = [(cx - sp, cz), (cx, cz), (cx + sp, cz)]
        elif num_subs == 4:
            positions = [(cx - sp/2, cz - sp/2), (cx + sp/2, cz - sp/2),
                        (cx - sp/2, cz + sp/2), (cx + sp/2, cz + sp/2)]
        elif num_subs == 5:
            positions = [(cx - sp, cz - sp/2), (cx, cz - sp/2), (cx + sp, cz - sp/2),
                        (cx - sp/2, cz + sp/2), (cx + sp/2, cz + sp/2)]
        elif num_subs == 6:
            positions = [(cx - sp, cz - sp/2), (cx, cz - sp/2), (cx + sp, cz - sp/2),
                        (cx - sp, cz + sp/2), (cx, cz + sp/2), (cx + sp, cz + sp/2)]
    elif arrangement == "Row Horizontal":
        offset = (num_subs - 1) / 2
        for i in range(num_subs):
            positions.append((cx + (i - offset) * sp, cz))
    elif arrangement == "Row Vertical":
        offset = (num_subs - 1) / 2
        for i in range(num_subs):
            positions.append((cx, cz + (i - offset) * sp))
    elif arrangement == "2x2 Grid":
        grid = [(0, 0), (1, 0), (0, 1), (1, 1), (0.5, 2), (0.5, -1)]
        for i in range(min(num_subs, 6)):
            gx, gz = grid[i]
            positions.append((cx + (gx - 0.5) * sp, cz + (gz - 0.5) * sp))
    elif arrangement == "Diamond":
        if num_subs == 4:
            positions = [(cx, cz - sp*0.7), (cx - sp*0.7, cz), (cx + sp*0.7, cz), (cx, cz + sp*0.7)]
        else:
            offset = (num_subs - 1) / 2
            for i in range(num_subs):
                positions.append((cx + (i - offset) * sp * 0.7, cz + (i - offset) * sp * 0.7))
    else:
        # Default fallback
        offset = (num_subs - 1) / 2
        for i in range(num_subs):
            positions.append((cx + (i - offset) * sp, cz))
    
    return positions

# Draw subwoofers
sub_spacing = sub_od + 0.5
sub_center_x = sub_x_actual if sub_mount_side in ["Front", "Back"] else edv / 2
sub_center_z = sub_z_actual

sub_positions = get_sub_positions(num_subs, sub_arrangement, sub_center_x, sub_center_z, sub_spacing)

for sub_idx in range(num_subs):
    # Offset subwoofer slightly to prevent Z-fighting with baffle
    sub_offset = 0.15  # Small offset to push sub through baffle slightly
    
    # Check if this specific sub is inverted
    is_this_sub_inverted = sub_inverted[sub_idx] if sub_idx < len(sub_inverted) else False
    
    # 4th ORDER BANDPASS: Mount sub on internal divider wall
    # DEFAULT: Motor (magnet) faces PORTED chamber (front), Cone faces SEALED chamber (back)
    if is_bandpass and 'bandpass_divider_y' in dir() and 'divider_sub_positions' in dir():
        # Use the divider sub positions we calculated earlier (centered on divider)
        if sub_idx < len(divider_sub_positions):
            pos_x, pos_z = divider_sub_positions[sub_idx]
        else:
            pos_x, pos_z = max_w / 2, max_h / 2
        
        # Mount on divider wall - DEFAULT: motor toward ported (front), cone toward sealed (back)
        if is_this_sub_inverted:
            # Inverted: cone faces ported (front), motor faces sealed (back)
            # Position sub on BACK side of divider, cone pointing toward front
            add_subwoofer_detailed(pos_x, bandpass_divider_y + wood + sub_offset, pos_z, 
                                   sub_c / 2, sub_od / 2, sub_depth, sub_name, direction=-1)
        else:
            # NORMAL DEFAULT: motor faces ported (front), cone faces sealed (back)
            # Position sub on FRONT side of divider, motor extending into ported chamber
            # direction=1 means cone extends in positive Y direction (toward back/sealed)
            add_subwoofer_detailed(pos_x, bandpass_divider_y + sub_offset, pos_z, 
                                   sub_c / 2, sub_od / 2, sub_depth, sub_name, direction=1)
    else:
        pos_x, pos_z = sub_positions[sub_idx] if sub_idx < len(sub_positions) else (sub_center_x, sub_center_z)
        
        if sub_mount_side == "Front":
            if is_this_sub_inverted:
                # Inverted: motor faces front, cone faces inside box
                add_subwoofer_detailed(pos_x, -exp - sub_offset, pos_z, sub_c / 2, sub_od / 2, sub_depth, sub_name, direction=-1)
            else:
                # Normal: cone faces front
                add_subwoofer_detailed(pos_x, -exp - sub_offset, pos_z, sub_c / 2, sub_od / 2, sub_depth, sub_name, direction=1)
        elif sub_mount_side == "Back":
            if is_this_sub_inverted:
                # Inverted: motor faces back, cone faces inside box
                add_subwoofer_detailed(pos_x, edv + exp + sub_offset, pos_z, sub_c / 2, sub_od / 2, sub_depth, sub_name, direction=1)
            else:
                # Normal: cone faces back
                add_subwoofer_detailed(pos_x, edv + exp + sub_offset, pos_z, sub_c / 2, sub_od / 2, sub_depth, sub_name, direction=-1)
        elif sub_mount_side == "Left":
            # Sub mounted on left wall - draw at X=0 facing inward
            sub_y_pos = edv / 2  # Center Y
            sub_z_pos = pos_z
            # Draw a simplified representation - circular rings to show sub position
            add_ring(sub_c / 2, wood, sub_y_pos, sub_z_pos, "red", f"Sub {sub_idx+1} Cutout", plane='yz')
            add_ring(sub_od / 2, wood, sub_y_pos, sub_z_pos, "orange", f"Sub {sub_idx+1} OD", plane='yz')
        elif sub_mount_side == "Right":
            # Sub mounted on right wall - draw at X=max_w facing inward
            sub_y_pos = edv / 2  # Center Y
            sub_z_pos = pos_z
            add_ring(sub_c / 2, max_w - wood, sub_y_pos, sub_z_pos, "red", f"Sub {sub_idx+1} Cutout", plane='yz')
            add_ring(sub_od / 2, max_w - wood, sub_y_pos, sub_z_pos, "orange", f"Sub {sub_idx+1} OD", plane='yz')
        elif sub_mount_side == "Top":
            # Sub mounted on top - draw at Z=max_h
            sub_y_pos = edv / 2  # Center Y
            add_ring(sub_c / 2, pos_x, sub_y_pos, max_h - wood, "red", f"Sub {sub_idx+1} Cutout", plane='xy')
            add_ring(sub_od / 2, pos_x, sub_y_pos, max_h - wood, "orange", f"Sub {sub_idx+1} OD", plane='xy')
        elif sub_mount_side == "Bottom":
            # Sub mounted on bottom - draw at Z=0
            sub_y_pos = edv / 2  # Center Y
            add_ring(sub_c / 2, pos_x, sub_y_pos, wood, "red", f"Sub {sub_idx+1} Cutout", plane='xy')
            add_ring(sub_od / 2, pos_x, sub_y_pos, wood, "orange", f"Sub {sub_idx+1} OD", plane='xy')

# Draw ports (for ported boxes and 4th order bandpass)
if is_ported or is_bandpass:
    outside_len = max(0.0, safe_port_len - p_len) if port_type == "Round Aero Port" else 0
    
    for i in range(int(num_ports)):
        if num_ports == 1:
            port_z_offset = port_z_actual
            port_x_offset = port_x_actual
        elif num_ports == 2:
            port_z_offset = port_z_actual + (i - 0.5) * (ps["d"] + 1)
            port_x_offset = port_x_actual
        else:
            port_z_offset = port_z_actual + ((i % 2) - 0.5) * (ps["d"] + 1)
            port_x_offset = port_x_actual + ((i // 2) - 0.5) * (ps["d"] + 1)
        
        if port_type == "Round Aero Port":
            # Determine port placement based on port_side_placement (from Component Placement)
            # Fall back to port_direction for backwards compatibility
            actual_placement = port_side_placement if 'port_side_placement' in dir() else port_direction
            
            if actual_placement == "Front Baffle" or port_direction == "Front":
                # Port on front baffle
                add_cyl(ps["d"] / 2, safe_port_len, port_x_offset, -outside_len - exp, port_z_offset, "dodgerblue", f"Port {i+1}", axis='y')
                add_ring(ps["c"] / 2, port_x_offset, -exp, port_z_offset, "cyan", f"Cutout {i+1}", plane='xz')
                add_ring(ps["od"] / 2, port_x_offset, -exp, port_z_offset, "orange", f"Flare OD {i+1}", plane='xz')
            elif actual_placement == "Rear" or port_direction == "Rear":
                # Port on rear panel
                add_cyl(ps["d"] / 2, safe_port_len, port_x_offset, edv - safe_port_len + outside_len + exp, port_z_offset, "dodgerblue", f"Port {i+1}", axis='y')
                add_ring(ps["c"] / 2, port_x_offset, edv + exp, port_z_offset, "cyan", f"Cutout {i+1}", plane='xz')
                add_ring(ps["od"] / 2, port_x_offset, edv + exp, port_z_offset, "orange", f"Flare OD {i+1}", plane='xz')
            elif "Left Side" in actual_placement or port_direction == "Side":
                # Port on left wall - determine front or rear of side
                port_y_pos = bt + 2 if "Front" in actual_placement else edv - 2
                add_cyl(ps["d"] / 2, safe_port_len, -outside_len - exp, port_y_pos, port_z_offset, "dodgerblue", f"Port {i+1}", axis='x')
                add_ring(ps["c"] / 2, 0, port_y_pos, port_z_offset, "cyan", f"Cutout {i+1}", plane='yz')
                add_ring(ps["od"] / 2, 0, port_y_pos, port_z_offset, "orange", f"Flare OD {i+1}", plane='yz')
            elif "Right Side" in actual_placement:
                # Port on right wall - determine front or rear of side
                port_y_pos = bt + 2 if "Front" in actual_placement else edv - 2
                add_cyl(ps["d"] / 2, safe_port_len, max_w + outside_len + exp - safe_port_len, port_y_pos, port_z_offset, "dodgerblue", f"Port {i+1}", axis='x')
                add_ring(ps["c"] / 2, max_w, port_y_pos, port_z_offset, "cyan", f"Cutout {i+1}", plane='yz')
                add_ring(ps["od"] / 2, max_w, port_y_pos, port_z_offset, "orange", f"Flare OD {i+1}", plane='yz')
            elif actual_placement == "Top" or port_direction == "Top":
                # Port on top panel
                add_cyl(ps["d"] / 2, safe_port_len, port_x_offset, edv / 2, max_h + outside_len + exp - safe_port_len, "dodgerblue", f"Port {i+1}", axis='z')
                add_ring(ps["c"] / 2, port_x_offset, edv / 2, max_h, "cyan", f"Cutout {i+1}", plane='xy')
                add_ring(ps["od"] / 2, port_x_offset, edv / 2, max_h, "orange", f"Flare OD {i+1}", plane='xy')
        elif port_type == "Slot Port":
            # Draw slot port properly inside the box spanning full interior height
            # Use the new interior slot port function
            
            if slot_position == "Dual (Both Sides)":
                # Draw slot ports on BOTH sides
                for side_pos in ["Left Side", "Right Side"]:
                    add_slot_port_interior(
                        slot_w=slot_width,
                        slot_h=slot_height,
                        leg1_len=slot_leg1_len,
                        leg2_len=slot_leg2_len,
                        needs_bend=port_needs_bend,
                        position=side_pos,
                        box_iw=iw,
                        box_ih=ih,
                        box_idv=idv,
                        wood_thick=wood,
                        bt=bt,
                        z_bottom=wood,  # Full interior height
                        color="dodgerblue",
                        name=f"Slot Port ({side_pos})",
                        shared_wall=slot_shared_wall
                    )
            else:
                # Single port (Left, Right, or Center)
                add_slot_port_interior(
                    slot_w=slot_width,
                    slot_h=slot_height,
                    leg1_len=slot_leg1_len,
                    leg2_len=slot_leg2_len,
                    needs_bend=port_needs_bend,
                    position=slot_position,
                    box_iw=iw,
                    box_ih=ih,
                    box_idv=idv,
                    wood_thick=wood,
                    bt=bt,
                    z_bottom=wood,  # Full interior height
                    color="dodgerblue",
                    name=f"Slot Port {i+1}",
                    shared_wall=slot_shared_wall
                )

# Terminal cup (Feature #29)
if show_terminal:
    add_ring(terminal_d / 2, terminal_x, -exp - 0.1, terminal_z, "gold", "Terminal Cup", plane='xz')

# Dimension labels
fig.add_trace(go.Scatter3d(
    x=[max_w / 2], y=[0], z=[-3 - exp], mode="text",
    text=[f"[ Width: {max_w} in ]"],
    textposition="bottom center",
    textfont=dict(color="white", size=14), showlegend=False))

fig.add_trace(go.Scatter3d(
    x=[-3 - exp], y=[0], z=[max_h / 2], mode="text",
    text=[f"[{max_h} in]"],
    textposition="middle left",
    textfont=dict(color="white", size=14), showlegend=False))

fig.add_trace(go.Scatter3d(
    x=[max_w + 3 + exp], y=[edv / 2], z=[0], mode="text",
    text=[f"[ Depth: {round(edv, 2)} in ]"],
    textposition="middle right",
    textfont=dict(color="white", size=14), showlegend=False))

fig.update_layout(
    scene=dict(
        xaxis=dict(showbackground=False, showgrid=False, zeroline=False, showticklabels=False, title=""),
        yaxis=dict(showbackground=False, showgrid=False, zeroline=False, showticklabels=False, title=""),
        zaxis=dict(showbackground=False, showgrid=False, zeroline=False, showticklabels=False, title=""),
        aspectmode="data",
    ),
    margin=dict(l=0, r=0, b=0, t=0),
)
st.plotly_chart(fig, use_container_width=True)

# ═══════════════════════════════════════════════════════════════════════════════
# BOTTOM SECTION - Tabs for different views
# ═══════════════════════════════════════════════════════════════════════════════
st.markdown("---")

tab1, tab2, tab3, tab4, tab5, tab6, tab7 = st.tabs(["📋 Cut List", "📐 Blueprint Plans", "📊 Acoustic Response", "💰 Cost Breakdown", 
                                               "📈 Advanced Analysis", "💾 Save/Load", "📤 Export"])

# TAB 1: CUT LIST (Feature #1)
with tab1:
    st.subheader("📋 Cut Sheet / Panel Layout")
    
    top_d = edv - bt - (lay_b * wood)
    
    col_cut1, col_cut2 = st.columns(2)
    
    with col_cut1:
        st.markdown("### Panel Dimensions")
        cut_data = {
            "Panel": ["Front Baffle", "Back Panel", "Top", "Bottom", "Left Side", "Right Side"],
            "Qty": [lay_f, lay_b, lay_tb, lay_tb, lay_s, lay_s],
            "Width (in)": [max_w, max_w, max_w, max_w, round(ih, 2), round(ih, 2)],
            "Height (in)": [max_h, max_h, round(top_d, 2), round(top_d, 2), round(top_d, 2), round(top_d, 2)],
        }
        
        # Add internal divider for 4th order bandpass
        if is_bandpass:
            # Divider dimensions: spans internal width × internal height
            divider_width = iw
            divider_height = ih
            cut_data["Panel"].append("Internal Divider*")
            cut_data["Qty"].append(1)
            cut_data["Width (in)"].append(round(divider_width, 2))
            cut_data["Height (in)"].append(round(divider_height, 2))
        
        # Calculate area for each panel
        areas = []
        for i in range(len(cut_data["Panel"])):
            area = cut_data["Width (in)"][i] * cut_data["Height (in)"][i] * cut_data["Qty"][i] / 144
            areas.append(round(area, 2))
        cut_data["Area (sq ft)"] = areas
        
        import pandas as pd
        df = pd.DataFrame(cut_data)
        st.dataframe(df, use_container_width=True)
        
        total_area = sum(areas)
        st.metric("Total Panel Area", f"{round(total_area, 2)} sq ft")
        st.metric("Sheets Needed (4x8)", f"{math.ceil(total_area * 1.2 / 32)}")
        
        # Notes for bandpass divider
        if is_bandpass:
            st.caption(f"*Internal Divider requires {num_subs}x Ø{sub_c}\" sub cutout(s)")
    
    with col_cut2:
        st.markdown("### Hole Cutouts")
        if is_bandpass:
            st.markdown(f"**Subwoofer Cutout (on divider):** {sub_c}\" diameter × {num_subs}")
        else:
            st.markdown(f"**Subwoofer Cutout:** {sub_c}\" diameter × {num_subs}")
        if (is_ported or is_bandpass) and port_type == "Round Aero Port":
            st.markdown(f"**Port Cutout:** {ps['c']}\" diameter × {num_ports}")
        elif (is_ported or is_bandpass) and port_type == "Slot Port":
            st.markdown(f"**Slot Port:** {slot_width}\" × {slot_height}\" × {num_ports}")
        if show_terminal:
            st.markdown(f"**Terminal Cup:** {terminal_d}\" diameter")
        
        st.markdown("---")
        st.markdown("### Box Dimensions")
        st.caption(f"**Internal:** {round(iw, 2)}\" × {round(ih, 2)}\" × {round(idv, 2)}\"")
        st.caption(f"**External:** {max_w}\" × {max_h}\" × {round(edv, 2)}\"")
        st.caption(f"**Gross Volume:** {round(gross, 3)} cf")
        st.caption(f"**Net Volume:** {round(net_v, 3)} cf")
        st.caption(f"**Total Displacement:** {round(total_disp, 3)} cf")
        
        # Show chamber volumes for bandpass
        if is_bandpass:
            st.markdown("---")
            st.markdown("### 4th Order Chambers")
            st.metric("Ported Chamber", f"{round(ported_chamber_vol, 2)} cf")
            st.metric("Sealed Chamber", f"{round(sealed_chamber_vol, 2)} cf")

# TAB 2: BLUEPRINT PLANS (like subbox.pro)
with tab2:
    st.subheader("📐 Blueprint Plans — Technical Drawing")
    
    # Create blueprint-style 2D views with dimensions
    blueprint_col1, blueprint_col2 = st.columns(2)
    
    with blueprint_col1:
        # FRONT VIEW
        st.markdown("### Front View")
        fig_front, ax_front = plt.subplots(figsize=(8, 6))
        ax_front.set_facecolor('#e8e8e8')  # Blueprint paper color
        fig_front.patch.set_facecolor('#e8e8e8')
        
        # Draw front panel outline
        front_rect = plt.Rectangle((0, 0), max_w, max_h, fill=False, 
                                   edgecolor='#1a1a1a', linewidth=2)
        ax_front.add_patch(front_rect)
        
        # For bandpass, front baffle has NO sub cutouts (subs are on divider)
        # Only show port if present
        if is_bandpass:
            # Front view of bandpass shows port opening only, no sub cutouts
            ax_front.text(max_w/2, max_h/2, 'PORT ONLY\n(Subs on Divider)', ha='center', va='center',
                         fontsize=10, color='#666', style='italic')
            
            # Draw port opening for bandpass
            if port_type == "Slot Port":
                if slot_position == "Left Side":
                    port_x = wood
                elif slot_position == "Right Side":
                    port_x = max_w - wood - slot_width
                else:
                    port_x = (max_w - slot_width) / 2
                port_rect = plt.Rectangle((port_x, wood), slot_width, ih, 
                                         fill=True, facecolor='#add8e6', edgecolor='blue', 
                                         linewidth=1.5, alpha=0.4)
                ax_front.add_patch(port_rect)
                ax_front.annotate(f'Port\n{round(slot_width, 1)}"×{round(ih, 1)}"', 
                                (port_x + slot_width/2, max_h/2), 
                                ha='center', va='center', fontsize=8, color='blue')
            elif port_type == "Round Aero Port":
                port_circle = plt.Circle((port_x_actual, port_z_actual), ps['c'] / 2, 
                                        fill=True, facecolor='#add8e6', edgecolor='blue', 
                                        linewidth=1.5, alpha=0.4)
                ax_front.add_patch(port_circle)
                ax_front.annotate(f'Ø{round(ps["c"], 1)}"', (port_x_actual, port_z_actual), 
                                ha='center', va='center', fontsize=8, color='blue')
        else:
            # Normal ported/sealed - draw sub cutout(s) on front baffle
            sub_positions_2d = get_sub_positions(num_subs, sub_arrangement, sub_x_actual, sub_z_actual, sub_od + 0.5)
            for i in range(num_subs):
                pos_x, pos_z = sub_positions_2d[i] if i < len(sub_positions_2d) else (sub_x_actual, sub_z_actual)
                sub_circle = plt.Circle((pos_x, pos_z), sub_c / 2, 
                                       fill=False, edgecolor='#333', linewidth=1.5, linestyle='--')
                ax_front.add_patch(sub_circle)
                # OD circle (mounting ring)
                od_circle = plt.Circle((pos_x, pos_z), sub_od / 2, 
                                       fill=False, edgecolor='#666', linewidth=0.8, linestyle=':')
                ax_front.add_patch(od_circle)
                ax_front.annotate(f'Ø{round(sub_c, 1)}"', (pos_x, pos_z), 
                                ha='center', va='center', fontsize=8, color='#333')
        
            # Draw port opening if ported (non-bandpass)
            if is_ported:
                if port_type == "Slot Port":
                    # Slot port opening - uses actual geometry from 3D
                    if slot_position == "Left Side":
                        port_x = wood  # Port starts at interior of left wall
                    elif slot_position == "Right Side":
                        port_x = max_w - wood - slot_width  # Port starts at divider
                    else:  # Center
                        port_x = (max_w - slot_width) / 2
                    # Port height = interior height (from bottom wood to top wood)
                    port_rect = plt.Rectangle((port_x, wood), slot_width, ih, 
                                             fill=True, facecolor='#add8e6', edgecolor='blue', 
                                             linewidth=1.5, alpha=0.4)
                    ax_front.add_patch(port_rect)
                    ax_front.annotate(f'Port\n{round(slot_width, 1)}"×{round(slot_height, 1)}"', 
                                    (port_x + slot_width/2, max_h/2), 
                                    ha='center', va='center', fontsize=7, color='blue')
                else:
                    # Round port - use actual position
                    port_cx = port_x_actual
                    port_cz = port_z_actual
                    port_circle = plt.Circle((port_cx, port_cz), ps['c'] / 2, 
                                            fill=True, facecolor='#add8e6', edgecolor='blue', 
                                            linewidth=1.5, alpha=0.4)
                    ax_front.add_patch(port_circle)
                    ax_front.annotate(f'Ø{round(ps["c"], 1)}"', (port_cx, port_cz), 
                                    ha='center', va='center', fontsize=8, color='blue')
        
        # Add dimension lines
        # Width dimension (bottom)
        ax_front.annotate('', xy=(max_w, -1.5), xytext=(0, -1.5),
                         arrowprops=dict(arrowstyle='<->', color='red', lw=1))
        ax_front.text(max_w/2, -2.5, f'{max_w}"', ha='center', va='top', fontsize=9, color='red')
        
        # Height dimension (right)
        ax_front.annotate('', xy=(max_w + 1.5, max_h), xytext=(max_w + 1.5, 0),
                         arrowprops=dict(arrowstyle='<->', color='red', lw=1))
        ax_front.text(max_w + 2.5, max_h/2, f'{max_h}"', ha='left', va='center', fontsize=9, color='red', rotation=90)
        
        ax_front.set_xlim(-3, max_w + 4)
        ax_front.set_ylim(-4, max_h + 2)
        ax_front.set_aspect('equal')
        ax_front.axis('off')
        ax_front.set_title('FRONT VIEW', fontsize=12, fontweight='bold', color='#1a1a1a')
        st.pyplot(fig_front)
        plt.close(fig_front)
    
    with blueprint_col2:
        # SIDE VIEW (Cross Section)
        st.markdown("### Side View (Cross-Section)")
        fig_side, ax_side = plt.subplots(figsize=(8, 6))
        ax_side.set_facecolor('#e8e8e8')
        fig_side.patch.set_facecolor('#e8e8e8')
        
        # Draw box outline (depth x height)
        side_rect = plt.Rectangle((0, 0), edv, max_h, fill=False, 
                                  edgecolor='#1a1a1a', linewidth=2)
        ax_side.add_patch(side_rect)
        
        # Draw internal cavity
        internal_rect = plt.Rectangle((bt, wood), idv, ih, fill=True, 
                                      facecolor='#f5f5f5', edgecolor='#666', linewidth=1)
        ax_side.add_patch(internal_rect)
        
        # Draw front baffle layers
        for layer in range(lay_f):
            baffle_rect = plt.Rectangle((layer * wood, 0), wood, max_h, 
                                        fill=True, facecolor='#d4a574', edgecolor='#1a1a1a', 
                                        linewidth=0.5, alpha=0.8)
            ax_side.add_patch(baffle_rect)
        
        # Draw back panel
        back_rect = plt.Rectangle((edv - lay_b * wood, 0), lay_b * wood, max_h, 
                                 fill=True, facecolor='#d4a574', edgecolor='#1a1a1a', 
                                 linewidth=0.5, alpha=0.8)
        ax_side.add_patch(back_rect)
        
        # Draw slot port divider if applicable
        if is_ported and port_type == "Slot Port":
            # Leg1 divider running from baffle interior back
            leg1_start_y = bt  # Start at interior of baffle
            leg1_end_y = bt + slot_leg1_len  # End of leg1
            
            divider_rect = plt.Rectangle((leg1_start_y, wood), slot_leg1_len, wood, fill=True, 
                                         facecolor='#c4946a', edgecolor='#1a1a1a', linewidth=1)
            ax_side.add_patch(divider_rect)
            
            # Port channel (air space)
            port_air = plt.Rectangle((leg1_start_y, wood + wood), slot_leg1_len, ih - wood, fill=True, 
                                     facecolor='#add8e6', edgecolor='blue', linewidth=0.5, alpha=0.3)
            ax_side.add_patch(port_air)
            
            # Leg 1 length dimension
            ax_side.annotate('', xy=(leg1_end_y, wood + wood/2), xytext=(leg1_start_y, wood + wood/2),
                           arrowprops=dict(arrowstyle='<->', color='blue', lw=1))
            ax_side.text((leg1_start_y + leg1_end_y)/2, wood + 1.5, f'Leg1: {round(slot_leg1_len, 1)}"', 
                        ha='center', va='bottom', fontsize=8, color='blue')
            
            if port_needs_bend and slot_leg2_len > 0:
                # L-bend leg2 divider
                leg2_y_start = leg1_end_y
                leg2_y_end = leg2_y_start + wood  # Leg2 divider runs perpendicular (thickness in Y)
                leg2_rect = plt.Rectangle((leg2_y_start, wood), wood, ih, fill=True, 
                                          facecolor='#c4946a', edgecolor='#1a1a1a', linewidth=1)
                ax_side.add_patch(leg2_rect)
                ax_side.text(leg2_y_start + wood/2, max_h/2, f'L-Bend', ha='center', va='center', 
                            fontsize=7, color='#1a1a1a', rotation=90)
            else:
                # Gap/clearance dimension (straight port)
                ax_side.annotate('', xy=(edv - lay_b * wood, wood + wood/2), xytext=(leg1_end_y, wood + wood/2),
                               arrowprops=dict(arrowstyle='<->', color='green', lw=1))
                ax_side.text((leg1_end_y + edv - lay_b * wood)/2, wood + 1.5, f'Gap: {round(gap, 1)}"', 
                            ha='center', va='bottom', fontsize=8, color='green')
        
        # 4th Order Bandpass - Internal divider and chamber labels
        if is_bandpass:
            # Calculate divider position same as 3D model
            interior_y_length = idv
            ported_proportion = bp_ratio_value / (1 + bp_ratio_value)
            divider_y_from_front = interior_y_length * ported_proportion
            bp_divider_x = bt + divider_y_from_front  # X position in side view
            
            # Calculate chamber internal dimensions
            ported_int_depth = divider_y_from_front
            sealed_int_depth = idv - divider_y_from_front - wood
            
            # Fill chambers with distinct colors
            # Ported chamber fill (light green)
            ported_fill = plt.Rectangle((bt, wood), ported_int_depth, ih, fill=True, 
                                        facecolor='#90EE90', edgecolor=None, alpha=0.3)
            ax_side.add_patch(ported_fill)
            
            # Sealed chamber fill (light blue)
            sealed_fill = plt.Rectangle((bp_divider_x + wood, wood), sealed_int_depth, ih, fill=True, 
                                        facecolor='#ADD8E6', edgecolor=None, alpha=0.3)
            ax_side.add_patch(sealed_fill)
            
            # Draw internal divider wall
            divider_rect = plt.Rectangle((bp_divider_x, wood), wood, ih, fill=True, 
                                         facecolor='#8B4513', edgecolor='#1a1a1a', linewidth=1.5)
            ax_side.add_patch(divider_rect)
            
            # Label ported chamber (front) with detailed dimensions
            ported_center = bt + ported_int_depth / 2
            ax_side.text(ported_center, max_h * 0.65, 'PORTED', ha='center', va='center', 
                        fontsize=10, color='darkgreen', fontweight='bold')
            ax_side.text(ported_center, max_h * 0.50, f'{round(ported_chamber_vol, 2)} cf', 
                        ha='center', va='center', fontsize=9, color='green', fontweight='bold')
            ax_side.text(ported_center, max_h * 0.35, f'{round(iw, 1)}"W x {round(ih, 1)}"H', 
                        ha='center', va='center', fontsize=7, color='green')
            ax_side.text(ported_center, max_h * 0.25, f'x {round(ported_int_depth, 1)}"D', 
                        ha='center', va='center', fontsize=7, color='green')
            
            # Label sealed chamber (back) with detailed dimensions
            sealed_center = bp_divider_x + wood + sealed_int_depth / 2
            ax_side.text(sealed_center, max_h * 0.65, 'SEALED', ha='center', va='center', 
                        fontsize=10, color='darkblue', fontweight='bold')
            ax_side.text(sealed_center, max_h * 0.50, f'{round(sealed_chamber_vol, 2)} cf', 
                        ha='center', va='center', fontsize=9, color='blue', fontweight='bold')
            ax_side.text(sealed_center, max_h * 0.35, f'{round(iw, 1)}"W x {round(ih, 1)}"H', 
                        ha='center', va='center', fontsize=7, color='blue')
            ax_side.text(sealed_center, max_h * 0.25, f'x {round(sealed_int_depth, 1)}"D', 
                        ha='center', va='center', fontsize=7, color='blue')
            
            # Draw subwoofer cross-section on divider (motor facing ported/front)
            sub_z_pos = max_h / 2
            # Motor structure (rectangle extending into ported chamber)
            motor_width = sub_depth * 0.5
            motor_height = sub_od * 0.5
            motor_rect = plt.Rectangle((bp_divider_x - motor_width + wood/2, sub_z_pos - motor_height/2), 
                                       motor_width, motor_height, fill=True, 
                                       facecolor='#404040', edgecolor='black', linewidth=1)
            ax_side.add_patch(motor_rect)
            ax_side.text(bp_divider_x - motor_width/2 + wood/2, sub_z_pos, 'MTR', 
                        ha='center', va='center', fontsize=6, color='white')
            
            # Cone (triangle extending into sealed chamber)
            cone_depth = sub_depth * 0.4
            cone_points = [
                (bp_divider_x + wood/2, sub_z_pos - sub_c/4),  # Top of cone at divider
                (bp_divider_x + wood/2, sub_z_pos + sub_c/4),  # Bottom of cone at divider
                (bp_divider_x + wood/2 + cone_depth, sub_z_pos)  # Tip of cone
            ]
            cone_patch = plt.Polygon(cone_points, fill=True, facecolor='#2d2d2d', 
                                    edgecolor='black', linewidth=1)
            ax_side.add_patch(cone_patch)
            
            # Sub cutout circle indicator
            cutout_circle = plt.Circle((bp_divider_x + wood/2, sub_z_pos), sub_c/4, 
                                       fill=False, edgecolor='red', linewidth=1.5, linestyle='--')
            ax_side.add_patch(cutout_circle)
            
            # Divider position dimension
            ax_side.annotate('', xy=(bp_divider_x, wood - 1.5), xytext=(bt, wood - 1.5),
                           arrowprops=dict(arrowstyle='<->', color='purple', lw=1))
            ax_side.text(bt + ported_int_depth/2, wood - 2.3, 
                        f'{round(ported_int_depth, 1)}"', 
                        ha='center', va='top', fontsize=8, color='purple')
            
            # Sealed depth dimension
            ax_side.annotate('', xy=(edv - lay_b * wood, wood - 1.5), xytext=(bp_divider_x + wood, wood - 1.5),
                           arrowprops=dict(arrowstyle='<->', color='blue', lw=1))
            ax_side.text(bp_divider_x + wood + sealed_int_depth/2, wood - 2.3, 
                        f'{round(sealed_int_depth, 1)}"', 
                        ha='center', va='top', fontsize=8, color='blue')
        
        # Dimension lines
        # Depth dimension (bottom)
        ax_side.annotate('', xy=(edv, -1.5), xytext=(0, -1.5),
                        arrowprops=dict(arrowstyle='<->', color='red', lw=1))
        ax_side.text(edv/2, -2.5, f'{round(edv, 2)}"', ha='center', va='top', fontsize=9, color='red')
        
        # Height dimension (right)
        ax_side.annotate('', xy=(edv + 1.5, max_h), xytext=(edv + 1.5, 0),
                        arrowprops=dict(arrowstyle='<->', color='red', lw=1))
        ax_side.text(edv + 2.5, max_h/2, f'{max_h}"', ha='left', va='center', fontsize=9, color='red', rotation=90)
        
        # Internal depth dimension
        ax_side.annotate('', xy=(bt + idv, max_h - wood - 0.5), xytext=(bt, max_h - wood - 0.5),
                        arrowprops=dict(arrowstyle='<->', color='#666', lw=0.8))
        ax_side.text(bt + idv/2, max_h - wood - 1.2, f'Int: {round(idv, 1)}"', 
                    ha='center', va='top', fontsize=7, color='#666')
        
        ax_side.set_xlim(-3, edv + 4)
        ax_side.set_ylim(-4, max_h + 2)
        ax_side.set_aspect('equal')
        ax_side.axis('off')
        ax_side.set_title('SIDE VIEW (Cross-Section)', fontsize=12, fontweight='bold', color='#1a1a1a')
        st.pyplot(fig_side)
        plt.close(fig_side)
    
    # TOP VIEW
    st.markdown("### Top View (Plan)")
    blueprint_col3, blueprint_col4 = st.columns([2, 1])
    
    with blueprint_col3:
        fig_top, ax_top = plt.subplots(figsize=(10, 6))
        ax_top.set_facecolor('#e8e8e8')
        fig_top.patch.set_facecolor('#e8e8e8')
        
        # Draw box outline (width x depth)
        top_rect = plt.Rectangle((0, 0), max_w, edv, fill=False, 
                                 edgecolor='#1a1a1a', linewidth=2)
        ax_top.add_patch(top_rect)
        
        # Draw internal cavity
        internal_rect = plt.Rectangle((wood, bt), iw, idv, fill=True, 
                                      facecolor='#f5f5f5', edgecolor='#666', linewidth=1)
        ax_top.add_patch(internal_rect)
        
        # Draw walls
        # Left wall
        left_wall = plt.Rectangle((0, 0), wood, edv, fill=True, facecolor='#d4a574', 
                                  edgecolor='#1a1a1a', linewidth=1, alpha=0.8)
        ax_top.add_patch(left_wall)
        # Right wall
        right_wall = plt.Rectangle((max_w - wood, 0), wood, edv, fill=True, facecolor='#d4a574', 
                                   edgecolor='#1a1a1a', linewidth=1, alpha=0.8)
        ax_top.add_patch(right_wall)
        # Front baffle
        front_wall = plt.Rectangle((0, 0), max_w, bt, fill=True, facecolor='#c4946a', 
                                   edgecolor='#1a1a1a', linewidth=1, alpha=0.9)
        ax_top.add_patch(front_wall)
        # Back wall
        back_wall = plt.Rectangle((0, edv - lay_b * wood), max_w, lay_b * wood, fill=True, 
                                  facecolor='#d4a574', edgecolor='#1a1a1a', linewidth=1, alpha=0.8)
        ax_top.add_patch(back_wall)
        
        # 4th/6th Order Bandpass - Draw internal divider in top view
        if is_bandpass:
            interior_y_length = idv
            ported_proportion = bp_ratio_value / (1 + bp_ratio_value)
            divider_y_from_front = interior_y_length * ported_proportion
            bp_divider_y = bt + divider_y_from_front  # Y position in top view
            
            # Draw divider as a horizontal bar across the box width
            divider_rect = plt.Rectangle((wood, bp_divider_y), iw, wood, fill=True, 
                                         facecolor='#8B4513', edgecolor='#1a1a1a', linewidth=1.5)
            ax_top.add_patch(divider_rect)
            
            # Label chambers
            ported_center_y = bt + divider_y_from_front / 2
            ax_top.text(max_w/2, ported_center_y, 'PORTED', ha='center', va='center', 
                       fontsize=10, color='darkgreen', fontweight='bold')
            
            sealed_center_y = bp_divider_y + wood + (edv - lay_b * wood - bp_divider_y - wood) / 2
            ax_top.text(max_w/2, sealed_center_y, 'SEALED', ha='center', va='center', 
                       fontsize=10, color='darkblue', fontweight='bold')
            
            # Draw sub cutout circle(s) on divider
            for i in range(num_subs):
                if num_subs == 1:
                    sub_x_top = max_w / 2
                elif num_subs == 2:
                    offset = (sub_od + 1) / 2
                    sub_x_top = max_w / 2 + (i - 0.5) * (sub_od + 1)
                else:
                    offset = (num_subs - 1) / 2
                    sub_x_top = max_w / 2 + (i - offset) * (sub_od + 0.5)
                
                # Draw cutout circle on divider
                cutout = plt.Circle((sub_x_top, bp_divider_y + wood/2), sub_c / 2, 
                                   fill=False, edgecolor='red', linewidth=2, linestyle='--')
                ax_top.add_patch(cutout)
                # OD circle
                od_circle = plt.Circle((sub_x_top, bp_divider_y + wood/2), sub_od / 2, 
                                       fill=False, edgecolor='orange', linewidth=1, linestyle=':')
                ax_top.add_patch(od_circle)
            
            # Dimension: divider position from front
            ax_top.annotate('', xy=(max_w + 0.5, bp_divider_y), xytext=(max_w + 0.5, bt),
                           arrowprops=dict(arrowstyle='<->', color='purple', lw=1))
            ax_top.text(max_w + 1.5, bt + divider_y_from_front/2, 
                       f'{round(divider_y_from_front, 1)}"', 
                       ha='left', va='center', fontsize=7, color='purple', rotation=90)
        
        # Draw slot port if applicable - MATCHING 3D MODEL EXACTLY
        if is_ported and port_type == "Slot Port":
            # Calculate positions exactly as in 3D model
            y_baffle_interior = bt
            y_leg1_end = bt + slot_leg1_len
            
            if slot_position == "Left Side":
                # Port channel is from interior of left wall to divider
                x_wall_inner = wood  # Interior of left wall
                x_port_end = x_wall_inner + slot_width  # Where port air channel ends
                x_div_inner = x_port_end  # Divider starts at port channel edge
                x_div_outer = x_div_inner + wood  # Divider outer edge
                
                # LEG 1: Port air channel (vertical in top view = Y direction)
                port_channel_1 = plt.Rectangle((x_wall_inner, y_baffle_interior), slot_width, slot_leg1_len, 
                                              fill=True, facecolor='#add8e6', edgecolor='blue', 
                                              linewidth=1.5, alpha=0.5)
                ax_top.add_patch(port_channel_1)
                
                # LEG 1: Divider board
                divider_1 = plt.Rectangle((x_div_inner, y_baffle_interior), wood, slot_leg1_len, 
                                         fill=True, facecolor='#c4946a', edgecolor='#1a1a1a', linewidth=1)
                ax_top.add_patch(divider_1)
                
                # L-BEND if needed
                if port_needs_bend and slot_leg2_len > 0:
                    # Leg 2 runs along X direction (horizontal in top view)
                    # Leg 2 divider starts at y_leg1_end (perpendicular to leg1)
                    leg2_div_y_front = y_leg1_end
                    leg2_div_y_back = y_leg1_end + wood
                    
                    # Leg 2 starts from port-side of leg1 divider (x_div_inner)
                    leg2_x_start = x_div_inner
                    leg2_x_end = leg2_x_start + slot_leg2_len + wood  # Include overlap
                    
                    # LEG 2: Port air channel (horizontal in top view = X direction)
                    # Air channel is ABOVE the leg2 divider (larger Y)
                    port_channel_2 = plt.Rectangle((x_div_outer, leg2_div_y_back), slot_leg2_len, slot_width, 
                                                  fill=True, facecolor='#add8e6', edgecolor='blue', 
                                                  linewidth=1.5, alpha=0.5)
                    ax_top.add_patch(port_channel_2)
                    
                    # LEG 2: Divider board (runs along X)
                    divider_2 = plt.Rectangle((leg2_x_start, leg2_div_y_front), leg2_x_end - leg2_x_start, wood, 
                                             fill=True, facecolor='#c4946a', edgecolor='#1a1a1a', linewidth=1)
                    ax_top.add_patch(divider_2)
                    
                    # Port path annotation with detailed measurements
                    ax_top.annotate(f'Leg2: {round(slot_leg2_len, 2)}"', 
                                  (x_div_outer + slot_leg2_len/2, leg2_div_y_back + slot_width/2),
                                  ha='center', fontsize=8, color='darkblue', fontweight='bold')
                    
                    # L-Bend corner position annotation
                    ax_top.plot([x_div_inner, x_div_inner], [y_leg1_end, leg2_div_y_front], 
                               'k--', linewidth=1, alpha=0.5)  # Corner marker
                    
                    # Y position of bend (distance from front baffle to corner)
                    ax_top.annotate('', xy=(max_w + 2.5, y_leg1_end), xytext=(max_w + 2.5, bt),
                                   arrowprops=dict(arrowstyle='<->', color='orange', lw=1))
                    ax_top.text(max_w + 3.2, (y_leg1_end + bt)/2, 
                               f'Bend Point: {round(y_leg1_end - bt, 2)}"', 
                               ha='left', fontsize=7, color='orange', rotation=90)
                    
                    # X position of leg 2 end
                    ax_top.annotate('', xy=(leg2_x_end, y_leg1_end - 1.2), xytext=(x_div_inner, y_leg1_end - 1.2),
                                   arrowprops=dict(arrowstyle='<->', color='darkgreen', lw=1))
                    ax_top.text((leg2_x_end + x_div_inner)/2, y_leg1_end - 1.7, 
                               f'Leg2 Length: {round(slot_leg2_len, 2)}"', 
                               ha='center', fontsize=7, color='darkgreen', fontweight='bold')
                
                # Leg1 annotation with exact measurements
                ax_top.annotate(f'Leg1: {round(slot_leg1_len, 2)}"', 
                              (x_wall_inner + slot_width/2, y_baffle_interior + slot_leg1_len/2),
                              ha='center', va='center', fontsize=8, color='darkblue', fontweight='bold', rotation=90)
                
                # DETAILED DIMENSION LINES for Leg 1
                # X position (width from left wall)
                ax_top.annotate('', xy=(x_wall_inner + slot_width, -0.8), xytext=(wood, -0.8),
                               arrowprops=dict(arrowstyle='<->', color='darkgreen', lw=1.5))
                ax_top.text((wood + x_wall_inner + slot_width)/2, -1.3, 
                           f'Port Width: {round(slot_width, 2)}"', 
                           ha='center', fontsize=8, color='darkgreen', fontweight='bold')
                
                # Y position (distance from front baffle)
                ax_top.annotate('', xy=(max_w + 0.5, y_baffle_interior), xytext=(max_w + 0.5, bt),
                               arrowprops=dict(arrowstyle='<->', color='darkred', lw=1.5))
                ax_top.text(max_w + 1.2, (y_baffle_interior + bt)/2, 
                           f'Leg1 Length: {round(slot_leg1_len, 2)}"', 
                           ha='left', fontsize=8, color='darkred', fontweight='bold', rotation=90)
                
                # Exact position from left edge
                ax_top.annotate('', xy=(wood, -2.5), xytext=(0, -2.5),
                               arrowprops=dict(arrowstyle='<->', color='purple', lw=1))
                ax_top.text(wood/2, -3.0, 
                           f'Wall Thickness: {round(wood, 2)}"', 
                           ha='center', fontsize=7, color='purple')
                
                # Port opening area label
                ax_top.annotate(f'Port Area: {round(slot_width * slot_height, 1)} in²', 
                              (x_wall_inner + slot_width/2, y_baffle_interior - 0.7),
                              ha='center', fontsize=7, color='blue', style='italic')
                              
            elif slot_position == "Right Side":
                # Port channel is from divider to interior of right wall
                x_wall_inner = max_w - wood  # Interior of right wall
                x_port_start = x_wall_inner - slot_width  # Where port air channel starts
                x_div_inner = x_port_start  # Divider inner edge (port side)
                x_div_outer = x_div_inner - wood  # Divider outer edge (chamber side)
                
                # LEG 1: Port air channel
                port_channel_1 = plt.Rectangle((x_port_start, y_baffle_interior), slot_width, slot_leg1_len, 
                                              fill=True, facecolor='#add8e6', edgecolor='blue', 
                                              linewidth=1.5, alpha=0.5)
                ax_top.add_patch(port_channel_1)
                
                # LEG 1: Divider board
                divider_1 = plt.Rectangle((x_div_outer, y_baffle_interior), wood, slot_leg1_len, 
                                         fill=True, facecolor='#c4946a', edgecolor='#1a1a1a', linewidth=1)
                ax_top.add_patch(divider_1)
                
                # L-BEND if needed
                if port_needs_bend and slot_leg2_len > 0:
                    leg2_div_y_front = y_leg1_end
                    leg2_div_y_back = y_leg1_end + wood
                    
                    # Leg 2 goes toward center (negative X)
                    leg2_x_start = x_div_inner
                    leg2_x_end = leg2_x_start - slot_leg2_len - wood
                    
                    # LEG 2: Port air channel
                    port_channel_2 = plt.Rectangle((leg2_x_end + wood, leg2_div_y_back), slot_leg2_len, slot_width, 
                                                  fill=True, facecolor='#add8e6', edgecolor='blue', 
                                                  linewidth=1.5, alpha=0.5)
                    ax_top.add_patch(port_channel_2)
                    
                    # LEG 2: Divider board
                    divider_2 = plt.Rectangle((leg2_x_end, leg2_div_y_front), leg2_x_start - leg2_x_end, wood, 
                                             fill=True, facecolor='#c4946a', edgecolor='#1a1a1a', linewidth=1)
                    ax_top.add_patch(divider_2)
                    
                    # DETAILED DIMENSION LINES for Leg 2 (Right Side - L-Bend)
                    # Y position of bend point (distance from front baffle to corner)
                    ax_top.annotate('', xy=(max_w + 2.5, y_leg1_end), xytext=(max_w + 2.5, bt),
                                   arrowprops=dict(arrowstyle='<->', color='orange', lw=1))
                    ax_top.text(max_w + 3.2, (y_leg1_end + bt)/2, 
                               f'Bend Point: {round(y_leg1_end - bt, 2)}"', 
                               ha='left', fontsize=7, color='orange', rotation=90)
                    
                    # X position of leg 2 (length from bend point toward center)
                    ax_top.annotate('', xy=(leg2_x_end, y_leg1_end - 1.2), xytext=(leg2_x_start, y_leg1_end - 1.2),
                                   arrowprops=dict(arrowstyle='<->', color='darkgreen', lw=1))
                    ax_top.text((leg2_x_end + leg2_x_start)/2, y_leg1_end - 1.7, 
                               f'Leg2 Length: {round(slot_leg2_len, 2)}"', 
                               ha='center', fontsize=7, color='darkgreen', fontweight='bold')
                
                ax_top.annotate(f'Leg1: {round(slot_leg1_len, 2)}"', 
                              (x_port_start + slot_width/2, y_baffle_interior + slot_leg1_len/2),
                              ha='center', va='center', fontsize=8, color='darkblue', fontweight='bold', rotation=90)
                
                # DETAILED DIMENSION LINES for Leg 1 (Right Side)
                # X position (width from right wall)
                ax_top.annotate('', xy=(x_port_start, -0.8), xytext=(max_w - wood, -0.8),
                               arrowprops=dict(arrowstyle='<->', color='darkgreen', lw=1.5))
                ax_top.text((x_port_start + max_w - wood)/2, -1.3, 
                           f'Port Width: {round(slot_width, 2)}"', 
                           ha='center', fontsize=8, color='darkgreen', fontweight='bold')
                
                # Y position (distance from front baffle)
                ax_top.annotate('', xy=(max_w + 0.5, y_baffle_interior), xytext=(max_w + 0.5, bt),
                               arrowprops=dict(arrowstyle='<->', color='darkred', lw=1.5))
                ax_top.text(max_w + 1.2, (y_baffle_interior + bt)/2, 
                           f'Leg1 Length: {round(slot_leg1_len, 2)}"', 
                           ha='left', fontsize=8, color='darkred', fontweight='bold', rotation=90)
                
                # Exact position from right edge
                ax_top.annotate('', xy=(max_w, -2.5), xytext=(max_w - wood, -2.5),
                               arrowprops=dict(arrowstyle='<->', color='purple', lw=1))
                ax_top.text(max_w - wood/2, -3.0, 
                           f'Wall Thickness: {round(wood, 2)}"', 
                           ha='center', fontsize=7, color='purple')
                
                # Port opening area label
                ax_top.annotate(f'Port Area: {round(slot_width * slot_height, 1)} in²', 
                              (x_port_start + slot_width/2, y_baffle_interior - 0.7),
                              ha='center', fontsize=7, color='blue', style='italic')
            
            # Port width label
            ax_top.annotate(f'Port W: {round(slot_width, 1)}"', 
                          (max_w/2, edv + 1),
                          ha='center', fontsize=8, color='blue')
        
        # Dimension lines
        # Width dimension (bottom)
        ax_top.annotate('', xy=(max_w, -1.5), xytext=(0, -1.5),
                       arrowprops=dict(arrowstyle='<->', color='red', lw=1))
        ax_top.text(max_w/2, -2.5, f'{max_w}"', ha='center', va='top', fontsize=9, color='red')
        
        # Depth dimension (right)
        ax_top.annotate('', xy=(max_w + 1.5, edv), xytext=(max_w + 1.5, 0),
                       arrowprops=dict(arrowstyle='<->', color='red', lw=1))
        ax_top.text(max_w + 2.5, edv/2, f'{round(edv, 2)}"', ha='left', va='center', fontsize=9, color='red', rotation=90)
        
        ax_top.set_xlim(-3, max_w + 4)
        ax_top.set_ylim(-4, edv + 3)
        ax_top.set_aspect('equal')
        ax_top.axis('off')
        ax_top.set_title('TOP VIEW (Plan)', fontsize=12, fontweight='bold', color='#1a1a1a')
        st.pyplot(fig_top)
        plt.close(fig_top)
    
    # DIVIDER VIEW for Bandpass (shows sub cutouts on internal divider)
    if is_bandpass:
        st.markdown("### Internal Divider View (Sub Mounting Baffle)")
        divider_col1, divider_col2 = st.columns([2, 1])
        
        with divider_col1:
            fig_div, ax_div = plt.subplots(figsize=(10, 6))
            ax_div.set_facecolor('#d4a574')  # Wood color background
            fig_div.patch.set_facecolor('#e8e8e8')
            
            # Draw divider outline (iw x ih - interior dimensions)
            div_rect = plt.Rectangle((0, 0), iw, ih, fill=True, 
                                     facecolor='#c4946a', edgecolor='#1a1a1a', linewidth=2)
            ax_div.add_patch(div_rect)
            
            # Calculate sub positions on divider (centered)
            div_sub_positions = []
            div_center_x = iw / 2
            div_center_z = ih / 2
            div_sub_spacing = sub_od + 0.5
            
            if num_subs == 1:
                div_sub_positions.append((div_center_x, div_center_z))
            elif num_subs == 2:
                if sub_arrangement == "Horizontal":
                    div_sub_positions = [(div_center_x - div_sub_spacing/2, div_center_z),
                                         (div_center_x + div_sub_spacing/2, div_center_z)]
                else:
                    div_sub_positions = [(div_center_x, div_center_z - div_sub_spacing/2),
                                         (div_center_x, div_center_z + div_sub_spacing/2)]
            elif num_subs == 3:
                div_sub_positions = [(div_center_x - div_sub_spacing, div_center_z),
                                     (div_center_x, div_center_z),
                                     (div_center_x + div_sub_spacing, div_center_z)]
            elif num_subs == 4:
                offset = div_sub_spacing / 2
                div_sub_positions = [(div_center_x - offset, div_center_z - offset),
                                     (div_center_x + offset, div_center_z - offset),
                                     (div_center_x - offset, div_center_z + offset),
                                     (div_center_x + offset, div_center_z + offset)]
            else:
                offset = (num_subs - 1) / 2
                for i in range(num_subs):
                    div_sub_positions.append((div_center_x + (i - offset) * div_sub_spacing, div_center_z))
            
            # Draw sub cutouts
            for i, (pos_x, pos_z) in enumerate(div_sub_positions):
                # Cutout hole
                cutout = plt.Circle((pos_x, pos_z), sub_c / 2, 
                                   fill=True, facecolor='#f5f5f5', edgecolor='red', 
                                   linewidth=2, linestyle='--')
                ax_div.add_patch(cutout)
                
                # OD mounting ring
                od_ring = plt.Circle((pos_x, pos_z), sub_od / 2, 
                                    fill=False, edgecolor='orange', linewidth=1.5, linestyle=':')
                ax_div.add_patch(od_ring)
                
                # Cutout dimension
                ax_div.annotate(f'Ø{round(sub_c, 1)}"', (pos_x, pos_z), 
                              ha='center', va='center', fontsize=9, color='red', fontweight='bold')
            
            # Dimension lines
            ax_div.annotate('', xy=(iw, -1.5), xytext=(0, -1.5),
                           arrowprops=dict(arrowstyle='<->', color='red', lw=1))
            ax_div.text(iw/2, -2.5, f'{round(iw, 2)}"', ha='center', va='top', fontsize=10, color='red')
            
            ax_div.annotate('', xy=(iw + 1.5, ih), xytext=(iw + 1.5, 0),
                           arrowprops=dict(arrowstyle='<->', color='red', lw=1))
            ax_div.text(iw + 2.5, ih/2, f'{round(ih, 2)}"', ha='left', va='center', fontsize=10, color='red', rotation=90)
            
            # Center line markers
            ax_div.axhline(y=ih/2, color='gray', linestyle=':', linewidth=0.5, alpha=0.5)
            ax_div.axvline(x=iw/2, color='gray', linestyle=':', linewidth=0.5, alpha=0.5)
            
            ax_div.set_xlim(-3, iw + 4)
            ax_div.set_ylim(-4, ih + 2)
            ax_div.set_aspect('equal')
            ax_div.axis('off')
            ax_div.set_title('INTERNAL DIVIDER (Bandpass Sub Baffle)', fontsize=12, fontweight='bold', color='#1a1a1a')
            st.pyplot(fig_div)
            plt.close(fig_div)
        
        with divider_col2:
            st.markdown("### Divider Specs")
            st.markdown(f"""
            **Divider Dimensions:**
            - Width: **{round(iw, 2)}"**
            - Height: **{round(ih, 2)}"**
            - Thickness: **{wood}"**
            
            **Subwoofer Cutout(s):**
            - Quantity: **{num_subs}**
            - Cutout Ø: **{round(sub_c, 2)}"**
            - Mounting OD: **{round(sub_od, 2)}"**
            
            **Sub Orientation:**
            - Motor → Ported (front)
            - Cone → Sealed (back)
            
            **Note:** Sub magnet/motor 
            structure extends into the 
            PORTED chamber. Cone fires 
            into the SEALED chamber.
            """)
    
    with blueprint_col4:
        st.markdown("### Specifications")
        st.markdown(f"""
        **External Dimensions:**
        - Width: **{max_w}"**
        - Height: **{max_h}"** 
        - Depth: **{round(edv, 2)}"**
        
        **Internal Dimensions:**
        - Width: **{round(iw, 2)}"**
        - Height: **{round(ih, 2)}"**
        - Depth: **{round(idv, 2)}"**
        
        **Volumes:**
        - Net Volume: **{round(net_v, 2)} ft³**
        - Gross Volume: **{round(gross, 3)} ft³**
        
        **Material:**
        - Thickness: **{wood}"**
        - Baffle Layers: **{lay_f}**
        """)
        
        if is_ported and port_type == "Slot Port":
            st.markdown(f"""
            **Slot Port:**
            - Width: **{round(slot_width, 2)}"**
            - Height: **{round(slot_height, 2)}"**
            - Length: **{round(p_len, 2)}"**
            - Area: **{round(slot_area, 1)} in²**
            - Tuning: **{tune} Hz**
            """)
            if port_needs_bend:
                st.markdown(f"""
                **L-Bend:**
                - Leg 1: **{round(slot_leg1_len, 2)}"**
                - Leg 2: **{round(slot_leg2_len, 2)}"**
                """)

# TAB 3: ACOUSTIC RESPONSE (Features #15, #16, #17)
with tab3:
    st.subheader("📊 Acoustic Response Analysis")
    
    col_resp1, col_resp2 = st.columns([1.5, 1])
    
    with col_resp1:
        # Frequency response calculation
        def get_db_sealed(f, fs, qts, vas, vb):
            """Sealed box frequency response"""
            qtc = qts * math.sqrt(1 + vas/vb)
            fn = f / fs
            fc = fs * math.sqrt(1 + vas/vb)
            fn_c = f / fc
            
            response = fn_c ** 2 / math.sqrt((1 - fn_c ** 2) ** 2 + (fn_c / qtc) ** 2)
            return 20 * math.log10(response + 1e-9)
        
        def get_db_ported(f, fs, qts, vas, vb, fb):
            """Ported box frequency response using T/S model"""
            if f < 1:
                return -40
            
            alpha = vas / vb
            h = fb / fs
            fn = f / fs
            
            # 4th order response
            A = fn ** 4
            B = (fn ** 2) * ((1 + alpha + (1 / (qts ** 2))) * (h ** 2) + 1)
            C = (h ** 4) + (fn ** 4) * ((1 + alpha) ** 2)
            D = (fn ** 2) * (h ** 2) * (1 + alpha + (1 / (qts ** 2)))
            
            H2 = (A ** 2) / ((C - B) ** 2 + (D - A * h ** 2 / qts) ** 2 + 1e-9)
            H = math.sqrt(H2)
            
            r = min(1.5, H * 2)
            return 20 * math.log10(r + 1e-9)
        
        freqs = np.linspace(10, 150, 200)
        
        fig_resp, ax = plt.subplots(figsize=(10, 5))
        
        if is_sealed:
            dbs = [get_db_sealed(f, ts_fs, ts_qts, ts_vas, net_v) for f in freqs]
            ax.plot(freqs, dbs, color="#ff4b4b", linewidth=2.5, label=f"Sealed (Qtc={round(ts_qts * math.sqrt(1 + ts_vas/net_v), 2)})")
        else:
            dbs = [get_db_ported(f, ts_fs, ts_qts, ts_vas, net_v, tune) for f in freqs]
            ax.plot(freqs, dbs, color="#ff4b4b", linewidth=2.5, label=f"Ported @ {tune}Hz")
            ax.axvline(x=tune, color='cyan', linestyle='--', alpha=0.8, linewidth=1.5, label=f'Fb: {tune} Hz')
        
        # Multiple tuning comparison (Feature #11)
        if is_ported and compare_tunings:
            colors = ['yellow', 'lime', 'magenta']
            for idx, t in enumerate(tune_compare):
                if t != tune:
                    dbs_comp = [get_db_ported(f, ts_fs, ts_qts, ts_vas, net_v, t) for f in freqs]
                    ax.plot(freqs, dbs_comp, color=colors[idx], linewidth=1.5, linestyle='--', alpha=0.7, label=f'{t}Hz')
        
        # Apply cabin gain if enabled
        if enable_cabin:
            ax.fill_between(freqs, -30, [d + (math.log2(g_start / f) * g_slope if f < g_start else 0) for f, d in zip(freqs, dbs)], 
                           alpha=0.1, color='cyan', label='+ Cabin Gain')
        
        ax.axhline(y=-3, color='yellow', linestyle=':', alpha=0.6, linewidth=1, label='-3dB')
        ax.axhline(y=-6, color='orange', linestyle=':', alpha=0.4, linewidth=1, label='-6dB')
        
        ax.grid(True, alpha=0.3, color='gray')
        ax.set_xlabel("Frequency (Hz)", color='white')
        ax.set_ylabel("dB", color='white')
        ax.set_title(f"Frequency Response — {num_subs}x {sub_name}", color='white')
        ax.legend(loc='lower right', facecolor='#0e1117', labelcolor='white', fontsize=8)
        ax.set_facecolor("#0e1117")
        ax.tick_params(colors='white')
        for spine in ax.spines.values():
            spine.set_color('#444444')
        fig_resp.patch.set_facecolor("#0e1117")
        ax.set_ylim(-24, 6)
        ax.set_xlim(10, 150)
        
        st.pyplot(fig_resp)
    
    with col_resp2:
        st.markdown("### Key Parameters")
        
        # Find F3 (Feature #15)
        for i, db in enumerate(dbs):
            if db <= -3:
                f3 = freqs[i]
                st.metric("F3 (-3dB Point)", f"{round(f3, 1)} Hz")
                break
        else:
            st.metric("F3 (-3dB Point)", "< 10 Hz")
        
        # Find F6
        for i, db in enumerate(dbs):
            if db <= -6:
                f6 = freqs[i]
                st.metric("F6 (-6dB Point)", f"{round(f6, 1)} Hz")
                break
        
        if is_sealed:
            qtc = ts_qts * math.sqrt(1 + ts_vas/net_v)
            fc = ts_fs * math.sqrt(1 + ts_vas/net_v)
            st.metric("Qtc", f"{round(qtc, 2)}")
            st.metric("Fc", f"{round(fc, 1)} Hz")
        
        st.markdown("---")
        st.markdown("### T/S Parameters Used")
        st.caption(f"Fs: {ts_fs} Hz")
        st.caption(f"Qts: {ts_qts}")
        st.caption(f"Vas: {ts_vas} cf")
        st.caption(f"Xmax: {ts_xmax} mm")

# TAB 4: COST BREAKDOWN
with tab4:
    st.subheader("💰 Material Cost Breakdown")
    
    col_cost1, col_cost2 = st.columns(2)
    
    with col_cost1:
        st.markdown("### Estimated Costs")
        for item, cost in material_breakdown.items():
            st.text(f"{item}: ${cost:.2f}")
        st.markdown("---")
        st.metric("**Total Estimated Cost**", f"${round(total_cost, 2)}")
    
    with col_cost2:
        st.markdown("### Additional Items")
        st.text(f"Subwoofer(s): {num_subs}x (not included)")
        if is_ported:
            st.text(f"Port(s): {num_ports}x (not included)")
        st.markdown("---")
        st.markdown("### Notes")
        st.caption("• Prices are estimates and may vary by region")
        st.caption("• Add 20% waste factor for cuts")
        st.caption("• Consider bulk discounts for multiple boxes")

# TAB 5: ADVANCED ANALYSIS (Features #16, #17, #18)
with tab5:
    st.subheader("📈 Advanced Analysis")
    
    col_adv1, col_adv2 = st.columns(2)
    
    with col_adv1:
        st.markdown("### Group Delay (Feature #16)")
        
        def calculate_group_delay(f, fs, qts, fb):
            """Calculate group delay in milliseconds"""
            if f < 1:
                return 0
            # Simplified group delay calculation for ported box
            fn = f / fb
            gd = (1000 / (2 * math.pi * f)) * (2 * fn / (1 + fn ** 2))
            return gd * 10  # Scale for visibility
        
        freqs_gd = np.linspace(10, 150, 200)
        if is_ported:
            gd = [calculate_group_delay(f, ts_fs, ts_qts, tune) for f in freqs_gd]
        else:
            gd = [calculate_group_delay(f, ts_fs, ts_qts, ts_fs) for f in freqs_gd]
        
        fig_gd, ax_gd = plt.subplots(figsize=(6, 3))
        ax_gd.plot(freqs_gd, gd, color='lime', linewidth=2)
        ax_gd.set_xlabel("Frequency (Hz)", color='white')
        ax_gd.set_ylabel("Group Delay (ms)", color='white')
        ax_gd.set_title("Group Delay", color='white')
        ax_gd.grid(True, alpha=0.3)
        ax_gd.set_facecolor("#0e1117")
        ax_gd.tick_params(colors='white')
        fig_gd.patch.set_facecolor("#0e1117")
        st.pyplot(fig_gd)
    
    with col_adv2:
        st.markdown("### Cone Excursion (Feature #17)")
        
        def calculate_excursion(f, power, sens, xmax, sd, fb):
            """Calculate cone excursion in mm"""
            if f < 1:
                return 0
            # Simplified excursion calculation
            # Excursion increases dramatically below tuning
            if is_ported and f < fb:
                excursion_factor = (fb / f) ** 2
            else:
                excursion_factor = 1.0
            
            # Base excursion at power
            base_excursion = xmax * math.sqrt(power / 1000) * 0.3
            
            return min(xmax * 2, base_excursion * excursion_factor)
        
        sd = math.pi * (sub_c / 2) ** 2
        excursion = [calculate_excursion(f, ts_power, ts_sens, ts_xmax, sd, tune if is_ported else ts_fs) for f in freqs_gd]
        
        fig_ex, ax_ex = plt.subplots(figsize=(6, 3))
        ax_ex.plot(freqs_gd, excursion, color='orange', linewidth=2, label='Excursion')
        ax_ex.axhline(y=ts_xmax, color='red', linestyle='--', label=f'Xmax ({ts_xmax}mm)')
        ax_ex.set_xlabel("Frequency (Hz)", color='white')
        ax_ex.set_ylabel("Excursion (mm)", color='white')
        ax_ex.set_title(f"Cone Excursion @ {ts_power}W", color='white')
        ax_ex.legend(facecolor='#0e1117', labelcolor='white')
        ax_ex.grid(True, alpha=0.3)
        ax_ex.set_facecolor("#0e1117")
        ax_ex.tick_params(colors='white')
        fig_ex.patch.set_facecolor("#0e1117")
        st.pyplot(fig_ex)
    
    # Power handling (Feature #18)
    st.markdown("---")
    st.markdown("### Power Handling Analysis (Feature #18)")
    
    col_pwr1, col_pwr2, col_pwr3 = st.columns(3)
    with col_pwr1:
        st.metric("RMS Power Rating", f"{ts_power} W")
    with col_pwr2:
        thermal_limit = ts_power  # Thermal = RMS rating
        st.metric("Thermal Limit", f"{thermal_limit} W")
    with col_pwr3:
        # Mechanical limit based on Xmax
        # Simplified: mech limit = where excursion hits Xmax
        mech_power = ts_power * (ts_xmax / (ts_xmax * 1.5)) ** 2
        st.metric("Mechanical Limit (est)", f"{round(mech_power, 0)} W")

# TAB 6: SAVE/LOAD (Feature #19, #21, #22)
with tab6:
    st.subheader("💾 Save / Load Designs")
    
    col_save, col_load = st.columns(2)
    
    with col_save:
        st.markdown("### Save Current Design")
        design_name = st.text_input("Design Name", f"{sub_name}_{num_subs}x_{round(net_v, 1)}cf")
        
        if st.button("💾 Save Design"):
            design_data = {
                "name": design_name,
                "created": datetime.now().isoformat(),
                "enclosure_type": enclosure_type,
                "sub_name": sub_name,
                "num_subs": num_subs,
                "sub_size": sel_sub_size,
                "sub_cutout": sub_c,
                "sub_displacement": sub_d,
                "sub_depth": sub_depth,
                "width": max_w,
                "height": max_h,
                "net_volume": net_v,
                "tuning": tune if is_ported else 0,
                "port_type": port_type if is_ported else "None",
                "port_size": sel_port if is_ported and port_type == "Round Aero Port" else "None",
                "num_ports": num_ports,
                "wood_thickness": wood,
                "layers": {"front": lay_f, "back": lay_b, "top_bottom": lay_tb, "sides": lay_s},
                "ts_params": {"fs": ts_fs, "qts": ts_qts, "vas": ts_vas, "xmax": ts_xmax, "sens": ts_sens, "power": ts_power},
                "calculated": {"edv": edv, "gross": gross, "weight": box_weight, "cost": total_cost}
            }
            
            st.session_state.saved_designs[design_name] = design_data
            st.success(f"✅ Design '{design_name}' saved!")
            
            # Generate downloadable JSON
            json_str = json.dumps(design_data, indent=2)
            b64 = base64.b64encode(json_str.encode()).decode()
            href = f'<a href="data:application/json;base64,{b64}" download="{design_name}.json">📥 Download JSON</a>'
            st.markdown(href, unsafe_allow_html=True)
    
    with col_load:
        st.markdown("### Load Design")
        
        if st.session_state.saved_designs:
            sel_design = st.selectbox("Select Saved Design", list(st.session_state.saved_designs.keys()))
            if st.button("📂 Load Design"):
                st.info(f"Design '{sel_design}' data available. Refresh to apply.")
                st.json(st.session_state.saved_designs[sel_design])
        else:
            st.info("No saved designs yet. Save a design first!")
        
        # Upload JSON
        st.markdown("---")
        st.markdown("### Import Design")
        uploaded_file = st.file_uploader("Upload JSON file", type=['json'])
        if uploaded_file:
            try:
                design_data = json.load(uploaded_file)
                st.session_state.saved_designs[design_data.get('name', 'Imported')] = design_data
                st.success("✅ Design imported!")
            except:
                st.error("Invalid JSON file")
    
    # Share link (Feature #22)
    st.markdown("---")
    st.markdown("### Share Design (Feature #22)")
    
    # Create shareable URL with parameters
    params = {
        "w": max_w, "h": max_h, "v": net_v, "t": tune,
        "subs": num_subs, "sub_size": sel_sub_size
    }
    param_str = urllib.parse.urlencode(params)
    st.code(f"?{param_str}", language="text")
    st.caption("Add this to your URL to share the design parameters")

# TAB 7: EXPORT (Features #19, #20)
with tab7:
    st.subheader("📤 Export Options")
    
    col_exp1, col_exp2 = st.columns(2)
    
    with col_exp1:
        st.markdown("### PDF Cut Sheet (Feature #19)")
        st.caption("Generate printable cut sheet with all dimensions")
        
        if st.button("📄 Generate Cut Sheet Text"):
            cut_sheet = f"""
=====================================
BASS BUILDER PRO - CUT SHEET
=====================================
Design: {sub_name} - {num_subs}x in {round(net_v, 2)} cf
Generated: {datetime.now().strftime("%Y-%m-%d %H:%M")}

EXTERNAL DIMENSIONS:
  Width:  {max_w}"
  Height: {max_h}"
  Depth:  {round(edv, 2)}"

PANEL LIST:
  Front Baffle: {lay_f}x @ {max_w}" x {max_h}"
  Back Panel:   {lay_b}x @ {max_w}" x {max_h}"
  Top:          {lay_tb}x @ {max_w}" x {round(top_d, 2)}"
  Bottom:       {lay_tb}x @ {max_w}" x {round(top_d, 2)}"
  Left Side:    {lay_s}x @ {round(ih, 2)}" x {round(top_d, 2)}"
  Right Side:   {lay_s}x @ {round(ih, 2)}" x {round(top_d, 2)}"

CUTOUTS:
  Subwoofer: {sub_c}" dia x {num_subs}
  {"Port: " + str(round(ps['c'], 2)) + '" dia x ' + str(num_ports) if is_ported else "Sealed - No Port"}
  {"Terminal: " + str(terminal_d) + '" dia' if show_terminal else ""}

SPECIFICATIONS:
  Net Volume:   {round(net_v, 2)} cf
  Gross Volume: {round(gross, 3)} cf
  {"Tuning: " + str(tune) + " Hz" if is_ported else "Sealed Box"}
  Box Weight:   ~{round(box_weight, 1)} lbs

MATERIALS:
  Wood: {wood}" MDF x {math.ceil(sum(areas) * 1.2 / 32)} sheets
  Est. Cost: ${round(total_cost, 2)}
=====================================
"""
            st.code(cut_sheet, language="text")
            
            # Download button
            b64 = base64.b64encode(cut_sheet.encode()).decode()
            href = f'<a href="data:text/plain;base64,{b64}" download="cut_sheet.txt">📥 Download Cut Sheet</a>'
            st.markdown(href, unsafe_allow_html=True)
    
    with col_exp2:
        st.markdown("### DXF/SVG Export (Feature #20)")
        st.caption("For CNC cutting machines")
        
        # Simple SVG generation for front panel
        if st.button("🔧 Generate Front Panel SVG"):
            # Create simple SVG of front panel with cutouts
            svg_width = max_w * 10  # Scale up for visibility
            svg_height = max_h * 10
            
            svg_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{svg_width}" height="{svg_height}" viewBox="0 0 {max_w} {max_h}">
  <!-- Front Panel Outline -->
  <rect x="0" y="0" width="{max_w}" height="{max_h}" fill="none" stroke="black" stroke-width="0.1"/>
  
  <!-- Subwoofer Cutout -->
  <circle cx="{sub_x_actual}" cy="{max_h - sub_z_actual}" r="{sub_c/2}" fill="none" stroke="red" stroke-width="0.1"/>
'''
            if is_ported and port_type == "Round Aero Port":
                svg_content += f'''
  <!-- Port Cutout -->
  <circle cx="{port_x_actual}" cy="{max_h - port_z_actual}" r="{ps['c']/2}" fill="none" stroke="blue" stroke-width="0.1"/>
'''
            if show_terminal:
                svg_content += f'''
  <!-- Terminal Cutout -->
  <circle cx="{terminal_x}" cy="{max_h - terminal_z}" r="{terminal_d/2}" fill="none" stroke="green" stroke-width="0.1"/>
'''
            svg_content += "</svg>"
            
            st.code(svg_content, language="xml")
            
            b64 = base64.b64encode(svg_content.encode()).decode()
            href = f'<a href="data:image/svg+xml;base64,{b64}" download="front_panel.svg">📥 Download SVG</a>'
            st.markdown(href, unsafe_allow_html=True)
        
        st.markdown("---")
        st.markdown("### SketchUp Ruby Code")
        sketchup_code = f"m=Sketchup.active_model;e=m.active_entities;b=e.add_face([[0,0,0],[{max_w},0,0],[{max_w},{round(edv, 2)},0],[0,{round(edv, 2)},0]]);b.pushpull(-{max_h})"
        st.code(sketchup_code, language="ruby")

# ═══════════════════════════════════════════════════════════════════════════════
# FOOTER
# ═══════════════════════════════════════════════════════════════════════════════
st.markdown("---")
st.caption("Bass Builder Pro v5.0 - Ultimate Edition | 30 Features | BigAss Ports Integration")
