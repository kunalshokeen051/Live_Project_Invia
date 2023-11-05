using LP.Models;
using LP.Models.ViewModels;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LP.Repository.Interfaces
{
    public interface IAdminRepository
    {
        bool AddCustomer(Customer obj);
        bool DeleteCustomer(int id);
        bool DisableUser(int id);
        bool UpdateCustomer(Customer obj);
        bool UpdateRound(int Id);
        IEnumerable<CustomerEnquiryViewModel> Enquires();
        int ActiveEnquires();
    }
}
