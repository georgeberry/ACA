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

|State Name    | Lives saved / 100k (lower) | Lives saved / 100k (mid) | Lives saved / 100k (upper) | Rep margin change |
|:-------------|-----------------------:|---------------------:|-----------------------:|-----------------:|
|Kentucky      |                13.20411|              29.65845|                76.67384|         0.0714564|
|West Virginia |                12.96018|              29.11055|                75.25739|         0.1492815|
|New Mexico    |                12.12728|              27.23974|                70.42092|         0.0193631|
|Arkansas      |                11.75611|              26.40602|                68.26557|         0.0323303|
|California    |                11.63223|              26.12777|                67.54623|        -0.0687168|
|Michigan      |                11.48318|              25.79298|                66.68073|         0.0971912|
|Oregon        |                11.45434|              25.72821|                66.51328|         0.0111164|
|Montana       |                10.33668|              23.21778|                60.02323|         0.0657907|
|Ohio          |                10.26007|              23.04570|                59.57837|         0.1105010|
|Nevada        |                10.17475|              22.85406|                59.08294|         0.0426381|



# License

GPL3
