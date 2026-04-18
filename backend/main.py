from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import uvicorn
import numpy as np
from PIL import Image
import io
import os
import logging
import base64

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Nail Checker AI API", description="API untuk deteksi penyakit kuku menggunakan YOLO dan EfficientNet")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)

# --- Model Paths ---
YOLO_MODEL_PATH = "models/yolo_model.pt"
EFFNET_MODEL_PATH = "models/effnet_model.keras"

# --- Classes (Sesuaikan urutannya dengan urutan saat training / class_indices) ---
CLASSES = [
    "Acral Lentiginous Melanoma",
    "Blue Finger",
    "Clubbing",
    "Kuku Sehat",
    "Onychogryphosis",
    "Onychomycosis",
    "Pitting",
    "Onycholysis",
    "Psoriasis",
    "Beau's line"
]

# --- Global Variables for Models ---
yolo_model = None
effnet_model = None

@app.on_event("startup")
async def load_models():
    global yolo_model, effnet_model
    
    # Buat folder models jika belum ada
    os.makedirs("models", exist_ok=True)
    
    # Load YOLO Model
    try:
        from ultralytics import YOLO
        if os.path.exists(YOLO_MODEL_PATH):
            yolo_model = YOLO(YOLO_MODEL_PATH)
            logger.info("YOLO model loaded successfully.")
        else:
            logger.warning(f"YOLO model not found at {YOLO_MODEL_PATH}. Tolong masukkan file .pt kamu ke folder models/")
    except Exception as e:
        logger.error(f"Error loading YOLO: {e}")

    # Load EfficientNet Model
    try:
        import tensorflow as tf
        if os.path.exists(EFFNET_MODEL_PATH):
            effnet_model = tf.keras.models.load_model(EFFNET_MODEL_PATH)
            logger.info("EfficientNet model loaded successfully.")
        else:
            logger.warning(f"EfficientNet model not found at {EFFNET_MODEL_PATH}. Tolong masukkan file .keras kamu ke folder models/")
    except Exception as e:
        logger.error(f"Error loading EfficientNet: {e}")


@app.get("/")
def read_root():
    return {
        "message": "Nail Checker AI Backend is running!",
        "yolo_loaded": yolo_model is not None,
        "effnet_loaded": effnet_model is not None
    }


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    # 1. Validasi Models
    if yolo_model is None or effnet_model is None:
        raise HTTPException(status_code=500, detail="Model belum siap. Pastikan file model ada di folder models/")

    try:
        # 2. Baca Gambar
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        
        # 3. Proses YOLO (Mencari Kuku)
        # Lakukan deteksi
        results = yolo_model.predict(image, conf=0.2, verbose=False)
        
        detected_nails = []
        
        if len(results) > 0 and len(results[0].boxes) > 0:
            logger.info(f"Terdeteksi {len(results[0].boxes)} kuku dalam gambar.")
            
            # 4. Looping setiap kuku yang terdeteksi
            for i, box_data in enumerate(results[0].boxes):
                # Ambil koordinat bounding box
                box = box_data.xyxy[0].cpu().numpy() # [x1, y1, x2, y2]
                x1, y1, x2, y2 = map(int, box)
                
                # Potong (Crop) gambar hanya pada area kuku ini
                cropped_image = image.crop((x1, y1, x2, y2))
                
                # Konversi cropped image ke base64
                try:
                    buffered = io.BytesIO()
                    cropped_image.save(buffered, format="JPEG")
                    img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
                except Exception as b64_err:
                    logger.error(f"Error encoding image to base64: {b64_err}")
                    img_str = "" # Fallback jika gagal encode

                # Proses EfficientNet (Klasifikasi Penyakit)
                try:
                    target_size = (260, 260)
                    processed_image = cropped_image.resize(target_size)
                    img_array = np.array(processed_image).astype('float32')
                    
                    # Tambahkan dimensi batch
                    img_array = np.expand_dims(img_array, axis=0)
                    
                    # Prediksi
                    predictions = effnet_model.predict(img_array)
                    logger.info(f"DEBUG: Raw Predictions: {predictions[0]}")
                    
                    predicted_class_index = np.argmax(predictions[0])
                    confidence = float(predictions[0][predicted_class_index])
                    
                    predicted_label = CLASSES[predicted_class_index] if predicted_class_index < len(CLASSES) else "Unknown"
                    
                    # Simpan hasil untuk kuku ini
                    detected_nails.append({
                        "nail_index": i + 1,
                        "box": {"x1": x1, "y1": y1, "x2": x2, "y2": y2},
                        "prediction": predicted_label,
                        "confidence": round(confidence * 100, 2),
                        "cropped_image_base64": img_str
                    })
                except Exception as eff_err:
                    logger.error(f"Error during EfficientNet prediction for nail {i+1}: {eff_err}")
                    continue # Lewati kuku ini jika gagal klasifikasi
                
            return JSONResponse({
                "status": "success",
                "total_nails_detected": len(detected_nails),
                "results": detected_nails,
                "message": f"Berhasil menganalisis {len(detected_nails)} kuku."
            })
            
        else:
            logger.warning("Tidak ada kuku yang terdeteksi oleh YOLO.")
            return JSONResponse({
                "status": "success",
                "total_nails_detected": 0,
                "results": [],
                "message": "Tidak ada kuku yang terdeteksi pada gambar."
            })

    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        logger.error(f"Error during prediction:\n{error_details}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
