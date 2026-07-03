# Asilia API

Node.js backend for **Dawa Asili** — carousels, content posts, Darasa Huru lessons, user auth, Mwalimu chat, and push notifications.

## Setup

```bash
cp .env.example .env
# Edit DATABASE_URL, JWT_SECRET, ADMIN_EMAIL, ADMIN_PASSWORD

npm install
npm run seed   # init DB schema + clear demo content
npm start      # http://localhost:3001
```

## Deploy

Configured for [Railway](https://railway.app) via `railway.toml`. Set `DATABASE_URL`, `JWT_SECRET`, `ADMIN_EMAIL`, and optional `FIREBASE_SERVICE_ACCOUNT`.

## Default admin

- Email: `mimeanidawa@gmail.com` (or `ADMIN_EMAIL` in `.env`)
- Password: set via `ADMIN_PASSWORD` in `.env`
