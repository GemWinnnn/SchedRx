# 💊 SchedRx - Prescription Reader App

![App Banner](images/iconlogo.png)
## 📖 Overview
This iOS application automates the parsing of printed prescriptions using the **Med7 model**, specifically tailored for the **Philippine context**. It extracts key details including:
- 💊 Medication & supplements
- ⚖️ Dosage & strength
- 🔄 Frequency & duration
- 📅 Intake tracking

Built with a **Python backend** and **Flutter frontend**, featuring a clean hospital-inspired UI designed for accessibility.

## ✨ Key Features
| Feature | Description |
|---------|-------------|
| 🖼️ **Image Parsing** | Extract text from prescription images using OCR |
| 🤖 **Med7 Integration** | AI-powered medicine information extraction |
| 🇵🇭 **Localized Dataset** | Philippine-specific medicines from Philstats |
| 🔥 **Firebase Sync** | Real-time medicine intake tracking |
| 🏥 **Clean UI** | Distraction-free hospital-inspired design |

## 🖼️ Screenshots
| | | |
|:-------------------------:|:-------------------------:|:-------------------------:|
| ![Home](images/simulator_screenshot_D8357A96-E590-4929-AF85-7BD815DA38C9.png) *Home* | ![Add Meds](images/simulator_screenshot_FB3D1DFB-5015-48FF-92B3-871AC085FD1C.png) *Add Medicine* | ![Schedule](images/simulator_screenshot_DC8E64CD-6613-48A3-8E9F-BD07DC0DB4F1.png) *Schedule* |
| ![List](https://via.placeholder.com/300x600/ffffff/1a73e8?text=Medicine+List) *Medicine List* | ![Details](images/simulator_screenshot_C86AF964-E65D-42D1-A552-F152EB627F5C.png) *Details* | ![Tracking](images/simulator_screenshot_299C01B5-D373-466A-914D-72FBDB82034C.png) *Tracking* |

## 🛠️ Installation
### Backend Setup
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload