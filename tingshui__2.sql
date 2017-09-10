/* 1. School rank: show the school rank of each subdivision along with 
the average base price of floor plans the subdivision provides.*/
CREATE VIEW School_Rank (Sub_school_rank, Avg_floor_price) AS
SELECT S.School_rank, F.Avg_price
FROM SUBDIVISION S
RIGHT JOIN
(SELECT F.Sub_name, AVG(F.price) AS Avg_price
FROM FLOOR_PLAN F
GROUP BY F.Sub_name)
ON S.name = F.Sub_name

/*Q1 M2*/
CREATE VIEW School_Rank (Sub_name, Sub_school_rank, Avg_floor_price) AS
SELECT S.Name, S.School_rank, ROUND (AVG(F.price))
FROM SUBDIVISION S, FLOOR_PLAN F
WHERE S.name = F.Sub_name
GROUP BY S.School_rank, S.Name

/*2. Promising customers: show the name, age and email address of potential 
customers with credit score over 740. ??AGE??*/
CREATE VIEW Promising_Customer AS
SELECT First_name, Last_name, Email
FROM CUSTOMER C
WHERE C.Customer_type = 'potential' AND C.Credit_score >= 740

/*3. Inventory homes: show the information of unsold inventory homes that have 
been completed or will be completed by the end of 2015 for each subdivision 
along with the manager name of the subdivision.*/
CREATE VIEW Inventory_homes AS
SELECT I.*, E. First_name AS Manager_first_name, E.Last_name AS Manager_last_name
FROM INVENTORY I
RIGHT JOIN MANAGER M
ON I.Sub_name = M.Sub_name
RIGHT JOIN EMPLOYEE E
ON M.Employee_ID = E.Employee_ID
WHERE to_date(I.Move_in_date, 'MM/DD/YYYY') <= to_date('12/31/2015', 'MM/DD/YYYY') and I.availability = 'T'

/*4. Large floor plans: show the information of floor plans over 4000 square 
feet for each subdivision.*/
CREATE VIEW Large_floor_plans AS
SELECT F.*
FROM FLOOR_PLAN F
WHERE F.Square_footage >= 4000

/* 5. Sales record: for each subdivision, show the name of each sales agent and 
the number of contracts she prepared in year 2014.*/
CREATE VIEW Sales_record (Sale_first_name, Sale_last_name, Sale_Sub_name, Contract_num) AS
SELECT E.FIRST_NAME, E.Last_name, E.SUB_NAME, COUNT(C.CONTRACT_ID)
FROM EMPLOYEE E, CONTRACT C
WHERE C.DATE_SIGNED LIKE '%2014%' and C.EMPLOYEE_ID = E.EMPLOYEE_ID
GROUP BY E.FIRST_NAME, E.Last_name, E.Sub_name, C.EMPLOYEE_ID


/*6. Deal discount: for each subdivision, show the information of the contracts 
signed for inventory homes with a discount in year 2015. Here contract with 
discount means that the sales price showed in the contract is lower than the 
list price of the inventory home.*/
CREATE VIEW Deal_discount AS
SELECT C.*, I.Price
FROM CONTRACT C, SIGN S, INVENTORY I
WHERE C.SALE_PRICE < I.PRICE AND C.CONTRACT_ID = S.CONTRACT_ID AND S.SUB_NAME = I.SUB_NAME 
AND C.DATE_SIGNED LIKE '%2015%'

/*1. Retrieve the school rank of each subdivision in decreasing order of the 
average base price of floor plans the subdivision provides.*/
SELECT Sub_name, Sub_School_rank
FROM SCHOOL_RANK
ORDER BY AVG_FLOOR_PRICE DESC

/*2. For each subdivision, retrieve the number of unsold inventory homes that 
have been completed or will be ready by the end of year 2015.*/
SELECT SUB_NAME, COUNT(Inventory_Id)
From INVENTORY_HOMES
GROUP BY SUB_NAME

/*3. For each subdivision, retrieve information of the sales agents who prepared
all the contracts with floor plans over 4000 square feet signed in year 2015.*/
/* you don't have EXCEPT IN ORACLE!!!*/
/*The way to do divide: SELECT name FROM sailors
WHERE Sid NOT IN (
SELECT s.Sid
FROM sailors s, boats b
WHERE (s.Sid, b.Bid) NOT IN (
SELECT Sid, Bid FROM reserves))*/
/* high land park subdivision: no employee complete all contact, but gainesville does */
/* We do not need to use DIVIDE! because all contract are different,
and every contract is prepared by only one employee by our definition.
We just need to check if all suitable contracts in one subdivision are finished by one employee,
which means the number of employee for one subdivision can only equal to one. */
CREATE VIEW FLOOR4000_2015 AS
SELECT C2.CONTRACT_ID, C2.EMPLOYEE_ID, L.Sub_name
FROM CONTRACT C2, SIGN S, LARGE_FLOOR_PLANS L
WHERE L.Sub_name = S.Sub_name AND S.CONTRACT_ID = C2.CONTRACT_ID and C2.Date_signed LIKE '%2015%'

