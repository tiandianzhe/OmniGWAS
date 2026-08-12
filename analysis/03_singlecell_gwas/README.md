# 3. 单细胞GWAS分析

单细胞和空间转录组分析模块，整合单细胞eQTL、空间转录组数据进行GWAS功能解读。

## 模块内容

| 文件 | 说明 |
|------|------|
| `singlecell_gwas.R` | Markdown 格式的研究流程参考，不是可直接 `source()` 的 R 模块 |

## 功能分类

### 3.1 动态免疫单细胞SMR
- `batch_xqtl_smr()` - 批量单细胞SMR分析
- 支持多种细胞类型：CD4, CD8, T细胞亚群, B细胞, NK等
- 支持动态时间点数据

### 3.2 pQTL/mQTL/eQTL SMR
- pQTL: 蛋白数量性状基因座分析
- mQTL: DNA甲基化QTL分析
- eQTL: 表达数量性状基因座分析

### 3.3 多组学SMR
- `multi_omic_MR()` - 多组学MR分析
- `multi_omic_SMR()` - 多组学SMR分析
- `miRNA_xqtl_MR()` - miRNA-xQTL分析

### 3.4 单细胞虚拟敲除
- `scTenifoldKnk()` - 基因虚拟敲除分析
- 差异调控基因识别
- 可视化（火山图、柱状图）

## 关联模块

- `batch_smr_dynamic/` - 动态免疫单细胞SMR模块
- `batch_gsmap/` - 空间转录组gsMap模块

## 使用方法

请把 `singlecell_gwas.R` 作为研究 recipe 阅读。选择所需的 fenced R 代码块，逐项审核依赖版本、单细胞或 xQTL 资源、数据来源、网络访问、路径与统计假设后，再复制到独立分析脚本中执行。不要对该文件运行 `source()`。

## 依赖

- easyGWAS
- easyMR
- Seurat
- scTenifoldKnk
