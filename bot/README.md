# Kaustub's PA (Slack DM bot)

Owners (Kaustubh U09DQDPAVDX, Hemanath U09DGS9MB9U) DM the bot. It answers from Epik data
(read-only SQL through Metabase), can draft messages to CDEs (sent only after the owner replies
"send"), and relays CDE replies to the owners.

Code: `pondu-bot/index.ts` (Supabase Edge Function `pondu-bot`, project `epik-ld-hive`,
JWT check off, Slack signature verified in code). Tables: `migration.sql`.

## Setup order
1. Create the Slack app from `slack-app-manifest.yaml` (api.slack.com/apps, Create New App, From a manifest). Install it to the workspace.
2. Copy the Signing Secret (Basic Information) and the Bot User OAuth Token (OAuth & Permissions, `xoxb-...`).
3. In Supabase (Edge Functions, Secrets) add: `SLACK_SIGNING_SECRET`, `SLACK_BOT_TOKEN`, `ANTHROPIC_API_KEY`, `METABASE_API_KEY`. Optional: `METABASE_URL`, `OWNER_IDS`, `CLAUDE_MODEL`, `ANTHROPIC_WORKSPACE_ID`.
4. In the Slack app, Event Subscriptions: On, Request URL `https://nrfushxgqjqtfdghkvak.supabase.co/functions/v1/pondu-bot`, subscribe to bot event `message.im`, Save, then reinstall the app if asked.
5. DM the bot "hello".

## Safety design
- Only the owner ids may command the bot. CDEs may only reply; their text is relayed and stored, never executed.
- Messages to CDEs are drafted by the model but sent by code only after the owner replies "send".
- SQL is SELECT-only (one statement) and the Metabase key is read-only.
