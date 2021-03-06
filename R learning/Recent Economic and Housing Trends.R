# This comes from http://lenkiefer.com/2016/08/27/housing-market-update
## load required libraries ##
library(data.table)
library(reshape2)
library(stringr)
library(ggplot2)
library(scales)
library(ggthemes)
library(rgeos)
library(maptools)
library(albersusa)
library(dplyr)
library(tidyr)
library(ggalt)
library(viridis)
library(zoo)
library(readxl)
library(htmlTable)
library(animation)
library(tweenr)

# function for combining graphs see: http://www.cookbook-r.com/Graphs/Multiple_graphs_on_one_page_(ggplot2)/
source('code/multiplot.R')

# source code for recession bars see: https://www.r-bloggers.com/use-geom_rect-to-add-recession-bars-to-your-time-series-plots-rstats-ggplot/
source("code/recessions.R")

###### Mortgage rate charts @mrtg  ######

# Read in data for mortgage rate charts:
mdata<-read_excel("data/chartbook aug 2016.xlsx",sheet="mrate")
mdata$date<-as.Date(mdata$date, format="%m/%d/%Y")
mdata<-data.table(mdata)

print.table<-data.table(mdata)[date>as.Date("2016-06-22"),
                               list(date=as.character(date,format="%B %d, %Y"),
                                    rate=format(rate, nsmall = 2))]

rownames(print.table)<-print.table$date
print.table$date<-NULL
htmlTable(print.table, header=c("30-year FRM"),
          row.names=print.table$date,row.label="Date",
          col.rgroup = c("none", "#F7F7F7"),caption="30-year fixed mortgage rates since Brexit",
          tfoot="Source: Freddie Mac Primary Mortgage Market Survey")


pmms1<-
  ggplot(data=mdata[year(date)>=2013, ], aes(x=date,y=rate,label=rate))+geom_line(size=1.1)+theme_minimal()+
  theme(legend.position="none")+
  scale_x_date()+
  scale_y_continuous(limits=c(3,4.75),breaks=seq(3,4.75,.25))+
  geom_text(data=mdata[date>='2015-12-31' & week==i],nudge_y=-.050,hjust=0,size=3)+
  geom_point(data=mdata[date>='2015-12-31' & week==i],size=2,color="red",alpha=0.75)+
  labs(x="", y="Mortgage Rate (%)",
       title="30-year Fixed Mortgage Rate (%)",
       subtitle="",
       caption="@lenkiefer Source: Freddie Mac Primary Mortgage Market Survey")+
  theme(plot.title=element_text(size=12))+
  theme(plot.subtitle=element_text(size=10))+
  theme(axis.title=element_text(size=8))+
  theme(axis.text=element_text(size=8))+
  theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10)))+
  theme(plot.margin=unit(c(0.25,0.25,0.25,0.25),"cm"))+
  coord_cartesian(xlim=c(as.Date("2012-12-31"),as.Date("2016-10-31")), y=c(3.25,4.75))

pmms2<-  
  ggplot(data=mdata[year>2012 & week<=i], 
         aes(x=week,y=rate,label=paste("   ",year),color=as.factor(year)))+
  geom_line(size=1.1)+theme_minimal()+
  scale_color_viridis(discrete=T,direction=-1,end=0.85)+
  theme(legend.position="none")+
  scale_x_continuous(limits=c(0,38))+
  scale_y_continuous(limits=c(3.25,4.75),breaks=seq(3.25,4.5,0.25))+
  geom_text(data=mdata[year>2012 & week==i],size=3,hjust=0)+
  geom_point(data=mdata[year>2012 & week==i],size=3,alpha=0.75)+
  labs(x="Week of year", y="Mortgage Rate (%)",
       title="30-year Fixed Mortgage Rate by Week",
       subtitle="comparing 2013, 2014, 2015 and 2016",
       caption="")+
  theme(plot.title=element_text(size=12))+
  theme(plot.subtitle=element_text(size=10))+
  theme(axis.title=element_text(size=8))+
  theme(axis.text=element_text(size=8))+
  theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10)))+
  theme(plot.margin=unit(c(0.25,0.25,0.25,0.25),"cm"))

#combine charts:
multiplot(pmms1,pmms2,cols=2)  

