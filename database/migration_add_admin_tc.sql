-- Admins tablosuna TC kimlik alanı ekleme migration
-- Mevcut veritabanı için çalıştırılacak migration dosyası

ALTER TABLE admins 
ADD COLUMN IF NOT EXISTS tc_number VARCHAR(11) UNIQUE;

-- TC numarası için index oluştur (performans için)
CREATE INDEX IF NOT EXISTS idx_admins_tc_number ON admins(tc_number);

