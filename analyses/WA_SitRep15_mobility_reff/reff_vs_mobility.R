library(tidyverse)
library(INLA)
library(ggnewscale)
library(cowplot)
library(lemon)


## weekends
weekend <- data.frame(date = seq(as.Date('2020-02-17'),as.Date('2020-08-30'), by=1))
weekend$day_of_week_idx <- c(1:7)
weekend$is_weekend <- weekend$day_of_week_idx>=6

w1<-weekend
w1$county<-"King"
w2<-weekend
w2$county<-"Yakima"
w3<-weekend
w3$county<-"Benton-Franklin"

weekend <- rbind(w1,w2,w3)




## google mobility (sorry for no variable name change!)
sg <- read.csv('Google_Mobility_filtered.csv')

# very little franklin for some reason
sg <- sg %>% filter(sg$sub_region_2 %in% c("King County","Yakima County",'Benton County'))

sg$date<-as.Date(sg$date)

sg$county <- sub(' County','',sg$sub_region_2)

sg$county[sg$county=='Benton'] <- 'Benton-Franklin'
sg$percent_home <- pmax(0,sg$residential_percent_change_from_baseline)

sg <- right_join(sg,weekend,by=c('date','county'))

sg$date_idx <- NA
for(NAME in unique(sg$county)){
  sg$date_idx[sg$county==NAME] <- c(1:sum(sg$county==NAME))
}



# smooth mobility and remove weekend effects

for(NAME in unique(sg$county)){
  
  lc<-list()
  for( k in 1:sum(sg$county==NAME) ){
    lc[k] <- inla.make.lincomb('(Intercept)' = 1, date_idx = c(rep(NA,k-1),1))
    names(lc[k])<- paste0('latent_field',k)
  }
  
  summary(mod <- inla(percent_home ~  
                             is_weekend +
                             f(day_of_week_idx,model='iid',constr=TRUE) +
                             f(date_idx, model ='rw2', constr = TRUE),
                           data=sg %>% filter(county==NAME),
                           lincomb=lc,
                           control.compute=list(config=TRUE),verbose=FALSE,
                           control.predictor=list(compute=TRUE,link=1)))
  
  
  # plot((mod$summary.fitted.values$mode),sg$percent_home[d$county==NAME])
  # plot((mod$summary.fitted.values$mode))
  # lines(d$percent_home[sg$county==NAME])
  # 
  # plot(mod$summary.random$npi_idx$mean)
  # 
  # plot(mod$summary.random$day_idx$mean)
  # 
  plot(mod$summary.lincomb.derived$mean)
  lines(sg$percent_home[sg$county==NAME])
  
  sg$percent_home_smooth[sg$county==NAME] <- mod$summary.lincomb.derived$mean
  
}

ggplot() + 
  geom_line(data=sg,aes(x=date,y=percent_home, group=county, color=county)) +
  geom_line(data=sg,aes(x=date,y=percent_home_smooth, group=county, color=county),size=1.5) + 
  xlab('') + ylab('percent at home') + 
  scale_x_date(date_labels = "%B", breaks='1 month')



## reff
rk <- read.csv('kc_r0_9_6.csv')
names(rk)[1]<-'date'
rk$date<-as.Date(rk$date)
rk$county <- "King"

ry <- read.csv('yakima_r0_9_6.csv')
names(ry)[1]<-'date'
ry$county <- "Yakima"
ry$date<-as.Date(ry$date)

rb <- read.csv('tricities_r0_9_6.csv')
names(rb)[1]<-'date'
rb$county <- "Benton-Franklin"
rb$date<-as.Date(rb$date)

rt <- rbind(rk,ry,rb)
head(rt)



## rt dataset
d <- right_join(sg, rt, by=c('county','date')) %>% arrange(county,date)  


d$date_idx <- NA
for(NAME in unique(d$county)){
  d$date_idx[d$county==NAME] <- c(1:sum(d$county==NAME))
}

# for INLA
d$npi_idx <- c(1:sum(d$county=='Benton-Franklin'),1:sum(d$county=="King"), 1:sum(d$county=='Yakima'))
d$masks_on <- 1

d$masks_on[d$date<'2020-05-18']<-0
d$masks_on_idx <- d$masks_on
d$masks_on_idx[d$county=="King"] <- pmax(1,d$npi_idx[d$county=="King"]-sum(d$masks_on[d$county=="King"]==0))
d$masks_on_idx[d$county=="Yakima"] <- pmax(1,d$npi_idx[d$county=="Yakima"]-sum(d$masks_on[d$county=="Yakima"]==0))
d$masks_on_idx[d$county=="Benton-Franklin"] <- pmax(1,d$npi_idx[d$county=="Benton-Franklin"]-sum(d$masks_on[d$county=="Benton-Franklin"]==0))

d$county_idx <- as.numeric(as.factor(d$county))
 


ggplot(d) + geom_point(aes(x=percent_home,y=log(r0_t), color=date)) + facet_grid("county")
ggplot(d) + geom_point(aes(x=percent_home_smooth,y=log(r0_t), color=date)) + facet_grid("county")


