import { router } from '@kit.ArkUI'
import { OrderCategory, TargetType, SplitMode, OrderStatus, AppColors, AppSizes,
  CATEGORY_INFO, CategoryDisplay } from '../common/Constants'
import { GroupOrder, OrderItem, generateId } from '../model/OrderModel'
import { OrderStore } from '../model/OrderStore'
import { CURRENT_USER_ID, CURRENT_USER_NAME } from '../model/MockData'
import { DetailParam, ReuseParam } from '../common/RouterParams'

interface CreateParams {
  reuseTitle?: string
  reuseCategory?: string
}

interface ItemInput {
  name: string
  price: string
}

@Entry
@Component
struct CreatePage {
  @State selectedCategory: OrderCategory = OrderCategory.FOOD
  @State title: string = ''
  @State targetType: TargetType = TargetType.AMOUNT
  @State targetValue: string = ''
  @State note: string = ''
  @State myItems: ItemInput[] = [{ name: '', price: '' }]
  @State splitMode: SplitMode = SplitMode.BY_ITEM
  @State extraFee: string = ''

  private categories: OrderCategory[] = [
    OrderCategory.FOOD, OrderCategory.DRINK, OrderCategory.FRUIT,
    OrderCategory.DAILY, OrderCategory.EXPRESS, OrderCategory.CUSTOM
  ]

  aboutToAppear(): void {
    try {
      const params = router.getParams() as ReuseParam
      if (params?.reuseTitle) {
        this.title = params.reuseTitle
      }
      if (params?.reuseCategory) {
        this.selectedCategory = params.reuseCategory as OrderCategory
      }
    } catch (e) { /* ignore */ }
  }

