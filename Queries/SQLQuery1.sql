CREATE DATABASE Live_ProjectDb;

USE Live_ProjectDb;

-- Plans table
CREATE TABLE Plans (
  Id INT PRIMARY KEY
 ,Plan_Name NVARCHAR(255) NOT NULL
 ,Plan_Validity INT NOT NULL
 ,Plan_Amount DECIMAL(10, 2) NOT NULL
 ,Max_Rounds INT NOT NULL
);



-- Customer Table
CREATE TABLE Customers (
  Id INT PRIMARY KEY IDENTITY (1, 1)
 ,Email NVARCHAR(255) NOT NULL UNIQUE
 ,First_Name NVARCHAR(255) NOT NULL
 ,Last_Name NVARCHAR(255) NOT NULL
 ,City NVARCHAR(255)
 ,Country NVARCHAR(255)
 ,Address NVARCHAR(255)
 ,Current_Plan INT
 ,TransactionId INT
 ,PlanId INT
 ,Organization NVARCHAR(255)
 ,Created_Date DATETIME
);


-- Transactions table
CREATE TABLE Transactions (
  Id INT PRIMARY KEY IDENTITY (1, 1)
 ,Transaction_Id INT NOT NULL
 ,Plan_Start DATETIME NOT NULL
 ,Plan_End DATETIME NOT NULL
 ,Current_Round INT NOT NULL
 ,IsLatest BIT NOT NULL
 ,CustomerId INT NOT NULL
 ,PlanId INT NOT NULL
);

-- Users table
CREATE TABLE Users (
  Id INT PRIMARY KEY IDENTITY (1, 1)
 ,Username NVARCHAR(255) NOT NULL
 ,Password NVARCHAR(255) NOT NULL
 ,IsCustomer BIT NOT NULL
 ,IsAdmin BIT NOT NULL
 ,IsEmployee BIT NOT NULL
 ,CustomerId INT
 ,IsActive BIT NOT NULL
 ,
);

-- Enquires table
CREATE TABLE Enquires (
  Id INT PRIMARY KEY IDENTITY (1, 1)
 ,Enquiry_Date DATETIME NOT NULL
 ,isResolved BIT NOT NULL
 ,Message VARCHAR(MAX)
 ,CustomerId INT
 ,PlanId INT
 ,
);

--Domain table
CREATE TABLE [dbo].[Domains](
    Id uniqueIdentifier not null,
	[Name] [nvarchar](500) NOT NULL,
	[Title] [varchar](1000) NULL,
	[RegDate] [date] NULL,
	[ExpDate] [date] NULL,
	[Registrar] [varchar](250) NULL,
	[Size] [varchar](50) NULL,
	[WebServer] [varchar](250) NULL,
	[Country] [nvarchar](255) NULL,
	[OpenPort] [varchar](max) NULL,
	[CriticalPort] [varchar](max) NULL,
	[IpAddress] [varchar](50) NULL,
	[Customer_Id] [int] NOT NULL,
	[Round] [int] NOT NULL
	)

--Sub-Domain table
CREATE TABLE [dbo].[Subdomains](
    [Name] [nvarchar](500) NOT NULL,
    [DomainId] [uniqueidentifier] NULL,
    [IpAddress] [varchar](50) NULL
)

--RansomwareSusceptibilityTests table
CREATE TABLE [dbo].[RansomwareSusceptibilityTests](
	[AffectedApplication] [varchar](500) NOT NULL,
	[RansomwareType] [varchar](150) NULL,
	[DomainId] [uniqueidentifier] NOT NULL
	)

--Vulnerabilities table
CREATE TABLE [dbo].[Vulnerabilities](
	[Id] [UNIQUEIDENTIFIER] NOT NULL,
	[Name] [nvarchar](500) NOT NULL,
	[Description] [varchar](max) NULL,
	[Path] [varchar](500) NULL,
	[SeverityRank] [int] NULL,
	[Remidiation] [varchar](max) NULL,
	[DomainId] [uniqueidentifier] NULL,
	[IpAddress] [varchar](50) NULL
 )

 -- Procedure for signin 
