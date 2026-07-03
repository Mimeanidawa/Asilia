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

Default admin: `mimeanidawa@gmail.com`
