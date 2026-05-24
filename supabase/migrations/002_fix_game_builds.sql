-- Fix: add html_code column if missing from pre-existing game_builds table
ALTER TABLE game_builds ADD COLUMN IF NOT EXISTS html_code text NOT NULL DEFAULT '';

-- Fix: ensure status values are up to date
ALTER TABLE projects DROP CONSTRAINT IF EXISTS projects_status_check;
ALTER TABLE projects ADD CONSTRAINT projects_status_check
  CHECK (status IN ('draft', 'generating', 'generated', 'completed'));
