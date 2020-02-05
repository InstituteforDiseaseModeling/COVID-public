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



# incubation = duration from exposure to onset
# censored survival analysis

t1 <- as.numeric(linelist$symptom_onset - linelist$exposure_end)
t1 <- pmax(1,t1)
t2 <- as.numeric(linelist$symptom_onset - linelist$exposure_start)
st <- data.frame(t1=t1,t2=t2,status=3)

st<- st[!is.na(st$t1) | !is.na(st$t2),]

surv_object <- Surv(time = st$t1,
                    time2 = st$t2, 
                    type='interval2')

mod <- survfit(surv_object~1,data=st)
plot(mod)

mod2<-flexsurvreg(surv_object ~ 1, dist="exponential", data=st)
ggflexsurvplot(mod2,conf.int = TRUE) 
mod2

mod2a<-flexsurvreg(surv_object ~ 1, dist="weibull", data=st)
ggflexsurvplot(mod2,conf.int = TRUE) 


mod3<-flexsurvreg(surv_object ~ 1, dist="lognormal", data=st)
ggflexsurvplot(mod3,conf.int = TRUE, summary.flexsurv = summary(mod3,t=seq(1,20,by=0.1))) 
mod3

predMod <- as.data.frame(summary(mod3,t=seq(1,100,by=0.1)))

kmp <- ggsurvplot(mod,risk.table = TRUE, xlim=c(0,20), conf.int = FALSE) + guides(color=FALSE) 

p1<-kmp$plot + geom_line(data=predMod,aes(x=time,y=est)) +
  geom_line(data=predMod,aes(x=time,y=lcl),linetype='dashed') + 
  geom_line(data=predMod,aes(x=time,y=ucl),linetype='dashed') + 
  scale_x_continuous(limits=c(0,20), breaks=seq(0,20,by=2)) + 
  xlab('') + ylab('probability')

p2<- kmp$table + scale_x_continuous(limits=c(0,20), breaks=seq(0,20,by=2)) + 
  xlab('days from exposure to symptom onset') + ylab('')

plot_grid(p1,p2,nrow = 2, rel_heights = c(0.7,0.25), align='v')

ggsave('./sitrep/incubation_period_estimate/incubation_from_linelist.png',width=5, height=5,units='in',dpi=600)

incubationIntervals<-matrix(c(predMod$time[min(which(predMod$est<=0.5))], predMod$time[min(which(predMod$est<=0.975))],predMod$time[min(which(predMod$est<=0.025))],
                              predMod$time[min(which(predMod$lcl<=0.5))], predMod$time[min(which(predMod$lcl<=0.975))],predMod$time[min(which(predMod$lcl<=0.025))],
                              predMod$time[min(which(predMod$ucl<=0.5))], predMod$time[min(which(predMod$ucl<=0.975))],predMod$time[min(which(predMod$ucl<=0.025))]),
                            ncol = 3)


incubationIntervals <- data.frame(incubationIntervals,row.names = c('duration_median','duration_lower95','duration_upper95'))
names(incubationIntervals) <- c('model_mle','model_lcl','model_ucl')
incubationIntervals

png('./sitrep/incubation_period_estimate/incubation_from_linelist_summary.png',width=5, height=1.5,units='in',res=600)
grid.arrange(tableGrob(incubationIntervals))
dev.off()

