# pca plot
# Jon Tatum

n = 100
chars = c(rep(16, n-2), 18, 17)
cols = c(rep(8, n-2), 3, 4)
cex = c(rep(0.75, n-2), 2, 2)
data = mvrnorm(n, mu=c(1, 1), Sigma=0.3*rbind(c(1,0.8),
                                            c(0.8,1)) )
plot(c(0,1), c(0,1), cex=1, pch=1, xlim=c(-3, 3), ylim=(c(-3,3)))
points(data, col=cols, pch=chars, cex = cex)
pca = prcomp(data, scale.=T)
plot(c(0), c(0), cex=1, pch=1, xlim=c(-3, 3), ylim=(c(-3,3)))
points(pca$x, xlim=c(-3, 3), ylim=c(-3,3), col=cols, pch=chars, cex = cex )
