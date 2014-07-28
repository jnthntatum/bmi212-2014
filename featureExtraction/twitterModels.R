# twitterModels.R
# run k-fold CV to tune parameters and select features for models
# CV blocks are slow, so they are commented out.  
#
# Jon Tatum (jdtatum@cs.stanford)
# Emily Doughty

library(e1071)
library(neuralnet)
library(glmnet)
# library(scatterplot3d)

# full.data = read.table("features.csv", header = T, sep = "\t")
# all = full.data
# 
# full.data$label[full.data$label == 1] = 1
# full.data$label[full.data$label == 2] = 0
#
# set.seed(10000)
# #split into 25% test and 75% training
# pos = which(full.data$label == 1)
# test.pos = sample(pos, length(pos) * .25, replace=F)
# neg = which(full.data$label == 0)
# test.neg = sample(neg, length(neg) * .25, replace=F)
# 
# 
# test = full.data[c(test.pos, test.neg), ]
# training = full.data[-c(test.pos, test.neg), ]
# write.table()
set.seed(as.integer(Sys.time()))

training = read.table("train.dat")
test = read.table("test.dat")
# correction = read.table("features.csv", header = T, sep = "\t")
# correction$label = 1
# # errror recording id 35959731 => 2413555298
# idx = which(training$user.id == 35959731 )
# 
# bad = which(training$delay.10th == 0 | training$in.degree == 0 | training$out.degree == 0)
# training = training[-(bad),]
# 
# bad = which(test$delay.10th == 0 | test$in.degree == 0 | test$out.degree == 0)
# test = test[-(bad), ]

all = rbind(training, test)

remove.cols = function(tab) {
  return (tab[, !(colnames(tab) %in% c("drug", "user.id", "time.offsetted", "total.tweets", "num.tweets", "cohort_name"))])
}

training = remove.cols(training)
test = remove.cols(test)
training[idx, ] = remove.cols(correction)
full.data = rbind(training, test)


lab2err = function(labels, predictions) 
{
  t = table(factor(labels, levels=c(0, 1)), factor(predictions, levels=c(0 , 1)))
  tp = t[2, 2]
  tn = t[1, 1]
  fn = t[2, 1]
  fp = t[1, 2]
  return (c(tn, tp, fp, fn))
}

# Naive Bayes

train.Bayes.args = list(laplace=1)

train.Bayes = function(training.data, training.labels, arguments = train.Bayes.args ) {
  bayes.model = naiveBayes( training.data,
                            y = as.factor(training.labels), 
                            laplace = arguments$laplace)
  return(bayes.model)
  
}

test.Bayes = function (model, test.data, test.labels, arguments=NA){
  bayes.pred = predict(model, test.data, type = "class")
  return (lab2err(test.labels, bayes.pred))
}

# svm

train.svm.args = list(kernel="radial", gamma=0.01, C=1, cw=c("1"=3, "0"=1))

train.svm = function(training.data, 
                     training.labels, 
                     arguments = svm.train.args ) 
{
  svm.model = svm(training.data,
                  as.factor(training.labels),
                  kernel = arguments$kernel,
                  cost=arguments$C, # cost for misclassification. Higher 
                  # values reduces tolerance for misclasses
                  scale=F,
                  #class.weights=arguments$cw,
                  gamma = arguments$gamma # "width" of the kernel
  )
  return(svm.model)
}

test.svm = function(svm.model, 
                    test.data, test.labels,
                    arguments= NA)
{
  svm.pred = predict(svm.model, test.data, type = "class")
  return(lab2err(test.labels, svm.pred))
}

# Neural Network 

train.nn.args = list(
  stepmax = 1e+05, # training epochs
  threshold = 0.01,
  hidden = c(1),
  learning.rate = list(minus=0.2, plus=1.3)
)

train.nn = function(training.data, training.labels,
                    arguments = train.nn.args)
{
  nn.formula = as.formula( paste("label ~", paste(colnames(training.data), collapse=" + ")) )
  nn.model = neuralnet(nn.formula, cbind(label=training.labels, training.data),
                       hidden = arguments$hidden, 
                       stepmax = arguments$stepmax,
                       learningrate = arguments$learning.rate,
                       threshold = arguments$threshold)
  return (nn.model)
}

