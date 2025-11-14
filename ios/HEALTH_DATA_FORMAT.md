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

每个时段的数据格式为:

```json
{
  "date": "20251114",           // 用户时区的日期 (yyyyMMdd格式)
  "indicators": [               // 指标列表
    {
      "key": "stepCount",       // 指标唯一标识
      "name": "步数",            // 指标显示名称
      "unit": "count",          // 数据单位
      "total_value": 8524.0,    // 当天总聚合值
      "aggregation_method": "sum",  // 聚合方法
      "hour_items": [           // 按小时细分的数据
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

## 字段说明

### 顶层字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `date` | String | 用户时区的日期,格式为 `yyyyMMdd`,如 `20251114` |
| `indicators` | Array | 指标数组,包含所有采集到的健康数据 |

### Indicator 对象

| 字段 | 类型 | 说明 |
|------|------|------|
| `key` | String | 指标唯一标识符,如 `stepCount`, `heartRate` |
| `name` | String | 指标的中文显示名称,如 "步数", "心率" |
| `unit` | String | 数据单位,如 `count`(次), `m`(米), `bpm`(次/分钟) |
| `total_value` | Number | 当天的总聚合值 |
| `aggregation_method` | String | 聚合方法: `sum`(累加), `average`(平均), `latest`(最新值), `count`(计数) |
| `hour_items` | Array | 按小时细分的数据(可选) |

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

## 示例数据

```json
{
  "date": "20251114",
  "indicators": [
    {
      "key": "stepCount",
      "name": "步数",
      "unit": "count",
      "total_value": 8524.0,
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
      "total_value": 72.5,
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
      "total_value": 68.5,
      "aggregation_method": "latest",
      "hour_items": [
        {
          "hour": "2025-11-14 07:00",
          "value": 68.5
        }
      ]
    }
  ]
}
```
