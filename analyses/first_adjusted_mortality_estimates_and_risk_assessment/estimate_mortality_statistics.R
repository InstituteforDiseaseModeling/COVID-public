# estimate incubation period

library(tidyverse)
library(survival)
library(flexsurv)
library(survminer)
library(cowplot)
library(gridExtra)
library(matrixStats)

# linelist <- read.csv('./Data/Kudos to DXY.cn Last update_ 01_25_2020,  11_30 am (EST) - Line-list.csv', header=TRUE)
linelist <- read.csv('./Data/Kudos to DXY.cn Last update_ 01_27_2020,  9_00 pm (EST) - Line-list.csv', header=TRUE, stringsAsFactors = FALSE)
names(linelist)

linelist$reporting.date <- as.Date(linelist$reporting.date)
linelist$symptom_onset <- as.Date(linelist$symptom_onset)
linelist$hosp_visit_date <- as.Date(linelist$hosp_visit_date)
linelist$exposure_start <- as.Date(linelist$exposure_start)
linelist$exposure_end <- as.Date(linelist$exposure_end)
linelist$death_date <- as.Date(linelist$death_date)
linelist$recovered_date <- as.Date(linelist$recovered_date)
linelist$recovered_fever_date <- as.Date(linelist$recovered_fever_date)
linelist$severity[is.na(linelist$severity)]<-'unknown'

linelist <- linelist %>% mutate(age_bin=round(0.1*age)/0.1)

# linelist <- linelist %>% filter(!is.na(age))

sum(linelist$type_of_visit == 'hospital' & !is.na(linelist$type_of_visit))
sum(linelist$type_of_visit != 'hospital' & !is.na(linelist$type_of_visit))

sum(linelist$type_of_visit == 'hospital' & !is.na(linelist$type_of_visit) & linelist$death!=0 | linelist$recovered!=0)
sum(linelist$type_of_visit == 'hospital' & !is.na(linelist$type_of_visit) & linelist$death!=0)



# symptom onset to death

t1 <- as.numeric(linelist$death_date - linelist$symptom_onset)
t1[is.na(t1)]<-as.numeric(as.Date('2020-01-26')-linelist$symptom_onset[is.na(t1)])
t1<-pmax(t1,1)
outcome <- linelist$death
outcome[outcome==1]<-'death'
outcome[linelist$recovered==1]<-'recovered'
outcome[outcome=='0']<-'censored'

t1[linelist$recovered==1] <- as.numeric(linelist$recovered_date[linelist$recovered==1] - linelist$symptom_onset[linelist$recovered==1])
status<-as.numeric(outcome!='censored')
st <- data.frame(t1=t1,status=status,outcome=outcome)

st <- st
# st <- st %>% filter(outcome!='0')

st$outcome <- factor(st$outcome, levels=c('death','recovered','censored'))
surv_object <- Surv(time = st$t1,
                    event = st$status, 
                    type='right')

mod <- survfit(surv_object~1,data=st)
plot(mod)

deathDurationModel <- flexsurvreg(surv_object~1,data=st, dist='lognormal')

kmp2 <- ggsurvplot(mod,risk.table = TRUE, xlim=c(0,42), conf.int = TRUE) + guides(color=FALSE) 

p3<-kmp2$plot +  scale_x_continuous(limits=c(0,42), breaks=seq(0,40,by=4)) + 
  xlab('') + ylab('P(T>t)')
p4<- kmp2$table + scale_x_continuous(limits=c(0,42), breaks=seq(0,40,by=4)) + 
  xlab('days from symptom onset to outcome') + ylab('')

plot_grid(p3,p4,nrow = 2, rel_heights = c(0.75,0.22), align='v')

ggsave('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/symptom_onset_to_death_from_linelist.png',width=6, height=5,units='in',dpi=600)


# symptom onset to hospitalization

t1 <- as.numeric(linelist$hosp_visit_date - linelist$symptom_onset)
t1[is.na(t1)]<-as.numeric(as.Date('2020-01-26')-linelist$symptom_onset[is.na(t1)])
t1<-pmax(t1,1)
outcome <- linelist$death
outcome[outcome==1]<-'death'
outcome[linelist$recovered==1]<-'recovered'
outcome[outcome=='0']<-'censored'

