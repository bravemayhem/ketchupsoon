-- Add selection_type column to schedule_polls table
ALTER TABLE schedule_polls 
ADD COLUMN selection_type TEXT NOT NULL DEFAULT 'poll' 
CHECK (selection_type IN ('one_on_one', 'poll'));

-- Update existing rows to have a default value
UPDATE schedule_polls SET selection_type = 'poll' WHERE selection_type IS NULL; 