test.nn.args = list(threshold=0.5)

test.nn = function(model, test.data, test.labels, arguments = test.nn.args) {
  nn.pred = compute(x=model, cbind(test.data))$net.result
  nn.pred[nn.pred < arguments$threshold] = 0
  nn.pred[nn.pred >= arguments$threshold] = 1
  return(lab2err(test.labels, nn.pred))
}

# (tn, tp, fp, fn)
format.results = function (evals) {
  results = data.frame(
    precision = evals[2]  / sum(evals[2:3]),
    recall = evals[2] / (evals[2] + evals[4]), 
    accuracy = sum(evals[1:2]) / sum(evals[1:4]),
    wacc = 0.5 * evals[1] / (evals[1] + evals[3]) + 0.5 * evals[2] / (evals[2] + evals[4])
  )
  if(is.nan(results$precision) || results$precision == 0 || results$recall == 0){
    results$precision = 0
    results$f1 = 0
  } else{
    results$f1 = 2 * results$precision * results$recall / ((results$precision + results$recall))
  }
  return (results)
}

# train.fn is a function object with signature (train.data,  )
# train.fn(train.data, train.labels train.args) -> model
# test.fn(model, test.data, test.labels, test.args) -> (tn, tp, fn, fp)
# test.fn returns a list (tn, tp, fp, fn)
kfold.cv = function(train.fn, test.fn, dataset, k, train.args=NA, test.args=NA) {
  pos = which(dataset$label == 1)   
  pos.len = length(pos)
  neg = which(dataset$label == 0)
  neg.len = length(neg)
  posOrdering = sample(pos, pos.len, replace=F)
  negOrdering = sample(neg, neg.len, replace=F)
  evals = c(0, 0, 0, 0)
  for (i in 1:k) {
    holdout.neg = negOrdering[ceiling((i-1)*(neg.len / k)):floor((i)*(neg.len / k))]     
    holdout.pos = posOrdering[ceiling((i-1)*(pos.len / k)):floor((i)*(pos.len / k))]     
    test.cv = dataset[c(holdout.neg, holdout.pos), ]
    train.cv = dataset[-c(holdout.neg, holdout.pos), ] 
    
    test.cv.lbls = test.cv$label
    train.cv.lbls = train.cv$label
    
    train.cv = train.cv[, !(colnames(train.cv) %in% c("label"))]
    test.cv = test.cv[, !(colnames(test.cv) %in% c("label"))]
    
    model = train.fn(train.cv, train.cv.lbls, train.args)
    evals = evals + test.fn(model, test.cv, test.cv.lbls, test.args)
  }
  return (format.results(evals))
}

avg.kfold = function (train.fn, test.fn, dataset, k, train.args=NA, test.args=NA, n = 5) {
  df = NA
  for (i in 1:n){
    r = kfold.cv(train.fn, test.fn, dataset, k, train.args, test.args)
    if (is.na(df)){
      df = r
    } else {
      df = rbind(df, r)
    }
  }
  return (df)
}

train.scaled = data.frame(cbind(label=training$label, scale(removeLabels(training))))

deltas = c("delay.10th", "delay.25th", "delay.50th", "delay.75th", "delay.90th") 
train.logged = training
train.logged[, deltas] = log(train.logged[, deltas] + 1, 10)

train.logged.scaled = data.frame(cbind(label=training$label, scale(removeLabels(train.logged))))

train.feat = removeLabels(training)
pca = prcomp(x=train.feat, center=T, scale.=T)
train.pca = cbind(label=training$label, data.frame(pca$x))
train.pca.99 = train.pca[, 1:23]
train.pca.95 = train.pca[, 1:19]
train.pca.90 = train.pca[, 1:16]
train.pca.85 = train.pca[, 1:14]
train.pca.80 = train.pca[, 1:12]
train.pca.75 = train.pca[, 1:9]

train.feat = train.logged[, !(colnames(training) %in% c("label"))]
pca = prcomp(x=train.feat, center=T, scale.=T)
train.logged.pca = cbind(label=training$label, data.frame(pca$x))

# ======================
# Tuning
# ======================