CREATE PROCEDURE dbo.CheckUser @Username NVARCHAR(255), 
@Password NVARCHAR(255) AS BEGIN DECLARE @UserId INT;
SELECT 
  * 
FROM 
  Users 
WHERE 
  Username = @Username 
  AND Password = @Password;
END;

  -- Procedure create new customer
  CREATE OR ALTER PROCEDURE sp_Create_Customer @Email NVARCHAR(255),
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
    DECLARE @Validity INT;
    DECLARE @Password NVARCHAR(MAX);
    DECLARE @RandomNumber INT;
    DECLARE @Cus_Id INT;
    DECLARE @Plan_Start DATETIME;
    DECLARE @Plan_End DATETIME;
    DECLARE @Created_Date DATETIME;
    SET @RandomNumber = CAST(RAND() * 9000 + 1000 AS INT);
    SET @Created_Date = GETDATE();

    INSERT INTO Customers (Email, First_Name, Last_Name, City, Country, [Address], Current_Plan, TransactionId, PlanId, Organization, Created_Date)
      VALUES (@Email, @First_Name, @Last_Name, @City, @Country, @Address, @Current_Plan, @TransactionId, @PlanId, @Organization, @Created_Date);

    SET @Validity = (SELECT
        Plan_Validity
      FROM Plans
      WHERE Id = @PlanId);
    SET @Password = @First_Name + @Last_Name + CAST(@RandomNumber AS NVARCHAR(4));
    SET @Password = REPLACE(@Password, ' ', '');
    SET @Cus_Id = SCOPE_IDENTITY();
    SET @Plan_Start = GETDATE();
    SET @Plan_End = DATEADD(DAY, @Validity, @Plan_Start);

    EXEC Sp_Create_Transaction @TransactionId
                              ,@Plan_Start
                              ,@Plan_End
                              ,1
                              ,1
                              ,@Cus_Id
                              ,@PlanId

    EXEC Sp_Create_User @Email
                       ,@Password
                       ,1
                       ,0
                       ,0
                       ,@Cus_Id
  END

    --Sp for creating a new transaction
    CREATE OR ALTER PROCEDURE Sp_Create_Transaction @Transaction_Id INT,
    @Plan_Start DATETIME,
    @Plan_End DATETIME,
    @Current_Round INT,
    @IsLatest BIT,
    @CustomerId INT,
    @PlanId INT
    AS
    BEGIN
      IF EXISTS (SELECT
            1
          FROM Transactions
          WHERE CustomerId = @CustomerId)
      BEGIN

        UPDATE Transactions
        SET IsLatest = 0
        WHERE CustomerId = @CustomerId;

        INSERT INTO Transactions (Transaction_Id, Plan_Start, Plan_End, Current_Round, IsLatest, CustomerId, PlanId)
          VALUES (@Transaction_Id, @Plan_Start, @Plan_End, @Current_Round, @IsLatest, @CustomerId, @PlanId);

        UPDATE Customers
        SET Current_Plan = @PlanId
           ,TransactionId = @Transaction_Id
        WHERE Id = @CustomerId;
      END
      ELSE
      BEGIN
        INSERT INTO Transactions (Transaction_Id, Plan_Start, Plan_End, Current_Round, IsLatest, CustomerId, PlanId)
          VALUES (@Transaction_Id, @Plan_Start, @Plan_End, @Current_Round, @IsLatest, @CustomerId, @PlanId);
      END
    END

      -- Procedure create User
      CREATE OR ALTER PROCEDURE Sp_Create_User @Email NVARCHAR(255),
      @Password NVARCHAR(255),
      @IsCustomer BIT,
      @IsAdmin BIT,
      @IsEmployee BIT,
      @CustomerId INT
      AS
      BEGIN
        DECLARE @UserName VARCHAR(50)
        DECLARE @IsActive BIT
        SET @IsActive = 1
        SET @UserName = SUBSTRING(@Email, 1, CHARINDEX('@', @Email) - 1)
        INSERT INTO Users
          VALUES (@UserName, @Password, @IsCustomer, @IsAdmin, @IsEmployee, @CustomerId, @IsActive)
        EXEC sp_Welcome_Mail @Email
                            ,@UserName
                            ,@Password
      END


        ----Procedure GetAllCustomerData
        CREATE OR ALTER PROC sp_GetAllCustomerData
        AS
        BEGIN
          SELECT
            C.Id
           ,C.Email
           ,C.First_Name
           ,C.Last_Name
           ,C.City
           ,C.Country
           ,C.Address
           ,C.Current_Plan
           ,C.Organization
           ,P.Plan_Name
          FROM Customers C
          LEFT JOIN Plans P
            ON C.PlanId = P.Id;
        END


          -- Procedure for sending Welcome Email
          CREATE OR ALTER PROCEDURE sp_Welcome_Mail @User_Email NVARCHAR(255),
          @Username NVARCHAR(50),
          @Password NVARCHAR(50)
          AS
          BEGIN
            DECLARE @Subject NVARCHAR(255)
            DECLARE @Message NVARCHAR(MAX)

            SET @Subject = 'Welcome to Invia Connect - Your Enterprise Security Solution'
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


            EXEC msdb.dbo.sp_send_dbmail @profile_name = 'SQLAlerts'
                                        ,@recipients = @User_Email
                                        ,@subject = @Subject
                                        ,@body = @Message
                                        ,@body_format = 'HTML';
          END


            --Procedure for Sending Enquiry
            CREATE OR ALTER PROCEDURE sp_AddEnquiry @Id INT,
            @CustomerId INT
            AS
            BEGIN
              DECLARE @PlanName NVARCHAR(255);
              SELECT
                @PlanName = Plan_Name
              FROM Plans
              WHERE Id = @Id;

              IF EXISTS (SELECT
                    1
                  FROM Customers
                  WHERE Id = @CustomerId)
              BEGIN
                INSERT INTO Enquires (Enquiry_Date, isResolved, Message, CustomerId, PlanId)
                  VALUES (GETDATE(), 0, 'Hi, I need to know more about the ' + @PlanName, @CustomerId, @Id);
              END
            END


              -- sp_CustomerPlanDetails stored procedure
              CREATE OR ALTER PROCEDURE sp_CustomerPlanDetails 
			  @customerId INT
              AS
              BEGIN
                SELECT
                  c.Id
                 ,c.First_Name
                 ,c.Last_Name
                 ,c.Email
                 ,c.City
                 ,c.[Address]
                 ,c.Organization
                 ,p.Plan_Name
                 ,t.Current_Round
                 ,t.Plan_Start
                 ,t.Plan_End
                 ,p.Id AS planId
                FROM Customers c
                JOIN Transactions t
                  ON t.CustomerId = c.Id
                JOIN Plans p
                  ON p.Id = c.Current_Plan
                WHERE c.Id = @customerId
                ORDER BY T.IsLatest DESC, T.Plan_Start DESC;
              END

                -- Stored procedure customeTransactions Details
                CREATE OR ALTER PROCEDURE sp_CustomerTransactions @customerId INT
                AS
                BEGIN
                  SELECT
                    c.Id
                   ,t.Transaction_Id
                   ,t.Plan_Start
                   ,t.Plan_End
                   ,p.Plan_Name
                   ,p.Id AS planId
                  FROM Transactions t
                  JOIN Customers c
                    ON t.CustomerId = c.Id
                  JOIN Plans p
                    ON p.Id = t.PlanId
                  WHERE c.Id = @customerId
                END

                  --Stored procedure for Deleting User
                  CREATE OR ALTER PROCEDURE Sp_Delete_Customer @Customer_Id INT
                  AS
                  BEGIN
                    DECLARE @Subject NVARCHAR(255) = 'Account Deletion Notification';
                    DECLARE @Body NVARCHAR(MAX) = 'Dear Customer, we regret to inform you that your account has been deleted. Thank you for being our valuable customer.';
                    DECLARE @MailProfile NVARCHAR(128) = 'SQLAlerts';
                    DECLARE @CustomerMail NVARCHAR(255);

                    SELECT
                      @CustomerMail = c.Email
                    FROM Customers c
                    WHERE c.Id = @Customer_Id;

                    DELETE FROM Users
                    WHERE CustomerId = @Customer_Id;
                    DELETE FROM Transactions
                    WHERE CustomerId = @Customer_Id;
                    DELETE FROM Customers
                    WHERE Id = @Customer_Id;
                    DELETE FROM Enquires
                    WHERE CustomerId = @Customer_Id;

                    EXEC msdb.dbo.sp_send_dbmail @profile_name = @MailProfile
                                                ,@recipients = @CustomerMail
                                                ,@subject = @Subject
                                                ,@body = @Body;
                  END


                    -- stored procedure for next round start
                    CREATE OR ALTER PROCEDURE Sp_RoundUpdate @Customer_Id INT
                    AS
                    BEGIN
                      DECLARE @Round INT
                             ,@Max_Round INT
                      SELECT
                        @Round = t.Current_Round
                      FROM Transactions t
                      JOIN Customers c
                        ON t.Transaction_Id = c.TransactionId
                      WHERE t.CustomerId = @Customer_Id;

                      SELECT
                        @Max_Round = p.Max_Rounds
                      FROM Plans p
                      JOIN Customers c
                        ON p.Id = c.Current_Plan
                      WHERE c.Id = @Customer_Id;

                      IF (@Round < @Max_Round)
                      BEGIN
                        SET @Round += 1
                        UPDATE Transactions
                        SET Current_Round = @Round
                        WHERE CustomerId = @Customer_Id;
                      END
                    END

