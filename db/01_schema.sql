CREATE TABLE users (
    user_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR2(50) NOT NULL UNIQUE,
    email VARCHAR2(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    category_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(50) NOT NULL,
    type VARCHAR2(10) CHECK (type IN ('income', 'expense')),
    user_id NUMBER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE tasks (
    task_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR2(200) NOT NULL,
    description CLOB,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR2(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    priority NUMBER CHECK (priority BETWEEN 1 AND 5),
    user_id NUMBER NOT NULL,
    category_id NUMBER,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE transactions (
    transaction_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    amount NUMBER(10, 2) NOT NULL,
    description VARCHAR2(200),
    transaction_date DATE NOT NULL,
    type VARCHAR2(10) CHECK (type IN ('income', 'expense')),
    user_id NUMBER NOT NULL,
    category_id NUMBER,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_start_date ON tasks(start_date);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);