###### GDP contributions Charts @gdp ######

gdata<-data.table(read_excel("data/chartbook aug 2016.xlsx",sheet="gdpc"))
gdata$date<-as.Date(gdata$date, format="%m/%d/%Y")

gdata[, avgc:=mean(value), by=var]
gdata<-gdata[order(date,avgc),]
gdata[Total !="total", end:=cumsum(value), by=date]
gdata[Total=="total", end:=0, by=date]
gdata[,start:=shift(end,1,fill=0), by=date]
gdata[,id:=.I]
gdata[,id:=1:.N,,by=date]
gdata[, myjust:=ifelse(value<0,1,0)]
gdata[, lp:=ifelse(Total=="total",start,end)]
gdata[,dlabel:=factor(paste(year,"Q",quarter,sep=""))]
gdata[,cont:=factor(cont)]
gdata[,var:=factor(var)]

gdata$var<-factor(gdata$var, levels=gdata$var[order(gdata$avgc)])

gdata.plot<-gdata[year==2016]
gdata.plot[,date.label:=paste0(year,"Q",quarter)]

ggplot(data=gdata.plot, aes(x=var, y=lp,fill = cont,label=value)) + 
  geom_rect(aes(x = var, xmin = id - 0.45, xmax = id + 0.45, ymin = end,ymax = start))  +
  theme_minimal()+coord_flip()+   
  geom_text(data=gdata.plot,aes(hjust=myjust) )+
  labs(title="Contributions to Percent Change in Real Gross Domestic Product",x="",y="",
       subtitle="Seasonally adjusted at annual rates",
       caption="@lenkiefer Source: U.S. Bureau of Economic Analysis, Table 1.1.2, accessed 8/26/2016.")+
  scale_fill_manual(name="",values=c("red","lightblue","gray"))+
  theme(plot.title=element_text(size=12))+
  scale_y_continuous(limits=c(-3,3))+
  #geom_text(data=gdata.plot[cont=="total"] ,aes(y=0,x=7.25,label=dlabel),hjust=0,size=4,fontface="bold")  +
  theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10),size=10))+
  theme(legend.justification=c(0,0), legend.position="none")+facet_wrap(~date.label)

## Make animated gif ##
myd<-unique(gdata[year>=2008]$date)
myf<-function(d){as.data.frame(gdata[date==d, list(date,end,start,id,myjust,lp,var,cont,value,dlabel,year,avgc)])}
pdatag<-myf(myd[2])
pdatag<-data.table(pdatag)

# use lapply to generate the list of data sets:
my.list<-lapply(c(myd,tail(myd,1),tail(myd,1),tail(myd,1),tail(myd,1)),myf)

# apply tweenr
tf <- tween_states(my.list, tweenlength= 2, statelength=1, ease=rep('cubic-in-out',64),nframes=250)

# convert variable lables to factor, and order by average contribution so they go from big to small
tf$var<-factor(tf$var, levels=tf$var[order(tf$avgc)])
#conver to data table
tf<-data.table(tf)

p<-
  ggplot(data=tf, aes(x=var, y=lp,fill = cont,label=value,frame=.frame)) + 
  geom_rect(aes(x = var, xmin = id - 0.45, xmax = id + 0.45, ymin = end,ymax = start))  +
  theme_minimal()+coord_flip()+   geom_text(data=tf[date %in% myd , ] ,hjust=tf[date %in% myd , ]$myjust)+
  labs(title="Contributions to Percent Change in Real Gross Domestic Product",x="",y="",
       subtitle="Seasonally adjusted at annual rates",
       caption="@lenkiefer Source: U.S. Bureau of Economic Analysis, Table 1.1.2, accessed 8/26/2016.")+
  scale_fill_manual(name="",values=c("red","lightblue","gray"))+
  theme(plot.title=element_text(size=12))+
  geom_text(data=tf[cont=="total" ,  ] ,aes(y=0,x=7.25,label=dlabel),hjust=0,size=4,fontface="bold")  +
  theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10),size=10))+
  theme(legend.justification=c(0,0), legend.position="none")

gg_animate(p, "contributions to gdp 2016q2.gif", title_frame = F, ani.width = 740, 
           ani.height = 550, interval=.1)


