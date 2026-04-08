# 5. 其他辅助分析

辅助工具模块，包含数据处理、可视化、蛋白组学MR和其他支持性分析功能。

## 模块内容

| 文件 | 说明 |
|------|------|
| `auxiliary_tools.R` | 辅助分析工具完整代码 |

## 功能分类

### 5.1 数据处理
- 数据读取 (`read.table`)
- 类型转换 (`as.numeric`)
- NA值检查

### 5.2 数据导出
- `writexl` - Excel导出
- `write.table` - TXT/压缩文件导出
- RDS格式保存

### 5.3 数据清洗
- 删除不需要的列
- 数据重命名
- 数据压缩

### 5.4 蛋白组学MR
- `PWMR3()` - 蛋白组学MR分析
- `XWMR_Volcano_plot()` - 结果可视化

### 5.5 多组学数据
- `format_omics_data()` - 组学数据格式化
- `omics_manhattan_plot()` - 多组学曼哈顿图

### 5.6 数据补充
- `get_data_from_1000g()` - 1000G数据补充

## 关联模块

- `utils/` - 通用工具模块
- `convert_supergnova/` - 格式转换
- `manhattan_plot/` - 可视化

## 使用方法

```r
# 加载辅助工具
source("analysis/05_auxiliary_tools/auxiliary_tools.R")

# 数据处理示例
library(writexl)
write_xlsx(data, "output.xlsx")

# 数据清洗
data_clean <- data %>% select(-any_of(c("col1", "col2")))
```

## 依赖

- easyGWAS
- easyMR
- dplyr
- writexl
