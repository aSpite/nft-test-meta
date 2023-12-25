-- CREATE DATABASE IF NOT EXISTS magazine;

-- USE magazine;

-- CREATE TABLE IF NOT EXISTS suppliers (
--         supplierID  INT UNSIGNED  NOT NULL AUTO_INCREMENT, 
--         name        VARCHAR(30)   NOT NULL DEFAULT '', 
--         phone       CHAR(8)       NOT NULL DEFAULT '',
--         PRIMARY KEY (supplierID)
--        );

-- CREATE TABLE IF NOT EXISTS products (
--         productID    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
--         productCode  CHAR(3)       NOT NULL DEFAULT '',
--         name         VARCHAR(30)   NOT NULL DEFAULT '',
--         supplierID   INT UNSIGNED  NOT NULL,
--         quantity     INT UNSIGNED  NOT NULL DEFAULT 0,
--         price        DECIMAL(7,2)  NOT NULL DEFAULT 99999.99,
--         PRIMARY KEY  (productID)
-- );

-- ALTER TABLE products
--        ADD FOREIGN KEY (supplierID) REFERENCES suppliers (supplierID);

-- INSERT INTO suppliers VALUES
--         (1, 'ABC Traders', '88881111'), 
--         (2, 'OYAL', '99442222'), 
--         (3, 'MR Fix', '90055333'),
--         (4, 'Coloritm', '99455333');

-- INSERT INTO products (productCode, name, supplierID, quantity, price) VALUES
--         ('PEC', 'Pencil 2B', 1, 10000, 0.48),
--         ('PEC', 'Pencil 2H', 1, 8000, 0.49),
--         ('PEN', 'Pen Red', 1, 12000, 1.20),
--         ('PEN', 'Pen Blue', 2, 12500, 1.15),
--         ('PEN', 'Pen Black', 2, 13000, 1.00),
--         ('PPR', 'A4', 4, 500, 4.50),
--         ('PPR', 'A5', 4, 800, 5.50),
--         ('PPR', 'A3', 2, 740, 8.00),
--         ('PPR', 'A2', 2, 250, 10.00),
--         ('PEC', 'Pencil Color Set N50', 3, 1000, 25.50),
--         ('PEC', 'Pencil Color Set N25', 1, 1100, 20.50),
--         ('PEC', 'Pencil Color Set N10', 1, 700, 10.00),
--         ('BLK', 'Blackboard 2 x 1.5', 2, 210, 20.00),
--         ('BLK', 'Blackboard 1 x 0.5', 3, 200, 12.00),
--         ('BLK', 'Blackboard 0.5 x 0.2', 2, 400, 6.00);

-- CREATE TABLE IF NOT EXISTS deleted_products (
--         productID    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
--         productCode  CHAR(3)       NOT NULL DEFAULT '',
--         name         VARCHAR(30)   NOT NULL DEFAULT '',
--         supplierID   INT UNSIGNED  NOT NULL,
--         quantity     INT UNSIGNED  NOT NULL DEFAULT 0,
--         price        DECIMAL(7,2)  NOT NULL DEFAULT 99999.99,
--         deletedAt    TIMESTAMP     NOT NULL DEFAULT NOW(),
--         PRIMARY KEY  (productID)
-- );


-- 1. Create procedure, to get `total sum of quantities` of all products by product code (use IN, OUT);  [1.4]
DROP PROCEDURE IF EXISTS getTotalSumOfQuantities;
DELIMITER //
CREATE PROCEDURE getTotalSumOfQuantities (
    IN product_code CHAR(3), 
    OUT total_sum_of_quantities INT
)
BEGIN
    SELECT SUM(quantity) 
    INTO total_sum_of_quantities 
    FROM products 
    WHERE productCode = product_code;
END //
DELIMITER ;

SET @quantitiesTotalSum = 0;
CALL getTotalSumOfQuantities('PEN', @quantitiesTotalSum);
SELECT @quantitiesTotalSum;


-- 2. Create procedure, to count of all products and total sum of all (quantities)products by each suppliers (use IN, OUT);  [1.4]

DROP PROCEDURE IF EXISTS getProductCountsAndQuantitiesTotalSum;
DELIMITER //
CREATE PROCEDURE getProductCountsAndQuantitiesTotalSum (
    IN supplier_name VARCHAR(30), 
    OUT total_count_of_products INT,
    OUT total_sum_of_quantities INT
)
BEGIN
    SELECT COUNT(*) 
    INTO total_count_of_products 
    FROM products p
    INNER JOIN suppliers s ON p.supplierID = s.supplierID
    WHERE s.name = supplier_name;
    
    SELECT SUM(quantity)
    INTO total_sum_of_quantities 
    FROM products p
    INNER JOIN suppliers s ON p.supplierID = s.supplierID
    WHERE s.name = supplier_name;
