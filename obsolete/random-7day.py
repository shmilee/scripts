import random
import datetime
import calendar
import sys

def select_random_dates(year=None, month=None, num=7):
    """
    从指定年份和月份中随机选取不重复的日期（默认为当前月）。

    参数:
        year (int, optional): 年份。若为 None 则使用当前年份。
        month (int, optional): 月份（1-12）。若为 None 则使用当前月份。
        num (int): 需要选取的天数，默认为 7。

    返回:
        list[datetime.date]: 选中的日期列表（已排序）。
    """
    # 如果没有提供年月，则使用当前日期
    if year is None or month is None:
        today = datetime.date.today()
        year = year if year is not None else today.year
        month = month if month is not None else today.month

    # 校验月份范围
    if not (1 <= month <= 12):
        raise ValueError(f"月份必须介于 1 到 12 之间，传入值为 {month}")

    # 获取该月的总天数
    _, days_in_month = calendar.monthrange(year, month)

    # 若请求的天数大于当月天数，自动调整为当月天数（一般不会发生，因为最少28天>7）
    if num > days_in_month:
        print(f"警告：请求 {num} 天，但 {year}年{month}月只有 {days_in_month} 天，将选取全部日期。")
        num = days_in_month

    # 生成该月所有日期列表
    all_dates = [datetime.date(year, month, day) for day in range(1, days_in_month + 1)]

    # 随机抽取不重复的日期
    selected = random.sample(all_dates, num)

    # 按日期升序排序（使输出更整洁）
    selected.sort()
    return selected

def main():
    # 解析命令行参数
    # 用法: python script.py [year month]
    # 示例: python script.py 2025 12
    if len(sys.argv) == 3:
        try:
            year = int(sys.argv[1])
            month = int(sys.argv[2])
        except ValueError:
            print("错误：年份和月份必须是整数。")
            sys.exit(1)
        dates = select_random_dates(year, month)
        print(f"{year}年{month}月 随机选取的 {len(dates)} 天：")
    elif len(sys.argv) == 1:
        dates = select_random_dates()  # 使用当前年月
        today = datetime.date.today()
        print(f"当前月份（{today.year}年{today.month}月）随机选取的 {len(dates)} 天：")
    else:
        print("用法：")
        print("  python script.py                # 随机选取当前月份的7天")
        print("  python script.py 年份 月份       # 随机选取指定年月的7天")
        sys.exit(1)

    # 输出日期
    for d in dates:
        print(d.strftime("%Y-%m-%d"), end=' ')
    print()

if __name__ == "__main__":
    main()