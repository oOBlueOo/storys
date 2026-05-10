-- Run in Supabase → SQL → New query → Run.
-- Makes story_editor_secret.save_token match EDITOR_SAVE_TOKEN in index.html.
-- Re-run this if you change the token in either place.

update public.story_editor_secret
set save_token = 'duhskabgfuyhsaghbeuybhaiusewbhfuija'
where id = 1;