#### GDP contributions time series @gdp ####

ggplot(data=gdata[year>1980 & cont!="total",])+facet_wrap(~var)+
  theme_minimal()+ theme(plot.title=element_text(size=12))+
  scale_color_viridis(discrete=T,direction=-1,end=0.85)+
  theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10),size=10))+
  theme(legend.justification=c(0,0), legend.position="none")+
  geom_rect(data=subset(recessions.df,Peak>="1980-01-01"), 
            aes(xmin=Peak, xmax=Trough, ymin=-Inf, ymax=+Inf), fill="gray", alpha=0.35)+
  geom_line(aes(x=date,y=value,color=var),size=1.1)+
  labs(x="",y="",title="Contributions to Percent Change in Real Gross Domestic Product",
       subtitle="Seasonally adjusted at annual rates",
       caption="@lenkiefer Source: U.S. Bureau of Economic Analysis, Table 1.1.2, accessed 8/26/2016.\nShaded area NBER Recession dates")
  

######  Home sales charts @sales  ######

mydata<-read_excel("data/chartbook aug 2016.xlsx",sheet="sales")
mydata$date<-as.Date(mydata$date, format="%m/%d/%Y")

mydata$date<-as.Date(mydata$date, format="%m/%d/%Y")
ggplot(data=mydata, aes(x=date,y=nhs.sa, label = nhs.sa))+geom_line(data=mydata)+
  scale_y_continuous(limits = c(200, 1600), breaks=seq(200,1600,200)) + 
  geom_point(data=tail(mydata,1),colour = plasma(5)[1], size = 3)+
  scale_x_date(labels= date_format("%b-%Y"), limits = as.Date(c('2000-01-01','2016-08-31'))) +
  geom_ribbon(data=mydata,aes(x=date,ymin=down,ymax=up),fill=plasma(5)[5],alpha=0.5)  +
  geom_hline(yintercept=tail(mydata,1)$nhs.sa,linetype=2,color=plasma(5)[1])+
  theme(axis.title.x = element_blank()) +   # Remove x-axis label
  ylab("")+xlab("")+
  theme_minimal()+
  labs(x=NULL, y=NULL,
       title="New Home Sales (Ths. SAAR)",
       subtitle=paste(as.character(tail(mydata,1)$date,format="%b-%Y"),":",tail(mydata,1)$nhs.sa),
       caption="@lenkiefer Source: Census/HUD, shaded area denotes confidence interval")+
  theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10)))+
  theme(plot.subtitle=element_text(color=plasma(5)[1]))+
  theme(plot.margin=unit(c(0.5,0.5,0.5,0.75),"cm"))

mydata<-data.table(mydata)    
mydata[, ehsc:=cumsum(ehs), by=year]  #computer cumulative sales YTD

#Make plot
ggplot(data=mydata[year>2006 & month<8], 
       aes(x = factor(year), y = ehs,fill=reorder(mname,month),label=mname)) +
  geom_bar(color = "gray", stat = "identity",alpha=0.75)+
  scale_fill_viridis(discrete=T,end=0.95,direction=1,option="D")+  #use viridis color scale
  theme_minimal()+ 
  geom_text(data=mydata[month==7 & year==2016],aes(y=ehsc),nudge_y=0.25,hjust=-.2)+
  geom_hline(yintercept=mydata[ month==7 & year==2016]$ehsc,linetype=2,color="black")+
  xlab("")+ylab("")+
  labs(title="Existing Home Sales (Ths. NSA)",
       subtitle="dotted line 2016 YTD",
       caption="@lenkiefer Source:NAR")+
  theme(plot.title=element_text(size=14))+
  theme(legend.justification=c(0,0), legend.position="none")+
  theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10)))+
  theme(plot.margin=unit(c(0.25,0.25,0.25,0.25),"cm"))+
  coord_flip()  #flip so that the bars are horizontal rather than vertical    

## Make animated home sales chart: ##

myf3<-function(m){
  DT<-copy(mydata)
  DT<-DT[month>m,ehs:=0]
  DT$mm<-m
  DT %>% map_if(is.character, as.factor) %>% as.data.frame() ->DT 
  as.data.frame(DT)}



