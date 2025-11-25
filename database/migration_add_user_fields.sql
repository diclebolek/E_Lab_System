-- Users tablosuna yeni alanlar ekleme migration
-- Mevcut veritabanı için çalıştırılacak migration dosyası

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS gender VARCHAR(10),
ADD COLUMN IF NOT EXISTS age INTEGER,
ADD COLUMN IF NOT EXISTS birth_date DATE,
ADD COLUMN IF NOT EXISTS blood_type VARCHAR(10),
ADD COLUMN IF NOT EXISTS emergency_contact VARCHAR(20);

