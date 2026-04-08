# 3. 单细胞GWAS分析 (Single-cell GWAS Analysis)

单细胞和空间转录组分析模块，整合单细胞eQTL、空间转录组数据进行GWAS功能解读。

## 模块说明

### 3.1 动态免疫单细胞SMR分析
```r
# 批量单细胞SMR分析
# 相关模块: OmniGWAS/batch_smr_dynamic/

?easyGWAS::batch_xqtl_smr
easyGWAS::batch_xqtl_smr(
  out_filename = "E:/mr/HCC/GWAS/eur/HCC_full_outcome.rds",
  id_outcome = NULL,
  outcome_name = "HCC",
  xqtl_resource = "CD4_Memory_stim_16h",
  xqtl_type = "sc_eqtl",
  smr_multi = FALSE,
  pval = 5e-08,
  diff_freq_prop = 0.9,
  diff_freq = 0.2,
  ancestry = "EUR",
  MAF = NULL,
  quick_smr = TRUE,
  smr_HEIDI_p = 0.05,
  only_gene = FALSE,
  plot_col = "#B4D151",
  plot_highlight.col = "#8680C0",
  save_path = "E:/mr/HCC/smr/sc_eqtl/dynamic/"
)

# 可用的单细胞资源:
# CD4_STIM, CD4_NAIVE, CD8_NAIVE, CD8_STIM, M2, B_CELL_NAIVE, NK_dice
# TREG_NAIVE, TFH, TH17, TH1, TH2, TREG_MEM, THSTAR, MONOCYTES

# 动态时间点单细胞资源:
# TN_0h, TN_16h, TN_40h, TN_5d
# TCM_0h, TCM_16h, TCM_40h, TCM_5d
# TEM_0h, TEM_16h, TEM_40h, TEM_5d
# CD4_Memory_stim_16h, CD4_Memory_stim_40h, CD4_Memory_stim_5d
# nTreg_0h, nTreg_16h, nTreg_40h
```

### 3.2 pQTL单细胞SMR
```r
# 蛋白数量性状基因座(pQTL) SMR分析
easyGWAS::batch_xqtl_smr(
  out_filename = "E:/mr/comorbidity/POAG_myopia/GWAS/Myopia.rds",
  id_outcome = NULL,
  outcome_name = "Myopia",
  xqtl_resource = "loya_H",
  xqtl_type = "pqtl",
  smr_multi = FALSE,
  pval = 5e-08,
  diff_freq_prop = 0.9,
  diff_freq = 0.2,
  ancestry = "EUR",
  MAF = NULL,
  quick_smr = TRUE,
  smr_HEIDI_p = 0.05,
  only_gene = FALSE,
  save_path = "E:/mr/comorbidity/POAG_myopia/smr/pqtl/"
)

# 可用的pQTL资源:
# decode_2021, Sun_BB, Suhre_k, Pietzner_4979, loya_H, Gudjonsson_A_protei_4782
```

### 3.3 mQTL单细胞SMR
```r
# DNA甲基化QTL(mQTL) SMR分析
easyGWAS::batch_xqtl_smr(
  out_filename = "E:/mr/comorbidity/POAG_myopia/GWAS/POAG.rds",
  id_outcome = NULL,
  outcome_name = "POAG",
  xqtl_resource = "godmc_mqtl",
  xqtl_type = "mqtl",
  smr_multi = FALSE,
  pval = 5e-08,
  diff_freq_prop = 0.9,
  diff_freq = 0.2,
  ancestry = "EUR",
  MAF = NULL,
  quick_smr = TRUE,
  smr_HEIDI_p = 0.05,
  only_gene = FALSE,
  save_path = "E:/mr/comorbidity/POAG_myopia/smr/mqtl/"
)

# 可用的mQTL资源:
# godmc_mqtl, ROSMAP_mqtl, EUR_mqtl
```

