CREATE DATABASE Live_ProjectDb;

USE Live_ProjectDb;

-- Plans table
CREATE TABLE Plans (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Plan_Name NVARCHAR(255) NOT NULL,
    Plan_Validity INT NOT NULL, -- In days
    Plan_Amount DECIMAL(10, 2) NOT NULL,
    Max_Rounds INT NOT NULL
);

-- Customer Table
CREATE TABLE Customers (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Email NVARCHAR(255) NOT NULL UNIQUE,
    First_Name NVARCHAR(255) NOT NULL,
    Last_Name NVARCHAR(255) NOT NULL,
    City NVARCHAR(255),
    Country NVARCHAR(255),
    Address NVARCHAR(255),
    Current_Plan INT,
    TransactionId INT,
    PlanId INT,
    Organization NVARCHAR(255),
	Created_Date datetime
);


-- Transactions table
CREATE TABLE Transactions (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Transaction_Id INT NOT NULL,
    Plan_Start DATETIME NOT NULL,
    Plan_End DATETIME NOT NULL,
    Current_Round INT NOT NULL,
    IsLatest BIT NOT NULL,
    CustomerId INT NOT NULL,
    PlanId INT NOT NULL
);

-- Users table
CREATE TABLE Users (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(255) NOT NULL,
    Password NVARCHAR(255) NOT NULL,
    IsCustomer BIT NOT NULL,
    IsAdmin BIT NOT NULL,
    IsEmployee BIT NOT NULL,
    CustomerId INT,
    IsActive BIT NOT NULL,
);

-- Enquires table
CREATE TABLE Enquires (
    Id INT PRIMARY KEY IDENTITY(1,1),
	Enquiry_Date datetime not null,
	isResolved bit not null,
    Message varchar(Max),
    CustomerId INT,
    PlanId INT, 
);

-- Procedure for signin 
CREATE PROCEDURE dbo.CheckUser
    @Username NVARCHAR(255),
    @Password NVARCHAR(255)
AS
BEGIN
    DECLARE @UserId INT;
    SELECT *
    FROM Users
    WHERE Username = @Username AND Password = @Password;
END;

exec dbo.CheckUser 'kunalshokeen99','admin12'

-- Procedure create new customer
CREATE OR ALTER PROCEDURE sp_Create_Customer
 @Email NVARCHAR(255),
 @First_Name NVARCHAR(255),
 @Last_Name NVARCHAR(255),
 @City NVARCHAR(255),
 @Country NVARCHAR(255),
 @Address NVARCHAR(255),
 @Current_Plan INT,
 @TransactionId INT,
 @PlanId INT,
 @Organization NVARCHAR(255)
AS
BEGIN
	Declare @Validity int;
	Declare @Password NVARCHAR(MAX);
	DECLARE @RandomNumber INT;
	Declare @Cus_Id int;
	Declare @Plan_Start datetime;
	Declare @Plan_End datetime;
	Declare @Created_Date datetime;
    SET @RandomNumber = CAST(RAND() * 9000 + 1000 AS INT);
	SET @Created_Date = GETDATE();

    INSERT INTO Customers (Email, First_Name, Last_Name, City, Country, [Address], Current_Plan, TransactionId, PlanId, Organization,Created_Date)
    VALUES (@Email, @First_Name, @Last_Name, @City, @Country, @Address, @Current_Plan,@TransactionId, @PlanId, @Organization,@Created_Date);

	SET @Validity = (select Plan_Validity from Plans where Id = @PlanId);
	SET @Password = @First_Name + @Last_Name + CAST(@RandomNumber AS NVARCHAR(4));
	SET @Password = replace(@Password,' ','');
	SET @Cus_Id =   SCOPE_IDENTITY();
	SET @Plan_Start = GETDATE();
	SET @Plan_End = DATEADD(DAY,@Validity,@Plan_Start);

    Exec  Sp_Create_Transaction  
	         @TransactionId,
             @Plan_Start,
             @Plan_End, 
             1, 
             1, 
             @Cus_Id, 
             @PlanId
			 
	Exec Sp_Create_User  @Email,@Password,1,0,0,@Cus_Id
END

