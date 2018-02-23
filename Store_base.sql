use master; 
go 

if db_id (N'db') is not NULL 
	drop database db; 
go 

create database db
	on (name = db_data, filename = 'C:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\db_data.mdf', size = 10, maxsize = unlimited, filegrowth = 5%)   /*FILEGROWTH - автоувелечение размера файла, по ум. файл +=1МБ, лог += 10%*/
	log on (name = db_log, filename = 'C:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\db_log.ldf', size = 5MB, maxsize = 25GB, filegrowth = 5MB)
go

use db
go

--Магазин
create table SHOP
(	/*identity - позволяет делать инкремент; обеспечивает сущностную целостность*/
	S_NAME char(255) primary key NOT NULL,
	S_OWNER char(255) NOT NULL,
	S_LICENSE char(255) NOT NULL,
	S_OPENING_TIME time NULL,
	S_CLOSING_TIME time NULL
)

--Отдел
create table DEPARTMENT
(
	D_NAME char(255) primary key NOT NULL,
	D_OPENING_TIME datetime NULL,
	D_CLOSING_TIME datetime NULL,
	S_NAME char(255) NOT NULL
)

--Сотрудник
create table EMPLOYEE
(
	E_SNILS char(255) primary key NOT NULL,
	E_NAME char(255) NOT NULL,
	E_PHONE_NUMBER char(255) NOT NULL,
	E_ADDRESS char(255) NULL
)

--Таблица отношений: отдел-сотрудник
create table RELATION_DEPARTMENT_EMPLOYEE(
	R_NAME char(255) NOT NULL references DEPARTMENT(D_NAME) on update no action on delete cascade,
	R_SNILS char(255) NOT NULL references EMPLOYEE(E_SNILS) on update no action on delete cascade,
	R_SCHEDULE char(255) NULL,
	/*составной ключ*/
	primary key(R_NAME, R_SNILS)
)

--Товар
create table SHIPMENT
(
	S_NAME char(255) primary key NOT NULL,
	S_PRODUCER char(255) NULL,
	S_PRICE int NOT NULL
)

--Таблица отношений: отдел-товар
create table RELATION_DEPARTMENT_SHIPMENT
(
	R_NAME_DEP char(255) NOT NULL references DEPARTMENT(D_NAME) on update no action on delete cascade,
	R_NAME_SHIP char(255) NOT NULL references SHIPMENT(S_NAME) on update no action on delete cascade,
	primary key(R_NAME_DEP, R_NAME_SHIP)
)

--Покупатель
create table CUSTOMER
(
	C_NAME char(255) primary key NOT NULL,
	C_PHONE_NUMBER char(255) NOT NULL,
	C_ADDRESS char(255) NOT NULL
)

--Скидка (таблица отношений:товар-покупатель)
create table DISCOUNT
(
	DIS_PRICE int NOT NULL,
	DIS_TYPE char(255) NULL,
	DIS_OPENING_TIME datetime NULL,
	DIS_CLOSING_TIME datetime NULL,
	DIS_NAME_CUST char(255) NOT NULL references CUSTOMER(C_NAME) on update no action on delete cascade,
	DIS_NAME_SHIP char(255) NOT NULL references SHIPMENT(S_NAME) on update no action on delete cascade,
	primary key(DIS_NAME_SHIP, DIS_NAME_CUST)
)

--Скидка
create table ACTION_SALE
(
	A_NAME char(255) primary key NOT NULL,
	A_TYPE char(255) NULL,
	A_OPENING_TIME datetime NULL,
	A_CLOSING_TIME datetime NULL
)

--Таблица отношений: скидка-акция
create table RELATION_DISCOUNT_ACTION_SALE
(
	DIS_C_NAME char(255) NOT NULL references CUSTOMER(C_NAME) on update no action on delete cascade,
	DIS_A_NAME char(255) NOT NULL references ACTION_SALE(A_NAME) on update no action on delete cascade,
	primary key(DIS_C_NAME, DIS_A_NAME)
)

