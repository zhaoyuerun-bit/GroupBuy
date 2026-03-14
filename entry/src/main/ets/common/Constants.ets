// 拼单品类
export enum OrderCategory {
  FOOD = 'food',         // 外卖
  DRINK = 'drink',       // 奶茶
  FRUIT = 'fruit',       // 水果
  DAILY = 'daily',       // 日用
  EXPRESS = 'express',   // 快递
  CUSTOM = 'custom'      // 自定义
}

// 品类显示信息
export const CATEGORY_INFO: Record<string, CategoryDisplay> = {
  'food': { icon: '🍜', label: '外卖' },
  'drink': { icon: '🧋', label: '奶茶' },
  'fruit': { icon: '🍎', label: '水果' },
  'daily': { icon: '🧴', label: '日用' },
  'express': { icon: '📦', label: '快递' },
  'custom': { icon: '✏️', label: '自定义' }
}

export interface CategoryDisplay {
  icon: string
  label: string
}

// 拼单目标类型
export enum TargetType {
  AMOUNT = 'amount',   // 凑金额
  COUNT = 'count'      // 凑人数
}

// 拼单状态
export enum OrderStatus {
  GATHERING = 'gathering',   // 拼单中
  READY = 'ready',           // 可下单（已达目标）
  ORDERED = 'ordered',       // 已下单
  ARRIVED = 'arrived',       // 已到货
  COMPLETED = 'completed',   // 已完成
  CANCELLED = 'cancelled',   // 已取消
  EXPIRED = 'expired'        // 已过期
}

// 状态显示信息
export const STATUS_INFO: Record<string, StatusDisplay> = {
  'gathering': { label: '拼单中', color: '#FF6B35' },
  'ready': { label: '可下单', color: '#34C759' },
  'ordered': { label: '已下单', color: '#007AFF' },
  'arrived': { label: '已到货', color: '#34C759' },
  'completed': { label: '已完成', color: '#999999' },
  'cancelled': { label: '已取消', color: '#FF3B30' },
  'expired': { label: '已过期', color: '#999999' }
}

export interface StatusDisplay {
  label: string
  color: string
}

// AA分摊方式
export enum SplitMode {
  BY_ITEM = 'by_item',     // 按实际消费 + 均摊杂费
  EQUAL = 'equal',         // 完全均摊
  TREAT = 'treat'          // 发起人请客
}

// 颜色常量（参考美团暖色风格，高对比度）
export class AppColors {
  static readonly PRIMARY: string = '#FF6B00'
  static readonly PRIMARY_DARK: string = '#E05E00'
  static readonly PRIMARY_LIGHT: string = '#FFF3E0'
  static readonly PRIMARY_BG: string = '#FFFAF5'
  static readonly TEXT_PRIMARY: string = '#222222'
  static readonly TEXT_SECONDARY: string = '#555555'
  static readonly TEXT_HINT: string = '#888888'
  static readonly TEXT_WHITE: string = '#FFFFFF'
  static readonly BG_PAGE: string = '#F5F6FA'
  static readonly BG_CARD: string = '#FFFFFF'
  static readonly BG_INPUT: string = '#F5F6F8'
  static readonly DIVIDER: string = '#EBEDF0'
  static readonly BORDER: string = '#E8E8E8'
  static readonly SUCCESS: string = '#07C160'
  static readonly WARNING: string = '#FF9500'
  static readonly DANGER: string = '#FA5151'
  static readonly DISABLED_BG: string = '#E0E0E0'
  static readonly DISABLED_TEXT: string = '#AAAAAA'
}

// 尺寸常量
export class AppSizes {
  static readonly RADIUS_SM: number = 8
  static readonly RADIUS_MD: number = 12
  static readonly RADIUS_LG: number = 20
  static readonly RADIUS_XL: number = 24
  static readonly PADDING_XS: number = 4
  static readonly PADDING_SM: number = 8
  static readonly PADDING_MD: number = 16
  static readonly PADDING_LG: number = 20
  static readonly PADDING_XL: number = 24
  static readonly FONT_XS: number = 11
  static readonly FONT_SM: number = 12
  static readonly FONT_MD: number = 14
  static readonly FONT_LG: number = 16
  static readonly FONT_XL: number = 18
  static readonly FONT_TITLE: number = 20
  static readonly FONT_HEADER: number = 24
}
