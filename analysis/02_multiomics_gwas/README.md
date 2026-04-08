# 2. 多组学GWAS分析

多组学整合分析模块，整合eQTL、pQTL、mQTL等组学数据与GWAS进行联合分析。

## 模块内容

| 文件 | 说明 |
|------|------|
| `multiomics_gwas.R` | 多组学GWAS分析完整代码 |

## 功能分类

### 2.1 数据提取
- `get_druggable_gene_eqtlgen_data()` - eQTLGen可药物靶点数据
- `get_gtex_v8_allpairs_gene_data()` - GTEx V8基因数据
- `get_full_gtex_v8_gene_data()` - GTEx V8完整数据
- `get_GTEx_V8_significant_variant_gene_pairs_data()` - 显著变异-基因对
- `get_full_psychencode_data()` - PsychENCODE数据

### 2.2 TWAS分析
- `SPrediXcan_model()` - 单组织TWAS
- `SMulTiXcan_model()` - 跨组织TWAS
- `UTMOST_format()` / `UTMOST_single_tissue_association()` - UTMOST分析

### 2.3 HESS分析
- `hess_format()` - HESS格式准备
- `run_hess()` - HESS遗传力富集分析

### 2.4 MR-JTI分析
- `run_MR_JTI()` - MR-JTI跨组织分析
- `get_cross_tissue_data()` - 跨组织数据提取

### 2.5 XWAS/FUSION分析
- `xwas_fusion()` - XWAS分析
- `xwas_fusion_conditional()` - 条件分析
- `xwas_fusion_plot()` - 可视化
- `batch_xwas_fusion()` - 批量蛋白组XWAS

## 使用方法

```r
# 加载多组学分析函数
source("analysis/02_multiomics_gwas/multiomics_gwas.R")

# 示例：TWAS分析
easyGWAS:::SPrediXcan_model(
  filename = "path/to/GWAS.rds",
  trait_name = "Trait",
  model = "UTMOST"
)
```

## 依赖

- easyGWAS
- easyMR
- MetaXcan (需安装)
