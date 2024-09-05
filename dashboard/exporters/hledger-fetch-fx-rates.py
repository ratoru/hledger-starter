#!/usr/bin/env python3

import os
import sys
import time
from html.parser import HTMLParser

import requests

DRY_RUN = "--dry-run" in sys.argv
BASE_CURRENCY = "GBP"


def get_financial_times(url):
    class PriceFinder(HTMLParser):
        def __init__(self):
            HTMLParser.__init__(self)
            self.found = None
            self.isnext = False

        def handle_data(self, data):
            if self.found is not None:
                return

            if data == f"Price ({BASE_CURRENCY})":
                self.isnext = True
            elif self.isnext:
                self.found = data
                self.isnext = False

    r = requests.get(url)
    r.raise_for_status()
    finder = PriceFinder()
    finder.feed(r.text)
    if finder.found is None:
        raise Exception("could not find price")
    else:
        return finder.found


def get_financial_times_currency(symbol):
    return get_financial_times(
        f"https://markets.ft.com/data/currencies/tearsheet/summary?s={symbol}{BASE_CURRENCY}"
    )


def get_financial_times_fund(isin):
    return get_financial_times(
        f"https://markets.ft.com/data/funds/tearsheet/summary?s={isin}:{BASE_CURRENCY}"
    )


DATE = time.strftime("%Y-%m-%d")

COMMODITIES = [
    ("EUR", get_financial_times_currency),
    ("JPY", get_financial_times_currency),
    ("USD", get_financial_times_currency),
    ("VANEA", "GB00B41XG308", get_financial_times_fund),
]

with sys.stdout if DRY_RUN else open(os.environ["PRICE_FILE"], "a") as f:
    print("", file=f)

    for commodity in COMMODITIES:
        symbol = commodity[0]
        try:
            rate = commodity[-1](commodity[-2])
            print(f"P {DATE} {symbol} £{rate}", file=f)
        except Exception as e:
            print(f"; '{symbol}': {e}", file=f)
