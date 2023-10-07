# Parallel Trends
The standard difference-in-difference method returns an unbiased estimate under three key assumptions:
  * parallel trends (PT) assumption, also known as common trend (CT) assumption;
  * no anticipation (NA) assumption;
  * homogeneous treatment effect assumption.

Sadly, these assumptions do not hold strictly in many empirical settings. Due to these sad phenomena, nowadays a lot of econometricians are working on relaxing these assumptions. In this repository, my shooting target is the **parallel trends** assumption.

<p align="center">
  <strong><em>It is hard to find parallel trends in this non-parallel world.</em></strong>
</p>

Please see my another repository ([DID Handbook](https://github.com/IanHo2019/DID_Handbook)) if you are interested in heterogeneity-robust DID estimators (which relax the homogeneity assumption).


## What Is Parallel Trends?
In a two-period DID setting where some units get treated in the second period, the parallel trends can be formalized as
$$E[Y_{i2}(0) – Y_{i1}(0) | D_i = 1] = E[Y_{i2}(0) – Y_{i1}(0) | D_i = 0]$$
where $Y_{it}(0)$ denotes unit $i$'s **untreated** potential outcome in period $t$.

In a staggered DID setting (i.e., different units get treated in different periods), the parallel trends can be formalized as
$$E[Y_{it}(\infty) – Y_{it'}(\infty) | G_i = g] = E[Y_{it}(\infty) – Y_{it'}(\infty) | G_i = g'] \quad \forall t \neq t', g \neq g'$$
where $Y_{it}(\infty)$ denotes unit $i$'s **never-treated** potential outcome in period $t$, and $G_i$ denotes unit $i$'s group (units are grouped based on when they get first treated; those units getting treated in the same period belong to the same group).


## Traditional Assessments on Parallel Trends and Their Flaws
