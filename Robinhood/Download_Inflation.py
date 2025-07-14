import requests

url = "https://data.bls.gov/pdq/SurveyOutputServlet"
payload = {
    "request_action": "get_data",
    "reformat": "true",
    "from_results_page": "true",
    "years_option": "specific_years",
    "delimiter": "comma",
    "output_type": "multi",
    "periods_option": "all_periods",
    "output_view": "pct_12mths",
    "to_year": "2024",
    "from_year": "2014",
    "output_format": "excelTable",
    "original_output_type": "default",
    "annualAveragesRequested": "false",
    "series_id": "CUUR0000SA0L1E"
}

response = requests.post(url, data=payload)
