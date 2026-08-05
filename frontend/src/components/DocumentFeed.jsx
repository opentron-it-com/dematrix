import React, { useState } from 'react';
import { api } from '../services/api';

export const DocumentFeed = ({ documents, filterText, setFilterText, selectedDocIds, toggleDocumentSelection, deleteSelectedIds, toggleDeleteSelection, handleDeleteDocuments, isDeleting, theme, onUploadClick }) => {
  const filteredDocuments = documents.filter(doc => 
    doc.fileName.toLowerCase().includes(filterText.toLowerCase())
  );

  const handleSelectAllChat = () => {
    const allSelected = selectedDocIds.length === filteredDocuments.length && filteredDocuments.length > 0;
    filteredDocuments.forEach(doc => {
      const docId = doc.documentId || doc.id;
      if (allSelected && selectedDocIds.includes(docId)) {
        // Deselect all
        toggleDocumentSelection(docId);
      } else if (!allSelected && !selectedDocIds.includes(docId)) {
        // Select all
        toggleDocumentSelection(docId);
      }
    });
  };

  const handleSelectAllDelete = () => {
    const allSelected = deleteSelectedIds.length === filteredDocuments.length && filteredDocuments.length > 0;
    filteredDocuments.forEach(doc => {
      const docId = doc.documentId || doc.id;
      if (allSelected && deleteSelectedIds.includes(docId)) {
        // Deselect all
        toggleDeleteSelection(docId);
      } else if (!allSelected && !deleteSelectedIds.includes(docId)) {
        // Select all
        toggleDeleteSelection(docId);
      }
    });
  };

  const allChatSelected = selectedDocIds.length === filteredDocuments.length && filteredDocuments.length > 0;
  const allDeleteSelected = deleteSelectedIds.length === filteredDocuments.length && filteredDocuments.length > 0;

  return (
    <>
      <header style={{ background: theme.bgSecondary, borderBottom: `1px solid ${theme.border}`, padding: '24px 32px' }}>
        <div style={{ marginBottom: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 700, color: theme.text }}>Document Analysis Feed</h1>
            <p style={{ margin: '4px 0 0 0', fontSize: '14px', color: theme.textSecondary }}>
              Showing {filteredDocuments.length} of {documents.length} documents 
              {selectedDocIds.length > 0 && ` • ${selectedDocIds.length} selected for chat`}
              {deleteSelectedIds.length > 0 && ` • ${deleteSelectedIds.length} selected for delete`}
            </p>
          </div>
          <button onClick={onUploadClick} style={{ padding: '10px 16px', background: theme.accent, color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 600 }}>
            📤 Upload
          </button>
        </div>
        
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap' }}>
          <input
            type="text"
            placeholder="🔍 Filter by document name..."
            value={filterText}
            onChange={(e) => setFilterText(e.target.value)}
            style={{ flex: 1, minWidth: '200px', padding: '10px 12px', border: `1px solid ${theme.border}`, borderRadius: '6px', fontSize: '13px', background: theme.bg, color: theme.text }}
          />
          
          <button
            onClick={handleSelectAllChat}
            style={{ padding: '10px 14px', background: allChatSelected ? theme.accent : theme.bgTertiary, color: allChatSelected ? 'white' : theme.text, border: `1px solid ${theme.border}`, borderRadius: '6px', cursor: 'pointer', fontWeight: 600, fontSize: '13px', whiteSpace: 'nowrap' }}
            title="Select all for chat"
          >
            ✓ All Chat ({selectedDocIds.length})
          </button>

          {deleteSelectedIds.length > 0 && (
            <button
              onClick={handleDeleteDocuments}
              disabled={isDeleting}
              style={{ padding: '10px 14px', background: '#f44336', color: 'white', border: 'none', borderRadius: '6px', cursor: isDeleting ? 'not-allowed' : 'pointer', fontWeight: 600, fontSize: '13px', opacity: isDeleting ? 0.6 : 1, whiteSpace: 'nowrap' }}
            >
              🗑️ Delete ({deleteSelectedIds.length})
            </button>
          )}

          {deleteSelectedIds.length === 0 && (
            <button
              onClick={handleSelectAllDelete}
              style={{ padding: '10px 14px', background: allDeleteSelected ? '#f44336' : theme.bgTertiary, color: allDeleteSelected ? 'white' : theme.text, border: `1px solid ${theme.border}`, borderRadius: '6px', cursor: 'pointer', fontWeight: 600, fontSize: '13px', whiteSpace: 'nowrap' }}
              title="Select all for delete"
            >
              ✕ All Delete ({deleteSelectedIds.length})
            </button>
          )}
        </div>
      </header>

      <div style={{ flex: 1, background: theme.bgSecondary, borderRadius: '8px', padding: '16px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {filteredDocuments.length === 0 && documents.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '60px 40px', color: theme.textSecondary }}>
            <p>📄 No documents analyzed yet</p>
            <button onClick={onUploadClick} style={{ marginTop: '16px', padding: '8px 16px', background: theme.accent, color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer' }}>
              Upload
            </button>
          </div>
        ) : filteredDocuments.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px', color: theme.textSecondary }}>
            <p>🔍 No documents match "{filterText}"</p>
          </div>
        ) : (
          filteredDocuments.map((doc) => {
            const docId = doc.documentId || doc.id;
            const isSelected = selectedDocIds.includes(docId);
            const isDeleteSelected = deleteSelectedIds.includes(docId);

            return (
              <div 
                key={docId} 
                style={{ background: theme.bgTertiary, border: `2px solid ${isDeleteSelected ? '#f44336' : isSelected ? theme.accent : theme.border}`, borderRadius: '8px', padding: '16px', transition: 'all 0.2s', flexShrink: 0, display: 'flex', gap: '12px', alignItems: 'flex-start' }}
              >
                {/* Chat selection checkbox */}
                <button
                  onClick={() => toggleDocumentSelection(docId)}
                  style={{ flex: 0, padding: '6px 8px', background: 'none', border: `2px solid ${isSelected ? theme.accent : '#ccc'}`, borderRadius: '4px', cursor: 'pointer', fontSize: '14px', color: isSelected ? theme.accent : '#999', fontWeight: 600, minWidth: '28px', height: '28px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
                  title="Select for chat"
                >
                  {isSelected ? '✓' : ''}
                </button>

                {/* Document info */}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <h3 style={{ margin: '0 0 4px 0', fontSize: '16px', fontWeight: 700, color: theme.text }}>{doc.fileName}</h3>
                  <p style={{ margin: 0, fontSize: '12px', color: theme.textSecondary }}>📊 {doc.chunkCount} chunks • {doc.status}</p>
                </div>

                {/* Delete checkbox */}
                <button
                  onClick={() => toggleDeleteSelection(docId)}
                  style={{ flex: 0, padding: '6px 8px', background: 'none', border: `2px solid ${isDeleteSelected ? '#f44336' : '#ccc'}`, borderRadius: '4px', cursor: 'pointer', fontSize: '14px', color: isDeleteSelected ? '#f44336' : '#999', fontWeight: 600, minWidth: '28px', height: '28px', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s' }}
                  title="Select for delete"
                >
                  {isDeleteSelected ? '✕' : ''}
                </button>
              </div>
            );
          })
        )}
      </div>
    </>
  );
};
