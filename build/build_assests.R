PACKAGE <- "paws.application.integration"

# basic logger
log_info <- function(msg) {
  on.exit(flush.console())
  date_time <- strftime(Sys.time(), format = "%Y-%m-%d %H:%M:%S")
  log_msg <- sprintf("INFO %s: %s", date_time, msg)
  writeLines(log_msg)
}

log_info("Build site assests")

# copy assests from vendor
fs::file_copy("vendor/paws/docs/logo.png", "build/mkdocs/docs", overwrite = TRUE)

# create site directory structure
dirs <- fs::path("build/mkdocs/docs", c("img"))
if (all(file.exists(dirs))) fs::dir_delete(dirs)

make_hierarchy <- function(dir = "vendor/paws/cran") {
  paws_desc <- fs::path(dir, "paws/DESCRIPTION")
  lines <- readLines(paws_desc)
  pkgs <- lines[grepl("paws\\.[a-z\\.]", lines, perl = T)]
  paws_pkg <- trimws(gsub("\\([^)]*\\).*", "", pkgs))

  hierarchy <- unlist(lapply(paws_pkg, \(pkg) {
    if (pkg == PACKAGE) {
      gsub("\\.Rd$", "\\.md", basename(fs::dir_ls(file.path(dir, pkg, "man"))))
    } else {
      sprintf(
        "https://dyfanjones.github.io/dev.%s/%s/",
        pkg,
        gsub("\\.Rd$", "", basename(fs::dir_ls(file.path(dir, pkg, "man"))))
      )
    }
  }))

  lvl <- gsub("_.*|\\.md$", "", basename(hierarchy))
  ref <- sub("[a-zA-Z0-9]+_", "", basename(hierarchy), perl = T)
  ref <- gsub("\\.md$", "", ref)
  ref[lvl == ref] <- "Client"

  idx <- grepl("\\.md$", hierarchy)
  hierarchy[idx] <- sprintf("%s: docs/%s", ref[idx], hierarchy[idx])
  hierarchy[!idx] <- sprintf("%s: %s", ref[!idx], hierarchy[!idx])
  hierarchy <- split(hierarchy, lvl)

  # order hierarchy
  for (j in seq_along(hierarchy)) {
    idx <- grep("Client", hierarchy[[j]])
    hierarchy[[j]] <- c(hierarchy[[j]][idx], sort(hierarchy[[j]][-idx]))
  }
  return(hierarchy)
}


# TODO: hyper link the other content
paws_make_hierarchy <- function(paws_dir = "vendor/paws/cran") {
  paws_desc <- fs::path(paws_dir, "/paws/DESCRIPTION")
  lines <- readLines(paws_desc)
  pkgs <- lines[grepl("paws\\.[a-z\\.]", lines, perl = T)]
  paws_pkg <- trimws(gsub("\\([^)]*\\).*", "", pkgs))

  hierarchy <- sapply(paws_pkg, \(x) gsub("\\.Rd$", "\\.md", basename(fs::dir_ls(file.path(paws_dir, x, "man")))), simplify = F)

  for (i in seq_along(hierarchy)) {
    lvl <- gsub("_.*|\\.md$", "", hierarchy[[i]])
    ref <- sub("[a-zA-Z0-9]+_", "", hierarchy[[i]], perl = T)
    ref <- gsub("\\.md$", "", ref)

    ref[lvl == ref] <- "Client"
    hierarchy[[i]] <- sprintf("%s: docs/%s", ref, hierarchy[[i]])
    hierarchy[[i]] <- split(hierarchy[[i]], lvl)

    # order hierarchy
    for (j in seq_along(hierarchy[[i]])) {
      idx <- grep("Client", hierarchy[[i]][[j]])
      hierarchy[[i]][[j]] <- c(hierarchy[[i]][[j]][idx], sort(hierarchy[[i]][[j]][-idx]))
    }
  }
  return(hierarchy)
}

get_version <- function(dir = "vendor/paws/cran/paws/DESCRIPTION") {
  desc <- readLines(dir)
  version <- desc[grepl("Version:*.[0-9]+\\.[0-9]+\\.[0-9]+", desc)]
  pattern <- "[0-9]+\\.[0-9]+\\.[0-9]+"
  m <- regexpr(pattern, version)
  regmatches(version, m)
}

build_site_yaml <- function() {
  site_yaml <- org_yaml <- yaml::yaml.load_file(
    "build/mkdocs.orig.yml"
  )

  for (i in c("extra_css", "plugins")) {
    if (!is.null(org_yaml[[i]]) && !is.list(length(org_yaml[[i]]))) {
      site_yaml[[i]] <- as.list(site_yaml[[i]])
    }
  }

  site_yaml$site_name <- sprintf("paws: %s", get_version())

  # add references
  ref_idx <- which(vapply(site_yaml$nav, \(x) names(x) == "Reference", FUN.VALUE = logical(1)))
  site_yaml$nav[[ref_idx]]$Reference <- make_hierarchy() # paws_make_hierarchy()

  site_yaml <- yaml::as.yaml(site_yaml, indent.mapping.sequence = T)
  site_yaml <- gsub("- '", "- ", site_yaml)

  # tidy up file paths
  for (ext in c("md", "pdf")) {
    site_yaml <- gsub(
      sprintf("\\.%s'", ext),
      sprintf("\\.%s", ext),
      site_yaml
    )
  }
  site_yaml <- gsub(
    "/'", "/", site_yaml
  )
  writeLines(site_yaml, "build/mkdocs/mkdocs.yml", "")
}

build_site_yaml()
