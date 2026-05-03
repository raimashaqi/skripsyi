from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from typing import List
import uvicorn
import numpy as np
from PIL import Image
import io
import os
import logging
import base64
import cv2
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
    "Beau's line",
    "Onycholysis",
    "Psoriasis"
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


def VizGradCAMBBfix(model, image, threshold=0.5):
    import tensorflow as tf
    from tensorflow.keras.models import Model

    # image is a PIL Image object. Convert to RGB numpy array.
    img_rgb = np.array(image).astype('uint8')
    img_resized = cv2.resize(img_rgb, (260, 260))
    img_tensor = tf.cast(np.expand_dims(img_resized, axis=0), tf.float32)

    base_model = model.get_layer('efficientnetb2')
    target_layer = base_model.get_layer('block7b_add') 

    with tf.GradientTape() as tape:
        gradient_model = Model([base_model.input], [target_layer.output, base_model.output])
        conv_outputs, base_pred = gradient_model(img_tensor)
        
        # In newer Keras versions, base_model.output might be returned as a list containing the tensor
        if isinstance(base_pred, list):
            base_pred = base_pred[0]
        
        # Pass through the rest of the outer model
        x = model.get_layer('global_average_pooling2d')(base_pred)
        x = model.get_layer('batch_normalization')(x)
        x = model.get_layer('gaussian_noise')(x, training=False)
        x = model.get_layer('dropout')(x, training=False)
        prediction = model.get_layer('dense')(x)
        
        pred_idx = tf.argmax(prediction[0])
        loss = prediction[:, pred_idx]

    grads = tape.gradient(loss, conv_outputs)
    guided_grads = tf.cast(grads > 0, "float32") * tf.cast(conv_outputs > 0, "float32") * grads
    weights = tf.reduce_mean(guided_grads[0], axis=(0, 1))
    
    heatmap = np.dot(conv_outputs[0], weights[..., np.newaxis])
    heatmap = np.squeeze(heatmap)
    heatmap = np.maximum(heatmap, 0)
    
    denominator = np.max(heatmap) - np.min(heatmap)
    if denominator == 0:
        denominator = 1e-10
    heatmap = (heatmap - np.min(heatmap)) / denominator
    
    heatmap_res = cv2.resize(np.uint8(255 * heatmap), (260, 260))
    heatmap_color = cv2.applyColorMap(heatmap_res, cv2.COLORMAP_JET)
    
    # img_resized is RGB, but heatmap_color is BGR. 
    # Convert img_resized to BGR so we can mix them and return a BGR image.
    img_bgr = cv2.cvtColor(img_resized, cv2.COLOR_RGB2BGR)
    
    final_img = cv2.addWeighted(img_bgr, 0.5, heatmap_color, 0.5, 0)

    _, thresh = cv2.threshold(heatmap_res, int(255 * threshold), 255, cv2.THRESH_BINARY)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    for contour in contours:
        if cv2.contourArea(contour) > 500:
            x, y, w, h = cv2.boundingRect(contour)
            cv2.rectangle(final_img, (x, y), (x + w, y + h), (0, 255, 0), 2)
            
    return final_img

@app.post("/predict")
async def predict(files: List[UploadFile] = File(...)):
    # 1. Validasi Models
    if yolo_model is None or effnet_model is None:
        raise HTTPException(status_code=500, detail="Model belum siap. Pastikan file model ada di folder models/")

    try:
        all_detected_nails = []
        
        for file in files:
            logger.info(f"Memproses file: {file.filename}")
            # 2. Baca Gambar
            contents = await file.read()
            image = Image.open(io.BytesIO(contents)).convert("RGB")
            
            # 3. Proses YOLO (Mencari Kuku)
            # Lakukan deteksi
            results = yolo_model.predict(image, conf=0.2, verbose=False)
            
            if len(results) > 0 and len(results[0].boxes) > 0:
                logger.info(f"Terdeteksi {len(results[0].boxes)} kuku dalam gambar {file.filename}.")
                
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
                        
                        predicted_class_index = np.argmax(predictions[0])
                        confidence = float(predictions[0][predicted_class_index])
                        
                        predicted_label = CLASSES[predicted_class_index] if predicted_class_index < len(CLASSES) else "Unknown"
                        
                        gradcam_str = ""
                        try:
                            # Generate Grad-CAM BGR array
                            gradcam_bgr = VizGradCAMBBfix(effnet_model, processed_image)
                            # Convert BGR back to RGB for PIL
                            gradcam_rgb = cv2.cvtColor(gradcam_bgr, cv2.COLOR_BGR2RGB)
                            gradcam_pil = Image.fromarray(gradcam_rgb)
                            buffered_gc = io.BytesIO()
                            gradcam_pil.save(buffered_gc, format="JPEG")
                            gradcam_str = base64.b64encode(buffered_gc.getvalue()).decode("utf-8")
                        except Exception as gc_err:
                            logger.error(f"Error generating Grad-CAM: {gc_err}")
                        
                        # Simpan hasil untuk kuku ini
                        all_detected_nails.append({
                            "nail_index": len(all_detected_nails) + 1,
                            "filename": file.filename,
                            "box": {"x1": x1, "y1": y1, "x2": x2, "y2": y2},
                            "prediction": predicted_label,
                            "confidence": round(confidence * 100, 2),
                            "cropped_image_base64": img_str,
                            "gradcam_image_base64": gradcam_str
                        })
                    except Exception as eff_err:
                        logger.error(f"Error during EfficientNet prediction for nail in {file.filename}: {eff_err}")
                        continue 
            else:
                logger.warning(f"Tidak ada kuku yang terdeteksi oleh YOLO pada {file.filename}.")

        return JSONResponse({
            "status": "success",
            "total_nails_detected": len(all_detected_nails),
            "results": all_detected_nails,
            "message": f"Berhasil menganalisis {len(all_detected_nails)} kuku dari {len(files)} gambar."
        })

    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        logger.error(f"Error during prediction:\n{error_details}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
