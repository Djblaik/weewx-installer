<div class="row forecast-row">
    <div class="col-lg-8 forecastTitle" id="forecastTitle">
        <span class="forecast-stitle" id="stitle"></span>
    </div>
	
    <div class="col-lg-4 menu"></div>
    <div id="24hrselected-forecast" style="display: block;">
        <div class="banner col-lg-12 row-no-padding" id="forecast-banner">
            <!-- forecast cards are inserted here -->
        </div>        
    </div>
</div>
#raw
<script>
async function fetchWeatherData() {
    const apiUrl = 'https://api.weather.bom.gov.au/v1/locations/r7g860j/forecasts/daily';
    try {
        const response = await fetch(apiUrl);
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        const data = await response.json();
        // Assuming the API returns metadata along with the forecast data
        //const forecasts = data.data.slice(0, 7);  // Get only 7 days
        
        // en-CA gives YYYY-MM-DD which is safe for string comparison
        const today = new Date().toLocaleDateString('en-CA', {
            timeZone: 'Australia/Brisbane'
        });

        const forecastsFromToday = data.data
            .filter(f => {
                const forecastDay = new Date(f.date).toLocaleDateString('en-CA', {
                    timeZone: 'Australia/Brisbane'
                });
                return forecastDay >= today;
            })
            .slice(0, 7);

        return { forecasts: forecastsFromToday, issuetime: data.metadata.issue_time };

    } catch (error) {
        console.error('Error fetching weather data:', error);
        return null;
    }
}

function extractWindSpeed(text) {
    // const match = text.match(/(\d+\s*to\s*\d+|\d+)\s*km\/h/);
    // return match ? match[0].replace('to', '|') : "N/A";
	
	const match = text.match(/(\d+)\s*(?:to\s*(\d+))?\s*km\/h/);
    if (match) {
        const low = match[1]; // First number
        const high = match[2] || low; // Second number (or same as low if not given)
        return { low: parseInt(low, 10), high: parseInt(high, 10) };
    }
    return { low: "N/A", high: "N/A" };
}

function convertDate(gmtdate) {
    // Ensure gmtdate is a Date object
    const dateObj = new Date(gmtdate);
    const options = { 
      timeZone: 'Australia/Brisbane', 
      weekday: 'short', 
      day: 'numeric', 
      month: '2-digit' 
    };
    const aeTime = dateObj.toLocaleDateString('en-GB', options);
    const aestTime = aeTime.replace(/^0/, ''); // Remove leading zeros
    console.log(aestTime); // Outputs, e.g., Tue 3/04
    return aestTime;
}

function issuedate(idate) {
	const dateObj = new Date(idate);
	// Options for formatting the date and time
	const options = {
	  year: 'numeric',
	  month: 'long',
	  day: 'numeric',
	  hour: 'numeric',
	  minute: 'numeric',
	  second: 'numeric',
	  hour12: true,
	  timeZone: 'Australia/Brisbane'
	};

	// Format the date using the options
	const formattedDate = dateObj.toLocaleString('en-US', options);
	return formattedDate;
}

function renderBanner(forecasts, issuetime) {
    const banner = document.getElementById('forecast-banner');
    banner.innerHTML = '';  // Clear previous content

    const title = document.getElementById('forecastTitle');
	
    title.innerHTML = `Forecast ` + `<span class="forecast-stitle" id="stitle"></span>`;
	
	const stitle = document.getElementById('stitle');
	
	
	if (issuetime) {
		const localDate = issuedate(issuetime);
		stitle.innerHTML = `Last updated on ${localDate}`;
    } else {
        stitle.innerHTML = 'Last updated information not available';
    }
	
    forecasts.forEach(forecast => {
        const card = document.createElement('div');
        card.classList.add('forecast-card');
		card.classList.add('border-left');
        const date = new Date(forecast.date);
        const today = new Date();

    if (
        date.getDate() === today.getDate() &&
        date.getMonth() === today.getMonth() &&
        date.getFullYear() === today.getFullYear()
    ) {
        formdate = 'Today';
    } else {
        formdate = date.toLocaleDateString('en-AU', { weekday: 'short', day: 'numeric', month: 'short' });
    }

		const windSpeed = extractWindSpeed(forecast.extended_text);
        card.innerHTML = `
            <span class="date">${formdate}</span>
                <br>
                <div class="forecast-conds">
                    <img class="icon" src="bomsvgicons/${forecast.icon_descriptor}.svg" alt="${forecast.short_text}">
                    <br>
                    <span class="forecast-text">${forecast.short_text}</span>
                </div>
				<span class="temp">${forecast.temp_min ?? '--'}°</span>
				|
                <span class="temp">${forecast.temp_max ?? '--'}°</span>
                <br>
                <div class="rain">
                    <img src="bomsvgicons/rain.svg" class="icon2" alt="rain">
                    <span>
                    ${forecast.rain.amount.lower_range} - ${forecast.rain.amount.upper_range} mm
                    </span>
                </div>
                <div class="wind">
                    <img src="bomsvgicons/wind.svg" class="icon2" alt="Wind">
                    <span>${windSpeed.low}</span>                    |
                    <span> ${windSpeed.high} km/h</span>
                </div>
        `;
        banner.appendChild(card);
    });
}

