# 1. 基础GWAS分析

基础GWAS分析模块，包含核心的GWAS数据处理、质量控制、位点提取和基本统计分析功能。

## 模块内容

| 文件 | 说明 |
|------|------|
| `basic_gwas.R` | Markdown 格式的研究流程参考，不是可直接 `source()` 的 R 模块 |

## 功能分类

### 1.1 环境配置
- R包安装和配置
- OpenGWAS API密钥设置

### 1.2 GWAS位点提取
- `get_loci()` - 从GWAS结果提取显著位点
- `get_nearest_gene()` - 提取最近基因
- `get_loci2()` - 批量提取位点

### 1.3 格式转换
- `convert_format()` - GWAS数据格式转换
- `liftover_convert_data()` - 基因组版本转换 (hg38↔hg19)

### 1.4 GWAS Meta分析
- `metal_gwas()` - GWAS Meta分析

### 1.5 基因分析
- `run_magmar()` - MAGMA分析
- `run_pops_v2()` - POPS分析
- `run_gcta_gene_based_analysis()` - GCTA基因分析

### 1.6 精细映射
- `focus_format()` - Focus精细映射格式准备
- `focus_finemaping()` - Focus精细映射运行
- `gsmap_format()` / `run_gsmap_quick_mode()` - gsMap空间转录组分析

### 1.7 质量控制
- `run_EasyQC_munge()` - EasyQC质量控制
- `run_ldsc_EFA()` - LDSC探索性因子分析

## 使用方法

请把 `basic_gwas.R` 作为研究 recipe 阅读。选择所需的 fenced R 代码块，逐项审核依赖版本、数据来源、基因组版本、凭证、路径与统计假设后，再复制到独立分析脚本中执行。不要对该文件运行 `source()`，也不要直接执行其中的示例路径或安装说明。

## 依赖

- easyGWAS
- easyMR
- devtools
