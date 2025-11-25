-- E-Laboratuvar Sistemi PostgreSQL Veritabanı Şeması

-- Kullanıcılar (Hastalar) Tablosu
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    tc_number VARCHAR(11) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    gender VARCHAR(10),
    age INTEGER,
    birth_date DATE,
    blood_type VARCHAR(10),
    emergency_contact VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Yöneticiler (Doktorlar) Tablosu
CREATE TABLE admins (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    tc_number VARCHAR(11) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Tahliller Tablosu
CREATE TABLE tahliller (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    tc_number VARCHAR(11) NOT NULL,
    birth_date DATE,
    age INTEGER NOT NULL,
    gender VARCHAR(10) NOT NULL,
    patient_type VARCHAR(50) NOT NULL,
    sample_type VARCHAR(100) NOT NULL,
    report_date VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES admins(id),
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Serum Tipleri Tablosu (Tahlil ile ilişkili)
CREATE TABLE serum_types (
    id SERIAL PRIMARY KEY,
    tahlil_id INTEGER NOT NULL REFERENCES tahliller(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tahlil FOREIGN KEY (tahlil_id) REFERENCES tahliller(id) ON DELETE CASCADE
);

-- Kılavuzlar Tablosu
CREATE TABLE kilavuzlar (
    id SERIAL PRIMARY KEY,
    guide_name VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES admins(id)
);

-- Kılavuz Satırları Tablosu
CREATE TABLE kilavuz_rows (
    id SERIAL PRIMARY KEY,
    kilavuz_id INTEGER NOT NULL REFERENCES kilavuzlar(id) ON DELETE CASCADE,
    age_range VARCHAR(50) NOT NULL,
    geo_mean_min DECIMAL(10, 2),
    geo_mean_max DECIMAL(10, 2),
    mean_min DECIMAL(10, 2),
    mean_max DECIMAL(10, 2),
    min_value DECIMAL(10, 2),
    max_value DECIMAL(10, 2),
    interval_min DECIMAL(10, 2),
    interval_max DECIMAL(10, 2),
    serum_type VARCHAR(50) NOT NULL,
    arith_mean_min DECIMAL(10, 2),
    arith_mean_max DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_kilavuz FOREIGN KEY (kilavuz_id) REFERENCES kilavuzlar(id) ON DELETE CASCADE
);

-- İndeksler (Performans için)
CREATE INDEX idx_users_tc_number ON users(tc_number);
CREATE INDEX idx_admins_email ON admins(email);
CREATE INDEX idx_admins_tc_number ON admins(tc_number);
CREATE INDEX idx_tahliller_tc_number ON tahliller(tc_number);
CREATE INDEX idx_tahliller_user_id ON tahliller(user_id);
CREATE INDEX idx_tahliller_created_at ON tahliller(created_at);
CREATE INDEX idx_serum_types_tahlil_id ON serum_types(tahlil_id);
CREATE INDEX idx_kilavuzlar_guide_name ON kilavuzlar(guide_name);
CREATE INDEX idx_kilavuz_rows_kilavuz_id ON kilavuz_rows(kilavuz_id);
CREATE INDEX idx_kilavuz_rows_serum_type ON kilavuz_rows(serum_type);

-- Updated_at otomatik güncelleme fonksiyonu
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger'lar
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tahliller_updated_at BEFORE UPDATE ON tahliller
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kilavuzlar_updated_at BEFORE UPDATE ON kilavuzlar
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

