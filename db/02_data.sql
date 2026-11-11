INSERT INTO users (username, email) VALUES 
('john_doe', 'john@example.com'),
('jane_smith', 'jane@example.com');

INSERT INTO categories (name, type, user_id) VALUES 
('Salary', 'income', 1),
('Groceries', 'expense', 1),
('Entertainment', 'expense', 1),
('Freelance', 'income', 2),
('Rent', 'expense', 2);

INSERT INTO tasks (title, description, start_date, end_date, status, priority, user_id, category_id) VALUES 
('Complete project proposal', 'Finish the proposal for client review', DATE '2026-11-05', DATE '2026-11-10', 'in_progress', 4, 1, 3),
('Buy groceries', 'Weekly grocery shopping', DATE '2026-11-06', DATE '2026-11-06', 'pending', 3, 1, 2),
('Submit quarterly report', 'Prepare and submit Q4 financial report', DATE '2026-11-15', DATE '2026-11-20', 'pending', 5, 2, 5);

INSERT INTO transactions (amount, description, transaction_date, type, user_id, category_id) VALUES 
(3000.00, 'Monthly salary', DATE '2026-11-01', 'income', 1, 1),
(85.30, 'Grocery shopping', DATE '2026-11-03', 'expense', 1, 2),
(200.00, 'Movie tickets', DATE '2026-11-04', 'expense', 1, 3),
(1500.00, 'Freelance work payment', DATE '2026-11-02', 'income', 2, 4),
(1200.00, 'Monthly rent', DATE '2026-11-01', 'expense', 2, 5);

INSERT INTO budgets (user_id, category_id, amount, start_date, end_date) VALUES 
(1, 2, 300.00, DATE '2026-11-01', DATE '2026-11-30'),
(1, 3, 150.00, DATE '2026-11-01', DATE '2026-11-30'),
(2, 5, 1500.00, DATE '2026-11-01', DATE '2026-11-30');