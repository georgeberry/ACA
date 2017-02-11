# ACA
Some code on ACA

Read [this paper](http://www.nejm.org/doi/full/10.1056/NEJMsa1202099), particularly the model in Table 2.

## Plan

Get the data to estimate mortality changes.

Table 2 gives mortality rates for different subgroups. We'll consider the poverty measure and race measure separately.

## Assumptions

1. Expanding Medicaid and providing insurance on exchanges has same effect.
1. All demographic factors not explicitly controlled for are assumed to be the same

## Data

### Population

Go [here](http://www.census.gov/data/datasets/2015/demo/popest/counties-detail.html) and download the United States county population data. ~112MB

### Uninsured rate data

Go [here](https://www.enrollamerica.org/research-maps/maps/changes-in-uninsured-rates-by-county/) and click on the download link at the bottom of the page.

## Tables

### Top 10 states

|State name    | Lives saved/100k (low)| Lives saved/100k (mid)| Lives saved/100k (upper)| 2016 red margin shift|
|:-------------|----------------------:|----------------------:|------------------------:|---------------------:|
|Kentucky      |                  13.20|                  29.66|                    76.67|                  0.07|
|West Virginia |                  12.96|                  29.11|                    75.26|                  0.15|
|New Mexico    |                  12.13|                  27.24|                    70.42|                  0.02|
|Arkansas      |                  11.76|                  26.41|                    68.27|                  0.03|
|California    |                  11.63|                  26.13|                    67.55|                 -0.07|
|Michigan      |                  11.48|                  25.79|                    66.68|                  0.10|
|Oregon        |                  11.45|                  25.73|                    66.51|                  0.01|
|Montana       |                  10.34|                  23.22|                    60.02|                  0.07|
|Ohio          |                  10.26|                  23.05|                    59.58|                  0.11|
|Nevada        |                  10.17|                  22.85|                    59.08|                  0.04|

###

# License

GPL3