select * from SHOP
select * from DEPARTMENT
select * from EMPLOYEE
select * from RELATION_DEPARTMENT_EMPLOYEE
select * from SHIPMENT
select * from RELATION_DEPARTMENT_SHIPMENT
select * from DISCOUNT
select * from CUSTOMER
select * from ACTION_SALE
select * from RELATION_DISCOUNT_ACTION_SALE

/*--------------------------------------------------------------------------------------------------------------------Магазин - Отдел*/

insert into SHOP(S_NAME, S_OWNER, S_LICENSE, S_OPENING_TIME, S_CLOSING_TIME) values ('Golden cord', 'Milena', 'Лицензия на осуществление торговли. Выдана:...', '08:00:00', '00:00:00')
insert into SHOP(S_NAME, S_OWNER, S_LICENSE, S_OPENING_TIME, S_CLOSING_TIME) values ('World of music', 'Milena', 'Лицензия на осуществление торговли. Выдана:...', '08:00:00', '00:00:00')

GO
CREATE TRIGGER Trigger_insert_department
ON DEPARTMENT
INSTEAD OF INSERT
AS	
	IF EXISTS 
	(SELECT S_NAME from inserted
	where (S_NAME NOT IN (SELECT S_NAME from SHOP)))
	BEGIN
		PRINT('Такого магазина не существует')
	END
	ELSE
	insert DEPARTMENT (D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME) select D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME from inserted
GO

insert into DEPARTMENT(D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME) values ('Струнные', '08:00:00', '00:00:00', 'Golden cord')
insert into DEPARTMENT(D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME) values ('Клавишные', '08:00:00', '00:00:00', 'Golden cord')
insert into DEPARTMENT(D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME) values ('Ударные', '08:00:00', '00:00:00', 'Golden cord')
insert into DEPARTMENT(D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME) values ('Этнические', '08:00:00', '00:00:00', 'Golden cord')
/*Заполнения не произойдёт*/
insert into DEPARTMENT(D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME) values ('Литература', '08:00:00', '00:00:00', 'Golden string')

select * from SHOP
select * from DEPARTMENT

GO
CREATE TRIGGER Trigger_update_department
ON DEPARTMENT
AFTER UPDATE
AS	
	IF EXISTS 
	(SELECT S_NAME from inserted
	where (S_NAME NOT IN (SELECT S_NAME from SHOP)))
	BEGIN
	RAISERROR('Такого магазина не существует', 16, 0);
	ROLLBACK TRANSACTION
	END
GO

/*Обновления не произойдёт*/
update DEPARTMENT
set S_NAME = 'Golden_string'
where D_NAME = 'Струнные'

update DEPARTMENT
set S_NAME = 'World of music'
where D_NAME = 'Этнические'

select * from DEPARTMENT

GO
CREATE TRIGGER Trigger_update_shop
ON SHOP
INSTEAD OF UPDATE
AS	
	create table t_1(
			ID int IDENTITY PRIMARY KEY,
			S_NAME char(255),
		);
		insert into t_1(S_NAME) select S_NAME from deleted
		create table t_2(
			ID int IDENTITY PRIMARY KEY,
			S_NAME char(255), 
		);
		insert into t_2(S_NAME) select S_NAME from inserted
		create table t_3(
			ID int IDENTITY PRIMARY KEY,
			S_NAME_OLD char(255),
			S_NAME_NEW char(255),
		);
		insert into t_3(S_NAME_OLD, S_NAME_NEW) 
		select t_1.S_NAME, t_2.S_NAME
		from t_1 join t_2 on t_1.ID = t_2.ID
		select *
			from t_1;
		select *
			from t_2;
		select *
			from t_3;
		UPDATE SHOP
			set S_NAME = t.S_NAME_NEW
			from t_3 t
			where S_NAME = t.S_NAME_OLD

		UPDATE DEPARTMENT
			set S_NAME = t.S_NAME_NEW
			from t_3 t
			where S_NAME = t.S_NAME_OLD
		drop table t_1
		drop table t_2
		drop table t_3
