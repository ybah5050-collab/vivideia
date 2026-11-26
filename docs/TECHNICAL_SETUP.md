# VIVIDEIA — technical foundation

## Architecture
- Frontend: existing static site; inspect and integrate before replacing.
- Database, Auth and private Storage: Supabase.
- Trusted API: Cloudflare Workers (planned).
- Video generation: choose fal or Runway after cost/quality tests.
- Media processing: FFmpeg in a server-side environment.
- Payments: validate a Senegal-compatible provider (PayTech/PayDunya) before implementation.

## Supabase setup
1. Create the Supabase project.
2. In SQL Editor, run `supabase/migrations/001_initial_schema.sql`.
3. Find the Project URL and publishable key in Connect or Settings > API Keys.
4. Put only the publishable key in browser configuration.
5. Put the secret/service-role key only in backend secret storage; never commit it.
6. Configure Auth site URL and redirect URLs for the deployed domain before launch.

## Tables
- profiles: one profile per Auth user.
- projects: user's video project briefs.
- generations: asynchronous provider job records.
- credit_ledger: append-only credit grants/debits.

## Security
RLS is enabled. Users can only access their own rows. Clients can create/manage projects, but generation records and credit mutations are reserved for trusted backend operations. Generated videos use a private bucket with per-user folder paths.

## Environment variables
See `.env.example`. It contains placeholders only. Never commit real credentials.

## Next milestones
1. Apply the SQL migration and verify tables/RLS.
2. Connect frontend Auth.
3. Create a Cloudflare Worker API and add server secrets.
4. Integrate one video provider and webhook/job tracking.
5. Add audio, subtitles, rendering and payments.
