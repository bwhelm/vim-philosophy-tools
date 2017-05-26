# vim-philosophy-tools

This vim plugin exposes several commands:

- `Doi2Bib`: downloads BibTeX citation info when given a DOI as input. Data are
  downloaded from `http://api.crossref.org/works/`.

- `PPSearch`: searches <http://philpapers.org> for the given query, and returns
  a structured list of items. Hitting `<CR>` on an item in this list will
  attempt to download BibTeX citation info from an available DOI (using
  `crossref.org`) or from J-Stor. Note that this is highly dependent on the
  webpage returned from `philpapers.org`.

- `SEPtoMarkdown`: retrieves an article from the Stanford Encyclopedia of
  Philosophy (<https://plato.stanford.edu/>) and does its best to convert to
  markdown using `pandoc` (<https://pandoc.org>). Must enter `SEPtoMarkdown`
  followed by the article portion of the URL. Thus, `SEPtoMarkdown plato`
  will retrieve the article at `https://plato.stanford.edu/entries/plato/`.
  Note that conversion to markdown is not perfect, and this will choke on
  document elements like tables.