t1[linelist$recovered==1] <- as.numeric(linelist$recovered_date[linelist$recovered==1] - linelist$symptom_onset[linelist$recovered==1])
status<-as.numeric(outcome!='censored')
st <- data.frame(t1=t1,status=status,outcome=outcome)

st <- st
# st <- st %>% filter(outcome!='0')

st$outcome <- factor(st$outcome, levels=c('death','recovered','censored'))
surv_object <- Surv(time = st$t1,
                    event = st$status, 
                    type='right')

mod <- survfit(surv_object~1,data=st)
plot(mod)

onsetToHospDurationModel <- flexsurvreg(surv_object~1,data=st, dist='lognormal')

kmp2 <- ggsurvplot(mod,risk.table = TRUE, xlim=c(0,42), conf.int = TRUE) + guides(color=FALSE) 

p3<-kmp2$plot +  scale_x_continuous(limits=c(0,42), breaks=seq(0,40,by=4)) + 
  xlab('') + ylab('P(T>t)')
p4<- kmp2$table + scale_x_continuous(limits=c(0,42), breaks=seq(0,40,by=4)) + 
  xlab('days from symptom onset to outcome') + ylab('')

plot_grid(p3,p4,nrow = 2, rel_heights = c(0.75,0.22), align='v')

ggsave('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/symptom_onset_to_hospitalization_from_linelist.png',width=6, height=5,units='in',dpi=600)



## hospitalization to death
t1 <- as.numeric(linelist$death_date - linelist$hosp_visit_date)
t1[is.na(t1)]<-as.numeric(as.Date('2020-01-26')-linelist$hosp_visit_date[is.na(t1)])
t1<-pmax(t1,1)
outcome <- linelist$death
outcome[outcome==1]<-'death'
outcome[linelist$recovered==1]<-'recovered'
outcome[outcome=='0']<-'censored'

t1[linelist$recovered==1] <- as.numeric(linelist$recovered_date[linelist$recovered==1] - linelist$symptom_onset[linelist$recovered==1])
status<-as.numeric(outcome!='censored')
st <- data.frame(t1=t1,status=status,outcome=outcome)
st <- st %>% filter(outcome!='recovered')

st$outcome <- factor(st$outcome, levels=c('death','recovered','censored'))
surv_object <- Surv(time = st$t1,
                    event = st$status, 
                    type='right')

mod <- survfit(surv_object~1,data=st)
plot(mod)

deathDurationModel <- flexsurvreg(surv_object~1,data=st, dist='lognormal')
plot(deathDurationModel)


kmp2 <- ggsurvplot(mod,risk.table = TRUE, xlim=c(0,42), conf.int = TRUE) + guides(color=FALSE) 

p3<-kmp2$plot +  scale_x_continuous(limits=c(0,42), breaks=seq(0,40,by=4)) + 
  xlab('') + ylab('P(T>t)')
p4<- kmp2$table + scale_x_continuous(limits=c(0,42), breaks=seq(0,40,by=4)) + 
  xlab('days from symptom onset to outcome') + ylab('')

plot_grid(p3,p4,nrow = 2, rel_heights = c(0.75,0.22), align='v')

ggsave('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/hospitalization_to_death_from_linelist.png',width=6, height=5,units='in',dpi=600)



# symptom onset to death by age

t1 <- as.numeric(linelist$death_date - linelist$symptom_onset)
status<-t1/t1
status[is.na(t1)]<-0
age_bin <- linelist$age_bin
t1[is.na(t1)]<-as.numeric(as.Date('2020-01-26')-linelist$symptom_onset[is.na(t1)])
t1<-pmax(t1,1,na.rm=TRUE)
st <- data.frame(t1=t1,status=status, age_bin=age_bin)

# st <- st[linelist$death==1,]
# st<- st[!is.na(st$t1),]

surv_object <- Surv(time = st$t1,
                    event = st$status, 
                    type='right')

mod <- survfit(surv_object~age_bin,data=st)
plot(mod)

kmp2 <- ggsurvplot(mod,risk.table = TRUE, xlim=c(0,42), conf.int = FALSE) + guides(color=FALSE) 

p3<-kmp2$plot +  scale_x_continuous(limits=c(0,42), breaks=seq(0,42,by=4)) + 
  xlab('') + ylab('probability')
p4<- kmp2$table + scale_x_continuous(limits=c(0,42), breaks=seq(0,42,by=4)) + 
  xlab('days from symptom onset to death') + ylab('')

