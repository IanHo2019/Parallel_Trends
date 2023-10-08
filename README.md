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


## Traditional Assessments of Parallel Trends
The parallel trends (PT) assumption is testable if we observe more than two periods.

### Graphic Evidence
The most popular way of assessing the PT assumption *was* visualizing the averages of observed outcomes. That is, researchers plot the average outcomes by group and across time periods, and then check whether the lines look approximately parallel. In math words, this method is equivalent to using human's naked eyes (or eyes with glasses) to test

$$\frac{1}{N_1} \sum_{i \in G_1} (Y_{it} – Y_{it'}) = \frac{1}{N_0} \sum_{i \in G_0} (Y_{it} – Y_{it'}) \quad \forall t, t' < t^* \text{ and } t \neq t'$$

where $N_1$ and $N_0$ are number of observations in treated and control groups ($G_1$ and $G_0$) respectively, $Y_{it}$ is an observed outcome, and $t^*$ indicates the treatment time. An example is shown below (Stata coding is [here](https://github.com/IanHo2019/Parallel_Trends/blob/main/Coding/PTA_graph.do)).

<div align="center">
  <img src="./Figures/PTA_graph_evidence.svg" title="Graphic Evidence for Parallel Trends Assumption" alt="Graphic Evidence for Parallel Trends Assumption" style="width:75%"/>
</div>

### Event-Study Evidence
The visualization method is tiresome in staggered DID setting. In such cases, researchers had ever turned to a simple event-study specification (usually with a plot reporting results). The specification has the following form:
$$Y_{i,t} = \alpha_i + \phi_t + \sum_{s=0}^{S} D_{i,t-s} \beta_s + \sum_{s=1}^S D_{i,t+s} \gamma_s + e_{i,t}$$
where $D_{i,t}$ is a dummy equaling 1 if unit $i$ is (or has been) treated in period $t$ and equaling 0 otherwise. If the estimate of $\gamma_s$ (the pre-treatment parameter) is insignificant for all $s \in \\{1, 2, 3,…, S\\}$, researchers conclude that the parallel trends assumption is satisfied. A Stata coding example is [here](https://github.com/IanHo2019/Parallel_Trends/blob/main/Coding/PTA_event_study.do).

### Flaws of Traditional Methods
Unfortunately, neither method provides a good assessment of the PT assumption. The key reason is that they focus on the pre-treatment trends, but our interest is the trends over all time periods (including pre- and post-treatment periods). An interesting instance against the traditional PT test is given by [Roth et al. (2023)](https://doi.org/10.1016/j.jeconom.2023.03.008):

> [T]he average height of boys and girls evolves in parallel until about age 13 and then diverges, but we should not conclude from this that there is a causal effect of [bar mitzvahs](https://en.wikipedia.org/wiki/Bar_and_bat_mitzvah) (which occur for boys at age 13) on children's height!

Other reasons include:
 * The assessment based on the visualization of average outcomes depend on users' sense of sight. Plotting on empirical data often shows two lines that look imperfectly parallel. Then, how to assess?
 * The assessment based on an event-study regression in staggered setting is potentially biased because each coefficient estimate is contaminated by the cohort-specific ATT in other periods. See [Sun & Abraham (2021)](https://doi.org/10.1016/j.jeconom.2020.09.006) for details.

Therefore, we hunger for some more robust methods of assessing the PT assumption. More importantly, if the PT assumption really doesn't hold, we also hunger for some ways to relax it.

## Relaxing PT: Bounding Post-Treatment Differences in Trends
