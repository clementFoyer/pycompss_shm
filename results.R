#!/usr/bin/env R
##
## install extra packages
## and load them
##install.packages("splitstackshape")
##install.packages("tidyverse")
##install.packages("plot3D")
##install.packages("sqldf")
##install.packages("scatterplot3d")
##install.packages("ggplot2")

library(readr)
library(tidyr)
library(dplyr)
library(sqldf)
library(plot3D)
library(tidyverse)
library(splitstackshape)
library(scatterplot3d)
library(ggplot2)

setwd("pycompss_shm")

###########################################################################################
### MATRIX MULTIPLICATION

## LOADING FUNCTIONS
load_file_result <- function (filename) read_csv(filename,
                                                 col_names = c("nblocks","blocksize", "nnodes","with_shm","time"), comment = "#",
                                                 col_types = cols(col_number(), col_number(), col_number(), col_character(), col_double()))

get_order <- function (df) with(df[ c("nblocks","blocksize","nnodes") ],
                                order(blocksize, nblocks, nnodes))

get_uniques <- function (df) unique(df[ get_order(df), c("nblocks","blocksize","nnodes") ])

## PLOTING FUNCTIONS
opt_boxplot_nologx <- function (results,title,subtitle) {
  ggplot(data=results,
         mapping=aes(x=interaction(nblocks,blocksize,nnodes),
                     y=time,
                     group=interaction(nblocks,blocksize,nnodes,with_shm),
                     color=with_shm), notch=FALSE) +
    scale_y_continuous(trans='log2') +
    ylab("Time (s)") +
    xlab("Dimensions (#blocks, block size, #nodes)") +
    labs(colour = "With or without SHM") +
    guides(colour=guide_legend(order=2), shape=guide_legend(order=1)) +
    theme(legend.justification=c(0,1), legend.position=c(0,1)) + labs(title=title) + labs(subtitle=subtitle)
}

results=load_file_result("matmul_results/results.csv")
results2=load_file_result("matmul_results/results.2.csv")
results3=load_file_result("matmul_results/results.allscratch.csv")

## T-TEST for each of the possible cases


apply_t.test <- function (df) apply(get_uniques(df), 1,
                                    function (x, df) (
                                      function (df,nblk,blksz,nnd)
                                        t.test(time~with_shm, alternative="two.sided", paired=FALSE,
                                               data=subset(df, nblocks==nblk & blocksize==blksz & nnodes==nnd)
                                        )
                                    ) (df, x[1], x[2], x[3]), df=df)

apply_t.test (results)
apply_t.test (results2)
apply_t.test (results3)

opt_boxplot_nologx(results, "Timings", "With master data on GPFS, workers data on scratch") + geom_boxplot()
opt_boxplot_nologx(results2, "Timings", "With selection of arrays, master data on GPFS, workers data on scratch") + geom_boxplot()
opt_boxplot_nologx(results3, "Timings", "With selection of arrays, all data on scratch disks") + geom_boxplot()


apply_mean <- function (df) apply(get_uniques(df), 1,
                                    function (x, df) (
                                      function (df,nblk,blksz,nnd) (
                                          aggregate(time~with_shm, mean,
                                               data=subset(df, nblocks==nblk & blocksize==blksz & nnodes==nnd))
                                      )
                                    ) (df, x[1], x[2], x[3]), df=df)

apply_mean (results)
apply_mean (results2)
apply_mean (results3)

get_count <- function (df) {
  apply(get_uniques(df), 1,
        function (x, df) (
          function (df,nblk,blksz,nnd) nrow(df[df$nblocks==nblk & df$blocksize==blksz & df$nnodes==nnd,])
        ) (df, x[1], x[2], x[3]), df=df)
}