# print(kfold.cv(train.Bayes, test.Bayes, training, 5, train.Bayes.args))
# print(kfold.cv(train.svm, test.svm, training, 5, train.svm.args))
#print(kfold.cv(train.nn, test.nn, training, 5, train.nn.args, test.nn.args))

# print(kfold.cv(train.Bayes, test.Bayes, train.pca, 5, train.Bayes.args))
# print(kfold.cv(train.svm, test.svm, train.pca, 5, train.svm.args))
# print(kfold.cv(train.nn, test.nn, train.pca, 5, train.nn.args, test.nn.args))
# 
# print(kfold.cv(train.Bayes, test.Bayes, train.logged, 5, train.Bayes.args))
# print(kfold.cv(train.svm, test.svm, train.logged, 5, train.svm.args))
# print(kfold.cv(train.nn, test.nn, train.logged, 5, train.nn.args, test.nn.args))

gammas = 2 ^ seq(from=-10, to=-4.5, by=0.5) 
Cs      = 2 ^ seq(from=3, to=8, by = 0.5)

plot(0, 0, xlim = c(0., 0.05), ylim=c(0.4, 0.8))
best = rbind(c(0, 0, 0), c(0,0,0))
max.f1 = c(0, 0, 0)
max.sd = c(0, 0, 0)
w.max = 1
for (j in Cs) {
  r.tab = c() 
  for (i in gammas) {
    train.svm.args$gamma = i
    train.svm.args$C = j
    results = avg.kfold(train.svm, test.svm, train.pca, 5, train.svm.args, n=50)
    # print(results)
    a.results = apply(results, 2, mean)
    sd.results = apply(results, 2, sd)
    r.tab = rbind(r.tab, a.results)
    if (a.results['f1'] > max.f1[w.max]) {
      max.f1[w.max] = a.results['f1']
      max.sd[w.max] = sd.results['f1']
      best[, w.max] = c(j, i)
      w.max = which.min(max.f1)
    }
  }
  lines(x=gammas, y=r.tab[, "f1"])  
} 
 
print(best)
print(max.f1)
print(max.sd)

train.svm.args$gamma = 2^-8
train.svm.args$C = 2^8
results = avg.kfold(train.svm, test.svm, train.pca.95, 5, train.svm.args, n=50)
# print(results)
a.results = apply(results, 2, mean)
sd.results = apply(results, 2, sd)
print (a.results)
print (sd.results)


# laplace = c(2.0)
# plot(0, 0, xlim = c(1, 29), ylim=c(0, 1.0))
# pcs = 1:28
# best = rbind(c(0, 0, 0))
# max.f1 = c(0, 0, 0)
# max.sd = c(0, 0, 0)
# w.max = 1
# r.tab = c()
# for (j in pcs) { 
#   train.Bayes.args$laplace = 2.0
#   results = avg.kfold(train.Bayes, test.Bayes, train.logged.pca[, 1:(j+1)], 5, train.Bayes.args, n=10)
#   print(results)
#   a.results = apply(results, 2, mean)
#   sd.results = apply(results, 2, sd)
#   r.tab = rbind(r.tab, a.results)
#   if (a.results['f1'] > max.f1[w.max]) {
#     max.f1[w.max] = a.results['f1']
#     max.sd[w.max] = sd.results['f1']
#     best[, w.max] = c(j)
#     w.max = which.min(max.f1)
#   }
# } 
# 
# lines(x=1:28, y=r.tab[, 'f1'])
# 
# print (best)
# print (max.sd)
# print (max.f1)

r.tab = NULL
results = avg.kfold(train.Bayes, test.Bayes, train.logged.pca, 5, train.Bayes.args, n=50)
  print(results)
  a.results = apply(results, 2, mean)
  sd.results = apply(results, 2, sd)
  r.tab = rbind(r.tab, a.results)
results = avg.kfold(train.Bayes, test.Bayes, train.logged, 5, train.Bayes.args, n=50)

a.results = apply(results, 2, mean)
sd.results = apply(results, 2, sd)
r.tab = rbind(r.tab, a.results)
results = avg.kfold(train.Bayes, test.Bayes, train.pca, 5, train.Bayes.args, n=50)

a.results = apply(results, 2, mean)
sd.results = apply(results, 2, sd)
r.tab = rbind(r.tab, a.results)
results = avg.kfold(train.Bayes, test.Bayes, training, 5, train.Bayes.args, n=50)

