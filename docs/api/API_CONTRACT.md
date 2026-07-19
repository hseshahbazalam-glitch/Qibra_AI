# QIBRA AI API CONTRACT

Base URL

/api/v1

---

AUTH

POST /auth/login

POST /auth/register

POST /auth/logout

POST /auth/forgot-password

---

QURAN

GET /quran

GET /quran/surah/{id}

GET /quran/search

GET /quran/juz

---

HADITH

GET /hadith

GET /hadith/search

GET /hadith/book

---

TAFSIR

GET /tafsir

GET /tafsir/search

---

DUAS

GET /duas

GET /duas/category

GET /duas/search

---

AI

POST /ai/chat

POST /ai/ayah

POST /ai/hadith

POST /ai/dua

---

PROFILE

GET /profile

PUT /profile

DELETE /profile

---

STANDARD RESPONSE

{
 success,
 message,
 data,
 timestamp,
 traceId
}