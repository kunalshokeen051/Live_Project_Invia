using LP.Models;
using LP.Repository.Interfaces;
using System;
using System.Linq;
using Dapper;
using System.Data;
using LP.Models.ViewModels;
using System.Collections.Generic;
using System.Reflection;

namespace LP.Repository.Repositories
{
    public class AdminRepository:IAdminRepository
    {
        private readonly IDbConnection _dbConnection;
        private readonly IDbTransaction _transaction;

        public AdminRepository(IDbConnection dbConnection, IDbTransaction transaction)
        {
            _dbConnection = dbConnection;
            _transaction = transaction;
        }

        bool IAdminRepository.AddCustomer(Customer obj)
        {
            try
            {
               
                _dbConnection.Execute("sp_Create_Customer", new
                {
                    Email = obj.Email,
                    First_Name = obj.F_Name,
                    Last_Name = obj.L_Name,
                    City = obj.City.ToString(),
                    Country = obj.Country.ToString(),
                    Address = obj.Address,
                    Current_Plan = obj.CurrentPlan,
                    TransactionId = GenerateNewTransactionId(),
                    PlanId = obj.CurrentPlan,
                    Organization = obj.Organisation
                }, commandType: CommandType.StoredProcedure, transaction: _transaction);


                return true;
            }


            catch (Exception ex)
            {
                Console.WriteLine("An error occurred: " + ex.Message);
                return false;
            }
        }
        int GenerateNewTransactionId()
        {
            Random rand = new Random();
            int transactionId = rand.Next(100000, 999999);

            bool isUnique = IsTransactionIdUnique(transactionId);
            if (isUnique)
            {
                return transactionId;
            }
            else
            {
                return GenerateNewTransactionId();
            }

        }
        bool IsTransactionIdUnique(int transactionId)
        {
            try
            {
                string query = "SELECT COUNT(*) FROM Transactions WHERE Transaction_Id = @transactionId";

                DynamicParameters dp = new DynamicParameters();
                dp.Add("@transactionId", transactionId);

                int count = _dbConnection.Query<int>(query, dp,transaction:_transaction).FirstOrDefault();
                return count == 0;
            }

            catch (Exception ex)
            {
                Console.WriteLine("An error occurred: " + ex.Message);
                return false;
            }
        }

        bool IAdminRepository.DeleteCustomer(int id)
        {
            try
            {
                _dbConnection.Execute("Sp_Delete_Customer", new { Customer_Id = id }, commandType: CommandType.StoredProcedure, transaction: _transaction);
                return true;
            }

            catch (Exception ex)
            {
                return false;
                throw new Exception("Error deleting customer.", ex);
            }
        }

        bool IAdminRepository.DisableUser(int id)
        {
            try
            {
                string query = "SELECT IsActive FROM Users WHERE CustomerId = @customerId";
                int currentIsActiveValue = _dbConnection.QuerySingleOrDefault<int>(query, new { customerId = id }, transaction: _transaction);

                int newIsActiveValue = currentIsActiveValue == 1 ? 0 : 1;

                string updateQuery = "UPDATE Users SET IsActive = @newIsActiveValue WHERE CustomerId = @customerId";
                _dbConnection.Execute(updateQuery, new { newIsActiveValue, customerId = id }, transaction: _transaction);

                return true;
            }

            catch (Exception ex)
            {
                return false;
                throw new Exception("Error deleting customer.", ex);
            }
        }

        bool IAdminRepository.UpdateRound(int Id)
        {
            try
            {
                var rowsAffected =_dbConnection.Execute("Sp_RoundUpdate", new { Customer_Id = Id },
                    commandType: CommandType.StoredProcedure, transaction: _transaction);
                if(rowsAffected == 1)
                {
                return true;
                }
                else { 
                    return false; 
                };
            }

            catch (Exception ex)
            {
                return false;
                throw new Exception("Error updating round.", ex);
            }
        }

        IEnumerable<CustomerEnquiryViewModel> IAdminRepository.Enquires()
        {
            try
            {

                string query = @"
                                SELECT
                                    C.First_Name + ' ' + C.Last_Name AS CustomerName,
                                    C.Email AS CustomerEmail,
                                    P.Plan_Name AS CurrentPlanName,
                                    P.Plan_Validity AS PlanValidity,
                                    E.Id,
                                    E.Enquiry_Date,
                                    E.isResolved,
                                    E.Message
                                FROM Enquires E
                                INNER JOIN Customers C ON E.CustomerId = C.Id
                                INNER JOIN Plans P ON C.PlanId = P.Id
                                ORDER BY CustomerName, E.isResolved ASC, E.Enquiry_Date ASC";

                var results = new Dictionary<string, CustomerEnquiryViewModel>();
                _dbConnection.Query<CustomerEnquiryViewModel, Enquiry, CustomerEnquiryViewModel>(
                    query,
                    (viewModel, enquiry) =>
                    {
                        if (!results.TryGetValue(viewModel.CustomerName, out var existingViewModel))
                        {
                            existingViewModel = viewModel;
                            existingViewModel.Enquiries = new List<Enquiry>();
                            results[viewModel.CustomerName] = existingViewModel;
                        }
                        existingViewModel.Enquiries.Add(enquiry);
                        return viewModel;
                    },
                    splitOn: "Id",
                    transaction: _transaction
                );

                var groupedResults = results.Values.ToList();

                return groupedResults;
            }

            catch (Exception ex)
            {
                throw;
            }
        }
        int IAdminRepository.ActiveEnquires()
        {
            try
            {
                string sql = "SELECT COUNT(*) FROM enquires WHERE IsResolved = 0";
                int Count = _dbConnection.QuerySingle<int>(sql,transaction:_transaction);

                return Count;
            }
            catch(Exception ex)
            {
                throw;
            }
        }

