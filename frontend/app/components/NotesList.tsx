interface Note {
  id: string;
  title: string;
  content: string;
  category: string;
  isPinned: boolean;
  createdAt: string;
  updatedAt: string;
}

interface NotesListProps {
  notes: Note[];
  onEdit: (note: Note) => void;
  onDelete: (id: string) => void;
  onTogglePin: (id: string) => void;
}

export default function NotesList({ notes, onEdit, onDelete, onTogglePin }: NotesListProps) {
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <div className="notes-grid">
      {notes.map((note) => (
        <div key={note.id} className={`note-card ${note.isPinned ? 'pinned' : ''}`}>
          <div className="note-header">
            <span className={`category-badge ${note.category}`}>
              {note.category}
            </span>
            <button
              className={`pin-btn ${note.isPinned ? 'active' : ''}`}
              onClick={() => onTogglePin(note.id)}
              title={note.isPinned ? 'Unpin note' : 'Pin note'}
            >
              📌
            </button>
          </div>
          
          <h3 className="note-title">{note.title}</h3>
          <p className="note-content">{note.content}</p>
          
          <div className="note-footer">
            <span className="note-date">
              {formatDate(note.updatedAt)}
            </span>
            <div className="note-actions">
              <button
                className="btn-icon edit"
                onClick={() => onEdit(note)}
                title="Edit note"
              >
                ✏️
              </button>
              <button
                className="btn-icon delete"
                onClick={() => onDelete(note.id)}
                title="Delete note"
              >
                🗑️
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
