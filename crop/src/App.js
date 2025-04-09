import React, { useState } from "react";
import "./App.css";

const App = () => {
  const [image, setImage] = useState(null);
  const [preview, setPreview] = useState(null);
  const [detections, setDetections] = useState(null);
  const [loading, setLoading] = useState(false);
  const serverUrl = process.env.REACT_APP_SERVER_URL || "http://127.0.0.1:5000"; 

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImage(file);
      setPreview(URL.createObjectURL(file));
      setDetections(null);
    }
  };

  const handleSubmit = async () => {
    if (!image) {
      alert("Please select an image first!");
      return;
    }

    setLoading(true);

    const formData = new FormData();
    formData.append("image", image);

    try {
      const response = await fetch(`${serverUrl}/predict`, {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`Server error: ${response.statusText}`);
      }

      const data = await response.json();
      setDetections(data);
    } catch (error) {
      console.error("Error:", error);
      alert("Error in prediction. Check server!");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app-container">
      <h1>Crop & Weed Detection</h1>
      <p className="subtitle">Powered by YOLOv8</p>
      
      <div className="upload-section">
        <label className="upload-button">
          Upload Image
          <input type="file" accept="image/*" onChange={handleFileChange} />
        </label>
        
        {preview && (
          <div className="preview-container">
            <h3>Input Image</h3>
            <img src={preview} alt="Preview" className="preview-image" />
            <button 
              onClick={handleSubmit} 
              className="detect-button"
              disabled={loading}
            >
              {loading ? "Processing..." : "Detect"}
            </button>
          </div>
        )}
      </div>

      {detections && (
        <div className="results-container">
          <h3>Detection Results</h3>
          <div className="results-grid">
            <div className="detection-image">
              <img 
                src={`${serverUrl}${detections.image_url}`} 
                alt="Detection Result" 
              />
            </div>
            
            <div className="detection-info">
              <h4>Objects Detected: {detections.detection_count}</h4>
              <div className="detections-list">
                {detections.detections.map((item, index) => (
                  <div key={index} className="detection-item">
                    <div className={`class-tag ${item.class.toLowerCase()}`}>
                      {item.class}
                    </div>
                    <div className="confidence">
                      Confidence: {(item.confidence * 100).toFixed(2)}%
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default App;