idx<-d$county=="Benton-Franklin"
cor(log(d$r0_t[idx]),d$percent_home_smooth[idx])

idx<-d$county=="King"
cor(log(d$r0_t[idx]),d$percent_home_smooth[idx])

idx<-d$county=="Yakima"
cor(log(d$r0_t[idx]),d$percent_home_smooth[idx])




## analysis


# independent models for each county. Fits better than single model for all
# and that makes sense since the population density and social structure varies between these regions, 
# so cellphone movement may not have a universal quantitative mapping to transmission

mod<-list()
for(NAME in unique(d$county)){

  # fixed_lc
  lc<-list()
  for( k in 1:sum(d$county==NAME) ){
    tmp<-d[d$county==NAME,]
    lc[k] <- inla.make.lincomb('(Intercept)' = 1, percent_home_smooth = tmp$percent_home_smooth[k])
    names(lc[k])<- paste0('latent_field',k)
  }

  N<- max(d$masks_on_idx[d$county==NAME])
  summary(mod[[NAME]] <- inla(log(r0_t) ~  percent_home_smooth +
                             f(masks_on_idx, model ='rw2', constr = FALSE, #),
                                                         extraconstr = list(A = rbind(rep(c(-1,1,0),c(1,1,N-2)), rep(c(1,0),c(1,N-1))), e = rbind(0, 0))),
          data=d %>% filter(county==NAME),
          lincomb=lc,
          scale = (1/d$std_err[d$county==NAME]^2),
          control.compute=list(config=TRUE),verbose=TRUE,
          control.predictor=list(compute=TRUE,link=1)))


  plot(exp(mod[[NAME]]$summary.fitted.values$mode),d$r0_t[d$county==NAME])
  plot(mod[[NAME]]$summary.random$masks_on_idx$mean)


  plot(exp(mod[[NAME]]$summary.lincomb.derived$mean))

}

mod$`Benton-Franklin`$summary.fixed
mod$King$summary.fixed
mod$Yakima$summary.fixed


plot_df<-list()
for(NAME in unique(d$county)){

  plot_df[[NAME]] <- data.frame(date = d %>% filter(county==NAME) %>% select(date),
                                fit = exp(mod[[NAME]]$summary.fitted.values$mean + mod[[NAME]]$summary.fitted.values$sd^2/2),
                                fit_0.025quant = exp(mod[[NAME]]$summary.fitted.values$`0.025quant`),
                                fit_0.975quant = exp(mod[[NAME]]$summary.fitted.values$`0.975quant`),
                                counterfactual_mean = exp(mod[[NAME]]$summary.lincomb.derived$mean + mod[[NAME]]$summary.lincomb.derived$sd^2/2),
                                counterfactual_0.025quant = exp(mod[[NAME]]$summary.lincomb.derived$`0.025quant`),
                                counterfactual_0.975quant = exp(mod[[NAME]]$summary.lincomb.derived$`0.975quant`),
                                county=NAME)

}
plot_df2 <- left_join(d,rbind(plot_df[[1]],plot_df[[2]],plot_df[[3]]))



# shared intercept and slope model
# lc<-list()
# for( k in 1:nrow(d) ){
#   lc[k] <- inla.make.lincomb('(Intercept)' = 1, percent_home_smooth = d$percent_home_smooth[k])
#   names(lc[k])<- paste0('latent_field',k)
# }
# 
# N<- max(d$masks_on_idx)
# 
# summary(mod <- inla(log(r0_t) ~  percent_home_smooth +
#                               f(masks_on_idx, model ='rw2', replicate=county_idx,
#                                 constr = FALSE,
#                                 # extraconstr=list(A=matrix(rep(c(1,0),c(1,N-1)))),e=0),
#                                 extraconstr = list(A = rbind(rep(c(-1,1,0),c(1,1,N-2)), rep(c(1,0),c(1,N-1))), e = rbind(0, 0))),
#                             data=d,
#                             scale = (1/d$std_err^2),
#                             lincomb=lc,
#                             control.compute=list(config=TRUE),verbose=TRUE,
#                             control.predictor=list(compute=TRUE,link=1)))
# 
# mod$summary.fixed
# 
# plot_df2<- left_join(d,
#                      data.frame(date = d %>% select(date),
#                               # fit = exp(mod$summary.fitted.values$mean + mod$summary.fitted.values$sd^2/2),
#                               # fit_0.025quant = exp(mod$summary.fitted.values$`0.025quant`),
#                               # fit_0.975quant = exp(mod$summary.fitted.values$`0.975quant`),
#                               counterfactual_mean = exp(mod$summary.lincomb.derived$mean + mod$summary.lincomb.derived$sd^2/2),
#                               counterfactual_0.025quant = exp(mod$summary.lincomb.derived$`0.025quant`),
#                               counterfactual_0.975quant = exp(mod$summary.lincomb.derived$`0.975quant`),
#                               county=d$county)
# )





## plots


