using Microsoft.AspNetCore.Mvc;
using System;
using LP.Models;
using LP.Repository;

namespace Live_Project.Controllers
{
    public class HomeController : Controller
    {

        public IActionResult Index()
        {
            if(HttpContext.Session.GetString("usr") != null)
            {
                if(HttpContext.Session.GetString("UserType") == "Admin")
                {
                    return RedirectToAction("Index","Dashboard");
                }
                else
                {
                    int? id = HttpContext.Session.GetInt32("CurrentUser");
                    return RedirectToAction("ShowCustomerData", "Customer",new { id });
                }
            }
            return View();
        }

    }
}