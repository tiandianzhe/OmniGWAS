# 4. 共病GWAS分析 (Comorbidity GWAS Analysis)

共病和双样本MR分析模块，研究疾病之间的因果关系和共同遗传基础。

## 模块说明

### 4.1 双样本MR分析
```r
# 双样本MR主函数
?mr_modified
mr_modified(
  exposure_data = NULL,
  exp_file_sig = NULL,
  exposure_id = NULL,
  exp_filenames = c(
    "E:/mr/comorbidity/HCC_sarcopenia/GWAS/Sarcopenia_EWGSOP_full_exposure.rds",
    "E:/mr/comorbidity/HCC_sarcopenia/GWAS/Sarcopenia_FNIH_full_exposure.rds"
  ),
  id_outcome = NULL,
  out_filenames = c("E:/mr/HCC/GWAS/eur/HCC_wo_UKB_full_outcome.rds"),
  outcome_data = NULL,
  exp = "Sarcopenia",
  out = "HCC",
  clump = TRUE,
  clump_r2 = 0.001,
  clump_kb = 10000,
  clump_local = TRUE,
  proxies = FALSE,
  pop = "EUR",
  pval = 5e-08,
  pval_out = 5e-08,
  r2 = 0.8,
  f_cutoff = 10,
  action = 2,
  remove_HLA = FALSE,
  palindromic = FALSE,
  NbD = 1000,
  core = 20,
  full_MR = TRUE,
  run_steiger_filtering = TRUE,
  save_path = "E:/mr/HCC/comorbidity/ReverseMR/"
)
```

### 4.2 共定位分析
```r
# 贝叶斯共定位分析
?data_to_coloc
data_to_coloc(
  exposure_file = "E:/mr/Imaging/MRI/Visceral_adipose_tissue_volume/Visceral_adipose_tissue_volume_full_exposure.rds",
  exposure_build = 37,
  exposure_type = "quant",
  exposure_name = "VATV",
  outcome_file = "E:/mr/comorbidity/LF_liver_disease/GWAS/HCC.rds",
  outcome_build = 37,
  outcome_type = "cc",
  outcome_name = "HCC",
  lead_snp = FALSE,
  top_snp = FALSE,
  SNP = NULL,
  remove_MHC = TRUE,
  pval = 1,
  kb = 1000,
  LD = FALSE,
  clump_r2 = 0.001,
  clump_kb = 10000,
  clump_local = FALSE,
  p1 = 1e-04,
  p2 = 1e-04,
  p12 = 1e-05,
  r2thr = 0.01,
  pthr = 1e-06,
  maxhits = 3,
  exposure_title = "VATV",
  outcome_title = "HCC",
  combine = FALSE,
  legend_position = "topright",
  save_path = "E:/mr/comorbidity/qMRI_HCC/coloc/"
)

# HyPrColoc多性状共定位
res <- run_hyprcoloc(
  gene_anno = "NCBI",
  gene_name = NULL,
  eqtl_resource = "GTEx_V8",
  tissue = NULL,
  kb = 100,
  pval = 1,
  gwas_list = c(
    "E:/mr/Imaging/MRI/liver_fat/liver_fat_full_outcome.rds",
    "E:/mr/Imaging/MRI/Liver_iron_content/Liver_iron_content_full_outcome.rds",
    "E:/mr/Imaging/MRI/liver_volume/liver_volume_full_outcome.rds",
    "E:/mr/Imaging/MRI/Abdominal_subcutaneous_adipose_tissue_volume/ASATV_full_outcome.rds",
    "E:/mr/Imaging/MRI/Visceral_adipose_tissue_volume/VATV_full_outcome.rds",
    "E:/mr/liver/liver_cancer/subgroup/HCC/GWAS_meta/HCC_full_outcome.rds"
  ),
  type_gwas_list = c("quant","quant","quant","quant","quant","binary"),
  save_path = "E:/mr/liver/liver_cancer/subgroup/HCC/Imaging/hyprcoloc/"
)

# 指定基因的HyPrColoc
res <- run_hyprcoloc(
  gene_name = "PLA2G2A",
  eqtl_resource = "full_eQTLGen",
  mqtl_resource = NULL,
  tissue = NULL,
  kb = 100,
  pval = 1,
  eqtl = "ENSG00000188257",
  gwas_list = c("E:/mr/liver/fibrosis_cirrhosis/gwas_meta/Fibrosis_and_cirrhosis_metal_metal_full_outcome.rds"),
  type_gwas_list = c("binary"),
  type_gwas_id = "binary",
  save_path = "E:/mr/liver/fibrosis_cirrhosis/test/"
)
```