GO

/*Произойдёт обновление родительской и дочерней таблицы*/
update SHOP
set S_NAME = 'Allegro'
where S_NAME = 'World of music'

DELETE FROM DEPARTMENT
WHERE D_NAME = 'Ударные'

select * from SHOP
select * from DEPARTMENT

GO
CREATE TRIGGER Trigger_delete_shop
ON SHOP
INSTEAD OF DELETE
AS
	DELETE FROM SHOP WHERE S_NAME IN (select S_NAME from deleted)
	DELETE FROM DEPARTMENT WHERE S_NAME IN (select S_NAME from deleted)
GO

DELETE FROM SHOP
WHERE S_NAME = 'Allegro'

select * from SHOP
select * from DEPARTMENT

/*--------------------------------------------------------------------------------------------------------------------Отдел - Сотрудник*/
insert into DEPARTMENT(D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME) values ('Ударные', '08:00:00', '00:00:00', 'Golden cord')
insert into DEPARTMENT(D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME) values ('Этнические', '08:00:00', '00:00:00', 'Golden cord')

insert into EMPLOYEE(E_SNILS, E_NAME, E_PHONE_NUMBER, E_ADDRESS) values ('11111111111', 'Masha M.', '8-915-123-12-23', 'Moscow')
insert into EMPLOYEE(E_SNILS, E_NAME, E_PHONE_NUMBER, E_ADDRESS) values ('11111111112', 'Anna A.', '8-915-123-12-33', 'Petersburg')
insert into EMPLOYEE(E_SNILS, E_NAME, E_PHONE_NUMBER, E_ADDRESS) values ('11111111113', 'Kate K.', '8-916-123-12-33', 'Petersburg')
insert into EMPLOYEE(E_SNILS, E_NAME, E_PHONE_NUMBER, E_ADDRESS) values ('11111111114', 'Sasha S.', '8-916-123-12-23', 'Moscow')
insert into EMPLOYEE(E_SNILS, E_NAME, E_PHONE_NUMBER, E_ADDRESS) values ('11111111115', 'Pasha P.', '8-916-123-12-23', 'Moscow')

insert into RELATION_DEPARTMENT_EMPLOYEE(R_NAME, R_SNILS) values ('Струнные', '11111111111')
insert into RELATION_DEPARTMENT_EMPLOYEE(R_NAME, R_SNILS) values ('Струнные', '11111111112')
insert into RELATION_DEPARTMENT_EMPLOYEE(R_NAME, R_SNILS) values ('Струнные', '11111111113')
insert into RELATION_DEPARTMENT_EMPLOYEE(R_NAME, R_SNILS) values ('Струнные', '11111111114')
insert into RELATION_DEPARTMENT_EMPLOYEE(R_NAME, R_SNILS) values ('Клавишные', '11111111114')
insert into RELATION_DEPARTMENT_EMPLOYEE(R_NAME, R_SNILS) values ('Этнические', '11111111115')

select * from DEPARTMENT
select * from EMPLOYEE
select * from RELATION_DEPARTMENT_EMPLOYEE

/*GROUP BY*/
SELECT R_SNILS, R_NAME
FROM RELATION_DEPARTMENT_EMPLOYEE AS S
GROUP BY R_SNILS, R_NAME
HAVING R_NAME = 'Струнные'

DELETE FROM DEPARTMENT
WHERE D_NAME = 'Этнические'
DELETE FROM EMPLOYEE
WHERE E_SNILS = '11111111115'

select * from DEPARTMENT
select * from EMPLOYEE
select * from RELATION_DEPARTMENT_EMPLOYEE

