# Asilia (Dawa Asili)

Monorepo for **Dawa Asili** — natural medicine learning platform in Kiswahili.

| Path | Description |
|------|-------------|
| `backend/` | Node.js API (Express + PostgreSQL) |
| `lib/` | User Flutter app |
| `administrator/` | Admin Flutter app |

## API (backend)

```bash
cd backend
cp .env.example .env
npm install
npm run seed
npm start
```

Deploy via Railway with **Root Directory = `backend`**. Default admin: `mimeanidawa@gmail.com`.

## User app

```bash
flutter pub get
flutter run
```

## Admin app

```bash
cd administrator
flutter pub get
flutter run
```
