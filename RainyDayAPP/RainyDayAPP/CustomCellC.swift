import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseMessaging



//(1) プロトコル定義
protocol CustomCellCDelegate {
// senderを受け取るための引数(changeSenderValue)を使う
    
    func changeDatePicker(changeSenderValue:UIDatePicker)
}


class CustomCellC: UITableViewCell {
    //(2)
    var delegate: CustomCellCDelegate?
    
    
    @IBAction func changeDatePicker(_ sender: UIDatePicker) {
        // DatePickerを動かすたび、呼ばれる
        // sender(選択時刻)をchangeSenderValueが受け取り実行
        
        delegate?.changeDatePicker(changeSenderValue: sender)
        print("changeDatePicker()実行")
    }
}
