import { GroupOrder, calcProgress, getUniqueUserCount, calcOrderTotal, getProgressText } from '../model/OrderModel'
import { CATEGORY_INFO, STATUS_INFO, OrderStatus, TargetType, AppColors, AppSizes } from '../common/Constants'

@Component
export struct OrderCard {
  @Prop order: GroupOrder
  onCardClick: () => void = () => {}

  build() {
    Column() {
      // 顶部：品类图标 + 标题 + 状态标签
      Row() {
        Column() {
          Text(CATEGORY_INFO[this.order.category]?.icon ?? '📦')
            .fontSize(24)
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .borderRadius(AppSizes.RADIUS_SM)
        .backgroundColor(AppColors.PRIMARY_LIGHT)
        .margin({ right: 12 })

        Column() {
          Text(this.order.title)
            .fontSize(AppSizes.FONT_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Row() {
            Text(`${this.order.creatorName}`)
              .fontSize(AppSizes.FONT_SM)
              .fontColor(AppColors.TEXT_SECONDARY)
            Text(` · ${this.getTimeAgo()}`)
              .fontSize(AppSizes.FONT_SM)
              .fontColor(AppColors.TEXT_HINT)
          }
          .margin({ top: 4 })
        }
        .layoutWeight(1)

        // 状态标签
        Text(STATUS_INFO[this.order.status]?.label ?? '')
          .fontSize(AppSizes.FONT_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor(STATUS_INFO[this.order.status]?.color ?? AppColors.TEXT_HINT)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(AppSizes.RADIUS_SM)
          .backgroundColor(this.getStatusBgColor())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 进度条（仅拼单中/可下单状态显示）
      if (this.order.status === OrderStatus.GATHERING || this.order.status === OrderStatus.READY) {
        Column() {
          Row() {
            Text(`${getUniqueUserCount(this.order)}人参与`)
              .fontSize(AppSizes.FONT_SM)
              .fontColor(AppColors.TEXT_SECONDARY)

            Text(` · ¥${calcOrderTotal(this.order).toFixed(0)}`)
              .fontSize(AppSizes.FONT_SM)
              .fontColor(AppColors.TEXT_SECONDARY)

            Blank()

            Text(getProgressText(this.order))
              .fontSize(AppSizes.FONT_SM)
              .fontColor(this.isTargetMet() ? AppColors.SUCCESS : AppColors.PRIMARY)
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')

          // 进度条
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(6)
              .borderRadius(3)
              .backgroundColor(AppColors.BG_INPUT)

            Row()
              .width(`${calcProgress(this.order)}%`)
              .height(6)
              .borderRadius(3)
              .backgroundColor(this.isTargetMet() ? AppColors.SUCCESS : AppColors.PRIMARY)
          }
          .width('100%')
          .height(6)
          .margin({ top: 8 })
        }
        .margin({ top: 12 })
      }

      // 已完成状态：显示总价和人数
      if (this.order.status === OrderStatus.COMPLETED) {
        Row() {
          Text(`${getUniqueUserCount(this.order)}人参与`)
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_HINT)

          Text(` · ¥${calcOrderTotal(this.order).toFixed(0)}`)
            .fontSize(AppSizes.FONT_SM)
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('100%')
        .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding(AppSizes.PADDING_MD)
    .borderRadius(AppSizes.RADIUS_MD)
    .backgroundColor(AppColors.BG_CARD)
    .shadow({
      radius: 6,
      color: 'rgba(0,0,0,0.06)',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => this.onCardClick())
  }

  private isTargetMet(): boolean {
    if (this.order.targetType === TargetType.COUNT) {
      return getUniqueUserCount(this.order) >= this.order.targetValue
    }
    return calcOrderTotal(this.order) >= this.order.targetValue
  }

  private getStatusBgColor(): string {
    const status = this.order.status
    if (status === OrderStatus.GATHERING) return AppColors.PRIMARY_LIGHT
    if (status === OrderStatus.READY || status === OrderStatus.ARRIVED) return '#E8F5E9'
    if (status === OrderStatus.ORDERED) return '#E3F2FD'
    if (status === OrderStatus.CANCELLED) return '#FFEBEE'
    return '#F5F5F5'
  }

  private getTimeAgo(): string {
    const diff = Date.now() - this.order.createdAt
    const minutes = Math.floor(diff / 60000)
    if (minutes < 1) return '刚刚'
    if (minutes < 60) return `${minutes}分钟前`
    const hours = Math.floor(minutes / 60)
    if (hours < 24) return `${hours}小时前`
    const days = Math.floor(hours / 24)
    return `${days}天前`
  }
}