bind_result_to_sizes <- function (df) {
  cbind(get_uniques(df),
        (function (list_of_res) t(sapply(list_of_res,
                                         function (x) cbind(x$estimate[[1]],
                                                            x$estimate[[2]],
                                                            x$conf.int[1],
                                                            x$conf.int[2],
                                                            x$p.value)
        ))) (apply_t.test (df)),
        get_count(df[df$with_shm=='with',]),
        get_count(df[df$with_shm=='without',])
  )
}

get_significants <- function (df) {
  (function (df) subset(df, (df$'3' < 0 & df$'4' < 0) | (df$'3' > 0 & df$'4' > 0))) (bind_result_to_sizes(df))
}

format.tex.row <- function (df) {
  apply(df, 1,
        function (x) (
          sprintf(paste("\\rowcolor{%s}\n\\rownumber{}\\label{tab:matmul} & %d & %d & %.3f & %.3f & %.3f & %.3f & %",
                        ifelse(x[8] < 0.01, "8.3e", "8.7f"), " & %d & %d & %5f & %5f & %5f", sep=""),
                  ifelse((x[6] < 0 & x[7] < 0) | (x[6] > 0 & x[7] > 0),
                         ifelse(x[4] < x[5], "green!50", "red!50"),
                         "black!50"),
                  x[1], x[2], x[4], x[5], x[6], x[7], x[8], x[9], x[10],
                  100*x[6]/x[5], 100*(x[4]-x[5])/x[5], 100*x[7]/x[5])
        )
  )
}

print.tex.table <- function (df) {
  cat(reduce(format.tex.row(df),
             function(a,b) cat(a,b,' \\\\\n', sep=""),
             .init=paste('\\begin{tabular}{*{3}{c}*{5}{r}}\n\\toprule\n',
                         'ID & \\#blocks & block size & time with & time without & ',
                         '\\multicolumn{2}{c}{conf.\\@ inter.\\@ inf.\\@ and sup.\\@} &',
                         'p-value \\\\\n\\midrule\n',
                         sep='')),
      '\\bottomrule\n\\end{tabular}', sep="")
}

data.frame.select_significants <- function (df) {
  do.call("rbind", apply(get_uniques(get_significants(df)), 1,
                         function (x, df) (
                           function (df, nblk, blksz, nnd)
                             subset(df, nblocks==nblk & blocksize==blksz & nnodes==nnd)
                         ) (df, x[1], x[2], x[3]), df=df))
}

print.tex.table(get_significants(results3))

opt_boxplot_nologx(data.frame.select_significants(results3),
                   "Timings (Significant cases only)",
                   "With selection of arrays, all data on scratch disks") + geom_boxplot()


###########################################################################################
### KMEANS

## LOADING FUNCTIONS
kmeans.load_file_result <- function (filename) read_csv(filename,
                                                 col_names = c("npoints","maxiter", "ndims", "ncentres", "nfrags", "nnodes","with_shm","time"), comment = "#",
                                                 col_types = cols(col_number(), col_number(), col_number(), col_number(), col_number(), col_number(), col_character(), col_double()))

kmeans.get_order <- function (df) with(df[ c("npoints","maxiter","ndims", "ncentres", "nfrags", "nnodes") ],
                                order(ncentres, maxiter, ndims, npoints))

kmeans.get_uniques <- function (df) unique(df[ kmeans.get_order(df), c("npoints","maxiter","ndims", "ncentres", "nfrags", "nnodes") ])

## PLOTING FUNCTIONS

kmeans.opt_boxplot_nologx_nology <- function (results,title,subtitle) {
  ggplot(data=results,
         mapping=aes(x=interaction(npoints, ndims, maxiter, ncentres),
                     y=time,
                     group=interaction(maxiter, npoints, ndims, ncentres, with_shm),
                     color=with_shm), notch=FALSE) +
    ylab("Time (s)") +
    xlab("Dimensions (#points, #dimensions, max. iterations, #centres)") +
    labs(colour = "With or without SHM") +
    guides(colour=guide_legend(order=2), shape=guide_legend(order=1)) +
    theme(legend.justification=c(0,1), legend.position=c(0,1), legend.direction="horizontal") +
    labs(title=title) + labs(subtitle=subtitle)
}

