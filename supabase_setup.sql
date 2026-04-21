# Script SQL — Ejecutar en Supabase SQL Editor
# URL: https://egljgmaibeiocwzakufl.supabase.co/project/default/sql

# 1. TABLA DE EMPRESAS
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  corporate_limit NUMERIC DEFAULT 0,
  daily_trips_limit INTEGER DEFAULT 2,
  allowed_schedules TEXT[] DEFAULT ARRAY['06:00 - 22:00'],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

# 2. TABLA DE USUARIOS (vinculada a Firebase Auth por firebase_uid)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT,
  display_name TEXT,
  name TEXT,
  photo_url TEXT,
  role TEXT DEFAULT 'normal',
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  estado_solicitud TEXT DEFAULT 'ninguno',
  rol_solicitado TEXT,
  is_active BOOLEAN DEFAULT true,
  full_name TEXT,
  phone TEXT,
  position TEXT,
  notas TEXT,
  corporate_limit NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

# 3. HABILITAR REALTIME en ambas tablas
ALTER PUBLICATION supabase_realtime ADD TABLE companies;
ALTER PUBLICATION supabase_realtime ADD TABLE users;

# 4. ROW LEVEL SECURITY — permitir acceso autenticado (ajustar según necesidad)
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

# Política temporal: Acceso total para todos los usuarios autenticados
# (Puedes hacer esto más estricto después)
CREATE POLICY "allow_all_authenticated" ON companies
  FOR ALL USING (true);

CREATE POLICY "allow_all_authenticated" ON users
  FOR ALL USING (true);

# 5. STORAGE BUCKET para fotos de perfil
# Ir a Storage > New Bucket > Nombre: "profile-photos" > Public: TRUE
