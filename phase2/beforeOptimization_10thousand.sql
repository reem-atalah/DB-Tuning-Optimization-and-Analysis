CREATE SCHEMA IF NOT EXISTS `onlinestore2_b10` ;
use `onlinestore2_b10`; 
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

-- number of Data is 10,000
-- 1 : 52 sec
-- EXPLAIN
-- "-> Inner hash join (no condition)  (cost=9762442.15 rows=97450000) (actual time=171.051..15274.991 rows=100000000 loops=1)
--     -> Table scan on c  (cost=0.23 rows=9745) (actual time=1.344..72.263 rows=10000 loops=1)
--     -> Hash
--         -> Nested loop inner join  (cost=16080.50 rows=10000) (actual time=17.153..154.877 rows=10000 loops=1)
--             -> Nested loop inner join  (cost=11980.50 rows=10000) (actual time=17.131..122.053 rows=10000 loops=1)
--                 -> Index scan on oc using CustomerId  (cost=1032.23 rows=10000) (actual time=16.123..28.960 rows=10000 loops=1)
--                 -> Single-row index lookup on p using PRIMARY (ID=oc.ProductId)  (cost=0.99 rows=1) (actual time=0.009..0.009 rows=1 loops=10000)
--             -> Single-row index lookup on o using PRIMARY (Id=oc.OrderId)  (cost=0.31 rows=1) (actual time=0.003..0.003 rows=1 loops=10000)
-- "

explain analyze select c.FirstName, c.SecondName, p.name as product_name
from `OrderComponents` as oc, `Order` as o, `Product` as p, `Customer` as c
where oc.ProductId = p.Id  and oc.OrderId = o.Id ;

-- 2 : 0.047
-- EXPLAIN
-- "-> Nested loop inner join  (cost=14715.21 rows=19364) (actual time=17.450..159.382 rows=9000 loops=1)
--     -> Nested loop inner join  (cost=7937.66 rows=19364) (actual time=17.307..117.596 rows=9000 loops=1)
--         -> Index scan on d using PhoneNumber  (cost=1160.10 rows=10033) (actual time=16.515..29.713 rows=10000 loops=1)
--         -> Index lookup on o using DeliveryManId (DeliveryManId=d.Id)  (cost=0.48 rows=2) (actual time=0.007..0.008 rows=1 loops=10000)
--     -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.25 rows=1) (actual time=0.004..0.004 rows=1 loops=9000)
-- "

explain analyze select c.FirstName, c.SecondName
from `Order` as o, `Customer` as c  ,DeliveryMan as d
where o.CustomerId = c.Id and o.DeliveryManId = d.Id;

-- 3 : 0.234
-- EXPLAIN
-- "-> Nested loop inner join  (cost=20029.40 rows=18046) (actual time=1.381..236.002 rows=74225 loops=1)
--     -> Nested loop inner join  (cost=15654.04 rows=10268) (actual time=0.867..127.366 rows=9000 loops=1)
--         -> Nested loop inner join  (cost=4627.10 rows=10268) (actual time=0.062..46.111 rows=9000 loops=1)
--             -> Filter: (o.DeliveryManId is not null)  (cost=1033.30 rows=10268) (actual time=0.044..8.894 rows=9000 loops=1)
--                 -> Table scan on o  (cost=1033.30 rows=10268) (actual time=0.043..6.961 rows=10000 loops=1)
--             -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.25 rows=1) (actual time=0.004..0.004 rows=1 loops=9000)
--         -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.97 rows=1) (actual time=0.009..0.009 rows=1 loops=9000)
--     -> Index lookup on oc using CustomerId (CustomerId=o.CustomerId)  (cost=0.25 rows=2) (actual time=0.005..0.011 rows=8 loops=9000)
-- "

explain analyze select c.FirstName, c.SecondName
from `OrderComponents` as oc,`Order` as o, `Customer` as c  ,DeliveryMan as d
where o.CustomerId = c.Id and oc.CustomerId = c.Id and o.DeliveryManId = d.Id;

-- 4 : 0.016
-- EXPLAIN
-- "-> Nested loop inner join  (cost=14601.19 rows=10000) (actual time=16.330..125.917 rows=10000 loops=1)
--     -> Nested loop inner join  (cost=11101.19 rows=10000) (actual time=16.297..101.253 rows=10000 loops=1)
--         -> Index scan on oc using CustomerId  (cost=1032.23 rows=10000) (actual time=0.049..5.435 rows=10000 loops=1)
--         -> Single-row index lookup on p using PRIMARY (ID=oc.ProductId)  (cost=0.91 rows=1) (actual time=0.009..0.009 rows=1 loops=10000)
--     -> Single-row index lookup on o using PRIMARY (Id=oc.OrderId)  (cost=0.25 rows=1) (actual time=0.002..0.002 rows=1 loops=10000)
-- "

explain analyze select p.name as product_name
from `OrderComponents` as oc, `Order` as o, `Product` as p
where oc.ProductId = p.Id  and oc.OrderId = o.Id ;

-- 5 no space left on disk
select c.FirstName, p.name, d.Email
from `OrderComponents` as oc, `Order` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p 
where d.FirstName='Andrew' in (select d.Id from `DeliveryMan` as d 
								where d.Id in (select o.DeliveryManId from `Order` as o
                                where o.Id in (select p.Id from `Product` as p 
                                where p.Id in (select oc.ProductId from `OrderComponents` as oc
                                where oc.CustomerId in (select o.CustomerId from `Order` as o )))));

-- 5 after rearrangement of joins (query optimization) 
-- 36 sec
select c.FirstName, p.name, d.Email
from `OrderComponents` as oc, `Order` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p  
where c.Id in (select o.CustomerId from `Order` as o
				where o.CustomerId in (select oc.CustomerId from `OrderComponents` as oc
                where oc.ProductId in (select p.Id from `Product` as p  
                where p.Id in (select o.Id from `Order` as o 
                where o.DeliveryManId in (select d.Id from `DeliveryMan` as d
                where d.FirstName='Andrew' )))));

-- analyze before showing status to get updated status
ANALYZE TABLE `Order`;
ANALYZE TABLE `ordercomponents`;
ANALYZE TABLE `customer`;
ANALYZE TABLE `deliveryman`;
ANALYZE TABLE `product`;



-- get statistics
show status;
select * from INFORMATION_SCHEMA.TABLES where table_schema = 'onlinestore2_b10';

select * from `order` ;

