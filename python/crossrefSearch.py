#! /usr/bin/env python3
from habanero import Crossref
from sys import argv


def authorTitle2doi(author="", title=""):
    title = title.lower()
    author = author.lower()
    clean_title = ''.join(e for e in title if e.isalnum())
    cr = Crossref()
    res = cr.works(query_title=title, query_author=author, select="title,DOI", limit=5)
    for r in res['message']['items']:
        fetched_title = r['title'][0].lower()
        clean_fetched = ''.join(e for e in fetched_title if e.isalnum())
        if clean_fetched == clean_title:
            return r['DOI']


if __name__ == "__main__":
    author = argv[1]
    title = argv[2]
    print(authorTitle2doi(author, title))
