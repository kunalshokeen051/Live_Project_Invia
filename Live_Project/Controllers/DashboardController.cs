using Dapper;
using LP.Models;
using LP.Models.ViewModels;
using LP.Repository.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System.Data;
using AspNetCoreHero.ToastNotification.Abstractions;
using LP.Repository;

namespace Live_Project.Controllers
{
    [Authorized_Access_Only]
    public class DashboardController : Controller
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INotyfService _notyf;

        public DashboardController(IUnitOfWork UnitOfWork, INotyfService notyf)
        {
            _unitOfWork = UnitOfWork;
            _notyf = notyf;
        }

        public IActionResult Index()
        {
            if (HttpContext.Session.GetString("UserType") == "Admin")
            {
                _notyf.Success("Hello Admin!",2);
                return View();
            }
            else
            {
                return StatusCode(401, "Unauthorized access");
                

            }
        }
 
        public IActionResult Enquires()
        {
            try
            {
                var Result = _unitOfWork.AdminRepository.Enquires();

                if(Result != null)
                {
                    return View(Result);
                }

                else
                {
                    _notyf.Information("No notification found");
                    return View();
                }
            }
            catch(Exception e)
            {
                return StatusCode(500, "An Error Occured");
            }
        }

        public IActionResult ActiveEnquires()
        {
            try
            {
                int unresolvedInquiryCount = _unitOfWork.AdminRepository.ActiveEnquires();

                if (unresolvedInquiryCount > 0)
                {
                    _notyf.Information("You have new Enquires");
                }

                return Json(new { success = true, message = "Enquiry data Received", unresolvedInquiries = unresolvedInquiryCount });
            }

            catch (Exception ex)
            {
                return StatusCode(500, "An error occured" + ex.Message);
            }
        }

        [HttpPost]
        public IActionResult AddCustomer(Customer obj)
        {
            try
            {
                var status = _unitOfWork.AdminRepository.AddCustomer(obj);
                _unitOfWork.SaveChanges();
                _notyf.Success("Customer added successfully");
                return RedirectToAction("Index");
            }

            catch (Exception ex)
            {
                
                return StatusCode(500, "An error occured" + ex.Message);
            }
        }

        public IActionResult DeleteCustomer(int id)
        {
            try
            {
                var status = _unitOfWork.AdminRepository.DeleteCustomer(id);
                if (status)
                {
                    _notyf.Success("User Successfully Deleted");
                    _unitOfWork.SaveChanges();
                    return Json(new { success = true});
                }
                else
                {
                    _notyf.Error("Error Occured while Deleting Customer");
                    throw new Exception("Error Occured while Deleting Customer");
                }
            }
            catch(Exception ex)
            {
                return StatusCode(500, "An error occured" + ex.Message);
            }
        }

        public IActionResult DisableUser(int id)
        {
            try
            {
                var status = _unitOfWork.AdminRepository.DisableUser(id);
                if (status)
                {
                    _notyf.Success("User Status Updated");
                    _unitOfWork.SaveChanges();                    
                    return Json(new { success = true});
                }
                else
                {
                    throw new Exception("Error Occured while updating User status");
                }
            }

            catch (Exception ex)
            {
                return StatusCode(500, "An error occured" + ex.Message);
            }
        }

        [HttpPost]
        public IActionResult UpdateCustomer(Customer obj)
        {
            try
            {
                var status = _unitOfWork.AdminRepository.UpdateCustomer(obj);
                if (status)
                {
                    _unitOfWork.SaveChanges();
                    _notyf.Success("User Updated Deleted");
                    return Json(new { success = true });
                }
                else
                {
                    _notyf.Error("Error Occured while Updating Customer");
                    throw new Exception("Error Occured while Updating Customer");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, "An error occured" + ex.Message);
            }
        }

        [HttpPost]
        public IActionResult UpdateRound(int Id)
        {
            try
            {
                var status = _unitOfWork.AdminRepository.UpdateRound(Id);
                if (status)
                {
                    _unitOfWork.SaveChanges();
                    _notyf.Success("Next Round Started Successfully");
                    return Json(new { success = true });
                }
                else
                {
                    _notyf.Error("Error, can't update the rounds");
                    return RedirectToAction("ShowCustomerData","Customer");
                }
            }
            catch(Exception ex)
            {
                return StatusCode(500, "An error occured" + ex.Message);
            }
        }
    }
}
