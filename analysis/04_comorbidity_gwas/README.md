# 4. 共病GWAS分析

共病和双样本MR分析模块，研究疾病之间的因果关系和共同遗传基础。

## 模块内容

| 文件 | 说明 |
|------|------|
| `comorbidity_gwas.R` | Markdown 格式的研究流程参考，不是可直接 `source()` 的 R 模块 |

## 功能分类

### 4.1 双样本MR分析
- `mr_modified()` - 双样本MR主函数
- 支持多暴露、多结局分析

### 4.2 共定位分析
- `data_to_coloc()` - 贝叶斯共定位分析
- `run_hyprcoloc()` - HyPrColoc多性状共定位

### 4.3 蛋白互作分析
- `format_sum_stats()` - 数据格式化
- `pwcoco()` - 蛋白互作共调控分析

### 4.4 LDSC分析
- `ldsc()` - LDSC与MRlap分析
- `multi_ldsc()` - 多性状LDSC

### 4.5 高级MR方法
- `run_HDL()` - 混合效应分层分析
- `run_pleioFDR()` - pleioFDR分析
- `cause_MR()` - CAUSE因果推断
- `LCV()` - 遗传因果比例分析
- `run_placo()` - PLACO因果推断

### 4.6 遗传相关性
- `run_gnova()` - GNOVA遗传相关性
- `run_supergnova()` - SuperGNOVA共定位

### 4.7 多性状分析
- `run_mtag()` - MTAG多性状GWAS
- `run_CPASSOC()` - CPASSOC跨性状关联
- `run_mixer()` - Mixer多性状分析

### 4.8 LAVA分析
- `run_lava()` - 局部遗传相关性分析
- `plot_lava()` - 可视化

### 4.9 多变量MR
- `run_mvmr()` - 多变量MR分析

## 使用方法

请把 `comorbidity_gwas.R` 作为研究 recipe 阅读。选择所需的 fenced R 代码块，逐项审核依赖版本、暴露与结局数据、样本重叠、祖源、参考面板、路径与统计假设后，再复制到独立分析脚本中执行。不要对该文件运行 `source()`。

## 依赖

- easyGWAS
- easyMR
