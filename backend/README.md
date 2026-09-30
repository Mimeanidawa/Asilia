# Asilia API

Node.js backend for **Dawa Asili** — carousels, content posts, Darasa Huru lessons, user auth, Mwalimu chat, and push notifications.

## Setup

```bash
cp .env.example .env
npm install
npm run seed
npm start
```

## Deploy (Railway)

Set **Root Directory** to `backend` in Railway service settings.

Required env vars: `DATABASE_URL`, `JWT_SECRET`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`.

For live payments, also configure `SONICPESA_ACCESS_KEY` and
`SONICPESA_SECRET_KEY`.

SonicPesa allows one webhook. If several apps share that API, keep:

```text
https://washatv-production.up.railway.app/api/v1/webhooks/sonicpesa
```

This service listens on the same path, so Asilia orders are marked paid only
when that webhook (or the status poll) hits the database that stored the
checkout. Payment secrets belong only in Railway environment variables.

Default admin: `mimeanidawa@gmail.com`
