CREATE OR REPLACE PACKAGE budget_pkg AS
    PROCEDURE set_user_category_budget(
        p_user_id NUMBER,
        p_category_id NUMBER,
        p_amount NUMBER,
        p_start_date DATE,
        p_end_date DATE
    );
    
    FUNCTION get_user_category_spent(
        p_user_id NUMBER,
        p_category_id NUMBER,
        p_start_date DATE,
        p_end_date DATE
    ) RETURN NUMBER;
    
    PROCEDURE check_budget_exceeded(
        p_transaction_id NUMBER
    );
END budget_pkg;
/

CREATE OR REPLACE PACKAGE BODY budget_pkg AS
    PROCEDURE set_user_category_budget(
        p_user_id NUMBER,
        p_category_id NUMBER,
        p_amount NUMBER,
        p_start_date DATE,
        p_end_date DATE
    ) IS
        e_invalid_amount EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_invalid_amount, -20001);
    BEGIN
        IF p_amount <= 0 THEN
            RAISE e_invalid_amount;
        END IF;
        
        MERGE INTO budgets b
        USING (SELECT 1 FROM DUAL) ON (
            b.user_id = p_user_id AND b.category_id = p_category_id
        )
        WHEN MATCHED THEN
            UPDATE SET
                amount = p_amount,
                start_date = p_start_date,
                end_date = p_end_date
        WHEN NOT MATCHED THEN
            INSERT (user_id, category_id, amount, start_date, end_date)
            VALUES (p_user_id, p_category_id, p_amount, p_start_date, p_end_date);
            
        -- 감사 로그 기록
        INSERT INTO audit_logs(user_id, action, table_name, description)
        VALUES (p_user_id, 'UPDATE_BUDGET', 'budgets', 'Budget updated for category ' || p_category_id);
    EXCEPTION
        WHEN e_invalid_amount THEN
            RAISE_APPLICATION_ERROR(-20001, 'Budget amount must be greater than zero');
    END;
    
    FUNCTION get_user_category_spent(
        p_user_id NUMBER,
        p_category_id NUMBER,
        p_start_date DATE,
        p_end_date DATE
    ) RETURN NUMBER IS
        v_total NUMBER := 0;
    BEGIN
        SELECT SUM(amount) INTO v_total
        FROM transactions
        WHERE user_id = p_user_id
            AND category_id = p_category_id
            AND transaction_date BETWEEN p_start_date AND p_end_date
            AND type = 'expense';
        
        RETURN NVL(v_total, 0);
    END;
    
    PROCEDURE check_budget_exceeded(
        p_transaction_id NUMBER
    ) IS
        v_user_id NUMBER;
        v_category_id NUMBER;
        v_amount NUMBER;
        v_transaction_date DATE;
        v_budget_amount NUMBER;
        v_spent_amount NUMBER;
        v_start_date DATE;
        v_end_date DATE;
        e_budget_exceeded EXCEPTION;
    BEGIN
        -- 거래 정보 조회
        SELECT t.user_id, t.category_id, t.amount, t.transaction_date
        INTO v_user_id, v_category_id, v_amount, v_transaction_date
        FROM transactions t
        WHERE transaction_id = p_transaction_id;
        
        -- 예산 기간 조회
        SELECT start_date, end_date, amount
        INTO v_start_date, v_end_date, v_budget_amount
        FROM budgets
        WHERE user_id = v_user_id AND category_id = v_category_id
            AND v_transaction_date BETWEEN start_date AND end_date;
        
        -- 해당 기간 동안 소비 금액 계산
        v_spent_amount := get_user_category_spent(v_user_id, v_category_id, v_start_date, v_end_date);
        
        -- 예산 초과 확인
        IF (v_spent_amount + v_amount) > v_budget_amount THEN
            RAISE e_budget_exceeded;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- 예산이 설정되지 않은 경우
            NULL;
        WHEN e_budget_exceeded THEN
            -- 예산 초과 시 감사 로그 기록
            INSERT INTO audit_logs(user_id, action, table_name, description)
            VALUES (v_user_id, 'BUDGET_EXCEEDED', 'transactions', 
                   'Budget exceeded for category ' || v_category_id || ', transaction id: ' || p_transaction_id);
            RAISE_APPLICATION_ERROR(-20002, 'Budget exceeded for this category');
    END;
END budget_pkg;
/