plot_grid(p3,p4,nrow = 2, rel_heights = c(0.5,0.45), align='v')

ggsave('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/symptom_onset_to_death_by_age_from_linelist.png',width=5, height=5,units='in',dpi=600)



## explore epi curve mortality
names(linelist)
plotDat <- linelist %>% group_by(symptom_onset) %>% summarize(will_die=sum(death==1), will_recover=sum(recovered==1), censored = sum(recovered!=1 & death!=1)) %>%
  gather(key,count,-symptom_onset) %>% mutate(key = factor(key,levels=c('censored','will_recover','will_die')))
plotDat2 <- linelist %>% group_by(death_date) %>% summarize(died=sum(death==1)) %>% drop_na() %>% mutate(date=death_date)
plotDat3 <- linelist %>% group_by(recovered_date) %>% summarize(recovered=sum(recovered==1)) %>% drop_na() %>% mutate(date=recovered_date)
plotDat4 <- plotDat %>% mutate(date=symptom_onset) %>% select(date ) %>%
  left_join(plotDat2 %>% full_join(plotDat3) %>% select(died,date,recovered) %>% gather(key,count,-date) %>%
  mutate(key = factor(key,levels=c('censored','recovered','died'))) ) %>% mutate(count=replace_na(count,0)) %>%
  mutate(key=replace_na(key,'censored'))


p1<-ggplot(plotDat) + geom_bar(aes(x=symptom_onset,y=count, group=key, fill=key), stat='identity') + xlab('symptom_onset')
p2<-ggplot(plotDat4) + geom_bar(aes(x=date,y=count, fill=key, group=key), stat='identity') + 
  scale_fill_manual(values=scales::hue_pal()(3)) +xlab('death_or_recovery_date')
plot_grid(p1,p2,nrow=2)


plotDat <- linelist %>% group_by(symptom_onset) %>% summarize(n=n(),deaths=sum(death==1), recovered=sum(recovered==1)) %>%
  group_by(symptom_onset) %>% summarize(will_recover=recovered/n, will_die = deaths/n,  censored=(n-deaths-recovered)/n) %>%
  gather(key,frequency,-symptom_onset) %>% mutate(key = factor(key,levels=c('censored','will_recover','will_die')) ) 

p3<-ggplot(plotDat) + geom_bar(aes(x=symptom_onset,y=frequency, group=key, fill=key), stat='identity')

plot_grid(p3,p1,p2,nrow=3, align='v')


ggsave('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/mortality_recover_timeseries.png',width=5, height=5,units='in',dpi=600)

plotDat <- linelist %>% group_by(symptom_onset) %>% summarize(n=n(),deaths=sum(death==1), recovered=sum(recovered==1)) %>%
  summarize(fracDead = mean(deaths/n,na.rm=TRUE), fracRecovered=mean(recovered/n,na.rm=TRUE)) %>%
  gather(key,value) %>% print()

# we're looking at at least a 40% case fatality rate early on!  


## age
## assume censored cases before Jan 15 are lost to follow up in case reports
plotDat <- linelist %>% mutate(age_bin=round(0.1*age)/0.1) %>% filter(symptom_onset<=as.Date('2020-01-15')) %>%
  group_by(age_bin) %>% summarize(will_die=sum(death==1), will_recover=sum(recovered==1), censored = sum(recovered!=1 & death!=1)) %>%
  gather(key,count,-age_bin) %>% mutate(key = factor(key,levels=c('censored','will_recover','will_die')))

age_mortality <- plotDat

p1<-ggplot(plotDat) + geom_bar(aes(x=age_bin,y=count, group=key, fill=key), stat='identity') + xlab('') + 
  xlim(c(0,95)) + scale_x_continuous(breaks=seq(0,90,by=10))

plotDat <- linelist %>% mutate(age_bin=round(0.1*age)/0.1) %>% filter(symptom_onset<=as.Date('2020-01-15')) %>%
  group_by(age_bin) %>% summarize(n=n(),deaths=sum(death==1), recovered=sum(recovered==1)) %>%
  group_by(age_bin) %>% summarize(will_recover=recovered/n, will_die = deaths/n,  censored=(n-deaths-recovered)/n) %>%
  gather(key,count,-age_bin) %>% mutate(key = factor(key,levels=c('censored','will_recover','will_die')) )

