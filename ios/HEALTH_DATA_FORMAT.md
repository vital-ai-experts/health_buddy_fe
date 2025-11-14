# 健康数据格式说明

## 数据结构概览

健康数据采用以下层级结构:

```json
{
  "yesterday_data": "{ ... }",  // 昨天的数据(JSON字符串)
  "today_data": "{ ... }",      // 今天的数据(JSON字符串)
  "recent_data": "{ ... }"      // 最近3小时的数据(JSON字符串)
}
```

### 日期范围数据格式 (yesterday_data, today_data)

```json
{
  "date": "20251114",           // 用户时区的日期 (yyyyMMdd格式)
  "indicators": [               // 指标列表(只包含有数据的指标)
    {
      "key": "stepCount",       // 指标唯一标识
      "name": "步数",            // 指标显示名称
      "unit": "count",          // 数据单位
      "value": 8524.0,          // 总聚合值
      "aggregation_method": "sum",  // 聚合方法
      "hour_items": [           // 按小时细分的数据(可选,仅当有多个小时数据时)
        {
          "hour": "2025-11-14 00:00",
          "value": 245.0
        },
        {
          "hour": "2025-11-14 01:00",
          "value": 123.0
        }
      ]
    }
  ]
}
```

### 时间范围数据格式 (recent_data)

```json
{
  "start_time": "2025-11-14T13:30:00+08:00",  // ISO8601格式开始时间
  "end_time": "2025-11-14T16:30:00+08:00",    // ISO8601格式结束时间
  "indicators": [               // 指标列表(只包含有数据的指标)
    {
      "key": "stepCount",
      "name": "步数",
      "unit": "count",
      "value": 1523.0,
      "aggregation_method": "sum"
      // 注意: recent_data 可能没有 hour_items,因为时间跨度较短
    }
  ]
}
```

## 字段说明

### 顶层字段

#### 日期范围模式 (yesterday_data, today_data)

| 字段 | 类型 | 说明 |
|------|------|------|
| `date` | String | 用户时区的日期,格式为 `yyyyMMdd`,如 `20251114` |
| `indicators` | Array | 指标数组,**只包含有数据的指标** |

#### 时间范围模式 (recent_data)

| 字段 | 类型 | 说明 |
|------|------|------|
| `start_time` | String | ISO8601格式的开始时间,如 `2025-11-14T13:30:00+08:00` |
| `end_time` | String | ISO8601格式的结束时间,如 `2025-11-14T16:30:00+08:00` |
| `indicators` | Array | 指标数组,**只包含有数据的指标** |

### Indicator 对象

| 字段 | 类型 | 说明 |
|------|------|------|
| `key` | String | 指标唯一标识符,如 `stepCount`, `heartRate` |
| `name` | String | 指标的中文显示名称,如 "步数", "心率" |
| `unit` | String | 数据单位,如 `count`(次), `m`(米), `bpm`(次/分钟) |
| `value` | Number | 总聚合值 |
| `aggregation_method` | String | 聚合方法: `sum`(累加), `average`(平均), `latest`(最新值), `count`(计数) |
| `hour_items` | Array (可选) | 按小时细分的数据,**仅当有多个小时数据时才存在** |

### Hour Item 对象

| 字段 | 类型 | 说明 |
|------|------|------|
| `hour` | String | 小时时间戳,格式为 `yyyy-MM-dd HH:mm` |
| `value` | Number | 该小时的聚合值 |
| `count` | Number | (仅分类数据)该小时的计数 |

## 聚合方法说明

### sum (累加)
用于累积类型的指标,将所有值相加。

**适用指标:**
- 步数、距离类指标
- 能量消耗
- 运动时间、站立时间
- 营养摄入

### average (平均)
用于离散类型的指标,计算平均值。

**适用指标:**
- 心率、心率变异性
- 血压、血糖
- 体温
- 血氧饱和度
- 运动速度

### latest (最新值)
用于身体测量类指标,取最后一次测量值。

**适用指标:**
- 身高、体重
- BMI、体脂率
- 腰围

### count (计数)
用于分类类型的指标,统计事件发生次数。

**适用指标:**
- 睡眠分析
- 正念时长

## 数据单位说明

| 单位 | 含义 | 适用指标 |
|------|------|----------|
| `count` | 次数 | 步数、爬楼层数、跌倒次数 |
| `m` | 米 | 距离、身高、腰围、步长 |
| `min` | 分钟 | 运动时间、站立时间、日光时间 |
| `kcal` | 千卡 | 能量消耗、饮食能量 |
| `bpm` | 次/分钟 | 心率、呼吸频率 |
| `ms` | 毫秒 | 心率变异性 |
| `%` | 百分比 | 血氧饱和度、体脂率 |
| `mmHg` | 毫米汞柱 | 血压 |
| `°C` | 摄氏度 | 体温 |
| `mmol/L` | 毫摩尔/升 | 血糖 |
| `dB` | 分贝 | 音频暴露 |
| `m/s` | 米/秒 | 速度 |
| `kg` | 千克 | 体重 |
| `L` | 升 | 饮水量 |
| `g` | 克 | 蛋白质、碳水、脂肪、纤维 |
| `mg` | 毫克 | 咖啡因 |
| `μg` | 微克 | 维生素A、维生素D |

