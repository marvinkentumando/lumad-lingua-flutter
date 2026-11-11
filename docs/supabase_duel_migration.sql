-- Supabase Migration Script for Lingua Duel (Postgres Tables + RLS + Realtime)

-- 1. Create table for duel matches
CREATE TABLE IF NOT EXISTS public.duel_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player1_id TEXT NOT NULL,
  player2_id TEXT,
  player1_name TEXT NOT NULL DEFAULT 'Warrior',
  player2_name TEXT,
  player1_avatar TEXT NOT NULL DEFAULT '👤',
  player2_avatar TEXT,
  status TEXT NOT NULL DEFAULT 'waiting',
  questions JSONB NOT NULL DEFAULT '[]'::jsonb,
  player1_hp DOUBLE PRECISION NOT NULL DEFAULT 1.0,
  player2_hp DOUBLE PRECISION NOT NULL DEFAULT 1.0,
  current_round INT NOT NULL DEFAULT 0,
  winner_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  battle_started_at TIMESTAMPTZ,
  round_started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ,
  last_seen JSONB NOT NULL DEFAULT '{}'::jsonb,
  player1_rematch BOOLEAN NOT NULL DEFAULT false,
  player2_rematch BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for duel_matches
ALTER TABLE public.duel_matches ENABLE ROW LEVEL SECURITY;

-- Create policies for duel_matches
CREATE POLICY "Allow public select on duel_matches" ON public.duel_matches
  FOR SELECT USING (true);

CREATE POLICY "Allow public insert on duel_matches" ON public.duel_matches
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public update on duel_matches" ON public.duel_matches
  FOR UPDATE USING (true);

CREATE POLICY "Allow public delete on duel_matches" ON public.duel_matches
  FOR DELETE USING (true);

-- Enable Supabase Realtime for duel_matches
ALTER PUBLICATION supabase_realtime ADD TABLE public.duel_matches;

-- 2. Create table for duel history
CREATE TABLE IF NOT EXISTS public.duel_history (
  id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  opponent_id TEXT NOT NULL,
  opponent_name TEXT NOT NULL DEFAULT 'Warrior',
  opponent_avatar TEXT NOT NULL DEFAULT '👤',
  is_winner BOOLEAN NOT NULL DEFAULT false,
  final_player_hp DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  final_opponent_hp DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  rounds_played INT NOT NULL DEFAULT 0,
  xp_earned INT NOT NULL DEFAULT 0,
  mist_crystals_earned INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (id, user_id)
);

-- Enable RLS for duel_history
ALTER TABLE public.duel_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public full access on duel_history" ON public.duel_history
  FOR ALL USING (true);

-- Enable Supabase Realtime for duel_history
ALTER PUBLICATION supabase_realtime ADD TABLE public.duel_history;

-- 3. Create table for learner pronunciation attempts
CREATE TABLE IF NOT EXISTS public.learner_pronunciation_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id TEXT NOT NULL,
  phrase_id TEXT NOT NULL,
  phrase_title TEXT NOT NULL,
  best_score NUMERIC NOT NULL,
  attempt_count INT NOT NULL DEFAULT 1,
  last_attempted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for learner_pronunciation_attempts
ALTER TABLE public.learner_pronunciation_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public full access on learner_pronunciation_attempts" ON public.learner_pronunciation_attempts
  FOR ALL USING (true) WITH CHECK (true);

