# Imports libraries for Robinhood access, file I/O, data handling, and timestamps
import robin_stocks.robinhood as rs
import base64
import os
import glob
import pandas as pd
from datetime import datetime


def excel_to_csv_list(file_path):
    df = pd.read_excel(file_path, engine='openpyxl')
    csv_list = df.to_csv(index=False).splitlines()
    return csv_list

def get_rows_after_year(csv_list):
    header_index = next((i for i, row in enumerate(csv_list) if "Year" in row), None)
    if header_index is not None:
        return csv_list[header_index:]
    else:
        return []

def extract_date():
    from datetime import datetime
    current_date = datetime.now()
    current_year = current_date.year
    current_month = current_date.month
    index = current_year - 2012
    months_left = 12 - current_month
    return index, months_left

def FindPortfolioYield(summary, symbols):
    total_yield = 0
    del(symbols[0])
    i = 0
    while i < len(summary):
        symbol = symbols[i]['symbol']
        div_yields = rs.stocks.get_fundamentals(symbol, info='dividend_yield')
        div_yield = (div_yields[0])
        pct_of_portfolio = float(summary[symbol]['percentage'])/100
        if div_yield != None:
            stock_yield = float(div_yield)/100 * pct_of_portfolio
            total_yield += stock_yield
        i += 1
    return total_yield*100

def FindTotalReinvested(summary, symbols):
    #del(symbols[0])
    i = 0
    total_amnt_invst = 0
    total_amnt = 0
    reinvested_pct = 0
    while i < len(summary):
        symbol = symbols[i]['symbol']
        length = len(summary[symbol])
        equity = summary[symbol]['equity']
        total_amnt = total_amnt + float(equity)
        if length > 12: 
            amnt_reinvested = summary[symbol]['amount_paid_to_date']
            total_amnt_invst += float(amnt_reinvested)
        i += 1
    reinvested_pct = (total_amnt_invst / total_amnt) * 100
    return total_amnt_invst, reinvested_pct, total_amnt

def FindPortfolioGrowth(summary, symbols):
    i = 0
    total_growth_pct = 0
    while i < len(summary):
        symbol = symbols[i]['symbol']
        pct_of_portfolio = float(summary[symbol]['percentage'])/100
        prices = rs.stocks.get_stock_historicals(symbol, interval='week', span='year', bounds='regular', info=None)
        start_price = prices[0]['open_price']
        current_price = prices[-1]['open_price']
        #print(start_price, current_price)
        difference =  float(current_price) - float(start_price)
        pct_growth = difference/float(start_price)
        total_growth_pct += (pct_of_portfolio * pct_growth)
        i += 1
    return total_growth_pct

def GetInflationRate():
    downloads_path = os.path.join(os.path.expanduser("~"), "Downloads")
    file_pattern = os.path.join(downloads_path, "*SeriesReport-*.xlsx")
    matching_files = glob.glob(file_pattern)
    matching_files = [file for file in matching_files if not os.path.basename(file).startswith('~$')]
    for file_path in matching_files:
        csv_list = excel_to_csv_list(file_path)
        index, months = extract_date()
        rows_after_year = get_rows_after_year(csv_list)
        last12months = []
        rows = 2
        r = 0
        while r < rows: 
            index += r
            row = rows_after_year[index]
            row_list = row.split(',')
            row_list = [float(item) if i != 0 else int(item) for i, item in enumerate(row_list) if item]
            if r == 0:
                row_list = row_list[months+1:13]
            else:
                row_list = row_list[1:]
            last12months.append(row_list)
            r += 1
        flattened_list = [item for sublist in last12months for item in sublist]
        average = sum(flattened_list) / len(flattened_list)
        return average
    # Print a message if no files are found
    if not matching_files:
        print("No files found containing 'SeriesReport-' in the name.")

if __name__ == "__main__":
    password = 'enZxemR6bHJzMQ=='
    rs.login(username='adhi.ramkumar@gmail.com',
         password=base64.b64decode(password),
         expiresIn=4000,
         by_sms=True)
    summary = rs.account.build_holdings(with_dividends=True)
    symbols = rs.account.get_all_positions()
    annual_returns = 0
    monthly_returns = 0
    inflation_rate = GetInflationRate()
    total_yield_pct = FindPortfolioYield(summary, symbols)
    total_amnt_invst, reinvested_pct, total_amnt = FindTotalReinvested(summary, symbols)
    user_exp = input("Enter the number of years you would like to see growth for: ")
    total_growth_pct = FindPortfolioGrowth(summary, symbols) * 100
    buying_power_pct = (total_growth_pct + total_yield_pct) - inflation_rate
    years_growth = (1+buying_power_pct/100) ** float(user_exp)
    total_money_pct = total_growth_pct + total_yield_pct
    total_money = (1+total_money_pct/100) ** float(user_exp)
    money_buy_growth = total_amnt * years_growth
    money_growth = total_amnt * total_money
    annual_returns = total_amnt * total_yield_pct/100
    monthly_returns = annual_returns / 12
    print("Your Portfolio Amount: ", total_amnt, "$")
    print("Total buying power in", user_exp, "years:", money_buy_growth)
    print("Total Money in", user_exp, "years:", money_growth)
    print("Your Annual income:", annual_returns)
    print("Your Monthly income:", monthly_returns)
    print("Your total dividend yield is:", total_yield_pct, "%")
    print("Your total dividend yield accrued:", total_amnt_invst, " which is this percentage of your total portfolio", reinvested_pct)
    print("Your total Portfolio Growth this past year is:", total_growth_pct)
    print("My total growth in the past 12 months: ",)
    print("Your increase in buying power over the last 12 months:", buying_power_pct)


   