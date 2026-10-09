# Kaustub's PA (Slack DM bot)

Owners (Kaustubh U09DQDPAVDX, Hemanath U09DGS9MB9U) DM the bot. It
- answers any question about demos and sales from the Epik database (read-only SQL through Metabase), including trends, patterns, sentiment, CDE comparisons and recommendations for improving sales;
- understands voice notes (Slack voice clips are transcribed with an OpenAI-compatible Whisper API);
- drafts messages to CDEs, sent only after the owner replies "send";
- keeps custom watches ("alert me if ..."), checked every few hours;
- relays CDE replies (text or voice) to the owners.

Automatic monitoring (Supabase pg_cron calls the function with a secret key from `public.pondu_config`):
- `pondu-monitor`, 09:30, 13:30 and 17:30 IST: hot or qualified leads with no order after 30 to 72 hours, missing demos or insights, custom watches.
- `pondu-digest`, 19:00 IST: today's demos, qualified, hot leads and orders against the 7-day average, CDEs slipping, and three actions for tomorrow.
Alerts repeat at most once per cooldown (see `pondu_alerts_log`).

Code: `pondu-bot/index.ts` (Supabase Edge Function `pondu-bot`, project `epik-ld-hive`, JWT check off, Slack signature verified in code). Tables: `migration.sql` (plus `pondu_config`, `pondu_watches`, `pondu_alerts_log`).

## Secrets (Supabase, Edge Functions, Secrets)
Required: `SLACK_SIGNING_SECRET`, `SLACK_BOT_TOKEN`, `ANTHROPIC_API_KEY`, `METABASE_API_KEY`.
Voice notes: `TRANSCRIBE_API_KEY` (OpenAI key; for Groq also set `TRANSCRIBE_BASE_URL=https://api.groq.com/openai/v1` and `TRANSCRIBE_MODEL=whisper-large-v3-turbo`).
Optional: `METABASE_URL`, `OWNER_IDS`, `CLAUDE_MODEL`, `ANTHROPIC_WORKSPACE_ID`, `BOT_NAME`.

## Slack app
Create it from `slack-app-manifest.yaml`. The `files:read` scope is needed for voice notes. After adding a scope, reinstall the app.

## Safety design
- Only the owner ids may command the bot. CDEs may only reply; their text is relayed and stored, never executed.
- Messages to CDEs are drafted by the model but sent by code only after the owner replies "send".
- SQL is SELECT-only (one statement, no pg_ functions) and the Metabase key is read-only.
- The /monitor and /digest endpoints require the secret key; without it they answer 403.
