'use client';

import { useState, useEffect } from 'react';
import NotesList from './components/NotesList';
import NoteForm from './components/NoteForm';
import SearchBar from './components/SearchBar';

interface Note {
  id: string;
  title: string;
  content: string;
  category: string;
  isPinned: boolean;
  createdAt: string;
  updatedAt: string;
}

export default function Home() {
  const [notes, setNotes] = useState<Note[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingNote, setEditingNote] = useState<Note | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || '/api';

  const fetchNotes = async () => {
    try {
      setLoading(true);
      let url = `${apiUrl}/notes`;
      
      if (searchQuery) {
        url += `?search=${encodeURIComponent(searchQuery)}`;
      } else if (selectedCategory !== 'all') {
        url += `?category=${encodeURIComponent(selectedCategory)}`;
      }
      
      const response = await fetch(url);
      if (!response.ok) throw new Error('Failed to fetch notes');
      const data = await response.json();
      setNotes(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load notes');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotes();
  }, [searchQuery, selectedCategory]);

  const handleCreateNote = async (noteData: Partial<Note>) => {
    try {
      const response = await fetch(`${apiUrl}/notes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(noteData),
      });
      if (!response.ok) throw new Error('Failed to create note');
      await fetchNotes();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create note');
    }
  };

  const handleUpdateNote = async (id: string, noteData: Partial<Note>) => {
    try {
      const response = await fetch(`${apiUrl}/notes/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(noteData),
      });
      if (!response.ok) throw new Error('Failed to update note');
      setEditingNote(null);
      await fetchNotes();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update note');
    }
  };

  const handleDeleteNote = async (id: string) => {
    if (!confirm('Are you sure you want to delete this note?')) return;
    
    try {
      const response = await fetch(`${apiUrl}/notes/${id}`, {
        method: 'DELETE',
      });
      if (!response.ok) throw new Error('Failed to delete note');
      await fetchNotes();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete note');
    }
  };

  const handleTogglePin = async (id: string) => {
    try {
      const response = await fetch(`${apiUrl}/notes/${id}/pin`, {
        method: 'PUT',
      });
      if (!response.ok) throw new Error('Failed to toggle pin');
      await fetchNotes();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to toggle pin');
    }
  };

  const categories = ['all', 'personal', 'work', 'ideas', 'todo'];

  return (
    <main className="container">
      <header className="header">
        <h1>📝 Notes App</h1>
        <p className="subtitle">A simple, fast, and secure notes application</p>
      </header>

      {error && (
        <div className="error-banner">
          <span>⚠️ {error}</span>
          <button onClick={() => setError(null)}>✕</button>
        </div>
      )}

      <div className="controls">
        <SearchBar 
          searchQuery={searchQuery}
          onSearchChange={setSearchQuery}
        />
        
        <div className="category-filter">
          {categories.map(cat => (
            <button
              key={cat}
              className={`category-btn ${selectedCategory === cat ? 'active' : ''}`}
              onClick={() => setSelectedCategory(cat)}
            >
              {cat.charAt(0).toUpperCase() + cat.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <NoteForm
        note={editingNote}
        onSubmit={editingNote ? 
          (data) => handleUpdateNote(editingNote.id, data) : 
          handleCreateNote
        }
        onCancel={() => setEditingNote(null)}
      />

      {loading ? (
        <div className="loading">Loading notes...</div>
      ) : (
        <NotesList
          notes={notes}
          onEdit={setEditingNote}
          onDelete={handleDeleteNote}
          onTogglePin={handleTogglePin}
        />
      )}

      {!loading && notes.length === 0 && (
        <div className="empty-state">
          <p>📭 No notes yet. Create your first note above!</p>
        </div>
      )}

      <footer className="footer">
        <p>💻 Backend: NestJS + PostgreSQL | 🎨 Frontend: Next.js</p>
        <p>📊 Total Notes: {notes.length}</p>
      </footer>
    </main>
  );
}