--Procedure for customer Details
CREATE OR ALTER PROCEDURE Sp_Update_Customer
 @Customer_Id INT,
 @Email NVARCHAR(255),
 @First_Name NVARCHAR(255),
 @Last_Name NVARCHAR(255),
 @City NVARCHAR(255),
 @Address NVARCHAR(255),
 @Current_Plan INT,
 @TransactionId INT,
 @Organization NVARCHAR(255)
AS
BEGIN
    DECLARE @Plan_Start DATETIME,@Plan_End DATETIME,@Validity int
	IF (@Current_Plan != (SELECT Current_Plan FROM Customers WHERE Id = @Customer_Id))
	BEGIN
		SET @Plan_Start = GETDATE();
		SET @Validity = (select Plan_Validity from Plans where Id = @Current_Plan);
		SET @Plan_End = DATEADD(DAY,@Validity,@Plan_Start);

		exec Sp_Create_Transaction @TransactionId,@Plan_Start,@Plan_End,1,1, @Customer_Id,@Current_Plan;
	END
	UPDATE Customers
    SET
        Email = @Email,
        First_Name = @First_Name,
        Last_Name = @Last_Name,
        City = @City,
        Address = @Address,
        Current_Plan = @Current_Plan,
        Organization = @Organization
    WHERE
        Id = @Customer_Id;
