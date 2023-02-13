CREATE SCHEMA IF NOT EXISTS `onlinestore2_A10` ;
use `onlinestore2_a10`; 
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
CREATE INDEX ordering_index_FK ON `OrderOptimized`(CustomerId, ProductId, DeliveryManId);

ALTER TABLE `OrderOptimized` ADD FOREIGN KEY (`CustomerId`) REFERENCES `Customer` (`Id`)  ON DELETE CASCADE  ON UPDATE CASCADE;

ALTER TABLE `OrderOptimized` ADD FOREIGN KEY (`DeliveryManId`) REFERENCES `DeliveryMan` (`Id`)  ON DELETE Set null  ON UPDATE CASCADE;

ALTER TABLE `OrderOptimized` ADD FOREIGN KEY (`ProductId`) REFERENCES `Product` (`ID`)  ON DELETE Set null  ON UPDATE CASCADE;

show status;

ANALYZE TABLE `OrderOptimized`;
ANALYZE TABLE `customer`;
ANALYZE TABLE `deliveryman`;
ANALYZE TABLE `product`;

-- 1 : before index 0.063 sec
-- after index : 0.047
-- EXPLAIN
-- "-> Nested loop inner join  (cost=23291.72 rows=10162) (actual time=3.030..190.507 rows=9000 loops=1)
--     -> Nested loop inner join  (cost=12171.70 rows=10162) (actual time=2.319..122.603 rows=9000 loops=1)
--         -> Filter: (o.ProductId is not null)  (cost=1046.42 rows=10162) (actual time=1.138..14.032 rows=9000 loops=1)
--             -> Index scan on o using ordering_index_FK  (cost=1046.42 rows=10162) (actual time=1.136..12.221 rows=10000 loops=1)
--         -> Single-row index lookup on p using PRIMARY (ID=o.ProductId)  (cost=0.99 rows=1) (actual time=0.012..0.012 rows=1 loops=9000)
--     -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.99 rows=1) (actual time=0.007..0.007 rows=1 loops=9000)
-- "

explain analyze select c.FirstName, c.SecondName, p.name as product_name
from `OrderOptimized` as o, `Product` as p, `Customer` as c
where o.ProductId = p.ID  and o.CustomerId = c.Id ;

-- 2 : before index  0.062
-- after index : 0.031
-- EXPLAIN
-- "-> Nested loop inner join  (cost=8780.84 rows=10162) (actual time=17.334..197.739 rows=9000 loops=1)
--     -> Nested loop inner join  (cost=4603.12 rows=10162) (actual time=17.292..103.758 rows=9000 loops=1)
--         -> Filter: (o.DeliveryManId is not null)  (cost=1046.42 rows=10162) (actual time=16.360..30.309 rows=9000 loops=1)
--             -> Index scan on o using ordering_index_FK  (cost=1046.42 rows=10162) (actual time=16.357..28.192 rows=10000 loops=1)
--         -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.25 rows=1) (actual time=0.008..0.008 rows=1 loops=9000)
--     -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.31 rows=1) (actual time=0.010..0.010 rows=1 loops=9000)
-- "

explain analyze select c.FirstName, c.SecondName
from `OrderOptimized` as o, `Customer` as c  ,`DeliveryMan` as d
where o.CustomerId = c.Id and o.DeliveryManId = d.Id;

-- 3 :before index  0.047
-- after index : 0.015
-- EXPLAIN
-- "-> Nested loop inner join  (cost=12171.70 rows=10162) (actual time=17.558..77.238 rows=9000 loops=1)
--     -> Filter: (o.ProductId is not null)  (cost=1046.42 rows=10162) (actual time=15.993..25.491 rows=9000 loops=1)
--         -> Index scan on o using ProductId  (cost=1046.42 rows=10162) (actual time=15.717..24.309 rows=10000 loops=1)
--     -> Single-row index lookup on p using PRIMARY (ID=o.ProductId)  (cost=0.99 rows=1) (actual time=0.005..0.005 rows=1 loops=9000)
-- "

explain analyze select p.name as product_name
from `OrderOptimized` as o, `Product` as p
where o.ProductId = p.Id ;

-- 4 : before index  : 0.063
-- after index : 0.031
-- EXPLAIN
-- "-> Nested loop inner join  (cost=21008.42 rows=10162) (actual time=16.299..254.044 rows=8102 loops=1)
--     -> Nested loop inner join  (cost=11185.15 rows=10162) (actual time=16.288..133.187 rows=8102 loops=1)
--         -> Nested loop inner join  (cost=4603.12 rows=10162) (actual time=15.524..64.558 rows=8102 loops=1)
--             -> Filter: ((o.ProductId is not null) and (o.DeliveryManId is not null))  (cost=1046.42 rows=10162) (actual time=15.504..29.994 rows=8102 loops=1)
--                 -> Index scan on o using ordering_index_FK  (cost=1046.42 rows=10162) (actual time=15.500..27.465 rows=10000 loops=1)
--             -> Single-row index lookup on p using PRIMARY (ID=o.ProductId)  (cost=0.25 rows=1) (actual time=0.004..0.004 rows=1 loops=8102)
--         -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.55 rows=1) (actual time=0.008..0.008 rows=1 loops=8102)
--     -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.87 rows=1) (actual time=0.014..0.015 rows=1 loops=8102)
-- "

explain analyze select c.FirstName, c.SecondName, p.name as product_name, d.PhoneNumber as delivery_phone
from `OrderOptimized` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p
where o.CustomerId = c.Id and o.ProductId = p.Id and o.DeliveryManId = d.Id;

-- 5 : before index : 0 sec
-- after index : 0 sec
-- EXPLAIN
-- "-> Nested loop inner join  (cost=8791.18 rows=1016) (actual time=52.936..100.226 rows=1 loops=1)
--     -> Nested loop inner join  (cost=4952.20 rows=10162) (actual time=16.241..52.066 rows=9000 loops=1)
--         -> Filter: (o.DeliveryManId is not null)  (cost=1046.42 rows=10162) (actual time=15.686..22.875 rows=9000 loops=1)
--             -> Index scan on o using ordering_index_FK  (cost=1046.42 rows=10162) (actual time=15.684..21.566 rows=10000 loops=1)
--         -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.28 rows=1) (actual time=0.003..0.003 rows=1 loops=9000)
--     -> Filter: (d.City = c.City)  (cost=0.28 rows=0) (actual time=0.005..0.005 rows=0 loops=9000)
--         -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.28 rows=1) (actual time=0.005..0.005 rows=1 loops=9000)
-- "

explain analyze select c.city, d.email , d.PhoneNumber
from `OrderOptimized` as o, `Customer` as c ,`DeliveryMan` as d
where c.city = d.city and c.Id = o.CustomerId and o.DeliveryManId = d.Id;

-- get statistics
-- select * from INFORMATION_SCHEMA.STATISTICS
select * from INFORMATION_SCHEMA.TABLES where table_schema = 'onlinestore2_A10';

select * from `OrderOptimized` ;

