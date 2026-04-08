# 2. 多组学GWAS分析 (Multi-omics GWAS Analysis)

多组学整合分析模块，整合eQTL、pQTL、mQTL等组学数据与GWAS进行联合分析。

## 模块说明

### 2.1 GTEx数据提取
```r
# 本地提取eQTLGen可药物靶点数据
?get_druggable_gene_eqtlgen_data
exp_eqtlgen <- get_druggable_gene_eqtlgen_data(
  kb = 100,
  pval = 1,
  clump_kb = 10000,
  clump_r2 = 0.1,
  remove_F10_SNP = TRUE,
  save_path = "E:/mr/comorbidity/POAG_myopia/eqtlgen/"
)

# 提取GTEx V8基因数据
data1 <- easyGWAS::get_gtex_v8_allpairs_gene_data(
  gene_name = "PCSK9",
  tissue = "Whole_Blood",
  kb = 1000,
  pval = 1,
  maf = 0.005,
  build = 38,
  save_path = "E:/mr/test/GTEx_V8/"
)

# 在线提取GTEx V8完整数据
data2 <- get_full_gtex_v8_gene_data(
  gene_name = "PCSK9",
  tissue = "Whole_Blood",
  kb = 1000,
  pval = 1,
  maf = 0.005,
  build = 38,
  save_path = "E:/mr/test/GTEx_V8/"
)

# 提取显著变异-基因对
GTEx_V8_CSF1R <- get_GTEx_V8_significant_variant_gene_pairs_data(
  gene_name = "CSF1R",
  tissue = "Whole_Blood",
  cross_tissue = FALSE,
  pval = 1e-04,
  build = 38
)
```

### 2.2 PsychENCODE数据
```r
# 提取PsychENCODE靶点数据
exp2 <- easyMR::psychencode_targe_data(
  gene_names = "A2MP1",
  kb = NULL,
  pval = 1,
  save_path = "E:/mr/test/psychencode/"
)

# 提取完整PsychENCODE数据
exp1 <- easyGWAS::get_full_psychencode_data(
  gene_name = "A2MP1",
  kb = NULL,
  pval = 1,
  save_path = "E:/mr/test/psychencode/"
)
```

### 2.3 TWAS分析
```r
# 安装MetaXcan
easyGWAS::install_metaxcan()

# 查看可用模型
easyMR::GTEX_v8_info
easyGWAS:::SPrediXcan_model

# SPrediXcan分析 (单组织)
easyGWAS:::SPrediXcan_model(
  filename = "E:/mr/comorbidity/HCC_sarcopenia/GWAS/Sarcopenia_EWGSOP_full_outcome.rds",
  trait_name = "Sarcopenia_EWGSOP",
  snp = "SNP",
  model = "UTMOST",
  effect_allele = "effect_allele.outcome",
  other_allele = "other_allele.outcome",
  eaf = "eaf.outcome",
  beta = "beta.outcome",
  se = "se.outcome",
  pval = "pval.outcome",
  core = 4,
  save_path = "E:/mr/comorbidity/HCC_sarcopenia/TWAS/"
)

# SMulTiXcan分析 (跨组织)
?SMulTiXcan_model
easyGWAS:::SMulTiXcan_model(
  trait_name = "Sarcopenia_EWGSOP",
  model = "en",
  imputation_gwas = "E:/mr/comorbidity/HCC_sarcopenia/TWAS/Sarcopenia_EWGSOP.txt.gz",
  save_path = "E:/mr/comorbidity/HCC_sarcopenia/TWAS/"
)

# UTMOST格式准备
?UTMOST_format
UTMOST_format(
  filename = "E:/mr/comorbidity/POAG_myopia/GWAS/POAG.rds",
  trait_name = "POAG",
  save_path = "E:/mr/comorbidity/POAG_myopia/UTMOST/POAG/"
)

# UTMOST单组织关联分析
UTMOST_single_tissue_association(
  file_name = "E:/mr/comorbidity/POAG_myopia/UTMOST/POAG/POAG.txt",
  trait_name = "POAG",
  core = 10,
  save_path = "E:/mr/comorbidity/POAG_myopia/UTMOST/POAG/"
)
```

### 2.4 HESS分析
```r
# HESS格式准备
?hess_format
hess_format(
  filename = "E:/mr/comorbidity/POAG_myopia/GWAS/POAG.rds",
  trait_name = "POAG",
  save_path = "E:/mr/comorbidity/POAG_myopia/HESS/"
)

hess_format(
  filename = "E:/mr/comorbidity/POAG_myopia/GWAS/Myopia.rds",
  trait_name = "Myopia",
  save_path = "E:/mr/comorbidity/POAG_myopia/HESS/"
)

# HESS分析
res_hess <- run_hess(
  gwas_list = c(
    "E:/mr/comorbidity/POAG_myopia/HESS/POAG.sumstats",
    "E:/mr/comorbidity/POAG_myopia/HESS/Myopia.sumstats"
  ),
  save_path = "E:/mr/comorbidity/POAG_myopia/HESS/"
)
```

