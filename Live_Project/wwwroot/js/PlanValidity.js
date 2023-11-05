var id = $('#customer-id').val();

function fetchData() {
    return new Promise(function (resolve, reject) {
        $.ajax({
            url: '/charts/PlanValidity/' + id,
            method: 'GET',
            success: resolve,
            error: reject
        });
    });
}


fetchData()
    .then((data) => {
        var startDate = new Date(data.Plan_Start);
        var endDate = new Date(data.Plan_End);
        var currentDate = new Date();
        var totalDays = Math.floor((endDate - startDate) / (1000 * 60 * 60 * 24));
        var daysPassed = Math.floor((currentDate - startDate) / (1000 * 60 * 60 * 24));
        var completedPercentage = Math.ceil((daysPassed / totalDays) * 100);
        var remainingPercentage = 100 - completedPercentage;

        var ctx = document.getElementById('PlanValidity').getContext('2d');
        var chart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Plan Completed %', 'days left %'],
                datasets: [{
                    data: [completedPercentage, remainingPercentage],
                    backgroundColor: ['#6A0DAD', '#9370DB'],
                }],
                hoverOffset: 4
            },
        });


});

