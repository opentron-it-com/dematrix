// Document management utilities
export const useDocumentManagement = () => {
  const toggleDeleteSelection = (deleteSelectedIds, setDeleteSelectedIds, docId) => {
    setDeleteSelectedIds(prev => 
      prev.includes(docId) 
        ? prev.filter(id => id !== docId)
        : [...prev, docId]
    );
  };

  const handleDeleteDocuments = async (deleteSelectedIds, setDeleteSelectedIds, documents, setDocuments, selectedDocIds, setSelectedDocIds, loadAnalytics, setIsDeleting, api) => {
    if (deleteSelectedIds.length === 0) return;
    if (!window.confirm(`Delete ${deleteSelectedIds.length} document${deleteSelectedIds.length !== 1 ? 's' : ''}? This cannot be undone.`)) return;

    setIsDeleting(true);
    try {
      const response = await fetch(api.documents.deleteMultiple, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ documentIds: deleteSelectedIds })
      });

      if (response.ok) {
        setDocuments(prev => prev.filter(d => !deleteSelectedIds.includes(d.documentId || d.id)));
        setDeleteSelectedIds([]);
        setSelectedDocIds(prev => prev.filter(id => !deleteSelectedIds.includes(id)));
        loadAnalytics();
      } else {
        alert('Error deleting documents');
      }
    } catch (err) {
      console.error('Delete error:', err);
      alert('Error deleting documents: ' + err.message);
    } finally {
      setIsDeleting(false);
    }
  };

  return { toggleDeleteSelection, handleDeleteDocuments };
};