        IEnumerable<DomainVM> IAdminRepository.GetAllDomains(int Id)
        {
            try
            {
                string sql = @"select c.Id,d.Title,d.Id as DoaminId,d.Name, d.IpAddress,d.CriticalPort,d.OpenPort,d.WebServer,d.Round,p.Max_Rounds,t.Current_Round from Customers c
                               INNER JOIN Transactions t on t.CustomerId = c.Id
                               inner join Plans p on p.Id = t.PlanId
                               inner join Domains d on d.Customer_Id = c.Id
                               where c.Id = @Cus_Id and t.IsLatest = 1 order by d.Round desc";

                var domains = _dbConnection.Query<DomainVM>
                (sql, new { @Cus_Id = Id }, transaction: _transaction);
                return domains.ToList();
            }

            catch (Exception ex)
            {
                Console.WriteLine("An error occurred: " + ex.Message);
                throw;
            }
        }

        IEnumerable<SubDomainVM> IAdminRepository.GetAllSubDomains(int Id)
        {
            try
            {
                string sql = "select c.Id as CustomerId,s.Name,s.IpAddress,d.Name as Domain " +
                    "from Customers c join Domains d on d.Customer_Id = c.Id " +
                    "join Subdomains s on s.DomainId = d.Id where c.Id = @Cus_Id";
                var subdomains = _dbConnection.Query<SubDomainVM>
                (sql, new { Cus_Id = Id }, transaction: _transaction);
                return subdomains.ToList();
            }

            catch (Exception ex)
            {
                Console.WriteLine("An error occurred: " + ex.Message);
                throw;
            }
        }

        IEnumerable<VulnerableDomainVM> IAdminRepository.GetAllVulnerableDomains(int Id)
        {
            try
            {

                var vulnerableDomains = _dbConnection.Query<VulnerableDomainVM>
                ("sp_GetAllVulnerableDomains", new { Customer_Id = Id }, commandType: CommandType.StoredProcedure, transaction: _transaction);
                return vulnerableDomains;
            }

            catch (Exception ex)
            {
                Console.WriteLine("An error occurred: " + ex.Message);
                throw;
            }


        }
        bool IAdminRepository.AddDomain(Domain obj)
        {
            try
            {
                var result =  _dbConnection.Execute("sp_Add_Domain", new
                {
                    Id = obj.Id,
                    Title = obj.Title,
                    Name = obj.Name,
                    IpAddress = obj.IpAddress,
                    CriticalPort = obj.CriticalPort,
                    OpenPort = obj.OpenPort,
                    WebServer = obj.WebServer
                }, commandType: CommandType.StoredProcedure, transaction: _transaction);

                /*result*/
                return true;
            }

            catch (Exception ex)
            {
                return false;
            }
        }

        bool IAdminRepository.UpdateCustomer(CustomerDetailsVM obj)
        {
            try
            {
                _dbConnection.Execute("Update_Customer", new
                {
                    Customer_Id = obj.Id,
                    Email = obj.Email,
                    First_Name = obj.First_Name,
                    Last_Name = obj.Last_Name,
                    City = obj.City,
                    Address = obj.Address,
                    Current_Plan = obj.Plan_Name,
                    Organization = obj.Organization
                }, commandType: CommandType.StoredProcedure, transaction: _transaction);


                return true;
            }


            catch (Exception ex)
            {
                return false;
            }
        }

        bool IAdminRepository.DeleteDomain(int id,string IpAddress)
        {

            try
            {
                string sql = @"DELETE FROM Domains WHERE IpAddress = @IpAddress AND Customer_Id = @id";
                var result = _dbConnection.QueryFirstOrDefault(sql, new { @IpAddress = IpAddress, @id = id},transaction:_transaction);

                if(result  == null)
                {
                    return false;
                }
                else
                {
                  return true;
                }
            }

            catch (Exception ex)
            {
                Console.WriteLine("An error occurred: " + ex.Message);
                throw;
            }
        }
    }
}