GO
CREATE TRIGGER Trigger_insert_relation_department_employee
ON RELATION_DEPARTMENT_EMPLOYEE
INSTEAD OF INSERT
AS
	/*Пытаемся добавить что-то с несуществующим ключом*/
	IF EXISTS(select R_NAME from inserted where inserted.R_NAME not in (select D_NAME from DEPARTMENT))
	BEGIN
	RAISERROR('Нужно добавит ключ в DEPARTMENT', 16, 0);
	END
	IF EXISTS(select R_SNILS from inserted where inserted.R_SNILS not in (select E_SNILS from EMPLOYEE))
	BEGIN
	RAISERROR('Нужно добавит ключ в EMPLOYEE', 16, 0);
	END
	ELSE
	BEGIN
	INSERT INTO RELATION_DEPARTMENT_EMPLOYEE select * from inserted
	END
GO

insert into RELATION_DEPARTMENT_EMPLOYEE(R_NAME, R_SNILS) values ('Струнные', '999')
insert into RELATION_DEPARTMENT_EMPLOYEE(R_NAME, R_SNILS) values ('Аксессуары', '11111111111')
insert into RELATION_DEPARTMENT_EMPLOYEE(R_NAME, R_SNILS) values ('Аксессуары', '999')

select * from DEPARTMENT
select * from EMPLOYEE
select * from RELATION_DEPARTMENT_EMPLOYEE

/*--------------------------------------------------------------------------------------------------------------------Отдел - Товар*/
insert into DEPARTMENT(D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME) values ('Этнические', '08:00:00', '00:00:00', 'Golden cord')

insert into SHIPMENT(S_NAME, S_PRODUCER, S_PRICE) values ('Скрипка YAMAHA V5SA34', 'Россия', 21000)
insert into SHIPMENT(S_NAME, S_PRODUCER, S_PRICE) values ('Гитара Epiphone Dave Navarro', 'Индонезия', 23000)
insert into SHIPMENT(S_NAME, S_PRODUCER, S_PRICE) values ('Гитара Dowina GACE 222', 'Словакия', 23690)
insert into SHIPMENT(S_NAME, S_PRODUCER, S_PRICE) values ('Синтезатор YAMAHA PSR-R200', 'Россия', 6000)
insert into SHIPMENT(S_NAME, S_PRODUCER, S_PRICE) values ('Блок-флейта', 'Китай', 1000)

insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Струнные', 'Скрипка YAMAHA V5SA34')
insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Струнные', 'Гитара Epiphone Dave Navarro')
insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Струнные', 'Гитара Dowina GACE 222')
insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Клавишные', 'Синтезатор YAMAHA PSR-R200')
insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Этнические', 'Блок-флейта')

DELETE FROM DEPARTMENT
WHERE D_NAME = 'Струнные'
DELETE FROM SHIPMENT
WHERE S_NAME = 'Блок-флейта'

select * from DEPARTMENT
select * from SHIPMENT
select * from RELATION_DEPARTMENT_SHIPMENT

insert into DEPARTMENT(D_NAME, D_OPENING_TIME, D_CLOSING_TIME, S_NAME) values ('Струнные', '08:00:00', '00:00:00', 'Golden cord')
insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Струнные', 'Скрипка YAMAHA V5SA34')
insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Струнные', 'Гитара Epiphone Dave Navarro')
insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Струнные', 'Гитара Dowina GACE 222')
insert into SHIPMENT(S_NAME, S_PRODUCER, S_PRICE) values ('Блок-флейта', 'Китай', 1000)
insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Этнические', 'Блок-флейта')

GO
CREATE TRIGGER Trigger_insert_relation_department_shipment
ON RELATION_DEPARTMENT_SHIPMENT
INSTEAD OF INSERT
AS
	/*Пытаемся добавить что-то с несуществующим ключом*/
	IF EXISTS(select R_NAME_DEP from inserted where inserted.R_NAME_DEP not in (select D_NAME from DEPARTMENT))
	BEGIN
	RAISERROR('Нужно добавит ключ в DEPARTMENT', 16, 0);
	END
	IF EXISTS(select R_NAME_SHIP from inserted where inserted.R_NAME_SHIP not in (select S_NAME from SHIPMENT))
	BEGIN
	RAISERROR('Нужно добавит ключ в SHIPMENT', 16, 0);
	END
	ELSE
	BEGIN
	INSERT INTO RELATION_DEPARTMENT_SHIPMENT select * from inserted
	END
