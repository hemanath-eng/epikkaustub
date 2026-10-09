-- Pondu Manager chatbot tables (RLS on, no policies: only the Edge Function's service role can use them).
create table if not exists public.pondu_cdes (
  slack_id text primary key,
  name text not null,
  active boolean not null default true
);
create table if not exists public.pondu_messages (          -- owner chat history (text only)
  id bigserial primary key,
  owner_id text not null,
  role text not null check (role in ('user','assistant')),
  content text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.pondu_pending (           -- messages to CDEs awaiting the owner's "send"
  id bigserial primary key,
  owner_id text not null,
  cde_slack_id text not null references public.pondu_cdes(slack_id),
  text text not null,
  status text not null default 'pending' check (status in ('pending','sent','cancelled')),
  created_at timestamptz not null default now()
);
create table if not exists public.pondu_replies (           -- what CDEs wrote back to the bot
  id bigserial primary key,
  cde_slack_id text not null,
  text text not null,
  slack_ts text,
  created_at timestamptz not null default now(),
  unique (cde_slack_id, slack_ts)
);
create table if not exists public.pondu_sent (              -- messages the bot sent to CDEs (context for replies)
  id bigserial primary key,
  cde_slack_id text not null,
  text text not null,
  source text not null default 'owner' check (source in ('owner','daily')),
  created_at timestamptz not null default now()
);
alter table public.pondu_cdes enable row level security;
alter table public.pondu_messages enable row level security;
alter table public.pondu_pending enable row level security;
alter table public.pondu_replies enable row level security;
alter table public.pondu_sent enable row level security;

insert into public.pondu_cdes (slack_id, name) values
 ('U0ANT2BL28P','Ajith Kumar'),('U0ASWUSJ53P','Akshay A'),('U0AP23YUB7D','Bhuvaneshwari'),
 ('U0C3PQV59ST','D Prasanth'),('U0APC3E6QUC','Gowda Jyothi'),('U0BKU25M10Q','Gulsan Jahan Talukdar'),
 ('U0ASJT8BZN3','Ikram Pasha'),('U09PEQYN431','Kishan G R'),('U0C6V0TKGKV','Mansoor'),
 ('U0C6F6MB3A6','M Prashanth'),('U09DBGPCZ38','Naveed Pasha'),('U0C452U2NUS','Roseline'),
 ('U0AP8FJ0DKL','Roshan Shariff'),('U09UM673V47','Sanjay S'),('U0B2T437DQF','Shadab Qadri'),
 ('U0AP23V2D0T','Srikanth'),('U0C170WLA6P','Vijay Kanth'),('U0C6MBHE137','Vivek C Yajaman')
on conflict (slack_id) do nothing;
