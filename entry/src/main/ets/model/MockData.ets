import { GroupOrder, OrderItem } from './OrderModel'
import { OrderCategory, TargetType, OrderStatus, SplitMode } from '../common/Constants'

// 当前用户（模拟）
export const CURRENT_USER_ID: string = 'user_self'
export const CURRENT_USER_NAME: string = '我'

// 模拟数据：进行中的拼单
export function getMockActiveOrders(): GroupOrder[] {
  const now = Date.now()
  return [
    {
      id: 'order_001',
      category: OrderCategory.FOOD,
      title: '沙县小吃（学校北门）',
      creatorId: CURRENT_USER_ID,
      creatorName: CURRENT_USER_NAME,
      targetType: TargetType.AMOUNT,
      targetValue: 30,
      splitMode: SplitMode.BY_ITEM,
      extraFee: 6,
      note: '北门取，大概30分钟',
      status: OrderStatus.GATHERING,
      items: [
        {
          id: 'item_001',
          orderId: 'order_001',
          userId: CURRENT_USER_ID,
          userName: CURRENT_USER_NAME,
          itemName: '蛋炒饭',
          price: 12,
          createdAt: now - 300000
        },
        {
          id: 'item_002',
          orderId: 'order_001',
          userId: 'user_hong',
          userName: '小红',
          itemName: '拌面',
          price: 10,
          createdAt: now - 200000
        },
        {
          id: 'item_003',
          orderId: 'order_001',
          userId: 'user_hua',
          userName: '小华',
          itemName: '炒河粉',
          price: 13,
          createdAt: now - 100000
        }
      ],
      createdAt: now - 300000,
      updatedAt: now - 100000
    },
    {
      id: 'order_002',
      category: OrderCategory.DRINK,
      title: '瑞幸咖啡',
      creatorId: 'user_hong',
      creatorName: '小红',
      targetType: TargetType.COUNT,
      targetValue: 5,
      splitMode: SplitMode.BY_ITEM,
      extraFee: 0,
      note: '满5杯打8折',
      status: OrderStatus.GATHERING,
      items: [
        {
          id: 'item_010',
          orderId: 'order_002',
          userId: 'user_hong',
          userName: '小红',
          itemName: '生椰拿铁',
          price: 19,
          createdAt: now - 720000
        },
        {
          id: 'item_011',
          orderId: 'order_002',
          userId: CURRENT_USER_ID,
          userName: CURRENT_USER_NAME,
          itemName: '美式咖啡',
          price: 13,
          createdAt: now - 600000
        },
        {
          id: 'item_012',
          orderId: 'order_002',
          userId: 'user_li',
          userName: '小李',
          itemName: '橙C美式',
          price: 16,
          createdAt: now - 500000
        },
        {
          id: 'item_013',
          orderId: 'order_002',
          userId: 'user_wang',
          userName: '小王',
          itemName: '丝绒拿铁',
          price: 19,
          createdAt: now - 400000
        }
      ],
      createdAt: now - 720000,
      updatedAt: now - 400000
    }
  ]
}

// 模拟数据：历史拼单
export function getMockHistoryOrders(): GroupOrder[] {
  const now = Date.now()
  const dayMs = 86400000
  return [
    {
      id: 'order_h01',
      category: OrderCategory.FOOD,
      title: '沙县小吃（学校北门）',
      creatorId: CURRENT_USER_ID,
      creatorName: CURRENT_USER_NAME,
      targetType: TargetType.AMOUNT,
      targetValue: 30,
      splitMode: SplitMode.BY_ITEM,
      extraFee: 6,
      note: '',
      status: OrderStatus.COMPLETED,
      items: [
        {
          id: 'item_h01', orderId: 'order_h01', userId: CURRENT_USER_ID,
          userName: CURRENT_USER_NAME, itemName: '蛋炒饭', price: 12, createdAt: now - dayMs
        },
        {
          id: 'item_h02', orderId: 'order_h01', userId: 'user_hong',
          userName: '小红', itemName: '云吞', price: 14, createdAt: now - dayMs
        },
        {
          id: 'item_h03', orderId: 'order_h01', userId: 'user_hua',
          userName: '小华', itemName: '蒸饺', price: 12, createdAt: now - dayMs
        },
        {
          id: 'item_h04', orderId: 'order_h01', userId: 'user_li',
          userName: '小李', itemName: '拌面', price: 10, createdAt: now - dayMs
        }
      ],
      createdAt: now - dayMs,
      updatedAt: now - dayMs + 3600000
    },
    {
      id: 'order_h02',
      category: OrderCategory.FRUIT,
      title: '百果园（芒果拼箱）',
      creatorId: 'user_hua',
      creatorName: '小华',
      targetType: TargetType.COUNT,
      targetValue: 3,
      splitMode: SplitMode.EQUAL,
      extraFee: 0,
      note: '',
      status: OrderStatus.COMPLETED,
      items: [
        {
          id: 'item_h10', orderId: 'order_h02', userId: CURRENT_USER_ID,
          userName: CURRENT_USER_NAME, itemName: '芒果拼箱1/3', price: 15, createdAt: now - 2 * dayMs
        },
        {
          id: 'item_h11', orderId: 'order_h02', userId: 'user_hua',
          userName: '小华', itemName: '芒果拼箱1/3', price: 15, createdAt: now - 2 * dayMs
        },
        {
          id: 'item_h12', orderId: 'order_h02', userId: 'user_hong',
          userName: '小红', itemName: '芒果拼箱1/3', price: 15, createdAt: now - 2 * dayMs
        }
      ],
      createdAt: now - 2 * dayMs,
      updatedAt: now - 2 * dayMs + 7200000
    }
  ]
}
