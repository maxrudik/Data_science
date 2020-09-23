--PART 2

--1 A
select row_number() over (order by count(CustomerID) desc) as rank, 
SalesPerson, count(CustomerID) as clients
from SalesLT.Customer group by SalesPerson
order by clients desc;

--1 B
create view sales_seller as
select c.SalesPerson, s.SalesOrderID
from SalesLT.SalesOrderHeader s 
join SalesLT.Customer c 
on s.CustomerID = c.CustomerID;

select row_number() over(order by count(SalesOrderID) desc) as rank,
SalesPerson, count(SalesOrderID) as sales_amount
from dbo.sales_seller group by SalesPerson
order by sales_amount desc;

--1 C

--1st part with no nulls used to create view
create view seller_income as
select SalesPerson, sum(LineTotal) as income
from dbo.total_no_nulls
group by SalesPerson;

select row_number() over(order by income desc) as rank,
SalesPerson, income 
from seller_income order by income desc;

--2 A
create view con_state_cus as
select a.CountryRegion, a.StateProvince,
count(c.CustomerID) as customer_amount
from SalesLT.Address a
join SalesLT.CustomerAddress c 
on a.AddressID = c.AddressID
group by a.CountryRegion, a.StateProvince;

select CountryRegion, StateProvince,
percent_rank() over (partition by CountryRegion order by customer_amount) as percent_rank,
customer_amount
from dbo.con_state_cus
order by CountryRegion asc, customer_amount desc, StateProvince asc;

--2 B
create view cus_add as 
select c.CustomerID, a.AddressID
from SalesLT.Customer c 
left join SalesLT.CustomerAddress a 
on a.CustomerID = c.CustomerID;

create view add_cus_null as
select a.CountryRegion, a.StateProvince,
count(c.CustomerID) as customer_amount
from dbo.cus_add c 
left join SalesLT.Address a
on a.AddressID = c.AddressID
group by a.CountryRegion, a.StateProvince;

select CountryRegion, StateProvince,
dense_rank() over (partition by CountryRegion order by customer_amount desc) as dense_rank,
customer_amount
from dbo.add_cus_null
order by CountryRegion asc, customer_amount desc, StateProvince asc;

--2 C
create view city_country_cus_same as
select a.City, a.StateProvince, a.CountryRegion,
count(c.CustomerID) over (partition by a.City) as clients_amount
from SalesLT.Address a 
join SalesLT.CustomerAddress c 
on a.AddressID = c.AddressID;

create view city_country_cus_unique as
select City, StateProvince, CountryRegion, 
max(clients_amount) as clients_amount
from city_country_cus_same
group by City, StateProvince, CountryRegion;

create view rank as
select CountryRegion, StateProvince,
City, row_number() over(partition by CountryRegion order by clients_amount desc) as rank_in_country,
clients_amount
from city_country_cus_unique;

select CountryRegion, StateProvince, City,
rank_in_country, clients_amount,
(lag(clients_amount) over (partition by CountryRegion order by rank_in_country) - clients_amount) as delta
from dbo.rank;