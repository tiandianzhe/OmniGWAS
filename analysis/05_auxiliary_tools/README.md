# 5. 其他辅助分析

辅助工具模块，包含数据处理、可视化、蛋白组学MR和其他支持性分析功能。

## 模块内容

| 文件 | 说明 |
|------|------|
| `auxiliary_tools.R` | Markdown 格式的研究流程参考，不是可直接 `source()` 的 R 模块 |

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

请把 `auxiliary_tools.R` 作为研究 recipe 阅读。选择所需的 fenced R 代码块，逐项审核依赖版本、输入数据、输出覆盖行为、网络访问与路径后，再复制到独立分析脚本中执行。不要对该文件运行 `source()`。可维护且可直接调用的工具位于本目录各子模块的 `R/` 与 `src/` 中。

## 依赖

- easyGWAS
- easyMR
- dplyr
- writexl
