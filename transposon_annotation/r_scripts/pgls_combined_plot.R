allsuperfam.dat <- read.table("all_15_species_te-superfamilies_cval_raw_bp_counts_tab.tsv.txt",header=T,sep="\t",row.names=1)

options(scipen=10)
par(mfrow=c(2,1), mai=c(1.1,1.1,0.5,0.5))
superfam.gyp.gls <- gls(Gypsy ~ GenomeSize, data = allsuperfam.dat)
superfam.gyp.pgls <- gls(Gypsy ~ GenomeSize, correlation = corBrownian(value = 1, tre), data = allsuperfam.dat)
plot(Gypsy ~ GenomeSize, data = allsuperfam.dat, cex.axis=0.6,col="darkgreen",pch=20,cex=1.6,xaxt = "n", yaxt = "n", ylab = "Gypsy genome coverage (Mbp)", xlab = "")
axis(1, at = c(2000000000,2500000000,3000000000,3500000000,4000000000), labels = c(2000,2500,3000,3500,4000))
axis(2, at = c(0,500000000,1000000000,1500000000,2000000000,2500000000), labels = c(0,500,1000,1500,2000,2500))
abline(coef(superfam.gyp.gls), lwd = 2, col = "black")
abline(coef(superfam.gyp.pgls), lwd = 2, col = "red")
legend(2000000000, 2500000000, c("GLS", "PGLS"), lty=c(1,1),cex=0.8,col=c("black","red"))

superfam.cop.gls <- gls(Copia ~ GenomeSize, data = allsuperfam.dat)
superfam.cop.pgls <- gls(Copia ~ GenomeSize, correlation = corBrownian(value = 1, tre), data = allsuperfam.dat)
plot(Copia ~ GenomeSize, data = allsuperfam.dat, cex.axis=0.6,col="aquamarine4",pch=20,cex=1.6,xaxt = "n", yaxt = "n", xlab = "Genome size (Mbp)", ylab = "Copia genome coverage (Mbp)")
axis(1, at = c(2000000000,2500000000,3000000000,3500000000,4000000000), labels = c(2000,2500,3000,3500,4000))
axis(2, at = c(0,250000000,500000000,750000000,1000000000,1250000000), labels = c(0,250,500,750,1000,1250))
abline(coef(superfam.cop.gls), lwd = 2, col = "black")
abline(coef(superfam.cop.pgls), lwd = 2, col = "red")
legend(2000000000, 1000000000, c("GLS", "PGLS"), lty=c(1,1),cex=0.8,col=c("black","red"))