SELECT distinct E.*
FROM EMPLOYEE E, FLOOR4000_2015 F1
WHERE E.EMPLOYEE_ID = F1.EMPLOYEE_ID AND F1.Sub_name IN
(SELECT F.Sub_name
From FLOOR4000_2015 F
GROUP BY F.Sub_name
HAVING COUNT(distinct F.Employee_ID) = 1)

/*4. For each subdivision, retrieve the information of the sales agent who 
prepared the highest number of contracts in year 2014.*/
SELECT S.SALE_FIRST_NAME, S.SALE_LAST_NAME, MAX(S.CONTRACT_NUM) AS MAX_CONTRACT_NUM
FROM SALES_RECORD S
GROUP BY S.SALE_SUB_NAME, S.SALE_FIRST_NAME, S.SALE_LAST_NAME

/*5. Retrieve the information of the inventory home that has not been sold for the 
longest time since its completion, along with the name of the manager who is in 
charge of that subdivision.*/
SELECT I.* 
FROM INVENTORY_HOMES I
WHERE NOT EXISTS
(SELECT I1.Move_in_date
FROM INVENTORY_HOMES I1
WHERE to_date(I.Move_in_date, 'MM/DD/YYYY') > to_date(I1.Move_in_date, 'MM/DD/YYYY'))

/*6. Retrieve the information of potential customers who have been visiting 
subdivisions of the company for more than one month and the price range of the 
inventory homes they have toured lies between $300,000 to $400,000.*/
SELECT C.*
FROM CUSTOMER C 
WHERE C.Customer_type = 'potential' and C.email IN
((SELECT V.Customer_email
FROM VISIT V
WHERE to_date(V.Visit_date, 'MM/DD/YYYY') < SYSDATE - 30)
INTERSECT
(SELECT T.Customer_email
FROM TOUR T
WHERE T.Sub_name IN
(SELECT I.Sub_name
FROM Inventory I
WHERE I.Price >= 300000 and I.Price <= 400000)))

/*7. For each subdivision, retrieve the information of each customer whose home 
loan has not been approved over one month after he/she signed his/her contract.*/
/*modified: time period between credit approve and sign > 1 month*/
SELECT C.*
FROM CUSTOMER C, LOAN_APPLICANT L, CONTRACT CON, SIGN S
WHERE S.CONTRACT_ID = CON.CONTRACT_ID AND S.CUSTOMER_EMAIL = C.EMAIL
AND C.LOAN_ID = L.LOAN_ID AND to_date(CON.date_signed, 'MM/DD/YYYY') - to_date(L.A_D_DATE, 'MM/DD/YYYY') > 30

/*8. Retrieve the name, age and email address of potential customers with credit
score over 740 who visited a subdivision in August this year but have not 
visited any subdivision since September 1st.*/
(SELECT P.First_name, P.Last_name, P.Email
FROM VISIT V, Promising_customer P
WHERE V.Visit_date LIKE '08%2015' and V.Customer_email = P.email)
MINUS
(SELECT P1.First_name, P1.Last_name, P1.Email
FROM VISIT V1, Promising_customer P1
WHERE V1.Visit_date LIKE '09%2015' and V1.Customer_email = P1.email)

/*9. Retrieve the average discount received by the customers who have signed a 
contract to purchase an inventory home.*/
SELECT AVG(D.price - D.Sale_price)
FROM Deal_discount D 

/*10. Retrieve information of the potential customers whose house preferences 
can be matched by one or more inventory homes that will be ready to move in 
by the end of year 2015.*/
/* The target sqare of customers is the maximum square footage. */
/* The target school rank of customer is the minimum square rank. */

SELECT C.*
FROM CUSTOMER C, INVENTORY_HOMES I, FLOOR_PLAN F, SUBDIVISION S
WHERE C.NUM_OF_BATH = F. NUM_OF_BATH AND C.NUM_OF_BEDROOM = F.NUM_OF_BEDROOM AND C.SCHOOL_RANK >= S.SCHOOL_RANK
AND C.SQUARE_FOOTAGE <= F.SQUARE_FOOTAGE AND C.CUSTOMER_TYPE = 'potential' AND S.NAME = F.SUB_NAME
AND S.NAME = I.SUB_NAME AND I.SUB_NAME = F.SUB_NAME AND I.FLOOR_NUM = F.FLOOR_NUM
