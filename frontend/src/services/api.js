// API Configuration
// Use relative URLs so nginx proxy handles routing
export const API_BASE = '/api';

export const api = {
  analytics: {
    entities: `${API_BASE}/analytics/entities`,
    stats: `${API_BASE}/analytics/stats`,
  },
  settings: `${API_BASE}/settings`,
  documents: {
    list: `${API_BASE}/documents`,
    upload: `${API_BASE}/documents/upload`,
    delete: (id) => `${API_BASE}/documents/${id}`,
    deleteMultiple: `${API_BASE}/documents`,
    match: `${API_BASE}/documents/match`,
  },
  chat: {
    stream: `${API_BASE}/chat/stream`,
    analyze: `${API_BASE}/chat/analyze`,
    health: `${API_BASE}/chat/health`,
  },
};

export default API_BASE;
