# QIBRA AI DATABASE SCHEMA

## DATABASE PRINCIPLES

- Offline First
- Normalized Database
- Indexed Search
- Fast Queries
- Future Proof

---

## USERS

user_id

name

email

photo_url

language

theme

created_at

updated_at

---

## QURAN

surah_id

ayah_id

juz

page

hizb

ruku

arabic

translation_en

translation_ur

transliteration

audio_url

---

## HADITH

hadith_id

collection

book

chapter

number

arabic

english

urdu

grade

narrator

topic

---

## TAFSIR

tafsir_id

ayah_id

source

language

content

---

## DUAS

dua_id

category

title

arabic

roman

urdu

english

benefits

reference

audio

---

## BOOKMARKS

bookmark_id

user_id

type

reference

folder

created_at

---

## NOTES

note_id

user_id

ayah_id

note

color

created_at

updated_at

---

## READING_HISTORY

history_id

user_id

surah

ayah

page

juz

timestamp

---

## AI_HISTORY

chat_id

user_id

question

answer

sources

timestamp

---

## SETTINGS

theme

language

font

translation

audio_quality

notifications