### 3.4 eQTL单细胞SMR
```r
# 表达数量性状基因座(eQTL) SMR分析
easyGWAS::batch_xqtl_smr(
  out_filename = "E:/mr/comorbidity/POAG_myopia/GWAS/POAG.rds",
  id_outcome = NULL,
  outcome_name = "POAG",
  xqtl_resource = "Whole_Blood",
  xqtl_type = "eqtl",
  smr_multi = FALSE,
  pval = 5e-08,
  diff_freq_prop = 0.9,
  diff_freq = 0.2,
  ancestry = "EUR",
  MAF = NULL,
  quick_smr = TRUE,
  smr_HEIDI_p = 0.05,
  only_gene = FALSE,
  save_path = "E:/mr/comorbidity/POAG_myopia/smr/eqtl/"
)

# 组织资源:
GTEX_v8_info$Tissue
onek1k_samplesize_info$Cell.id
```

### 3.5 多组学SMR分析
```r
# 多组学MR分析
res_e <- easyGWAS::multi_omic_MR(
  out_filename = "E:/mr/liver/HCC/GWAS_meta/liver_cancer_metal_metal_full_outcome.rds",
  outcome_name = 'LC',
  gene_set_name = "endoplasmic_reticulum_stress_related_gene",
  xqtl_resource = "eQTLGen",
  clump_r2 = 0.01,
  get_mr = TRUE,
  run_MRPRESSO = TRUE,
  run_steiger_filtering = TRUE,
  run_smr_plot = TRUE,
  run_coloc = TRUE,
  get_smr = TRUE,
  clump_pval = 5e-8,
  proxies = FALSE,
  smr_multi = FALSE,
  coloc_kb = 1000,
  query_pval = 1,
  xqtl_build = 37,
  outcome_build = 37,
  lead_SNP = FALSE,
  core = 10,
  save_path = "E:/mr/test/multiomic/eQTLGen/"
)

# 多组学SMR
?multi_omic_SMR
multi_omic_SMR(
  pqtl_resource = "decode_2021",
  mqtl_resource = "LBC_BSGS_meta",
  eqtl_resource = "eQTLGen",
  tissue = NULL,
  gene_set_name = "ChEMBL_actionable_gene",
  gene_set_list = NULL,
  smr_multi = FALSE,
  smr_pval = 5e-08,
  MAF = 0.01,
  cis_wind = 1000,
  smr_wind = 1000,
  diff_freq = 0.2,
  diff_freq_prop = 0.05,
  HEIDI_pval = 0.00157,
  run_smr_plot = FALSE,
  run_coloc = FALSE,
  lead_SNP = FALSE,
  clump_kb = 10000,
  clump_r2 = 0.001,
  clump_pval = 5e-08,
  NbD = 1000,
  core = 20,
  run_MR = TRUE,
  save_path = "E:/mr/eye/glaucoma/multiomics/"
)
```

### 3.6 miRNA-xQTL MR分析
```r
# miRNA与xQTL的MR分析
?miRNA_xqtl_MR
miRNA_xqtl_MR(
  miRNA = "hsa-miR-139-3p",
  miRNA_mr_kb = 1000,
  miRNA_coloc_kb = 1000,
  miRNA_resource = "miRNA_Nikpay_2019",
  xqtl = "ENSG00000186642",
  xqtl_resource = "eQTLGen",
  xqtl_build = 37,
  tissue = NULL,
  clump_r2 = 0.001,
  clump_kb = 10000,
  pval_out = 5e-08,
  f_cutoff = 10,
  clump_pval = 5e-08,
  NbD = 1000,
  core = 4,
  run_steiger_filtering = FALSE,
  p1 = 1e-04,
  p2 = 1e-04,
  p12 = 1e-05,
  smr_multi = FALSE,
  smr_pval = 5e-08,
  MAF = 0.01,
  cis_wind = 1000,
  smr_wind = 1000,
  HEIDI_pval = 0.00157,
  ld_upper = 0.9,
  ld_lower = 0.05,
  LD = FALSE,
  save_path = "E:/mr/test/"
)
```

