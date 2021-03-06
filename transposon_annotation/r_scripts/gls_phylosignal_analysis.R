library(picante)

## GLS and PGLS
allsuperfam.dat <- read.table("all_15_species_te-superfamilies_cval_raw_bp_counts_tab.tsv.txt",header=T,sep="\t",row.names=1)
superfam.gls <- gls(GenomeSize ~ Gypsy, data = allsuperfam.dat)
superfam.pgls <- gls(GenomeSize ~ Gypsy, correlation = corBrownian(value = 1, tre), data = allsuperfam.dat)
anova(superfam.pgls)

## plot gypsy against genome size
dat.superfam <- read.table("all_15_species_te-superfamilies_cval_raw_bp_counts_tab.tsv.txt",header=T,sep="\t",row.names=1)
gyp.gls <- gls(Gypsy ~ GenomeSize, data = allsuperfam.dat)
gyp.pgls <- gls(Gypsy ~ GenomeSize, correlation = corBrownian(value = 1, tre), data = allsuperfam.dat)

plot(Gypsy ~ GenomeSize, data = dat.superfam, pch = 21, bg = "black",xaxt="n",yaxt="n", 
	   xlab="Genome size (Mbp)",ylab="Gyspy coverage in base pairs (millions)")
abline(coef(gyp.gls), lwd = 3, col = "black")
abline(coef(gyp.pgls), lwd = 3, col = "red")
axis(2, at=c(500000000, 1000000000, 1500000000,2000000000, 2500000000), labels=c(500, 1000, 1500, 2000, 2500))
axis(1, at=c(2000000000, 2500000000, 3000000000, 3500000000, 4000000000), labels=c(2000, 2500, 3000, 3500, 4000))
legend("topleft", legend = c("GLS fit", "Phylogenetic GLS fit"), lwd = 2, col = c("black","red"))

## Kcalc
tre <- read.tree("ape_tree_15_aster_species")
dat <- read.table("all_15_species_te-families_cval_raw_bp_counts_tab_for_picante.txt",row.names=1,header=T,sep="")
fam_Kcalc_stats <- apply(dat, 2, Kcalc, tre)
fam_multiphylosignal_stats <- multiPhylosignal(dat, multi2di(tre))

superfam.dat <- read.table("all_15_species_te-superfamilies_cval_raw_bp_counts_tab_for_picante.txt",row.names=1,header=T,sep="\t")
superfam_Kcalc_stats <- apply(superfam.dat, 2, Kcalc, tre)
superfam_mulitphylosignal_stats <- multiPhylosignal(superfam.dat, multi2di(tre))