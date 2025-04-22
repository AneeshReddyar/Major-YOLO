from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import numpy as np
from PIL import Image
import io
import os
import uuid
from ultralytics import YOLO
import cv2

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend access

# Create folders for saving images
os.makedirs("static", exist_ok=True)
os.makedirs("uploads", exist_ok=True)

# Load YOLOv8 model
try:
    model = YOLO("yolov8_crop_weed.pt")  # Update with your model path
    print("✅ YOLOv8 model loaded successfully!")
    
    # Class names
    class_names = ['crop', 'weed']  # Update with your actual class names
    
except Exception as e:
    print(f"❌ Error loading YOLOv8 model: {str(e)}")
    model = None

@app.route("/predict", methods=["POST"])
def predict():
    if model is None:
        return jsonify({"error": "Model not loaded"}), 500

    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    try:
        # Read and save uploaded image
        image_file = request.files["image"]
        image_bytes = image_file.read()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        
        # Generate unique filename
        filename = f"{uuid.uuid4().hex}.jpg"
        upload_path = os.path.join("uploads", filename)
        image.save(upload_path)
        
        # Run YOLOv8 inference
        results = model(upload_path)
        result = results[0]  # Get first result
        
        # Save the result image with detections
        result_image = result.plot()
        result_image_rgb = cv2.cvtColor(result_image, cv2.COLOR_BGR2RGB)
        result_filename = f"detected_{filename}"
        result_path = os.path.join("static", result_filename)
        Image.fromarray(result_image_rgb).save(result_path)
        
        # Prepare response data
        detections = []
        for box, cls, conf in zip(result.boxes.xyxy.tolist(), 
                                 result.boxes.cls.tolist(),
                                 result.boxes.conf.tolist()):
            x1, y1, x2, y2 = box
            class_id = int(cls)
            confidence = float(conf)
            class_name = class_names[class_id]
            
            detections.append({
                "class": class_name,
                "confidence": confidence,
                "bbox": [x1, y1, x2, y2]
            })
        
        # Return results
        return jsonify({
            "detections": detections,
            "image_url": f"/static/{result_filename}",
            "detection_count": len(detections)
        })

    except Exception as e:
        return jsonify({"error": f"Failed to process image: {str(e)}"}), 500

@app.route("/static/<filename>")
def serve_image(filename):
    return send_file(f"static/{filename}", mimetype="image/jpeg")

@app.route("/health", methods=["GET"])
def health_check():
    if model is None:
        return jsonify({"status": "error", "message": "Model not loaded"}), 500
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
    
# For Vercel to handle the Flask app
def handler(request, context):
    return app(request, context)
