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