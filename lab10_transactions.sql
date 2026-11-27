DROP TABLE IF EXISTS sells;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0.00 CHECK (balance >= 0)
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE sells (
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (shop, product)
);

INSERT INTO accounts (name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob', 500.00),
    ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke', 2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);

INSERT INTO sells (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke', 2.00),
    ('Joe''s Shop', 'Pepsi', 3.00);



-- task 1
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
COMMIT;
SELECT name, balance FROM accounts ORDER BY id;

-- answers
-- а) Alice = 900.00
--    Bob = 600.00
--    Wally = 750.00
-- б) Атомарность гарантирует, что обе операции будут зафиксированы вместе
--    или обе будут отменены. Согласованность сохраняется благодаря CHECK
--    и сохранению общей суммы. Изоляция не позволяет другим транзакциям
--    увидеть незавершённый перевод
-- в) При autocommit списание могло бы зафиксироваться до сбоя сервера,
--    а зачисление — нет. Alice потеряла бы $100, Bob их не получил бы,
--    и общая сумма на счетах уменьшилась бы на $100 до ручного исправления



-- task 2
BEGIN;
UPDATE accounts SET balance = balance - 500.00 WHERE name = 'Alice';
SELECT name, balance AS transient_uncommitted_balance
FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT name, balance AS restored_balance FROM accounts WHERE name = 'Alice';

-- answers
-- а) Во время транзакции баланс Alice временно равен 400.00 (900 - 500)
-- б) После ROLLBACK зафиксированный баланс Alice снова равен 900.00
-- в) Откат нужен, если 
--     (1) многоэтапный платёж не завершился после авторизации, но до записи в реестр
--     (2) заказу не удалось зарезервировать весь товар
--     (3) проверка данных не пройдена при создании клиента, счёта и связанных записей реестра



-- task 3
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
ROLLBACK TO SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';
COMMIT;
SELECT name, balance FROM accounts ORDER BY id;

-- answers
-- а) Alice = 800.00
--    Bob = 600.00
--    Wally = 850.00
-- б) Промежуточное зачисление Bob отменено командой ROLLBACK TO SAVEPOINT
-- в) SAVEPOINT позволяет отменить только действия после контрольной точки



--task 4
-- part A
-- terminal 1
    BEGIN ISOLATION LEVEL READ COMMITTED;
    SELECT product, price FROM products WHERE shop = 'Joe''s Shop' ORDER BY product;

-- terminal 2
   BEGIN;
   DELETE FROM products WHERE shop = 'Joe''s Shop';
   INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Fanta', 3.50);
   COMMIT;

-- terminal 1
   SELECT product, price FROM products WHERE shop = 'Joe''s Shop' ORDER BY product;
   COMMIT;


-- part B
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke', 2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);

-- terminal 1
    BEGIN ISOLATION LEVEL SERIALIZABLE;
    SELECT product, price FROM products WHERE shop = 'Joe''s Shop' ORDER BY product;

-- terminal 2
   BEGIN;
   DELETE FROM products WHERE shop = 'Joe''s Shop';
   INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Fanta', 3.50);
   COMMIT;

-- terminal 1
   SELECT product, price FROM products WHERE shop = 'Joe''s Shop' ORDER BY product;
   COMMIT;

-- answers
-- а) При READ COMMITTED первый запрос видит Coke 2.50 и Pepsi 3.00, а второй — Fanta 3.50, поскольку каждый запрос получает новый снимок
-- б) При SERIALIZABLE второй запрос видит исходные Coke и Pepsi. 
-- в) READ COMMITTED получает новый снимок MVCC для каждого запроса. SERIALIZABLE использует снимок на уровне транзакции и Serializable Snapshot Isolation (SSI)
--    для обнаружения опасных зависимостей чтения и записи; при необходимости транзакция отменяется, чтобы сохранить сериализуемый результат




-- task 5
-- terminal 1
   BEGIN ISOLATION LEVEL REPEATABLE READ;
   SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
-- terminal 2
   INSERT INTO products (shop, product, price)
     VALUES ('Joe''s Shop', 'Sprite', 4.00);
   COMMIT;
-- terminal 1
   SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
   COMMIT;