### 4.3 pwcoco蛋白互作分析
```r
# 格式化汇总统计数据
?format_sum_stats
format_sum_stats(
  gwas_file = "E:/mr/comorbidity/LF_liver_disease/GWAS/PDFF.rds",
  trait_name = "PDFF",
  SNP = "SNP",
  CHR = "chr.outcome",
  POS = "pos.outcome",
  A1 = "effect_allele.outcome",
  A2 = "other_allele.outcome",
  FRQ = "eaf.outcome",
  BETA = "beta.outcome",
  SE = "se.outcome",
  P = "pval.outcome",
  NCASE = "ncase.outcome",
  N = "samplesize.outcome",
  save_path = "E:/mr/comorbidity/LF_liver_disease/pwcoco/"
)

# pwcoco分析
pwcoco(
  sum_stats1 = "E:/mr/comorbidity/glaucoma_myopia/pwcoco/Glaucoma.txt",
  sum_stats2 = "E:/mr/comorbidity/glaucoma_myopia/pwcoco/Myopia.txt",
  maf = 0.1,
  chr = 1,
  p_cutoff1 = 5e-08,
  p_cutoff2 = 5e-08,
  freq_differ = 0.2,
  pph4_threshold = 80,
  save_path = "E:/mr/comorbidity/glaucoma_myopia/pwcoco/"
)
```

### 4.4 LDSC与MRlap
```r
# LDSC与MRlap分析
?easyMR::ldsc
res <- easyMR::ldsc(
  exp_name = "POAG",
  out_name = "Myopia",
  expfilename = "E:/mr/comorbidity/POAG_myopia/GWAS/POAG_full_exposure.rds",
  outfilename = "E:/mr/comorbidity/POAG_myopia/GWAS/Myopia_full_outcome.rds",
  exp_type = "binary",
  out_type = "binary",
  remove_HLA = TRUE,
  run_MRlap = TRUE,
  pval = 5e-8,
  MR_reverse = 5e-8,
  save_path = "E:/mr/comorbidity/POAG_myopia/TSMR/"
)

# 多性状LDSC
?multi_ldsc
multi_ldsc(
  trait_list_gwas = c("E:/mr/HCC/GWAS/eur/HCC_full_outcome.rds"),
  remove_MHC = TRUE,
  pop = "eur",
  without_constrained_intercept = TRUE,
  ignore_sample.prev = TRUE,
  sample.prev = NULL,
  save_path = "E:/mr/HCC/comorbidity/LDSC/"
)
```

### 4.5 HDL分析
```r
# 混合效应分层分析
res_HDL <- easyMR::run_HDL(
  exposure_path = "E:/mr/Imaging/MRI/liver_fat/liver_fat_full_exposure.rds",
  outcome_path = "E:/mr/liver/liver_cancer/subgroup/HCC/GWAS_meta/HCC_full_outcome.rds",
  exp_name = "LF",
  LD.path = paste0(easyMR::get_MRdatabase(), "/UKB_imputed_hapmap2_SVD_eigen99_extraction"),
  out_name = "HCC",
  save_path = "E:/mr/liver/liver_cancer/subgroup/HCC/Imaging/HDL/"
)
```

### 4.6 pleioFDR分析
```r
# 遗传相关性校正分析
?run_pleioFDR
run_pleioFDR(
  trait_list_gwas = c(
    "E:/mr/comorbidity/HCC_sarcopenia/GWAS/Sarcopenia_EWGSOP_full_outcome.rds",
    "E:/mr/comparative/NAFLD/GWAS/NAFLD_lean_full_outcome.rds"
  ),
  stattype = "condfdr21",
  matlab_exe = "D:/matlab_R2019a/bin/matlab.exe",
  fdrthresh = 0.05,
  randprune_n = 500,
  save_path = "E:/mr/comorbidity/HCC_sarcopenia/pleioFDR/"
)
```

### 4.7 CAUSE分析
```r
# CAUSE因果推断
?cause_MR
cause_MR(
  exp_filename = "E:/mr/comorbidity/POAG_myopia/GWAS/POAG_full_exposure.rds",
  exp = "POAG",
  out_filename = "E:/mr/comorbidity/POAG_myopia/GWAS/Myopia.rds",
  out = "Myopia",
  kb = 10000,
  r2 = 0.001,
  pvalue = 5e-8,
  pop = "EUR",
  confounder_SNPs = NULL,
  delete_confouner_SNP = FALSE,
  standardize = FALSE,
  save_path = "E:/mr/comorbidity/POAG_myopia/CAUSE/"
)
```

