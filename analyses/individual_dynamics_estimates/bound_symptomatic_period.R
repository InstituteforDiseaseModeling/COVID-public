# estimate incubation period

library(tidyverse)
library(survival)
library(flexsurv)
library(survminer)
library(cowplot)
library(gridExtra)


linelist <- read.csv('./Data/Kudos to DXY.cn Last update_ 01_25_2020,  11_30 am (EST) - Line-list.csv', header=TRUE)
linelist$date <- as.Date(linelist$date)
linelist$symptom_onset <- as.Date(linelist$symptom_onset)
linelist$hosp_visit_date <- as.Date(linelist$hosp_visit_date)
linelist$exposure_start <- as.Date(linelist$exposure_start)
linelist$exposure_end <- as.Date(linelist$exposure_end)
linelist$death_date <- as.Date(linelist$death_date)
linelist$recovered_date <- as.Date(linelist$recovered_date)


# lower bound on symptomatic period: duration from onset to hospitalization
# censored survival analysis

t1 <- as.numeric(linelist$hosp_visit_date - linelist$symptom_onset)
st <- data.frame(t1=t1,status=1)

st<- st[!is.na(st$t1) & st$t1>0,]  # filter out those who report hospitalization and onset on same day. I suspect these are either severe symptom onsets, or the onset date wasn't really reported.

surv_object <- Surv(time = st$t1,
                    event = st$status, 
                    type='right')

mod <- survfit(surv_object~1,data=st)
plot(mod)


mod3<-flexsurvreg(surv_object ~ 1, dist="lognormal", data=st)
ggflexsurvplot(mod3,conf.int = TRUE, summary.flexsurv = summary(mod3,t=seq(1,40,by=0.2))) 
mod3

predMod <- as.data.frame(summary(mod3,t=seq(1,100,by=0.1)))

kmp <- ggsurvplot(mod,risk.table = TRUE, xlim=c(0,40), conf.int = FALSE) + guides(color=FALSE) 

p1<-kmp$plot + geom_line(data=predMod,aes(x=time,y=est)) +
  geom_line(data=predMod,aes(x=time,y=lcl),linetype='dashed') + 
  geom_line(data=predMod,aes(x=time,y=ucl),linetype='dashed') + 
  scale_x_continuous(limits=c(0,40), breaks=seq(0,40,by=4)) + 
  xlab('') + ylab('probability')

p2<- kmp$table + scale_x_continuous(limits=c(0,40), breaks=seq(0,40,by=4)) + 
  xlab('days from symptom onset to hospitalization') + ylab('')

plot_grid(p1,p2,nrow = 2, rel_heights = c(0.7,0.25), align='v')

ggsave('./sitrep/individual_dynamics_estimates/symptom_onset_to_hospital_from_linelist.png',width=5, height=5,units='in',dpi=600)

hospitalIntervals<-matrix(c(predMod$time[min(which(predMod$est<=0.5))], predMod$time[min(which(predMod$est<=0.975))],predMod$time[min(which(predMod$est<=0.025))],
                            predMod$time[min(which(predMod$lcl<=0.5))], predMod$time[min(which(predMod$lcl<=0.975))],predMod$time[min(which(predMod$lcl<=0.025))],
                            predMod$time[min(which(predMod$ucl<=0.5))], predMod$time[min(which(predMod$ucl<=0.975))],predMod$time[min(which(predMod$ucl<=0.025))]),
                          ncol = 3)


hospitalIntervals <- data.frame(hospitalIntervals,row.names = c('duration_median','duration_lower95','duration_upper95'))
names(hospitalIntervals) <- c('model_mle','model_lcl','model_ucl')
hospitalIntervals

png('./sitrep/individual_dynamics_estimates/symptom_onset_to_hospital_from_linelist_summary.png',width=5, height=1.5,units='in',res=600)
grid.arrange(tableGrob(hospitalIntervals))
dev.off()




# upper bound symptom onset to death

t1 <- as.numeric(linelist$death_date - linelist$symptom_onset)
st <- data.frame(t1=t1,status=1)

st<- st[!is.na(st$t1),]

surv_object <- Surv(time = st$t1,
                    event = st$status, 
                    type='right')

mod <- survfit(surv_object~1,data=st)
plot(mod)


mod3<-flexsurvreg(surv_object ~ 1, dist="lognormal", data=st)
ggflexsurvplot(mod3,conf.int = TRUE, summary.flexsurv = summary(mod3,t=seq(1,40,by=0.2))) 
mod3

predMod2 <- as.data.frame(summary(mod3,t=seq(1,100,by=0.1)))

kmp2 <- ggsurvplot(mod,risk.table = TRUE, xlim=c(0,40), conf.int = FALSE) + guides(color=FALSE) 

p3<-kmp2$plot + geom_line(data=predMod2,aes(x=time,y=est)) +
  geom_line(data=predMod2,aes(x=time,y=lcl),linetype='dashed') + 
  geom_line(data=predMod2,aes(x=time,y=ucl),linetype='dashed') + 
  scale_x_continuous(limits=c(0,40), breaks=seq(0,40,by=4)) + 
  xlab('') + ylab('probability')

p4<- kmp2$table + scale_x_continuous(limits=c(0,40), breaks=seq(0,40,by=4)) + 
  xlab('days from symptom onset to death') + ylab('')

plot_grid(p3,p4,nrow = 2, rel_heights = c(0.7,0.25), align='v')

ggsave('./sitrep/individual_dynamics_estimates/symptom_onset_to_death_from_linelist.png',width=5, height=5,units='in',dpi=600)

survivalIntervals<-matrix(c(predMod$time[min(which(predMod2$est<=0.5))], predMod$time[min(which(predMod2$est<=0.975))],predMod2$time[min(which(predMod$est<=0.025))],
                              predMod$time[min(which(predMod2$lcl<=0.5))], predMod$time[min(which(predMod2$lcl<=0.975))],predMod2$time[min(which(predMod$lcl<=0.025))],
                              predMod$time[min(which(predMod2$ucl<=0.5))], predMod$time[min(which(predMod2$ucl<=0.975))],predMod2$time[min(which(predMod$ucl<=0.025))]),
                            ncol = 3)


survivalIntervals <- data.frame(survivalIntervals,row.names = c('duration_median','duration_lower95','duration_upper95'))
names(survivalIntervals) <- c('model_mle','model_lcl','model_ucl')
survivalIntervals

png('./sitrep/individual_dynamics_estimates/symptom_onset_to_death_from_linelist_summary.png',width=5, height=1.5,units='in',res=600)
grid.arrange(tableGrob(survivalIntervals))
dev.off()