-- answers
-- а) Терминал 1 не видит Sprite. Оба агрегатных запроса вернут MAX = 3.00
--    и MIN = 2.50.
-- б) Фантомное чтение возникает, когда повторный запрос с тем же условием
--    возвращает другой набор строк, поскольку другая зафиксированная транзакция добавила, удалила или изменила строки, подходящие под это условие
-- в) Уровень REPEATABLE READ в PostgreSQL использует снимок транзакции и
--    предотвращает фантомы. ANSI SQL-92 допускает фантомы при REPEATABLE READ и требует SERIALIZABLE для их предотвращения. Более строгое поведение
--    REPEATABLE READ — особенность реализации PostgreSQL; SERIALIZABLE также обнаруживает аномалии сериализации с помощью SSI




-- task 6
-- terminal 1
   BEGIN ISOLATION LEVEL READ UNCOMMITTED;
   SELECT product, price FROM products WHERE shop = 'Joe''s Shop' ORDER BY product;
-- terminal 2
   BEGIN;
   UPDATE products SET price = 99.99
     WHERE shop = 'Joe''s Shop' AND product = 'Fanta';
-- terminal 1
   SELECT product, price FROM products WHERE shop = 'Joe''s Shop' ORDER BY product;
-- terminal 2
   ROLLBACK;
-- terminal 1
   COMMIT;


-- answers
-- а) Нет, Терминал 1 не видит незавершённое изменение цены на 99.99
--    он видит последнюю зафиксированную версию цены Fanta
-- б) Грязное чтение это чтение данных, записанных ещё не завершившейся транзакцией
--    Если она затем выполнит ROLLBACK, читатель уже мог принять решение на основе несуществующего значения, что приводит к неверным балансам, решениям или последующим записям
-- в) PostgreSQL приравнивает READ UNCOMMITTED к READ COMMITTED. Правила видимости MVCC не показывают незавершённые версии строк других транзакций



-- task 7
BEGIN;
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Mountain Dew', 3.25);
SAVEPOINT sp1;
UPDATE products SET price = 4.50 WHERE shop = 'Joe''s Shop' AND product = 'Mountain Dew';
SAVEPOINT sp2;
DELETE FROM products WHERE shop = 'Joe''s Shop' AND product = 'Mountain Dew';
ROLLBACK TO SAVEPOINT sp1;
COMMIT;
SELECT shop, product, price FROM products ORDER BY shop, product;

-- answers
-- а) Приведённый SELECT показывает итоговое содержимое products. Mountain Dew
--    присутствует с ценой 3.25 остальные строки зависят от предыдущих опытов
-- б) Вставка выполнена до sp1 и сохраняется при откате к этой точке
--    Изменение цены и удаление выполнены после sp1 и отменяются
--    Вставленная строка восстанавливается с ценой 3.25.



-- task 8.1
DO $$
DECLARE
    v_bob_id INTEGER;
    v_balance NUMERIC(10, 2);
BEGIN
    SELECT id, balance INTO v_bob_id, v_balance
    FROM accounts WHERE name = 'Bob' FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account Bob was not found';
    END IF;
    IF v_balance < 200.00 THEN
        RAISE EXCEPTION 'Insufficient funds: Bob has %, needs 200.00', v_balance;
    END IF;

    UPDATE accounts SET balance = balance - 200.00 WHERE id = v_bob_id;
    UPDATE accounts SET balance = balance + 200.00 WHERE name = 'Wally';
END;
$$;
SELECT name, balance FROM accounts WHERE name IN ('Bob', 'Wally') ORDER BY name;



-- task 8.2
UPDATE accounts SET balance = 500.00 WHERE name='Bob';


-- A
BEGIN; 
SELECT balance FROM accounts WHERE name='Bob';
-- B
BEGIN; 
SELECT balance FROM accounts WHERE name='Bob';
-- A
UPDATE accounts SET balance = balance - 400 WHERE name='Bob'; 
COMMIT;
-- B
UPDATE accounts SET balance = balance - 400 WHERE name='Bob'; 
COMMIT;


-- correct 
BEGIN;
    SELECT balance FROM accounts WHERE name = 'Bob' FOR UPDATE;
-- Если баланс меньше 400:
-- ROLLBACK;
-- Если баланс не меньше 400:
    UPDATE accounts SET balance = balance - 400 WHERE name = 'Bob';
COMMIT;



--task 8.3
DELETE FROM sells WHERE shop='Joe''s Shop';
INSERT INTO sells VALUES 
    ('Joe''s Shop','Coke',2.00),
    ('Joe''s Shop','Pepsi',3.00);

-- Сессия Sally
SELECT MAX(price) FROM sells WHERE shop = 'Joe''s Shop';

