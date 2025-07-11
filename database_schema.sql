CREATE TABLE public.daily_summaries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  drink_count smallint DEFAULT '0'::smallint,
  user_id uuid NOT NULL,
  date date,
  total_consumed_ml integer,
  goal_ml integer,
  goal_achieved boolean,
  CONSTRAINT daily_summaries_pkey PRIMARY KEY (id),
  CONSTRAINT daily_summaries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.drinking_data (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  amount_ml integer,
  created_at timestamp with time zone,
  CONSTRAINT drinking_data_pkey PRIMARY KEY (id),
  CONSTRAINT drinking_data_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.users (
  role text DEFAULT 'user'::text,
  id uuid NOT NULL,
  email text UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text),
  username text,
  daily_goal_ml integer DEFAULT 2000 CHECK (daily_goal_ml > 0),
  notifications_enabled boolean DEFAULT true,
  height_cm smallint,
  weight_kg real,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);