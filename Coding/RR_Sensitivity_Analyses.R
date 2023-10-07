# This R code file shows how to conduct sensitivity analysis for DID estimation, following Rambachan & Roth (2023).
# The following codes are updated based on "https://github.com/asheshrambachan/HonestDiD".
# Author: Ian Ho
# Date: Oct 6, 2023
# R Version: 4.3.1



# Packages ---------------------------------------------------------------------
library(dplyr)      # for data wrangling
library(haven)      # for reading Stata's dta file
library(ggplot2)    # for plotting
library(fixest)     # for fixed-effects estimation
library(HonestDiD)  # for Rambachan & Roth (2023) sensitivity analyses



# Non-Staggered Dynamic DID ----------------------------------------------------
df <- read_dta("../Data/medicaid_expansion.dta")

# We restrict the sample to the years 2015 and earlier, and drop states that first got treated in 2015.
# The remaining panel data only have some units getting treated in 2014 or not getting treated during the sample period.
df_nonstaggered <- df %>% filter(year < 2016 & (is.na(yexp2) | yexp2 != 2015))

# Generate treatment dummy: Di = 1{state i belongs to treated group in sample period}
df_nonstaggered <- df_nonstaggered %>% mutate(Di = case_when(yexp2 == 2014 ~ 1, T ~ 0))

# Run a TWFE regression
twfe <- fixest::feols(dins ~ i(year, Di, ref = 2013) | stfips + year,    # i() function creates a set of interact terms: a treatment dummy for each period, but excluding 2013 as a reference year.
                      cluster = "stfips",    # standard errors are clustered at state level
                      data = df_nonstaggered)

beta <- summary(twfe)$coefficients    #save estimated coefficients
sigma <- summary(twfe)$cov.scaled     #save the var-cov matrix

fixest::iplot(twfe,
              main = "Effect on Insurance Rate",
              xlab = "Year", ylab = "Coefficient Estimates",
              col = "dodgerblue3", ci.lwd = 1.5, pt.lwd = 2.5, ci.width = 0.1,    # style of point and interval estimates
              grid.par = list(vert = FALSE),    # disable the vertical grid lines
              ref.line.par = list(lty = 2, lwd = 1)    # customize the reference line
             )



# Relative Magnitude (RM) Restriction ------------------------------------------

# We will do a sensitivity analysis on the first estimated effect (i.e., the effect in 2014).

# Results under restrictions
delta_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
    betahat = beta,               # coefficient estimates
    sigma = sigma,                # var-cov matrix
    numPrePeriods = 5,            # number of pre-treatment coefficients
    numPostPeriods = 2,           # number of post-treatment coefficients
    Mbarvec = seq(0.5, 2, by=0.5) # values of M
  )

delta_rm    # The breakdown value for a significant effect is about 2.


# Results without restrictions
original <- HonestDiD::constructOriginalCS(betahat = beta,
                                           sigma = sigma,
                                           numPrePeriods = 5,
                                           numPostPeriods = 2)

svg(file='../Figures/Sensitivity_Analysis_RM.svg', width=7, height=5)
HonestDiD::createSensitivityPlot_relativeMagnitudes(delta_rm, original) +
  ggtitle(expression(paste("Sensitivity Analysis for ", tau[2014], " under ", Delta^{RM}))) +
  xlab("M") + 
  scale_y_continuous(limits = c(-0.02, 0.1)) +    # customize the range of y-axis
  guides(color = "none")    # disable the legend
dev.off()



# Smoothness Restriction -------------------------------------------------------
delta_sd <- HonestDiD::createSensitivityResults(
    betahat = beta,
    sigma = sigma,
    numPrePeriods = 5,
    numPostPeriods = 2,
    Mvec = seq(0, 0.05, by=0.01))

delta_sd    # The breakdown value for a significant effect is close to 0.03.

HonestDiD::createSensitivityPlot(delta_sd, original)



# Sensitivity Analysis for Average Effects -------------------------------------
delta_rm_avg <- HonestDiD::createSensitivityResults_relativeMagnitudes(
    betahat = beta,
    sigma = sigma,
    numPrePeriods = 5,
    numPostPeriods = 2,
    Mbarvec = seq(0, 2, by=0.5),
    l_vec = c(0.5, 0.5)    # average over the two post-treatment effects
  )

original_avg <- HonestDiD::constructOriginalCS(betahat = beta,
                                               sigma = sigma,
                                               numPrePeriods = 5,
                                               numPostPeriods = 2,
                                               l_vec = c(0.5, 0.5))

HonestDiD::createSensitivityPlot_relativeMagnitudes(delta_rm_avg, original_avg) +
  ggtitle(expression(paste("Sensitivity Analysis for ", bar(tau), " under ", Delta^{RM}))) +
  xlab("M") +
  scale_y_continuous(limits = c(-0.02, 0.12)) +
  guides(color = "none")



# Sensitivity Analysis for Effects in Other Periods ----------------------------
delta_rm_2nd <- HonestDiD::createSensitivityResults_relativeMagnitudes(
  betahat = beta,
  sigma = sigma,
  numPrePeriods = 5,
  numPostPeriods = 2,
  Mbarvec = seq(0, 2, by=0.5),
  l_vec = basisVector(2, 2)    # the first 2 in basisVector(,) indicates the second post-treatment effects; the second 2 in basisVector(,) indicates the number of post-treatment periods (= numPostPeriods)
)

delta_rm_2nd    # The breakdown value for a significant effect is about 2.