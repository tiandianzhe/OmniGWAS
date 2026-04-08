# 5. 其他辅助分析 (Auxiliary Tools)

辅助工具模块，包含数据处理、可视化、蛋白组学MR和其他支持性分析功能。

## 模块说明

### 5.1 数据处理工具
```r
# 读取数据
file_path <- "C:/Users/onekey/Desktop/MRI_HCC/supergnova/LF_HCC_results.txt"
data <- read.table(
  file = file_path,
  header = TRUE,
  sep = "",
  na.strings = "NA",
  check.names = FALSE
)

# 转换为数值型
Fibrosis_and_cirrhosis_metal_metal_full_outcome$pos.outcome <- as.numeric(
  Fibrosis_and_cirrhosis_metal_metal_full_outcome$pos.outcome
)

# 检查NA数量
sum(is.na(Fibrosis_and_cirrhosis_metal_metal_full_outcome$pos.outcome))
```

### 5.2 数据导出
```r
# 导出为Excel
library(writexl)
output_path <- "E:/mr/liver/HCC/Imaging/supergnova/LV_LC.xlsx"
dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
write_xlsx(res_LV, path = output_path)

# 导出为压缩TXT (用于FUMA等工具)
simple_data_clean <- liver_cancer_metal_metal_full_outcome %>%
  select(c("SNP","chr.outcome","pos.outcome","pval.outcome",
           "effect_allele.outcome","other_allele.outcome",
           "beta.outcome","se.outcome"))

write.table(
  simple_data_clean,
  file = gzfile("E:/mr/liver/HCC/FUMA/liver_cancer.txt.gz")
)

# 导出为TXT
output_dir <- "E:/mr/liver/liver_cancer/subgroup/HCC/Imaging/FUMA/"
output_file <- paste0(output_dir, "VATV_FUMA.txt")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
}
write.table(
  Visceral_adipose_tissue_volume_full_outcome,
  file = output_file,
  sep = "\t",
  row.names = FALSE,
  col.names = TRUE,
  quote = FALSE,
  na = "NA"
)
```

### 5.3 数据清洗与压缩
```r
# 删除不需要的列
library(dplyr)
data_clean <- liver_cancer_metal_metal_full_outcome %>%
  select(-any_of(c("outcome", "id.outcome", "mr_keep.outcome",
                   "pval_origin.outcome","ncase.outcome","ncontrol.outcome")))
```

### 5.4 数据重命名
```r
# 修改数据集内容
NASH <- Nonalcoholic_steatohepatitis_R11_full_outcome %>%
  mutate(
    outcome = str_replace(outcome, fixed("Nonalcoholic_steatohepatitis_R11"), "NASH"),
    id.outcome = str_replace(id.outcome, fixed("Nonalcoholic_steatohepatitis_R11"), "NASH")
  )

# 保存为RDS
output_file <- "E:/mr/comorbidity/LF_liver_disease/GWAS/NASH.rds"
saveRDS(NASH, file = output_file)
```

### 5.5 蛋白组学MR
```r
# 安装R2BGLiMS包
library(devtools)
devtools::install_github("pjnewcombe/R2BGLiMS", force = TRUE)

# PWMR3分析
?PWMR3
PWMR3(
  gene_name = NULL,
  pqtl_resource = "loya_H",
  outcome_dat = NULL,
  outcome_id = NULL,
  outcome_file = "E:/mr/HCC/GWAS/eur/HCC_full_outcome.rds",
  outcome_name = "HCC",
  kb = 1000,
  maf = 0.01,
  coloc_kb = 500,
  core = 8,
  pval = 5e-08,
  clump_kb = 10000,
  clump_r2 = 0.1,
  r2_corr = 0.1,
  proxy_r2 = 0.8,
  pqtl_build = 37,  # 37: EA, loya_H, Gudjonsson, Pietzner
  outcome_build = 37,
  outcome_type = "cc",
  proxies = FALSE,
  remove_HLA = FALSE,
  p1 = 1e-04,
  p2 = 1e-04,
  p12 = 1e-05,
  LD = FALSE,
  save_path = "E:/mr/HCC/PWMR/loya_H/"
)
```

### 5.6 蛋白组学结果可视化
```r
# XWMR火山图
p <- easyGWAS:::XWMR_Volcano_plot(res = PWMR_POAG)
print(p)
```

### 5.7 多组学数据处理
```r
# 格式组学数据
?format_omics_data

# 多组学曼哈顿图
omics_manhattan_plot(
  res_mqtl,
  plot_col = "#B4D151",
  plot_highlight.col = "#8680C0",
  only_gene = FALSE,
  legend = "mqtl-gwas",
  save_name = "mqtl",
  save_path = "E:/mr/liver/fibrosis_cirrhosis/multiomics/mqtl/"
)
```

### 5.8 数据1000G补充
```r
# 从1000G获取缺失数据
?get_data_from_1000g
AHCC_with_eaf <- get_data_from_1000g(
  data = AHCC,
  type = "outcome",
  build = 37,
  type_binary = TRUE,
  trait_name = "AHCC",
  chr = "chr.outcome",
  pos = "pos.outcome",
  A1 = "effect_allele.outcome",
  A2 = "other_allele.outcome",
  eaf = NULL,
  beta = "beta.outcome",
  se = "se.outcome",
  pval = "pval.outcome",
  samplesize = 2107,
  ncase = 775,
  save_path = "E:/mr/alcohol_related_HCC/GWAS/"
)
```

### 5.9 SuperGNOVA后处理
```r
# 读取SuperGNOVA结果
data <- read.csv("E:/mr/comorbidity/LF_liver_disease/supergnova/Cirrhosis_PDFF_results.csv")

# FDR校正
data$p_adjusted <- p.adjust(data$p, method = "fdr")
write.csv(data, "E:/mr/comorbidity/LF_liver_disease/supergnova/Cirrhosis_PDFF_results_FDR.csv", row.names = FALSE)
cat("FDR校正完成!")
```

## 关联模块

- `utils/` - OmniGWAS通用工具模块
- `convert_supergnova/` - SuperGNOVA格式转换
- `manhattan_plot/` - 曼哈顿图绘制

## 依赖包

```r
library(easyGWAS)
library(easyMR)
library(dplyr)
library(writexl)
```
