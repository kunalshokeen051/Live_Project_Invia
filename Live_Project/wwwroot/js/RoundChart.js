var id = $('#customer-id').val();

function fetchData() {
    return new Promise(function (resolve, reject) {
        $.ajax({
            url: '/charts/RoundsLeft/' + id,
            method: 'GET',
            success: resolve,
            error: reject
        });
    });
}


fetchData()
    .then(function (data) {
        var completedPercentage = Math.ceil((data.Current_Round / data.Max_Rounds) * 100);
        var remainingPercentage = 100 - completedPercentage;
        var ctx = document.getElementById('progressChart').getContext('2d');
        var chart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Completed Round %', 'Rounds Left %'],
                datasets: [{
                    data: [completedPercentage, remainingPercentage],
                    backgroundColor: ['#6A0DAD', '#9370DB'],
                }],
                hoverOffset: 4
            }
        });
    })
    .catch(function (error) {
        console.log(error);
    });