p3<-ggplot(plotDat) + geom_bar(aes(x=age_bin,y=count, group=key, fill=key), stat='identity')  + scale_x_continuous(breaks=seq(0,95,by=10))


# complete range with logistic regression

mod<-mgcv::gam(key ~ s(age_bin,k=7), data=age_mortality, weights=age_mortality$count, family='binomial')

age_mortality_fit <- data.frame(age_bin=seq(0,90,by=10),
                            fraction_dead=predict(mod, newdata=data.frame(age_bin=seq(0,95,by=10)),type='response'))
p3<-p3 + geom_line(data=age_mortality_fit,aes(x=age_bin,y=fraction_dead)) + ylab('fraction')

plot_grid(p3,p1,nrow=2, align='v')


ggsave('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/mortality_recover_age.png',width=5, height=5*2/3,units='in',dpi=600)


## total expected deaths

expected_outcomes <-
  linelist %>% group_by(age_bin) %>%
  summarize(n=n()) %>% group_by(age_bin) %>%
  left_join(age_mortality_fit) %>% 
  summarize(n=n, 
            expected_dead = round(n*fraction_dead,1),
            fraction_dead = round(fraction_dead,2)) %>% drop_na()

expected_outcomes<- expected_outcomes %>% rbind(data.frame(age_bin=' ',n='',expected_dead='',fraction_dead='')) %>%
  rbind(expected_outcomes %>% summarize(age_bin='total',n=sum(n,na.rm=TRUE),
                                expected_dead=sum(expected_dead,na.rm=TRUE),
                                fraction_dead=round(sum(expected_dead,na.rm=TRUE)/sum(n,na.rm=TRUE),2)))


png('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/estimated_mortality_among_early_cases.png',width=6.5, height=3.7,units='in',res=300)
grid.arrange(tableGrob(expected_outcomes, rows=NULL))
dev.off()


## bigger line list
linelist <- read.csv('./Data/nCoV2019_2020_line_list_open - outside_Hubei.csv', header=TRUE, stringsAsFactors = FALSE) %>%
  rbind(read.csv('./Data/nCoV2019_2020_line_list_open - Hubei.csv', header=TRUE, stringsAsFactors = FALSE))
names(linelist)

linelist$age[grepl('-',linelist$age)]<-''
linelist$age <- as.numeric(linelist$age)
linelist$age_reported<-'yes'
linelist$age_reported[is.na(linelist$age)]<-'no'
linelist <- linelist %>% mutate(age_bin=replace_na(factor(5+round(0.1*age)/0.1,levels=c(seq(5,95,by=10),'unknown'),ordered=TRUE),'unknown'))


sum(!is.na(linelist$age))

linelist$date_admission_hospital <- as.Date(linelist$date_admission_hospital,format='%d.%m.%y')
idx<-linelist$date_admission_hospital>as.Date('2020-03-01') & !is.na(linelist$date_admission_hospital)
linelist$date_admission_hospital[idx]<-linelist$date_admission_hospital[idx]-366
idx<-linelist$date_admission_hospital>=as.Date('2020-02-01') & !is.na(linelist$date_admission_hospital)
linelist$date_admission_hospital[idx]<-linelist$date_admission_hospital[idx]-29


linelist$date_onset_symptoms <- as.Date(linelist$date_onset_symptoms,format='%d.%m.%y')
idx<-linelist$date_onset_symptoms>as.Date('2020-03-01') & !is.na(linelist$date_onset_symptoms)
linelist$date_onset_symptoms[idx]<-linelist$date_onset_symptoms[idx]-366
idx<-linelist$date_onset_symptoms>=as.Date('2020-02-01') & !is.na(linelist$date_onset_symptoms)
linelist$date_onset_symptoms[idx]<-linelist$date_onset_symptoms[idx]-29

linelist$date_confirmation <- as.Date(linelist$date_confirmation,format='%d.%m.%y')
idx<-linelist$date_confirmation>as.Date('2020-03-01') & !is.na(linelist$date_confirmation)
linelist$date_confirmation[idx]<-linelist$date_confirmation[idx]-366
idx<-linelist$date_confirmation>=as.Date('2020-02-01') & !is.na(linelist$date_confirmation)
linelist$date_confirmation[idx]<-linelist$date_confirmation[idx]-29

linelist$hospitalization_or_confirmation <- if_else(!is.na(linelist$date_admission_hospital), linelist$date_admission_hospital,linelist$date_confirmation)