GO

insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Струнные', 'Скрипка')
insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Аксессуары', 'Скрипка YAMAHA V5SA34')
insert into RELATION_DEPARTMENT_SHIPMENT(R_NAME_DEP, R_NAME_SHIP) values ('Аксессуары', 'Скрипка')

/*----------------------------------------------------------------------------------------------------------------Товар - Покупатель*/
insert into CUSTOMER(C_NAME, C_PHONE_NUMBER, C_ADDRESS) values ('Elena E.', '8-915-123-12-23', 'Moscow')
insert into CUSTOMER(C_NAME, C_PHONE_NUMBER, C_ADDRESS) values ('Alex A.', '8-915-125-12-23', 'Moscow')
insert into CUSTOMER(C_NAME, C_PHONE_NUMBER, C_ADDRESS) values ('Vladimir V.', '8-916-125-12-33', 'Moscow')

insert into DISCOUNT(DIS_NAME_CUST, DIS_NAME_SHIP, DIS_PRICE) values ('Elena E.', 'Скрипка YAMAHA V5SA34', 1000)
insert into DISCOUNT(DIS_NAME_CUST, DIS_NAME_SHIP, DIS_PRICE) values ('Alex A.', 'Гитара Epiphone Dave Navarro', 2000)
insert into DISCOUNT(DIS_NAME_CUST, DIS_NAME_SHIP, DIS_PRICE) values ('Vladimir V.', 'Гитара Dowina GACE 222', 3000)

DELETE FROM SHIPMENT
WHERE S_NAME = 'Скрипка YAMAHA V5SA34'
DELETE FROM CUSTOMER
WHERE C_NAME = 'Alex A.'

select * from SHIPMENT
select * from CUSTOMER
select * from ACTION_SALE

insert into SHIPMENT(S_NAME, S_PRODUCER, S_PRICE) values ('Скрипка YAMAHA V5SA34', 'Россия', 21000)
insert into CUSTOMER(C_NAME, C_PHONE_NUMBER, C_ADDRESS) values ('Alex A.', '8-915-125-12-23', 'Moscow')
insert into DISCOUNT(DIS_NAME_CUST, DIS_NAME_SHIP, DIS_PRICE) values ('Elena E.', 'Скрипка YAMAHA V5SA34', 1000)
insert into DISCOUNT(DIS_NAME_CUST, DIS_NAME_SHIP, DIS_PRICE) values ('Alex A.', 'Гитара Epiphone Dave Navarro', 2000)

select * from SHIPMENT
select * from CUSTOMER
select * from DISCOUNT

GO
CREATE TRIGGER Trigger_insert_discount
ON DISCOUNT
INSTEAD OF INSERT
AS
	/*Пытаемся добавить что-то с несуществующим ключом*/
	IF EXISTS(select DIS_NAME_CUST from inserted where inserted.DIS_NAME_CUST not in (select C_NAME from CUSTOMER))
	BEGIN
	RAISERROR('Нужно добавит ключ в CUSTOMER', 16, 0);
	END
	IF EXISTS(select DIS_NAME_SHIP from inserted where inserted.DIS_NAME_SHIP not in (select S_NAME from SHIPMENT))
	BEGIN
	RAISERROR('Нужно добавит ключ в SHIPMENT', 16, 0);
	END
	ELSE
	BEGIN
	INSERT INTO DISCOUNT select * from inserted
	END
GO

