#!/usr/bin/env python3
# ============================================================================
# PPSEARCH.PY
# ============================================================================
#
# This takes a search query, scrapes search results from http://philpapers.org,
# and formats and prints those results.

from bs4 import BeautifulSoup as bs
from re import sub, IGNORECASE
from requests import get
from sys import argv
import subprocess
import re
from nameparser import HumanName
from nameparser.config import CONSTANTS

# Format for names (from nameparser)
CONSTANTS.string_format = "{last}, {first} {middle} {suffix}"

query = '%20'.join(argv[1:])

# Note: PhilPapers.org seems to require a real web browser. I'm working around
# this by using the following headers to pretend to be a Mac browser.
headers = {"user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5)",
           "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
           "accept-charset": "ISO-8859-1,utf-8;q=0.7,*;q=0.3",
           "accept-language": "en-US,en;q=0.8"}

pageUrl = 'https://philpapers.org/s/' + query
page = get(pageUrl, headers=headers)
soup = bs(page.text, 'html.parser')
list = soup.find('ol', class_='entryList')


def pandocConvert(text, toFormat):
    pandocCmd = subprocess.Popen(['/opt/homebrew/bin/pandoc',
                                  '-f', 'html', '-t', toFormat],
                                 text=True,
                                 stdin=subprocess.PIPE,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
    return pandocCmd.communicate(input=text)[0][:-1]


def printList(list):
    counter = 0
    text = ''
    if list is None:
        return 'Search returned no hits.'
    for item in list.contents:
        if item != '\n':  # Note: every other item is '\n'
            counter += 1
            try:
                item_id = item['id'][1:]
            except KeyError:
                item_id = ''
            try:
                item_citation = item.find('span', {'class': 'citation'})
            except (TypeError, AttributeError):
                item_citation = ''
            try:
                item_title = '"' + item_citation.find('span',
                                          {'class': 'articleTitle recTitle'}).text + '"'
            except (TypeError, AttributeError):
                try:
                    item_title = '*' + item_citation.find('span',
                                          {'class': 'articleTitle pub_name recTitle'}).text + '*'
                except (TypeError, AttributeError):
                    item_title = ''
            try:
                human_name = HumanName(item_citation.find('span', {'class':
                                                                   'name'}).text)
                item_name = str(human_name)
            except (TypeError, AttributeError):
                item_name = ''
            try:
                item_pubYear = item_citation.find('span', {'class': 'pubYear'}).text
            except (TypeError, AttributeError):
                item_pubYear = ''
            try:
                # # NEW VERSION: try using pandoc to convert from html to markdown
                # tempText = ''.join([str(tag) for tag in
                #                        item.find('span',
                #                                  {'class': 'pubInfo'})])
                # item_pubInfo = pandocConvert(tempText, 'markdown')

                # OLD VERSION: just use html text, with some simple mods
                item_pubInfo = ''.join([str(tag) for tag in
                                       item.find('span',
                                                 {'class': 'pubInfo'})]) \
                    .replace('<i class="pubName">', '*') \
                    .replace('<em class="pubName">', '*') \
                    .replace('<em>', '*') \
                    .replace('</em>', '*')
                # Adjust links: `<i><a href="URL">Title of Book</a></i>`
                #     ==> `*Title of Book* (<URL>)`
                item_pubInfo = re.sub(r'<i><a href="([^"]*)">(.+?)</a></i>',
                                      '*\\2* (<\\1>)', item_pubInfo)
                item_pubInfo = re.sub(r'<a href="([^"]*)">(.+?)</a>',
                                      '\\2 (<\\1>)', item_pubInfo)
                # Change `<i>...</i>` to `*...*`
                item_pubInfo = item_pubInfo.replace('<i>', '*') \
                        .replace('</i>', '*')
            except (TypeError, AttributeError):
                item_pubInfo = ''
            try:
                item_abstract = item.find('div', {'class': 'abstract'}).text
                item_abstract = item_abstract.replace(' (...)', '') \
                                             .replace('- ', '') \
                                             .replace(' (shrink)', '')
                # Substitution below to prevent spurious italics/boldface in
                # markdown.
                item_abstract = item_abstract.replace('_', '')
                item_abstract = item_abstract.strip()  # Strip off extra spaces
                # item_abstract = pandocConvert(item_abstract, 'latex')
                item_abstract = '    ABSTRACT: ' + item_abstract + '\n'
            except (TypeError, AttributeError):
                item_abstract = ''
            try:
                item_reference = item.find('div', {'class': 'options'}) \
                        .find('a', {'class': 'outLink', 'rel': 'nofollow'})['href']
                # Strip off initial philpapers.org href; use ":" and "/"
                item_reference = \
                    item_reference[item_reference.find('http', 5):] \
                    .replace('%3A', ':').replace('%2F', '/')
                if 'doi.org' in item_reference:
                    item_reference = sub('https?://(dx.)?doi.org/', '',
                                         item_reference, flags=IGNORECASE)
                    item_reference = '    DOI: ' + item_reference + '\n'
                elif item_reference == 'w':
                    item_reference = ''
                else:
                    item_reference = sub('%3f', '?', item_reference,
                                         flags=IGNORECASE)
                    item_reference = sub('%3d', '=', item_reference,
                                         flags=IGNORECASE)
                    item_reference = sub('%26', '&', item_reference,
                                         flags=IGNORECASE)
                    # philpapers.org's page for article
                    item_reference = '    URL: <' + item_reference + '>\n'
            except (TypeError, AttributeError):
                item_reference = ''
            # Now construct the reference the way I want it....
            text += str(counter) + '. ' + item_name + ' (' + item_pubYear
            text += '). ' + item_title + ' ' + item_pubInfo + '\n'
            text += item_abstract
            text += item_reference
            text += '    PP: <https://philpapers.org/rec/' + item_id + '>\n'
            text += '\n'
    return text


page = printList(list)

print(page)
