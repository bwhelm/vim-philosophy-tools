#!/usr/bin/env python3
# ============================================================================
# PPSCRAPEBIBTEX.PY
# ============================================================================
#
# This takes a philpapers id and tries to retrieve bibtex info scraped from
# philpapers.org

from bs4 import BeautifulSoup as bs
from requests import get
from sys import argv

query = argv[1]
pageUrl = 'https://philpapers.org/export.html?expformat=bib&eIds=' + query + '&formatName=BibTeX'

# Note: PhilPapers.org seems to require a real web browser. I'm working around
# this by using the following headers to pretend to be a Mac browser.
headers = {"user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5)",
           "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
           "accept-charset": "ISO-8859-1,utf-8;q=0.7,*;q=0.3",
           "accept-language": "en-US,en;q=0.8"}

page = get(pageUrl, headers=headers)
soup = bs(page.text, 'html.parser')
list = soup.find(id="exported")
text = list.find("pre").text
print(text)