plotDat<- linelist %>% group_by(hospitalization_or_confirmation,age_bin) %>% summarize(count=n()) %>%
  left_join(linelist %>% group_by(hospitalization_or_confirmation) %>% summarize(total=n()) ) %>%
  mutate(fraction = count/total)

p1<-ggplot(plotDat) + geom_bar(aes(x=hospitalization_or_confirmation,y=count, fill=age_bin,group=age_bin), stat='identity')+ guides(fill=FALSE)
p2<- ggplot(plotDat) + geom_bar(aes(x=hospitalization_or_confirmation,y=fraction, fill=age_bin,group=age_bin), stat='identity')+ guides(fill=FALSE)


plotDat<- linelist %>% filter(age_bin != 'unknown') %>% group_by(hospitalization_or_confirmation,age_bin) %>% summarize(count=n()) %>%
  left_join(linelist %>% filter(age_bin != 'unknown') %>% group_by(hospitalization_or_confirmation) %>% summarize(total=n()) ) %>%
  mutate(fraction = count/total)

p3<-ggplot(plotDat ) + geom_bar(aes(x=hospitalization_or_confirmation,y=fraction, fill=age_bin,group=age_bin), stat='identity') +
  theme(legend.position = 'bottom')


plotDat<- linelist %>% filter(age_bin != 'unknown') %>% group_by(hospitalization_or_confirmation,age_bin) %>% summarize(count=n()) %>%
  left_join(linelist %>% filter(age_bin != 'unknown') %>% group_by(hospitalization_or_confirmation) %>% summarize(total=n()) ) %>%
  group_by(hospitalization_or_confirmation) %>% summarize(mean_age = sum(count*as.numeric(as.character(age_bin)))/unique(total)) 

plotDat2<- linelist %>% filter(age_bin != 'unknown') %>% mutate(after_Jan17 = hospitalization_or_confirmation>as.Date('2020-01-17')) %>%
  group_by(after_Jan17,age_bin) %>% summarize(count=n()) %>%
  left_join(linelist %>% mutate(after_Jan17 = hospitalization_or_confirmation>as.Date('2020-01-17')) %>% filter(age_bin != 'unknown') %>% group_by(after_Jan17) %>% summarize(total=n()) ) %>%
  group_by(after_Jan17) %>% summarize(grand_mean_age = sum(count*as.numeric(as.character(age_bin)))/unique(total)) 

plotDat <- plotDat %>% mutate(after_Jan17 = hospitalization_or_confirmation>as.Date('2020-01-17')) %>% left_join(plotDat2)
p4<-ggplot(plotDat ) + 
  geom_line(aes(x=hospitalization_or_confirmation, y=mean_age)) +
  geom_line(aes(x=hospitalization_or_confirmation,y=grand_mean_age),size=1)

plot_grid(p1,p2,p3,p4,nrow=4, rel_heights = c(1,1,1.6,1))
ggsave('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/ages_expanded_linelist.png',width=5, height=5*4/3,units='in',dpi=600)


## symptom onset to hospitalization

t1 <- as.numeric(linelist$date_confirmation - linelist$date_onset_symptoms)
t1[is.na(t1)]<-as.numeric(as.Date('2020-01-26')-linelist$symptom_onset[is.na(t1)])
t1<-pmax(t1,1)

st <- data.frame(t1=t1)

st <- st %>% drop_na()
st$status <- 1
# st <- st %>% filter(outcome!='0')

surv_object <- Surv(time = st$t1,
                    event = st$status, 
                    type='right')

mod <- survfit(surv_object~1,data=st)
plot(mod)

onsetToHospDurationModel <- flexsurvreg(surv_object~1,data=st, dist='lognormal')
plot(onsetToHospDurationModel)

kmp2 <- ggsurvplot(mod,risk.table = TRUE, xlim=c(0,42), conf.int = TRUE) + guides(color=FALSE) 

p3<-kmp2$plot +  scale_x_continuous(limits=c(0,42), breaks=seq(0,40,by=4)) + 
  xlab('') + ylab('P(T>t)')
p4<- kmp2$table + scale_x_continuous(limits=c(0,42), breaks=seq(0,40,by=4)) + 
  xlab('days from symptom onset to outcome') + ylab('')