-- Сессия Joe
BEGIN;
UPDATE sells SET price = 4.00 WHERE shop = 'Joe''s Shop' AND product = 'Coke';
UPDATE sells SET price = 5.00 WHERE shop = 'Joe''s Shop' AND product = 'Pepsi';
COMMIT;

-- Сессия Sally
SELECT MIN(price) FROM sells WHERE shop = 'Joe''s Shop';

-- correct 
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price) FROM sells WHERE shop='Joe''s Shop';
SELECT MIN(price) FROM sells WHERE shop='Joe''s Shop';
COMMIT;






-- Theoretical Questions 

-- 1. ACID на примерах из банковской сферы:
-- Атомарность: списание и зачисление при переводе выполняются вместе либо
-- не выполняются вовсе. Согласованность: ограничения и бизнес-правила
-- соблюдаются до и после операции, например баланс неотрицателен и сумма
-- перевода сохраняется. Изоляция: параллельные переводы ведут себя так, будто
-- выполнены в безопасном порядке, без использования промежуточных результатов.
-- Надёжность: после подтверждения COMMIT реестр переживает сбой благодаря WAL
-- (с учётом настроек надёжности сервера).

-- 2. COMMIT фиксирует изменения транзакции и делает их видимыми
-- последующим транзакциям. ROLLBACK отменяет все незавершённые изменения
-- транзакции и восстанавливает предыдущее зафиксированное состояние.

-- 3. SAVEPOINT подходит, когда большая операция содержит необязательные
-- или повторяемые шаги: например, выбор способа доставки, импорт строк с
-- пропуском некорректной части или обработка необязательной позиции заказа.
-- Точка сохранения оставляет предыдущую корректную работу и отменяет только сбойную часть.

-- 4. Уровни изоляции ANSI:
-- READ UNCOMMITTED допускает грязные, неповторяемые и фантомные чтения.
-- READ COMMITTED запрещает грязные чтения, но допускает неповторяемые и фантомные.
-- REPEATABLE READ запрещает грязные и неповторяемые чтения, но по SQL-92
-- может допускать фантомные чтения.
-- SERIALIZABLE предотвращает все три аномалии и требует результата,
-- эквивалентного последовательному выполнению. Реализации СУБД могут быть строже:
-- PostgreSQL приравнивает READ UNCOMMITTED к READ COMMITTED; уровень REPEATABLE READ
-- предотвращает фантомы благодаря снимку, а SERIALIZABLE использует SSI.

-- 5. Грязное чтение — просмотр незавершённой записи другой транзакции.
-- ANSI READ UNCOMMITTED его допускает. PostgreSQL не показывает такие данные ни на одном уровне.

-- 6. Неповторяемое чтение возникает, когда транзакция читает строку,
-- другая транзакция фиксирует её изменение или удаление, а первый запрос читает
-- эту строку повторно и получает новое значение (или не получает строку) из нового снимка.
-- Пример: кассир читает баланс 500, другая транзакция фиксирует баланс 400,
-- и повторное чтение кассира при READ COMMITTED возвращает 400.

-- 7. Фантомное чтение — изменение набора строк при повторении запроса
-- с условием после вставок, удалений или обновлений, зафиксированных другой транзакцией.
-- ANSI SQL-92 требует SERIALIZABLE для предотвращения фантомов и допускает их
-- при REPEATABLE READ. PostgreSQL REPEATABLE READ также предотвращает фантомы
-- за счёт стабильного снимка; SERIALIZABLE дополнительно предотвращает другие
-- аномалии сериализации с помощью SSI.

-- 8. Веб-приложения с высокой нагрузкой часто выбирают READ COMMITTED:
-- каждый запрос видит свежие зафиксированные данные, транзакции реже отменяются,
-- растёт параллелизм и требуется меньше повторов. Для инвариантов между запросами
-- всё равно нужны ограничения, атомарные условные обновления и блокировки.

-- 9. СУБД координируют параллельную работу с помощью журналов транзакций,
-- снимков MVCC, блокировок строк и таблиц, проверки ограничений и анализа
-- зависимостей при сериализуемой изоляции. Они определяют видимые версии данных
-- и блокируют или отменяют конфликты, чтобы зафиксированные данные соблюдали правила.

-- 10. Незавершённые изменения не считаются зафиксированными. После сбоя
-- PostgreSQL восстанавливает данные из надёжного WAL и отменяет либо игнорирует
-- незавершённые транзакции, поэтому их изменения не становятся видимыми.
