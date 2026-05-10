-- Run once: Supabase → SQL → New query → paste this file → Run.
-- Set story_editor_secret.save_token to a long random string (Table Editor or SQL).
-- Put the same value in index.html as EDITOR_SAVE_TOKEN; Project URL + anon key there too.

create table if not exists public.story_content (
  id smallint primary key default 1 check (id = 1),
  content jsonb not null,
  updated_at timestamptz default now()
);

alter table public.story_content enable row level security;

drop policy if exists "story_content_select_all" on public.story_content;
create policy "story_content_select_all" on public.story_content
  for select using (true);

-- Direct writes are blocked for anon; only the RPC below (security definer) can upsert.

create table if not exists public.story_editor_secret (
  id int primary key default 1 check (id = 1),
  save_token text not null
);

insert into public.story_editor_secret (save_token)
values ('replace-with-a-long-random-secret-string')
on conflict (id) do nothing;

alter table public.story_editor_secret enable row level security;

create or replace function public.save_chapters(p_token text, p_json jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  expected text;
begin
  select trim(s.save_token) into expected
  from public.story_editor_secret s
  where s.id = 1
  limit 1;

  if expected is null or length(expected) = 0 then
    raise exception 'no_editor_secret_row';
  end if;

  if trim(coalesce(p_token, '')) is distinct from expected then
    raise exception 'unauthorized';
  end if;

  insert into public.story_content (id, content) values (1, p_json)
  on conflict (id) do update
    set content = excluded.content, updated_at = now();
end;
$$;

grant execute on function public.save_chapters(text, jsonb) to anon;
grant execute on function public.save_chapters(text, jsonb) to authenticated;

-- Let the browser read published story (RLS still applies).
grant usage on schema public to anon, authenticated;
grant select on public.story_content to anon, authenticated;
