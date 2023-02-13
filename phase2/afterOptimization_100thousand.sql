CREATE SCHEMA IF NOT EXISTS `onlinestore2_A100` ;
use `onlinestore2_A100`; 
CREATE TABLE `Customer` (
  `Id` int PRIMARY KEY AUTO_INCREMENT NOT NULL,
  `FirstName` varchar(255) NOT NULL,
  `SecondName` varchar(255) NOT NULL,
  `Governorate` varchar(255)  NOT NULL,
  `City` varchar(255)  NOT NULL,
  `StreetName` varchar(255)  NOT NULL,
  `BuildingNumber` varchar(255)  NOT NULL,
  `AppartmentNumber` varchar(255) NOT NULL,
  `Gender` char,
  `PhoneNumber` int(32)  NOT NULL  ,
  `Email` varchar(255)  NOT NULL  ,
  `Password` varchar(255) NOT NULL  
);

CREATE TABLE `DeliveryMan` (
  `Id` int PRIMARY KEY AUTO_INCREMENT NOT NULL,
  `FirstName` varchar(255) NOT NULL,
  `SecondName` varchar(255) NOT NULL,
  `Governorate` varchar(255)  NOT NULL,
  `City` varchar(255)  NOT NULL,
  `StreetName` varchar(255)  NOT NULL,
  `BuildingNumber` varchar(255)  NOT NULL,
  `AppartmentNumber` varchar(255)  NOT NULL,
  `PhoneNumber` int(32)  NOT NULL  ,
  `Email` varchar(255) NOT NULL  ,
  `Password` varchar(255) NOT NULL,
  `Salary` int DEFAULT 1000,
  `Bonus` int DEFAULT 0
);

CREATE TABLE `Product` (
  `ID` INT NOT NULL AUTO_INCREMENT,
  `Name` VARCHAR(45) NOT NULL,
  `Price` DECIMAL(19,4) NOT NULL,
  `Quantity` INT NULL,
  `Description` VARCHAR(255) NULL,
  `ExpiryDate` varchar(255) NULL,
  `ProductImage` VARCHAR(255) NULL,
  `Discount` INT ZEROFILL NULL,
  `EndTimeOffer` varchar(255) NULL,
  `Frequency` INT ZEROFILL NULL,
  PRIMARY KEY (`ID`)
);

CREATE TABLE `OrderOptimized` ( 
  `CustomerId` int NOT NULL,
  `ProductId` int ,
  `QuantityOrder` int NOT NULL,
  `Id` int PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `DeliveryManId` int Default Null,
  `TotalPayment` int NOT NULL,
  `IsDelivered` boolean Default false
);

ALTER TABLE `OrderOptimized` ADD FOREIGN KEY (`CustomerId`) REFERENCES `Customer` (`Id`)  ON DELETE CASCADE  ON UPDATE CASCADE;

ALTER TABLE `OrderOptimized` ADD FOREIGN KEY (`DeliveryManId`) REFERENCES `DeliveryMan` (`Id`)  ON DELETE Set null  ON UPDATE CASCADE;

ALTER TABLE `OrderOptimized` ADD FOREIGN KEY (`ProductId`) REFERENCES `Product` (`ID`)  ON DELETE Set null  ON UPDATE CASCADE;

show status;

CREATE INDEX ordering_index_FK ON `OrderOptimized`(CustomerId, ProductId, DeliveryManId);

-- 1 : before index : 50 sec
-- after index : 27
-- EXPLAIN
-- "-> Nested loop inner join  (cost=8159.82 rows=10162) (actual time=0.105..45.538 rows=9000 loops=1)
--     -> Nested loop inner join  (cost=4603.12 rows=10162) (actual time=0.089..28.015 rows=9000 loops=1)
--         -> Filter: (o.ProductId is not null)  (cost=1046.42 rows=10162) (actual time=0.066..5.249 rows=9000 loops=1)
--             -> Index scan on o using ordering_index_FK  (cost=1046.42 rows=10162) (actual time=0.064..4.087 rows=10000 loops=1)
--         -> Single-row index lookup on p using PRIMARY (ID=o.ProductId)  (cost=0.25 rows=1) (actual time=0.002..0.002 rows=1 loops=9000)
--     -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.25 rows=1) (actual time=0.002..0.002 rows=1 loops=9000)
-- "

explain analyze select c.FirstName, c.SecondName, p.name as product_name
from `OrderOptimized` as o, `Product` as p, `Customer` as c
where o.ProductId = p.ID  and o.CustomerId = c.Id ;