async function updateWeather() {
    const lastFetch = localStorage.getItem('lastWeatherFetch');
    const now = Date.now();
    const cachedData = localStorage.getItem('weatherData');

    // If more than 6 hours have passed or no cached data exists
    if (!cachedData || now - lastFetch >= 6 * 60 * 60 * 1000) {
        const result = await fetchWeatherData();
        if (result && result.forecasts) {
            renderBanner(result.forecasts, result.issuetime);
            // Cache the forecasts and issue time together
            localStorage.setItem('weatherData', JSON.stringify(result));
            localStorage.setItem('lastWeatherFetch', now);
        }
    } else {
        const cachedResult = JSON.parse(cachedData);
        renderBanner(cachedResult.forecasts, cachedResult.issuetime);
    }
}

async function init() {
    await updateWeather();
}

init();
</script>
#end raw

<style>
	.forecast-row {
		text-align: center;
		
}


	.forecastTitle {
		text-align: left;
		font-size: 25px;
		margin-bottom: 5px;
		padding-right: 0 !important;
}

	.forecast-stitle {
		font-size: 14px;
}
	
	.forecast-conds {
		min-height:160px;
		word-wrap:break-word;
}

	.forecast-card {
		position: relative;
		min-height: 270px;
		padding-left: 10px;
		padding-right: 10px;
		display: inline-block;
		width: 165px;position: relative;
		min-height: 270px;
		padding-left: 10px;
		padding-right: 10px;
		display: inline-block;
		width: 165px;
	}
	.date { 
		font-size: 1.2em; 
		margin-bottom: 5px; }
	
	.temp {
		margin: 5px 0;
		font-weight: 500; }
	
	.rain { 
		font-size:15px; }
		
	.wind { 
		font-size:15px; }
	
	//.icon { 
	//	width:30%;
    //    height:120; }
	
	.icon2 { 
		width: 24px; 
		height: 24px; 
		margin-top: 5px;
		margin-right: 10px; }
		
	.forecast-card:first-child {
		border-left: none !important; }
		
	.forecast-text {
		display:block;
	}
	
	.desc {
		min-height:160px;
		word-wrap:break-word;
	}
	
	.forecast-stitle {
		font-size: 14px;
		font-family: Roboto, sans-serif;
		font-weight: 300;
		line-height: 1.625;
	}
	
	@media (min-width: 1200px) {
		.col-lg-12 {
			width: 100%;
		}
		
		.col-lg-8 {
        width: 66.66666667%;
    }
	
		.col-lg-4 {
			width: 33.33333333%;
		}
	}
	
	
	@media (max-width: 768px) {
		.banner {
			max-width: 100%;
			flex-wrap: wrap; /* Allows items to wrap */
			gap: 10px; /* Adds spacing between items */
		}

		.forecast-card {
			flex: 1 1 48%; /* Ensures two cards per row */
			max-width: 48%;
			border-left: none !important; /* Removes unnecessary borders */
			border-bottom: 1px solid #D7D7D7 !important;
		}

		.forecast-card:nth-child(odd) {
			border-left: none !important; /* Adds border only to second column */
		}
    }
</style>
