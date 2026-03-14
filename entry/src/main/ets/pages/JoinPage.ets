import { router } from '@kit.ArkUI'
import { GroupOrder, OrderItem, generateId, getUniqueUserCount,
  calcOrderTotal, getProgressText } from '../model/OrderModel'
import { OrderStore } from '../model/OrderStore'
import { OrderStatus, AppColors, AppSizes, CATEGORY_INFO } from '../common/Constants'
import { getMockActiveOrders, CURRENT_USER_ID, CURRENT_USER_NAME } from '../model/MockData'
import { OrderIdParam, DetailParam } from '../common/RouterParams'

interface JoinParams {
  orderId?: string
}

@Entry
@Component
struct JoinPage {
  @State order: GroupOrder | null = null
  @State myItemName: string = ''
  @State myItemPrice: string = ''
  @State isAlreadyJoined: boolean = false
  @State isExpiredOrFull: boolean = false
  @State items: ItemEntry[] = [{ name: '', price: '' }]

  aboutToAppear(): void {
    try {
      const params = router.getParams() as OrderIdParam
      if (params?.orderId) {
        const stored = OrderStore.getInstance().getOrderById(params.orderId)
        if (stored) {
          this.order = stored
        } else {
          const orders = getMockActiveOrders()
          this.order = orders.find(o => o.id === params.orderId) ?? null
        }

        if (this.order) {
          this.isAlreadyJoined = this.order.items.some(item => item.userId === CURRENT_USER_ID)
          this.isExpiredOrFull = this.order.status !== OrderStatus.GATHERING &&
            this.order.status !== OrderStatus.READY
        }
      }
    } catch (e) { /* ignore */ }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onClick(() => { try { router.back() } catch (e) { /* ignore */ } })
          .padding({ right: 16 })

        Text('加入拼单')
          .fontSize(AppSizes.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)

        Blank()
      }
      .width('100%')
      .padding({
        left: AppSizes.PADDING_LG,
        right: AppSizes.PADDING_LG,
        top: AppSizes.PADDING_MD,
        bottom: AppSizes.PADDING_SM
      })