kmeans.opt_boxplot_nologx <- function (results,title,subtitle) {
  kmeans.opt_boxplot_nologx_nology(results, title, subtitle) +
    scale_y_continuous(trans='log2')
}

kmeans.results=kmeans.load_file_result("kmeans_results/results.csv")

## T-TEST for each of the possible cases

kmeans.apply_t.test <- function (df) apply(kmeans.get_uniques(df), 1,
                                    function (x, df) (
                                      function (df,npts,maxit,nd,nc,nfrg,nnd)
                                        t.test(time~with_shm, alternative="two.sided", paired=FALSE,
                                               data=subset(df, npoints==npts & maxiter==maxit & nnodes==nnd & ndims==nd & ncentres==nc & nfrags==nfrg)
                                        )
                                    ) (df, x[1], x[2], x[3], x[4], x[5], x[6]), df=df)

kmeans.apply_t.test (kmeans.results)


kmeans.opt_boxplot_nologx(kmeans.results, "Timings", "With selection of arrays, all data on scratch disks") + geom_boxplot()


kmeans.apply_mean <- function (df) apply(kmeans.get_uniques(df), 1,
                                  function (x, df) (
                                    function (df,npts,maxit,nd,nc,nfrg,nnd) (
                                      aggregate(time~with_shm, mean,
                                                data=subset(df, npoints==npts & maxiter==maxit & nnodes==nnd & ndims==nd & ncentres==nc & nfrags==nfrg))
                                    )
                                  ) (df, x[1], x[2], x[3], x[4], x[5], x[6]), df=df)

kmeans.apply_mean (kmeans.results)

kmeans.get_count <- function (df) {
  apply(kmeans.get_uniques(df), 1,
        function (x, df) (
          function (df,npts,maxit,nd,nc,nfrg,nnd) (
            nrow(df[df$npoints==npts & df$maxiter==maxit & df$nnodes==nnd & df$ndims==nd & df$ncentres==nc & df$nfrags==nfrg,])
          )
        ) (df, x[1], x[2], x[3], x[4], x[5], x[6]), df=df)
}

kmeans.bind_result_to_sizes <- function (df) {
  cbind(kmeans.get_uniques(df),
        (function (list_of_res) t(sapply(list_of_res,
                                         function (x) cbind(x$estimate[[1]],
                                                            x$estimate[[2]],
                                                            x$conf.int[1],
                                                            x$conf.int[2],
                                                            x$p.value)
        ))) (kmeans.apply_t.test (df)),
        kmeans.get_count(df[df$with_shm=='with',]),
        kmeans.get_count(df[df$with_shm=='without',])
  )
}

kmeans.get_significants <- function (df) {
  (function (df) subset(df, (df$'3' < 0 & df$'4' < 0) | (df$'3' > 0 & df$'4' > 0))) (kmeans.bind_result_to_sizes(df))
}

kmeans.format.tex.row <- function (df) {
  apply(df, 1,
        function (x) (
          sprintf(paste("\\rowcolor{%s}\n\\rownumber{}\\label{tab:km} & %d & %d & %d & %d & %.3f & %.3f & %.3f & %.3f & %",
                        ifelse(x[11] < 0.01, "8.3e", "8.7f"), " & %d & %d & %5f & %5f & %5f",
                        sep=""),
                  ifelse((x[9] < 0 & x[10] < 0) | (x[9] > 0 & x[10] > 0),
                         ifelse(x[7] < x[8], "green!50", "red!50"),
                         "black!50"),
                  x[1], x[2], x[3], x[4], x[7], x[8], x[9], x[10], x[11],
                  x[12], x[13], 100*x[9]/x[8], 100*(x[7]-x[8])/x[8], 100*x[10]/x[8])
        )
  )
}

