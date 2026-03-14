import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'
import { GroupOrder, UserStats } from './OrderModel'
import { OrderStatus } from '../common/Constants'

const STORE_NAME = 'group_buy_store'
const KEY_ORDERS = 'orders'
const KEY_USER_STATS = 'user_stats'

// 拼单数据持久化管理
export class OrderStore {
  private static instance: OrderStore | null = null
  private store: preferences.Preferences | null = null
  private orders: GroupOrder[] = []

  private constructor() {}

  static getInstance(): OrderStore {
    if (!OrderStore.instance) {
      OrderStore.instance = new OrderStore()
    }
    return OrderStore.instance
  }

  // 初始化（在 EntryAbility.onCreate 中调用一次）
  async init(context: Context): Promise<void> {
    try {
      this.store = preferences.getPreferencesSync(context, { name: STORE_NAME })
      await this.loadOrders()
    } catch (e) {
      console.error(`OrderStore init failed: ${JSON.stringify(e)}`)
    }
  }

  // 从本地加载全部拼单
  private async loadOrders(): Promise<void> {
    if (!this.store) return
    try {
      const json = this.store.getSync(KEY_ORDERS, '[]') as string
      this.orders = JSON.parse(json) as GroupOrder[]
    } catch (e) {
      console.error(`loadOrders failed: ${JSON.stringify(e)}`)
      this.orders = []
    }
  }

  // 保存全部拼单到本地
  private async saveOrders(): Promise<void> {
    if (!this.store) return
    try {
      this.store.putSync(KEY_ORDERS, JSON.stringify(this.orders))
      this.store.flush()
    } catch (e) {
      console.error(`saveOrders failed: ${JSON.stringify(e)}`)
    }
  }

  // 获取进行中的拼单
  getActiveOrders(): GroupOrder[] {
    return this.orders.filter(o =>
      o.status === OrderStatus.GATHERING ||
      o.status === OrderStatus.READY ||
      o.status === OrderStatus.ORDERED ||
      o.status === OrderStatus.ARRIVED
    ).sort((a, b) => b.updatedAt - a.updatedAt)
  }

  // 获取历史拼单（已完成/已取消）
  getHistoryOrders(): GroupOrder[] {
    return this.orders.filter(o =>
      o.status === OrderStatus.COMPLETED ||
      o.status === OrderStatus.CANCELLED ||
      o.status === OrderStatus.EXPIRED
    ).sort((a, b) => b.updatedAt - a.updatedAt)
  }

  // 根据ID查找拼单
  getOrderById(id: string): GroupOrder | undefined {
    return this.orders.find(o => o.id === id)
  }

  // 添加新拼单
  async addOrder(order: GroupOrder): Promise<void> {
    this.orders.unshift(order)
    await this.saveOrders()
  }

  // 更新拼单
  async updateOrder(order: GroupOrder): Promise<void> {
    const index = this.orders.findIndex(o => o.id === order.id)
    if (index >= 0) {
      this.orders[index] = order
    } else {
      this.orders.unshift(order)
    }
    await this.saveOrders()
  }

  // 删除拼单
  async removeOrder(orderId: string): Promise<void> {
    this.orders = this.orders.filter(o => o.id !== orderId)
    await this.saveOrders()
  }

  // 获取统计信息
  getStats(): UserStats {
    let totalSpent = 0
    const userId = 'user_self'
    for (const order of this.orders) {
      for (const item of order.items) {
        if (item.userId === userId) {
          totalSpent += item.price
        }
      }
    }
    const stats: UserStats = {
      totalOrders: this.orders.length,
      totalSpent: totalSpent
    }
    return stats
  }

  // 清理过期拼单（超过24小时未凑齐的自动过期）
  async cleanExpired(): Promise<void> {
    const now = Date.now()
    const expireMs = 24 * 60 * 60 * 1000 // 24小时
    let changed = false

    for (const order of this.orders) {
      if (order.status === OrderStatus.GATHERING && (now - order.createdAt) > expireMs) {
        order.status = OrderStatus.EXPIRED
        order.updatedAt = now
        changed = true
      }
    }

    if (changed) {
      await this.saveOrders()
    }
  }
}