--Sp for creating a new transaction
CREATE OR ALTER PROCEDURE Sp_Create_Transaction
    @Transaction_Id INT,
    @Plan_Start DATETIME,
    @Plan_End DATETIME,
    @Current_Round INT,
    @IsLatest BIT,
    @CustomerId INT,
    @PlanId INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Transactions WHERE CustomerId = @CustomerId)
    BEGIN

        UPDATE Transactions
        SET IsLatest = 0
        WHERE CustomerId = @CustomerId;


        INSERT INTO Transactions (Transaction_Id, Plan_Start, Plan_End, Current_Round, IsLatest, CustomerId, PlanId)
        VALUES (@Transaction_Id, @Plan_Start, @Plan_End, @Current_Round, @IsLatest, @CustomerId, @PlanId);

        UPDATE Customers
        SET Current_Plan = @PlanId, TransactionId = @Transaction_Id
        WHERE Id = @CustomerId;
    END
    ELSE
    BEGIN
        INSERT INTO Transactions (Transaction_Id, Plan_Start, Plan_End, Current_Round, IsLatest, CustomerId, PlanId)
        VALUES (@Transaction_Id, @Plan_Start, @Plan_End, @Current_Round, @IsLatest, @CustomerId, @PlanId);
    END
END

-- Procedure create User
create or alter  Procedure Sp_Create_User
@Email NVARCHAR(255),
@Password NVARCHAR(255),
@IsCustomer bit,
@IsAdmin bit,
@IsEmployee bit,
@CustomerId  int
as
begin
Declare @UserName varchar(50)
Declare @IsActive bit 
set @IsActive=1
set @UserName = SUBSTRING(@Email, 1, CHARINDEX('@', @Email) - 1)
   Insert into Users values (@UserName,@Password,@IsCustomer,@IsAdmin,@IsEmployee,@CustomerId,@IsActive)
   Exec sp_Welcome_Mail @Email, @UserName, @Password
end


----Procedure GetAllCustomerData
create or alter proc sp_GetAllCustomerData
as begin
	SELECT C.Id,C.Email, C.First_Name, C.Last_Name, C.City, C.Country,C.Address, C.Current_Plan, C.Organization, P.Plan_Name
                FROM Customers  C  
                LEFT JOIN Plans P ON C.PlanId = P.Id;
end 


-- Procedure for sending Welcome Email
create or alter procedure sp_Welcome_Mail
@User_Email Nvarchar(255),
@Username Nvarchar(50),
@Password Nvarchar(50)
as
begin
DECLARE @Subject NVARCHAR(255)
DECLARE @Message NVARCHAR(MAX)

set @Subject = 'Welcome to Invia Connect - Your B2B Telecom Solution' 
SET @Message = 
  '<html>
  <head>
    <style>
      body {
        font-size: 16px;
        font-family: Arial, sans-serif;
        line-height: 1.6;
        margin: 0;
        padding: 0;
      }
      img {
        display: block;
        width: 100%;
        height: 250px;
		margin: 20px 0;
		border-radius: 10px;
      }
      table {
        border: 1px solid #000;
        border-collapse: collapse;
        margin: 20px 0;
      }
      table td {
        border: 1px solid #000;
        padding: 5px;
      }
      p {
        margin: 20px 0;
      }
      h3 {
        color: #0047AB;
      }
      strong {
        font-weight: bold;
      }
    </style>
  </head>
  <body>
    <img src="https://i.ibb.co/Q8fLQWk/INVIA.png" alt="INVIA" border="0">
    <p>We are thrilled to have you on board with us!</p>
    
    <p>To get started, please use the following credentials:</p>
    
    <table>
      <tr>
        <td style="font-weight: bold;">Username:</td>
        <td>' + @Username + '</td>
      </tr>
      <tr>
        <td style="font-weight: bold;">Password:</td>
        <td>' + @Password + '</td>
      </tr>
    </table>
    
    <p>Thank you for choosing us. We look forward to serving you and to a productive and prosperous partnership. Welcome to the Invia family!</p>
    
    <p>Warm regards,</p>
    <h3>INVIA</h3>
    <strong>"Connecting People, Bridging Worlds."</strong>
  </body>
  </html>'


	 EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'SQLAlerts', 
        @recipients = @User_Email,
        @subject = @Subject,
        @body = @Message,
        @body_format = 'HTML'; 
end


