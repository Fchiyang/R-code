---
  title: "Biostat 203B Homework 2"
subtitle: Due Feb 10 @ 11:59PM
author: YOUR Fu-chi Yang and 405727254
format:
  html:
  theme: cosmo
number-sections: true
toc: true
toc-depth: 4
toc-location: left
code-fold: false
knitr:
  opts_chunk: 
  cache: false    
echo: true
fig.align: 'center'
fig.width: 6
fig.height: 4
message: FALSE
---
  
  Display machine information for reproducibility:
  ```{r}
#| eval: false
sessionInfo()
```

Load necessary libraries (you can add more as needed).
```{r setup}

install.packages("data.table")
library(data.table)
install.packages("lubridate")
library(lubridate)
install.packages("R.utils")
library(R.utils)
install.packages("tidyverse")
library(tidyverse)
```

MIMIC data location
```{r}
mimic_path <- "/Users/fuchiyang/203b-hw/mimic-iv-1.0"
```
/Users/fuchiyang/203b-hw
In this exercise, we use tidyverse (ggplot2, dplyr, etc) to explore the [MIMIC-IV](https://mimic.mit.edu/docs/iv/) data introduced in [homework 1](https://ucla-biostat-203b.github.io/2023winter/hw/hw1/hw1.html) and to build a cohort of ICU stays.

Display the contents of MIMIC data folder. 
```{r}
system(str_c("ls -l ", mimic_path, "/"), intern = TRUE)
system(str_c("ls -l ", mimic_path, "/core"), intern = TRUE)
system(str_c("ls -l ", mimic_path, "/hosp"), intern = TRUE)
system(str_c("ls -l ", mimic_path, "/icu"), intern = TRUE)
```

## Q1. `read.csv` (base R) vs `read_csv` (tidyverse) vs `fread` (data.table)

There are quite a few utilities in R for reading plain text data files. Let us test the speed of reading a moderate sized compressed csv file, `admissions.csv.gz`, by three programs: `read.csv` in base R, `read_csv` in tidyverse, and `fread` in the popular data.table package. 

Which function is fastest? Is there difference in the (default) parsed data types? (Hint: R function `system.time` measures run times.)

For later questions, we stick to the `read_csv` in tidyverse.


system.time(tmp_t <- read_csv(str_c(mimic_path,"/core/admissions.csv.gz")))
system.time(tmp_f <- fread(str_c(mimic_path,"/core/admissions.csv.gz")))



## Q2. ICU stays

`icustays.csv.gz` (<https://mimic.mit.edu/docs/iv/modules/icu/icustays/>) contains data about Intensive Care Units (ICU) stays. The first 10 lines are
```{r}
system(
  str_c(
    "zcat < ", 
    str_c(mimic_path, "/icu/icustays.csv.gz"), 
    " | head"
  ), 
  intern = TRUE
)
```

1. Import `icustatys.csv.gz` as a tibble `icustays_tble`. 
##
icustays<- read_csv(str_c(mimic_path, "/icu/icustays.csv.gz"))
icustays_tble <- icustays %>%
  arrange(subject_id, hadm_id) 


2. How many unique `subject_id`? Can a `subject_id` have multiple ICU stays? 
  ##
  
  icustays_tble  
nrow(distinct(icustays_tble, subject_id))

##
Yes, because unique id only 53150, less than total number 76530

3. Summarize the number of ICU stays per `subject_id` by graphs. 
##

count_table <- icustays_tble %>% count(subject_id)
count_table


ggplot(data=count_table, aes(subject_id, n)) +    
  geom_bar(stat = "identity") 

+
  theme(axis.text.x = element_text(angle = 90, size = 10))


4. For each `subject_id`, let's only keep the first ICU stay in the tibble `icustays_tble`. (Hint: `slice_min` and `slice_max` may take long. Think alternative ways to achieve the same function.)'
##
icustays_tble <- icustays_tble %>%
  arrange(subject_id, intime) %>%
  distinct(subject_id, .keep_all = TRUE)%>%
  slice_head(n=1) %>%
  print(width = Inf)


## Q3. `admission` data

Information of the patients admitted into hospital is available in `admissions.csv.gz`. See <https://mimic.mit.edu/docs/iv/modules/hosp/admissions/> for details of each field in this file. The first 10 lines are
```{r}
system(
  str_c(
    "zcat < ", 
    str_c(mimic_path, "/core/admissions.csv.gz"), 
    " | head"
  ), 
  intern = TRUE
)
```

1. Import `admissions.csv.gz` as a tibble `admissions_tble`.
##
admissions <- read_csv(str_c(mimic_path,"/core/admissions.csv.gz"))
admissions_tble <- admissions 

2. Let's only keep the admissions that have a match in `icustays_tble` according to `subject_id` and `hadmi_id`.'


admissions_tble <- admissions_tble %>%
  arrange(subject_id, hadm_id) %>%
  semi_join(icustays_tble, by = c("subject_id", "hadm_id")) 

3. Summarize the following variables by graphics. 
#admission year
ggplot(data = admissions_tble) + 
  geom_bar(mapping = aes(x = year(admittime))) +
  labs(x = "Admission Year")

#admission month
ggplot(data = admissions_tble) + 
  stat_count(mapping = aes(x = lubridate::month(admittime, label = T))) +
  labs(x = "Admission Month")

#admission month per day
ggplot(data = admissions_tble) + 
  stat_count(mapping = aes(x = mday(admittime))) +
  labs(x = "Admission Month Day")

#admission week day
ggplot(data = admissions_tble) + 
  stat_count(mapping = aes(x = lubridate::wday(admittime, label = T))) +
  labs(x = "Admission Week Day")

#admission hour day
ggplot(data = admissions_tble) + 
  stat_count(mapping = aes(x = hour(admittime))) +
  labs(x = "Admission Hour Day")



## Q4. `patients` data

Patient information is available in `patients.csv.gz`. See <https://mimic.mit.edu/docs/iv/modules/hosp/patients/> for details of each field in this file. The first 10 lines are
```{r}
system(
  str_c(
    "zcat < ", 
    str_c(mimic_path, "/core/patients.csv.gz"), 
    " | head"
  ), 
  intern = TRUE
)
```

1. Import `patients.csv.gz` (<https://mimic.mit.edu/docs/iv/modules/hosp/patients/>) as a tibble `patients_tble` and only keep the patients who have a match in `icustays_tble` (according to `subject_id`).
patients <- read_csv(str_c(mimic_path,"/core/patients.csv.gz"))

patients_tble <- patients %>%
  arrange(subject_id) %>%
  semi_join(icustays_tble, by = c("subject_id")) %>%
  print(width = Inf)


2. Summarize variables `gender` and `anchor_age`, and explain any patterns you see.

ggplot(data = patients_tble) + 
  geom_bar(mapping = aes(x = anchor_age, fill = gender))+
  labs(title = "")+
  scale_fill_manual(values=c("#9933FF",
                                      "#33FFFF",
                                      "red",
                                      "darkblue"))
                                      min(patients_tble$anchor_age)
                                      
                                      ## 
                                      man have more people in most of the age 
                                      year 18 have least people
                                      
                                      
                                      
                                      ## Q5. Lab results
                                      
                                      `labevents.csv.gz` (<https://mimic.mit.edu/docs/iv/modules/hosp/labevents/>) contains all laboratory measurements for patients. The first 10 lines are
                                      ```{r}
                                      system(
                                        str_c(
                                          "zcat < ", 
                                          str_c(mimic_path, "/hosp/labevents.csv.gz"), 
                                          " | head"
                                        ), 
                                        intern = TRUE
                                      )
                                      ```
                                      `d_labitems.csv.gz` is the dictionary of lab measurements. 
                                      ```{r}
                                      system(
                                        str_c(
                                          "zcat < ", 
                                          str_c(mimic_path, "/hosp/d_labitems.csv.gz"), 
                                          " | head"
                                        ), 
                                        intern = TRUE
                                      )
                                      ```
                                      
                                      1. Find how many rows are in `labevents.csv.gz`.
                                      
                                      labevent <- read_csv(str_c(mimic_path,"/hosp/labevents.csv.gz"),
                                                           show_col_types = FALSE)
                                      nrow(labevent)
                                      
                                      
                                      2. We are interested in the lab measurements of creatinine (50912), potassium (50971), sodium (50983), chloride (50902), bicarbonate (50882), hematocrit (51221), white blood cell count (51301), and glucose (50931). Retrieve a subset of `labevents.csv.gz` only containing these items for the patients in `icustays_tble` as a tibble `labevents_tble`. 
                                      
                                      Hint: `labevents.csv.gz` is a data file too big to be read in by the `read_csv` function in its default setting. Utilize the `col_select` option in the `read_csv` function to reduce the memory burden. It took my computer 5-10 minutes to ingest this file. If your computer really has trouble importing `labevents.csv.gz`, you can import from the reduced data file `labevents_filtered_itemid.csv.gz`.
                                      
                                      labevents<- 
                                        read_csv(str_c(mimic_path,"/hosp/labevents_filtered_itemid.csv.gz"), 
                                                 col_types = cols_only(subject_id = col_double(), 
                                                                       itemid = col_double(), 
                                                                       charttime = col_datetime(), 
                                                                       valuenum = col_double()),
                                                 lazy = TRUE)
                                      
                                      d_labitems_tble <- read_csv(str_c(mimic_path,"/hosp/d_labitems.csv.gz"))
                                      
                                      choose_label <- c("50912", "50971", "50983", "50902", "50882", 
                                                        "51221", "51301", "50931", "50960", "50893")
                                      labevents_tble <- labevents
                                      labevents_tble <- labevents_tble %>%
                                        arrange(subject_id, itemid) %>%
                                        semi_join(icustays_tble, by = c("subject_id")) %>%
                                        left_join(select(d_labitems_tble, itemid, label), by = c("itemid")) %>%
                                        print(width = Inf)
                                      
                                      
                                      3. Further restrict `labevents_tble` to the first lab measurement during the ICU stay. 
                                      
                                      labevents_tble <- labevents_tble %>%
                                        left_join(select(icustays_tble, subject_id, intime, outtime), 
                                                  by = c("subject_id")) 
                                      
                                      
                                      
                                      
                                      labevents_tble <- labevents_tble %>%
                                        filter(charttime >= intime, charttime <= outtime) %>%
                                        group_by(subject_id, itemid) %>%
                                        arrange(charttime, .by_group = TRUE) %>%
                                        slice_head(n = 1) %>%
                                        ungroup() %>%
                                        select(-c(itemid, charttime, intime, outtime)) %>%
                                        pivot_wider(names_from = label, values_from = valuenum) %>%
                                        rename(Calcium = "Calcium, Total", WBC = "White Blood Cells") %>%
                                        print(width = Inf) %>%
                                        write_rds("labevents_tble.rds")
                                      
                                      labevents_tble
                                      
                                      
                                      
                                      
                                      4. Summarize the lab measurements by appropriate numerics and graphics. 
                                      
                                      
                                      summary(labevents_tble[-1])
                                      
                                      
                                      ##only keep. items during the first ICU stayＩ
                                      
                                      
                                      
                                      
                                      
                                      
                                      
                                      
                                      
                                      ## Q6. Vitals from charted events
                                      
                                      `chartevents.csv.gz` (<https://mimic.mit.edu/docs/iv/modules/icu/chartevents/>) contains all the charted data available for a patient. During their ICU stay, the primary repository of a patient’s information is their electronic chart. The `itemid` variable indicates a single measurement type in the database. The `value` variable is the value measured for `itemid`. The first 10 lines of `chartevents.csv.gz` are
                                      ```{r}
                                      system(
                                        str_c(
                                          "zcat < ", 
                                          str_c(mimic_path, "/icu/chartevents.csv.gz"), 
                                          " | head"), 
                                        intern = TRUE
                                      )
                                      ```
                                      `d_items.csv.gz` (<https://mimic.mit.edu/docs/iv/modules/icu/d_items/>) is the dictionary for the `itemid` in `chartevents.csv.gz`. 
                                      ```{r}
                                      system(
                                        str_c(
                                          "zcat < ", 
                                          str_c(mimic_path, "/icu/d_items.csv.gz"), 
                                          " | head"), 
                                        intern = TRUE
                                      )
                                      ```
                                      
                                      1. We are interested in the vitals for ICU patients: heart rate (220045), mean non-invasive blood pressure (220181), systolic non-invasive blood pressure (220179), body temperature in Fahrenheit (223761), and respiratory rate (220210). Retrieve a subset of `chartevents.csv.gz` only containing these items for the patients in `icustays_tble` as a tibble `chartevents_tble`.
                                      
                                      Hint: `chartevents.csv.gz` is a data file too big to be read in by the `read_csv` function in its default setting. Utilize the `col_select` option in the `read_csv` function to reduce the memory burden. It took my computer >15 minutes to ingest this file. If your computer really has trouble importing `chartevents.csv.gz`, you can import from the reduced data file `chartevents_filtered_itemid.csv.gz`.
                                      
                                      
                                      
                                      chartevents <-
                                        read_csv(str_c(mimic_path,"/icu/chartevents_filtered_itemid.csv.gz"),
                                                 col_types = cols_only(subject_id = col_double(),
                                                                       hadm_id = col_double(),
                                                                       itemid = col_double(),
                                                                       itemid = col_double(), 
                                                                       charttime = col_datetime(), 
                                                                       valuenum = col_double()),
                                                 lazy = TRUE)
                                      d_items_tble <- read_csv(str_c(mimic_path,"/icu/d_items.csv.gz"))
                                      
                                      choice_sel <- c("220045", "220181", "220179", "223761", "220210")
                                      chartevents_tble <- chartevents
                                      chartevents_tble <- chartevents_tble %>%
                                        semi_join(icustays_tble, by = c("subject_id")) %>%
                                        left_join(select(d_items_tble, itemid, label), by = c("itemid")) %>%
                                        print(width = Inf)
                                      
                                      
                                      chartevents_tble
                                      
                                      2. Further restrict `chartevents_tble` to the first vital measurement during the ICU stay. 
                                      
                                      
                                      chartevents_tble <- chartevents_tble %>%
                                        left_join(select(icustays_tble, subject_id, intime, outtime), 
                                                  by = c("subject_id")) 
                                      
                                      chartevents_tble   
                                      chartevents_tble<- chartevents_tble %>%
                                        filter(charttime >= intime, charttime <= outtime) %>%
                                        group_by(subject_id, itemid) %>%
                                        arrange(charttime, .by_group = TRUE) %>%
                                        slice_head(n = 1) %>%
                                        ungroup() %>%
                                        select(c(subject_id, label, valuenum)) %>%
                                        pivot_wider(names_from = label, values_from = valuenum) %>%
                                        rename(HR = "Heart Rate", RR = "Respiratory Rate", 
                                               Mean_BP = "Non Invasive Blood Pressure Systolic",
                                               Systolic_BP = "Non Invasive Blood Pressure Mean",
                                               BT = "Temperature Fahrenheit") %>%
                                        print(width = Inf) %>%
                                        write_rds("chartevents_tble.rds")
                                      
                                      
                                      3. Summarize these vital measurements by appropriate numerics and graphics. 
                                      
                                      summary(chartevents_tble[-1])
                                      
                                      ## Q7. Putting things together
                                      
                                      Let us create a tibble `mimic_icu_cohort` for all ICU stays, where rows are the first ICU stay of each unique adult (age at admission > 18) and columns contain at least following variables  
                                      
                                      - all variables in `icustays.csv.gz`  
                                      - all variables in `admission.csv.gz`  
                                      - all variables in `patients.csv.gz`  
                                      - first lab measurements during ICU stay  
                                      - first vital measurements during ICU stay
                                      - an indicator variable `thirty_day_mort` whether the patient died within 30 days of hospital admission (30 day mortality)
                                      
                                      
                                      
                                      # file.remove("mimic_icu_cohort.rds")
                                      
                                      mimic_icu_cohort <- icustays_tble %>%
                                        left_join(admissions_tble, by = c("subject_id", "hadm_id")) %>%
                                        left_join(patients_tble, by = c("subject_id")) %>%
                                        left_join(labevents_tble, by = c("subject_id")) %>%
                                        left_join(chartevents_tble, by = c("subject_id")) %>%
                                        mutate(age_hadm = anchor_age + year(admittime) - anchor_year) %>%
                                        filter(age_hadm > 18) %>%
                                        mutate(thirty_day_mort = 
                                                 ifelse(is.na(deathtime), "FALSE", 
                                                        ifelse(as.Date(deathtime) - as.Date(admittime) <= 30, 
                                                               "TRUE", "FALSE"))) %>%
                                        print(width = Inf) %>%
                                        write_rds("mimic_icu_cohort.rds")
                                      
                                      
                                      table(mimic_icu_cohort$thirty_day_mort)
                                      
                                      
                                      ## Q8. Exploratory data analysis (EDA)
                                      
                                      Summarize following information using appropriate numerics or graphs.
                                      
                                      ##
                                      - `thirty_day_mort` vs demographic variables (ethnicity, language, insurance, marital_status, gender, age at hospital admission)
                                      
                                      q1 <- mimic_icu_cohort %>%
                                        ggplot() +
                                        geom_bar(mapping = aes(x = thirty_day_mort, fill = language), 
                                                 position = "fill") +
                                        scale_y_continuous(labels = scales::percent) +
                                        labs(x = "Mortality", y = "%") 
                                      
                                      q2 <- mimic_icu_cohort %>%
                                        ggplot() +
                                        geom_bar(mapping = aes(x = thirty_day_mort, fill = insurance), 
                                                 position = "fill") +
                                        scale_y_continuous(labels = scales::percent) +
                                        labs(x = "Mortality", y = "%") 
                                      
                                      q3 <- subset(mimic_icu_cohort, !is.na(marital_status)) %>%
                                        ggplot() +
                                        geom_bar(mapping = aes(x = thirty_day_mort, fill = marital_status), 
                                                 position = "fill") +
                                        scale_y_continuous(labels = scales::percent) +
                                        labs(x = "Mortality", y = "%") 
                                      
                                      q4 <- mimic_icu_cohort %>%
                                        ggplot() +
                                        geom_bar(mapping = aes(x = thirty_day_mort, fill = gender), 
                                                 position = "fill") +
                                        scale_y_continuous(labels = scales::percent) +
                                        labs(x = "Mortality", y = "%") 
                                      
                                      
                                      gridExtra::grid.arrange(q1,q2,q3,q4, nrow = 2)
                                      
                                      
                                      
                                      - `thirty_day_mort` vs first lab measurements
                                      
                                      mimic_icu_cohort %>%
                                        gather(27:36, key = "key", value = "value") %>%
                                        group_by(key) %>%
                                        filter(value > quantile(value, 0.025, na.rm = TRUE) 
                                               & value < quantile(value, 0.975, na.rm = TRUE)) %>%
                                        ungroup %>%
                                        ggplot(mapping = aes(x = thirty_day_mort, y = value)) +
                                        geom_boxplot() +
                                        labs(x = "Mortality") +
                                        facet_wrap(~key, scales = "free_y")
                                      
                                      
                                      
                                      
                                      
                                      
                                      
                                      
                                      
                                      - `thirty_day_mort` vs first vital measurements
                                      mimic_icu_cohort %>%
                                        gather(37:41, key = "key", value = "value") %>%
                                        group_by(key) %>%
                                        filter(value > quantile(value, 0.025, na.rm = TRUE) 
                                               & value < quantile(value, 0.975, na.rm = TRUE)) %>%
                                        ungroup %>%
                                        ggplot(mapping = aes(x = thirty_day_mort, y = value)) +
                                        geom_boxplot() +
                                        labs(x = "Mortality") +
                                        facet_wrap(~key, scales = "free_y") 
                                      
                                      
                                      
                                      
                                      - `thirty_day_mort` vs first ICU unit
                                      mimic_icu_cohort %>%
                                        ggplot() +
                                        geom_bar(mapping = aes(x = thirty_day_mort, fill = first_careunit), 
                                                 position = "fill") +
                                        labs(y = "%") +
                                        scale_y_continuous(labels = scales::percent) +
                                        labs(x = "Mortality", fill ="First ICU Unit")