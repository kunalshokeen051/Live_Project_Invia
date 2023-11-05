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
            return View();
        }

    }
}