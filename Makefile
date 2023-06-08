# Make R use the user's package library by setting the R user home path (R_USER)
# to the folder containing their package library. On Windows, it is in
# ~/Documents/R, whereas in Linux/macOS it is in ~/R.
ifdef OS
	R_USER := ${HOME}
else
	R_USER := ${HOME}
endif
export R_USER

.PHONY: all

update-deps:
	@echo "update paws dependency"
	@git submodule init
	@git submodule update --remote

clean-down:
	@echo "INFO $$(date +%F) $$(date +%T): Clearing down site"
	@rm -rf articles assets docs examples img search

build-docs: clean-down
	@Rscript build/rd2md.R
	@Rscript build/build_assests.R

build-site: build-docs
	@echo "INFO $$(date +%F) $$(date +%T): Building site"
	@cd build/mkdocs && python -m mkdocs build

regen-site: build-site
	@echo "INFO $$(date +%F) $$(date +%T): Moving site to root"
	@mv build/mkdocs/site/* .
	@rm -rf build/mkdocs/docs

requirements: 
	@Rscript -e "install.packages(c('rmarkdown', 'fs', 'yaml', 'roxygen2', 'remotes'), repos='https://cran.rstudio.com/')"
	@python -m pip install --upgrade pip
	@pip install --upgrade mkdocs-material awscli
