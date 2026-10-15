# Photographer portfolio

A responsive React + Vite portfolio template with public galleries and a private Supabase-backed administrator area. It ships without photographs, generated art, or demo gallery records. The hero and galleries remain empty until the owner adds real work.

## Local setup

1. Install Node.js 20 or later.
2. Create a Supabase project at [supabase.com](https://supabase.com/).
3. In the Supabase SQL Editor, run the migration files in order: `202610160001_initial.sql`, `202610160002_portfolio_navigation.sql`, then `202610160003_home_menu_item.sql`. These align the database with the current menu and hide legacy starter categories without deleting records or photographs.
4. The migration creates the `portfolio-images` public bucket (25 MB image limit), policies, tables, and nine editable initial menu categories. Public bucket objects can be viewed by anyone with their URL, including unpublished images; this is the tradeoff for direct public image delivery. If unpublished images must remain private, use a private bucket and signed URLs instead.
5. In Supabase Project Settings → API, copy the project URL and publishable/anon key. Copy `.env.example` to `.env.local` and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`. Do not put a service-role key in any `VITE_` variable or browser code.
6. Create the first admin user in Supabase Dashboard → Authentication → Users → Add user. Disable public signups under Authentication settings. Copy the user's UUID and run `insert into public.admin_users(user_id) values ('USER-UUID-HERE');` in SQL Editor. Administrator authorization is explicit and is enforced by RLS and Storage policies as well as the dashboard route.
7. Run `npm install`, then `npm run dev`. Build for deployment with `npm run build`; preview with `npm run preview`.

## Admin and content

Open `/admin/login` and sign in with the provisioned email and password. The dashboard manages uploads, captions, descriptions, publication, ordering, categories, homepage display, biography, and contact details. New photos are unpublished until explicitly published. The homepage starts with no hero image. No visitor account or registration flow exists.

Upload accepts image MIME types up to 25 MB. Originals are stored without compression. The public bucket means uploaded draft image files themselves are URL-accessible even while their metadata is unpublished; only published rows appear in public gallery queries. Deletion removes the storage file first and only removes the row when that succeeds. If the subsequent database deletion fails, the dashboard reports the remaining record so it can be retried. If record creation fails after upload, the dashboard reports the orphan storage path for cleanup.

The migration seeds nine menu entries, including Home, Biography, and Contact as requested. The public shell renders the dedicated home/about/contact pages separately and category links for visible categories; if you prefer these three content routes not to be editable as categories, remove those seed entries before launch.

## Troubleshooting

- **Missing environment configuration:** ensure `.env.local` uses the exact variable names, then restart Vite.
- **Login fails:** verify the user exists, the password is correct, and the account UUID has a row in `admin_users`. Password reset can be performed through Supabase Auth.
- **Login succeeds but admin is denied:** rerun the `admin_users` insert for the authenticated user's UUID and verify the `is_admin()` function and policies from the migration.
- **Gallery or settings appear empty:** confirm the migration ran in the same project as the frontend URL; check the browser console and Supabase API logs for RLS or network errors.
- **Upload denied:** confirm administrator provisioning, that the bucket is named `portfolio-images`, and that the migration's Storage policies are present. Images larger than 25 MB or unsupported image MIME types are rejected.
- **Public images:** the bucket is intentionally public for fast direct delivery. Hiding a photo in the gallery does not revoke direct access to its file URL.

## Design customization

Restyle CSS variables in `src/styles.css`. The admin and public site use the same Supabase project but enforce administrator writes through database and Storage RLS. Deploy as a static SPA with rewrite/fallback support for `/gallery/*` and `/admin/*` paths.