END

-- STORED PROCEDUR EXECUTION
 EXEC sp_GetAllCustomerData
EXEC sp_Create_Customer 'kunalshokeen051@gmail.com',
	'kunal',
	'shokeen',
	'Gurgoan',
	'India',
	'jharsa gurgaon',
	3,
	1234556,
	3,
	'Tower Research'

                      EXEC sp_AddEnquiry 2
                                        ,1
                      EXEC sp_CustomerTransactions 3012
                      EXEC sp_CustomerPlanDetails 4
                      EXEC Sp_Create_Transaction 324324
                                                ,'2023-10-28 18:17:08.350'
                                                ,'2024-04-28 18:17:08.350'
                                                ,1
                                                ,1
                                                ,3007
                                                ,2
                      EXEC Sp_Create_User 'kunalshokeen99@gmail.com'
                                         ,'admin123'
                                         ,0
                                         ,1
                                         ,1
                                         ,0
                      EXEC Sp_Delete_Customer 3024
                      EXEC Sp_RoundUpdate 3025		  
                   exec Sp_Update_Customer 1,'ddgangwar09@gmail.com','Dipanshu','Gangwar','Noida','Noida, Sector-59',1,'Google'

                      --Calling Tables
                      SELECT
                        *
                      FROM Plans
                      SELECT
                        *
                      FROM Customers
                      SELECT
                        *
                      FROM Transactions
                      SELECT
                        *
                      FROM Users
                      SELECT
                        *
                      FROM Enquires
					  select
					  *
					  from [Domains]
					  select
					  *
					  from [Subdomains]
					  select
					  *
					  from [RansomwareSusceptibilityTests]
					  select
					  *
					  from [Vulnerabilities]


