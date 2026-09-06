# RNA-seq Analysis of Cerebellar Transcriptional Changes Following Influenza A Infection in *Mus musculus*

## Abstract

This project implemented a reproducible RNA-sequencing workflow to investigate transcriptional differences between non-infected mouse cerebellum and cerebellum sampled following Influenza A infection. Five publicly available RNA-seq samples from NCBI GEO/SRA study GSE96870 were analysed, comprising three Day 0 non-infected controls and two Day 4 Influenza A-infected samples.

The workflow included SRA data retrieval, sequence quality control, read preprocessing, reference-genome alignment, gene-level quantification and differential-expression analysis. Reads were aligned to the *Mus musculus* GRCm39 reference genome using HISAT2, and all five samples achieved overall alignment rates above 99%. Gene-level counts were generated using featureCounts with the Ensembl release 116 annotation. Following low-count filtering, 19,911 genes were tested using DESeq2. Two genes met the predefined significance threshold of adjusted p-value < 0.05 and absolute log2 fold change >= 1. Both significant genes were upregulated in Day 4 Influenza A samples, while no significant downregulated genes were detected.

The results demonstrate a detectable but limited transcriptional response under the analysed comparison. Interpretation is constrained by the small and unbalanced sample design, particularly the presence of only two infected biological replicates.

## 1. Introduction

RNA sequencing provides transcriptome-wide measurement of gene expression and is widely used to investigate molecular responses to infection and other biological perturbations. Influenza A infection can induce host transcriptional responses involving antiviral defence, immune signalling and tissue-specific responses.

This project analysed publicly available RNA-seq data from GSE96870 to compare gene expression in mouse cerebellum between Day 0 non-infected controls and Day 4 Influenza A-infected samples.

The primary objective was to construct and document a reproducible RNA-seq workflow encompassing data acquisition, quality control, alignment, read quantification and differential-expression analysis.

## 2. Materials and Methods

### 2.1 Dataset and experimental design

Five *Mus musculus* cerebellum RNA-seq samples were analysed:

| Condition | Samples | n |
|---|---|---:|
| Day 0 non-infected cerebellum | SRR5364316, SRR5364317, SRR5364322 | 3 |
| Day 4 Influenza A cerebellum | SRR5364318, SRR5364323 | 2 |

The study therefore used an unbalanced 3:2 design. All five biological samples were retained because unequal replicate numbers can be modelled by DESeq2 and there was no analytical justification for excluding the additional control replicate.

### 2.2 Data acquisition and quality control

SRA run identifiers were stored in `data/metadata/SRR_accessions.txt`, while sample-level experimental metadata were stored in `data/metadata/sample_info.tsv`.

Sequencing data were retrieved using NCBI SRA Toolkit. `prefetch` was used for SRA download and `fasterq-dump` for conversion to FASTQ. Raw sequencing reads were assessed using FastQC. Reads were processed with fastp for adapter and quality trimming where necessary, followed by FastQC of trimmed reads. MultiQC was used to aggregate QC results across samples.

QC interpretation focused on metrics including per-base sequence quality, adapter content and sequence duplication.

### 2.3 Reference genome and alignment

Trimmed reads were aligned to the *Mus musculus* GRCm39 reference genome using HISAT2. SAM output was piped directly into samtools to generate sorted BAM files, reducing unnecessary disk usage.

The observed overall HISAT2 alignment rates were:

| Sample | Overall alignment rate | Status |
|---|---:|---|
| SRR5364316 | 99.46% | PASS |
| SRR5364317 | 99.43% | PASS |
| SRR5364318 | 99.37% | PASS |
| SRR5364322 | 99.38% | PASS |
| SRR5364323 | 99.43% | PASS |

All samples exceeded the predefined 75% minimum alignment-rate threshold.

### 2.4 Gene-level quantification

Gene-level counts were generated from sorted BAM files using featureCounts from the Subread package. Reads were assigned to exon features and summarised using Ensembl gene identifiers from the *Mus musculus* GRCm39 Ensembl release 116 GTF annotation.

Assigned read counts were:

| Sample | Assigned reads/fragments |
|---|---:|
| SRR5364316 | 35,361,258 |
| SRR5364317 | 32,975,367 |
| SRR5364318 | 34,010,818 |
| SRR5364322 | 41,502,425 |
| SRR5364323 | 35,425,622 |

A simplified gene-by-sample count matrix was generated for downstream statistical analysis.

### 2.5 Differential-expression analysis

Differential-expression analysis was conducted in R using DESeq2. Raw count data were combined with sample metadata using a design formula of:

`~ Condition`

The reference condition was Day 0 non-infected cerebellum, and the treatment condition was Day 4 Influenza A cerebellum.

Low-count genes were filtered prior to modelling. Significant differentially expressed genes were defined using:

- adjusted p-value < 0.05
- absolute log2 fold change >= 1

Variance-stabilising transformation was applied for visualisation and export of normalised expression values.

PCA, MA, volcano and heatmap plots were generated to assess sample structure and differential-expression patterns.

## 3. Results

### 3.1 Alignment performance

All five samples aligned strongly to the GRCm39 reference genome, with overall alignment rates ranging from 99.37% to 99.46%. No sample fell below the 75% QC threshold.

The consistently high rates indicate strong compatibility between the sequencing reads and the selected mouse reference genome and suggest that poor alignment was unlikely to be a major source of downstream analytical bias.

### 3.2 Gene-level read assignment