### 3.7 批量SMR分析
```r
# 批量bin-based SMR
?batch_run_smr
res2 <- batch_run_smr(
  filename = "E:/mr/HCC/GWAS/eur/HCC_full_outcome.rds",
  trait_name = "HCC",
  eqtl_resource = "bin",
  save_path = "E:/mr/HCC/smr/bin/"
)

# 多组学MR (通用函数)
res_eqtl <- easyGWAS::multi_omic_MR(
  out_filename = "E:/mr/liver/fibrosis_cirrhosis/gwas_meta/Fibrosis_and_cirrhosis_metal_metal_full_outcome.rds",
  outcome_name = 'Fibrosis_and_cirrhosis_metal_metal',
  gene_set_name = "positive_gene_list",
  gene_set_list = NULL,
  xqtl_resource = "eQTLGen",
  clump_r2 = 0.01,
  get_mr = TRUE,
  get_smr = TRUE,
  clump_pval = 5e-8,
  MAF = NULL,
  core = 2,
  run_steiger_filtering = TRUE,
  run_smr_plot = TRUE,
  run_MRPRESSO = TRUE,
  proxies = FALSE,
  smr_multi = TRUE,
  coloc_kb = 1000,
  query_pval = 1,
  xqtl_build = 37,
  outcome_build = 37,
  lead_SNP = FALSE,
  save_path = "E:/mr/liver/fibrosis_cirrhosis/multiomics/eqtl/"
)
```

### 3.8 单细胞虚拟敲除
```r
# scTenifoldKnk单细胞基因虚拟敲除分析
library(dplyr)
library(Seurat)
library(scTenifoldKnk)
library(ggplot2)
library(ggrepel)

# 加载单细胞数据
mmRNA_harmony <- readRDS("mmRNA_harmony2.rds")

# 提取count矩阵
countMatrix <- GetAssayData(mmRNA_harmony, slot = "counts")

# 运行虚拟敲除
result <- scTenifoldKnk(
  countMatrix = countMatrix,
  gKO = 'cxcl2',  # 敲除基因
  qc_mtThreshold = 0.1,
  qc_minLSize = 1000,
  nc_nNet = 10,
  nc_nCells = 500,
  nc_nComp = 3
)

# 保存结果
saveRDS(result, "scTenifoldKnk_GAB1_KO_results.rds")

# 可视化
top_genes <- head(result$diffRegulation[order(-result$diffRegulation$FC), ], 20)

p1 <- ggplot(top_genes, aes(x = reorder(gene, FC), y = FC)) +
  geom_bar(stat = 'identity', fill = 'steelblue') +
  coord_flip() +
  labs(title = "Top 20 Differentially Regulated Genes",
       x = "Gene", y = "Fold Change") +
  theme_minimal()

pdf("top20_genes_barplot.pdf", width = 10, height = 8)
print(p1)
dev.off()

# 火山图
df <- result$diffRegulation
df$log_pval <- -log10(df$p.adj)
label_genes <- subset(df, abs(Z) > 2 & p.adj < 0.01)

p2 <- ggplot(df, aes(x = Z, y = log_pval)) +
  geom_point(alpha = 0.5) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red") +
  geom_vline(xintercept = c(-2, 2), linetype = "dashed", color = "blue") +
  geom_text_repel(data = label_genes, aes(label = gene), size = 3) +
  labs(title = "Virtual Knockout: Z-score vs -log10(adjusted p-value)") +
  theme_classic()

pdf("volcano_plot.pdf", width = 12, height = 8)
print(p2)
dev.off()
```

## 关联模块

- `batch_smr_dynamic/` - 动态免疫单细胞SMR分析
- `batch_gsmap/` - 空间转录组gsMap分析

## 依赖包

```r
library(easyGWAS)
library(easyMR)
library(Seurat)
library(scTenifoldKnk)
```