-- --------------------------------------------------------------------------------------------------------------------------------		

INSERT INTO [dbo].[Domains] (Id, [Name], [Title], [RegDate], [ExpDate], [Registrar], [Size], [WebServer], [Country], [OpenPort], [CriticalPort], [IpAddress], [Customer_Id], [Round])
VALUES 
(NEWID(), 'example1.com', 'Example Website 6', '2023-01-15', '2024-01-15', 'GoDaddy', 'Small', 'Apache', 'United States', '80, 443', '22', '192.168.1.1', 4, 2),

INSERT INTO Vulnerabilities
     VALUES
           (
		    NEWID(),
            'Vulnerability9',
            'Description for Vulnerability9',
            '/path9',
            10,
            'Remediation9',
            'd2d9030b-664e-4ff9-b0f2-67059a9670e2',
            '192.168.1.14'
		)


 -- To select all the Domains of particular customer
 select c.Id,d.Title,d.Id,d.Name, d.IpAddress,d.CriticalPort,d.OpenPort,d.WebServer,d.Round,p.Max_Rounds,t.Current_Round from Customers c
 INNER JOIN Transactions t on t.PlanId = c.Current_Plan
 inner join Plans p on p.Id = t.PlanId
 inner join Domains d on d.Customer_Id = c.Id
 where c.Id = 31 and t.IsLatest = 1 order by d.Round desc


 -- To select all sub-domains of that particular customer
  select c.Id as CustomerId,s.Name,s.IpAddress,d.Name as Domain from Customers c
  join Domains d on d.Customer_Id = c.Id
  join Subdomains s on s.DomainId = d.Id
 where c.Id = 3027


 -- To get all result of Ransomware suspectibility test of a customer 
 select c.Id, d.Name, d.IpAddress, r.AffectedApplication, r.RansomwareType as type from Customers c
  join Domains d on d.Customer_Id = c.Id
  join RansomwareSusceptibilityTests r on r.DomainId = d.Id
  where c.Id = 3027


  -- to get all Vulnerabilities in domain of a customer
SELECT
    v.Id AS VulnerabilityId,
    v.Name AS VulnerabilityName,
    v.Description AS VulnerabilityDescription,
    v.Path AS VulnerabilityPath,
    v.SeverityRank AS SeverityRanking,
    v.Remidiation AS RemediationInfo,
    d.Id AS DomainId,
    d.Name AS DomainName,
    d.Title AS DomainTitle,
    d.Registrar AS DomainRegistrar,
    d.WebServer AS DomainWebServer,
    d.Country AS DomainCountry,
    d.OpenPort AS DomainOpenPort,
    d.CriticalPort AS DomainCriticalPort,
    d.IpAddress AS DomainIpAddress,
    c.Id AS CustomerId,
    c.First_Name AS CustomerName
FROM
    Domains d
JOIN
    Customers c ON d.Customer_Id = c.Id
JOIN
    Vulnerabilities v ON v.DomainId = d.Id
WHERE
    c.Id = 32
ORDER BY
    v.SeverityRank DESC


  CREATE or ALTER PROC RandNum
@TransactionId int,
@returnval int OUTPUT
AS
BEGIN
	DECLARE @in int,@out int
	SET @in = @TransactionId;
	IF EXISTS(SELECT Transaction_Id From Transactions WHERE Transaction_Id = @in)
	BEGIN
		SET @in = CAST(RAND() * 900000 + 1000 AS INT)
		exec RandNum @in, @out OUTPUT;
		SET @returnval = @out
	END
	ELSE
	BEGIN
		SET @returnval = @in
	END
END