featureCounts successfully assigned tens of millions of reads or fragments to annotated genes in every sample. Assigned counts ranged from 32,975,367 in SRR5364317 to 41,502,425 in SRR5364322.

The presence of substantial gene-assigned read counts across all samples provided sufficient count depth for differential-expression modelling.

### 3.3 Differential gene expression

Following filtering, 19,911 genes were tested.

| Metric | Result |
|---|---:|
| Total genes tested | 19,911 |
| Significant DEGs | 2 |
| Upregulated | 2 |
| Downregulated | 0 |

The two significant genes were:

| Gene ID | Base mean | log2 fold change | Adjusted p-value | Direction |
|---|---:|---:|---:|---|
| ENSMUSG00000033880 | 798.16 | 1.328 | 1.02 × 10^-30 | Up |
| ENSMUSG00000079017 | 87.43 | 1.204 | 3.92 × 10^-18 | Up |

Both genes showed increased expression in Day 4 Influenza A cerebellum compared with Day 0 non-infected controls.

A log2 fold change of 1.328 corresponds to approximately 2.51-fold higher expression, while a log2 fold change of 1.204 corresponds to approximately 2.30-fold higher expression.

### 3.4 Principal-component analysis

The PCA indicated that PC1 explained 48% of variance and PC2 explained 29%, meaning the first two principal components together represented approximately 77% of the observed variance.

The samples did not show complete separation by experimental condition. This suggests that biological condition was an important but not exclusive source of variability and that additional biological or technical variation may be present.

**Figure 1. Principal-component analysis of VST-transformed gene-expression data.**  
Samples are coloured by experimental condition. PC1 explains 48% of variance and PC2 explains 29%.

### 3.5 MA plot

The MA plot showed that most genes had log2 fold-change estimates close to zero across a wide range of mean normalised expression values.

This suggests that broad transcriptome-wide changes were limited under the analysed comparison and that only a small proportion of genes showed large expression differences.

**Figure 2. MA plot for Day 4 Influenza A versus Day 0 non-infected cerebellum.**

### 3.6 Volcano plot

The volcano plot showed only two genes that simultaneously met the adjusted p-value and absolute log2 fold-change thresholds. Both occurred on the positive fold-change side of the plot, consistent with upregulation in the infected group.

**Figure 3. Volcano plot of differential expression.**  
Significant genes are highlighted according to adjusted p-value < 0.05 and |log2FC| >= 1.

### 3.7 Heatmap of significant DEGs

The heatmap of the two significant genes demonstrated higher relative expression in Day 4 Influenza A samples compared with Day 0 controls.

The infected samples grouped together in the heatmap, although the overall five-sample clustering did not show complete condition-based separation. This is consistent with the PCA evidence of within-condition variability.

**Figure 4. Heatmap of significant differentially expressed genes.**  
Row-scaled VST expression values are shown for the two significant genes across the five samples.

## 4. Discussion

The analysis identified a limited but statistically strong differential-expression signature between Day 4 Influenza A-infected and Day 0 non-infected mouse cerebellum.

Only two of 19,911 tested genes satisfied both the adjusted p-value and fold-change criteria. Both genes were upregulated, with estimated expression increases of approximately 2.5-fold and 2.3-fold.

The restricted number of significant genes suggests that the detected transcriptional difference was relatively focused under the analysed conditions. However, it would be inappropriate to infer specific biological pathways from only two significant genes without first mapping the Ensembl identifiers to gene symbols and reviewing their established biological functions.

The high alignment rates across all samples provide confidence that poor reference matching was not responsible for the limited number of significant DEGs. Similarly, substantial gene-assigned read counts were obtained for every sample.

The PCA nevertheless indicates notable sample-level heterogeneity. Combined with the small sample size, this likely reduces statistical power for detecting more subtle transcriptional differences.

Conventional over-representation analysis using only the two significant genes would have very limited power. A ranked gene-set enrichment method such as GSEA may therefore be more appropriate for exploring pathway-level trends using the full ranked gene list.

## 5. Limitations

The principal limitation is the small sample size. Only five biological samples were analysed, comprising three controls and two infected samples. Although DESeq2 accommodates unequal replicate numbers, only two infected replicates provide limited information for estimating biological variability.

The analysis also focuses on a single Day 4 versus Day 0 comparison and therefore does not characterise temporal transcriptional dynamics beyond these two conditions.

Only two genes passed the selected significance criteria, which substantially limits conventional functional enrichment analysis.

Finally, the PCA demonstrates within-condition heterogeneity, suggesting that unmeasured biological or technical variables may contribute to the observed expression variation.

## 6. Conclusion

This project successfully implemented an end-to-end reproducible RNA-seq workflow using publicly available *Mus musculus* cerebellum data.

All five samples achieved HISAT2 alignment rates above 99%, and featureCounts assigned approximately 33–42 million reads or fragments per sample to annotated genomic features.

DESeq2 tested 19,911 genes and identified two significantly upregulated genes in Day 4 Influenza A cerebellum compared with Day 0 non-infected controls. No significant downregulated genes were detected.

The project demonstrates practical competence in SRA data retrieval, sequencing quality control, Bash scripting, reference-genome alignment, BAM processing, gene quantification, R-based differential-expression analysis, statistical visualisation, Git version control and reproducible bioinformatics workflow design.

Further analysis should prioritise gene annotation and ranked functional enrichment to investigate whether coordinated biological pathways are detectable beyond the small set of individually significant genes.