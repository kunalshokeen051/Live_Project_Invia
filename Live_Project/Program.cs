using LP.Repository;
using Microsoft.Extensions.DependencyInjection;
using System.Data;
using System.Data.SqlClient;
using LP.Repository.Interfaces;
using LP.Repository.Repositories;
using AspNetCoreHero.ToastNotification;
using AspNetCoreHero.ToastNotification.Extensions;
using DinkToPdf.Contracts;
using DinkToPdf;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

builder.Services.AddDistributedMemoryCache();

builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(20);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddTransient<IDbConnection>(db => new SqlConnection(connectionString));


builder.Services.AddTransient<IUnitOfWork, UnitOfWork>();

builder.Services.AddScoped<ICustomerRepository>(serviceProvider =>
{
    var dbConnection = serviceProvider.GetRequiredService<IDbConnection>();
    var transaction = serviceProvider.GetRequiredService<IDbTransaction>();
    return new CustomerRepository(dbConnection, transaction);
});

builder.Services.AddScoped<IAdminRepository>(serviceProvider =>
{
    var dbConnection = serviceProvider.GetRequiredService<IDbConnection>();
    var transaction = serviceProvider.GetRequiredService<IDbTransaction>();
    return new AdminRepository(dbConnection, transaction);
});

builder.Services.AddNotyf(config => {
    config.DurationInSeconds = 5; config.IsDismissable = true; config.Position = NotyfPosition.TopRight; });

builder.Services.AddSingleton(typeof(IConverter), new SynchronizedConverter(new PdfTools()));

var app = builder.Build();

//Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
}
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.UseAuthentication(); 

app.UseSession();

app.UseNotyf();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