plot_grid(p3,p4,nrow = 2, rel_heights = c(0.75,0.22), align='v')
ggsave('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/symptom_onset_to_confirmation_from_linelist.png',width=6, height=5,units='in',dpi=600)
onsetToHospDurationModel


## impute ages

linelist$imputed_age_bin <- linelist$age_bin
idx <-linelist$imputed_age_bin=='unknown'
linelist$imputed_age_bin[idx] <- 
  sample(linelist$imputed_age_bin[!idx],size=sum(idx),replace=TRUE)
linelist$imputed_age_bin <- droplevels(linelist$imputed_age_bin)

# imputed deaths
age_mortality_fit$imputed_age_bin <-factor(seq(5,95,by=10),ordered=TRUE)

linelist <- linelist %>% left_join(age_mortality_fit %>% select(-age_bin))
sum(linelist$fraction_dead)/nrow(linelist)

x<-rep(NA,1e4)
for (k in 1:1e4){
  x[k]<-sum(rbinom(linelist$fraction_dead[!idx],1, linelist$fraction_dead[!idx]))
}
quantile(x,c(0.025,0.975))/nrow(linelist[!idx,])

# given cases and survival time, how should deaths track infections?
deathDurationModel


# death_imputation <- function(linelist,reps=1e4){

reps=1e4
imputed_death_date <- rep(linelist$hospitalization_or_confirmation,reps)
imputed_death_date_18 <- matrix(imputed_death_date,ncol=reps)

imputed_death_date_18 <- imputed_death_date_18 +
rlnorm(length(imputed_death_date_18),meanlog=2.4602,sdlog=0.6785)

idx<-imputed_death_date >as.Date('2020-01-12') & !is.na(imputed_death_date)
imputed_death_date[idx] <- imputed_death_date[idx] +
  rlnorm(sum(idx,na.rm=TRUE),meanlog=log(7),sdlog=0.42)

imputed_death_date[!idx] <- imputed_death_date[!idx] +
  rlnorm(sum(!idx,na.rm=TRUE),meanlog=2.4602,sdlog=0.6785)


 
imputed_death_date <- matrix(imputed_death_date,ncol=reps)

linelist$imputed_death_date_mean_18 <-as.Date(rowMeans(imputed_death_date_18),origin='1970-01-01')
linelist$imputed_death_date_mean <-as.Date(rowMeans(imputed_death_date),origin='1970-01-01')
linelist$imputed_death_date_upper <-as.Date(rowQuantiles(imputed_death_date,na.rm=TRUE,probs=0.025),origin='1970-01-01')
linelist$imputed_death_date_lower <-as.Date(rowQuantiles(imputed_death_date,na.rm=TRUE,probs=0.975),origin='1970-01-01')
# }

plotDat <- linelist %>% group_by(hospitalization_or_confirmation) %>% summarize(total=n()) %>%
  mutate(total = cumsum(total)) %>% mutate(date=hospitalization_or_confirmation) %>% select(-hospitalization_or_confirmation) %>%
  mutate(outcome="linelist_cases")

plotDat2 <- linelist %>% group_by(imputed_death_date_mean) %>% summarize(total=sum(fraction_dead)) %>%
  mutate(total = pmax(1,cumsum(total))) %>% mutate(date=imputed_death_date_mean) %>% select(-imputed_death_date_mean) %>%
  mutate(outcome="imputed_linelist_deaths")

plotDat2a <- linelist %>% group_by(imputed_death_date_mean_18) %>% summarize(total=sum(fraction_dead)) %>%
  mutate(total = pmax(1,cumsum(total))) %>% mutate(date=imputed_death_date_mean_18) %>% select(-imputed_death_date_mean_18) %>%
  mutate(outcome="imputed_linelist_deaths_Jan15_params")

cumulativeData <- read.csv('./Data/cumulative_data_wikipedia.csv', header=TRUE, stringsAsFactors = FALSE) %>% select(-source)
names(cumulativeData)[1]<-'date'

cumulativeData<-cumulativeData %>% gather(outcome,total,-date)


plotDat3 <- linelist %>% group_by(imputed_death_date_lower) %>% summarize(total=sum(fraction_dead)) %>%
  mutate(total = pmax(1,cumsum(total))) %>% mutate(date=imputed_death_date_lower) %>% select(-imputed_death_date_lower) %>%
  mutate(outcome="imputed_death_date_lower")

