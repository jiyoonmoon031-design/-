# -
An AI-powered mobile platform that diagnoses crop diseases from images and provides farm-level monitoring and analysis.


# CropCare AI

AI-powered mobile platform for crop disease detection and farm monitoring using plant images.

## Overview
CropCare AI is a capstone project that helps users diagnose crop diseases from plant images and monitor disease trends across farm zones.

The system is designed as a mobile application with the following goals:
- Detect crop diseases from uploaded or captured plant images
- Visualize disease regions and explain AI predictions
- Provide treatment recommendations and disease information
- Store diagnosis history by farm and zone
- Analyze disease trends through a dashboard
- Improve user engagement with a mascot-based attendance feature

---

## Key Features

### 1. Diagnosis
- Plant image upload or camera capture
- Image quality check before inference
- Disease classification
- Disease region detection
- Severity estimation
- Confidence display
- Grad-CAM visualization
- Treatment recommendation
- Disease detail page

### 2. History Management
- Diagnosis record storage
- Search and filter by date, crop, disease, and zone
- Action status tracking
  - Pending
  - Completed

### 3. Analytics Dashboard
- Severity trend analysis
- Disease frequency analysis
- Crop-wise disease analysis
- Zone-based disease map
- Risk zone highlighting
- Alert notifications

### 4. User Experience
- Mascot character
- Daily attendance check
- Mascot growth system

---

## Tech Stack

### Mobile App
- Flutter

### Backend
- FastAPI

### AI / ML
- Python
- PyTorch
- OpenCV
- YOLO / Classification Model
- Grad-CAM

### Database
- TBD

---

## Project Structure

```text
cropcare-ai/
├── mobile/          # Flutter app
├── backend/         # API server
├── ai/              # Model training and inference
├── data/            # Dataset metadata / preprocessing scripts
├── docs/            # Project documents
└── README.md
