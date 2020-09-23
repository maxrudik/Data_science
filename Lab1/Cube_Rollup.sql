--Part 1

--A
--prod_cus_sales
create view prod_cus_sales as 
select p.ProductID, c.CustomerID, c.SalesPerson
from SalesLT.Product p
cross join SalesLT.Customer c;

--total_nulls
create view total_nulls as
select a.CustomerID, a.ProductID,
a.SalesPerson, e.LineTotal
from dbo.prod_cus_sales a
left join dbo.existing_sales e
on a.CustomerID = e.CustomerID and a.ProductID = e.ProductID;

--result (nulls)
select ProductID, CustomerID, SalesPerson, sum(LineTotal) as income
from dbo.total_nulls
group by cube(ProductID, CustomerID, SalesPerson);

--total_no_nulls
create view total_no_nulls as
select a.CustomerID, a.ProductID,
a.SalesPerson, e.LineTotal
from dbo.prod_cus_sales a
join dbo.existing_sales e
on a.CustomerID = e.CustomerID and a.ProductID = e.ProductID;

--result (no_nulls)
select ProductID, CustomerID, SalesPerson, sum(LineTotal) as income
from dbo.total_no_nulls
group by cube(ProductID, CustomerID, SalesPerson);

--B
--prod_sales_det
create view prod_sales_det as
select d.ProductID, d.LineTotal, h.BillToAddressID,
h.ShipToAddressID, h.CustomerID
from SalesLT.SalesOrderDetail d, SalesLT.SalesOrderHeader h
where d.SalesOrderID = h.SalesOrderID;

--total_address
create view total_adresses as
select s.ProductID, s.CustomerID,
s.BillToAddressID, s.ShipToAddressID,
a.AddressID, s.LineTotal
from dbo.prod_sales_det s, SalesLT.CustomerAddress a
where s.CustomerID = a.CustomerID;

--result
select ProductID, CustomerID,
BillToAddressID, ShipToAddressID,
AddressID, sum(LineTotal) as income
from dbo.total_adresses
group by cube(ProductID, CustomerID,
BillToAddressID, ShipToAddressID,
AddressID);

--C
--det_head
create view det_head as 
select d.LineTotal, (d.UnitPrice * d.UnitPriceDiscount * d.OrderQty) as discount,
h.CustomerID
from SalesLT.SalesOrderDetail d, SalesLT.SalesOrderHeader h 
where h.SalesOrderID = d.SalesOrderID;

--add_cus
create view add_cus as 
select a.City, a.StateProvince,
a.CountryRegion, c.CustomerID
from SalesLT.CustomerAddress c, SalesLT.Address a
where c.AddressID = a.AddressID;

--total_region
create view total_region as 
select d.LineTotal, d.discount,
a.City, a.StateProvince, a.CountryRegion
from dbo.add_cus a, dbo.det_head d 
where a.CustomerID = d.CustomerID;

--result
select CountryRegion, StateProvince, City,
sum(LineTotal) as income, sum(discount) as discount
from dbo.total_region
group by rollup(CountryRegion, StateProvince, City);

--D
--prod_cat
create view prod_cat as 
select p.ProductID, p.Name, c.ProductCategoryID,
c.ParentProductCategoryID
from SalesLT.Product p, SalesLT.ProductCategory c 
where p.ProductCategoryID = c.ProductCategoryID;

--total_cat
create view total_cat as
select p.ParentProductCategoryID, p.ProductCategoryID, p.ProductID,
s.UnitPrice * s.UnitPriceDiscount * s.OrderQty as discount,
s.LineTotal as income
from dbo.prod_cat p, SalesLT.SalesOrderDetail s 
where p.ProductID = s.ProductID;

--result
select ParentProductCategoryID, ProductCategoryID,
ProductID, sum(discount) as discount, sum(income) as discount
from total_cat
group by rollup(ParentProductCategoryID, ProductCategoryID, ProductID);

--E
--total
create view total as
select  
    sh.CustomerID, c.SalesPerson,
    sd.ProductID, sd.OrderQty,
    a.CountryRegion, a.StateProvince, a.City
from 
    SalesLT.SalesOrderDetail sd, SalesLT.SalesOrderHeader sh,
    SalesLT.CustomerAddress ca, SalesLT.Address a, SalesLT.Customer c
where sd.SalesOrderID = sh.SalesOrderID and ca.CustomerID = sh.CustomerID
and a.AddressID = ca.AddressID and c.CustomerID = ca.CustomerID;

--result
select ProductID, CustomerID,
SalesPerson, CountryRegion,
StateProvince, City,
sum(OrderQty) as total_count
from total
group by rollup(ProductID, CustomerID, SalesPerson, CountryRegion, StateProvince, City);