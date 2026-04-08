# 1. 基础GWAS分析 (Basic GWAS Analysis)

基础GWAS分析模块包含核心的GWAS数据处理、质量控制、位点提取和基本统计分析功能。

## 模块说明

本模块基于 **easyGWAS** R包开发，主要功能包括：

### 1.1 环境配置
```r
library(easyGWAS)
library(devtools)

# 安装本地R包
devtools::install_local('C:/Users/onekey/TwoSampleMR.zip')
remotes::install_github("mrcieu/ieugwasr")

# 配置OpenGWAS API密钥
Sys.setenv(OPENGWAS_JWT = "your_jwt_token")
TwoSampleMR::extract_instruments(outcomes = "ieu-a-300")
```

### 1.2 GWAS位点提取
```r
# 从GWAS结果提取显著位点
?get_loci
HCC_loci <- get_loci(
  data = NULL,
  outcome_file = "E:/mr/HCC/GWAS/eur/HCC_full_outcome.rds",
  ld_clump = TRUE,
  kb = 500,
  p_threshold = 5e-08,
  remove_MHC = TRUE,
  pop = "EUR",
  ld_clump_r2 = 0.01
)

# 提取最近的基因
?get_nearest_gene
nearest_gene_HCC <- get_nearest_gene(variants = HCC_loci, build = 37, kb = 100)
```

### 1.3 格式转换
```r
# GWAS数据格式转换
?convert_format
convert_format(
  gwas_file = "E:/mr/HCC/GWAS/eur/HCC_full_outcome.rds",
  remove_region = "['6:25119106-33854733']",
  trans_csv = FALSE,
  save_path = "E:/mr/HCC/loci/"
)

# 批量提取位点
?get_loci2
get_loci2(
  sumstats_file = "E:/mr/HCC/loci/HCC.txt.gz",
  out_name = "HCC",
  exclude_ranges = "6:25119106-33854733",
  clump_p1 = 5e-08,
  indep_r2 = 0.6,
  lead_r2 = 0.1,
  ld_window_kb = 10000,
  loci_merge_kb = 250,
  save_path = "E:/mr/HCC/loci/"
)
```

### 1.4 GWAS Meta分析
```r
# 数据格式转换 (liftover)
easyMR::liftover_convert_data(
  filename = "E:/mr/comorbidity/glaucoma_myopia/Myopia.rds",
  trait_name = "Myopia",
  SNP_col = "SNP",
  chrom_col = "chr.outcome",
  start_col = "pos.outcome",
  ref_genome = "hg38",
  convert_ref_genome = "hg19",
  save_path = "E:/mr/comorbidity/glaucoma_myopia/gwas_meta/"
)

# Meta分析
?metal_gwas
easyGWAS::metal_gwas(
  type = "outcome",
  filename.list = c(
    "E:/mr/comorbidity/glaucoma_myopia/gwas_meta/Myopia_hg19.rds",
    "E:/mr/comorbidity/glaucoma_myopia/Glaucoma.rds"
  ),
  trait_name = "Glaucoma_Myopia",
  ivw_meta_column = "samplesize",
  trans_beta_resource = "wingo",
  data_type = "binary",
  save_path = "E:/mr/comorbidity/glaucoma_myopia/gwas_meta/"
)
```

### 1.5 MAGMA基因分析
```r
?run_magmar
run_magmar(
  outcome_file = "E:/mr/comorbidity/HCC_sarcopenia/GWAS/Sarcopenia_EWGSOP_full_outcome.rds",
  trait_name = "Sarcopenia_EWGSOP",
  tissue_specific_analysis = FALSE,
  run_pops = TRUE,
  build = 37,
  save_path = "E:/mr/comorbidity/HCC_sarcopenia/magma/"
)

run_magmar(
  outcome_file = "E:/mr/comorbidity/qMRI_HCC/VATV/VATV.rds",
  trait_name = "VATV",
  build = 37,
  tissue_specific_analysis = FALSE,
  e_magma = FALSE,
  h_magma = FALSE,
  cell_or_tissue = GTEX_v8_info$Tissue,
  run_pops = TRUE,
  save_path = "E:/mr/comorbidity/qMRI_HCC/magma/"
)

# POPS分析
?run_pops_v2
run_pops_v2(
  magma_file_prefix = "E:/mr/comorbidity/HCC_sarcopenia/magma/Sarcopenia_EWGSOP",
  trait_name = "Sarcopenia_EWGSOP",
  full_pops = TRUE,
  save_path = "E:/mr/comorbidity/HCC_sarcopenia/magma/"
)
```

### 1.6 GCTA基因分析
```r
run_gcta_gene_based_analysis(
  outcome_file = "E:/mr/liver/liver_cancer/subgroup/HCC/GWAS_meta/HCC_full_outcome.rds",
  trait_name = "HCC",
  pval_col = "pval.outcome",
  snp_col = "SNP",
  samplesize_col = "samplesize.outcome",
  A1_col = "effect_allele.outcome",
  A2_col = "other_allele.outcome",
  eaf_col = "eaf.outcome",
  beta_col = "beta.outcome",
  se_col = "se.outcome",
  maf = 0.01,
  fastBAT_wind = 50,
  fastBAT_ld_cutoff = 0.9,
  fastBAT_seg = 100,
  core = 10,
  save_path = "E:/mr/liver/liver_cancer/subgroup/HCC/GCTA/"
)
```