--STORED PROCEDURE TO UPDATE CUSTOMER
CREATE OR ALTER PROCEDURE Update_Customer
 @Customer_Id INT,
 @Email NVARCHAR(255),
 @First_Name NVARCHAR(255),
 @Last_Name NVARCHAR(255),
 @City NVARCHAR(255),
 @Address NVARCHAR(255),
 @Current_Plan INT,
 @Organization NVARCHAR(255)
AS
BEGIN
    DECLARE @Plan_Start DATETIME,@Plan_End DATETIME,@Validity int,@TransactionId int,@r int
	SET @TransactionId = CAST(RAND() * 900000 + 1000 AS INT)
	exec RandNum @TransactionId, @r OUTPUT
	SET @TransactionId = @r
	IF (@Current_Plan != (SELECT Current_Plan FROM Customers WHERE Id = @Customer_Id))
	BEGIN
		SET @Plan_Start = GETDATE();
		SET @Validity = (select Plan_Validity from Plans where Id = @Current_Plan);
		SET @Plan_End = DATEADD(DAY,@Validity,@Plan_Start);
		
		exec Sp_Create_Transaction @TransactionId,@Plan_Start,@Plan_End,1,1, @Customer_Id,@Current_Plan;
	END
	UPDATE Customers
    SET
        Email = @Email,
        First_Name = @First_Name,
        Last_Name = @Last_Name,
        City = @City,
        Address = @Address,
        Current_Plan = @Current_Plan,
        Organization = @Organization
    WHERE
        Id = @Customer_Id;
END

  -- stored procedure for chart(threat level Dougnet chart)
CREATE OR ALTER PROCEDURE GetVulnerabilityCounts
  @customer_Id int,
  @Low_threat int output,
  @Medium_threat int output,
  @High_threat int output
AS
BEGIN
 select @Low_threat =  count(v.SeverityRank) from Customers c
                  join Domains d on d.Customer_Id = c.Id 
                  join Vulnerabilities v on v.DomainId = d.Id
                  where v.SeverityRank <= 4 and c.Id = @customer_Id

				   
 select @Medium_threat = count(v.SeverityRank) from Customers c
                  join Domains d on d.Customer_Id = c.Id 
                  join Vulnerabilities v on v.DomainId = d.Id
                  where v.SeverityRank <= 6 and v.SeverityRank > 4 and c.Id = @customer_Id

				   
 select @High_threat = count(v.SeverityRank) from Customers c
                  join Domains d on d.Customer_Id = c.Id 
                  join Vulnerabilities v on v.DomainId = d.Id
                  where v.SeverityRank <= 10 and v.SeverityRank > 6 and c.Id = @customer_Id
END

Declare @low int
Declare @medium int
Declare @high int
exec GetVulnerabilityCounts 38,@low OUTPUT,@medium OUTPUT,@high OUTPUT
select @low as 'Low Severity',@medium  as 'Medium Severity',@high  as 'High Severity'


-- stored procedure for adding domain
create or alter procedure sp_Add_Domain
@Id int,
@Title varchar(1000),
@Name nvarchar (500),
@IpAddress varchar(50),
@CriticalPort varchar(max),
@OpenPort varchar(max),
@WebServer varchar(250)
as
begin
DECLARE @Round int,@RegDate Datetime,@ExpDate Datetime,@Registrar varchar,@Size varchar,@Country varchar
SET @RegDate = GETDATE()
SET @ExpDate = DATEADD(YEAR, 1, @RegDate)
SET @Registrar = 'GoDaddy'
SET @Size = 'abc'
SET @Country = 'India'
SET @Round = (SELECT Current_Round FROM Transactions WHERE CustomerId = @Id AND IsLatest = 1)
 Insert into Domains(Id,Name,Title,RegDate,ExpDate,Registrar,Size,WebServer,Country,OpenPort,CriticalPort,IpAddress,Customer_Id,[Round])
 values(NEWID(),@Name,@Title,@RegDate,@ExpDate,@Registrar,@Size,@WebServer,@Country,@OpenPort,@CriticalPort,@IpAddress,@Id,@Round)
end

-- to get domain count
select COUNT(*) from Domains where Customer_Id = 27