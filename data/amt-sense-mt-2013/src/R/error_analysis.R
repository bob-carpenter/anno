# error_analysis.R  visualize data

libraryDir <- path.expand("~/anno/src/R");
source(file.path(libraryDir,"anno_fns.R",fsep=.Platform$file.sep));


dataDir <- path.expand("~/anno/data/amt-sense-mt-2013/munged");
erranDir <- path.expand("~/anno/data/amt-sense-mt-2013/error_analysis");

wordFiles <- list.files(path=dataDir,pattern = "\\.tsv");
W <- length(wordFiles);
words <- wordFiles;

for (w in 1:W) {
    print(w);
    words[w] <- sub("\\.[[:alnum:]]+$", "",words[w]);
    print(words[w]);

    dataFile <- file.path(dataDir,wordFiles[w],fsep=.Platform$file.sep);
    dfData <- get_data(dataFile);
    dfVotes <- get_votes(dfData);
    errorFileName  <- paste(words[w],"-leastagree.txt",sep="");
    errorFile <- file.path(erranDir,errorFileName,fsep=.Platform$file.sep);
    write_lowest(dfVotes,50,errorFile);
}

