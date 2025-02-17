-- Add responded_at column to poll_responses table
ALTER TABLE poll_responses 
ADD COLUMN responded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add selected_slots column to poll_responses table
ALTER TABLE poll_responses 
ADD COLUMN selected_slots JSONB; 