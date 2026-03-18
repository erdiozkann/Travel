-- Migration: Add missing columns and update schema
-- Run this in Supabase SQL Editor first

-- Add is_active to cities table
ALTER TABLE cities ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Add is_active to experiences table if not exists
ALTER TABLE experiences ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Add local_score to experiences if not exists
ALTER TABLE experiences ADD COLUMN IF NOT EXISTS local_score FLOAT DEFAULT 0.5;

-- Add status to experiences if not exists
ALTER TABLE experiences ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';

-- Add is_sponsored to experiences if not exists
ALTER TABLE experiences ADD COLUMN IF NOT EXISTS is_sponsored BOOLEAN DEFAULT false;

-- Update existing records to be active
UPDATE cities SET is_active = true WHERE is_active IS NULL;
UPDATE experiences SET is_active = true WHERE is_active IS NULL;

-- Make sure we have the required indexes
CREATE INDEX IF NOT EXISTS idx_cities_is_active ON cities(is_active);
CREATE INDEX IF NOT EXISTS idx_experiences_city_id ON experiences(city_id);
CREATE INDEX IF NOT EXISTS idx_experiences_status ON experiences(status);
