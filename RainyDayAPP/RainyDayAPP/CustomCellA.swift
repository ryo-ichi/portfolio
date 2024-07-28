//
//  CustomCellA.swift
//  Rainy Day APP
//
//  Created by 松原涼一 on 2023/09/01.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseMessaging


protocol AlertDelegate {
    func Alert()
}

protocol CustomCellADelegate {
    func textFieldShouldReturnAction()
}

var weatherManager = WeatherManager()

// TextField 入力時の完了通知を受け取るためにdelegateを追加
class CustomCellA: UITableViewCell,UITextFieldDelegate {


    @IBOutlet weak var LocationLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    var delegateAlert: AlertDelegate?
    var manager: WeatherManager?
    var delegateTapAction: CustomCellADelegate?

    // 入力文字制限
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count > 0 {
            // 入力可能な文字の制限
            let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
            // 変数には入力可能該当文字(allowedCharacters)のみ入れられる トリミングする
            let unwantedStr = string.trimmingCharacters(in: allowedCharacters)

            // トリミング後 変数unwantedStr内に文字残っている/残っていない 処理分岐
            if unwantedStr.count == 0 { // 0は残っていない
                return true
            } else {
                delegateAlert?.Alert() // デリゲートメソッド
                print("該当しない入力値です")
                return false
            }
        } else {
            return true
        }
    }

    // 検索ボタンが押された時の処理 guardでフィルターをかける 入力文字textField.text
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // 入力文字(.text)がnilでないときcityNameへ保持
        guard let cityName = textField.text else {
            return false // nilときfalseで中断
        }
        // cityNameはラベルに保持する値を一時的に保持 入力文字が""の場合 2回目以降は""が入っている
        if cityName.isEmpty{
            print("if文実行")
            delegateTapAction?.textFieldShouldReturnAction()

            //DB 該当部分削除
            ref.child("allDevices/\(refToken!)/userInformation/都市名").removeValue()
            ref.child("allDevices/\(refToken!)/userInformation/気象ID").removeValue()
            ref.child("allDevices/\(refToken!)/userInformation/気温").removeValue()

            // cityNameが都市名の場合
        } else {
            print("else文実行")
            // 検索ボタンタップ後 API通信が行われる処理 API通信が行われる
            print("cityNameは\(cityName)です")
            weatherManager.fetchWeather(cityName: cityName)
            textField.text = ""

            // キーボード閉じる
            textField.resignFirstResponder()
        }
        return true
    }
}
