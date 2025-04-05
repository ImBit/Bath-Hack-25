from fastapi import FastAPI, UploadFile, File, Form, BackgroundTasks
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from typing import List
import os
import uuid
import shutil
import json
import importlib
import sys
from pathlib import Path
import subprocess

app = FastAPI(title="Animal Detection API")

# Add CORS to allow requests from your Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for testing
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create folders for storage
UPLOAD_DIR = Path("uploaded_images")
RESULTS_DIR = Path("results")
UPLOAD_DIR.mkdir(exist_ok=True)
RESULTS_DIR.mkdir(exist_ok=True)

@app.get("/")
async def root():
    return {"message": "Animal Detection API is running"}

@app.post("/detect-animals")
async def detect_animals(
    background_tasks: BackgroundTasks,
    files: List[UploadFile] = File(...)
):
    # Create a unique session ID for this request
    session_id = str(uuid.uuid4())
    session_dir = UPLOAD_DIR / session_id
    session_dir.mkdir(exist_ok=True)
    
    # Save uploaded files
    saved_files = []
    for file in files:
        file_path = session_dir / file.filename
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        saved_files.append(str(file_path))
    
    # Path for results
    results_path = RESULTS_DIR / f"{session_id}.json"
    
    # Run the detection in the background
    background_tasks.add_task(
        run_detection_model,
        session_dir,
        results_path
    )
    
    return {
        "message": "Images uploaded successfully and processing has started",
        "session_id": session_id,
        "status_endpoint": f"/detection-status/{session_id}"
    }

@app.get("/detection-status/{session_id}")
async def get_detection_status(session_id: str):
    results_path = RESULTS_DIR / f"{session_id}.json"
    
    if not results_path.exists():
        return {"status": "processing"}
    
    with open(results_path, "r") as f:
        results = json.load(f)
    
    # Check if there was an error
    if "error" in results:
        return {
            "status": "error",
            "error": results["error"]
        }
    
    # Process results to make them more user-friendly
    formatted_results = []
    if "predictions" in results:
        print(f"Raw predictions: {results['predictions']}")  # Debug log
        
        for prediction in results["predictions"]:
            filepath = prediction["filepath"]
            filename = os.path.basename(filepath)
            
            print(f"Processing prediction for file: {filepath}, basename: {filename}")  # Debug log
            
            # Extract animal name from prediction
            animal_name = "Unknown"
            if prediction["prediction"] and isinstance(prediction["prediction"], str):
                pred_parts = prediction["prediction"].split(';')
                print(f"Prediction parts: {pred_parts}")  # Debug log
                
                if len(pred_parts) >= 7:
                    animal_name = pred_parts[6]
                    print(f"Extracted animal name: {animal_name}")  # Debug log
            
            formatted_results.append({
                "filename": filename,
                "original_path": filepath,
                "animal": animal_name,
                "confidence": prediction.get("confidence", 0)
            })
    
    print(f"Formatted results: {formatted_results}")  # Debug log
    return {
        "status": "complete",
        "results": formatted_results,
        "debug": {
            "raw_predictions_count": len(results.get("predictions", [])),
            "formatted_results_count": len(formatted_results)
        }
    }

def run_detection_model(input_dir: Path, output_path: Path):
    """Run the animal detection model on the input images"""
    try:
        # Method 1: Try using subprocess to run the command directly
        # This is more reliable than importing Python modules dynamically
        cmd = [
            "python",
            "-m",
            "speciesnet.scripts.run_model",
            "--folders", str(input_dir),
            "--predictions_json", str(output_path)
        ]
        
        print(f"Running command: {' '.join(cmd)}")
        process = subprocess.run(
            cmd, 
            capture_output=True, 
            text=True
        )
        
        if process.returncode != 0:
            print(f"Command failed with return code: {process.returncode}")
            print(f"Error output: {process.stderr}")
            
            # Create error output JSON
            with open(output_path, "w") as f:
                json.dump({
                    "error": process.stderr,
                    "predictions": []
                }, f)
            return
            
        print(f"Command output: {process.stdout}")
        
        # If the command ran but didn't generate a results file, create an empty one
        if not output_path.exists():
            print("Command ran but no output file was created")
            with open(output_path, "w") as f:
                json.dump({
                    "error": "Command completed but no output file was generated",
                    "predictions": []
                }, f)
        
    except Exception as e:
        print(f"Error running detection model: {e}")
        # Create error output
        with open(output_path, "w") as f:
            json.dump({
                "error": str(e),
                "predictions": []
            }, f)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)