### 1.7 精细映射 (Fine-mapping)
```r
# Focus精细映射
?focus_format
focus_format(
  data = NULL,
  filename = "E:/mr/comorbidity/LF_liver_disease/GWAS/HCC.rds",
  trait_name = "HCC",
  CHR = "chr.outcome",
  SNP = "SNP",
  BP = "pos.outcome",
  A1 = "effect_allele.outcome",
  A2 = "other_allele.outcome",
  BETA = "beta.outcome",
  P = "pval.outcome",
  N = "samplesize.outcome",
  save_path = "E:/mr/comorbidity/LF_liver_disease/focus/"
)

# 创建Focus数据库
create_focus_db(
  import_pos_file = "CMC.BRAIN.RNASEQ.pos",
  data_resource = "fusion",
  Ensembl_ID = TRUE,
  tissue = "BRAIN",
  name = "BRAIN",
  assay = "rnaseq",
  output_name = "BRAIN",
  save_path = "E:/mr/liver/liver_cancer/subgroup/HCC/focus/"
)

# Focus运行
focus_finemaping(
  trait_name = "HCC",
  tissue = "BRAIN",
  chr_num1 = 1,
  chr_num2 = 22,
  build = 37,
  pop = "EUR",
  ref_database = "sCCA1.db",
  save_path = "E:/mr/liver/liver_cancer/subgroup/HCC/focus/"
)
```

### 1.8 gsMap空间转录组GWAS分析
```r
# gsMap数据格式转换
gsmap_format(
  data = NULL,
  filename = "E:/mr/comorbidity/DM2_HCC/GWAS/T2D_full_outcome.rds",
  trait_name = "T2D",
  CHR = "chr.outcome",
  SNP = "SNP",
  BP = "pos.outcome",
  A1 = "effect_allele.outcome",
  A2 = "other_allele.outcome",
  OR = NULL,
  BETA = "beta.outcome",
  SE = "se.outcome",
  P = "pval.outcome",
  N = "samplesize.outcome",
  FRQ = "eaf.outcome",
  maf_min = 0.01,
  info_min = 0.9,
  format = "gsMap",
  save_path = "E:/mr/comorbidity/DM2_HCC/DM2/gsmap/"
)

# gsMap快速分析模式
?run_gsmap_quick_mode
run_gsmap_quick_mode(
  sumstats_file = "E:/mr/comparative/NAFLD/gsmap/NAFLD_lean/NAFLD_lean.sumstats.gz",
  trait_name = "NAFLD_lean",
  hdf5_path = "D:/MRmyy_refer_file/gsMap/gsMap_example_data/ST/E16.5_E1S1.MOSTA.h5ad",
  sample_name = "E16.5_E1S1",
  annotation = "annotation",
  data_layer = "count",
  max_processes = 10,
  save_path = "E:/mr/comparative/NAFLD/gsmap/NAFLD_lean/"
)
```

### 1.9 GWAS质量控制
```r
# EasyQC质量控制
run_EasyQC_munge(
  trait_name = "HT",
  gwas_data = Hypertension_full_outcome,
  CHR_col = "chr.outcome",
  POS_col = "pos.outcome",
  SNP_col = "SNP",
  A1_col = "effect_allele.outcome",
  A2_col = "other_allele.outcome",
  EAF_col = "eaf.outcome",
  Effect_col = "beta.outcome",
  SE_col = "se.outcome",
  Pval_col = "pval.outcome",
  N_col = "samplesize.outcome",
  info.filter = 0.9,
  maf.filter = 0.01,
  remove_MHC = FALSE,
  save_path = "E:/mr/liver/MAFLD/gSEM/easyQC/"
)

# LDSC EFA分析
ldsc_efa <- run_ldsc_EFA(
  sumstats_file = c(
    "WC.sumstats.gz", "BMI.sumstats.gz", "UA.sumstats.gz",
    "TP.sumstats.gz", "TG.sumstats.gz", "ALP.sumstats.gz",
    "ALT.sumstats.gz", "CRP.sumstats.gz", "GGT.sumstats.gz",
    "GLU.sumstats.gz", "HbA1c.sumstats.gz", "HDL.sumstats.gz",
    "LF.sumstats.gz", "T2D.sumstats.gz"
  ),
  modified_name = c("WC","UA","TP","TG","ALP","ALT","CRP","GGT","GLU","HbA1c","HDL","LF"),
  sample.prev = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,0.5),
  population.prev = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,0.1),
  pop = "eur",
  save_name = "MAFLD",
  save_path = "E:/mr/liver/MAFLD/gSEM/easyQC/munge/"
)
```

## 关联模块

- `convert_supergnova/` - SuperGNOVA格式转换
- `manhattan_plot/` - 曼哈顿图绘制
- `utils/` - 通用数据处理工具

## 依赖包

```r
library(easyGWAS)
library(easyMR)
library(devtools)
```