END //
DELIMITER ;

SET @productsCount = 0;
SET @quantitiesTotalSum = 0;
CALL getProductCountsAndQuantitiesTotalSum('OYAL', @productsCount, @quantitiesTotalSum);
SELECT @productsCount, @quantitiesTotalSum;


-- 3. Create a procedure to group products by productCode and displaying all products in a line, 
    -- separating by comma, and displaying counts of products;  [1.5]

DROP PROCEDURE IF EXISTS groupProductsByProductCode;
DELIMITER //
CREATE PROCEDURE groupProductsByProductCode(
    IN product_code CHAR(3),
    OUT products_count INT,
    OUT products_list VARCHAR(255)
)
BEGIN
    SELECT COUNT(*)
    INTO products_count
    FROM products
    WHERE productCode = product_code;

    SELECT GROUP_CONCAT(name SEPARATOR ', ')
    INTO products_list
    FROM products
    WHERE productCode = product_code;
END //
DELIMITER ;

SET @productsCount = 0;
SET @productsList = '';
CALL groupProductsByProductCode('PEN', @productsCount, @productsList);
SELECT @productsCount, @productsList;


-- 4. Create function, which will return `high price` or `low price` according to (if `total price` > average(price) ). 
    -- Write a simple query to use the function;  [1.4]

DROP FUNCTION IF EXISTS getHighOrLowPrice;
DELIMITER //
CREATE FUNCTION getHighOrLowPrice (
    total_price DECIMAL(7,2)
)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE average_price DECIMAL(7,2);
    SELECT AVG(price)
    INTO average_price
    FROM products;

    IF total_price > average_price THEN
        RETURN 'high price';
    ELSE
        RETURN 'low price';
    END IF;
END //
DELIMITER ;

SELECT getHighOrLowPrice(25);
SELECT getHighOrLowPrice(8);


-- 5. Create function, which will return (display) total cost of each product by percentage;
    -- Write a simple query to use the function;  [1.5]

DROP FUNCTION IF EXISTS getCostPerc;
DELIMITER //
CREATE FUNCTION getCostPerc(
    product_code CHAR(3)
)
RETURNS DECIMAL(4, 2)
DETERMINISTIC
BEGIN
    DECLARE price_total_sum DECIMAL(7, 2);
    DECLARE product_price_sum DECIMAL(7, 2);

    SELECT SUM(price)
    INTO price_total_sum
    FROM products;
    
    SELECT SUM(price)
    INTO product_price_sum
    FROM products
    WHERE productCode = product_code;

    RETURN product_price_sum * 100 / price_total_sum;
END //
DELIMITER ;

SELECT getCostPerc('PEN');


-- 6. Create after delete trigger to store (OLD) deleted product record with the current datetime;  [1.4]

DROP TRIGGER IF EXISTS after_delete_products;
DELIMITER //
CREATE TRIGGER after_delete_products
AFTER DELETE ON products
FOR EACH ROW
BEGIN
    INSERT INTO deleted_products (productID, productCode, name, supplierID, quantity, price)
    VALUES (OLD.productID, OLD.productCode, OLD.name, OLD.supplierID, OLD.quantity, OLD.price);
END //
DELIMITER ;

DELETE FROM products
WHERE name = 'Pencil 2B';

SELECT *
FROM deleted_products;

INSERT INTO products (productCode, name, supplierID, quantity, price) 
VALUES ('PEC', 'Pencil 2B', 1, 10000, 0.48);


-- 7. Create before insert trigger to signal state and highlight error, if product price is higher than 100 and smaller than 0.2;  [1.4]

DROP TRIGGER IF EXISTS before_insert_products;
DELIMITER //
CREATE TRIGGER before_insert_products
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.price > 100 OR NEW.price < 0.2 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Price must be between 0.2 and 100';
    END IF;
END //
DELIMITER ;

INSERT INTO products (productCode, name, supplierID, quantity, price) 
VALUES ('PEC', 'Pencil 2A', 1, 2000, 101);
INSERT INTO products (productCode, name, supplierID, quantity, price) 
VALUES ('PEC', 'Pencil 2A', 1, 2000, 0.1);