### 4.8 LCV分析
```r
# 遗传因果比例分析
LCV(
  expfilename = "E:/mr/comorbidity/POAG_myopia/GWAS/POAG_full_exposure.rds",
  outfilename = "E:/mr/comorbidity/POAG_myopia/GWAS/Myopia.rds",
  exp = "POAG",
  out = "Myopia",
  save_path = "E:/mr/comorbidity/POAG_myopia/LCV/"
)
```

### 4.9 placo分析
```r
# 孟德尔随机化因果推断
?run_placo
data_placo <- run_placo(
  exp_file = "E:/mr/comorbidity/POAG_myopia/GWAS/POAG.rds",
  exp_name = "POAG",
  out_file = "E:/mr/comorbidity/POAG_myopia/GWAS/Myopia.rds",
  out_name = "Myopia",
  remove_Z_80 = TRUE,
  MAF_threshold = 0.01,
  pval_threshold = 0.05,
  sig_pval = 5e-08,
  save_path = "E:/mr/comorbidity/POAG_myopia/placo/"
)
```

### 4.10 GNOVA分析
```r
# GNOVA遗传相关性分析
?run_gnova
res_gnova <- run_gnova(
  sumstats1 = "E:/mr/HCC/comorbidity/LDSC/HCC_wo_UKB.sumstats.gz",
  sumstats2 = "E:/mr/HCC/comorbidity/LDSC/Sarcopenia_EWGSOP.sumstats.gz",
  output_name = "HCC_wo_UKB_Sarcopenia_EWGSOP",
  save_path = "E:/mr/HCC/comorbidity/GNOVA/"
)
```

### 4.11 SuperGNOVA分析
```r
# SuperGNOVA共定位分析
?run_supergnova
run_supergnova(
  sumstats1 = "E:/mr/comorbidity/HCC_sarcopenia/LDSC/Sarcopenia_EWGSOP.sumstats.gz",
  sumstats2 = "E:/mr/comparative/NAFLD/LDSC/NAFLD_lean.sumstats.gz",
  output_name = "Sarcopenia_EWGSOP_NAFLD_lean",
  thread = 104,
  save_path = "E:/mr/comorbidity/HCC_sarcopenia/supergnova/"
)

# FDR校正后处理
data <- read.csv("E:/mr/comorbidity/LF_liver_disease/supergnova/Cirrhosis_PDFF_results.csv")
data$p_adjusted <- p.adjust(data$p, method = "fdr")
write.csv(data, "E:/mr/comorbidity/LF_liver_disease/supergnova/Cirrhosis_PDFF_results_FDR.csv", row.names = FALSE)
```

### 4.12 MTAG分析
```r
# 多性状GWAS分析
?run_mtag
run_mtag(
  gwas_list = c(
    "E:/mr/comorbidity/HCC_sarcopenia/GWAS/Sarcopenia_EWGSOP_full_outcome.rds",
    "E:/mr/comparative/NAFLD/GWAS/NAFLD_lean_full_outcome.rds"
  ),
  gwas_name_list = c("Sarcopenia_EWGSOP","NAFLD_lean"),
  core = 10,
  max_FDR = TRUE,
  filter_hm3 = TRUE,
  no_overlap = FALSE,
  equal_h2 = FALSE,
  save_path = "E:/mr/comorbidity/HCC_sarcopenia/mtag/"
)
```

