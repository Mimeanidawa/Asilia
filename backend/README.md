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

For live payments, also configure `PAYMENT_PROVIDER=aurax`,
`AURAXPAY_API_KEY`, `AURAXPAY_WEBHOOK_SECRET`, and
`AURAXPAY_BASE_URL=https://api.auraxpay.net/v1`.

Set the Aurax Pay webhook endpoint to:

```text
https://asilia-production.up.railway.app/api/payments/aurax/webhook
```

The webhook must retain the `X-Aurax-Signature` header. Payment secrets belong
only in Railway environment variables and must never be added to Flutter or Git.

Default admin: `mimeanidawa@gmail.com`
