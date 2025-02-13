-- Drop everything in the correct order to avoid dependency issues
DROP TABLE IF EXISTS verification_attempts CASCADE;
DROP TABLE IF EXISTS invites CASCADE;
DROP TABLE IF EXISTS event_attendees CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;
DROP FUNCTION IF EXISTS standardize_phone CASCADE;
DROP FUNCTION IF EXISTS verify_invite_phone CASCADE;
DROP FUNCTION IF EXISTS standardize_phone_on_save CASCADE;
DROP FUNCTION IF EXISTS check_invite_verification CASCADE;

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
    is_private BOOLEAN DEFAULT FALSE,
    google_calendar_id TEXT -- Store the Google Calendar event ID
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

-- Drop and recreate invites table with verified_at column and without event_id unique constraint
CREATE TABLE invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL,
    phone_number TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE -- NULL until first verification
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
CREATE INDEX idx_invites_token ON invites(token);

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

-- Function to standardize phone numbers (remove all non-digits and take last 10 digits)
CREATE OR REPLACE FUNCTION standardize_phone(phone TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    digits_only TEXT;
    result TEXT;
BEGIN
    -- Remove all non-digit characters
    digits_only := regexp_replace(phone, '\D', '', 'g');
    
    -- Take only the last 10 digits
    result := RIGHT(digits_only, 10);
    
    -- Raise notice for debugging
    RAISE NOTICE 'Phone standardization: input=%, digits_only=%, result=%', phone, digits_only, result;
    
    RETURN result;
END;
$$;

-- Function to verify phone number for invite
CREATE OR REPLACE FUNCTION verify_invite_phone(
    p_token TEXT,
    p_phone TEXT,
    p_ip TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_phone_exists BOOLEAN;
    v_attempt_count INT;
    v_formatted_phone TEXT;
    v_invite_record invites%ROWTYPE;
    v_debug_info JSONB;
BEGIN
    -- Get the invite record
    SELECT * INTO v_invite_record
    FROM invites
    WHERE token = p_token
    AND expires_at > NOW();

    -- If no valid invite found, return error
    IF v_invite_record IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'INVALID_OR_EXPIRED_TOKEN',
            'message', 'The invite token is invalid or has expired'
        );
    END IF;

    -- Standardize the phone number (get last 10 digits)
    v_formatted_phone := standardize_phone(p_phone);
    
    -- Debug info
    SELECT jsonb_build_object(
        'input_phone', p_phone,
        'formatted_phone', v_formatted_phone,
        'event_id', v_invite_record.event_id,
        'matching_attendees', (
            SELECT jsonb_agg(jsonb_build_object(
                'name', ea.name,
                'phone', ea.phone_number,
                'formatted_phone', standardize_phone(ea.phone_number)
            ))
            FROM event_attendees ea
            WHERE ea.event_id = v_invite_record.event_id
        )
    ) INTO v_debug_info;

    -- If this phone has already been verified for this invite, return success
    IF v_invite_record.verified_at IS NOT NULL 
       AND standardize_phone(v_invite_record.phone_number) = v_formatted_phone THEN
        RETURN json_build_object(
            'success', true,
            'message', 'Phone number already verified'
        );
    END IF;

    -- Check recent failed attempts, but skip for development
    IF p_ip != 'development' THEN
        SELECT COUNT(*)
        INTO v_attempt_count
        FROM verification_attempts
        WHERE ip_address = p_ip
        AND attempt_time > NOW() - INTERVAL '1 hour'
        AND success = false;

        -- If too many attempts, return rate limit error
        IF v_attempt_count >= 5 THEN
            RETURN json_build_object(
                'success', false,
                'error', 'RATE_LIMIT_EXCEEDED',
                'message', 'Too many failed attempts. Please try again later',
                'attempts', v_attempt_count
            );
        END IF;
    ELSE
        v_attempt_count := 0;
    END IF;

    -- Check if phone number exists as an attendee for this event
    SELECT EXISTS (
        SELECT 1
        FROM event_attendees ea
        WHERE ea.event_id = v_invite_record.event_id
        AND standardize_phone(ea.phone_number) = v_formatted_phone
    ) INTO v_phone_exists;

    -- Add more detailed debug info
    SELECT jsonb_build_object(
        'input_phone', p_phone,
        'formatted_phone', v_formatted_phone,
        'event_id', v_invite_record.event_id,
        'matching_attendees', (
            SELECT jsonb_agg(jsonb_build_object(
                'name', ea.name,
                'phone', ea.phone_number,
                'formatted_phone', standardize_phone(ea.phone_number),
                'matches_input', standardize_phone(ea.phone_number) = v_formatted_phone
            ))
            FROM event_attendees ea
            WHERE ea.event_id = v_invite_record.event_id
        )
    ) INTO v_debug_info;

    -- Record the attempt (even in development, for debugging)
    INSERT INTO verification_attempts (
        invite_token,
        phone_number,
        ip_address,
        success
    ) VALUES (
        p_token,
        v_formatted_phone,
        p_ip,
        v_phone_exists
    );

    -- If verification successful, update the invite record
    IF v_phone_exists THEN
        IF v_invite_record.verified_at IS NULL THEN
            UPDATE invites
            SET 
                verified_at = NOW(),
                phone_number = v_formatted_phone
            WHERE id = v_invite_record.id;
        END IF;
        
        RETURN json_build_object(
            'success', true,
            'message', 'Phone number verified successfully'
        );
    ELSE
        RETURN json_build_object(
            'success', false,
            'error', 'INVALID_PHONE_NUMBER',
            'message', 'This phone number is not associated with any event attendee',
            'attempts', v_attempt_count + 1,
            'debug', v_debug_info
        );
    END IF;
END;
$$;

-- Add trigger to standardize phone numbers on insert/update
CREATE OR REPLACE FUNCTION standardize_phone_on_save()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only standardize if phone number is not null
    IF NEW.phone_number IS NOT NULL THEN
        NEW.phone_number := standardize_phone(NEW.phone_number);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER standardize_attendee_phone
    BEFORE INSERT OR UPDATE ON event_attendees
    FOR EACH ROW
    EXECUTE FUNCTION standardize_phone_on_save();

-- Function to check if an invite is already verified
CREATE OR REPLACE FUNCTION check_invite_verification(p_token TEXT)
RETURNS TABLE (
    is_verified BOOLEAN,
    phone_number TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        verified_at IS NOT NULL,
        phone_number
    FROM invites
    WHERE token = p_token
    AND expires_at > NOW();
END;
$$; 