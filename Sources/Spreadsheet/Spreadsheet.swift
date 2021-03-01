import Foundation


public class Spreadsheet {
    /// 1 ... count
    public typealias Axis = Int

    public struct Coordinate {
        let row : Axis
        let col : Axis
    }
    struct Cell {
        let value:Any?

        init() {
            self.value = nil
        }
        init(with value:Any?) {
            self.value = value
        }

        func asString() -> String {
            guard let value = self.value else { return "" }
            if let string = value as? String {
                return string
            }
            if let number = value as? NSNumber {
                return number.stringValue
            }
            return String(describing: value)
        }

        /// this should do stuff with quotes and tabs...
        func asCSV() -> String {
            return self.asString()
        }
    }
    class Row {
        var cells = [Cell]()

        init(with cols:Axis) {
            self.cells = [Cell](repeating: Cell(), count: cols)
        }

        func expand(toColCount c:Int) {
            if self.cells.count < c {
                let addition = [Cell](repeating: Cell(), count: c - self.cells.count)
                self.cells.append(contentsOf: addition)
            }
        }

        func assign(value:Any?, atColumn col:Axis) {
            self.cells[col-1] = Cell(with: value)
        }

        func asCSV() -> String {
            let cols = self.cells.map { (cell) -> String in
                return cell.asCSV()
            }
            return cols.joined(separator: "\t")
        }
    }
    var rows = [Row]()
    var cols:Int = 0

    public convenience init(withRowCount r:Int, andColCount c:Int) {
        self.init()
        self.expand(toColCount: c)
        self.expand(toRowCount: r)
    }

    public func expand(toRowCount r:Int) {
        while self.rows.count < r {
            self.rows.append(Row(with: self.cols))
        }
    }

    public func expand(toColCount c:Int) {
        if c > self.cols {
            self.cols = c
            self.rows.forEach { (row) in
                row.expand(toColCount: c)
            }
        }
    }
    
    public func fetch(_ from:Coordinate) -> Any? {
        let r = from.row - 1
        if (0 ..< self.rows.count).contains(r) {
            let row = self.rows[r]
            let c = from.col - 1
            if (0 ..< row.cells.count).contains(c) {
                let cell = row.cells[c]
                return cell.value
            }
        }
        return nil
    }
    
    public func assign(value:Any?, at:Coordinate) {
        self.assign(value: value, atRow: at.row, andColumn: at.col)
    }

    public func assign(value:Any?, atRow row:Axis, andColumn col:Axis) {
        self.expand(toColCount: col)
        self.expand(toRowCount: row)
        self.rows[row-1].assign(value: value, atColumn: col)
    }

    public func assign(header:String, value:Any?, atColumn col:Axis, withRow row:Axis = .minimum) -> Axis {
        self.assign(value: header, atRow: row, andColumn: col)
        self.assign(value: value, atRow: row + 1, andColumn: col)
        return col + 1
    }

    public func assign(header:String, values:[Any], atColumn col:Axis, withRow row:Axis = .minimum) -> Axis {
        self.assign(value: header, atRow: row, andColumn: col)

        var off = 1
        values.forEach { (value) in
            self.assign(value: value, atRow: row + off, andColumn: col)
            off += 1
        }
        return col + 1
    }

    public func assign(headers:[String], atColumn col:Axis) -> Axis {
        var at = col
        headers.forEach { (header) in
            self.assign(value: header, atRow: .minimum, andColumn: at)
            at += 1
        }
        return at
    }

    public func assign(label:String, value:Any, atRow row:Axis) -> Axis {
        self.assign(value: label, atRow: row, andColumn: .minimum)
        self.assign(value: value, atRow: row, andColumn: .minimum + 1)
        return row + 1
    }

    public func asCSV() -> String {
        let lines = self.rows.map { (row) -> String in
            return row.asCSV()
        }
        return lines.joined(separator: "\n")
    }
}

extension Spreadsheet.Axis {
    /// the minimum row or col
    public static let minimum:Spreadsheet.Axis = 1

    public static func row(_ r:String) -> Spreadsheet.Axis {

        let floor = Spreadsheet.Axis(Character("A").asciiValue!)
        let base = 26
        var power = 1

        let value:Spreadsheet.Axis = r.uppercased().reversed().reduce(Spreadsheet.Axis.minimum) { (sum, ch) -> Spreadsheet.Axis in
            guard ch.isASCII, let raw = ch.asciiValue else { return sum }
            let value = Spreadsheet.Axis(raw) - floor
            guard (0 ..< base).contains(value) else { return sum }

            let result = sum + (value * power)
            power *= base
            return result
        }

        return value
    }
}

