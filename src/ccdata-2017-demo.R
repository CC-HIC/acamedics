# Set up and config (not for demo)
# install.packages("/Users/steve/projects/ac-paper-brc/src/libs/localPkgs/ccfun", repos=NULL, type="source")
library(ccfun)
library(pander)
library(lubridate)
library(yaml)

# ===================
# Shared code library
# ===================
# Load the cleanEHR R library
# remove.packages('cleanEHR')
# devtools::install_github('cc-hic/cleanEHR')
library(cleanEHR)

# ============================
# Anonymised 'Playground' data
# ============================
data.path <- '/Users/steve/data/CCHIC/releases/2017-02-21t1512/anon_public_da1000.RData'
load(data.path)
ls()
cc <- anon_ccd # a shorter name to save typing

# What have we got?
cc@nepisodes # number of episodes
head(cc@infotb) # first few lines of data (anonymised)

# Demographic table
ccd <- ccd_demographic_table(cc, dtype=TRUE)
head(ccd)
names(ccd)
# Unit survival
table(ccd$DIS)

# Quick look at some example data
# CRAN version
# episode.graph(cc, 1, c("h_rate",  "bilirubin", "fluid_balance_d"))
# github version
plot(cc@episodes[[1]], c("h_rate",  "bilirubin", "fluid_balance_d"))


# Now let's do things in a bit more of an organised way
# Write your own configuration file
setwd('/Users/steve/code/CCHIC/demos/jupyter/')
fields = yaml.load_file('data_demo.yaml')

# cleanEHR places both 1D and 2D fields correctly into a table for you
# Back to the proper audit trail and validation approach
# Let's load the data with an hourly cadence
cct <- create_cctable(cc, conf=fields, freq=1)

# 2 tables : original and 'clean'
head(cct$torigin)

# Clean data
cct$filter_range("green")
cct$filter_categories()
cct$filter_nodata()
cct$filter_missingness()

# Report validation (checking if heart rate is in the allowed range)
cct$dfilter

# Specifically examine for missingness
# a per episode question: do we have enough data to make sense of the episode
cct$dfilter$missingness$episode

# Apply validation to original data
cct$apply_filters()

# Impute 2d data as per specification
# cct$imputation()

# Relabel columns and a quick tidy
dt_origin <- data.table::copy(cct$torigin)
dt_clean <- data.table::copy(cct$tclean)
head(dt_clean)
ccfun::relabel_cols(dt_origin, "NHICcode", "shortName", dict=fields)
ccfun::relabel_cols(dt_clean, "NHICcode", "shortName", dict=fields)

# Inspect our new clean table of data
head(dt_clean)

dt_demo <- rbind(
    cbind(dt_origin, data="origin"),
    cbind(dt_clean, data="clean")
    )

set.seed(42)
library(ggplot2)
ggplot(dt_demo[episode_id %in% sample(unique(dt_demo$episode_id),12)]
  , aes(x=time, y=hrate, color=data)) +
  geom_point(size=1) + facet_wrap(~episode_id, scales="free_x")
