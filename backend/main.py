from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
import os
import shutil
from parser import PrescriptionParser

app = FastAPI()

UPLOAD_DIR = "images"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Create a global parser instance
parser = PrescriptionParser("datasets/combined_drug_names.csv")

@app.get("/")
def read_root():
    return {"message": "Prescription Parser Backend is running."}

@app.post("/parse-prescription")
async def parse_prescription_endpoint(file: UploadFile = File(...)):
    try:
        # Save uploaded file
        file_path = os.path.join(UPLOAD_DIR, file.filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        # Parse the image
        results = parser.parse_prescription(file_path)
        return results
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

@app.get("/reload-drugs")
def reload_drugs():
    parser.drug_names = parser.load_drug_names("/Users/gemwincanete/Documents/prescription_parser/datasets/combined_drug_names.csv")
    return {
        "message": "✅ Drug list reloaded successfully!",
        "count": len(parser.drug_names)
    } 