CREATE SCHEMA IF NOT EXISTS `onlinestore2_b100` ;
use `onlinestore2_b100`; 
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

CREATE TABLE `Order` (
  `CustomerId` int NOT NULL,
  `Id` int PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `DeliveryManId` int Default Null,
  `TotalPayment` int NOT NULL,
  `IsDelivered` boolean Default false
);


CREATE TABLE `OrderComponents` (
  `ProductId` int,
  `CustomerId` int,
  `OrderId` int,
  `Quantity` int NOT NULL,
  PRIMARY KEY (`ProductId`, `CustomerId`, `OrderId`)
);

ALTER TABLE `OrderComponents` ADD FOREIGN KEY (`CustomerId`) REFERENCES `Customer` (`Id`)  ON DELETE CASCADE  ON UPDATE CASCADE;

ALTER TABLE `OrderComponents` ADD FOREIGN KEY (`ProductId`) REFERENCES `Product` (`Id`)  ON DELETE CASCADE  ON UPDATE CASCADE;

ALTER TABLE `OrderComponents` ADD FOREIGN KEY (`OrderId`) REFERENCES `Order` (`Id`)  ON DELETE CASCADE  ON UPDATE CASCADE;

ALTER TABLE `Order` ADD FOREIGN KEY (`CustomerId`) REFERENCES `Customer` (`Id`)  ON DELETE CASCADE  ON UPDATE CASCADE;

ALTER TABLE `Order` ADD FOREIGN KEY (`DeliveryManId`) REFERENCES `DeliveryMan` (`Id`)  ON DELETE Set null  ON UPDATE CASCADE;

show status;

-- number of Data is 10,000
-- 1 : out of memory
select c.FirstName, c.SecondName, p.name as product_name
from `OrderComponents` as oc, `Order` as o, `Product` as p, `Customer` as c
where oc.ProductId = p.Id  and oc.OrderId = o.Id ;

-- 2 : 5 sec
-- EXPLAIN
-- "-> Nested loop inner join  (cost=230599.67 rows=100296) (actual time=3.241..19917.694 rows=98219 loops=1)
--     -> Nested loop inner join  (cost=120329.87 rows=100296) (actual time=1.874..10127.772 rows=98219 loops=1)
--         -> Filter: (o.DeliveryManId is not null)  (cost=10317.70 rows=100296) (actual time=1.102..312.713 rows=98219 loops=1)
--             -> Table scan on o  (cost=10317.70 rows=100296) (actual time=1.100..257.562 rows=100000 loops=1)
--         -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=1.00 rows=1) (actual time=0.099..0.099 rows=1 loops=98219)
--     -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=1.00 rows=1) (actual time=0.099..0.099 rows=1 loops=98219)
-- "

explain analyze select c.FirstName, c.SecondName
from `Order` as o, `Customer` as c  ,DeliveryMan as d
where o.CustomerId = c.Id and o.DeliveryManId = d.Id;

-- 3 : 25 sec
-- EXPLAIN
-- "-> Nested loop inner join  (cost=324921.68 rows=587118) (actual time=2.357..33067.437 rows=571388 loops=1)
--     -> Nested loop inner join  (cost=165454.76 rows=100296) (actual time=1.419..21911.565 rows=98219 loops=1)
--         -> Nested loop inner join  (cost=64224.99 rows=100296) (actual time=1.114..11369.463 rows=98219 loops=1)
--             -> Filter: (o.DeliveryManId is not null)  (cost=10315.89 rows=100296) (actual time=1.034..441.785 rows=98219 loops=1)
--                 -> Table scan on o  (cost=10315.89 rows=100296) (actual time=1.031..367.168 rows=100000 loops=1)
--             -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.44 rows=1) (actual time=0.110..0.111 rows=1 loops=98219)
--         -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.91 rows=1) (actual time=0.106..0.106 rows=1 loops=98219)
--     -> Index lookup on oc using CustomerId (CustomerId=o.CustomerId)  (cost=1.00 rows=6) (actual time=0.107..0.111 rows=6 loops=98219)
-- "

explain analyze select c.FirstName, c.SecondName
from `OrderComponents` as oc,`Order` as o, `Customer` as c  ,DeliveryMan as d
where o.CustomerId = c.Id and oc.CustomerId = c.Id and o.DeliveryManId = d.Id;

-- 4 : 1 sec
-- EXPLAIN
-- "-> Nested loop inner join  (cost=232341.72 rows=101301) (actual time=17.281..623.780 rows=100000 loops=1)
--     -> Nested loop inner join  (cost=121860.32 rows=101301) (actual time=16.943..502.427 rows=100000 loops=1)
--         -> Index scan on oc using CustomerId  (cost=10482.23 rows=101301) (actual time=0.091..100.211 rows=100000 loops=1)
--         -> Single-row index lookup on p using PRIMARY (ID=oc.ProductId)  (cost=1.00 rows=1) (actual time=0.004..0.004 rows=1 loops=100000)
--     -> Single-row index lookup on o using PRIMARY (Id=oc.OrderId)  (cost=0.99 rows=1) (actual time=0.001..0.001 rows=1 loops=100000)
-- "

explain analyze select p.name as product_name
from `OrderComponents` as oc, `Order` as o, `Product` as p
where oc.ProductId = p.Id  and oc.OrderId = o.Id ;

-- 5 
select c.FirstName, p.name, d.Email
from `OrderComponents` as oc, `Order` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p 
where d.FirstName='Andrew' in (select d.Id from `DeliveryMan` as d 
								where d.Id in (select o.DeliveryManId from `Order` as o
                                where o.Id in (select p.Id from `Product` as p 
                                where p.Id in (select oc.ProductId from `OrderComponents` as oc
                                where oc.CustomerId in (select o.CustomerId from `Order` as o )))));

-- 5 after rearrangement of joins (query optimization) no space left on disk
select c.FirstName, p.name, d.Email
from `OrderComponents` as oc, `Order` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p  
where c.Id in (select o.CustomerId from `Order` as o
				where o.CustomerId in (select oc.CustomerId from `OrderComponents` as oc
                where oc.ProductId in (select p.Id from `Product` as p  
                where p.Id in (select o.Id from `Order` as o 
                where o.DeliveryManId in (select d.Id from `DeliveryMan` as d
                where d.FirstName='Andrew' )))));
                

ANALYZE TABLE `Order`;
ANALYZE TABLE `ordercomponents`;
ANALYZE TABLE `customer`;
ANALYZE TABLE `deliveryman`;
ANALYZE TABLE `product`;

-- get statistics
-- select * from INFORMATION_SCHEMA.STATISTICS
select * from INFORMATION_SCHEMA.TABLES where table_schema = 'onlinestore2_b100';

select * from `order` ;

