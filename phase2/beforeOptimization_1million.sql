CREATE SCHEMA IF NOT EXISTS `onlinestore2` ;
use `onlinestore2`; 
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
  `PhoneNumber` int(32)  NOT NULL  UNIQUE,
  `Email` varchar(255)  NOT NULL  UNIQUE,
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
  `PhoneNumber` int(32)  NOT NULL  UNIQUE,
  `Email` varchar(255) NOT NULL  UNIQUE,
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

-- number of Data as in phase 1 report : 1M
-- 1 can't run, error: mysql client ran out of memory
select c.FirstName, c.SecondName, p.name as product_name
from `OrderComponents` as oc, `Order` as o, `Product` as p, `Customer` as c
where oc.ProductId = p.Id  and oc.OrderId = o.Id ;

-- 2 runned in 31 minutes
-- EXPLAIN
-- "-> Nested loop inner join  (cost=5014060.45 rows=2495465) (actual time=3.694..655541.403 rows=2348337 loops=1)
--    -> Nested loop inner join  (cost=2281460.30 rows=2495465) (actual time=2.662..123760.391 rows=2348337 loops=1)
--       -> Filter: (o.DeliveryManId is not null)  (cost=255536.74 rows=2495465) (actual time=1.833..6759.057 rows=2348337 loops=1)
--            -> Table scan on o  (cost=255536.74 rows=2495465) (actual time=1.831..5724.464 rows=2500000 loops=1)
--        -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.71 rows=1) (actual time=0.049..0.049 rows=1 loops=2348337)
--    -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=1.00 rows=1) (actual time=0.226..0.226 rows=1 loops=2348337)
-- "

explain analyze select c.FirstName, c.SecondName
from `Order` as o, `Customer` as c  ,DeliveryMan as d
where o.CustomerId = c.Id and o.DeliveryManId = d.Id;

-- 3 runned in 50 minutes
-- EXPLAIN
-- "-> Nested loop inner join  (cost=7430656.76 rows=8972283) (actual time=3.202..2076721.536 rows=66833928 loops=1)
--    -> Nested loop inner join  (cost=4025762.89 rows=2495465) (actual time=1.858..1089860.555 rows=2348337 loops=1)
--        -> Nested loop inner join  (cost=1345659.42 rows=2495465) (actual time=1.451..378221.979 rows=2348337 loops=1)
--            -> Filter: (o.DeliveryManId is not null)  (cost=255535.23 rows=2495465) (actual time=1.359..10810.925 rows=2348337 loops=1)
--                -> Table scan on o  (cost=255535.23 rows=2495465) (actual time=1.356..8885.824 rows=2500000 loops=1)
--            -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.34 rows=1) (actual time=0.156..0.156 rows=1 loops=2348337)
--        -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.97 rows=1) (actual time=0.302..0.302 rows=1 loops=2348337)
--    -> Index lookup on oc using CustomerId (CustomerId=o.CustomerId)  (cost=1.00 rows=4) (actual time=0.387..0.415 rows=28 loops=2348337)
-- "

explain analyze select c.FirstName, c.SecondName
from `OrderComponents` as oc,`Order` as o, `Customer` as c  ,DeliveryMan as d
where o.CustomerId = c.Id and oc.CustomerId = c.Id and o.DeliveryManId = d.Id;

-- 4 modifying query 1 to work: 28 minutes
-- EXPLAIN
-- "-> Nested loop inner join  (cost=6597613.42 rows=2887994) (actual time=2.449..1408005.212 rows=3000000 loops=1)
--    -> Nested loop inner join  (cost=3421184.48 rows=2887994) (actual time=1.542..745308.675 rows=3000000 loops=1)
--        -> Index scan on oc using CustomerId  (cost=299863.54 rows=2887994) (actual time=1.184..18315.453 rows=3000000 loops=1)
--        -> Single-row index lookup on p using PRIMARY (ID=oc.ProductId)  (cost=0.98 rows=1) (actual time=0.242..0.242 rows=1 loops=3000000)
--    -> Single-row index lookup on o using PRIMARY (Id=oc.OrderId)  (cost=1.00 rows=1) (actual time=0.220..0.220 rows=1 loops=3000000)
-- "

explain analyze select p.name as product_name
from `OrderComponents` as oc, `Order` as o, `Product` as p
where oc.ProductId = p.Id  and oc.OrderId = o.Id ;
                
-- 5 ran out of memory fter 1 hour
select c.FirstName, p.name, d.Email
from `OrderComponents` as oc, `Order` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p 
where d.FirstName='Andrew' in (select d.Id from `DeliveryMan` as d 
								where d.Id in (select o.DeliveryManId from `Order` as o
                                where o.Id in (select p.Id from `Product` as p 
                                where p.Id in (select oc.ProductId from `OrderComponents` as oc
                                where oc.CustomerId in (select o.CustomerId from `Order` as o )))));
                                
-- 5 after rearrangement of joins (query optimization) ran out of memory after 1 hour
select c.FirstName, p.name, d.Email
from `OrderComponents` as oc, `Order` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p  
where c.Id in (select o.CustomerId from `Order` as o
				where o.CustomerId in (select oc.CustomerId from `OrderComponents` as oc
                where oc.ProductId in (select p.Id from `Product` as p  
                where p.Id in (select o.Id from `Order` as o 
                where o.DeliveryManId in (select d.Id from `DeliveryMan` as d
                where d.FirstName='Andrew' )))));  
      
-- 8 it's labeled as 8 as in file "afterOptimization_1million.sql"
-- 30 sec
-- EXPLAIN
-- "-> Nested loop inner join  (cost=1026290.39 rows=288799) (actual time=1.420..26273.064 rows=48421 loops=1)
--     -> Nested loop inner join  (cost=925210.60 rows=288799) (actual time=1.407..25855.242 rows=48421 loops=1)
--         -> Nested loop inner join  (cost=613107.52 rows=288799) (actual time=1.145..15401.256 rows=51060 loops=1)
--             -> Filter: (oc.Quantity = 7)  (cost=299834.31 rows=288799) (actual time=0.875..4227.396 rows=51060 loops=1)
--                 -> Table scan on oc  (cost=299834.31 rows=2887994) (actual time=0.859..4017.717 rows=3000000 loops=1)
--             -> Single-row index lookup on c using PRIMARY (Id=oc.CustomerId)  (cost=0.98 rows=1) (actual time=0.218..0.218 rows=1 loops=51060)
--         -> Filter: (o.DeliveryManId is not null)  (cost=0.98 rows=1) (actual time=0.204..0.204 rows=1 loops=51060)
--             -> Single-row index lookup on o using PRIMARY (Id=oc.OrderId)  (cost=0.98 rows=1) (actual time=0.203..0.203 rows=1 loops=51060)
--     -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.25 rows=1) (actual time=0.008..0.008 rows=1 loops=48421)
-- "

explain analyze select c.FirstName, c.SecondName
from `OrderComponents` as oc, `Order` as o, `Customer` as c  ,`DeliveryMan` as d
where oc.CustomerId = c.Id and o.id = oc.OrderId and o.DeliveryManId = d.Id and oc.Quantity = '7';

-- get statistics
-- select * from INFORMATION_SCHEMA.STATISTICS
select * from INFORMATION_SCHEMA.TABLES where table_schema = 'onlinestore2';

-- get max row size in a table
-- SELECT MAX(LENGTH(`ProductId`)) FROM `OrderComponents`;

select * from `Product` ;

