# 💊 SchedRx - Prescription Reader App

![App Banner](https://via.placeholder.com/800x200/1a73e8/ffffff?text=SchedRx+-+Smart+Prescription+Management) <!-- Replace with actual banner image -->

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
| ![Home](https://via.placeholder.com/300x600/ffffff/1a73e8?text=Home+Screen) *Home* | ![Add Meds](https://via.placeholder.com/300x600/ffffff/1a73e8?text=Add+Medicine) *Add Medicine* | ![Schedule](https://via.placeholder.com/300x600/ffffff/1a73e8?text=Schedule) *Schedule* |
| ![List](https://via.placeholder.com/300x600/ffffff/1a73e8?text=Medicine+List) *Medicine List* | ![Details](https://via.placeholder.com/300x600/ffffff/1a73e8?text=Details) *Details* | ![Tracking](https://via.placeholder.com/300x600/ffffff/1a73e8?text=Tracking) *Tracking* |

## 🛠️ Installation
### Backend Setup
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload