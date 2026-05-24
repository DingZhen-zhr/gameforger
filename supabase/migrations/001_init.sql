-- GameForger 数据库初始化（幂等 v2 - 兼容所有 PG 版本）

-- ============================================================
-- 1. 用户扩展信息表
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text,
  avatar_url text,
  credits integer NOT NULL DEFAULT 100,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can view own profile') THEN
    CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can update own profile') THEN
    CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, credits)
  VALUES (new.id, split_part(new.email, '@', 1), 100);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- 2. 项目表
-- ============================================================
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'generating', 'completed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'projects' AND policyname = 'Users can view own projects') THEN
    CREATE POLICY "Users can view own projects" ON projects FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'projects' AND policyname = 'Users can create own projects') THEN
    CREATE POLICY "Users can create own projects" ON projects FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'projects' AND policyname = 'Users can update own projects') THEN
    CREATE POLICY "Users can update own projects" ON projects FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'projects' AND policyname = 'Users can delete own projects') THEN
    CREATE POLICY "Users can delete own projects" ON projects FOR DELETE USING (auth.uid() = user_id);
  END IF;
END;
$$;

-- ============================================================
-- 3. 思维链卡片表
-- ============================================================
CREATE TABLE IF NOT EXISTS cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('story', 'art', 'gameplay', 'asset', 'music', 'question', 'user_note')),
  content jsonb NOT NULL DEFAULT '{}',
  parent_id uuid REFERENCES cards(id) ON DELETE SET NULL,
  order_index integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE cards ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cards' AND policyname = 'Users can view own cards') THEN
    CREATE POLICY "Users can view own cards" ON cards FOR SELECT USING (
      EXISTS (SELECT 1 FROM projects WHERE projects.id = cards.project_id AND projects.user_id = auth.uid())
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cards' AND policyname = 'Users can create own cards') THEN
    CREATE POLICY "Users can create own cards" ON cards FOR INSERT WITH CHECK (
      EXISTS (SELECT 1 FROM projects WHERE projects.id = cards.project_id AND projects.user_id = auth.uid())
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cards' AND policyname = 'Users can update own cards') THEN
    CREATE POLICY "Users can update own cards" ON cards FOR UPDATE USING (
      EXISTS (SELECT 1 FROM projects WHERE projects.id = cards.project_id AND projects.user_id = auth.uid())
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cards' AND policyname = 'Users can delete own cards') THEN
    CREATE POLICY "Users can delete own cards" ON cards FOR DELETE USING (
      EXISTS (SELECT 1 FROM projects WHERE projects.id = cards.project_id AND projects.user_id = auth.uid())
    );
  END IF;
END;
$$;

-- ============================================================
-- 4. 游戏构建记录表
-- ============================================================
CREATE TABLE IF NOT EXISTS game_builds (
  id text PRIMARY KEY,
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  version integer NOT NULL DEFAULT 1,
  html_code text NOT NULL DEFAULT '',
  spec_snapshot jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE game_builds ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'game_builds' AND policyname = 'Users can view own game_builds') THEN
    CREATE POLICY "Users can view own game_builds" ON game_builds FOR SELECT USING (
      EXISTS (SELECT 1 FROM projects WHERE projects.id = game_builds.project_id AND projects.user_id = auth.uid())
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'game_builds' AND policyname = 'Users can create own game_builds') THEN
    CREATE POLICY "Users can create own game_builds" ON game_builds FOR INSERT WITH CHECK (
      EXISTS (SELECT 1 FROM projects WHERE projects.id = game_builds.project_id AND projects.user_id = auth.uid())
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'game_builds' AND policyname = 'Users can update own game_builds') THEN
    CREATE POLICY "Users can update own game_builds" ON game_builds FOR UPDATE USING (
      EXISTS (SELECT 1 FROM projects WHERE projects.id = game_builds.project_id AND projects.user_id = auth.uid())
    );
  END IF;
END;
$$;

-- ============================================================
-- 5. 点数交易记录表
-- ============================================================
CREATE TABLE IF NOT EXISTS credit_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount integer NOT NULL,
  type text NOT NULL CHECK (type IN ('purchase', 'deduction', 'refund')),
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'credit_transactions' AND policyname = 'Users can view own transactions') THEN
    CREATE POLICY "Users can view own transactions" ON credit_transactions FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'credit_transactions' AND policyname = 'Users can create own transactions') THEN
    CREATE POLICY "Users can create own transactions" ON credit_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END;
$$;

-- ============================================================
-- 索引
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cards_project_id ON cards(project_id);
CREATE INDEX IF NOT EXISTS idx_cards_order_index ON cards(project_id, order_index);
CREATE INDEX IF NOT EXISTS idx_game_builds_project_id ON game_builds(project_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_user_id ON credit_transactions(user_id);

-- ============================================================
-- 完成后请在 Dashboard 中创建 Storage Buckets:
-- 1. avatars - 公开可读，用户自己可写入
-- 2. game-assets - 公开可读，项目所有者可写入
-- 3. game-builds - 公开可读，项目所有者可写入
-- ============================================================
