-- E-Laboratuvar Sistemi - Örnek SQL Sorguları

-- 1. Kullanıcı kaydı (şifre hash'lenmeli)
INSERT INTO users (tc_number, password_hash, full_name)
VALUES ('12345678901', '$2b$10$...', 'Ahmet Yılmaz');

-- 2. Kullanıcı girişi kontrolü
SELECT id, tc_number, full_name, password_hash
FROM users
WHERE tc_number = '12345678901' AND is_deleted = FALSE;

-- 3. Admin kaydı
INSERT INTO admins (email, password_hash, full_name)
VALUES ('admin@example.com', '$2b$10$...', 'Dr. Mehmet Demir');

-- 4. Admin girişi kontrolü
SELECT id, email, full_name, password_hash
FROM admins
WHERE email = 'admin@example.com' AND is_active = TRUE;

-- 5. Tahlil ekleme
INSERT INTO tahliller (
    user_id, full_name, tc_number, birth_date, age, gender,
    patient_type, sample_type, report_date, created_by
)
VALUES (
    1, 'Ahmet Yılmaz', '12345678901', '1990-01-15', 34,
    'Erkek', 'Ayakta', 'Serum', '2024-01-15', 1
)
RETURNING id;

-- 6. Serum değerleri ekleme
INSERT INTO serum_types (tahlil_id, type, value)
VALUES
    (1, 'IgG', '1200'),
    (1, 'IgA', '250'),
    (1, 'IgM', '150');

-- 7. Kullanıcının tüm tahlillerini getir
SELECT 
    t.id,
    t.full_name,
    t.tc_number,
    t.birth_date,
    t.age,
    t.gender,
    t.patient_type,
    t.sample_type,
    t.report_date,
    t.created_at
FROM tahliller t
WHERE t.tc_number = '12345678901'
ORDER BY t.created_at DESC;

-- 8. Tahlil detayı ile serum değerleri
SELECT 
    t.*,
    json_agg(
        json_build_object(
            'type', st.type,
            'value', st.value
        )
    ) as serum_types
FROM tahliller t
LEFT JOIN serum_types st ON t.id = st.tahlil_id
WHERE t.id = 1
GROUP BY t.id;

-- 9. Kılavuz oluşturma
INSERT INTO kilavuzlar (guide_name, created_by)
VALUES ('Pediatrik IgG Kılavuzu', 1)
RETURNING id;

-- 10. Kılavuz satırları ekleme
INSERT INTO kilavuz_rows (
    kilavuz_id, age_range, geo_mean_min, geo_mean_max,
    mean_min, mean_max, min_value, max_value,
    interval_min, interval_max, serum_type,
    arith_mean_min, arith_mean_max
)
VALUES (
    1, '0-6 ay', 200.50, 800.50,
    300.00, 700.00, 150.00, 900.00,
    200.00, 800.00, 'IgG',
    250.00, 750.00
);

-- 11. Kılavuzları listele
SELECT id, guide_name, created_at, updated_at
FROM kilavuzlar
ORDER BY created_at DESC;

-- 12. Kılavuz detayı ile satırları
SELECT 
    k.id,
    k.guide_name,
    json_agg(
        json_build_object(
            'id', kr.id,
            'age_range', kr.age_range,
            'geo_mean_min', kr.geo_mean_min,
            'geo_mean_max', kr.geo_mean_max,
            'mean_min', kr.mean_min,
            'mean_max', kr.mean_max,
            'min', kr.min_value,
            'max', kr.max_value,
            'interval_min', kr.interval_min,
            'interval_max', kr.interval_max,
            'serum_type', kr.serum_type,
            'arith_mean_min', kr.arith_mean_min,
            'arith_mean_max', kr.arith_mean_max
        )
    ) as rows
FROM kilavuzlar k
LEFT JOIN kilavuz_rows kr ON k.id = kr.kilavuz_id
WHERE k.guide_name = 'Pediatrik IgG Kılavuzu'
GROUP BY k.id;

-- 13. Şifre güncelleme
UPDATE users
SET password_hash = '$2b$10$...', updated_at = CURRENT_TIMESTAMP
WHERE id = 1;

-- 14. Hesap silme (soft delete)
UPDATE users
SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP
WHERE id = 1;

-- 15. Tahlil arama (admin için)
SELECT 
    t.id,
    t.full_name,
    t.tc_number,
    t.report_date,
    t.created_at
FROM tahliller t
WHERE 
    t.full_name ILIKE '%Ahmet%'
    OR t.tc_number ILIKE '%123%'
ORDER BY t.created_at DESC
LIMIT 50;

-- 16. İstatistikler (admin dashboard için)
SELECT 
    COUNT(*) as total_tahliller,
    COUNT(DISTINCT tc_number) as unique_patients,
    COUNT(DISTINCT created_by) as active_admins
FROM tahliller
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days';

