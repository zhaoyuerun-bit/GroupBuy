import { GroupOrder } from '../model/OrderModel'

// 跳转到 JoinPage / DetailPage 的参数
export class OrderIdParam {
  orderId: string = ''
}

// 跳转到 CreatePage 的复用参数
export class ReuseParam {
  reuseTitle: string = ''
  reuseCategory: string = ''
}

// 跳转到 DetailPage 携带新建拼单
export class DetailParam {
  orderId: string = ''
  newOrder: GroupOrder | null = null
}
