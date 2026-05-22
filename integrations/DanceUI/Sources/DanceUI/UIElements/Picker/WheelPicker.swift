// Copyright (c) 2025 ByteDance Ltd. and/or its affiliates
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

internal import DanceUIGraph
internal import DanceUIRuntime

@available(iOS 13.0, *)
internal struct WheelPicker_Phone<A : CustomWheelPickerDataSource> : View {
    

    internal var dataSource: A

    internal var selection: Binding<[A.Rows.Index]>
    
    internal var body: some View {
        UIKitWheelPicker(dataSource: dataSource, selection: selection)
            .modifier(_EnvironmentKeyWritingModifier(keyPath: \.font, value: Font.system(size: 21)))
            .modifier(_EnvironmentKeyWritingModifier(keyPath: \.foregroundColor, value: Color.primary))
            .frame(minWidth: nil, idealWidth: nil, maxWidth: nil, minHeight: nil, idealHeight: nil, maxHeight: 216)
    }
}

@available(iOS 13.0, *)
fileprivate struct UIKitWheelPicker<A : CustomWheelPickerDataSource> : UIViewRepresentable {
    
    fileprivate typealias UIViewType = UIPickerView
    
    fileprivate typealias Coordinator = CoreCoordinator<A>
    
    fileprivate let dataSource: A

    fileprivate var selection: Binding<[A.Rows.Index]>

    fileprivate func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView(frame: .zero)
        picker.delegate = context.coordinator
        return picker
    }
    
    fileprivate func updateUIView(_ uiView: UIPickerView, context: Context) {
        context.coordinator.selection = selection
        if !DGCompareValues(lhs: dataSource, rhs: context.coordinator.dataSource) {
            uiView.reloadAllComponents()
        }
        
        for i in 0 ..< uiView.numberOfComponents {
            let selectedRow = uiView.selectedRow(inComponent: i)
            let index = selection.wrappedValue[i]
            let row = dataSource.rows(in: i).offset(of: index)
            if selectedRow != row {
                uiView.selectRow(row, inComponent: i, animated: context.transaction.animation != nil)
            }
            
        }
        uiView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        uiView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        uiView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)
    }
    
    fileprivate func makeCoordinator() -> Coordinator {
        CoreCoordinator(dataSource: dataSource, selection: selection)
    }
}

@available(iOS 13.0, *)
internal struct WheelPickerRow<Identifier, Cell : View> : CustomWheelPickerRow {
    
    internal var identifier: Identifier

    internal var cell: Cell

}

@available(iOS 13.0, *)
internal protocol CustomWheelPickerRow {
    
    associatedtype Identifier
    
    associatedtype Cell : View
    
    var cell : Cell { get }
}

@available(iOS 13.0, *)
internal protocol CustomWheelPickerDataSource {
    
    associatedtype Rows: Collection where Rows.Element: CustomWheelPickerRow
        
    func rows(in: Int) -> Rows
    
    var columnCount : Int { get }
}

@available(iOS 13.0, *)
extension Collection {
    
    internal func offset(of idx: Index) -> Int {
        distance(from: startIndex, to: idx)
    }
    
    internal func index(atOffset idx: Int) -> Index {
        index(startIndex, offsetBy: idx)
    }
}

@available(iOS 13.0, *)
private final class CoreCoordinator<A : CustomWheelPickerDataSource> : PlatformViewCoordinator, UIPickerViewDelegate, UIPickerViewDataSource {

    fileprivate var dataSource: A

    fileprivate var selection: Binding<[A.Rows.Index]>
    
    fileprivate init(dataSource: A, selection: Binding<[A.Rows.Index]>) {
        self.dataSource = dataSource
        self.selection = selection
    }

    @objc
    fileprivate func numberOfComponents(in pickerView: UIPickerView) -> Int {
        dataSource.columnCount
    }
    
    @objc
    fileprivate func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing: UIView?) -> UIView {
        let rows = dataSource.rows(in: component)
        let pickerCell = rows[rows.index(atOffset: row)].cell
        if let hostingView = reusing as? _UIHostingView<A.Rows.Element.Cell> {
            hostingView.rootView = pickerCell
            return hostingView
        } else {
            return _UIHostingView(rootView: pickerCell)
        }
    }
    
    @objc
    fileprivate func pickerView(_ pickerView: UIPickerView, rowHeightForComponent: Int) -> CGFloat { 30.0 }
    
    @objc
    fileprivate func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent: Int) -> Int {
        dataSource.rows(in: numberOfRowsInComponent).count
    }
    
    @objc
    fileprivate func pickerView(_ pickerView: UIPickerView, didSelectRow: Int, inComponent: Int) {
        let index = dataSource.rows(in: inComponent).index(atOffset: didSelectRow)
        var components = selection.wrappedValue
        components[inComponent] = index
        selection.wrappedValue = components
    }
}
