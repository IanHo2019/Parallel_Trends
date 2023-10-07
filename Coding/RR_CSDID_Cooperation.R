# This R code file shows how to conduct sensitivity analysis for heterogeneity-robust DID models, following Rambachan & Roth (2023).
# The following codes are updated based on "https://github.com/asheshrambachan/HonestDiD".
# Author: Ian Ho
# Date: Oct 6, 2023
# R Version: 4.3.1



# Packages ---------------------------------------------------------------------
library(dplyr)      # for data wrangling
library(haven)      # for reading dta file
library(ggplot2)    # for plotting
library(fixest)     # for fixed-effects estimation
library(did)        # for advanced DID specifications
library(HonestDiD)  # for Rambachan & Roth (2023) sensitivity analyses



# Define a New Function --------------------------------------------------------
#' @title honest_did
#' @description a function to compute a sensitivity analysis using the approach of Rambachan and Roth (2023)
honest_did <- function(...) UseMethod("honest_did")

#' @title honest_did.AGGTEobj
#' @description a function to compute a sensitivity analysis using the approach of Rambachan and Roth (2023) when
#'  when the event study is estimating using the `did` package
#' @param e event time to compute the sensitivity analysis for.
#'  `e=0` corresponds to the immediate effect of participating in the treatment.
honest_did.AGGTEobj <- function(es,
                                e          = 0,
                                type       = c("smoothness", "relative_magnitude"),
                                gridPoints = 100,
                                ...) {
  type <- match.arg(type)
  
  # Make sure that user is passing in an event study
  if (es$type != "dynamic") {
    stop("Need to pass in an event study")
  }
  
  # Check if the universal base period was used
  if (es$DIDparams$base_period != "universal") {
    stop("Use a universal base period for honest_did")
  }
  
  # Recover influence function for event study estimates
  es_inf_func <- es$inf.function$dynamic.inf.func.e
  
  # Recover variance-covariance matrix
  n <- nrow(es_inf_func)
  V <- t(es_inf_func) %*% es_inf_func / n / n
  
  # Remove the coefficient normalized to zero
  referencePeriodIndex <- which(es$egt == -1)
  V    <- V[-referencePeriodIndex,-referencePeriodIndex]
  beta <- es$att.egt[-referencePeriodIndex]
  
  nperiods <- nrow(V)
  npre     <- sum(1*(es$egt < -1))
  npost    <- nperiods - npre
  baseVec1 <- basisVector(index=(e+1),size=npost)
  orig_ci  <- constructOriginalCS(betahat        = beta,
                                  sigma          = V,
                                  numPrePeriods  = npre,
                                  numPostPeriods = npost,
                                  l_vec          = baseVec1)
  
  if (type=="relative_magnitude") {
    robust_ci <- createSensitivityResults_relativeMagnitudes(betahat        = beta,
                                                             sigma          = V,
                                                             numPrePeriods  = npre,
                                                             numPostPeriods = npost,
                                                             l_vec          = baseVec1,
                                                             gridPoints     = gridPoints,
                                                             ...)
    
  } else if (type == "smoothness") {
    robust_ci <- createSensitivityResults(betahat        = beta,
                                          sigma          = V,
                                          numPrePeriods  = npre,
                                          numPostPeriods = npost,
                                          l_vec          = baseVec1,
                                          ...)
  }
  
  return(list(robust_ci=robust_ci, orig_ci=orig_ci, type=type))
}



# Staggered Dynamic DID --------------------------------------------------------
df <- read_dta("../Data/medicaid_expansion.dta")

df <- df %>% mutate(yexp2 = ifelse(is.na(yexp2), 9999, yexp2))    # replace the NAs with a large number for the regression later

# Run a CS DID regression
cs <- did::att_gt(yname = "dins",
                  tname = "year",
                  idname = "stfips",
                  gname = "yexp2",
                  clustervars = "stfips",
                  control_group = "notyettreated",
                  base_period = "universal",    # this argument normalizes the coefficient beta_{-1} to 0
                  data = df
                 )

# Get an aggregation across relative time
es <- did::aggte(cs,
                 type = "dynamic", 
                 min_e = -5, max_e = 5)

did::ggdid(es,
           title = "CS DID",
           xlab = "Relative Periods",
           ylab = "Aggregated ATTs")

# Conduct a sensitivity analysis for tau_0 (smoothness)
SD_results0 <- honest_did(es,
                          e = 0,
                          type = "smoothness",
                          Mvec = seq(0, 0.05, by=0.01))

HonestDiD::createSensitivityPlot(SD_results0$robust_ci,
                                 SD_results0$orig_ci)


# Conduct a sensitivity analysis for tau_1 (relative magnitudes)
RM_results <- honest_did(es,
                         e = 1,
                         type = "relative_magnitude",
                         Mbarvec = seq(0.5, 3, by=0.5))

HonestDiD::createSensitivityPlot_relativeMagnitudes(RM_results1$robust_ci,
                                                    RM_results1$orig_ci)