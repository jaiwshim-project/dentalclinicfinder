-- =============================================
-- DentalClinicFinder Database Schema
-- =============================================

-- 1. 지역 테이블
CREATE TABLE regions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 사용자 테이블 (Supabase Auth와 연동)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(100),
    phone VARCHAR(20),
    user_type VARCHAR(20) DEFAULT 'patient' CHECK (user_type IN ('patient', 'doctor', 'admin')),
    plan_type VARCHAR(20) DEFAULT 'free' CHECK (plan_type IN ('free', 'basic', 'premium')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 병원 테이블
CREATE TABLE hospitals (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    website VARCHAR(255),
    region_id INTEGER REFERENCES regions(id),
    hospital_type VARCHAR(50),
    specialty VARCHAR(100),
    specialized_treatment VARCHAR(100),
    operating_hours TEXT,
    is_24h BOOLEAN DEFAULT FALSE,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 의사(원장) 테이블
CREATE TABLE doctors (
    id SERIAL PRIMARY KEY,
    hospital_id INTEGER REFERENCES hospitals(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    name VARCHAR(100) NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
    specialty VARCHAR(100),
    experience VARCHAR(50),
    contact VARCHAR(20),
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 의사 전문분야 테이블
CREATE TABLE doctor_specialties (
    id SERIAL PRIMARY KEY,
    doctor_id INTEGER REFERENCES doctors(id) ON DELETE CASCADE,
    specialty VARCHAR(100) NOT NULL
);

-- 6. 의사 학력/경력 테이블
CREATE TABLE doctor_education (
    id SERIAL PRIMARY KEY,
    doctor_id INTEGER REFERENCES doctors(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0
);

-- 7. 의사 성과 테이블
CREATE TABLE doctor_achievements (
    id SERIAL PRIMARY KEY,
    doctor_id INTEGER REFERENCES doctors(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    icon VARCHAR(10)
);

-- 8. AI 평가 점수 테이블
CREATE TABLE ai_scores (
    id SERIAL PRIMARY KEY,
    hospital_id INTEGER REFERENCES hospitals(id) ON DELETE CASCADE,
    doctor_id INTEGER REFERENCES doctors(id) ON DELETE CASCADE,
    claude_score INTEGER DEFAULT 0,
    gpt_score INTEGER DEFAULT 0,
    grok_score INTEGER DEFAULT 0,
    total_score INTEGER DEFAULT 0,
    ai_talk_count INTEGER DEFAULT 0,
    newspaper_count INTEGER DEFAULT 0,
    broadcast_count INTEGER DEFAULT 0,
    evaluated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(hospital_id, doctor_id)
);

-- 9. 환자 리뷰 테이블
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    hospital_id INTEGER REFERENCES hospitals(id) ON DELETE CASCADE,
    doctor_id INTEGER REFERENCES doctors(id),
    user_id UUID REFERENCES users(id),
    author_name VARCHAR(100),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    content TEXT,
    treatment_type VARCHAR(100),
    visit_date DATE,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. 비용 정보 테이블
CREATE TABLE treatment_costs (
    id SERIAL PRIMARY KEY,
    hospital_id INTEGER REFERENCES hospitals(id) ON DELETE CASCADE,
    treatment_category VARCHAR(100) NOT NULL,
    treatment_name VARCHAR(200) NOT NULL,
    min_price INTEGER,
    max_price INTEGER,
    price_unit VARCHAR(20) DEFAULT '원',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. FAQ 테이블
CREATE TABLE faqs (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50),
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. 블로그/뉴스 테이블
CREATE TABLE blog_posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    content TEXT,
    excerpt TEXT,
    author_id UUID REFERENCES users(id),
    category VARCHAR(50),
    thumbnail_url TEXT,
    is_featured BOOLEAN DEFAULT FALSE,
    view_count INTEGER DEFAULT 0,
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. 미디어(신문/방송) 테이블
CREATE TABLE media_coverage (
    id SERIAL PRIMARY KEY,
    hospital_id INTEGER REFERENCES hospitals(id),
    doctor_id INTEGER REFERENCES doctors(id),
    media_type VARCHAR(20) CHECK (media_type IN ('newspaper', 'broadcast', 'online')),
    title VARCHAR(300) NOT NULL,
    source VARCHAR(100),
    url TEXT,
    published_date DATE,
    thumbnail_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 14. 교육 프로그램 테이블
CREATE TABLE education_programs (
    id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    program_type VARCHAR(50),
    duration VARCHAR(50),
    price INTEGER,
    max_participants INTEGER,
    instructor VARCHAR(100),
    thumbnail_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 15. 교육 자료 테이블
CREATE TABLE education_materials (
    id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    material_type VARCHAR(50),
    url TEXT,
    thumbnail_url TEXT,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 16. 공지사항 테이블
CREATE TABLE announcements (
    id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    content TEXT,
    icon VARCHAR(10),
    is_important BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 인덱스 생성
-- =============================================
CREATE INDEX idx_hospitals_region ON hospitals(region_id);
CREATE INDEX idx_doctors_hospital ON doctors(hospital_id);
CREATE INDEX idx_reviews_hospital ON reviews(hospital_id);
CREATE INDEX idx_reviews_doctor ON reviews(doctor_id);
CREATE INDEX idx_ai_scores_hospital ON ai_scores(hospital_id);
CREATE INDEX idx_media_hospital ON media_coverage(hospital_id);

-- =============================================
-- RLS (Row Level Security) 정책
-- =============================================

-- 테이블별 RLS 활성화
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- 공개 읽기 정책 (병원, 의사, 리뷰는 누구나 조회 가능)
CREATE POLICY "Public read access" ON hospitals FOR SELECT USING (true);
CREATE POLICY "Public read access" ON doctors FOR SELECT USING (true);
CREATE POLICY "Public read access" ON reviews FOR SELECT USING (true);
CREATE POLICY "Public read access" ON regions FOR SELECT USING (true);
CREATE POLICY "Public read access" ON ai_scores FOR SELECT USING (true);
CREATE POLICY "Public read access" ON faqs FOR SELECT USING (is_active = true);
CREATE POLICY "Public read access" ON blog_posts FOR SELECT USING (published_at IS NOT NULL);
CREATE POLICY "Public read access" ON announcements FOR SELECT USING (is_active = true);

-- 사용자 본인 데이터 접근 정책
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

-- 리뷰 작성 정책
CREATE POLICY "Authenticated users can create reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reviews" ON reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reviews" ON reviews FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- 초기 데이터 삽입
-- =============================================

-- 지역 데이터
INSERT INTO regions (name) VALUES
('서울'),
('경기'),
('인천'),
('강원'),
('대전'),
('대구'),
('부산');

-- 샘플 FAQ 데이터
INSERT INTO faqs (category, question, answer, sort_order) VALUES
('서비스', 'DentalClinicFinder는 어떤 서비스인가요?', 'AI 기반으로 치과병원의 신뢰도와 소통 능력을 객관적으로 평가하여 환자분들이 최적의 치과를 찾을 수 있도록 도와드리는 플랫폼입니다.', 1),
('평가', 'AI 평가는 어떻게 이루어지나요?', 'Claude, GPT, Grok 등 여러 AI 모델을 활용하여 병원의 온라인 평판, 환자 후기, 의료 서비스 품질 등을 종합적으로 분석합니다.', 2),
('비용', '서비스 이용료가 있나요?', '기본 검색과 병원 정보 조회는 무료입니다. 프리미엄 기능(상세 분석 리포트, 비교 기능 등)은 유료 플랜에서 이용 가능합니다.', 3),
('회원', '회원가입은 어떻게 하나요?', '홈페이지 우측 상단의 회원가입 버튼을 클릭하여 이메일 또는 소셜 계정으로 간편하게 가입하실 수 있습니다.', 4);

-- 샘플 공지사항
INSERT INTO announcements (title, icon, is_important) VALUES
('DentalClinicFinder 서비스 오픈 안내', '💬', true),
('서비스 이용방법 안내 업데이트', '📊', false);
