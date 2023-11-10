using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LP.Models.ViewModels
{
    public class SubDomainVM
    {
        public int Id {get; set;}
        public int Customer_Id {get; set;}
        public string IpAddress { get; set;}
        public string Domain { get; set;}
    }
}
