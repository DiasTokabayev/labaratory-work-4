-- Полное безопасное создание структуры и данных
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- === Таблицы ===
CREATE TABLE IF NOT EXISTS employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50) DEFAULT 'General',
    salary INTEGER DEFAULT 50000,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

ALTER SEQUENCE IF EXISTS employees_emp_id_seq RESTART WITH 1;

CREATE TABLE IF NOT EXISTS departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE IF NOT EXISTS projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

-- === Вставка данных ===
INSERT INTO employees (first_name, last_name, department)
VALUES ('John', 'Smith', 'IT')
ON CONFLICT DO NOTHING;

INSERT INTO employees (first_name, last_name, salary, hire_date)
VALUES ('Emily', 'Davis', DEFAULT, CURRENT_DATE)
ON CONFLICT DO NOTHING;

INSERT INTO departments (dept_name, budget, manager_id)
VALUES 
('IT', 120000, 1),
('HR', 80000, 2),
('Sales', 150000, 3)
ON CONFLICT DO NOTHING;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Robert', 'Wilson', 'IT', 50000 * 1.1, CURRENT_DATE)
ON CONFLICT DO NOTHING;

-- === Временная таблица ===
DROP TABLE IF EXISTS temp_employees;
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

-- === Операции ===
UPDATE employees SET salary = salary * 1.1;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments
SET budget = (
    SELECT AVG(salary) * 1.2
    FROM employees e
    WHERE e.department = departments.dept_name
);

UPDATE employees
SET salary = salary * 1.15, status = 'Promoted'
WHERE department = 'Sales';

DELETE FROM employees WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department FROM employees WHERE department IS NOT NULL
);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- === Работа с NULL ===
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Alice', 'Brown', NULL, NULL)
ON CONFLICT DO NOTHING;

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

-- === RETURNING и подзапросы ===
INSERT INTO employees (first_name, last_name, salary, hire_date)
VALUES ('Sophia', 'Miller', 70000, CURRENT_DATE)
ON CONFLICT DO NOTHING
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'New', 'Hire', 'Temp', 55000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'New' AND last_name = 'Hire'
);

UPDATE employees
SET salary = salary * (
    CASE
        WHEN (SELECT budget FROM departments d WHERE d.dept_name = employees.department) > 100000 THEN 1.10
        ELSE 1.05
    END
);

-- === Массовые вставки ===
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES 
('Ethan', 'Reed', 'Sales', 60000, '2022-06-10'),
('Olivia', 'White', 'HR', 55000, '2023-02-05'),
('Liam', 'Green', 'IT', 65000, '2022-09-20'),
('Ava', 'Hill', 'Sales', 58000, '2021-11-11'),
('Noah', 'Gray', 'IT', 62000, '2023-03-15')
ON CONFLICT DO NOTHING;

UPDATE employees
SET salary = salary * 1.1
WHERE emp_id IN (SELECT emp_id FROM employees ORDER BY emp_id DESC LIMIT 5);

-- === Архивация ===
DROP TABLE IF EXISTS employee_archive;
CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

-- === Проекты ===
UPDATE projects
SET end_date = COALESCE(end_date, CURRENT_DATE) + INTERVAL '30 days'
WHERE budget > 50000 AND dept_id IN (
    SELECT dept_id
    FROM departments d
    JOIN employees e ON e.department = d.dept_name
    GROUP BY d.dept_id
    HAVING COUNT(e.emp_id) > 3
);

-- === Проверка данных ===
SELECT * FROM employees;
SELECT * FROM departments;
SELECT * FROM projects;
