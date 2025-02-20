-- Disable RLS on poll-related tables
ALTER TABLE schedule_polls DISABLE ROW LEVEL SECURITY;
ALTER TABLE time_slots DISABLE ROW LEVEL SECURITY;
ALTER TABLE poll_responses DISABLE ROW LEVEL SECURITY;

-- Policy for schedule_polls table
-- Allow anyone to read polls (they're meant to be shared)
CREATE POLICY "Anyone can view polls" ON schedule_polls
    FOR SELECT
    USING (true);

-- Allow authenticated users to create polls
CREATE POLICY "Authenticated users can create polls" ON schedule_polls
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy for time_slots table
-- Allow anyone to view time slots (they're part of the poll)
CREATE POLICY "Anyone can view time slots" ON time_slots
    FOR SELECT
    USING (true);

-- Allow authenticated users to create time slots
CREATE POLICY "Authenticated users can create time slots" ON time_slots
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy for poll_responses table
-- Allow anyone to view responses for a poll they can access
CREATE POLICY "Anyone can view poll responses" ON poll_responses
    FOR SELECT
    USING (true);

-- Allow anyone to submit responses
CREATE POLICY "Anyone can submit responses" ON poll_responses
    FOR INSERT
    WITH CHECK (true);

-- Prevent updating/deleting responses
CREATE POLICY "No updates to responses" ON poll_responses
    FOR UPDATE
    USING (false);

CREATE POLICY "No deleting responses" ON poll_responses
    FOR DELETE
    USING (false); 