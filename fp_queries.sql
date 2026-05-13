-- ============================================================
-- GoIT RDB Final Project — Kyrylo Proskurnia
-- ============================================================

-- ============================================================
-- ЗАВДАННЯ 1 — Створення схеми та завантаження даних
-- ============================================================

CREATE SCHEMA IF NOT EXISTS pandemic;

USE pandemic;

-- Таблиця завантажується через Import Wizard з файлу infectious_cases.csv
-- Перевірка кількості записів:
SELECT COUNT(*) FROM infectious_cases;


-- ============================================================
-- ЗАВДАННЯ 2 — Нормалізація до 3НФ
-- ============================================================

-- Таблиця 1: довідник країн (Entity + Code)
CREATE TABLE IF NOT EXISTS entities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity VARCHAR(255) NOT NULL,
    code   VARCHAR(10)
);

INSERT INTO entities (entity, code)
SELECT DISTINCT Entity, Code
FROM infectious_cases;

-- Таблиця 2: нормалізовані дані захворювань
CREATE TABLE IF NOT EXISTS infectious_cases_normalized (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    entity_id     INT NOT NULL,
    year          YEAR,
    number_yaws           FLOAT,
    polio_cases           FLOAT,
    cases_guinea_worm     FLOAT,
    number_rabies         FLOAT,
    number_malaria        FLOAT,
    number_hiv            FLOAT,
    number_tuberculosis   FLOAT,
    number_smallpox       FLOAT,
    number_cholera_cases  FLOAT,
    FOREIGN KEY (entity_id) REFERENCES entities(id)
);

INSERT INTO infectious_cases_normalized
    (entity_id, year, number_yaws, polio_cases, cases_guinea_worm,
     number_rabies, number_malaria, number_hiv, number_tuberculosis,
     number_smallpox, number_cholera_cases)
SELECT
    e.id,
    ic.Year,
    NULLIF(ic.Number_yaws, ''),
    NULLIF(ic.polio_cases, ''),
    NULLIF(ic.cases_guinea_worm, ''),
    NULLIF(ic.Number_rabies, ''),
    NULLIF(ic.Number_malaria, ''),
    NULLIF(ic.Number_hiv, ''),
    NULLIF(ic.Number_tuberculosis, ''),
    NULLIF(ic.Number_smallpox, ''),
    NULLIF(ic.Number_cholera_cases, '')
FROM infectious_cases ic
JOIN entities e
    ON e.entity = ic.Entity
   AND (e.code = ic.Code OR (e.code IS NULL AND ic.Code IS NULL));


-- ============================================================
-- ЗАВДАННЯ 3 — Аналіз Number_rabies
-- ============================================================

SELECT
    e.entity,
    e.code,
    ROUND(AVG(n.number_rabies), 2)  AS avg_rabies,
    MIN(n.number_rabies)             AS min_rabies,
    MAX(n.number_rabies)             AS max_rabies,
    ROUND(SUM(n.number_rabies), 2)  AS sum_rabies
FROM infectious_cases_normalized n
JOIN entities e ON e.id = n.entity_id
WHERE n.number_rabies IS NOT NULL
  AND n.number_rabies != 0
GROUP BY e.id, e.entity, e.code
ORDER BY avg_rabies DESC
LIMIT 10;


-- ============================================================
-- ЗАВДАННЯ 4 — Колонка різниці в роках
-- ============================================================

SELECT
    year,
    -- Дата 1 січня відповідного року
    MAKEDATE(year, 1)                                               AS first_jan,
    -- Поточна дата
    CURDATE()                                                        AS current_date,
    -- Різниця в роках
    TIMESTAMPDIFF(YEAR, MAKEDATE(year, 1), CURDATE())               AS years_diff
FROM infectious_cases_normalized
WHERE year IS NOT NULL
LIMIT 10;


-- ============================================================
-- ЗАВДАННЯ 5 — Власна функція
-- ============================================================

DROP FUNCTION IF EXISTS years_since;

DELIMITER //
CREATE FUNCTION years_since(input_year INT)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, MAKEDATE(input_year, 1), CURDATE());
END //
DELIMITER ;

-- Використання функції:
SELECT
    year,
    years_since(year) AS years_since_year
FROM infectious_cases_normalized
WHERE year IS NOT NULL
LIMIT 10;
