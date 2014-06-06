# Plotting CDF for Time of Day and Time Between Tweets
# Jon Tatum 
# jdtatum@cs.stanford

#install.packages("Hmisc")
library("Hmisc") # errbar



plotCDF = function(header, group.features, plot.lines = T, use.tod = F){
  
  ts = read.csv(paste(header, 'ts.txt', sep="_"), header = F) 
  tod = read.csv(paste(header, 'tod.txt', sep="_"), header = F)
  delta = read.csv(paste(header, 'delta.txt', sep="_"), header = F)
  
  if(plot.lines){
    c = par()$col
    par(col="black")
    abline(v=0.1)
    abline(v=0.25)
    abline(v=0.5)
    abline(v=0.75)
    abline(v=0.9)
    par(col=c)
  }
  
 
  
  if(use.tod) { 
    tod = tod[, 1]
    samp = sample(x=1:length(tod), size=1000,replace=F)
    p = (1:length(tod))/length(tod)
    y = jitter(tod[samp])
    x = p[samp]
    
  } else {
    bad = which(delta[, 1] < 0)
    delta = delta[-bad, 1]
    
    p = (1:length(delta))/length(delta)
    samp = sample(x=1:length(delta), size=1000,replace=F)
    y = jitter(log(2 + delta[samp], 10), 10)
    x = p[samp]
  }
  
  points(x=x, y, 
       cex=0.4, xlim=c(0,15), main=header)
  # err bars
  
  g.avg = apply(X=group.features, 2, mean)
  g.sd = apply(group.features, 2, sd)
  # remove outliers (3 sd from mean)
  outlier = which(apply(abs(t(group.features) - g.avg) > 2 * g.sd, 2, any))
  l.o = length(outlier)
  print(l.o)
  if (l.o > 0){
    group.features = group.features[-outlier, ]
  }
  g.avg = apply(X=group.features, 2, mean)
  g.sd = apply(group.features, 2, sd)
  
  samples = c(0.1, 0.25, 0.5, 0.75, 0.9)
  
#   errbar( samples, 
#           g.avg, yplus=g.avg + g.sd, yminus=g.avg - g.sd, 
#           type="b", add=T)
  
}  

old.features = features = read.delim('features.csv', header=T, sep="\t")
noisy_exclude = which(features$num.tweets < 300)
if (length(noisy_exclude) > 1){
  features = features[-noisy_exclude, ]
}
del = c('delay.10th', 'delay.25th', 'delay.50th', 'delay.75th', 'delay.90th')
ldf = log(x=features[, del] + 2, base=10)
ldf = data.frame(y=0, ldf); 

time = c('time.10th', 'time.25th', 'time.50th', 'time.75th', 'time.90th')
tf = data.frame(y=0, features[, time])


print(noisy_exclude)

fnidx = which(is.element(features$label, c(6)))
fhidx = which(is.element(features$label, c(1, 4)))
fcon = cbind(y=0, ldf[fnidx, ])
fcoh = cbind(y=0, ldf[fhidx, ])
ldf$y[fhidx] = 1 
ldf=ldf[union(fnidx, fhidx), ]

par(col="black")
plot(-1,-1,ylim=c(0, 6), xlim=c(0,1), xlab=NA, ylab=NA, xaxt='n', yaxt='n')

axis(side=1, at=c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0))
axis(side=2,
     at=c(log(15, 10), log(60, 10), log(60*60, 10), log(60*60*24, 10), log(60*60*24*7), log(60*60*24*30)), 
     labels=c("15 Sec", "Minute", "Hour", "Day", "Week", "Month"))
par(col="green")
delta.cohort = plotCDF("cohort", fcoh, F)

par(col="blue")
delta.control = plotCDF("control", fcon, F)

title(main="CDF", 
      xlab="Cumulative density", 
      ylab="Log(tweet interval + 2)")

legend("topleft", legend = c("Schizophrenia", "Control"), col=c("green", "blue"), pch=16, title.col="black", box.col="black", text.col="black")

## Time of day

fcon = tf[fnidx, ]
fcoh = tf[fhidx, ]
tf$y[fhidx] = 1
tf=tf[union(fnidx, fhidx), ]
par(col="black")
plot(-1, -1, ylim=c(0, 24 * 60 * 60), xlim=c(0,1), xlab=NA, ylab=NA, xaxt='n', yaxt='n')

axis(side=1, at=c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0))
axis(side=2,
     at=(1:6) * 4 * 60 * 60, 
     labels=c(paste((1:6) * 4, "Hours")))
