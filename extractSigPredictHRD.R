#!/opt/conda/bin/Rscript

options(stringsAsFactors=F) # to avoid invalid factor level warning

args <- commandArgs(TRUE)

  workingDir <- args[1]
  sampleName <- args[2]
   snvIndVcf <- args[3]
       svVcf <- args[4]
refGenomeVsn <- args[5] # RG_37 or RG_38
   sigOutTxt <- paste0( workingDir, '/', sampleName, '_chord_signatures.txt')
   prdOutTxt <- paste0( workingDir, '/', sampleName, '_chord_prediction.txt')

cat("[INFO] START CHORD signature extraction and HRD prediction", "\n")
setwd(workingDir)

suppressPackageStartupMessages(library('devtools'))
suppressPackageStartupMessages(library('randomForest'))
suppressPackageStartupMessages(library('mutSigExtractor'))
suppressPackageStartupMessages(library('CHORD'))

cat("[INFO] Package NamespaceVersions after loading:\n")
for (pkgName in c("mutSigExtractor", "CHORD")){
  pkgVsn=getNamespaceVersion(pkgName)[["version"]]
  cat("[INFO]   Package", pkgName, "has version", pkgVsn, "\n")
}

## Convert genome name to BSGenome name
if (refGenomeVsn == "RG_37") {
  suppressPackageStartupMessages(library(BSgenome.Hsapiens.UCSC.hg19))
  refGenome <- BSgenome.Hsapiens.UCSC.hg19
} else if (refGenomeVsn == "RG_38") {
  suppressPackageStartupMessages(library(BSgenome.Hsapiens.UCSC.hg38))
  refGenome <- BSgenome.Hsapiens.UCSC.hg38
} else {
  stop("Unsupported ref genome version: ", refGenomeVsn," (should be HG37 or HG38)\n")
}

cat("[INFO] CHORD Settings:\n")
cat("[INFO]   Working dir:", workingDir, "\n")
cat("[INFO]   Sample name:", sampleName, "\n")
cat("[INFO]   Somatic SNV/IND vcf:", snvIndVcf, "\n")
cat("[INFO]   Somatic SV vcf:", svVcf, "\n")
cat("[INFO]   Ref Genome Version:", refGenomeVsn, "\n")
cat("[INFO]   Signature out file:", sigOutTxt, "\n")
cat("[INFO]   Prediction out file:", prdOutTxt, "\n")

## Extract signature counts and predict HRD
cat("[INFO] Performing chord signature extraction\n")
signatures <- extractSigsChord(
  vcf.snv = snvIndVcf,
  vcf.indel = snvIndVcf,
  vcf.sv = svVcf,
  sample.name = sampleName,
  sv.caller = "gridss",
  vcf.filters=list(snv="PASS", indel="PASS", sv="PASS"),
  ref.genome=refGenome
)
cat("[INFO] Performing chord HRD prediction\n")
prediction <- chordPredict(
  signatures,
  rf.model = CHORD,
  hrd.cutoff = 0.5
)

## Output
cat("[INFO] Writing output file:", sigOutTxt,"\n")
write.table(signatures, file=sigOutTxt, sep="\t")

cat("[INFO] Writing output file:", prdOutTxt,"\n")
write.table(prediction, file=prdOutTxt, sep="\t", quote=FALSE, row.names=FALSE)

cat("[INFO] FINISHED CHORD signature extraction and HRD prediction\n")