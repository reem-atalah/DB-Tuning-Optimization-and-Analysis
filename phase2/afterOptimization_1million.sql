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

CREATE TABLE `OrderOptimized` ( 
  `CustomerId` int NOT NULL,
  `ProductId` int ,
  `QuantityOrder` int NOT NULL,
  `Id` int PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `DeliveryManId` int Default Null,
  `TotalPayment` int NOT NULL,
  `IsDelivered` boolean Default false
);

-- add multiple-column index on FK of `order` with its id to speed up the query
CREATE INDEX ordering_index_FK ON `OrderOptimized`(CustomerId, ProductId, DeliveryManId);
SHOW INDEXES FROM OrderOptimized;

-- change block size
Show variables; 
-- our read_buffer_size was 65536
-- SET SESSION read_buffer_size = 120000; -- now it's 118784, no difference

-- change cache memory space
-- innodb_buffer_pool_size was 8388608 (8M)
-- innodb_buffer_pool_size: buffer size of block for reading and joining
SET GLOBAL innodb_buffer_pool_size = 10000000; -- now it's 16777216(16M)


ALTER TABLE `OrderOptimized` ADD FOREIGN KEY (`CustomerId`) REFERENCES `Customer` (`Id`)  ON DELETE CASCADE  ON UPDATE CASCADE;

ALTER TABLE `OrderOptimized` ADD FOREIGN KEY (`DeliveryManId`) REFERENCES `DeliveryMan` (`Id`)  ON DELETE Set null  ON UPDATE CASCADE;

ALTER TABLE `OrderOptimized` ADD FOREIGN KEY (`ProductId`) REFERENCES `Product` (`ID`)  ON DELETE Set null  ON UPDATE CASCADE;


-- After optimization in schema and adding index
-- 1 : 30 min
-- 1	SIMPLE	c		ALL	PRIMARY				1022722	100.00	
-- 1	SIMPLE	o		ref	DeliveryManId,ordering_index_FK	ordering_index_FK	4	onlinestore2.c.Id	4	100.00	Using where; Using index
-- 1	SIMPLE	d		eq_ref	PRIMARY	PRIMARY	4	onlinestore2.o.DeliveryManId	1	10.00	Using where
-- EXPLAIN : actual time in ms
-- ex: 19.547ms: to read one row, 1831656.841ms : to read all rows
-- cost = 1 for reading an 8kB
-- "-> Nested loop inner join  (cost=7062568.70 rows=4931772) (actual time=19.547..1831656.841 rows=5000000 loops=1)
--     -> Nested loop inner join  (cost=1637748.78 rows=4931772) (actual time=17.648..43446.913 rows=5000000 loops=1)
--         -> Table scan on c  (cost=113277.12 rows=1022722) (actual time=16.446..7941.466 rows=1033612 loops=1)
--         -> Filter: (o.ProductId is not null)  (cost=1.01 rows=5) (actual time=0.017..0.033 rows=5 loops=1033612)
--             -> Index lookup on o using ordering_index_FK (CustomerId=c.Id)  (cost=1.01 rows=5) (actual time=0.016..0.029 rows=5 loops=1033612)
--     -> Single-row index lookup on p using PRIMARY (ID=o.ProductId)  (cost=1.00 rows=1) (actual time=0.357..0.357 rows=1 loops=5000000)
-- "

-- -----------------------------try to use EXPLAIN FORMAT=TREE
-- Filter: (payment.payment_date like '2005-08%')
-- (cost=117.43 rows=894)
-- (actual time=0.464..22.767 rows=2844 loops=2)
-- These estimates are made by the query optimizer before the query is executed, based on the available statistics. This information is also present in the EXPLAIN FORMAT=TREE output.

select c.FirstName, c.SecondName, p.name as product_name
from `OrderOptimized` as o, `Product` as p, `Customer` as c
where o.ProductId = p.ID  and o.CustomerId = c.Id ;

