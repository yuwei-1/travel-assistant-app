from dataclasses import dataclass
from googlesearch import search
import requests
import time
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from requests_html import HTMLSession, AsyncHTMLSession


@dataclass
class ExpediaFlightResultsGetter:

    timeout : int = 20
    url : str = """https://www.expedia.com/Flights-Search?flight-type=on&mode=search&trip=roundtrip&\
                leg1=from:{_from},to:{_to},departure:{_start_date}TANYT&\
                leg2=from:{_to},to:{_from},departure:{_end_date}TANYT&\
                options=cabinclass:{_cabin_class}&passengers=adults:{_num_travellers},infantinlap:N"""
    library : str = "selenium"

    def get(self, search_csv):
        """
        search_csv : from airport, to airport, start date, end date, cabin class, number of travellers
        """
        self._get_url(search_csv)
        print(self.url)
        return self._retrieve_from_soup()
    
    def _retrieve_from_soup(self):
        if self.library == "selenium":
            options = webdriver.ChromeOptions()
            driver = webdriver.Chrome(options=options)
            driver.get(self.url)
            flight_offerings = ""
            tic = toc = time.perf_counter()
            while not flight_offerings and (toc-tic < self.timeout):
                toc = time.perf_counter()
                flight_offerings = self._get_expedia_info(driver.page_source)
        else:
            response = requests.get(self.url, timeout=self.timeout).content
            flight_offerings = self._get_expedia_info(response)
        return self._result_guard(flight_offerings)

    def _get_expedia_info(self, response):
        soup = BeautifulSoup(response, 'html.parser')
        offers = soup.find_all('div', {"class" : ["uitk-card uitk-card-roundcorner-all uitk-card-has-border uitk-card-has-primary-theme"]})
        available_flights = []
        for divs in offers:
            res = divs.find_all('span', {"class" : ["is-visually-hidden"]})[-1]
            available_flights.append(res)
        return ". ".join([offer.text for offer in available_flights])
    
    @staticmethod
    def _result_guard(result):
        return result if result else "no results found"
    
    def _get_url(self, search_csv):
        _from, _to, _start_date, _end_date, _cabin_class, _num_travellers = search_csv.split(",")
        self.url = self.url.format(_from=_from, _to=_to, 
                              _start_date=_start_date, _end_date=_end_date, 
                              _cabin_class=_cabin_class, _num_travellers=_num_travellers).replace(" ", "")