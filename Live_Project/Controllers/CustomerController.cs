using LP.Models;
using Microsoft.AspNetCore.Mvc;
using LP.Repository.Interfaces;
using Microsoft.AspNetCore.OutputCaching;
using AspNetCoreHero.ToastNotification.Abstractions;
using LP.Repository;

[Authorized_Access_Only]
public class CustomerController : Controller
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly INotyfService _notyf;

    public CustomerController(IUnitOfWork UnitOfWork, INotyfService notyf)
    {
        _unitOfWork = UnitOfWork;
        _notyf = notyf;
    }
        
    public IActionResult GetAll()
    {
        try
        {
            var Result = _unitOfWork.CustomerRepository.GetAllCustomers();
            _unitOfWork.SaveChanges();
            return Json(Result);
        }

        catch(Exception e)
        {
            return StatusCode(500,"An Error Occured:" + e.Message);
        }
    }

    public IActionResult ShowCustomerData(int id)
    {
        try
        {
            var Result =  _unitOfWork.CustomerRepository.GetCustomerById(id);
            _unitOfWork.SaveChanges();

            return View(Result);
        }

        catch(Exception e)
        {
            return StatusCode(500, "An Error Occured:" + e.Message);
        }
    }

    [HttpPost]
    public IActionResult SendEnquiry(int Id, int customerId )
    {
       var status =  _unitOfWork.CustomerRepository.SendEnquiryToAdmin(Id, customerId);
        _unitOfWork.SaveChanges();
        if (status)
        {
            _notyf.Information("Enquiry sent successfully");
            return Json(new { success = true });
        }

        else
        {
            _notyf.Error("Enquiry failed");
            return Json(new { success = false});
        }
    } 
    
    public IActionResult GetTransactions(int Id )
    {
       var Data =  _unitOfWork.CustomerRepository.GetTransactions(Id);
        _unitOfWork.SaveChanges();
        if (Data != null)
        {
            return Json(new { success = true, data = Data });
        }

        else
        {
            _notyf.Warning("No Transaction Found");
            return Json(new { success = false });
        }
    }

    [HttpPost]
    public JsonResult EnquiryStatus(int enquiryId, bool isResolved)
    {
        try
        { 
            var success = _unitOfWork.CustomerRepository.UpdateEnquiryStatus(enquiryId, !isResolved);
            _unitOfWork.SaveChanges();
            if (success)
            {  
                _notyf.Warning("Enquiry Updated.");
                return Json(new { success = true });
            }
            else
            {
                _notyf.Warning("Failed to update status.");
                return Json(new { success = false });
            }
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = ex.Message });
        }
    }

}