-- 2 : before index : 15 min
-- after index: 20sec
-- 1	SIMPLE	c		ALL	PRIMARY				1022722	100.00	
-- 1	SIMPLE	o		ref	DeliveryManId,ordering_index_FK	ordering_index_FK	4	onlinestore2.c.Id	4	100.00	Using where; Using index
-- 1	SIMPLE	d		eq_ref	PRIMARY	PRIMARY	4	onlinestore2.o.DeliveryManId	1	10.00	Using where
-- EXPLAIN
-- "-> Nested loop inner join  (cost=3363868.91 rows=4931772) (actual time=4.653..21522.098 rows=5000000 loops=1)
--     -> Nested loop inner join  (cost=1637748.78 rows=4931772) (actual time=4.640..10064.638 rows=5000000 loops=1)
--         -> Table scan on c  (cost=113277.12 rows=1022722) (actual time=3.957..1633.932 rows=1033612 loops=1)
--         -> Filter: (o.DeliveryManId is not null)  (cost=1.01 rows=5) (actual time=0.005..0.008 rows=5 loops=1033612)
--             -> Index lookup on o using ordering_index_FK (CustomerId=c.Id)  (cost=1.01 rows=5) (actual time=0.005..0.007 rows=5 loops=1033612)
--     -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.25 rows=1) (actual time=0.002..0.002 rows=1 loops=5000000)
-- "

select c.FirstName, c.SecondName
from `OrderOptimized` as o, `Customer` as c  ,`DeliveryMan` as d
where o.CustomerId = c.Id and o.DeliveryManId = d.Id;

-- 3 : now this has no meaning, at refactoring, it's typical to query 2
-- select c.FirstName, c.SecondName
-- from `OrderComponents` as oc,`Order` as o, `Customer` as c  ,DeliveryMan as d
-- where o.CustomerId = c.Id and oc.CustomerId = c.Id and o.DeliveryManId = d.Id;

-- 4 : now this is very small : 14 sec
select p.name as product_name
from `OrderOptimized` as o, `Product` as p
where o.ProductId = p.Id ;

-- 5 : before index : 1.5 hour
-- after index ordering_index_FK ON `OrderOptimized`(CustomerId, ProductId, DeliveryManId): 45 minutes Wow! it's half time less!
-- 31 minutes after changing innodb_buffer_pool_size (block size)
--  EXPLAIN ANALYZE is a profiling tool for your queries that will show you where MySQL spends time on your query and why. It will plan the query, instrument it and execute it while counting rows and measuring time spent at various points in the execution plan.
-- explain analyze: 
-- -> Nested loop inner join  (cost=12312434.72 rows=4931772) (actual time=5.732..2741420.522 rows=5000000 loops=1)
--     -> Nested loop inner join  (cost=6887614.81 rows=4931772) (actual time=4.944..567011.570 rows=5000000 loops=1)
--         -> Nested loop inner join  (cost=1637873.51 rows=4931772) (actual time=4.391..68941.898 rows=5000000 loops=1)
--             -> Table scan on c  (cost=113401.86 rows=1022722) (actual time=3.797..25439.810 rows=1033612 loops=1)
--             -> Filter: ((o.DeliveryManId is not null) and (o.ProductId is not null))  (cost=1.01 rows=5) (actual time=0.021..0.040 rows=5 loops=1033612)
--                 -> Index lookup on o using ordering_index_FK (CustomerId=c.Id)  (cost=1.01 rows=5) (actual time=0.019..0.033 rows=5 loops=1033612)
--         -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.96 rows=1) (actual time=0.099..0.099 rows=1 loops=5000000)
--     -> Single-row index lookup on p using PRIMARY (ID=o.ProductId)  (cost=1.00 rows=1) (actual time=0.434..0.434 rows=1 loops=5000000)

select c.FirstName, c.SecondName, p.name as product_name, d.PhoneNumber as delivery_phone
from `OrderOptimized` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p
where o.CustomerId = c.Id and o.ProductId = p.Id and o.DeliveryManId = d.Id;

-- 6 : after index: 26 sec
-- customer and deliveryman are neighbours? so he can get the product as fast as possible, get the phone and email to contact him
-- 1	SIMPLE	c		ALL	PRIMARY				1022722	100.00	
-- 1	SIMPLE	o		ref	DeliveryManId,ordering_index_FK	ordering_index_FK	4	onlinestore2.c.Id	4	100.00	Using where; Using index
-- 1	SIMPLE	d		eq_ref	PRIMARY	PRIMARY	4	onlinestore2.o.DeliveryManId	1	10.00	Using where