my.list3<-lapply(c(seq(1,7,1),0),myf3)  #the animation will loop through each of the first five months of the year an then meet back at 0.
tf <- tween_states(my.list3, tweenlength= 2, statelength=3, ease=rep('cubic-in-out',17),nframes=70)
tf<-data.table(tf)  


oopt = ani.options(interval = 0.125)
saveGIF({for (i in 1:max(tf$.frame)) {
  g<-
    ggplot(data=tf[year>2006 & .frame==i & month<8], aes(x = factor(year), y = ehs,fill=reorder(mname,month),label=mname)) + geom_bar(color = "gray", stat = "identity",alpha=0.75)+
    scale_fill_viridis(discrete=T,end=0.95,direction=-1,option="D")+  #use viridis color scale
    theme_minimal()+ 
    geom_text(data=tf[month==mm& year==2016 & .frame==i],aes(y=ehsc),nudge_y=0.25,hjust=-.2)+
    geom_hline(yintercept=tf[.frame==i & month==mm & year==2016]$ehsc,linetype=2,color="black")+
    xlab("")+ylab("")+
    labs(title="Existing Home Sales (Ths. NSA)",
         subtitle="dotted line 2016 YTD",
         caption="@lenkiefer Source:NAR")+
    theme(plot.title=element_text(size=14))+
    theme(legend.justification=c(0,0), legend.position="none")+
    theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10)))+
    theme(plot.margin=unit(c(0.25,0.25,0.25,0.25),"cm"))+
    
    scale_y_continuous(limits=c(0,3500),labels=comma)+coord_flip()
  print(g)
  ani.pause()
}
},movie.name="ehs ytd july 2016.gif",ani.width = 600, ani.height = 450)


###### Housing starts @starts ######

mydata<-read_excel("data/chartbook aug 2016.xlsx",sheet="startserr")
mydata$date<-as.Date(mydata$date, format="%m/%d/%Y")
mydata$sales<-mydata$nsales
mydata$slabel<-round(mydata$starts,0)
mydata$slabel2<-round(mydata$hmi,0)
mydata<-data.table(mydata)
ggplot(data=mydata, aes(x=date,y=starts, label = slabel))+geom_line(data=mydata)+
  scale_y_continuous(limits = c(400, 2300), breaks=seq(400,2300,200)) + 
  geom_point(data=tail(mydata,2),colour = viridis(5)[1], size = 3)+
  scale_x_date(labels= date_format("%b-%Y"),
               limits = as.Date(c('2000-01-01','2016-12-31'))) +
  geom_ribbon(data=mydata,aes(x=date,ymin=down,ymax=up),fill=viridis(5)[5],alpha=0.5)  +
  coord_cartesian(xlim=as.Date(c('2000-01-01','2016-08-31')))+
  geom_hline(yintercept=tail(mydata,2)$starts,linetype=2,color=viridis(5)[5])+
  theme(axis.title.x = element_blank()) +   # Remove x-axis label
  ylab("")+xlab("")+
  theme_minimal()+
  labs(x=NULL, y=NULL,
       title="Housing Starts (Ths. SAAR)",
       #subtitle=paste(as.character(mydata$date[i],format="%b-%Y"),":",tail(mydata$slabel[i]),
       caption="@lenkiefer Source: Census/HUD, shaded area denotes confidence interval")+
  theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10)))+
  theme(plot.subtitle=element_text(color=plasma(5)[1]))+
  theme(plot.margin=unit(c(0.5,0.5,0.5,0.75),"cm"))


######  House price chart @price  ###### 

#read data:
fhfa.data<-fread("http://www.fhfa.gov/DataTools/Downloads/Documents/HPI/HPI_PO_state.txt")

fhfa.data[,hpa12:=index_sa/shift(index_sa,4)-1,by=state]
fhfa.data[,lag4:=shift(index_sa,4)-1,by=state]


fhfa.data[,iso_3166_2:=state]
fhfa.data[,date:=as.Date(ISOdate(yr,qtr*3,1))]
fhfa.data[,map.color:=min(0.2,max(-0.2,hpa12)),by=list(state,date)]

#reset index so that Q1 2000 =100
b.data<-fhfa.data[yr==2001 & qtr==1,list(hpi00Q1=index_sa),by=state]

