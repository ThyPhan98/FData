# TẠO DỮ LIỆU CƠ SỞ

CREATE TABLE Manufacturers (
	Code INTEGER PRIMARY KEY NOT NULL,
	Name CHAR(50) NOT NULL 
)

CREATE TABLE Products (
  Code INTEGER,
  Name VARCHAR(255) NOT NULL ,
  Price DECIMAL NOT NULL ,
  Manufacturer INTEGER NOT NULL,
  PRIMARY KEY (Code), 
  FOREIGN KEY (Manufacturer) REFERENCES Manufacturers(Code)
) ENGINE=INNODB


INSERT INTO Manufacturers(Code,Name)
VALUES (1,'Sony'),(2,'Creative Labs'),(3,'Hewlett-Packard'),(4,'Iomega'),(5,'Fujitsu'),(6,'Winchester')

INSERT INTO Products(Code,Name,Price,Manufacturer)
VALUES(1,'Hard drive',240,5),(2,'Memory',120,6),(3,'ZIP drive',150,4),(4,'Floppy disk',5,6),(5,'Monitor',240,1),
(6,'DVD drive',180,2),(7,'CD drive',90,2),(8,'Printer',270,3),(9,'Toner cartridge',66,3),(10,'DVD burner',180,2)


# THỰC HÀNH
-- 1. Select the names of all the products in the store.
SELECT Name FROM products p

-- 2. Select the names and the prices of all the products in the store.
SELECT Name, Price
FROM products p

-- 3. Select the name of the products with a price less than or equal to $200.
SELECT Name
FROM products p
WHERE Price <= 200

-- 4. Select all the products with a price between $60 and $120.
SELECT *
FROM products p
WHERE Price between 60 and 120

-- 5. Select the name and price in cents (i.e., the price must be multiplied by 100).
SELECT Name, Price*100 AS Price_in_cents 
FROM products p

-- 6. Compute the average price of all the products.
SELECT avg(Price)
FROM products p

-- 7. Compute the average price of all products with manufacturer code equal to 2.
SELECT avg(Price)
FROM products p
WHERE Manufacturer = 2

-- 8. Compute the number of products with a price larger than or equal to $180.
SELECT count(*)
FROM products p
WHERE Price >= 180

-- 9. Select the name and price of all products with a price larger than or equal to $180, 
	-- and sort first by price (in descending order), and then by name (in ascending order).
SELECT Name, Price
FROM products p
WHERE Price >= 180
ORDER BY Price desc, Name asc

-- 10. Select all the data from the products, including all the data for each product's manufacturer.
SELECT *
FROM products p
INNER JOIN manufacturers m
ON p.Manufacturer = m.Code

-- 11. Select the product name, price, and manufacturer name of all the products.
SELECT p.Name, Price, m.Name
FROM products p
INNER JOIN manufacturers m
ON p.Manufacturer = m.Code

-- 12. Select the average price of each manufacturer's products, showing only the manufacturer's code.
SELECT Manufacturer, avg(Price) 
FROM products p
GROUP BY Manufacturer

-- 13. Select the average price of each manufacturer's products, showing the manufacturer's name.
SELECT M.Name, avg(Price) 
FROM products p
INNER JOIN manufacturers m
ON P.Manufacturer = M.Code
GROUP BY m.Name

-- 14. Select the names of manufacturer whose products have an average price larger than or equal to $150.
SELECT m.Name, avg(Price)
FROM products p
INNER JOIN manufacturers m
ON p.Manufacturer = m.Code
GROUP BY m.Name
HAVING avg(Price) >= 150

-- 15. Select the name and price of the cheapest product.
SELECT Name, Price
FROM Products
WHERE Price = (SELECT min(Price) FROM Products)

-- 16. Select the name of each manufacturer along with the name and price of its most expensive product.
C1:
SELECT A.Name, A.Price, F.Name
FROM Products A 
INNER JOIN Manufacturers F
ON A.Manufacturer = F.Code
AND A.Price =
   (SELECT MAX(A.Price)
    FROM Products A
    WHERE A.Manufacturer = F.Code)

C2:
SELECT * FROM(
	SELECT A.Name AS P_Name, A.Price, F.Name AS Manu_Name, DENSE_RANK() OVER(PARTITION BY F.Name ORDER BY Price DESC) _RANK
	FROM Products A INNER JOIN Manufacturers F
	ON A.Manufacturer = F.Code) AS A
WHERE _RANK = 1

-- 17. Select the name of each manufacturer which have an average price above $145 and contain at least 2 different products.
SELECT M.Name, count(P.Code) AS p_count, avg(Price) AS  p_price
FROM Products P 
INNER JOIN Manufacturers M
ON P.Manufacturer = M.Code
GROUP BY M.Name
HAVING count(P.Code) >= 2
	AND avg(Price) > 145

-- 18. Add a new product: Loudspeakers, $70, manufacturer 2.
INSERT INTO Products(Code,Name,Price,Manufacturer)
VALUES(11,'Loudspeakers',70,2)

-- 19. Update the name of product 8 to "Laser Printer".
UPDATE Products
SET Name = 'Laser Printer'
WHERE Code = 8

-- 20. Apply a 10% discount to all products.
UPDATE Products
SET Price = Price - (Price*0.1)

select * from products p 
-- 21. Apply a 10% discount to all products with a price larger than or equal to $120.
UPDATE Products
SET Price = Price - (Price*0.1)
WHERE Price >= 120

