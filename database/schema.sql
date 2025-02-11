-- Drop existing tables and functions if they exist
DROP TABLE IF EXISTS event_attendees CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;

-- Create events table
CREATE TABLE events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT,
    description TEXT,
    duration INTEGER NOT NULL, -- in seconds
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    creator_id UUID NOT NULL,
    is_private BOOLEAN DEFAULT FALSE
);

-- Create event_attendees table
CREATE TABLE event_attendees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    rsvp_status TEXT DEFAULT 'pending' CHECK (rsvp_status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_events_date ON events(date);
CREATE INDEX idx_event_attendees_event_id ON event_attendees(event_id);
CREATE INDEX idx_events_creator_id ON events(creator_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for events table
CREATE TRIGGER update_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_attendees ENABLE ROW LEVEL SECURITY;

-- Create policies for events table
CREATE POLICY "Enable read access for all users" ON events
    FOR SELECT USING (
        NOT is_private OR creator_id = auth.uid()
    );

CREATE POLICY "Enable insert for authenticated users only" ON events
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for event creators" ON events
    FOR UPDATE USING (creator_id = auth.uid());

CREATE POLICY "Enable delete for event creators" ON events
    FOR DELETE USING (creator_id = auth.uid());

-- Create policies for event_attendees table
CREATE POLICY "Enable read access for all users" ON event_attendees
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM events e
            WHERE e.id = event_id
            AND (NOT e.is_private OR e.creator_id = auth.uid())
        )
    );

CREATE POLICY "Enable insert for event creators" ON event_attendees
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM events e
            WHERE e.id = event_id
            AND e.creator_id = auth.uid()
        )
    );

CREATE POLICY "Enable update for event creators and attendees" ON event_attendees
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM events e
            WHERE e.id = event_id
            AND (e.creator_id = auth.uid() OR email = auth.email())
        )
    );

CREATE POLICY "Enable delete for event creators" ON event_attendees
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM events e
            WHERE e.id = event_id
            AND e.creator_id = auth.uid()
        )
    ); 