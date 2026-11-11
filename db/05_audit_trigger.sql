CREATE OR REPLACE TRIGGER tr_audit_transactions
    AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW
DECLARE
    v_action VARCHAR2(10);
    v_description VARCHAR2(200);
BEGIN
    IF INSERTING THEN
        v_action := 'INSERT';
        v_description := 'New transaction inserted: ' || :NEW.amount;
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
        v_description := 'Transaction updated: ' || :OLD.amount || ' -> ' || :NEW.amount;
    ELSIF DELETING THEN
        v_action := 'DELETE';
        v_description := 'Transaction deleted: ' || :OLD.amount;
    END IF;
    
    INSERT INTO audit_logs(user_id, action, table_name, description)
    VALUES (:NEW.user_id, v_action, 'transactions', v_description);
END;
/