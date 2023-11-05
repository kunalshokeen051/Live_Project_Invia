INSERT INTO Plans (Plan_Name, Plan_Validity, Plan_Amount, Max_Rounds)
VALUES ('Basic Plan', 30, 19.99, 1),
       ('Standard Plan', 90, 49.99, 3),
       ('Premium Plan', 365, 99.99, 6);


INSERT INTO Customers (Email, First_Name, Last_Name, City, Country, Address, Current_Plan, TransactionId, PlanId)
VALUES ('customer1@email.com', 'John', 'Smith', 'New York', 'USA', '123 Main St, Apt 101', 1, 1, 1),
       ('customer2@email.com', 'Alice', 'Johnson', 'Los Angeles', 'USA', '456 Elm St, Suite 201', 2, 2, 2),
       ('customer3@email.com', 'Bob', 'Lee', 'London', 'UK', '789 Oak St, Unit 301', 3, 3, 3);

INSERT INTO Transactions (Transaction_Id, Plan_Start, Plan_End, Current_Round, IsLatest, CustomerId, PlanId)
VALUES (101, '2023-01-15 00:00:00', '2023-04-15 00:00:00', 1, 1, 1, 1),
       (102, '2023-03-20 00:00:00', '2023-06-20 00:00:00', 2, 1, 2, 2),
       (103, '2023-02-10 00:00:00', '2023-05-10 00:00:00', 3, 1, 3, 3);


INSERT INTO Users (Username, Password, IsCustomer, IsAdmin, IsEmployee, CustomerId, TransactionId, IsActive)
VALUES ('user1', 'password1', 1, 0, 0, 1, 1, 1),
       ('kunalshokeen99', 'admin123', 0, 1, 0, NULL, NULL, 1),
       ('user2', 'password2', 1, 0, 0, 2, 2, 1),
       ('employee1', 'empypass', 0, 0, 1, NULL, NULL, 1);

	   -- Inserting entries into the Enquires table
INSERT INTO Enquires (Enquiry_Date, isResolved, Message, CustomerId, PlanId)
VALUES ('2023-10-20 10:00:00', 0, 'I have a question about the Basic Plan', 1, 1),
       ('2023-10-21 14:30:00', 0, 'I need information about the Premium Plan', 2, 3),
       ('2023-10-22 12:15:00', 1, 'I am satisfied with the Standard Plan', 3, 2),
	   ('2023-10-20 10:00:00', 1, 'I need information about your Standard Plan', 2, 2);

	