-- Sprint 3: AI Trip Planner Tables
-- Tables for plan requests, cached plans, and saved user plans

-- AI Trip Plan Request (queue/logging)
CREATE TABLE IF NOT EXISTS ai_trip_plan_request (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    city_id UUID REFERENCES cities(id),
    request_params JSONB NOT NULL,
    client_ip TEXT,
    user_id UUID REFERENCES auth.users(id),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- AI Trip Plan (cached results)
CREATE TABLE IF NOT EXISTS ai_trip_plan (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_hash TEXT UNIQUE NOT NULL,
    result JSONB NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Saved Plans
CREATE TABLE IF NOT EXISTS user_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES ai_trip_plan(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, plan_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_trip_plan_cache_hash ON ai_trip_plan(cache_hash);
CREATE INDEX IF NOT EXISTS idx_ai_trip_plan_expires ON ai_trip_plan(expires_at);
CREATE INDEX IF NOT EXISTS idx_ai_trip_plan_request_ip ON ai_trip_plan_request(client_ip, created_at);
CREATE INDEX IF NOT EXISTS idx_user_plans_user ON user_plans(user_id);

-- RLS Policies

-- ai_trip_plan_request: Service role only (for rate limiting)
ALTER TABLE ai_trip_plan_request ENABLE ROW LEVEL SECURITY;

-- ai_trip_plan: Read for all, write for service role
ALTER TABLE ai_trip_plan ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_trip_plan_select" ON ai_trip_plan
    FOR SELECT USING (true);

-- user_plans: Users can manage their own
ALTER TABLE user_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_plans_select_own" ON user_plans
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_plans_insert_own" ON user_plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_plans_delete_own" ON user_plans
    FOR DELETE USING (auth.uid() = user_id);

-- Grant access to authenticated users for user_plans
GRANT SELECT, INSERT, DELETE ON user_plans TO authenticated;

-- Grant select on ai_trip_plan to anon and authenticated
GRANT SELECT ON ai_trip_plan TO anon, authenticated;

-- Comments
COMMENT ON TABLE ai_trip_plan_request IS 'Logs all AI plan generation requests for rate limiting and analytics';
COMMENT ON TABLE ai_trip_plan IS 'Cached AI-generated trip plans with TTL';
COMMENT ON TABLE user_plans IS 'User-saved trip plans (bookmarks)';