fhfa.data<-merge(fhfa.data,b.data,by="state")
fhfa.data[,index_sa2:=100*index_sa/hpi00Q1]
fhfa.data[,max4:=rollapply(index_sa2,4,max,align="right",fill=NA),by=state]
fhfa.data[,min4:=rollapply(index_sa2,4,min,align="right",fill=NA),by=state]

states<-usa_composite()
smap<-fortify(states,region="fips_state")
smap.all<-smap

states@data <- left_join(states@data, fhfa.data, by = "iso_3166_2")


### Function for preparing graph data ###
make_graph_data<-function(d){
  yy<-year(d)
  qq<-quarter(d)
  start.date<- as.Date(ISOdate(yy-2,qq*3,1) )
  end.date<- as.Date(ISOdate(yy,qq*3,1) )
  mygraph.data<-subset(fhfa.data,date==d)
  mygraph.data %>% map_if(is.character, as.factor) %>% as.data.frame() ->mygraph.data  
  return(mygraph.data)
}

### Function for creating plot ###
mycombo<-function(indata){
  states<-usa_composite()
  states@data <- left_join(states@data, indata, by = "iso_3166_2")
  d<-max(indata$date)
  yy<-year(d)
  qq<-quarter(d)
map1<-
    ggplot() +
    geom_map(data = smap.all, map = smap.all,
             aes(x = long, y = lat, map_id = id),
             color = "#2b2b2b", size = 0.05, fill = NA) +
    geom_map(data =  states@data, map = smap.all,
             aes( map_id = fips_state,fill=map.color),
             color = "gray", size = .25) +
    theme_map( base_size = 12) +
    theme(plot.title=element_text( size = 12, margin=margin(b=10))) +
    theme(plot.subtitle=element_text(size = 10, margin=margin(b=-20))) +
    theme(plot.caption=element_text(size = 9, margin=margin(t=-15))) +
    coord_proj(us_laea_proj) +   labs(title="",subtitle="" ) +
    scale_fill_viridis(name = " ", discrete=F,option="C",end=1,
                       direction=-1,         limits=c(-0.2,0.2),label=percent)+
    theme(legend.position = "top") +theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10)))+
    labs(x="",y="",
         title=paste0("Annual House Price Growth (Y/Y %) Q",qq,":",yy),
         caption="@lenkiefer Source: FHFA Purchase-Only House Price Index (SA)")
  
  graph1<-
    ggplot(data=indata,aes(x=index_sa2,y=state,color=map.color))+geom_point(size=2)+
    theme_minimal()+ theme(legend.position = "none") +
    scale_x_log10(breaks=c(100,150,200,300,400),limits=c(75,400))+
    scale_color_viridis(name = "", discrete=F,option="C",end=1,
                        direction=-1,         limits=c(-0.2,0.2),label=percent)+
    geom_segment(aes(x=min4,xend=max4,y=state,yend=state),size=1.05,alpha=0.6)+  theme(axis.text=element_text(size=8))+
    labs(x="House Price Index\nlog scale,Q1:2001=100",y="",title=paste0("House Price Index Q",qq,":",yy),
         caption="dot is value, line 4 trailing quarter min/max")+
    theme(plot.caption=element_text(hjust=0,vjust=1,margin=margin(t=10)))
  
  multiplot(graph1,map1,cols=2)
}

mycombo(make_graph_data("2016-06-01"))

#### Make the animated gif  ####


d.list<-unique(subset(fhfa.data,yr>2000)$date)
# d.list<-unique(subset(fhfa.data,yr>2000 & qtr==2)$date)  # alternative if you want to go 4 quarters at a time
my.list<-lapply(c(d.list,d.list[1]),make_graph_data)
tf <- tween_states(my.list,tweenlength= 3, statelength=2, ease=rep('cubic-in-out',2),nframes=length(d.list)*8)
tf<-data.table(tf) #data.table useful for subsetting
N<-max(tf$.frame)  #number of frames

#create the animation
oopt = ani.options(interval = 0.15)
saveGIF({for (i in 1:N) {
  mycombo(tf[.frame==i])
  print(i)
  ani.pause()  }
},movie.name="fhfa hpa4.gif",ani.width = 800, ani.height = 450)