plotDat4 <- linelist %>% group_by(imputed_death_date_upper) %>% summarize(total=sum(fraction_dead)) %>%
  mutate(total = pmax(1,cumsum(total))) %>% mutate(date=imputed_death_date_upper) %>% select(-imputed_death_date_upper) %>%
  mutate(outcome="imputed_death_date_upper")


plotDat <- plotDat %>% rbind(plotDat2) %>% rbind(cumulativeData)%>% rbind(plotDat2a)  %>% 
  filter(date <= as.Date('2020-02-05'))

plotDat$outcome <- factor(plotDat$outcome, levels=c('linelist_cases','cumulative_confirmed_cases',
                                                    'imputed_linelist_deaths','cumulative_confirmed_deaths','imputed_linelist_deaths_Jan15_params')[5:1])

ribDat <- plotDat3 %>% rbind(plotDat4) %>%  filter(date <= as.Date('2020-02-05')) %>%  spread(outcome, total)

# ribDat<- plotDat %>% filter(outcome %in% c('imputed_death_date_lower','imputed_death_date_upper')) %>%
#   spread(outcome, total)
ggplot(plotDat) +geom_step(aes(x=date,y=log10(total), group=outcome,color=outcome)) + 
  theme_bw()+theme(legend.position = 'right', legend.title = element_text(NULL)) + xlab('') +
  # geom_step(data=ribDat,aes(x=date,y=log10(imputed_death_date_lower),ymax=log10(imputed_death_date_upper)),linetype='dotted') +
  # geom_step(data=ribDat,aes(x=date,y=log10(imputed_death_date_upper)),linetype='dotted') +
  scale_color_brewer(type='qual', palette=3, direction=-1)

ggsave('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/cases_vs_deaths_fancy_model.png',width=6.5, height=3.5,units='in',dpi=600)



cumulativeData
tmp<-cumulativeData %>% filter(outcome=='cumulative_confirmed_cases') %>% mutate(outcome='expected_deaths') %>%
  mutate(total=round(0.33*(total))) %>% mutate(date = as.Date(as.Date(date)+7))

tmp<- cumulativeData %>% mutate(date=as.Date(date)) %>% rbind(tmp)
ggplot(tmp) + geom_step(aes(x=date, y=log10(total),color=outcome,group=outcome)) + theme_bw()
ggsave('./analyses/first_adjusted_mortality_estimates_and_risk_assessment/cases_vs_deaths_simple_model.png',width=6.5, height=3.5,units='in',dpi=600)

## model estimates of infections https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(20)30260-9/fulltext
casesJan25<-761 #https://www.cnn.com/asia/live-news/coronavirus-outbreak-hnk-intl-01-25-20/index.html

# discount infections by time it takes to observe! 

median_incubation <- c(5.4, 4.2, 6.7)
median_onset_to_confirmation <- exp(c(1.4482,1.3479,1.5484))
doubling<-c(6.4, 5.8, 7.1)

infectionsLu <- c(75815, 37304,130330 ) * 2^(-(median_incubation[c(1,3,2)]+
                                                 median_onset_to_confirmation[c(1,3,2)])/doubling)

infectionsLu

casesJan25/infectionsLu*100

casesJan25/infectionsLu*c(.33,.37,.29)*100 # outer interval

infectionsLu/casesJan25


## us flu mortality https://www.cdc.gov/flu/about/burden/index.html
invIFR <- sum(c(10,4.3,16,13,14,11,14,21,16.5)*1e6)/sum(c(37,12,43,38,51,23,38,61,34)*1e3)

invIFR <- mean(c(10,4.3,16,13,14,11,14,21,16.5)*1e6/(c(37,12,43,38,51,23,38,61,34)*1e3))



## international IFR bound

calthaus_CFR <- c(2.1, 0.55, 5.4)
sensitivity_weight <- c(2.8,1.5,4.4)

upper_IFR <- calthaus_CFR / sensitivity_weight[c(1,3,2)]
upper_IFR




expected_infections_to_singapore <- 0.042* c(834, 478, 1349) #https://www.medrxiv.org/content/10.1101/2020.02.04.20020479v1.full.pdf
imported_cases_as_of_Feb3 <- 18

ascertainment_rate <- imported_cases_as_of_Feb3 / expected_infections_to_singapore
ascertainment_rate

lower_IFR <- upper_IFR* ascertainment_rate[c(1,3,2)]
lower_IFR
