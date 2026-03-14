import { OrderCategory, TargetType, OrderStatus, SplitMode } from '../common/Constants'

// 拼单主模型
export interface GroupOrder {
  id: string
  category: OrderCategory
  title: string
  creatorId: string
  creatorName: string
  targetType: TargetType
  targetValue: number
  splitMode: SplitMode
  extraFee: number
  note: string
  status: OrderStatus
  items: OrderItem[]
  createdAt: number
  updatedAt: number
}

// 选品条目
export interface OrderItem {
  id: string
  orderId: string
  userId: string
  userName: string
  itemName: string
  price: number
  createdAt: number
}

// 参与人汇总
export interface ParticipantSummary {
  userId: string
  userName: string
  items: OrderItem[]
  subtotal: number
  extraShare: number
  total: number
}

// 用户统计
export interface UserStats {
  totalOrders: number
  totalSpent: number
}

// 辅助函数：生成唯一ID
export function generateId(): string {
  const timestamp = Date.now().toString(36)
  const random = Math.random().toString(36).substring(2, 8)
  return `${timestamp}-${random}`
}

// 辅助函数：计算拼单进度（0-100）
export function calcProgress(order: GroupOrder): number {
  if (order.targetType === TargetType.COUNT) {
    const uniqueUsers = getUniqueUserCount(order)
    return Math.min(100, Math.round((uniqueUsers / order.targetValue) * 100))
  } else {
    const total = calcOrderTotal(order)
    return Math.min(100, Math.round((total / order.targetValue) * 100))
  }
}

// 辅助函数：获取参与人数
export function getUniqueUserCount(order: GroupOrder): number {
  const userIds = new Set<string>()
  for (const item of order.items) {
    userIds.add(item.userId)
  }
  return userIds.size
}

// 辅助函数：计算总金额
export function calcOrderTotal(order: GroupOrder): number {
  let total = 0
  for (const item of order.items) {
    total += item.price
  }
  return total
}

// 辅助函数：计算AA分摊
export function calcSplit(order: GroupOrder): ParticipantSummary[] {
  const userMap = new Map<string, ParticipantSummary>()

  for (const item of order.items) {
    if (!userMap.has(item.userId)) {
      const summary: ParticipantSummary = {
        userId: item.userId,
        userName: item.userName,
        items: [],
        subtotal: 0,
        extraShare: 0,
        total: 0
      }
      userMap.set(item.userId, summary)
    }
    const summary = userMap.get(item.userId)!
    summary.items.push(item)
    summary.subtotal += item.price
  }

  const participantCount = userMap.size
  const extraPerPerson = participantCount > 0 ? order.extraFee / participantCount : 0

  const result: ParticipantSummary[] = []
  userMap.forEach((summary) => {
    if (order.splitMode === SplitMode.EQUAL) {
      const totalWithExtra = calcOrderTotal(order) + order.extraFee
      summary.total = Math.round((totalWithExtra / participantCount) * 100) / 100
      summary.extraShare = 0
    } else if (order.splitMode === SplitMode.TREAT) {
      summary.total = 0
      summary.extraShare = 0
    } else {
      summary.extraShare = Math.round(extraPerPerson * 100) / 100
      summary.total = Math.round((summary.subtotal + summary.extraShare) * 100) / 100
    }
    result.push(summary)
  })

  return result
}

// 辅助函数：判断是否达到目标
export function isTargetReached(order: GroupOrder): boolean {
  if (order.targetType === TargetType.COUNT) {
    return getUniqueUserCount(order) >= order.targetValue
  } else {
    return calcOrderTotal(order) >= order.targetValue
  }
}

// 辅助函数：复制拼单对象（ArkTS不支持对象spread）
export function copyOrder(order: GroupOrder): GroupOrder {
  const copied: GroupOrder = {
    id: order.id,
    category: order.category,
    title: order.title,
    creatorId: order.creatorId,
    creatorName: order.creatorName,
    targetType: order.targetType,
    targetValue: order.targetValue,
    splitMode: order.splitMode,
    extraFee: order.extraFee,
    note: order.note,
    status: order.status,
    items: order.items,
    createdAt: order.createdAt,
    updatedAt: order.updatedAt
  }
  return copied
}

// 辅助函数：获取进度描述文本
export function getProgressText(order: GroupOrder): string {
  if (order.targetType === TargetType.COUNT) {
    const current = getUniqueUserCount(order)
    const diff = order.targetValue - current
    if (diff <= 0) return '已凑够人数'
    return `还差 ${diff} 人`
  } else {
    const current = calcOrderTotal(order)
    const diff = order.targetValue - current
    if (diff <= 0) return '已达起送价'
    return `还差 ¥${diff.toFixed(0)}`
  }
}