kmeans.print.tex.table <- function (df) {
  cat(reduce(kmeans.format.tex.row(df),
             function(a,b) cat(a,b,' \\\\\n', sep=""),
             .init=paste('\\begin{tabular}{*{5}{c}*{5}{r}}\n\\toprule\n',
                         'ID & \\#points & max.\\@ iter & \\#dims & \\#centres & time with & time without & ',
                         '\\multicolumn{2}{c}{conf.\\@ inter.\\@ inf.\\@ \\& sup.\\@} &',
                         'p-value \\\\\n\\midrule\n',
                         sep='')),
      '\\bottomrule\n\\end{tabular}', sep="")
}

kmeans.data.frame.select_significants <- function (df) {
  do.call("rbind", apply(kmeans.get_significants(df), 1,
                         function (x, df) (
                           function (df, npts, maxit, nd, nc, nfrg, nnd)
                             subset(df, npoints==npts & maxiter==maxit & nnodes==nnd & ndims==nd & ncentres==nc & nfrags==nfrg & ncentres > 1)
                         ) (df, x[1], x[2], x[3], x[4], x[5], x[6]), df=df))
}

kmeans.print.tex.table(kmeans.bind_result_to_sizes(kmeans.results))

kmeans.opt_boxplot_nologx_nology_bw <- function(results,title,subtitle) {
  kmeans.opt_boxplot_nologx_nology(results,title,subtitle) +
    scale_fill_grey(start = 0, end = .9) + theme_bw() + theme(legend.direction="vertical")
}

kmeans.opt_boxplot_nologx_bw <- function(results,title,subtitle) {
  kmeans.opt_boxplot_nologx(results,title,subtitle) +
    scale_fill_grey(start = 0, end = .9) + theme_bw() + theme(legend.direction="vertical")
}

kmeans.opt_boxplot_nologx_bw(kmeans.data.frame.select_significants(kmeans.results), "Timings (significant cases only)", "With selection of arrays, all data on scratch disks") + geom_boxplot()

kmeans.select_case_center <- function(df) subset(df, npoints==4194304 & maxiter==20 & nnodes==2 & ndims==64 & nfrags==16)
kmeans.select_case_npoints <- function(df) subset(df, maxiter==20 & nnodes==2 & ndims==64 & nfrags==16 & ncentres==4)
kmeans.select_case_ndims <- function(df) subset(df, ((npoints==4194304 | npoints==8388608) & (ndims==64 | ndims==128)) & maxiter==20 & nnodes==2 & nfrags==16 & ncentres==4)
kmeans.select_case_maxiter <- function(df) subset(df, npoints==4194304 & nnodes==2 & ndims==64 & nfrags==16 & ncentres==4)

kmeans.opt_boxplot_nologx_bw(kmeans.select_case_center(kmeans.results), "Timings - Comparison w.r.t. #centres", "With selection of arrays, all data on scratch disks") + geom_boxplot()
kmeans.opt_boxplot_nologx_nology_bw(kmeans.select_case_npoints(kmeans.results), "Timings - Comparison w.r.t. #points", "With selection of arrays, all data on scratch disks") + geom_boxplot()
kmeans.opt_boxplot_nologx_bw(kmeans.select_case_npoints(kmeans.results), "Timings - Comparison w.r.t. #points", "With selection of arrays, all data on scratch disks") + geom_boxplot()
kmeans.opt_boxplot_nologx_bw(kmeans.select_case_ndims(kmeans.results), "Timings - Comparison w.r.t. #dims", "With selection of arrays, all data on scratch disks") + geom_boxplot()
kmeans.opt_boxplot_nologx_bw(kmeans.select_case_maxiter(kmeans.results), "Timings - Comparison w.r.t. max. number of iterations", "With selection of arrays, all data on scratch disks") + geom_boxplot()


