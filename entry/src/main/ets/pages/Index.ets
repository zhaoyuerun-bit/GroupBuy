import { router } from '@kit.ArkUI'
import { GroupOrder, calcOrderTotal, getUniqueUserCount } from '../model/OrderModel'
import { OrderStore } from '../model/OrderStore'
import { getMockActiveOrders, getMockHistoryOrders } from '../model/MockData'
import { OrderStatus, AppColors, AppSizes, CATEGORY_INFO } from '../common/Constants'
import { OrderCard } from '../components/OrderCard'
import { OrderIdParam, ReuseParam } from '../common/RouterParams'

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State activeOrders: GroupOrder[] = []
  @State historyOrders: GroupOrder[] = []
  private store: OrderStore = OrderStore.getInstance()
  @StorageProp('pendingOrderId') pendingOrderId: string = ''

  aboutToAppear(): void {
    this.loadData()

    // 如果从碰一碰/链接进入，跳转到加入页
    if (this.pendingOrderId) {
      try {
        const p = new OrderIdParam()
        p.orderId = this.pendingOrderId
        router.pushUrl({ url: 'pages/JoinPage', params: p })
      } catch (e) {
        console.error(`router error: ${JSON.stringify(e)}`)
      }
      AppStorage.setOrCreate('pendingOrderId', '')
    }
  }

  onPageShow(): void {
    // 每次回到首页刷新数据（从DetailPage/CreatePage返回时）
    this.loadData()
  }

  private loadData(): void {
    const storeActive = this.store.getActiveOrders()
    const storeHistory = this.store.getHistoryOrders()
    // 如果本地无数据，加载Mock数据供演示
    if (storeActive.length === 0 && storeHistory.length === 0) {
      this.activeOrders = getMockActiveOrders()
      this.historyOrders = getMockHistoryOrders()
    } else {
      this.activeOrders = storeActive
      this.historyOrders = storeHistory
    }
  }

  @Builder
  TabBarBuilder(title: string, icon: string, index: number) {
    Column() {
      Text(icon)
        .fontSize(22)
      Text(title)
        .fontSize(11)
        .fontColor(this.currentTab === index ? AppColors.PRIMARY : AppColors.TEXT_HINT)
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
      // Tab 1: 首页
      TabContent() {
        this.HomeContent()
      }
      .tabBar(this.TabBarBuilder('首页', '🏠', 0))

      // Tab 2: 我的
      TabContent() {
        this.ProfileContent()
      }
      .tabBar(this.TabBarBuilder('我的', '👤', 1))
    }
    .onChange((index: number) => {
      this.currentTab = index
    })
    .barHeight(56)
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  HomeContent() {
    Column() {
      // 顶部标题栏（白底）
      Row() {
        Text('校园拼单')
          .fontSize(AppSizes.FONT_HEADER)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)

        Blank()

        // 发起拼单按钮
        Button('＋ 发起拼单')
          .fontSize(AppSizes.FONT_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_WHITE)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(AppSizes.RADIUS_LG)
          .height(36)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            try { router.pushUrl({ url: 'pages/CreatePage' }) } catch (e) { /* ignore */ }
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: AppSizes.PADDING_MD, right: AppSizes.PADDING_MD })
      .backgroundColor(AppColors.BG_CARD)
      .alignItems(VerticalAlign.Center)

      // 可滚动内容区
      Scroll() {
        Column() {
          // 进行中的拼单
          if (this.activeOrders.length > 0) {
            this.SectionHeader('进行中', `${this.activeOrders.length}`)
            ForEach(this.activeOrders, (order: GroupOrder) => {
              OrderCard({
                order: order,
                onCardClick: () => {
                  try {
                    const p = new OrderIdParam()
                    p.orderId = order.id
                    router.pushUrl({ url: 'pages/DetailPage', params: p })
                  } catch (e) { /* ignore */ }
                }
              })
              .margin({ bottom: AppSizes.PADDING_SM })
            }, (order: GroupOrder) => order.id)
          } else {
            // 空状态
            Column() {
              Text('📦')
                .fontSize(48)
                .margin({ bottom: 12 })
              Text('暂无进行中的拼单')
                .fontSize(AppSizes.FONT_LG)
                .fontColor(AppColors.TEXT_HINT)
              Text('碰一碰好友加入拼单，或发起你的第一单')
                .fontSize(AppSizes.FONT_SM)
                .fontColor(AppColors.TEXT_HINT)
                .margin({ top: 4 })
            }
            .width('100%')
            .padding({ top: 60, bottom: 60 })
            .justifyContent(FlexAlign.Center)
          }

          // 历史拼单（一键复用）
          if (this.historyOrders.length > 0) {
            this.SectionHeader('最近完成', '')
            ForEach(this.historyOrders, (order: GroupOrder) => {
              this.HistoryCard(order)
            }, (order: GroupOrder) => order.id)
          }
        }
        .width('100%')
        .padding({
          left: AppSizes.PADDING_MD,
          right: AppSizes.PADDING_MD,
          bottom: AppSizes.PADDING_LG
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  SectionHeader(title: string, badge: string) {
    Row() {
      Row()
        .width(3)
        .height(16)
        .borderRadius(2)
        .backgroundColor(AppColors.PRIMARY)
        .margin({ right: 8 })

      Text(title)
        .fontSize(AppSizes.FONT_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      if (badge) {
        Text(` ${badge}`)
          .fontSize(AppSizes.FONT_SM)
          .fontColor(AppColors.TEXT_HINT)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: AppSizes.PADDING_MD, bottom: AppSizes.PADDING_SM })
  }

  @Builder
  HistoryCard(order: GroupOrder) {
    Row() {
      Column() {
        Text(CATEGORY_INFO[order.category]?.icon ?? '📦')
          .fontSize(22)
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .borderRadius(AppSizes.RADIUS_SM)
      .backgroundColor(AppColors.BG_INPUT)
      .margin({ right: 12 })

      Column() {
        Text(order.title)
          .fontSize(AppSizes.FONT_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${getUniqueUserCount(order)}人参与 · ¥${calcOrderTotal(order).toFixed(0)}`)
          .fontSize(AppSizes.FONT_SM)
          .fontColor(AppColors.TEXT_HINT)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button('再来一单')
        .fontSize(AppSizes.FONT_SM)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.PRIMARY)
        .backgroundColor(AppColors.PRIMARY_LIGHT)
        .borderRadius(AppSizes.RADIUS_LG)
        .height(32)
        .padding({ left: 12, right: 12 })
        .onClick(() => {
          try {
            const p = new ReuseParam()
            p.reuseTitle = order.title
            p.reuseCategory = order.category
            router.pushUrl({ url: 'pages/CreatePage', params: p })
          } catch (e) { /* ignore */ }
        })
    }
    .width('100%')
    .padding(AppSizes.PADDING_MD)
    .borderRadius(AppSizes.RADIUS_MD)
    .backgroundColor(AppColors.BG_CARD)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetX: 0, offsetY: 2 })
    .margin({ bottom: AppSizes.PADDING_SM })
  }

  @Builder
  ProfileContent() {
    Column() {
      // 顶部标题
      Text('我的')
        .fontSize(AppSizes.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .padding({
          left: AppSizes.PADDING_LG,
          right: AppSizes.PADDING_LG,
          top: AppSizes.PADDING_MD,
          bottom: AppSizes.PADDING_MD
        })

      // 统计卡片（橙色渐变背景）
      Row() {
        this.StatItem('累计拼单', `${this.activeOrders.length + this.historyOrders.length}`, '单')
        Column()
          .width(1)
          .height(40)
          .backgroundColor('rgba(255,255,255,0.3)')
        this.StatItem('累计消费', `¥${this.calcTotalSpent().toFixed(0)}`, '')
      }
      .width('100%')
      .padding(AppSizes.PADDING_XL)
      .margin({ left: AppSizes.PADDING_MD, right: AppSizes.PADDING_MD })
      .borderRadius(AppSizes.RADIUS_MD)
      .backgroundColor(AppColors.PRIMARY)
      .justifyContent(FlexAlign.SpaceEvenly)

      // 拼单记录
      Scroll() {
        Column() {
          this.SectionHeader('拼单记录', '')

          ForEach(
            [...this.activeOrders, ...this.historyOrders],
            (order: GroupOrder) => {
              Row() {
                Text(CATEGORY_INFO[order.category]?.icon ?? '📦')
                  .fontSize(18)
                  .margin({ right: 10 })

                Column() {
                  Text(order.title)
                    .fontSize(AppSizes.FONT_MD)
                    .fontColor(AppColors.TEXT_PRIMARY)
                  Text(this.formatDate(order.createdAt))
                    .fontSize(AppSizes.FONT_SM)
                    .fontColor(AppColors.TEXT_HINT)
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Text(`¥${calcOrderTotal(order).toFixed(0)}`)
                  .fontSize(AppSizes.FONT_MD)
                  .fontColor(AppColors.TEXT_PRIMARY)
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .borderWidth({ bottom: 0.5 })
              .borderColor(AppColors.DIVIDER)
            },
            (order: GroupOrder) => `profile_${order.id}`
          )
        }
        .width('100%')
        .padding({
          left: AppSizes.PADDING_MD,
          right: AppSizes.PADDING_MD,
          bottom: AppSizes.PADDING_LG
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG_PAGE)
  }

  @Builder
  StatItem(label: string, value: string, unit: string) {
    Column() {
      Row() {
        Text(value)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_WHITE)
        if (unit) {
          Text(unit)
            .fontSize(AppSizes.FONT_SM)
            .fontColor('rgba(255,255,255,0.8)')
            .margin({ left: 2 })
        }
      }
      .alignItems(VerticalAlign.Bottom)

      Text(label)
        .fontSize(AppSizes.FONT_SM)
        .fontColor('rgba(255,255,255,0.8)')
        .margin({ top: 4 })
    }
  }

  private calcTotalSpent(): number {
    let total = 0
    for (const order of [...this.activeOrders, ...this.historyOrders]) {
      for (const item of order.items) {
        if (item.userId === 'user_self') {
          total += item.price
        }
      }
    }
    return total
  }

  private formatDate(timestamp: number): string {
    const date = new Date(timestamp)
    return `${date.getMonth() + 1}/${date.getDate()}`
  }
}