  build() {
    Column() {
      // 顶部导航栏（白底，沉浸式）
      Row() {
        Row() {
          Text('‹')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .borderRadius(20)
        .onClick(() => { try { router.back() } catch (e) { /* ignore */ } })

        Text('发起拼单')
          .fontSize(AppSizes.FONT_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row().width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: AppSizes.PADDING_MD, right: AppSizes.PADDING_MD })
      .backgroundColor(AppColors.BG_CARD)

      // 表单内容
      Scroll() {
        Column() {
          // 1. 选品类 — 卡片包裹，3列Grid铺满
          Column() {
            this.FormLabel('选个品类')
            Grid() {
              ForEach(this.categories, (cat: OrderCategory) => {
                GridItem() {
                  Column() {
                    Text(CATEGORY_INFO[cat]?.icon ?? '')
                      .fontSize(28)
                    Text(CATEGORY_INFO[cat]?.label ?? '')
                      .fontSize(AppSizes.FONT_SM)
                      .fontColor(this.selectedCategory === cat ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
                      .fontWeight(this.selectedCategory === cat ? FontWeight.Medium : FontWeight.Normal)
                      .margin({ top: 4 })
                  }
                  .width('100%')
                  .height(68)
                  .justifyContent(FlexAlign.Center)
                  .borderRadius(AppSizes.RADIUS_MD)
                  .backgroundColor(this.selectedCategory === cat ? AppColors.PRIMARY_LIGHT : AppColors.BG_INPUT)
                  .borderWidth(this.selectedCategory === cat ? 1.5 : 0)
                  .borderColor(AppColors.PRIMARY)
                  .onClick(() => { this.selectedCategory = cat })
                }
              }, (cat: OrderCategory) => cat)
            }
            .columnsTemplate('1fr 1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)
            .width('100%')
            .height(156)
          }
          .width('100%')
          .padding(AppSizes.PADDING_MD)
          .borderRadius(AppSizes.RADIUS_MD)
          .backgroundColor(AppColors.BG_CARD)
          .margin({ bottom: AppSizes.PADDING_SM })

          // 2. 店名/商品名 + 目标
          Column() {
            this.FormLabel('店名 / 商品名')
            TextInput({ placeholder: '如：沙县小吃（学校北门）', text: this.title })
              .onChange((value: string) => { this.title = value })
              .height(48)
              .borderRadius(AppSizes.RADIUS_SM)
              .backgroundColor(AppColors.BG_INPUT)
              .padding({ left: 14, right: 14 })
              .width('100%')
              .margin({ bottom: AppSizes.PADDING_MD })

            this.FormLabel('拼单目标')
            Row() {
              this.TargetOption('凑金额', TargetType.AMOUNT)
              this.TargetOption('凑人数', TargetType.COUNT)
            }
            .width('100%')
            .margin({ bottom: 10 })

            Row() {
              TextInput({
                placeholder: this.targetType === TargetType.AMOUNT ? '如：30' : '如：4',
                text: this.targetValue
              })
                .onChange((value: string) => { this.targetValue = value })
                .type(InputType.Number)
                .height(48)
                .borderRadius(AppSizes.RADIUS_SM)
                .backgroundColor(AppColors.BG_INPUT)
                .padding({ left: 14, right: 14 })
                .layoutWeight(1)

              Text(this.targetType === TargetType.AMOUNT ? '元起送' : '人成团')
                .fontSize(AppSizes.FONT_MD)
                .fontColor(AppColors.TEXT_SECONDARY)
                .margin({ left: 10 })
            }
            .width('100%')
            .margin({ bottom: AppSizes.PADDING_MD })

            this.FormLabel('备注（选填）')
            TextInput({ placeholder: '如：北门取，大概30分钟到', text: this.note })
              .onChange((value: string) => { this.note = value })
              .height(48)
              .borderRadius(AppSizes.RADIUS_SM)
              .backgroundColor(AppColors.BG_INPUT)
              .padding({ left: 14, right: 14 })
              .width('100%')
          }
          .width('100%')
          .padding(AppSizes.PADDING_MD)
          .borderRadius(AppSizes.RADIUS_MD)
          .backgroundColor(AppColors.BG_CARD)
          .margin({ bottom: AppSizes.PADDING_SM })

          // 3. 我先点
          Column() {
            this.FormLabel('我先点')
            ForEach(this.myItems, (item: ItemInput, index: number) => {
              Row() {
                TextInput({ placeholder: '商品名', text: item.name })
                  .onChange((value: string) => {
                    this.myItems[index] = { name: value, price: this.myItems[index].price }
                  })
                  .height(44)
                  .borderRadius(AppSizes.RADIUS_SM)
                  .backgroundColor(AppColors.BG_INPUT)
                  .padding({ left: 14, right: 14 })
                  .layoutWeight(3)

                Text('¥')
                  .fontSize(AppSizes.FONT_LG)
                  .fontColor(AppColors.TEXT_HINT)
                  .margin({ left: 10, right: 4 })

                TextInput({ placeholder: '价格', text: item.price })
                  .onChange((value: string) => {
                    this.myItems[index] = { name: this.myItems[index].name, price: value }
                  })
                  .type(InputType.NUMBER_DECIMAL)
                  .height(44)
                  .borderRadius(AppSizes.RADIUS_SM)
                  .backgroundColor(AppColors.BG_INPUT)
                  .padding({ left: 14, right: 14 })
                  .layoutWeight(1)

                if (this.myItems.length > 1) {
                  Text('✕')
                    .fontSize(18)
                    .fontColor(AppColors.DANGER)
                    .margin({ left: 10 })
                    .onClick(() => {
                      this.myItems.splice(index, 1)
                      this.myItems = [...this.myItems]
                    })
                }
              }
              .width('100%')
              .margin({ bottom: 10 })
            }, (_item: ItemInput, index: number) => `item_${index}_${this.myItems.length}`)

            // 添加更多
            Row() {
              Text('＋')
                .fontSize(16)
                .fontColor(AppColors.PRIMARY)
                .margin({ right: 4 })
              Text('再加一样')
                .fontSize(AppSizes.FONT_MD)
                .fontColor(AppColors.PRIMARY)
            }
            .width('100%')
            .height(44)
            .justifyContent(FlexAlign.Center)
            .borderRadius(AppSizes.RADIUS_SM)
            .borderWidth(1)
            .borderColor(AppColors.PRIMARY)
            .borderStyle(BorderStyle.Dashed)
            .onClick(() => {
              this.myItems = [...this.myItems, { name: '', price: '' }]
            })
          }
          .width('100%')
          .padding(AppSizes.PADDING_MD)
          .borderRadius(AppSizes.RADIUS_MD)
          .backgroundColor(AppColors.BG_CARD)
          .margin({ bottom: AppSizes.PADDING_SM })

          // 4. AA方式
          Column() {
            this.FormLabel('AA方式')
            Row() {
              this.SplitOption('按实际消费', SplitMode.BY_ITEM)
              this.SplitOption('均摊', SplitMode.EQUAL)
              this.SplitOption('我请客', SplitMode.TREAT)
            }
            .width('100%')

            // 配送费（仅按实际时显示）
            if (this.splitMode === SplitMode.BY_ITEM) {
              Row() {
                Text('配送费等杂费')
                  .fontSize(AppSizes.FONT_MD)
                  .fontColor(AppColors.TEXT_SECONDARY)

                Blank()

                Text('¥')
                  .fontSize(AppSizes.FONT_MD)
                  .fontColor(AppColors.TEXT_HINT)
                  .margin({ right: 4 })

                TextInput({ placeholder: '0', text: this.extraFee })
                  .onChange((value: string) => { this.extraFee = value })
                  .type(InputType.NUMBER_DECIMAL)
                  .height(40)
                  .width(80)
                  .borderRadius(AppSizes.RADIUS_SM)
                  .backgroundColor(AppColors.BG_INPUT)
                  .padding({ left: 14, right: 14 })
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .margin({ top: 12 })
            }
          }
          .width('100%')
          .padding(AppSizes.PADDING_MD)
          .borderRadius(AppSizes.RADIUS_MD)
          .backgroundColor(AppColors.BG_CARD)
          .margin({ bottom: AppSizes.PADDING_SM })

          // 5. 发起按钮
          Button('发起拼单')
            .width('100%')
            .height(50)
            .fontSize(AppSizes.FONT_LG)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isFormValid() ? AppColors.TEXT_WHITE : AppColors.DISABLED_TEXT)
            .backgroundColor(this.isFormValid() ? AppColors.PRIMARY : AppColors.DISABLED_BG)
            .borderRadius(AppSizes.RADIUS_LG)
            .margin({ top: AppSizes.PADDING_MD, bottom: 40 })
            .enabled(this.isFormValid())
            .onClick(() => {
              this.submitOrder()
            })
        }
        .width('100%')
        .padding({
          left: AppSizes.PADDING_MD,
          right: AppSizes.PADDING_MD,
          top: AppSizes.PADDING_SM,
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
  FormLabel(text: string) {
    Text(text)
      .fontSize(AppSizes.FONT_LG)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.TEXT_PRIMARY)
      .margin({ bottom: 10 })
  }

  @Builder
  TargetOption(label: string, type: TargetType) {
    Row() {
      Radio({ value: type, group: 'target' })
        .checked(this.targetType === type)
        .onChange((isChecked: boolean) => {
          if (isChecked) this.targetType = type
        })
      Text(label)
        .fontSize(AppSizes.FONT_MD)
        .fontColor(this.targetType === type ? AppColors.TEXT_PRIMARY : AppColors.TEXT_SECONDARY)
        .fontWeight(this.targetType === type ? FontWeight.Medium : FontWeight.Normal)
        .margin({ left: 4 })
    }
    .margin({ right: 24 })
  }

  @Builder
  SplitOption(label: string, mode: SplitMode) {
    Column() {
      Text(label)
        .fontSize(AppSizes.FONT_MD)
        .fontColor(this.splitMode === mode ? AppColors.TEXT_WHITE : AppColors.TEXT_SECONDARY)
    }
    .height(36)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
    .borderRadius(18)
    .backgroundColor(this.splitMode === mode ? AppColors.PRIMARY : AppColors.BG_INPUT)
    .margin({ right: 8 })
    .onClick(() => { this.splitMode = mode })
  }

  private isFormValid(): boolean {
    if (!this.title.trim()) return false
    if (!this.targetValue.trim()) return false
    const target = Number(this.targetValue)
    if (isNaN(target) || target <= 0) return false
    // 至少一个选品有效
    for (const item of this.myItems) {
      if (item.name.trim() && item.price.trim()) {
        const price = Number(item.price)
        if (!isNaN(price) && price > 0) return true
      }
    }
    return false
  }

  private submitOrder(): void {
    const orderId = generateId()
    const now = Date.now()

    // 构建选品列表
    const items: OrderItem[] = []
    for (const item of this.myItems) {
      if (item.name.trim() && item.price.trim()) {
        const price = Number(item.price)
        if (!isNaN(price) && price > 0) {
          items.push({
            id: generateId(),
            orderId: orderId,
            userId: CURRENT_USER_ID,
            userName: CURRENT_USER_NAME,
            itemName: item.name.trim(),
            price: price,
            createdAt: now
          })
        }
      }
    }

    const order: GroupOrder = {
      id: orderId,
      category: this.selectedCategory,
      title: this.title.trim(),
      creatorId: CURRENT_USER_ID,
      creatorName: CURRENT_USER_NAME,
      targetType: this.targetType,
      targetValue: Number(this.targetValue),
      splitMode: this.splitMode,
      extraFee: Number(this.extraFee) || 0,
      note: this.note.trim(),
      status: OrderStatus.GATHERING,
      items: items,
      createdAt: now,
      updatedAt: now
    }

    // 持久化存储
    OrderStore.getInstance().addOrder(order)

    // 跳转到详情页
    try {
      const p = new DetailParam()
      p.orderId = order.id
      p.newOrder = order
      router.replaceUrl({ url: 'pages/DetailPage', params: p })
    } catch (e) { /* ignore */ }
  }
}
