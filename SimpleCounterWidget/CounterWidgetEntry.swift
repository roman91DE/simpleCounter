import SimpleCounterCore
import WidgetKit

struct CounterWidgetEntry: TimelineEntry {
    let date: Date
    let counter: Counter?
    let currentCount: Int
}
