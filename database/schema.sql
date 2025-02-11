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
    phone_number TEXT,
    rsvp_status TEXT DEFAULT 'pending' CHECK (rsvp_status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create invites table
CREATE TABLE invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL,
    phone_number TEXT NOT NULL,
    is_valid BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE
);

-- Create verification_attempts table to prevent brute force
CREATE TABLE verification_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invite_token TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    attempt_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    success BOOLEAN NOT NULL
);

-- Create indexes for better query performance
CREATE INDEX idx_events_date ON events(date);
CREATE INDEX idx_event_attendees_event_id ON event_attendees(event_id);
CREATE INDEX idx_events_creator_id ON events(creator_id);
CREATE INDEX idx_event_attendees_phone_number ON event_attendees(phone_number);
CREATE INDEX idx_invites_phone_number ON invites(phone_number);

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
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_attempts ENABLE ROW LEVEL SECURITY;

-- Create policies for events table
CREATE POLICY "Enable read access for all users" ON events
    FOR SELECT USING (
        true  -- Allow reading all events, access will be controlled by invite tokens
    );

CREATE POLICY "Enable insert for all users" ON events
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for event creators" ON events
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM invites i
            WHERE i.event_id = id
            AND i.verified_at IS NOT NULL
        )
    );

-- Create policies for event_attendees table
DROP POLICY IF EXISTS "Enable read access for all users" ON event_attendees;
DROP POLICY IF EXISTS "Enable insert for all users" ON event_attendees;
DROP POLICY IF EXISTS "Enable update for attendees" ON event_attendees;

-- New policies for event_attendees
CREATE POLICY "Enable read access for all users" ON event_attendees
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for event creators" ON event_attendees
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM events e
            WHERE e.id = event_id
        )
    );

CREATE POLICY "Enable update for attendees" ON event_attendees
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM invites i
            WHERE i.event_id = event_id
            AND i.verified_at IS NOT NULL
            AND i.phone_number = phone_number
        )
    );

-- Create policies for invites table
CREATE POLICY "Enable read access for all users on invites"
ON invites FOR SELECT
USING (true);

CREATE POLICY "Enable insert for all users on invites"
ON invites FOR INSERT
WITH CHECK (true);

-- Create policies for verification_attempts
CREATE POLICY "Enable insert for all on verification attempts"
ON verification_attempts FOR INSERT
WITH CHECK (true);

-- Function to verify phone number for invite
CREATE OR REPLACE FUNCTION verify_invite_phone(
    p_token TEXT,
    p_phone TEXT,
    p_ip TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_invite_exists BOOLEAN;
    v_attempt_count INT;
BEGIN
    -- Check recent failed attempts from this IP
    SELECT COUNT(*)
    INTO v_attempt_count
    FROM verification_attempts
    WHERE ip_address = p_ip
    AND attempt_time > NOW() - INTERVAL '1 hour'
    AND success = false;

    -- If too many attempts, reject
    IF v_attempt_count >= 5 THEN
        RETURN false;
    END IF;

    -- Check if invite exists and matches phone
    SELECT EXISTS (
        SELECT 1
        FROM invites
        WHERE token = p_token
        AND phone_number = p_phone
        AND is_valid = true
        AND expires_at > NOW()
        AND verified_at IS NULL
    ) INTO v_invite_exists;

    -- Record the attempt
    INSERT INTO verification_attempts (
        invite_token,
        phone_number,
        ip_address,
        success
    ) VALUES (
        p_token,
        p_phone,
        p_ip,
        v_invite_exists
    );

    -- If valid, mark as verified
    IF v_invite_exists THEN
        UPDATE invites
        SET verified_at = NOW()
        WHERE token = p_token;
    END IF;

    RETURN v_invite_exists;
END;
$$; 