### 2.5 MR-JTI分析
```r
# MR-JTI跨组织分析
run_MR_JTI(
  gene_list = c("FGD6", "STARD13", "SLC22A5"),
  tissue = "Adipose_Subcutaneous",
  pval = 1,
  kb = 1000,
  build = 38,
  out_filename = "E:/mr/liver/HCC/GWAS_meta/liver_cancer_metal_metal_full_outcome.rds",
  outcome_id = NULL,
  outcome_data = NULL,
  outcome_name = "LC",
  clump_r2 = 0.01,
  n_snps = 20,
  n_folds = 5,
  n_gene = 1,
  n_bootstrap = 500,
  maf = NULL,
  save_path = "E:/mr/test/cross_tissue/"
)

# 跨组织数据提取
data2 <- get_cross_tissue_data(
  target = "SGLT2_inhibition",
  gene_names = "SLC5A2",
  id_outcome = NULL,
  outcome_file = "E:/mr/liver/HCC/GWAS_meta/liver_cancer_metal_metal_full_outcome.rds",
  outcome_dat = NULL,
  pval_threshold = 5e-8,
  remove_duplicate_SNP = FALSE,
  remove_tissue = FALSE,
  tissue = FALSE,
  kb = 500,
  ld_local = TRUE,
  r2_threshold = 0.7,
  pval_out = 1e-4,
  clump_r2 = 0.8,
  clump_local = TRUE,
  save_path = "E:/mr/test/cross_tissue/"
)
```

### 2.6 XWAS/FUSION分析
```r
# XWAS格式准备
?xwas_fusion
multi_ldsc(
  trait_list_gwas = "E:/mr/HCC/GWAS/eur/HCC_full_outcome.rds",
  remove_MHC = FALSE,
  save_path = "E:/mr/HCC/XWAS/"
)

# XWAS分析
xwas_fusion(
  trait_name = "HCC",
  sumstats_file = "E:/mr/HCC/XWAS/HCC.sumstats.gz",
  weight_tissue = "GTExv8.EUR.Whole_Blood",
  chr_num1 = 1,
  chr_num2 = 22,
  coloc_pval = 0.05,
  force_model = NA,
  perm = 1e+05,
  max_impute = 0.5,
  min_r2pred = 0.7,
  perm_minp = 0.05,
  remove_MHC = FALSE,
  perform_pwas_conditional = TRUE,
  save_path = "E:/mr/HCC/XWAS/"
)

# 条件分析
xwas_fusion_conditional(
  trait_name = "HCC",
  xwas = "TWAS",
  chr_num1 = 1,
  chr_num2 = 22,
  locus_win = 1e+06,
  pval = 0.05,
  max_r2 = 0.9,
  min_r2 = 0.008,
  eqtl_model = "top1",
  plot_legend = "all",
  omnibus_corr = NA,
  omnibus = FALSE,
  save_path = "E:/mr/HCC/XWAS/"
)

# XWAS可视化
xwas_fusion_plot(
  trait_name = "HCC",
  xwas = "TWAS",
  chr_num1 = 1,
  chr_num2 = 22,
  weight_tissue = "GTExv8.EUR.Whole_Blood",
  sig_pval = 0.05,
  window = 0.5e6,
  build = 38,
  width = 2000,
  height = 1250,
  save_path = "E:/mr/HCC/XWAS/"
)

xwas_manhattan_plot(
  filename = "E:/mr/HCC/XWAS/HCC-gene.tsv.GW",
  pval = "TWAS.P",
  save_path = "E:/mr/HCC/XWAS",
  plot.type = "m"
)
```

### 2.7 蛋白组学XWAS
```r
# 批量XWAS FUSION分析
?batch_xwas_fusion
batch_xwas_fusion(
  gwas_file = "E:/mr/proteomics/HCC/HCC.sumstats.gz",
  trait_name = "HCC",
  weight_tissue = c("INTERVAL.PPC.nofilter", "UKB_Olink"),
  ncores = 8,
  save_path = "E:/mr/proteomics/HCC/"
)

# EWAS权重分析
batch_xwas_fusion(
  gwas_file = "E:/mr/HCC/XWAS/HCC.sumstats.gz",
  trait_name = "HCC",
  weight_tissue = "EWAS-weights",
  coloc_P = 0.05,
  ncores = 10,
  remove_MHC = FALSE,
  save_path = "E:/mr/HCC/XWAS/EWAS/"
)
```

## 依赖包

```r
library(easyGWAS)
library(easyMR)
```