p<-list()
for(NAME in unique(d$county)){
  
  if(NAME=="King"){
    col_pal<-c('#D13727') 
  } else if (NAME=="Yakima"){
    col_pal<-c('#F2C057')
  } else {
    col_pal<-c('#063852') 
  }
  
  p[[NAME]] <- ggplot(data=plot_df2 %>% filter(county==NAME))
  
  # if(NAME=='King'){
  #   p[[NAME]] <- p[[NAME]] +
  #   geom_vline(xintercept=as.Date('2020-06-05')) + geom_text(aes(x=as.Date('2020-06-05')+3, y=3.4, label='Phase 1.5'), angle=-90) +
  #   geom_vline(xintercept=as.Date('2020-06-19')) + geom_text(aes(x=as.Date('2020-06-19')+3, y=3.4, label='Phase 2'), angle=-90)
  # } else {
  #   p[[NAME]] <- p[[NAME]] +
  #   geom_vline(xintercept=as.Date('2020-07-09')) + geom_text(aes(x=as.Date('2020-07-09')+3, y=3.4, label='Phase 1.5'), angle=-90)
  # }
  
  p[[NAME]] <- p[[NAME]] +
    # geom_vline(xintercept=as.Date('2020-02-28')) + geom_text(aes(x=as.Date('2020-02-28')+3, y=0.33, label='First Death'), angle=-90) +
    geom_vline(xintercept=as.Date('2020-03-23')) + geom_text(aes(x=as.Date('2020-03-23')+3, y=3, label='Stay Home, Stay Healthy'), angle=-90) +
    geom_vline(xintercept=as.Date('2020-05-18')) + geom_text(aes(x=as.Date('2020-05-18')+3, y=3, label='Masks Recommended'), angle=-90) +
    geom_vline(xintercept=as.Date('2020-06-26')) + geom_text(aes(x=as.Date('2020-06-26')+3, y=3, label='Masks Required'), angle=-90) #+
    # geom_vline(xintercept=as.Date('2020-07-07')) + geom_text(aes(x=as.Date('2020-07-07')+3, y=3.4, label='No Mask, No Service'), angle=-90) +
    # geom_vline(xintercept=as.Date('2020-07-30')) + geom_text(aes(x=as.Date('2020-07-30')+3, y=3.4, label='Business Gathering Restrictions'), angle=-90) 
  
  p[[NAME]] <- p[[NAME]] +  
    geom_hline(aes(yintercept=1,color='black'),linetype='dashed') +
 
    # mobility only
    geom_ribbon(aes(x=date,ymin=counterfactual_0.025quant,ymax=counterfactual_0.975quant, group=county, fill='black', color=NULL),alpha=0.3) +
    scale_fill_manual(values='black') +
    geom_point(aes(x=date,y=counterfactual_mean, group=county, color='black')) +
    
    # debug total model fit
    # geom_ribbon(aes(x=date,ymin=fit_0.025quant,ymax=fit_0.975quant, group=county, fill='black', color=NULL),alpha=0.5) +
    # scale_fill_manual(values='black') +
    # geom_line(aes(x=date,y=fit, group=county, color='black')) +

    scale_color_manual(values='black') +
    scale_x_date(breaks='months', date_labels = '%B', expand = c(0,0)) +
    scale_y_continuous(breaks=seq(0,3,by=0.5),expand = c(0,0)) +
    
    new_scale_color() +
    new_scale_fill() +
    
    # Niket model
    geom_line(aes(x=date,y=r0_t, group=county, color=county)) +
    geom_ribbon(aes(x=date,ymin=pmax(0,r0_t-2*std_err),ymax=pmin(3.4,r0_t+2*std_err), group=county, fill=county, color=NULL),alpha=0.5)+
    scale_color_manual(values=col_pal) +
    scale_fill_manual(values=col_pal) +
    
    # formatting
    theme_classic() + 
    theme(legend.position = "none",axis.line=element_line(),plot.title = element_text(hjust=0.9)) + 
    scale_x_date(breaks='months', date_labels = '%B', expand = c(0,0),limits = as.Date(c('2020-03-01','2020-08-27'))) +
    scale_y_continuous(breaks=seq(0,3,by=0.5),expand = c(0,0),limits = c(0,3.4)) +
    xlab('') + ylab('Effective reproductive number') +
    ggtitle(NAME) 
    
    
}
p2<-plot_grid(p[[1]],p[[2]],p[[3]],nrow=3)
p2

png(filename='reff_compare.png',h=8,w=8, units='in',res=300)
p2
dev.off()




write_csv(plot_df2, 'mobility_reff_inla_model.csv')





# percent at home
p1<-ggplot() + geom_line(data=sg %>% filter(county %in% unique(plot_df2$county)),aes(x=date,y=percent_home, group=county, color=county)) + 
  geom_line(data=sg %>% filter(county %in% unique(plot_df2$county)),aes(x=date,y=percent_home_smooth, group=county, color=county),size=1.5) + 
  xlab('') + ylab('percent at home') + 
  scale_x_date(date_labels = "%B", breaks='1 month') 
p1
png(filename='stay_at_home.png',h=3,w=8, units='in',res=300)
p1
dev.off()


