# YTLite Fork — 待升级功能清单

> 记录本 fork（willame/ytlite）在上游 verback2308/ytlite 之上的自定义功能待办。
> 当前唯一自定义功能：播放队列（Play next / Add to queue + "Up next" 区块，v1.6.4）。
> 构建走 Path A：GitHub Actions（Windows 只能改码不能本地编译）。

---

## ✅ 本轮已实现（2026-07-23，待 CI 构建验证）

### [P0] 队列会被误清空 — 已修
- `WatchViewController+Content.swift`：`else` 分支加 `!queue.isUserQueue` 判定，用户自建队列切到非队列视频时保留待播项，只清空 playlist/auto 队列。

### 倍速面板：滑动式 → 纯 chips 点击式
- 预设档位 `0.5/1.0/1.25/1.5/1.75/2.0`，2 行 3 列 chips + 顶部大字号当前速度（如 `1.50x`），移除滑块。
- 改动：`VideoPlayerView.swift`（speedPresets/speedButtons 取代 speedSlider）、`+Setup.swift`（chip 网格构建 + 约束拆分）、`+Speed.swift`（speedPresetTapped/updateSpeedSelection，删除 slider 方法与 snapToSteps）。
- 顺带修：旧 `%.2g` 格式把 1.25 误显为 "1.2x"，现改 `%g`（chip/控制条）与 `%.2f`（大字号）。

### 倍速暂停后不再自动回落 1.0
- 根因：`AVPlayer.play()`（播放器/锁屏/PiP/迷你面板 4 处 resume）强制 rate=1.0。
- 解法：在已有 `rate` KVO 里加**唯一一处**对账 `reapplySpeedIfReset`——播放中速率偏离选定档位即纠正回来，覆盖全部 resume 路径。`VideoPlayerView+Playback.swift`。

### 相关视频误触 — 三轮修法，真因=选中 vs 点击手势
- v1（无效）：只加内层 collection 的 `isDragging/isDecelerating`——竖屏下相关列表 `isScrollEnabled=false`，该 guard 恒 false。
- v2（修好"滑动/惯性期误触"）：`lastScrollActivity` 冷却窗口，点击距上次滚动 <0.3s 则吞掉。命中"点一下停住惯性滚动"场景。**已验证有效**。
- **真因（v3）**：播放走 `UICollectionView` 选中（`didSelectItemAt`，触摸抬起即触发，**对按压时长无要求**）——手指停留再抬起也算选中，故"轻碰/停留即播"，比原版 YouTube 敏感得多（YT 用点击手势语义，长停留不触发）。
- v3 解法：
  - `VideoCell` 加 `onTap` + `UITapGestureRecognizer`（`cancelsTouchesInView=false` 不干扰其它复用 VideoCell 的控制器；`shouldReceive` 排除频道头像/名；tap 与其它手势互斥防双触发）。长停留≥0.4s 落入既有 long-press（队列菜单）而非播放。
  - `relatedCollectionView.allowsSelection=false` 关掉选中式播放，改由 tap 驱动；`handleRelatedTap` 保留 v2 冷却门（防惯性-停）。
  - 移除 `shouldSelectItemAt`/`didSelectItemAt`。
  - 文件：`VideoCell.swift`、`+CollectionDelegates.swift`、`+Layout.swift`。

### 遗留小清理（非阻塞）
- `player.speed.normal` 本地化 key 在 12 个 `.lproj/Localizable.strings` 中已无代码引用，可后续统一删除（本轮未动，避免为一个 key 扫 12 个语言文件）。

---

## 待跟进（原队列功能缺口）

## P1 — 队列可管理性（加得进拿不出）

### 2. 已排队项无法移除 / 重排 / 清空
- **现象**：`PlaybackQueue` 有 `clear()`，但 UI 无任何移除单项、重排、清空队列入口。
- **位置**：`YTLite/Core/Playback/PlaybackQueue.swift`（缺 remove 单项方法）、队列 section 无操作入口。
- **方向**：已排队 cell 长按给「从队列移除」；"Up next" 顶部给「清空队列」。

### 3. 长按只在播放页相关视频生效
- **现象**：`onLongPress` 是 `VideoCell` 通用能力，但只有播放页相关列表接了 `presentQueueMenu`；首页/搜索/频道/订阅列表长按无反应，无法边刷边攒队列。
- **位置**：`YTLite/Features/Player/WatchViewController+CollectionDelegates.swift:72`（唯一接线点）。
- **方向**：在其他列表控制器复用 `presentQueueMenu`，是现成能力的最小扩展。

---

## P2 — 体验完善

### 4. 队列不持久化
- **现象**：`PlaybackQueue.shared` 纯内存单例，App 一杀队列即丢失，无落盘/恢复。
- **位置**：`YTLite/Core/Playback/PlaybackQueue.swift`。
- **方向**：队列落盘（UserDefaults / 文件），启动恢复。

### 5. "Up next" 缺真正的队列视图
- **现象**：目前只是把相关列表 section 0 标题换成「Up next」，看不到完整队列列表，也不知道后面排了几个。
- **位置**：`YTLite/Features/Player/WatchViewController+CollectionDelegates.swift:99`。
- **方向**：独立队列面板 / 可展开列表，展示完整队列与顺序。

---

## 备忘：更大方向（非"升级"，属新功能规划）
- 本 fork 提取价值在上游自研的独立 InnerTube 客户端（含 signatureCipher 逆向）。后续若要做纯 UI 层做不到的功能，应基于该客户端能力规划，另立条目，不混入本清单。