insert into DISCOUNT(DIS_NAME_CUST, DIS_NAME_SHIP, DIS_PRICE) values ('Alisa A.', 'Скрипка YAMAHA V5SA34', 1000)
insert into DISCOUNT(DIS_NAME_CUST, DIS_NAME_SHIP, DIS_PRICE) values ('Elena E.', 'Электрокрипка', 1000)
insert into DISCOUNT(DIS_NAME_CUST, DIS_NAME_SHIP, DIS_PRICE) values ('Alisa A.', 'Электрокрипка', 1000)

/*---------------------------------------------------------------------------------------------------------------------Скидка - Акция*/

insert into ACTION_SALE(A_NAME) values ('Скидки в День Рождения')
insert into ACTION_SALE(A_NAME) values ('Скидки постоянным клиентам')
insert into ACTION_SALE(A_NAME, A_OPENING_TIME, A_CLOSING_TIME) values ('Новогодние скидки', '2013-12-28', '2014-01-10')

GO
CREATE TRIGGER Trigger_insert_action_sale
ON RELATION_DISCOUNT_ACTION_SALE
INSTEAD OF INSERT
AS
	/*Пытаемся добавить что-то с несуществующим ключом*/
	IF EXISTS(select DIS_C_NAME from inserted where inserted.DIS_C_NAME not in (select C_NAME from CUSTOMER))
	BEGIN
	RAISERROR('Нужно добавит ключ в CUSTOMER', 16, 0);
	END
	IF EXISTS(select DIS_A_NAME from inserted where inserted.DIS_A_NAME not in (select A_NAME from ACTION_SALE))
	BEGIN
	RAISERROR('Нужно добавит ключ в CUSTOMER', 16, 0);
	END
	ELSE
	BEGIN
	INSERT INTO RELATION_DISCOUNT_ACTION_SALE select * from inserted
	END
GO

insert into RELATION_DISCOUNT_ACTION_SALE(DIS_C_NAME, DIS_A_NAME) values ('Alex A.', 'Скидки в День Рождения')
insert into RELATION_DISCOUNT_ACTION_SALE(DIS_C_NAME, DIS_A_NAME) values ('Elena E.', 'Скидки постоянным клиентам')
insert into RELATION_DISCOUNT_ACTION_SALE(DIS_C_NAME, DIS_A_NAME) values ('Vladimir V.', 'Новогодние скидки')
/*Покупатель(CUSTOMER), акция(DISCOUNT), предмет(SHIPMENT)*/
insert into RELATION_DISCOUNT_ACTION_SALE(DIS_C_NAME, DIS_A_NAME) values ('Alex F.', 'Скидки в День Рождения')

DELETE FROM SHIPMENT
WHERE S_NAME = 'Скрипка YAMAHA V5SA34'
DELETE FROM CUSTOMER
WHERE C_NAME = 'Alex A.'

select * from CUSTOMER
select * from SHIPMENT
select * from ACTION_SALE
select * from RELATION_DISCOUNT_ACTION_SALE

insert into CUSTOMER(C_NAME, C_PHONE_NUMBER, C_ADDRESS) values ('Alex A.', '8-915-125-12-23', 'Moscow')
insert into SHIPMENT(S_NAME, S_PRODUCER, S_PRICE) values ('Скрипка YAMAHA V5SA34', 'Россия', 21000)
insert into RELATION_DISCOUNT_ACTION_SALE(DIS_C_NAME, DIS_A_NAME) values ('Alex A.', 'Скидки в День Рождения')

DROP TABLE dbo.[SHOP];
DROP TABLE dbo.[DEPARTMENT];
DROP TABLE dbo.[EMPLOYEE];
	DROP TABLE dbo.[RELATION_DEPARTMENT_EMPLOYEE];
DROP TABLE dbo.[SHIPMENT];
	DROP TABLE dbo.[RELATION_DEPARTMENT_SHIPMENT];
DROP TABLE dbo.[CUSTOMER];
	DROP TABLE dbo.[DISCOUNT];
DROP TABLE dbo.[ACTION_SALE];
DROP TABLE dbo.[RELATION_DISCOUNT_ACTION_SALE];