## 指标分类

### 活动与健身
- 步数 (stepCount)
- 步行+跑步距离 (distanceWalkingRunning)
- 骑行距离 (distanceCycling)
- 游泳距离 (distanceSwimming)
- 爬楼层数 (flightsClimbed)
- 锻炼时间 (exerciseTime)
- 活动能量 (activeEnergyBurned)
- 静息能量 (basalEnergyBurned)
- 站立时间 (standTime)
- 活动时间 (moveTime)

### 运动指标
- 步行速度 (walkingSpeed)
- 跑步速度 (runningSpeed)
- 步长 (walkingStepLength)
- 上楼速度 (stairAscentSpeed)
- 下楼速度 (stairDescentSpeed)

### 心肺健康
- 心率 (heartRate)
- 静息心率 (restingHeartRate)
- 步行平均心率 (walkingHeartRateAverage)
- 心率变异性 (heartRateVariability)
- 最大摄氧量 (vo2Max)
- 血氧饱和度 (oxygenSaturation)
- 呼吸频率 (respiratoryRate)
- 收缩压 (bloodPressureSystolic)
- 舒张压 (bloodPressureDiastolic)

### 身体测量
- 身高 (height)
- 体重 (bodyMass)
- BMI (bodyMassIndex)
- 瘦体重 (leanBodyMass)
- 体脂率 (bodyFatPercentage)
- 腰围 (waistCircumference)

### 营养
- 饮食能量 (dietaryEnergy)
- 饮水量 (dietaryWater)
- 蛋白质 (dietaryProtein)
- 碳水化合物 (dietaryCarbohydrates)
- 脂肪 (dietaryFat)
- 咖啡因 (dietaryCaffeine)
- 糖分 (dietarySugar)
- 纤维 (dietaryFiber)
- 维生素A (vitaminA)
- 维生素C (vitaminC)
- 维生素D (vitaminD)

### 睡眠与正念
- 睡眠分析 (sleepAnalysis)
- 正念时长 (mindfulSession)
- 睡眠手腕温度 (sleepingWristTemperature) - iOS 17+

### 其他健康指标
- 体温 (bodyTemperature)
- 血糖 (bloodGlucose)
- 跌倒次数 (numberOfTimesFallen)
- 环境音量 (environmentalAudioExposure)
- 耳机音量 (headphoneAudioExposure)
- 紫外线暴露 (uvExposure)
- 体力消耗 (physicalEffort) - iOS 17+
- 日光时间 (timeInDaylight) - iOS 17+

### 移动性
- 步行双支撑百分比 (walkingDoubleSupportPercentage)
- 步行不对称百分比 (walkingAsymmetryPercentage)

## 重要说明

### 数据优化规则

1. **只包含有数据的指标**: `indicators` 数组只包含有实际数据的指标,没有数据的指标不会出现
2. **hour_items 可选**: 只有当一个指标有多个小时的数据时才会包含 `hour_items` 字段
3. **时间范围区分**:
   - 日期范围 (yesterday/today) 使用 `date` 字段
   - 时间范围 (recent) 使用 `start_time` 和 `end_time` 字段

### 示例数据

#### 日期范围数据 (yesterday_data / today_data)

```json
{
  "date": "20251114",
  "indicators": [
    {
      "key": "stepCount",
      "name": "步数",
      "unit": "count",
      "value": 8524.0,
      "aggregation_method": "sum",
      "hour_items": [
        {
          "hour": "2025-11-14 08:00",
          "value": 1245.0
        },
        {
          "hour": "2025-11-14 09:00",
          "value": 2134.0
        }
      ]
    },
    {
      "key": "heartRate",
      "name": "心率",
      "unit": "count/min",
      "value": 72.5,
      "aggregation_method": "average",
      "hour_items": [
        {
          "hour": "2025-11-14 08:00",
          "value": 68.0
        },
        {
          "hour": "2025-11-14 09:00",
          "value": 75.0
        }
      ]
    },
    {
      "key": "bodyMass",
      "name": "体重",
      "unit": "kg",
      "value": 68.5,
      "aggregation_method": "latest"
      // 注意: 体重只有一次测量,所以没有 hour_items
    }
  ]
}
```

#### 时间范围数据 (recent_data)

```json
{
  "start_time": "2025-11-14T13:30:00+08:00",
  "end_time": "2025-11-14T16:30:00+08:00",
  "indicators": [
    {
      "key": "stepCount",
      "name": "步数",
      "unit": "count",
      "value": 1523.0,
      "aggregation_method": "sum",
      "hour_items": [
        {
          "hour": "2025-11-14 13:00",
          "value": 456.0
        },
        {
          "hour": "2025-11-14 14:00",
          "value": 521.0
        },
        {
          "hour": "2025-11-14 15:00",
          "value": 546.0
        }
      ]
    },
    {
      "key": "heartRate",
      "name": "心率",
      "unit": "count/min",
      "value": 75.0,
      "aggregation_method": "average"
      // 可能没有 hour_items,如果在这3小时内只有少量测量
    }
  ]
}
```