--Procedure for Sending Enquiry
create or alter procedure sp_AddEnquiry
@Id int,
@CustomerId int
as
begin
 DECLARE @PlanName NVARCHAR(255);
  SELECT @PlanName = Plan_Name FROM Plans WHERE Id = @Id;
	
    IF EXISTS (SELECT 1 FROM Customers WHERE Id = @CustomerId)
    BEGIN
        INSERT INTO Enquires (Enquiry_Date, isResolved, Message, CustomerId, PlanId)
        VALUES (GETDATE(), 0, 'Hi, I need to know more about the ' + @PlanName, @CustomerId, @Id);
    End
end


-- sp_CustomerPlanDetails stored procedure
CREATE OR ALTER PROCEDURE sp_CustomerPlanDetails
    @customerId INT
AS
BEGIN
    select c.Id, c.First_Name,c.Last_Name, c.Email,c.City,c.[Address],c.Organization,p.Plan_Name,t.Current_Round
	,t.Plan_Start,t.Plan_End,p.Id as planId from Customers c
	join Transactions t on t.CustomerId = c.Id
    join Plans p on p.Id = c.PlanId
	where c.Id = @customerId
    ORDER BY T.IsLatest DESC, T.Plan_Start DESC;
END

-- Stored procedure customeTransactions Details
create or alter procedure sp_CustomerTransactions
@customerId INT
as
begin
select c.Id, t.Transaction_Id, t.Plan_Start, t.Plan_End, p.Plan_Name,p.Id as planId from Transactions t 
join Customers c on t.CustomerId = c.Id
join Plans p on p.Id = t.PlanId 
where c.Id = @customerId
end

--Stored procedure for Deleting User
CREATE OR ALTER PROCEDURE Sp_Delete_Customer
 @Customer_Id INT
AS
BEGIN
    DECLARE @Subject NVARCHAR(255) = 'Account Deletion Notification';
    DECLARE @Body NVARCHAR(MAX) = 'Dear Customer, we regret to inform you that your account has been deleted. Thank you for being our valuable customer.';
    DECLARE @MailProfile NVARCHAR(128) = 'SQLAlerts';
	Declare @CustomerMail Nvarchar(255);

    SELECT @CustomerMail = c.Email
    FROM Customers c
    WHERE c.Id = @Customer_Id;

    DELETE FROM Users WHERE CustomerId = @Customer_Id;
    DELETE FROM Transactions WHERE CustomerId = @Customer_Id;
    DELETE FROM Customers WHERE Id = @Customer_Id;
    DELETE FROM Enquires WHERE CustomerId = @Customer_Id;

	EXEC msdb.dbo.sp_send_dbmail
        @profile_name = @MailProfile,
        @recipients = @CustomerMail, 
        @subject = @Subject,
        @body = @Body;
END


-- stored procedure for next round start
Create or Alter procedure Sp_RoundUpdate
@Customer_Id INT
AS
BEGIN
	Declare @Round int, @Max_Round int
	SELECT @Round =  t.Current_Round
    FROM Transactions t
    JOIN Customers c ON t.Transaction_Id = c.TransactionId
    WHERE t.CustomerId = @Customer_Id;

	Select @Max_Round = p.Max_Rounds
    FROM Plans p
    JOIN Customers c ON p.Id = c.Current_Plan
    WHERE c.Id = @Customer_Id;

	IF (@Round < @Max_Round)
	BEGIN
	Set @Round += 1
    UPDATE Transactions 
    SET Current_Round = @Round
    WHERE CustomerId = @Customer_Id; 
	END
END


-- STORED PROCEDUR EXECUTION
exec sp_GetAllCustomerData
Exec sp_Create_Customer 'kunalshokeen051@gmail.com','kunal','shokeen','Gurgoan',
'India','jharsa gurgaon',3,1234556,3,'Tower Research'
Exec sp_AddEnquiry 2, 1
Exec sp_CustomerTransactions 3012
Exec sp_CustomerPlanDetails 3012
Exec Sp_Create_Transaction 324324,'2023-10-28 18:17:08.350','2024-04-28 18:17:08.350',1,1,3007,2
Exec Sp_Create_User 'kunalshokeen99@gmail.com','admin123',0,1,1,0
Exec Sp_Delete_Customer 3024
Exec Sp_RoundUpdate 3025


--Calling Tables
select * from Plans
select * from Customers 
select * from Transactions 
select * from Users 
select * from Enquires

