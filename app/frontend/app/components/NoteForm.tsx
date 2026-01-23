import { useState, useEffect } from 'react';

interface Note {
  id: string;
  title: string;
  content: string;
  category: string;
  isPinned: boolean;
}

interface NoteFormProps {
  note: Note | null;
  onSubmit: (noteData: Partial<Note>) => void;
  onCancel: () => void;
}

export default function NoteForm({ note, onSubmit, onCancel }: NoteFormProps) {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [category, setCategory] = useState('personal');

  useEffect(() => {
    if (note) {
      setTitle(note.title);
      setContent(note.content);
      setCategory(note.category);
    } else {
      setTitle('');
      setContent('');
      setCategory('personal');
    }
  }, [note]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) return;
    
    onSubmit({
      title: title.trim(),
      content: content.trim(),
      category,
    });
    
    if (!note) {
      setTitle('');
      setContent('');
      setCategory('personal');
    }
  };

  return (
    <form className="note-form" onSubmit={handleSubmit}>
      <div className="form-header">
        <h2>{note ? '✏️ Edit Note' : '➕ New Note'}</h2>
        {note && (
          <button type="button" className="btn-cancel" onClick={onCancel}>
            Cancel
          </button>
        )}
      </div>
      
      <div className="form-group">
        <input
          type="text"
          className="form-input"
          placeholder="Note title..."
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          required
        />
      </div>
      
      <div className="form-group">
        <textarea
          className="form-textarea"
          placeholder="Write your note here..."
          value={content}
          onChange={(e) => setContent(e.target.value)}
          rows={4}
          required
        />
      </div>
      
      <div className="form-footer">
        <select
          className="form-select"
          value={category}
          onChange={(e) => setCategory(e.target.value)}
        >
          <option value="personal">Personal</option>
          <option value="work">Work</option>
          <option value="ideas">Ideas</option>
          <option value="todo">To-Do</option>
        </select>
        
        <button type="submit" className="btn-primary">
          {note ? 'Update Note' : 'Create Note'}
        </button>
      </div>
    </form>
  );
}