### 4.13 CPASSOC分析
```r
# 跨性状关联分析
?run_CPASSOC
run_CPASSOC(
  df1 = "E:/mr/comorbidity/POAG_myopia/GWAS/POAG_full_exposure.rds",
  df1_name = "POAG",
  df2 = "E:/mr/comorbidity/POAG_myopia/GWAS/Myopia.rds",
  df2_name = "Myopia",
  remove_Z_1.96 = FALSE,
  SNP_col_df1 = "SNP",
  SNP_col_df2 = "SNP",
  chr_col_df1 = "chr.exposure",
  chr_col_df2 = "chr.outcome",
  pos_col_df1 = "pos.exposure",
  pos_col_df2 = "pos.outcome",
  A1_col_df1 = "effect_allele.exposure",
  A1_col_df2 = "effect_allele.outcome",
  A2_col_df1 = "other_allele.exposure",
  A2_col_df2 = "other_allele.outcome",
  beta_col_df1 = "beta.exposure",
  beta_col_df2 = "beta.outcome",
  se_col_df1 = "se.exposure",
  se_col_df2 = "se.outcome",
  samplesize_df1 = "samplesize.exposure",
  samplesize_df2 = "samplesize.outcome",
  save_path = "E:/mr/comorbidity/POAG_myopia/mtag/"
)

# CPASSOC与MTAG显著SNP筛选
?CPASSOC_mtag_sig
CPASSOC_mtag_sig(
  gwas_name_list = c("POAG","Myopia"),
  clump_kb = 500,
  clump_r2 = 0.2,
  sig_matg_pval = 5e-8,
  sig_CPASSOC_pval = 5e-8,
  clump_p1 = 5e-8,
  clump_p2 = 1e-5,
  pop = "EUR",
  save_path = "E:/mr/comorbidity/POAG_myopia/mtag/"
)
```

### 4.14 Mixer分析
```r
# Mixer多性状分析
?run_mixer
run_mixer(
  trait_list_gwas = c(
    "E:/mr/comorbidity/LF_liver_disease/GWAS/NASH.rds",
    "E:/mr/comorbidity/LF_liver_disease/GWAS/PDFF.rds"
  ),
  remove_region = "6:26000000-34000000",
  extract_snps = "1000G",
  trait_name = c("NASH","PDFF"),
  pop = "EUR",
  uni_fit_sequence = c("diffevo-fast"),
  bi_fit_sequence = c("diffevo-fast neldermead-fast brute1-fast brent1-fast"),
  randprune_n = 64,
  randprune_r2 = 0.1,
  chr2use = "1",
  fit_kmax = 20000,
  test_kmax = 100,
  diffevo_fast_repeats = 1,
  power_curve = TRUE,
  qq_plots = TRUE,
  rep2use = "1-20",
  flip = FALSE,
  ext = "pdf",
  zmax = 10,
  statistic = "mean std",
  save_path = "E:/mr/comorbidity/LF_liver_disease/mixer/"
)
```

### 4.15 LAVA分析
```r
# LAVA局部遗传相关性分析
?run_lava
res_lava <- easyMR::run_lava(
  exp_name = "PDFF",
  out_name = "ALD",
  expfilename = "E:/mr/Imaging/MRI/liver_fat/liver_fat_full_exposure.rds",
  outfilename = "E:/mr/comorbidity/LF_liver_disease/GWAS/ALD.rds",
  exp_type = "continuous",
  out_type = "binary",
  n.loc = NULL,
  save_path = "E:/mr/comorbidity/LF_liver_disease/lava/"
)

# LAVA可视化
plot_lava(
  lavaresult = "E:/mr/comorbidity/LF_liver_disease/lava/PDFF_ALD.bivar.lava",
  lociref = paste0(easyGWAS::get_MRdatabase(), "/blocks_s2500_m25_f1_w200.GRCh37_hg19.locfile"),
  color_combsig = "red",
  color_sig = "blue",
  color_nsig = "gray",
  save_name = "PDFF_ALD",
  save_path = "E:/mr/comorbidity/LF_liver_disease/lava/"
)
```

### 4.16 多变量MR
```r
# 多变量MR分析
run_mvmr(
  exposure_data = NULL,
  exp_file_sig = NULL,
  exp_filenames = c(
    "E:/mr/Imaging/MRI/liver_fat/liver_fat_full_exposure.rds",
    "E:/mr/Imaging/MRI/Liver_iron_content/Liver_iron_content_full_exposure.rds"
  ),
  exposure_id = NULL,
  id_outcome = NULL,
  out_filenames = "E:/mr/liver/liver_cancer/subgroup/HCC/GWAS_meta/HCC_full_outcome.rds",
  outcome_data = NULL,
  exp = "MRI",
  out = "HCC",
  clump_r2 = 0.001,
  clump_kb = 10000,
  clump_local = TRUE,
  proxies = TRUE,
  time_out = TRUE,
  pval = 5e-06,
  pval_out = 5e-08,
  r2 = 0.8,
  kb = 10000,
  pop = "EUR",
  action = 2,
  proxies_out = TRUE,
  NbDistribution = 1000,
  run_mvmr_presso = FALSE,
  save_path = "E:/mr/liver/liver_cancer/subgroup/HCC/Imaging/mvmr/"
)
```

## 依赖包

```r
library(easyGWAS)
library(easyMR)
```
