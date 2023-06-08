temp_html_dir <- tempfile()
md_dir <- "build/mkdocs/docs/docs"
dir <- "vendor/paws/cran"
pkg <- "paws.application.integration"

find_and_replace <- function(string, operator) {
  m <- regexpr(">[a-z0-9_]+<", string)
  found <- gsub(">|<", "", regmatches(string, m))
  gsub(
    found,
    sprintf('<a href="../%s_%s/"> %s </a>', operator, found, found),
    string
  )
}

# basic logger
log_info <- function(msg) {
  on.exit(flush.console())
  date_time <- strftime(Sys.time(), format = "%Y-%m-%d %H:%M:%S")
  log_msg <- sprintf("INFO %s: %s", date_time, msg)
  writeLines(log_msg)
}

build_long_rd <- function(long_doc = "vendor/paws/paws") {
  suppressMessages({
    roxygen2::update_collate(long_doc)
    roxygen2::roxygenize(long_doc, roclets = c("rd"))
  })
}

if (file.exists(md_dir)) fs::dir_delete(md_dir)
fs::dir_create(c(md_dir, temp_html_dir), recurse = TRUE)

log_info("Build Rd docs")

# create Rd docs
# build_long_rd()

log_info("Converting Rd to Markdown")

files <- basename(fs::dir_ls(file.path(dir, pkg, "man")))

# remove paws-package.Rd
files <- files[files != "paws-package.Rd"]

html_files <- fs::path(temp_html_dir, gsub("\\.Rd", "\\.html", files))
md_files <- fs::path(getwd(), md_dir, gsub("\\.Rd", "\\.md", files))
rd_files <- file.path("vendor/paws", "paws", "man", files)

col_width <- c(
  "<colgroup>",
  '<col style="width: 35%" />',
  '<col style="width: 65%" />',
  "</colgroup>"
)

# rd to markdown
for (i in seq_along(rd_files)) {
  tools::Rd2HTML(rd_files[[i]], html_files[[i]])
  rmarkdown::pandoc_convert(
    html_files[[i]],
    to = "markdown_strict",
    output = md_files[[i]]
  )

  # add url links
  if (!grepl("_", basename(md_files[[i]]))) {
    md <- readLines(md_files[[i]])
    idx <- grep('style=\"text-align: left;\">[a-z0-9_]+</td>', md)
    operator <- gsub("\\.md$", "", basename(md_files[[i]]))
    for (j in idx) {
      md[[j]] <- find_and_replace(md[[j]], operator)
    }

    # format table width
    idx <- grep('<col style="width: 50%" />', md)
    md[[idx[1]]] <- gsub("50", "15", md[[idx[1]]])
    md[[idx[2]]] <- gsub("50", "85", md[[idx[2]]])
    writeLines(md, md_files[[i]])
  } else {
    md <- readLines(md_files[[i]])

    # edit existing col groupings
    if (any(grepl("<colgroup>", md))) {
      idx <- grep('<col style="width: 50%" />', md)
      md[[idx[1]]] <- gsub("50", "35", md[[idx[1]]])
      md[[idx[2]]] <- gsub("50", "65", md[[idx[2]]])
    } else {
      # add col groupings
      idx <- grep("<table>", md)
      if (length(idx) > 0) {
        md <- c(md[1:idx], col_width, md[(idx + 1):length(md)])
      }
    }
    writeLines(md, md_files[[i]])
  }
}

fs::dir_delete(temp_html_dir)
