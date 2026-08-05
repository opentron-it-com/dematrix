import React, { useState, useRef } from 'react';
import { useDocumentUpload } from '../hooks/useDocumentUpload';
import './DocumentDropzone.css';

export const DocumentDropzone = ({ onDocumentProcessed }) => {
  const [isDragOver, setIsDragOver] = useState(false);
  const [uploadQueue, setUploadQueue] = useState([]);
  const [currentUploadIndex, setCurrentUploadIndex] = useState(0);
  const { uploadDocument, isLoading, uploadProgress, error } = useDocumentUpload();
  const fileInputRef = useRef(null);

  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragOver(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragOver(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragOver(false);

    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFileSelection(files);
    }
  };

  const handleFileChange = (e) => {
    const files = e.target.files;
    if (files.length > 0) {
      handleFileSelection(files);
    }
  };

  const handleFileSelection = (fileList) => {
    const newFiles = Array.from(fileList).map((file) => ({
      file,
      title: file.name.replace(/\.[^/.]+$/, ''),
      status: 'pending',
      progress: 0,
      id: Math.random()
    }));

    const updatedQueue = [...uploadQueue, ...newFiles];
    setUploadQueue(updatedQueue);

    // Start upload if not already uploading
    if (!isLoading && uploadQueue.length === 0) {
      processNextUpload(updatedQueue, 0);
    }
  };

  const processNextUpload = async (queue, index) => {
    if (index >= queue.length) {
      setCurrentUploadIndex(0);
      return;
    }

    const item = queue[index];
    setCurrentUploadIndex(index);

    try {
      console.log(`Uploading file ${index + 1}/${queue.length}: ${item.file.name}`);
      
      const response = await uploadDocument(item.file, item.title);
      console.log('Upload successful:', response);
      
      // Update queue item status
      const updatedQueue = [...queue];
      updatedQueue[index] = { ...item, status: 'completed', progress: 100 };
      setUploadQueue(updatedQueue);
      
      onDocumentProcessed(response);

      // Process next file
      processNextUpload(updatedQueue, index + 1);
    } catch (err) {
      console.error('Upload error:', err);
      const updatedQueue = [...queue];
      updatedQueue[index] = { ...item, status: 'error' };
      setUploadQueue(updatedQueue);

      // Continue with next file even if this one failed
      processNextUpload(updatedQueue, index + 1);
    }
  };

  const removeFromQueue = (id) => {
    const filtered = uploadQueue.filter(item => item.id !== id);
    setUploadQueue(filtered);
    if (filtered.length > 0 && !isLoading) {
      processNextUpload(filtered, currentUploadIndex < filtered.length ? currentUploadIndex : 0);
    }
  };

  const handleClickDropzone = () => {
    console.log('Dropzone clicked, opening file picker');
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  const isProcessing = isLoading || uploadQueue.length > 0;
  const completedCount = uploadQueue.filter(item => item.status === 'completed').length;
  const errorCount = uploadQueue.filter(item => item.status === 'error').length;

  return (
    <div className="dropzone-container">
      <div
        className={`dropzone ${isDragOver ? 'drag-over' : ''} ${isProcessing ? 'loading' : ''}`}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onClick={handleClickDropzone}
        role="button"
        tabIndex="0"
      >
        {isProcessing ? (
          <div className="upload-progress">
            <div className="spinner"></div>
            <p>Processing {currentUploadIndex + 1} of {uploadQueue.length}</p>
            <p style={{ fontSize: '12px', marginTop: '8px', opacity: 0.7 }}>
              ✓ {completedCount} completed {errorCount > 0 ? `• ✕ ${errorCount} failed` : ''}
            </p>
          </div>
        ) : (
          <>
            <svg className="upload-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
              <polyline points="17 8 12 3 7 8"></polyline>
              <line x1="12" y1="3" x2="12" y2="15"></line>
            </svg>
            <h3>Drop documents here</h3>
            <p>or click to browse (multiple files supported)</p>
          </>
        )}
        <input
          ref={fileInputRef}
          type="file"
          onChange={handleFileChange}
          accept=".pdf,.txt"
          multiple
          className="file-input"
          disabled={isProcessing}
          aria-label="Upload documents"
        />
      </div>

      {uploadQueue.length > 0 && (
        <div className="upload-queue">
          <div className="queue-header">
            <h4>Upload Queue ({uploadQueue.length})</h4>
            {!isProcessing && uploadQueue.length > 0 && (
              <button
                onClick={() => setUploadQueue([])}
                style={{ fontSize: '12px', padding: '4px 8px', cursor: 'pointer' }}
              >
                Clear All
              </button>
            )}
          </div>
          <div className="queue-items">
            {uploadQueue.map((item, idx) => (
              <div key={item.id} className={`queue-item queue-item-${item.status}`}>
                <div className="queue-item-info">
                  <div className="queue-item-name">
                    {idx === currentUploadIndex && isLoading ? (
                      <span className="uploading-indicator">↻</span>
                    ) : item.status === 'completed' ? (
                      <span className="status-icon">✓</span>
                    ) : item.status === 'error' ? (
                      <span className="status-icon error">✕</span>
                    ) : (
                      <span className="status-icon pending">◯</span>
                    )}
                    {item.file.name}
                  </div>
                  <div className="queue-item-size">
                    {(item.file.size / 1024 / 1024).toFixed(2)} MB
                  </div>
                </div>
                {idx === currentUploadIndex && isLoading && (
                  <div className="queue-item-progress">
                    <div className="progress-bar">
                      <div
                        className="progress-fill"
                        style={{ width: `${uploadProgress}%` }}
                      ></div>
                    </div>
                    <div className="progress-text">{Math.round(uploadProgress)}%</div>
                  </div>
                )}
                {!isProcessing && (
                  <button
                    onClick={() => removeFromQueue(item.id)}
                    className="queue-item-remove"
                    title="Remove from queue"
                  >
                    ✕
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {error && <div className="error-message">{error}</div>}
    </div>
  );
};