par(col="green")
delta.cohort = plotCDF("cohort", fcoh, F, T)

par(col="blue")
delta.control = plotCDF("control", fcon, F, T)

title(main="CDF Tweet Time of Day", 
      xlab="Cumulative Density", 
      ylab="Time of Day (s)")

legend("topleft", legend = c("Schizophrenia", "Control"), col=c("green", "blue"), pch=16, title.col="black", box.col="black", text.col="black")

library(ggplot2)


tf$time.10th = as.POSIXct(tf$time.10th, origin="1960-01-01", tz="UTC")
tf$time.25th = as.POSIXct(tf$time.25th, origin="1960-01-01", tz="UTC")
tf$time.50th = as.POSIXct(tf$time.50th, origin="1960-01-01", tz="UTC")
tf$time.75th = as.POSIXct(tf$time.75th, origin="1960-01-01", tz="UTC")
tf$time.90th = as.POSIXct(tf$time.90th, origin="1960-01-01", tz="UTC")

hs = seq(from=as.POSIXct(0, origin="1960-01-01", tz="UTC"), by="hour", length.out=25);
hs = hs[0:6 *4 + 1]
Sys.setenv(TZ="UTC")

formatter = function(x) ifelse(x==1, "schizophrenia", "control")

ggplot(tf, aes(x=factor(y), y=time.10th)) + 
  ggtitle("10th Percentile") + 
  geom_boxplot() + 
  scale_y_datetime(breaks=hs, labels=date_format("%I%p"), limits=c(hs[1], hs[7])) +
  scale_x_discrete("Group", labels = formatter) + 
  ylab("Time of Day") 

ggplot(tf, aes(x=factor(y), y=time.25th)) + 
  ggtitle("25th Percentile") + 
  geom_boxplot() + 
  scale_y_datetime(breaks=hs, labels=date_format("%I%p"), limits=c(hs[1], hs[7])) +
  scale_x_discrete("Group", labels = formatter) + 
  ylab("Time of Day") 

ggplot(tf, aes(x=factor(y), y=time.50th)) + 
  ggtitle("50th Percentile") + 
  geom_boxplot() + 
  scale_y_datetime(breaks=hs, labels=date_format("%I%p"), limits=c(hs[1], hs[7])) +
  scale_x_discrete("Group", labels = formatter) + 
  ylab("Time of Day") 

ggplot(tf, aes(x=factor(y), y=time.75th)) + 
  ggtitle("75th Percentile") + 
  geom_boxplot() + 
  scale_y_datetime(breaks=hs, labels=date_format("%I%p"), limits=c(hs[1], hs[7])) +
  scale_x_discrete("Group", labels = formatter) + 
  ylab("Time of Day") 

ggplot(tf, aes(x=factor(y), y=time.90th)) + 
  ggtitle("90th Percentile") + 
  geom_boxplot() + 
  scale_y_datetime(breaks=hs, labels=date_format("%I%p"), limits=c(hs[1], hs[7])) +
  scale_x_discrete("Group", labels = formatter) + 
  ylab("Time of Day") 



ggplot(ldf, aes(x=factor(y), y=delay.10th), ylim(0, 6.25)) + 
  ggtitle("10th Percentile") + 
  geom_boxplot() + 
  scale_x_discrete("Group", labels = formatter) + 
  ylim(c(0, 6.25)) +
  ylab("Log Delay")

ggplot(ldf, aes(x=factor(y), y=delay.25th)) + 
  geom_boxplot() + 
  ggtitle("25th Percentile") + 
  scale_x_discrete("Group",  labels = formatter) + 
  ylim(0, 6.25) +
  ylab("Log Delay")

ggplot(ldf, aes(x=factor(y), y=delay.50th)) + 
  geom_boxplot() + 
  ggtitle("50th Percentile") + 
  scale_x_discrete("Group",  labels = formatter) + 
  ylim(0, 6.25) +
  ylab("Log Delay")

ggplot(ldf, aes(x=factor(y), y=delay.75th)) + 
  geom_boxplot() + 
  ggtitle("75th Percentile") + 
  scale_x_discrete("Group",  labels = formatter) + 
  ylim(0, 6.25) +
  ylab("Log Delay")

ggplot(ldf, aes(x=factor(y), y=delay.90th)) + 
  geom_boxplot() + 
  ggtitle("90th Percentile") + 
  scale_x_discrete("Group", labels = formatter) + 
  ylim(0, 6.25) +
  ylab("Log Delay")

par(mfrow=c(1))

