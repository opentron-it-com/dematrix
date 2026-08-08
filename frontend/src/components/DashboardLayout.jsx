import React, { useState, useEffect, useRef } from 'react';
import { DocumentDropzone } from './DocumentDropzone';
import { DocumentFeed } from './DocumentFeed';
import RenderRequirementMessage from './RenderRequirementMessage';
import { api } from '../services/api';

export const DashboardLayout = () => {
  const [documents, setDocuments] = useState([]);
  const [selectedDocIdsReq, setSelectedDocIdsReq] = useState([]);
  const [deleteSelectedIdsReq, setDeleteSelectedIdsReq] = useState([]);
  const [filterTextReq, setFilterTextReq] = useState('');
  const [selectedDocIdsCand, setSelectedDocIdsCand] = useState([]);
  const [deleteSelectedIdsCand, setDeleteSelectedIdsCand] = useState([]);
  const [filterTextCand, setFilterTextCand] = useState('');
  const [selectedDocIds, setSelectedDocIds] = useState([]);
  const [isDeleting, setIsDeleting] = useState(false);
  const [showUpload, setShowUpload] = useState(false);
  const [uploadSide, setUploadSide] = useState('requirements');
  const [page, setPage] = useState('feed');
  const [chatMessages, setChatMessages] = useState([]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);
  const [matchingResults, setMatchingResults] = useState(null);
  const [isMatching, setIsMatching] = useState(false);
  const [loadingDocs, setLoadingDocs] = useState(true);
  const [currentPage, setCurrentPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [totalDocs, setTotalDocs] = useState(0);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [entities, setEntities] = useState(null);
  const [stats, setStats] = useState(null);
  const [settings, setSettings] = useState(null);
  const [savingSettings, setSavingSettings] = useState(false);
  const [documentsTags, setDocumentsTags] = useState({});

  const DOCUMENT_TAGS_STORAGE_KEY = 'enterprise-doc-analyzer-document-tags';

  const getPersistedDocumentTags = () => {
    if (typeof window === 'undefined') return {};
    try {
      const stored = localStorage.getItem(DOCUMENT_TAGS_STORAGE_KEY);
      return stored ? JSON.parse(stored) : {};
    } catch (err) {
      console.warn('Could not read persisted document tags:', err);
      return {};
    }
  };

  const persistDocumentTags = (tags) => {
    if (typeof window === 'undefined') return;
    try {
      localStorage.setItem(DOCUMENT_TAGS_STORAGE_KEY, JSON.stringify(tags));
    } catch (err) {
      console.warn('Could not persist document tags:', err);
    }
  };

  const theme = settings?.darkTheme ? {
    bg: '#1a1a1a', bgSecondary: '#2d2d2d', bgTertiary: '#3a3a3a', text: '#e0e0e0',
    textSecondary: '#b0b0b0', border: '#404040', accent: '#1a9b71', accentLight: '#2ab886',
    error: '#ff6b6b', success: '#51cf66'
  } : {
    bg: '#f5f5f5', bgSecondary: 'white', bgTertiary: '#f0f0f0', text: '#1a1a1a',
    textSecondary: '#666', border: '#e0e0e0', accent: '#1a9b71', accentLight: '#2ab886',
    error: '#c62828', success: '#1a9b71'
  };

  const getDocumentType = (value) => {
    if (!value) return null;
    const lower = value.toLowerCase();
    if (lower.includes('cv') || lower.includes('resume') || lower.includes('vita')) return 'candidates';
    if (lower.includes('job') || lower.includes('requirement') || lower.includes('spec')) return 'requirements';
    return null;
  };

  useEffect(() => { loadDocuments(0, true); loadAnalytics(); loadSettings(); }, []);
  useEffect(() => { setSelectedDocIds([...selectedDocIdsReq, ...selectedDocIdsCand]); }, [selectedDocIdsReq, selectedDocIdsCand]);

  const loadAnalytics = async () => {
    try {
      const [entitiesRes, statsRes] = await Promise.all([fetch(api.analytics.entities), fetch(api.analytics.stats)]);
      if (entitiesRes.ok) setEntities(await entitiesRes.json());
      if (statsRes.ok) setStats(await statsRes.json());
    } catch (err) { console.error('Error loading analytics:', err); }
  };

  const loadSettings = async () => {
    try {
      const res = await fetch(api.settings);
      if (res.ok) setSettings(await res.json());
    } catch (err) { console.error('Error loading settings:', err); }
  };

  const handleSaveSettings = async () => {
    if (!settings) return;
    setSavingSettings(true);
    try {
      const res = await fetch(api.settings, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(settings) });
      if (res.ok) alert('Settings saved!');
      else alert('Error saving settings');
    } catch (err) { alert('Error: ' + err.message); }
    finally { setSavingSettings(false); }
  };

  const loadDocuments = async (pageNum, reset = false) => {
    try {
      const response = await fetch(`${api.documents.list}?page=${pageNum}&size=20`, { method: 'GET', headers: { 'Content-Type': 'application/json' } });
      if (!response.ok) { setLoadingDocs(false); return; }
      const data = await response.json();
      const docs = data.documents || [];
      const persistedTags = getPersistedDocumentTags();
      const newTags = { ...persistedTags };
      docs.forEach(doc => {
        const id = doc.documentId || doc.id;
        const persistedType = persistedTags[id];
        const inferredType = getDocumentType(doc.fileName) || getDocumentType(doc.title);
        if (persistedType) newTags[id] = persistedType;
        else if (inferredType) newTags[id] = inferredType;
      });
      persistDocumentTags(newTags);
      if (reset || pageNum === 0) { setDocuments(docs); setDocumentsTags(newTags); }
      else { setDocuments(prev => [...prev, ...docs]); setDocumentsTags(prev => ({ ...prev, ...newTags })); }
      setCurrentPage(pageNum);
      setTotalDocs(data.totalElements || 0);
      setHasMore(data.hasMore || false);
    } catch (err) { console.error('Error loading documents:', err); if (reset) setDocuments([]); }
    finally { setLoadingDocs(false); setIsLoadingMore(false); }
  };

  const handleDocumentProcessed = (doc, side) => {
    const normalizedDoc = {
      ...doc,
      id: doc?.id || doc?.documentId || `doc-${Date.now()}`,
      documentId: doc?.documentId || doc?.id || `doc-${Date.now()}`,
    };
    const id = normalizedDoc.documentId || normalizedDoc.id;

    setDocuments(prev => [normalizedDoc, ...prev]);
    setDocumentsTags(prevTags => {
      const nextTags = { ...prevTags, [id]: side };
      persistDocumentTags(nextTags);
      return nextTags;
    });
    setShowUpload(false);
    setTotalDocs(prev => prev + 1);
    loadAnalytics();
  };

  const toggleDocumentSelectionReq = (docId) => { setSelectedDocIdsReq(prev => prev.includes(docId) ? prev.filter(id => id !== docId) : [...prev, docId]); };
  const toggleDeleteSelectionReq = (docId) => { setDeleteSelectedIdsReq(prev => prev.includes(docId) ? prev.filter(id => id !== docId) : [...prev, docId]); };

  const handleDeleteDocumentsReq = async () => {
    if (deleteSelectedIdsReq.length === 0) return;
    if (!window.confirm(`Delete ${deleteSelectedIdsReq.length} document(s)?`)) return;
    setIsDeleting(true);
    try {
      const res = await fetch(api.documents.deleteMultiple, { method: 'DELETE', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ documentIds: deleteSelectedIdsReq }) });
      if (res.ok) {
        setDocuments(prev => prev.filter(d => !deleteSelectedIdsReq.includes(d.documentId || d.id)));
        setDeleteSelectedIdsReq([]);
        setSelectedDocIdsReq(prev => prev.filter(id => !deleteSelectedIdsReq.includes(id)));
        const newTags = { ...documentsTags };
        deleteSelectedIdsReq.forEach(id => delete newTags[id]);
        setDocumentsTags(newTags);
        persistDocumentTags(newTags);
        loadAnalytics();
      }
    } catch (err) { alert('Error deleting documents: ' + err.message); }
    finally { setIsDeleting(false); }
  };

  const toggleDocumentSelectionCand = (docId) => { setSelectedDocIdsCand(prev => prev.includes(docId) ? prev.filter(id => id !== docId) : [...prev, docId]); };
  const toggleDeleteSelectionCand = (docId) => { setDeleteSelectedIdsCand(prev => prev.includes(docId) ? prev.filter(id => id !== docId) : [...prev, docId]); };

  const handleDeleteDocumentsCand = async () => {
    if (deleteSelectedIdsCand.length === 0) return;
    if (!window.confirm(`Delete ${deleteSelectedIdsCand.length} document(s)?`)) return;
    setIsDeleting(true);
    try {
      const res = await fetch(api.documents.deleteMultiple, { method: 'DELETE', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ documentIds: deleteSelectedIdsCand }) });
      if (res.ok) {
        setDocuments(prev => prev.filter(d => !deleteSelectedIdsCand.includes(d.documentId || d.id)));
        setDeleteSelectedIdsCand([]);
        setSelectedDocIdsCand(prev => prev.filter(id => !deleteSelectedIdsCand.includes(id)));
        const newTags = { ...documentsTags };
        deleteSelectedIdsCand.forEach(id => delete newTags[id]);
        setDocumentsTags(newTags);
        persistDocumentTags(newTags);
        loadAnalytics();
      }
    } catch (err) { alert('Error deleting documents: ' + err.message); }
    finally { setIsDeleting(false); }
  };

  const handleFindMatches = async () => {
    if (selectedDocIdsReq.length === 0 || selectedDocIdsCand.length === 0) { alert('Select both requirements and candidates'); return; }
    setIsMatching(true);
    try {
      const res = await fetch(api.documents.match, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ requirementIds: selectedDocIdsReq, candidateIds: selectedDocIdsCand }) });
      if (res.ok) {
        const data = await res.json();
        const messages = [{ type: 'system', text: `🎯 Found ${data.matches ? data.matches.length : 0} CV-to-Requirement Matches` }];
        if (data.matches && data.matches.length > 0) {
          data.matches.forEach((match) => {
            messages.push({ type: 'match', text: '', match: match, requirement: match.requirementName, candidate: match.candidateName, score: match.matchPercentage || (match.matchScore * 100).toFixed(0), matched: match.matchedSkills || [], missing: match.missingSkills || [], reasoning: match.reasoning || 'Match analysis' });
          });
        }
        setChatMessages(messages);
      }
    } catch (err) { alert('Error: ' + err.message); }
    finally { setIsMatching(false); }
  };

  const handleChatSubmit = async () => {
    if (!chatInput.trim() || selectedDocIds.length === 0) return;
    const userMessage = chatInput;
    const assistantMessageId = `assistant-${Date.now()}`;
    setChatInput('');
    const selectedDocNames = documents.filter(d => selectedDocIds.includes(d.documentId || d.id)).map(d => d.fileName).join(', ');
    setChatMessages(prev => [...prev, { type: 'user', text: userMessage, docContext: selectedDocNames }, { id: assistantMessageId, type: 'assistant', text: '' }]);
    setChatLoading(true);

    const appendAssistantChunk = (chunk) => {
      if (!chunk) return;
      setChatMessages(prev => prev.map(msg => msg.id === assistantMessageId ? { ...msg, text: `${msg.text}${chunk}` } : msg));
    };

    const setAssistantError = (message) => {
      setChatMessages(prev => prev.map(msg => msg.id === assistantMessageId ? { ...msg, type: 'error', text: `Error: ${message}` } : msg));
    };

    const processSseLine = (line) => {
      const trimmedLine = line.trim();
      if (!trimmedLine.startsWith('data:')) return;
      const data = JSON.parse(trimmedLine.slice(5).trim());
      if (data.error) throw new Error(data.error);
      appendAssistantChunk(data.chunk);
    };
    
    try {
      const res = await fetch(api.chat.stream, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ query: userMessage, conversationId: `conv-${Date.now()}`, contextLimit: 5, documentIds: selectedDocIds, comprehensiveAnalysis: selectedDocIdsReq.length > 0 && selectedDocIdsCand.length === 0 }) });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const contentType = res.headers.get('content-type') || '';
      if (contentType.includes('application/json')) { const data = await res.json(); if (data.error) throw new Error(data.error); appendAssistantChunk(data.chunk); return; }
      if (!res.body) throw new Error('No response body');
      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';
        for (const line of lines) processSseLine(line);
      }
      if (buffer.trim()) processSseLine(buffer);
    } catch (err) { console.error('Chat error:', err); setAssistantError(err.message); }
    finally { setChatLoading(false); }
  };

  const filterRequirements = () => documents.filter(d => { const tag = documentsTags[d.documentId || d.id]; return tag === 'requirements' || (tag === undefined && getDocumentType(d.fileName) === 'requirements'); });
  const filterCandidates = () => documents.filter(d => { const tag = documentsTags[d.documentId || d.id]; return tag === 'candidates' || (tag === undefined && getDocumentType(d.fileName) === 'candidates'); });

  return (
    <div style={{ display: 'flex', height: '100vh', background: theme.bg, fontFamily: 'Arial, sans-serif', color: theme.text }}>
      <main style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {page === 'feed' && (
          <div style={{ display: 'flex', flexDirection: 'column', flex: 1, overflow: 'hidden' }}>
            {showUpload && <div style={{ background: theme.bgSecondary, padding: '16px 32px', borderBottom: `1px solid ${theme.border}` }}><DocumentDropzone onDocumentProcessed={(doc) => handleDocumentProcessed(doc, uploadSide)} /></div>}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 320px', gap: '24px', padding: '24px 32px', flex: 1, overflow: 'hidden' }}>
              <div style={{ display: 'flex', flexDirection: 'column', overflow: 'hidden', minWidth: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}><h2 style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: theme.text }}>📋 Client Requirements</h2><button onClick={() => { setShowUpload(!showUpload); setUploadSide('requirements'); }} style={{ padding: '6px 12px', background: theme.accent, color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 600, fontSize: '12px' }}>{showUpload && uploadSide === 'requirements' ? '✕ Close' : '📤'}</button></div>
                <DocumentFeed documents={filterRequirements()} filterText={filterTextReq} setFilterText={setFilterTextReq} selectedDocIds={selectedDocIdsReq} toggleDocumentSelection={toggleDocumentSelectionReq} deleteSelectedIds={deleteSelectedIdsReq} toggleDeleteSelection={toggleDeleteSelectionReq} handleDeleteDocuments={handleDeleteDocumentsReq} isDeleting={isDeleting} theme={theme} onUploadClick={() => { setShowUpload(!showUpload); setUploadSide('requirements'); }} />
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', overflow: 'hidden', minWidth: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}><h2 style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: theme.text }}>👥 Candidates</h2><button onClick={() => { setShowUpload(!showUpload); setUploadSide('candidates'); }} style={{ padding: '6px 12px', background: theme.accent, color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 600, fontSize: '12px' }}>{showUpload && uploadSide === 'candidates' ? '✕ Close' : '📤'}</button></div>
                <DocumentFeed documents={filterCandidates()} filterText={filterTextCand} setFilterText={setFilterTextCand} selectedDocIds={selectedDocIdsCand} toggleDocumentSelection={toggleDocumentSelectionCand} deleteSelectedIds={deleteSelectedIdsCand} toggleDeleteSelection={toggleDeleteSelectionCand} handleDeleteDocuments={handleDeleteDocumentsCand} isDeleting={isDeleting} theme={theme} onUploadClick={() => { setShowUpload(!showUpload); setUploadSide('candidates'); }} />
              </div>
              <div style={{ background: theme.bgSecondary, border: `1px solid ${theme.border}`, borderRadius: '8px', padding: '16px', overflowY: 'auto', display: 'flex', flexDirection: 'column' }}>
                <h3 style={{ margin: '0 0 16px 0', fontSize: '14px', fontWeight: 600, color: theme.text }}>System Status 🟢</h3>
                <div style={{ fontSize: '12px', color: theme.textSecondary, flex: 1 }}>
                  <div style={{ marginBottom: '16px', paddingBottom: '12px', borderBottom: `1px solid ${theme.border}` }}><div style={{ fontWeight: 600, color: theme.text, marginBottom: '4px' }}>Total Documents</div><div>{documents.length} / {totalDocs} loaded</div></div>
                  <div style={{ marginBottom: '16px', paddingBottom: '12px', borderBottom: `1px solid ${theme.border}` }}><div style={{ fontWeight: 600, color: theme.text, marginBottom: '4px' }}>Requirements</div><div>{filterRequirements().length}</div></div>
                  <div style={{ marginBottom: '16px', paddingBottom: '12px', borderBottom: `1px solid ${theme.border}` }}><div style={{ fontWeight: 600, color: theme.text, marginBottom: '4px' }}>Candidates</div><div>{filterCandidates().length}</div></div>
                  <div style={{ marginBottom: '16px', paddingBottom: '12px', borderBottom: `1px solid ${theme.border}` }}><div style={{ fontWeight: 600, color: theme.text, marginBottom: '4px' }}>Req. Selected</div><div>{selectedDocIdsReq.length}</div></div>
                  <div style={{ marginBottom: '16px', paddingBottom: '12px', borderBottom: `1px solid ${theme.border}` }}><div style={{ fontWeight: 600, color: theme.text, marginBottom: '4px' }}>Cand. Selected</div><div>{selectedDocIdsCand.length}</div></div>
                  <div style={{ marginBottom: '12px' }}><div style={{ fontWeight: 600, color: theme.text }}>Chat Selection</div><div>{selectedDocIds.length} total</div></div>
                  <div><div style={{ fontWeight: 600, color: theme.text }}>Vector Search</div><div>Ready</div></div>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>

      {selectedDocIds.length > 0 && (
        <div style={{ position: 'fixed', right: 0, top: 0, width: '480px', height: '100vh', background: theme.bgSecondary, borderLeft: `1px solid ${theme.border}`, display: 'flex', flexDirection: 'column', zIndex: 1000, boxShadow: '-2px 0 12px rgba(0,0,0,0.08)' }}>
          <div style={{ padding: '20px', borderBottom: `1px solid ${theme.border}`, display: 'flex', justifyContent: 'space-between' }}>
            <div><h2 style={{ margin: 0, fontSize: '14px', color: theme.accent }}>🧬 adesso</h2><h3 style={{ margin: '4px 0 0 0', fontSize: '18px', fontWeight: 700, color: theme.text }}>Multi-Document Chat</h3><p style={{ margin: '2px 0 0 0', fontSize: '12px', color: theme.textSecondary }}>{selectedDocIds.length} document{selectedDocIds.length !== 1 ? 's' : ''} selected</p><div style={{ marginTop: '8px', display: 'flex', flexWrap: 'wrap', gap: '4px' }}>{documents.filter(d => selectedDocIds.includes(d.documentId || d.id)).map(d => <span key={d.documentId || d.id} style={{ fontSize: '11px', background: theme.accent, color: 'white', padding: '2px 8px', borderRadius: '3px' }}>{d.fileName}</span>)}</div></div>
            <button onClick={() => { setSelectedDocIdsReq([]); setSelectedDocIdsCand([]); setChatMessages([]); }} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', color: theme.textSecondary }}>✕</button>
          </div>
          <div style={{ flex: 1, padding: '20px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {chatMessages.length === 0 ? (
              <div style={{ textAlign: 'center', color: theme.textSecondary, marginTop: '40px' }}><p style={{ fontSize: '14px' }}>Ask questions about the selected documents...</p></div>
            ) : (
              chatMessages.map((msg, idx) => (
                <div key={idx}>
                  {msg.type === 'system' ? (
                    <div style={{ textAlign: 'center', padding: '16px 12px', background: theme.bgTertiary, borderRadius: '8px', color: theme.accent, fontWeight: 600, fontSize: '13px', border: `1px solid ${theme.accent}40` }}>{msg.text}</div>
                  ) : msg.type === 'match' ? (
                    <div style={{ padding: '14px 16px', borderRadius: '8px', background: theme.bgTertiary, border: `2px solid ${theme.accent}60`, color: theme.text, fontSize: '12px', lineHeight: '1.7' }}>
                      <div style={{ fontWeight: 700, color: theme.accent, marginBottom: '8px' }}>📋 Requirement: {msg.requirement}</div>
                      <div style={{ fontWeight: 700, color: theme.accent, marginBottom: '12px' }}>👤 Candidate: {msg.candidate}</div>
                      <div style={{ fontSize: '14px', fontWeight: 600, color: msg.score >= 80 ? '#4caf50' : msg.score >= 60 ? '#ff9800' : '#f44336', marginBottom: '12px' }}>Score: {msg.score}%</div>
                      <div style={{ marginBottom: '12px' }}><div style={{ fontWeight: 600, color: theme.text, marginBottom: '4px' }}>✓ Matched Skills:</div><div style={{ paddingLeft: '12px', color: '#4caf50' }}>{msg.matched.length > 0 ? msg.matched.map((skill, i) => <div key={i}>• {skill}</div>) : <div>None</div>}</div></div>
                      <div style={{ marginBottom: '12px' }}><div style={{ fontWeight: 600, color: theme.text, marginBottom: '4px' }}>✗ Missing Skills:</div><div style={{ paddingLeft: '12px', color: '#f44336' }}>{msg.missing.length > 0 ? msg.missing.map((skill, i) => <div key={i}>• {skill}</div>) : <div>None</div>}</div></div>
                      <div style={{ borderTop: `1px solid ${theme.border}`, paddingTop: '8px', fontStyle: 'italic', color: theme.textSecondary }}>💡 {msg.reasoning}</div>
                    </div>
                  ) : (
                    <div style={{ display: 'flex', justifyContent: msg.type === 'user' ? 'flex-end' : 'flex-start', width: '100%' }}>
                      <div style={{ maxWidth: '95%', padding: '12px 14px', borderRadius: '8px', background: msg.type === 'user' ? theme.accent : msg.type === 'error' ? theme.error : theme.bgTertiary, color: msg.type === 'user' ? 'white' : msg.type === 'error' ? (settings?.darkTheme ? '#ff6b6b' : '#c62828') : theme.text, fontSize: '13px', lineHeight: '1.5', wordWrap: 'break-word', overflowWrap: 'break-word' }}>
                        {msg.type === 'assistant' ? <RenderRequirementMessage text={msg.text} theme={theme} /> : msg.text}
                      </div>
                    </div>
                  )}
                  {msg.docContext && <div style={{ fontSize: '11px', color: theme.textSecondary, padding: '4px 16px', marginTop: '4px' }}>Based on: {msg.docContext}</div>}
                </div>
              ))
            )}
            {chatLoading && <div style={{ display: 'flex', gap: '4px', padding: '12px 16px' }}><span style={{ width: '6px', height: '6px', borderRadius: '50%', background: theme.accent }}></span><span style={{ width: '6px', height: '6px', borderRadius: '50%', background: theme.accent }}></span><span style={{ width: '6px', height: '6px', borderRadius: '50%', background: theme.accent }}></span></div>}
          </div>
          <div style={{ display: 'flex', gap: '8px', padding: '16px 20px', borderTop: `1px solid ${theme.border}`, flexWrap: 'wrap' }}>
            {selectedDocIdsReq.length > 0 && selectedDocIdsCand.length > 0 && <button onClick={handleFindMatches} disabled={isMatching} style={{ flex: '1 1 auto', padding: '10px 12px', background: isMatching ? theme.textSecondary : '#ff9800', color: 'white', border: 'none', borderRadius: '4px', cursor: isMatching ? 'not-allowed' : 'pointer', fontWeight: 600, fontSize: '12px', minWidth: '120px' }}>{isMatching ? '🔄 Matching...' : '🎯 Find Matches'}</button>}
            <input type="text" placeholder="Ask about selected documents..." value={chatInput} onChange={(e) => setChatInput(e.target.value)} onKeyPress={(e) => { if (e.key === 'Enter' && !chatLoading && selectedDocIds.length > 0) handleChatSubmit(); }} disabled={chatLoading || selectedDocIds.length === 0} style={{ flex: selectedDocIdsReq.length > 0 && selectedDocIdsCand.length > 0 ? '1 1 auto' : '1', padding: '10px', border: `1px solid ${theme.border}`, borderRadius: '4px', fontSize: '13px', background: theme.bg, color: theme.text, minWidth: '100px' }} />
            <button onClick={handleChatSubmit} disabled={chatLoading || !chatInput.trim() || selectedDocIds.length === 0} style={{ padding: '10px 12px', background: chatLoading || !chatInput.trim() || selectedDocIds.length === 0 ? theme.textSecondary : theme.accent, color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 600 }}>{chatLoading ? '⏳' : '→'}</button>
          </div>
        </div>
      )}
    </div>
  );
};