-- 2 : before index : 60 sec
-- after index : 22 sec
-- EXPLAIN
-- "-> Nested loop inner join  (cost=8159.82 rows=10162) (actual time=0.160..57.312 rows=9000 loops=1)
--     -> Nested loop inner join  (cost=4603.12 rows=10162) (actual time=0.151..26.667 rows=9000 loops=1)
--         -> Filter: (o.DeliveryManId is not null)  (cost=1046.42 rows=10162) (actual time=0.128..6.184 rows=9000 loops=1)
--             -> Index scan on o using ordering_index_FK  (cost=1046.42 rows=10162) (actual time=0.126..4.807 rows=10000 loops=1)
--         -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.25 rows=1) (actual time=0.002..0.002 rows=1 loops=9000)
--     -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.25 rows=1) (actual time=0.003..0.003 rows=1 loops=9000)
-- "

explain analyze select c.FirstName, c.SecondName
from `OrderOptimized` as o, `Customer` as c  ,`DeliveryMan` as d
where o.CustomerId = c.Id and o.DeliveryManId = d.Id;

-- 3 :before index  : 0.484
-- after index : 0.5 sec
-- EXPLAIN
-- "-> Nested loop inner join  (cost=4603.12 rows=10162) (actual time=16.548..42.153 rows=9000 loops=1)
--     -> Filter: (o.ProductId is not null)  (cost=1046.42 rows=10162) (actual time=16.525..25.498 rows=9000 loops=1)
--         -> Index scan on o using ProductId  (cost=1046.42 rows=10162) (actual time=16.090..24.580 rows=10000 loops=1)
--     -> Single-row index lookup on p using PRIMARY (ID=o.ProductId)  (cost=0.25 rows=1) (actual time=0.002..0.002 rows=1 loops=9000)
-- "

explain analyze select p.name as product_name
from `OrderOptimized` as o, `Product` as p
where o.ProductId = p.Id ;

-- 4 : before index  : 87 sec
-- after index : 53 sec
-- EXPLAIN
-- "-> Nested loop inner join  (cost=11716.53 rows=10162) (actual time=0.146..142.434 rows=8102 loops=1)
--     -> Nested loop inner join  (cost=8159.82 rows=10162) (actual time=0.137..92.927 rows=8102 loops=1)
--         -> Nested loop inner join  (cost=4603.12 rows=10162) (actual time=0.123..60.765 rows=8102 loops=1)
--             -> Filter: ((o.ProductId is not null) and (o.DeliveryManId is not null))  (cost=1046.42 rows=10162) (actual time=0.094..14.228 rows=8102 loops=1)
--                 -> Index scan on o using ordering_index_FK  (cost=1046.42 rows=10162) (actual time=0.092..10.427 rows=10000 loops=1)
--             -> Single-row index lookup on p using PRIMARY (ID=o.ProductId)  (cost=0.25 rows=1) (actual time=0.005..0.005 rows=1 loops=8102)
--         -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.25 rows=1) (actual time=0.003..0.004 rows=1 loops=8102)
--     -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.25 rows=1) (actual time=0.006..0.006 rows=1 loops=8102)
-- "

explain analyze select c.FirstName, c.SecondName, p.name as product_name, d.PhoneNumber as delivery_phone
from `OrderOptimized` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p
where o.CustomerId = c.Id and o.ProductId = p.Id and o.DeliveryManId = d.Id;

-- 5 : before index :  57 sec
-- after index : 23 sec
-- EXPLAIN
-- "-> Nested loop inner join  (cost=8159.82 rows=1016) (actual time=24.399..70.182 rows=1 loops=1)
--     -> Nested loop inner join  (cost=4603.12 rows=10162) (actual time=0.102..29.961 rows=9000 loops=1)
--         -> Filter: (o.DeliveryManId is not null)  (cost=1046.42 rows=10162) (actual time=0.078..7.056 rows=9000 loops=1)
--             -> Index scan on o using ordering_index_FK  (cost=1046.42 rows=10162) (actual time=0.077..5.688 rows=10000 loops=1)
--         -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.25 rows=1) (actual time=0.002..0.002 rows=1 loops=9000)
--     -> Filter: (d.City = c.City)  (cost=0.25 rows=0) (actual time=0.004..0.004 rows=0 loops=9000)
--         -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.25 rows=1) (actual time=0.004..0.004 rows=1 loops=9000)
-- "

explain analyze select c.city, d.email , d.PhoneNumber
from `OrderOptimized` as o, `Customer` as c ,`DeliveryMan` as d
where c.city = d.city and c.Id = o.CustomerId and o.DeliveryManId = d.Id;

ANALYZE TABLE `OrderOptimized`;
ANALYZE TABLE `customer`;
ANALYZE TABLE `deliveryman`;
ANALYZE TABLE `product`;

-- get statistics
-- select * from INFORMATION_SCHEMA.STATISTICS
select * from INFORMATION_SCHEMA.TABLES where table_schema = 'onlinestore2_A100';

select * from `product` ;

