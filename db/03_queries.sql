-- 사용자별 월간 수입과 지출 통계
WITH monthly_summary AS (
    SELECT 
        u.username,
        EXTRACT(YEAR FROM t.transaction_date) AS year,
        EXTRACT(MONTH FROM t.transaction_date) AS month,
        SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END) AS total_income,
        SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END) AS total_expense
    FROM transactions t
    JOIN users u ON t.user_id = u.user_id
    WHERE EXTRACT(YEAR FROM t.transaction_date) = 2026
    GROUP BY u.username, EXTRACT(YEAR FROM t.transaction_date), EXTRACT(MONTH FROM t.transaction_date)
)
SELECT * FROM monthly_summary ORDER BY month;

-- 사용자별 과제 진행률
SELECT 
    u.username,
    COUNT(*) AS total_tasks,
    SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) AS completed_tasks,
    ROUND(SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS completion_rate
FROM tasks t
JOIN users u ON t.user_id = u.user_id
GROUP BY u.username;

-- 과제별 카테고리별 평균 우선순위
SELECT 
    c.name AS category_name,
    AVG(t.priority) AS avg_priority
FROM tasks t
JOIN categories c ON t.category_id = c.category_id
WHERE c.type = 'expense'
GROUP BY c.name;

-- 사용자별 최신 5개의 거래 내역
SELECT 
    u.username,
    t.description,
    t.amount,
    t.transaction_date,
    t.type
FROM transactions t
JOIN users u ON t.user_id = u.user_id
ORDER BY t.transaction_date DESC
FETCH FIRST 5 ROWS ONLY;

-- 사용자별 카테고리별 예산 및 소비 현황
WITH user_category_spending AS (
    SELECT 
        u.username,
        c.name AS category_name,
        b.amount AS budget_amount,
        NVL(SUM(t.amount), 0) AS spent_amount,
        ROUND(NVL(SUM(t.amount), 0) / b.amount * 100, 2) AS spent_percentage
    FROM budgets b
    JOIN users u ON b.user_id = u.user_id
    JOIN categories c ON b.category_id = c.category_id
    LEFT JOIN transactions t ON b.user_id = t.user_id AND b.category_id = t.category_id 
        AND t.transaction_date BETWEEN b.start_date AND b.end_date
        AND t.type = 'expense'
    WHERE EXTRACT(YEAR FROM b.start_date) = 2026
    GROUP BY u.username, c.name, b.amount
)
SELECT * FROM user_category_spending ORDER BY username, category_name;

-- 예산 초과 알림: 사용자별 카테고리별 예산이 초과된 내역
WITH budget_exceeded AS (
    SELECT 
        u.username,
        c.name AS category_name,
        b.amount AS budget_amount,
        SUM(t.amount) AS spent_amount,
        (SUM(t.amount) - b.amount) AS excess_amount
    FROM budgets b
    JOIN users u ON b.user_id = u.user_id
    JOIN categories c ON b.category_id = c.category_id
    JOIN transactions t ON b.user_id = t.user_id AND b.category_id = t.category_id 
        AND t.transaction_date BETWEEN b.start_date AND b.end_date
        AND t.type = 'expense'
    WHERE EXTRACT(YEAR FROM b.start_date) = 2026
    GROUP BY u.username, c.name, b.amount
    HAVING SUM(t.amount) > b.amount
)
SELECT * FROM budget_exceeded ORDER BY username, excess_amount DESC;

-- 카테고리별 예산과 실제 소비 금액의 비교
SELECT 
    c.name AS category_name,
    c.type,
    NVL(SUM(b.amount), 0) AS total_budget,
    NVL(SUM(t.amount), 0) AS total_spent,
    CASE WHEN NVL(SUM(b.amount), 0) > 0 THEN ROUND(NVL(SUM(t.amount), 0) / NVL(SUM(b.amount), 1) * 100, 2) ELSE 0 END AS spent_ratio
FROM categories c
LEFT JOIN budgets b ON c.category_id = b.category_id
LEFT JOIN transactions t ON c.category_id = t.category_id AND t.type = 'expense'
WHERE c.type = 'expense'
GROUP BY c.name, c.type;

-- 사용자별 가장 많은 소비 카테고리
WITH user_category_spending AS (
    SELECT 
        u.username,
        c.name AS category_name,
        SUM(t.amount) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY u.user_id ORDER BY SUM(t.amount) DESC) AS rn
    FROM transactions t
    JOIN users u ON t.user_id = u.user_id
    JOIN categories c ON t.category_id = c.category_id
    WHERE t.type = 'expense'
    GROUP BY u.username, c.name, u.user_id
)
SELECT username, category_name, total_spent
FROM user_category_spending
WHERE rn = 1;

-- 예산 설정이 없는 카테고리
SELECT 
    u.username,
    c.name AS category_name
FROM users u
JOIN categories c ON u.user_id = c.user_id
LEFT JOIN budgets b ON u.user_id = b.user_id AND c.category_id = b.category_id
WHERE b.user_id IS NULL;

-- 월별 예산 사용률 추이 (2026년 기준)
SELECT 
    u.username,
    EXTRACT(YEAR FROM b.start_date) AS year,
    EXTRACT(MONTH FROM b.start_date) AS month,
    SUM(b.amount) AS total_budget,
    NVL(SUM(t.amount), 0) AS total_spent,
    CASE WHEN SUM(b.amount) > 0 THEN ROUND(NVL(SUM(t.amount), 0) / SUM(b.amount) * 100, 2) ELSE 0 END AS usage_rate
FROM budgets b
JOIN users u ON b.user_id = u.user_id
LEFT JOIN transactions t ON b.user_id = t.user_id AND b.category_id = t.category_id 
    AND t.transaction_date BETWEEN b.start_date AND b.end_date
    AND t.type = 'expense'
WHERE EXTRACT(YEAR FROM b.start_date) = 2026
GROUP BY u.username, EXTRACT(YEAR FROM b.start_date), EXTRACT(MONTH FROM b.start_date)
ORDER BY month;