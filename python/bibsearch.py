# ============================================================================
# BIBSEARCH.PY
# ============================================================================
#
# This takes a search query, scrapes search results from http://philpapers.org,
# and formats and prints those results.

from requests import get
from bs4 import BeautifulSoup as bs
from sys import argv

query = '%20'.join(argv[1:])

pageUrl = 'https://philpapers.org/s/' + query
page = get(pageUrl)
soup = bs(page.text, 'html.parser')
list = soup.table.ol


def printList(list):
    counter = 0
    text = ''
    for item in list.contents:
        if item != '\n':  # Note: every other item is '\n'
            counter += 1
            item_id = item['id'][1:]
            item_citation = item.find('span', {'class': 'citation'})
            item_title = item_citation.find('span',
                                            {'class':
                                             'articleTitle recTitle'}).text
            item_name = item_citation.find('span', {'class': 'name'}).text
            item_pubYear = item_citation.find('span', {'class':
                                                       'pubYear'}).text
            item_pubInfo = ''.join([str(tag) for tag in item.find('span', {'class': 'pubInfo'})]).replace('<em class="pubName">', '*').replace('<em>', '*').replace('</em>', '*')
            try:
                item_abstract = item.find('div', {'class': 'abstract'}).text
                item_abstract = item_abstract.replace(' (...)', '').replace('- ', '').replace(' (shrink)', '')
                item_abstract = '\t**Abstract:** ' + item_abstract + '\n'
            except:
                item_abstract = ''
            try:
                item_reference = item.find('div', {'class': 'options'}).find('a', {'rel': 'nofollow'})['href']
                # Strip off initial philpapers.org href; use ":" and "/"
                item_reference = item_reference[item_reference.find('http', 5):].replace('%3A', ':').replace('%2F', '/')
                if 'jstor.org' in item_reference:
                    item_reference = '\t**J-Stor:** <' + item_reference + '>\n'
                elif 'doi.org' in item_reference:
                    item_reference = '\t**DOI:** ' + item_reference[18:] + '\n'
                elif item_reference == 'w':
                    item_reference = ''
                else:
                    item_reference = '\t**URL:** <' + item_reference + '>\n'
                    # Here is philpapers.org's BibTeX page; may want to scrape it....
                    item_bibtex = 'https://philpapers.org/export.html?__format=bib&eId=' + item_id + '&formatName=BibTeX'
                    item_reference += '\t**PP:** <' + item_bibtex + '>\n'
            except:
                item_reference = ''
            # Now construct the reference the way I want it....
            text += str(counter) + '. ' + item_name + ' (' + item_pubYear
            text += '). ' + item_title + ' ' + item_pubInfo + '\n'
            text += item_abstract
            text += item_reference
            text += '\n'
    return text


page = printList(list)

print(page)