a.results = apply(results, 2, mean)
sd.results = apply(results, 2, sd)
r.tab = rbind(r.tab, a.results)

# train nueral net
# need to set training time, network structure and prediction threshold
epochs=c(5000, 10000, 5e4, 1e5)
structures = list(
  c(1),
  c(1, 1),
  c(2)#,
 # c(3),
  #c(2, 2)#,
 #c(3, 2),
  #c(7, 3),
  #c(7, 7),
  #c(14, 7)
  #c(29, 1),
  #c(29, 14)#,
  #c(29, 14, 1),
  #c(29, 29),
  #c(29, 29, 1),
  #c(29, 14, 7)
  #c(29, 29, 29),
)
thresholds = seq(0, 1, by=0.01)
plot(0, 0, xlim = c(1, 29), ylim=c(0, 1.0))
best = rbind(c(0, 0, 0))
max.f1 = c(0, 0, 0)
max.sd = c(0, 0, 0)
w.max = 1
r.tab = c()
# for (j in 1:length(structures)) { 
#   train.nn.args$stepmax = 1e5
#   train.nn.args$threshold = 1e-3
#   train.nn.args$hidden = structures[[j]]
#   test.nn.args$threshold = 0.5
#   results = avg.kfold(train.nn, test.nn, train.pca, 5, train.nn.args, test.nn.args, n=5)
#   print(results)
#   a.results = apply(results, 2, mean)
#   sd.results = apply(results, 2, sd)
#   r.tab = rbind(r.tab, a.results)
#   if (a.results['f1'] > max.f1[w.max]) {
#     max.f1[w.max] = a.results['f1']
#     max.sd[w.max] = sd.results['f1']
#     best[, w.max] = j
#     w.max = which.min(max.f1)
#   }
# } 
# 
# train.nn.args$hidden = structures[[1]]
# results = avg.kfold(train.nn, test.nn, train.pca, 5, train.nn.args, test.nn.args, n=5)
# a.results = apply(results, 2, mean)
# sd.results = apply(results, 2, sd)
# 
# print(a.results)
# print(sd.results)
# print (best)
# print (max.sd)
# print (max.f1)


train.nn.args$stepmax = 1e5
train.nn.args$threshold = 1e-3
train.nn.args$hidden = c(1)
test.nn.args$threshold = 0.5
results = avg.kfold(train.nn, test.nn, train.pca, 5, train.nn.args, test.nn.args, n=20)
print(results)
a.results = apply(results, 2, mean)
sd.results = apply(results, 2, sd)
# 
print(a.results)
print(sd.results)

# ==============================
# End tuning
# ==============================

## 
# rank features for naive bayes, the better the separation, the more informative the feature
# naive bayes is making an assumption that the features are gaussian and 
# conditionally independent, so t-test gives a reasonable approximation of how important the feature 
# is to the model.
# Since the conditions naive bayes assumes are clearly violated, a more appropriate test is 
# wilcoxon, so we do that as well for comparison.  
tab = NULL
tab2 = NULL
t.pos = which(training$label == 1)
t.neg = which(training$label == 0)
for (col in colnames(training)) {
  if (col == "label"){
    next
  }
  t = wilcox.test(train.logged[t.pos, col], train.logged[t.neg, col])

  t2 = t.test(train.logged[t.pos, col], train.logged[t.neg, col])
  
  row = c(col, t$statistic, t$p.value)
  tab = rbind(tab, row)
  row = c(col, t2$statistic, t2$p.value)
  tab2 = rbind(tab2, row)
}
tab = tab[order(as.double(tab[, 3])), ]
tab2 = tab2[order(as.double(tab2[, 3])), ]

tab = cbind(tab, p.adjust(as.double(tab[, 3]), method="BH"))

##
# testing for final report

ntrain = nrow(training)
ntest = nrow(test)
all = rbind(training, test)
deltas = c("delay.10th", "delay.25th", "delay.50th", "delay.75th", "delay.90th") 

all.scaled = data.frame(cbind(label = all$label, scale(removeLabels(all))))
tr.scaled = all.scaled[1:ntrain, ]
te.scaled = all.scaled[-(1:ntrain), ]


