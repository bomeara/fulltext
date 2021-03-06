# ft_links plugins --------------------------------------
plugin_links_entrez <- function(sources, ids, opts, ...){
  if (any(grepl("entrez", sources))) {
    allids <- paste(paste0(ids, "[doi]"), collapse = " OR ")
    tmp <- rentrez::entrez_search(db = "pubmed", term = allids)
    if (length(tmp$ids) == length(ids)) {
      message("Only ", length(tmp$ids), " found for Entrez, proceeding...")
    }
    res <- rentrez::entrez_link(dbfrom = "pubmed", db = "", cmd = "llinks", id = tmp$ids)
    out <- lapply(res$linkouts, function(z) {
      rbind_fill(lapply(z, function(w) {
        w <- unclass(w)
        df <- data.frame(w, stringsAsFactors = FALSE)
        stats::setNames(df, tolower(names(df)))
      }))
    })
    list(found = length(ft_compact(out)), ids = names(out), data = out, opts = opts)
  } else {
    emptylist(opts)
  }
}

plugin_links_plos <- function(sources, ids, opts, ...){
  if (any(grepl("plos", sources))) {
    ids <- grep("annotation", ids, value = TRUE, invert = TRUE)
    tmp <- as.list(stats::setNames(rplos::full_text_urls(ids), ids))
    tmp <- lapply(tmp, function(z) list(xml = z, pdf = sub("manuscript", "printable", z)))
    list(found = length(tmp), ids = names(tmp), data = tmp, opts = opts)
  } else {
    emptylist(opts)
  }
}

plugin_links_crossref <- function(sources, ids, opts, ...){
  if (any(grepl("crossref", sources))) {
    safe_crm_links <- function(x, type = "xml", ...) {
      tryCatch(crminer::crm_links(x, type, ...), error = function(e) NULL)
    }
    tmp <- ft_compact(lapply(ids, safe_crm_links, type = "all"))
    out <- lapply(tmp, function(z) {
      rbind_fill(lapply(z, function(w) {
        data.frame(url = w[[1]], doi = attr(w, "doi"), type = attr(w, "type"),
                   member = attr(w, "member") %||% "", 
                   intended_application = attr(w, "intended_application") %||% "",
                   stringsAsFactors = FALSE)
      }))
    })
    out <- ft_compact(out)
    out <- stats::setNames(out, sapply(out, function(x) x$doi[1]))
    list(found = length(ft_compact(out)), ids = names(out), 
         data = out, opts = opts)
  } else {
    emptylist(opts)
  }
}

plugin_links_bmc <- function(sources, ids, opts, ...){
  if (any(grepl("bmc", sources))) {
    tmp <- stats::setNames(bmc_link(ids), ids)
    # remove empty slots
    tmp <- Filter(function(z) !all(vapply(z, class, "") == "NULL"), tmp)
    list(found = length(tmp), ids = names(tmp), data = tmp, opts = opts)
  } else {
    emptylist(opts)
  }
}

bmc_link <- function(dois) {
  xmlbase <- "http://%s/content/download/xml/%s.xml"
  pdfbase <- "http://%s/content/pdf/%s.pdf"
  lapply(dois, function(x) {
    res2 <- crul::HttpClient$new(paste0("https://doi.org/", x))$head()
    if (!res2$success()) return(list(xml = NULL, pdf = NULL))
    url <- crul::url_parse(res2$response_headers_all[[1]]$location)$domain
    x <- strsplit(x, "/")[[1]][2]
    list(xml = sprintf(xmlbase, url, x), pdf = sprintf(pdfbase, url, x))
  })
}

# plugin_links_arxiv <- function(sources, ids, opts, ...){
#   emptylist(opts)
# }

# plugin_links_biorxiv <- function(sources, ids, opts, ...){
#   emptylist(opts)
# }

plugin_links_elife <- function(sources, ids, opts, ...){
  if (any(grepl("elife", sources))) {
    tmp <- stats::setNames(elife_link(ids), ids)
    list(found = length(tmp), ids = names(tmp), data = tmp, opts = opts)
  } else {
    emptylist(opts)
  }
}

elife_link <- function(dois) {
  xmlbase <- "http://elifesciences.org/content/3/e%s.source.xml"
  pdfbase <- "http://elifesciences.org/content/elife/3/e%s.full.pdf"
  lapply(dois, function(x) {
    x <- strsplit(x, "eLife\\.")[[1]][2]
    list(xml = sprintf(xmlbase, x), pdf = sprintf(pdfbase, x))
  })
}

plugin_links_peerj <- function(sources, ids, opts, ...){
  if (any(grepl("peerj", sources))) {
    tmp <- peerj_link(ids)
    list(found = length(tmp), ids = names(tmp), data = tmp, opts = opts)
  } else {
    emptylist(opts)
  }
}

peerj_link <- function(dois) {
  xmlbase <- "https://peerj.com/articles/%s.xml"
  pdfbase <- "https://peerj.com/articles/%s.pdf"
  stats::setNames(lapply(dois, function(x) {
    x <- strsplit(x, "peerj\\.")[[1]][2]
    list(xml = sprintf(xmlbase, x), pdf = sprintf(pdfbase, x))
  }), dois)
}

plugin_links_frontiersin <- function(sources, ids, opts, ...){
  if (any(grepl("frontiersin", sources))) {
    tmp <- frontiersin_link(ids)
    list(found = length(tmp), ids = names(tmp), data = tmp, opts = opts)
  } else {
    emptylist(opts)
  }
}

frontiersin_link <- function(dois) {
  xmlbase <- "http://journal.frontiersin.org/article/%s/xml/nlm"
  pdfbase <- "http://journal.frontiersin.org/article/%s/pdf"
  stats::setNames(lapply(dois, function(x) {
    list(xml = sprintf(xmlbase, x), pdf = sprintf(pdfbase, x))
  }), dois)
}

plugin_links_copernicus <- function(sources, ids, opts, ...){
  if (any(grepl("copernicus", sources))) {
    tmp <- copernicus_link(ids)
    list(found = length(tmp), ids = names(tmp), data = tmp, opts = opts)
  } else {
    emptylist(opts)
  }
}

copernicus_link <- function(dois) {
  xmlbase <- "http://www.ann-geophys.net/%s/%s/%s/%s.xml"
  pdfbase <- "http://www.ann-geophys.net/%s/%s/%s/%s.pdf"
  stats::setNames(lapply(dois, function(x) {
    x <- strsplit(x, "/")[[1]][2]
    pcs <- strsplit(x, "-")[[1]]
    list(xml = sprintf(xmlbase, pcs[2], pcs[3], pcs[4], x), 
         pdf = sprintf(pdfbase, pcs[2], pcs[3], pcs[4], x))
  }), dois)
}

plugin_links_cogent <- function(sources, ids, opts, ...){
  if (any(grepl("cogent", sources))) {
    tmp <- cogent_link(ids)
    list(found = length(tmp), ids = names(tmp), data = tmp, opts = opts)
  } else {
    emptylist(opts)
  }
}

cogent_link <- function(dois) {
  xmlbase <- "http://cogentoa.tandfonline.com/doi/xml/"
  pdfbase <- "http://cogentoa.tandfonline.com/doi/pdf/"
  stats::setNames(lapply(dois, function(x) {
    list(xml = paste0(xmlbase, x), pdf = paste0(pdfbase, x))
  }), dois)
}

# empty list helper
emptylist <- function(opts = list()) {
  list(found = NULL, ids = NULL,  data = NULL, opts = opts)
}
