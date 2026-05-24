-- Add spec_snapshot column that was missed in previous migrations
ALTER TABLE game_builds ADD COLUMN IF NOT EXISTS spec_snapshot jsonb NOT NULL DEFAULT '{}';