ds.logged = all
ds.logged[, deltas] = log(ds.logged[, deltas] + 1, 10)
tr.logged = ds.logged[1:ntrain, ]
te.logged = ds.logged[-(1:ntrain), ]

ds.feat = removeLabels(all)
pca = prcomp(x=ds.feat, center=T, scale.=T)
ds.pca = cbind(label=all$label, data.frame(pca$x))
tr.pca = ds.pca[1:ntrain, ]
te.pca = ds.pca[-(1:ntrain), ]

# 23 => 99%
# 18 => 95%
# 15 => 90%
# 13 => 85%
tr.pca.95 = ds.pca[1:ntrain, 1:23]
te.pca.95 = ds.pca[-(1:ntrain), 1:23]

# ds.feat = ds.logged[, !(colnames(training) %in% c("label"))]
# pca = prcomp(x=ds.feat, center=T, scale.=T)
# ds.logged.pca = cbind(label=all$label, data.frame(pca$x))
# tr.logged.pca = ds.logged.pca[1:ntrain, ]
# te.logged.pca = ds.logged.pca[-(1:ntrain), ]

# tuned parameters
train.svm.args$gamma = 2^-9
train.svm.args$C     = 2^8

train.Bayes.args$laplace = 2.0

train.nn.args$stepmax = 1e5
train.nn.args$threshold = 1e-3
train.nn.args$hidden = c(1)
test.nn.args$threshold = 0.5
print ("NAIVE BAYES")
nb.model = train.Bayes(removeLabels(tr.logged), tr.logged$label, train.Bayes.args)
nb.result = test.Bayes(nb.model, removeLabels(te.logged), te.logged$label)
print(format.results(nb.result))

print("\nSVM PCA")
train.svm.args$gamma = 2^-8
train.svm.args$C     = 2^8
svm.model = train.svm(removeLabels(tr.pca), tr.pca$label, train.svm.args)
svm.result = test.svm(svm.model, removeLabels(te.pca), te.pca$label) 
print(format.results(svm.result))

print("SVM PCA 95")
train.svm.args$gamma = 2^-8
train.svm.args$C = 2^8
svm.model = train.svm(removeLabels(tr.pca.95), tr.pca$label, train.svm.args)
svm.result = test.svm(svm.model, removeLabels(te.pca.95), te.pca$label)
print(format.results(svm.result))

print("SVM UNTRANSFORMED")
train.svm.args$gamma = 2^-8
train.svm.args$C = 2^8
svm.model = train.svm(removeLabels(training), tr.pca$label, train.svm.args)
svm.result = test.svm(svm.model, removeLabels(test), te.pca$label)
print(format.results(svm.result))

print("\nANN")
nn.model = train.nn(removeLabels(tr.pca), tr.pca$label, arguments=train.nn.args)
test.nn.args$threshold = 0.5
nn.result = test.nn(nn.model, removeLabels(te.pca), te.pca$label, test.nn.args)

print(format.results(nn.result))
# 
# # Logistic regression just for fun
# model = cv.glmnet(as.matrix(removeLabels(tr.logged)), as.factor(tr.pca$label), family="binomial")
# pred = as.integer(predict(model, as.matrix(removeLabels(te.logged)), type='response') > 0.5)
# logit.result = lab2err(te.logged$label, pred)
# 
# print(format.results(logit.result))


# ds.feat = all[, !(colnames(all) %in% c("label"))]
# pca = prcomp(x=ds.feat, center=T, scale.=T)
# ds.pca = cbind(label=all$label, data.frame(pca$x))
# tr.pca = ds.pca[1:ntrain, ]
# te.pca = ds.pca[-(1:ntrain), ]

# dir_guess = predict(svm.model, removeLabels(director), type="class")
# 
# pred = as.integer(predict(model, as.matrix(removeLabels(te.logged)), type='response') > 0.5)
# 

# 
# #visualize PCA
# library(scatterplot3d)
# for (i in (1:36)*10) {
#   scatterplot3d(tr.pca[, c(2,3,4)],
#                 pch=tr.pca$label + 2, 
#                 color=tr.pca$label + 3, 
#                 angle=i, 
#                 box=T, highlight.3d=F, 
#                 type="h")
#   Sys.sleep(0.8)
# }