      if (this.order === null) {
        // 拼单不存在
        this.ErrorState('😕', '拼单不存在', '可能已被删除或链接失效')
      } else if (this.isAlreadyJoined) {
        // 已在拼单中
        this.ErrorState('✅', '你已在这个拼单中', '点击下方按钮查看详情')
        Button('查看拼单详情')
          .width('80%')
          .height(44)
          .fontSize(AppSizes.FONT_MD)
          .fontColor(Color.White)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(AppSizes.RADIUS_LG)
          .margin({ top: 20 })
          .onClick(() => {
            try {
              const p = new OrderIdParam()
              p.orderId = this.order!.id
              router.replaceUrl({ url: 'pages/DetailPage', params: p })
            } catch (e) { /* ignore */ }
          })
      } else if (this.isExpiredOrFull) {
        // 拼单已结束
        this.ErrorState('⏰', '拼单已结束', `当前状态：${this.order!.status}`)
        Button('返回首页')
          .width('80%')
          .height(44)
          .fontSize(AppSizes.FONT_MD)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(AppColors.PRIMARY_LIGHT)
          .borderRadius(AppSizes.RADIUS_LG)
          .margin({ top: 20 })
          .onClick(() => { try { router.back() } catch (e) { /* ignore */ } })
      } else {
        // 正常加入流程
        Scroll() {
          Column() {
            // 拼单信息卡片
            this.OrderInfoCard()

            // 已参与人列表
            this.ExistingParticipants()

            // 我要点什么
            this.MyItemsInput()
          }
          .width('100%')
          .padding({
            left: AppSizes.PADDING_LG,
            right: AppSizes.PADDING_LG,
            bottom: 100
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        // 底部加入按钮
        Row() {
          Button('✅ 加入拼单')
            .width('100%')
            .height(48)
            .fontSize(AppSizes.FONT_LG)
            .fontColor(Color.White)
            .backgroundColor(this.hasValidItem() ? AppColors.PRIMARY : '#CCCCCC')
            .borderRadius(AppSizes.RADIUS_LG)
            .enabled(this.hasValidItem())
            .onClick(() => { this.joinOrder() })
        }
        .width('100%')
        .padding({
          left: AppSizes.PADDING_LG,
          right: AppSizes.PADDING_LG,
          top: AppSizes.PADDING_SM,
          bottom: AppSizes.PADDING_LG
        })
        .backgroundColor(AppColors.BG_CARD)
        .shadow({
          radius: 8,
          color: 'rgba(0,0,0,0.08)',
          offsetX: 0,
          offsetY: -2
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  ErrorState(icon: string, title: string, desc: string) {
    Column() {
      Text(icon)
        .fontSize(48)
        .margin({ bottom: 12 })
      Text(title)
        .fontSize(AppSizes.FONT_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
      Text(desc)
        .fontSize(AppSizes.FONT_SM)
        .fontColor(AppColors.TEXT_HINT)
        .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 80 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  OrderInfoCard() {
    Column() {
      // 品类图标 + 标题
      Row() {
        Text(CATEGORY_INFO[this.order!.category]?.icon ?? '📦')
          .fontSize(36)
          .margin({ right: 12 })

        Column() {
          Text(this.order!.title)
            .fontSize(AppSizes.FONT_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)

          Text(`发起人：${this.order!.creatorName}`)
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 进度信息
      Row() {
        Column() {
          Text(`${getUniqueUserCount(this.order!)}人`)
            .fontSize(AppSizes.FONT_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY)
          Text('已加入')
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_HINT)
        }
        .layoutWeight(1)

        Column() {
          Text(`¥${calcOrderTotal(this.order!).toFixed(0)}`)
            .fontSize(AppSizes.FONT_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY)
          Text('当前总额')
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_HINT)
        }
        .layoutWeight(1)

        Column() {
          Text(getProgressText(this.order!))
            .fontSize(AppSizes.FONT_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WARNING)
          Text('距目标')
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_HINT)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 16 })
      .padding(12)
      .borderRadius(8)
      .backgroundColor(AppColors.BG_PAGE)

      // 备注
      if (this.order!.note) {
        Row() {
          Text(`📝 ${this.order!.note}`)
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding(AppSizes.PADDING_MD)
    .borderRadius(AppSizes.RADIUS_MD)
    .backgroundColor(AppColors.BG_CARD)
    .margin({ top: AppSizes.PADDING_SM })
  }

  @Builder
  ExistingParticipants() {
    Column() {
      Text('已参与')
        .fontSize(AppSizes.FONT_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ bottom: 8 })

      ForEach(this.order!.items, (item: OrderItem) => {
        Row() {
          Text(`${item.userName}`)
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_SECONDARY)
            .layoutWeight(1)
          Text(`${item.itemName} ¥${item.price.toFixed(0)}`)
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
      }, (item: OrderItem) => item.id)
    }
    .width('100%')
    .padding(AppSizes.PADDING_MD)
    .borderRadius(AppSizes.RADIUS_MD)
    .backgroundColor(AppColors.BG_CARD)
    .margin({ top: AppSizes.PADDING_SM })
  }

  @Builder
  MyItemsInput() {
    Column() {
      Text('我要点')
        .fontSize(AppSizes.FONT_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ bottom: 12 })

      ForEach(this.items, (item: ItemEntry, index: number) => {
        Row() {
          TextInput({ placeholder: '商品名', text: item.name })
            .onChange((v: string) => {
              this.items[index] = { name: v, price: this.items[index].price }
            })
            .height(44)
            .borderRadius(AppSizes.RADIUS_SM)
            .backgroundColor('#F8F8F8')
            .padding({ left: 12, right: 12 })
            .layoutWeight(3)

          Text('¥')
            .fontSize(AppSizes.FONT_MD)
            .fontColor(AppColors.TEXT_HINT)
            .margin({ left: 8, right: 4 })

          TextInput({ placeholder: '价格', text: item.price })
            .onChange((v: string) => {
              this.items[index] = { name: this.items[index].name, price: v }
            })
            .type(InputType.NUMBER_DECIMAL)
            .height(44)
            .borderRadius(AppSizes.RADIUS_SM)
            .backgroundColor('#F8F8F8')
            .padding({ left: 12, right: 12 })
            .layoutWeight(1)

          if (this.items.length > 1) {
            Text('✕')
              .fontSize(18)
              .fontColor(AppColors.DANGER)
              .margin({ left: 8 })
              .onClick(() => {
                this.items.splice(index, 1)
                this.items = [...this.items]
              })
          }
        }
        .width('100%')
        .margin({ bottom: 8 })
      }, (_item: ItemEntry, index: number) => `join_item_${index}_${this.items.length}`)

      Row() {
        Text('＋ 再加一样')
          .fontSize(AppSizes.FONT_MD)
          .fontColor(AppColors.PRIMARY)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 8 })
      .onClick(() => {
        this.items = [...this.items, { name: '', price: '' }]
      })
    }
    .width('100%')
    .padding(AppSizes.PADDING_MD)
    .borderRadius(AppSizes.RADIUS_MD)
    .backgroundColor(AppColors.BG_CARD)
    .margin({ top: AppSizes.PADDING_SM })
  }

  private hasValidItem(): boolean {
    for (const item of this.items) {
      if (item.name.trim() && item.price.trim()) {
        const price = Number(item.price)
        if (!isNaN(price) && price > 0) return true
      }
    }
    return false
  }

  private joinOrder(): void {
    if (!this.order) return
    const now = Date.now()

    for (const item of this.items) {
      if (item.name.trim() && item.price.trim()) {
        const price = Number(item.price)
        if (!isNaN(price) && price > 0) {
          const newItem: OrderItem = {
            id: generateId(),
            orderId: this.order.id,
            userId: CURRENT_USER_ID,
            userName: CURRENT_USER_NAME,
            itemName: item.name.trim(),
            price: price,
            createdAt: now
          }
          this.order.items.push(newItem)
        }
      }
    }

    this.order.updatedAt = now
    // 持久化
    OrderStore.getInstance().updateOrder(this.order)

    // 跳转到详情页
    try {
      const p = new DetailParam()
      p.orderId = this.order.id
      p.newOrder = this.order
      router.replaceUrl({ url: 'pages/DetailPage', params: p })
    } catch (e) { /* ignore */ }
  }
}

interface ItemEntry {
  name: string
  price: string
}
