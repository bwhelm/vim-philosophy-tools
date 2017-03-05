# vim-bibsearch

This vim plugin exposes two commands:

- `Doi2Bib`: downloads BibTeX citation info when given a DOI as input. Data are
  downloaded from `http://api.crossref.org/works/`.

- `BibSearch`: searches `http://philpapers.org` for the given query, and
  returns a structured list of items. Hitting `<CR>` on an item in this list
  will attempt to download BibTeX citation info from an available DOI (using
  `crossref.org`) or from J-Stor.

Note that this is highly dependant on the webpage returned from
`philpapers.org`.