-- EXPLAIN ANALYZE
-- "-> Nested loop inner join  (cost=6887614.81 rows=493177) (actual time=186.090..29004.538 rows=5 loops=1)
--     -> Nested loop inner join  (cost=1637873.51 rows=4931772) (actual time=2.771..12376.398 rows=5000000 loops=1)
--         -> Table scan on c  (cost=113401.86 rows=1022722) (actual time=1.579..1747.596 rows=1033612 loops=1)
--         -> Filter: (o.DeliveryManId is not null)  (cost=1.01 rows=5) (actual time=0.006..0.010 rows=5 loops=1033612)
--             -> Index lookup on o using ordering_index_FK (CustomerId=c.Id)  (cost=1.01 rows=5) (actual time=0.006..0.009 rows=5 loops=1033612)
--     -> Filter: (d.City = c.City)  (cost=0.96 rows=0) (actual time=0.003..0.003 rows=0 loops=5000000)
--         -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.96 rows=1) (actual time=0.003..0.003 rows=1 loops=5000000)
-- "

-- explain format
explain FORMAT=JSON select c.city, d.email , d.PhoneNumber
from `OrderOptimized` as o, `Customer` as c ,`DeliveryMan` as d
where c.city = d.city and c.Id = o.CustomerId and o.DeliveryManId = d.Id;

-- 7 query unoptimized (I didn't run this because the optimized didn't work, this for sure won't work)
select c.FirstName,  p.name, d.Email
from `OrderOptimized` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p 
where d.FirstName='Andrew' in (select d.Id from `DeliveryMan` as d 
								where d.Id in (select o.DeliveryManId from `OrderOptimized` as o
                                where o.ProductId in (select p.Id from `Product` as p ) and 
                                o.CustomerId in (select c.Id from `Customer` as c )));

-- 7 unoptimization query (change select order) (I didn't run this because the optimized didn't work, this for sure won't work)
select c.FirstName,  p.name, d.Email
from `Customer` as c  ,`DeliveryMan` as d, `Product` as p 
where d.FirstName='Andrew' in (select d.Id from `DeliveryMan` as d,  `Customer` as c 
								where c.Id in (select p.Id from `Product` as p
                                where (p.Id,c.Id) in (select o.ProductId,o.CustomerId from `OrderOptimized` as o)));
                                
-- 7 for query optimization no space in disk
select c.FirstName, p.name, d.Email
from `OrderOptimized` as o, `Customer` as c  ,`DeliveryMan` as d, `Product` as p  
where c.Id in (select o.CustomerId from `OrderOptimized` as o
				where o.ProductId in (select p.Id from `Product` as p ) and 
                o.DeliveryManId in (select d.Id from `DeliveryMan` as d where d.FirstName="Andrew"));
                


-- 8 : 30 sec
-- EXPLAIN
-- "-> Nested loop inner join  (cost=1224916.41 rows=498692) (actual time=2.734..37994.760 rows=85411 loops=1)
--     -> Nested loop inner join  (cost=687851.19 rows=498692) (actual time=2.368..3964.943 rows=85411 loops=1)
--         -> Filter: ((o.QuantityOrder = 7) and (o.DeliveryManId is not null))  (cost=513308.84 rows=498692) (actual time=2.350..3103.431 rows=85411 loops=1)
--             -> Table scan on o  (cost=513308.84 rows=4986924) (actual time=1.963..2540.132 rows=5000000 loops=1)
--         -> Single-row index lookup on d using PRIMARY (Id=o.DeliveryManId)  (cost=0.25 rows=1) (actual time=0.009..0.009 rows=1 loops=85411)
--     -> Single-row index lookup on c using PRIMARY (Id=o.CustomerId)  (cost=0.98 rows=1) (actual time=0.398..0.398 rows=1 loops=85411)
-- "

explain analyze select c.FirstName, c.SecondName
from `OrderOptimized` as o, `Customer` as c  ,`DeliveryMan` as d
where o.CustomerId = c.Id and o.DeliveryManId = d.Id and o.QuantityOrder = '7';

-- analyze before showing status to get updated status
ANALYZE TABLE `OrderOptimized`;
ANALYZE TABLE `customer`;
ANALYZE TABLE `deliveryman`;
ANALYZE TABLE `product`;

-- get statistics
-- select * from INFORMATION_SCHEMA.STATISTICS
select * from INFORMATION_SCHEMA.TABLES where table_schema = 'onlinestore2';
show status;

select * from `OrderOptimized` ;

