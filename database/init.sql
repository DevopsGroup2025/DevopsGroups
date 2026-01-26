-- =============================================================================
-- PostgreSQL Database Initialization Script
-- =============================================================================

-- Create the notes table if it doesn't exist
-- Note: TypeORM with synchronize:true will auto-create tables,
-- but this script ensures the schema exists on first run

-- Enable UUID extension (if needed for future use)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    category VARCHAR(50) DEFAULT 'Personal',
    "isPinned" BOOLEAN DEFAULT FALSE,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster searches
CREATE INDEX IF NOT EXISTS idx_notes_category ON notes(category);
CREATE INDEX IF NOT EXISTS idx_notes_pinned ON notes("isPinned");
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes("createdAt" DESC);

-- Create full-text search index for title and content
CREATE INDEX IF NOT EXISTS idx_notes_search ON notes USING gin(to_tsvector('english', title || ' ' || COALESCE(content, '')));

-- Insert sample data for testing (optional - remove in production)
INSERT INTO notes (title, content, category, "isPinned") VALUES
    ('Welcome to Notes App', 'This is your first note. You can create, edit, and delete notes.', 'Personal', true),
    ('Project Ideas', 'List of project ideas to work on:\n- Build a REST API\n- Learn Docker\n- Study Kubernetes', 'Ideas', false),
    ('Meeting Notes', 'Team meeting summary:\n- Discussed project timeline\n- Assigned tasks\n- Next meeting on Friday', 'Work', false)
ON CONFLICT DO NOTHING;

-- Create function to update the updatedAt timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updatedAt
DROP TRIGGER IF EXISTS update_notes_updated_at ON notes;
CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions (adjust as needed)
-- GRANT ALL PRIVILEGES ON TABLE notes TO dbadmin;
-- GRANT USAGE, SELECT ON SEQUENCE notes_id_seq TO dbadmin;

-- Log initialization completion
DO $$
BEGIN
    RAISE NOTICE 'Database initialization completed successfully!';
END $$;



