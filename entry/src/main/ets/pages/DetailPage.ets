import { router } from '@kit.ArkUI'
import { GroupOrder, OrderItem, ParticipantSummary, generateId,
  calcProgress, getUniqueUserCount, calcOrderTotal, calcSplit,
  isTargetReached, getProgressText, copyOrder } from '../model/OrderModel'
import { OrderStatus, TargetType, SplitMode, AppColors, AppSizes,
  CATEGORY_INFO, STATUS_INFO } from '../common/Constants'
import { OrderStore } from '../model/OrderStore'
import { getMockActiveOrders, CURRENT_USER_ID, CURRENT_USER_NAME } from '../model/MockData'
import { DetailParam, ReuseParam } from '../common/RouterParams'

interface DetailParams {
  orderId?: string
  newOrder?: GroupOrder
}

interface EditingItem {
  name: string
  price: string
}

@Entry
@Component
struct DetailPage {
  @State order: GroupOrder | null = null
  @State participants: ParticipantSummary[] = []
  @State showSharePanel: boolean = false
  @State showAddItem: boolean = false
  @State newItemName: string = ''
  @State newItemPrice: string = ''
  @State editingItem: EditingItem | null = null

  private store: OrderStore = OrderStore.getInstance()

  aboutToAppear(): void {
    try {
      const params = router.getParams() as DetailParam
      if (params?.newOrder) {
        this.order = params.newOrder
      } else if (params?.orderId) {
        const stored = this.store.getOrderById(params.orderId)
        if (stored) {
          this.order = stored
        } else {
          const orders = getMockActiveOrders()
          this.order = orders.find(o => o.id === params.orderId) ?? null
        }
      }
    } catch (e) { /* ignore */ }
    if (this.order) {
      this.participants = calcSplit(this.order)
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部导航
        Row() {
          Text('←')
            .fontSize(24)
            .fontColor(AppColors.TEXT_PRIMARY)
            .onClick(() => { try { router.back() } catch (e) { /* ignore */ } })
            .padding({ right: 16 })

          Text(this.order?.title ?? '拼单详情')
            .fontSize(AppSizes.FONT_TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('📤')
            .fontSize(22)
            .onClick(() => { this.showSharePanel = true })
        }
        .width('100%')
        .padding({
          left: AppSizes.PADDING_LG,
          right: AppSizes.PADDING_LG,
          top: AppSizes.PADDING_MD,
          bottom: AppSizes.PADDING_SM
        })

        if (this.order) {
          Scroll() {
            Column() {
              // 状态卡片
              this.StatusCard()

              // 参与人 & 选品
              this.ParticipantsSection()

              // 费用汇总
              this.SummarySection()

              // 我的选品操作
              this.MyItemsSection()

              // 占位，防止底部按钮遮挡
              Row().height(100)
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
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG_PAGE)

      // 底部操作栏
      if (this.order) {
        this.BottomBar()
      }

      // 分享面板
      if (this.showSharePanel) {
        this.SharePanel()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  StatusCard() {
    Column() {
      // 状态标签 + 品类
      Row() {
        Text(CATEGORY_INFO[this.order!.category]?.icon ?? '📦')
          .fontSize(28)
          .margin({ right: 10 })

        Column() {
          Text(STATUS_INFO[this.order!.status]?.label ?? '')
            .fontSize(AppSizes.FONT_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(STATUS_INFO[this.order!.status]?.color ?? AppColors.TEXT_PRIMARY)

          if (this.order!.note) {
            Text(this.order!.note)
              .fontSize(AppSizes.FONT_SM)
              .fontColor(AppColors.TEXT_HINT)
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text(`¥${calcOrderTotal(this.order!).toFixed(0)}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(this.order!.targetType === TargetType.AMOUNT
            ? `目标¥${this.order!.targetValue}` : `目标${this.order!.targetValue}人`)
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_HINT)
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      // 进度条
      if (this.order!.status === OrderStatus.GATHERING || this.order!.status === OrderStatus.READY) {
        Column() {
          Row() {
            Text(`👥 ${getUniqueUserCount(this.order!)}人已加入`)
              .fontSize(AppSizes.FONT_SM)
              .fontColor(AppColors.TEXT_SECONDARY)
            Blank()
            Text(getProgressText(this.order!))
              .fontSize(AppSizes.FONT_SM)
              .fontWeight(FontWeight.Medium)
              .fontColor(isTargetReached(this.order!) ? AppColors.SUCCESS : AppColors.PRIMARY)
          }
          .width('100%')

          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(8)
              .borderRadius(4)
              .backgroundColor('#F0F0F0')

            Row()
              .width(`${calcProgress(this.order!)}%`)
              .height(8)
              .borderRadius(4)
              .backgroundColor(isTargetReached(this.order!) ? AppColors.SUCCESS : AppColors.PRIMARY)
          }
          .width('100%')
          .height(8)
          .margin({ top: 8 })
        }
        .margin({ top: 12 })
      }

      // 已下单/已到货提示
      if (this.order!.status === OrderStatus.ORDERED) {
        Row() {
          Text('🚴 已下单，等待送达…')
            .fontSize(AppSizes.FONT_MD)
            .fontColor('#007AFF')
        }
        .width('100%')
        .margin({ top: 12 })
        .padding(10)
        .borderRadius(8)
        .backgroundColor('#E3F2FD')
      }

      if (this.order!.status === OrderStatus.ARRIVED) {
        Row() {
          Text('📦 外卖到了！快来取！')
            .fontSize(AppSizes.FONT_MD)
            .fontColor(AppColors.SUCCESS)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .margin({ top: 12 })
        .padding(10)
        .borderRadius(8)
        .backgroundColor('#E8F5E9')
      }
    }
    .width('100%')
    .padding(AppSizes.PADDING_MD)
    .borderRadius(AppSizes.RADIUS_MD)
    .backgroundColor(AppColors.BG_CARD)
    .margin({ top: AppSizes.PADDING_SM })
  }

  @Builder
  ParticipantsSection() {
    Column() {
      Text('参与人 & 选品')
        .fontSize(AppSizes.FONT_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ bottom: 12 })

      ForEach(this.participants, (p: ParticipantSummary) => {
        Column() {
          // 参与人名
          Row() {
            Text(`👤 ${p.userName}`)
              .fontSize(AppSizes.FONT_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
            if (p.userId === this.order?.creatorId) {
              Text('发起人')
                .fontSize(10)
                .fontColor(AppColors.PRIMARY)
                .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                .borderRadius(4)
                .backgroundColor(AppColors.PRIMARY_LIGHT)
                .margin({ left: 6 })
            }
            Blank()
            Text(`¥${p.subtotal.toFixed(0)}`)
              .fontSize(AppSizes.FONT_MD)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')

          // 该参与人的选品
          ForEach(p.items, (item: OrderItem) => {
            Row() {
              Text(`· ${item.itemName}`)
                .fontSize(AppSizes.FONT_SM)
                .fontColor(AppColors.TEXT_SECONDARY)
                .layoutWeight(1)
              Text(`¥${item.price.toFixed(0)}`)
                .fontSize(AppSizes.FONT_SM)
                .fontColor(AppColors.TEXT_HINT)
            }
            .width('100%')
            .padding({ left: 20, top: 4 })
          }, (item: OrderItem) => item.id)
        }
        .width('100%')
        .padding({ bottom: 12 })
        .borderWidth({ bottom: 0.5 })
        .borderColor(AppColors.DIVIDER)
        .margin({ bottom: 8 })
      }, (p: ParticipantSummary) => p.userId)

      // 等待加入占位
      if (this.order!.targetType === TargetType.COUNT &&
        getUniqueUserCount(this.order!) < this.order!.targetValue) {
        Row() {
          Text('👤 等待加入…')
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('100%')
        .padding({ top: 4 })
      }
    }
    .width('100%')
    .padding(AppSizes.PADDING_MD)
    .borderRadius(AppSizes.RADIUS_MD)
    .backgroundColor(AppColors.BG_CARD)
    .margin({ top: AppSizes.PADDING_SM })
  }

  @Builder
  SummarySection() {
    Column() {
      Text('费用汇总')
        .fontSize(AppSizes.FONT_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ bottom: 12 })

      Row() {
        Text('商品总计')
          .fontSize(AppSizes.FONT_MD)
          .fontColor(AppColors.TEXT_SECONDARY)
        Blank()
        Text(`¥${calcOrderTotal(this.order!).toFixed(2)}`)
          .fontSize(AppSizes.FONT_MD)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width('100%')

      if (this.order!.extraFee > 0 && this.order!.splitMode === SplitMode.BY_ITEM) {
        Row() {
          Text('配送费（均摊）')
            .fontSize(AppSizes.FONT_MD)
            .fontColor(AppColors.TEXT_SECONDARY)
          Blank()
          Text(`¥${this.order!.extraFee.toFixed(2)}`)
            .fontSize(AppSizes.FONT_MD)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .width('100%')
        .margin({ top: 6 })
      }

      Divider().margin({ top: 10, bottom: 10 }).color(AppColors.DIVIDER)

      // AA明细
      Text(this.getSplitModeLabel())
        .fontSize(AppSizes.FONT_SM)
        .fontColor(AppColors.TEXT_HINT)
        .margin({ bottom: 8 })

      ForEach(this.participants, (p: ParticipantSummary) => {
        Row() {
          Text(p.userName)
            .fontSize(AppSizes.FONT_MD)
            .fontColor(AppColors.TEXT_SECONDARY)
            .layoutWeight(1)
          Text(`¥${p.total.toFixed(2)}`)
            .fontSize(AppSizes.FONT_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
      }, (p: ParticipantSummary) => `summary_${p.userId}`)
    }
    .width('100%')
    .padding(AppSizes.PADDING_MD)
    .borderRadius(AppSizes.RADIUS_MD)
    .backgroundColor(AppColors.BG_CARD)
    .margin({ top: AppSizes.PADDING_SM })
  }

  @Builder
  MyItemsSection() {
    if (this.isEditable()) {
      Column() {
        Text('我的选品')
          .fontSize(AppSizes.FONT_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ bottom: 12 })

        // 我的现有选品
        ForEach(this.getMyItems(), (item: OrderItem) => {
          Row() {
            Text(item.itemName)
              .fontSize(AppSizes.FONT_MD)
              .fontColor(AppColors.TEXT_PRIMARY)
              .layoutWeight(1)

            Text(`¥${item.price.toFixed(0)}`)
              .fontSize(AppSizes.FONT_MD)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ right: 12 })

            Text('删除')
              .fontSize(AppSizes.FONT_SM)
              .fontColor(AppColors.DANGER)
              .onClick(() => {
                this.removeItem(item.id)
              })
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .borderWidth({ bottom: 0.5 })
          .borderColor(AppColors.DIVIDER)
        }, (item: OrderItem) => item.id)

        // 添加新选品
        if (this.showAddItem) {
          Row() {
            TextInput({ placeholder: '商品名', text: this.newItemName })
              .onChange((v: string) => { this.newItemName = v })
              .height(40)
              .borderRadius(AppSizes.RADIUS_SM)
              .backgroundColor('#F8F8F8')
              .padding({ left: 12, right: 12 })
              .layoutWeight(3)

            Text('¥')
              .fontSize(AppSizes.FONT_MD)
              .fontColor(AppColors.TEXT_HINT)
              .margin({ left: 8, right: 4 })

            TextInput({ placeholder: '价格', text: this.newItemPrice })
              .onChange((v: string) => { this.newItemPrice = v })
              .type(InputType.NUMBER_DECIMAL)
              .height(40)
              .borderRadius(AppSizes.RADIUS_SM)
              .backgroundColor('#F8F8F8')
              .padding({ left: 12, right: 12 })
              .layoutWeight(1)

            Text('✓')
              .fontSize(20)
              .fontColor(AppColors.SUCCESS)
              .margin({ left: 8 })
              .onClick(() => { this.addNewItem() })
          }
          .width('100%')
          .margin({ top: 8 })
        }

        Row() {
          Text('＋ 再加一样')
            .fontSize(AppSizes.FONT_MD)
            .fontColor(AppColors.PRIMARY)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 12 })
        .onClick(() => {
          this.showAddItem = true
          this.newItemName = ''
          this.newItemPrice = ''
        })
      }
      .width('100%')
      .padding(AppSizes.PADDING_MD)
      .borderRadius(AppSizes.RADIUS_MD)
      .backgroundColor(AppColors.BG_CARD)
      .margin({ top: AppSizes.PADDING_SM })
    }
  }

  @Builder
  BottomBar() {
    Row() {
      if (this.order!.status === OrderStatus.GATHERING || this.order!.status === OrderStatus.READY) {
        // 邀请更多人
        Button('📤 邀请')
          .fontSize(AppSizes.FONT_MD)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(AppColors.PRIMARY_LIGHT)
          .borderRadius(AppSizes.RADIUS_LG)
          .height(44)
          .layoutWeight(1)
          .margin({ right: 8 })
          .onClick(() => { this.showSharePanel = true })

        // 发起人：凑够了去下单
        if (this.order!.creatorId === CURRENT_USER_ID) {
          Button(isTargetReached(this.order!) ? '✅ 凑够了，去下单' : '等待凑齐中…')
            .fontSize(AppSizes.FONT_MD)
            .fontColor(Color.White)
            .backgroundColor(isTargetReached(this.order!) ? AppColors.PRIMARY : '#CCCCCC')
            .borderRadius(AppSizes.RADIUS_LG)
            .height(44)
            .layoutWeight(2)
            .enabled(isTargetReached(this.order!))
            .onClick(() => { this.updateStatus(OrderStatus.ORDERED) })
        }
      }

      if (this.order!.status === OrderStatus.ORDERED && this.order!.creatorId === CURRENT_USER_ID) {
        Button('📦 已到货，通知大家')
          .fontSize(AppSizes.FONT_MD)
          .fontColor(Color.White)
          .backgroundColor(AppColors.SUCCESS)
          .borderRadius(AppSizes.RADIUS_LG)
          .height(44)
          .layoutWeight(1)
          .onClick(() => { this.updateStatus(OrderStatus.ARRIVED) })
      }

      if (this.order!.status === OrderStatus.ARRIVED) {
        Button('✅ 确认收到')
          .fontSize(AppSizes.FONT_MD)
          .fontColor(Color.White)
          .backgroundColor(AppColors.SUCCESS)
          .borderRadius(AppSizes.RADIUS_LG)
          .height(44)
          .layoutWeight(1)
          .onClick(() => { this.updateStatus(OrderStatus.COMPLETED) })
      }

      if (this.order!.status === OrderStatus.COMPLETED) {
        Button('🔄 再来一单')
          .fontSize(AppSizes.FONT_MD)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(AppColors.PRIMARY_LIGHT)
          .borderRadius(AppSizes.RADIUS_LG)
          .height(44)
          .layoutWeight(1)
          .onClick(() => {
            try {
              const p = new ReuseParam()
              p.reuseTitle = this.order!.title
              p.reuseCategory = this.order!.category
              router.replaceUrl({ url: 'pages/CreatePage', params: p })
            } catch (e) { /* ignore */ }
          })
      }
    }
    .width('100%')
    .padding({
      left: AppSizes.PADDING_MD,
      right: AppSizes.PADDING_MD,
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

  @Builder
  SharePanel() {
    Column() {
      // 半透明背景
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => { this.showSharePanel = false })

      // 分享面板
      Column() {
        Text('邀请好友加入')
          .fontSize(AppSizes.FONT_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ bottom: 20 })

        Row() {
          this.ShareOption('📱', '碰一碰')
          this.ShareOption('📷', '二维码')
          this.ShareOption('🔗', '复制链接')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)

        Row() {
          this.ShareOption('💬', '微信好友')
          this.ShareOption('👥', '微信群')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: 16 })

        Button('取消')
          .width('100%')
          .height(44)
          .fontSize(AppSizes.FONT_MD)
          .fontColor(AppColors.TEXT_SECONDARY)
          .backgroundColor('#F8F8F8')
          .borderRadius(AppSizes.RADIUS_LG)
          .margin({ top: 24 })
          .onClick(() => { this.showSharePanel = false })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24, bottom: 40 })
      .borderRadius({ topLeft: 20, topRight: 20 })
      .backgroundColor(AppColors.BG_CARD)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ShareOption(icon: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(32)
      Text(label)
        .fontSize(AppSizes.FONT_SM)
        .fontColor(AppColors.TEXT_SECONDARY)
        .margin({ top: 6 })
    }
    .width(72)
    .height(72)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // TODO: 实现各分享方式
      this.showSharePanel = false
    })
  }

  private isEditable(): boolean {
    return this.order!.status === OrderStatus.GATHERING || this.order!.status === OrderStatus.READY
  }

  private getMyItems(): OrderItem[] {
    return this.order!.items.filter(item => item.userId === CURRENT_USER_ID)
  }

  private removeItem(itemId: string): void {
    this.order!.items = this.order!.items.filter(item => item.id !== itemId)
    this.order!.updatedAt = Date.now()
    this.participants = calcSplit(this.order!)
    this.order = copyOrder(this.order!)
    this.store.updateOrder(this.order!)
  }

  private addNewItem(): void {
    if (!this.newItemName.trim() || !this.newItemPrice.trim()) return
    const price = Number(this.newItemPrice)
    if (isNaN(price) || price <= 0) return

    const newItem: OrderItem = {
      id: generateId(),
      orderId: this.order!.id,
      userId: CURRENT_USER_ID,
      userName: CURRENT_USER_NAME,
      itemName: this.newItemName.trim(),
      price: price,
      createdAt: Date.now()
    }
    this.order!.items.push(newItem)
    this.order!.updatedAt = Date.now()
    this.participants = calcSplit(this.order!)
    this.order = copyOrder(this.order!)
    this.store.updateOrder(this.order!)
    this.showAddItem = false
    this.newItemName = ''
    this.newItemPrice = ''
  }

  private updateStatus(newStatus: OrderStatus): void {
    this.order!.status = newStatus
    this.order!.updatedAt = Date.now()
    this.order = copyOrder(this.order!)
    this.store.updateOrder(this.order!)
  }

  private getSplitModeLabel(): string {
    if (this.order!.splitMode === SplitMode.EQUAL) return '均摊模式'
    if (this.order!.splitMode === SplitMode.TREAT) return '发起人请客'
    return '按实际消费 + 均摊杂费'
  }
}
