import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseMessaging


class SettingViewController: UIViewController,
                             UITableViewDelegate,
                             UITableViewDataSource {

    var timeLabelValue: String? = "未設定" //timeLabelの初期値とする要素
    var locationLabelValue: String? = "未設定" //LocationLabelの初期値とする要素
    var selectedDateTimeValue = "00:00:00" // Pickerの初期時刻
    let now = Date()


    @IBOutlet weak var tableView: UITableView!
    @IBAction func cancelButton(_ sender: Any) {


        ref.child("allDevices/\(refToken!)/userInformation").removeValue() // DB全削除
        self.locationLabelValue = "未設定"
        self.timeLabelValue = "未設定"
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // DBからデータ取得 ラベルへ保持　更新
        getLocationDataDB()
        print("getSetTimeDataDB()が呼ばれた\(getSetTimeDataDB())")
        weatherManager.delegate = self // selfはSettingViewControllerのこと

        //表示するセルの登録
        //CellA
        tableView.register(UINib(nibName: "CustomCellA", bundle: nil), forCellReuseIdentifier: "customCellA")

        //CellB
        tableView.register(UINib(nibName: "CustomCellB", bundle: nil), forCellReuseIdentifier: "customCellB")

        //CellC
        tableView.register(UINib(nibName: "CustomCellC", bundle: nil), forCellReuseIdentifier: "customCellC")
    }

    //セルの数を設定
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    //セル表示 行が偶数奇数でセル出し分け Pathに該当するセルを返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var identifier: String

        switch indexPath {
            // indexPath型の値の形式[0, 0]
        case [0, 0] :
            identifier = "customCellA"
        case [0, 1] :
            identifier = "customCellB"
        case [0, 2] :
            identifier = "customCellC"

        default: identifier = "Fetch failed Cell"
        }

        if identifier == "customCellA" {
            guard let cellA = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? CustomCellA else {
                return UITableViewCell()
            }
            cellA.delegateAlert = self
            cellA.manager?.delegate = self
            cellA.LocationLabel.text = self.locationLabelValue
            cellA.delegateTapAction = self // API通信で使用インスタンス(cellA)


            return cellA

        } else if identifier == "customCellB" {
            guard let cellB = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? CustomCellB else {
                return UITableViewCell()
            }
            //cellBに適当な変数に一度入れてその値をtimeLabel.textにいれてから更新
            cellB.delegate = self
            cellB.timeLabel.text = self.timeLabelValue
            print("timeLabelValueは\(timeLabelValue!)です")
            return cellB

        } else if identifier == "customCellC" {
            guard let cellC = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? CustomCellC else {
                return UITableViewCell()
            }
            cellC.delegate = self
            return cellC

        } else {
            return UITableViewCell()
        }
    }

    // 個別のセルに対して固定サイズを指定
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < 2 { //　Pathが2よりも小さいとき、80にする
            return 80
        } else {
            return 250 // 2よりも大きいとき、250
        }
    }

    // DBから都市データ取得 ラベルへ保持
    func getLocationDataDB() {
        guard let refToken = refToken else {
                print("Error: refToken is nil")
                return
            }
        ref.child("allDevices/\(refToken)/userInformation").observe(.value, with: { snapshot in

            // 観測されたDatasnapShot型のデータのまとまり(定数snaphot)を出力
            print("snapshot内のデータは\(snapshot)です")

            //.valueはタプルに指定できるプロパティ　snapshotの値を受け取りAny型データを返す
            //.valueを指定して返されたAny型データはタプルとしてanySnapshotへ保持
            // DataSnapshot型にAny型は代入不可(逆は可能)
            if let anySnapshotTuple = snapshot.value {
                //Anyから辞書[String:Any]へダウンキャスト
                let anyDictionary = anySnapshotTuple as? [String:Any]
                var locationData = anyDictionary?["都市名"] //DBデータ取得

                //locationDataがnilのときだけ、この処理が読まれる nil以外スル-
                if locationData == nil {
                    locationData = "未設定"
                } else {
                    self.locationLabelValue = locationData as? String // Stringにダウン
                    self.tableView.reloadData()
                }
            }
        })
    }

    // viewDidLoad()実行後 DBからデータ取得とテーブル/ラベル更新
    func getSetTimeDataDB() {
        guard let refToken = refToken else {
                print("Error: refToken is nil")
                return
            }

        ref.child("allDevices/\(refToken)/userInformation").observe(.value, with: { [self]snapshot in

            if let anySnapshotTuple = snapshot.value {
                //Anyから辞書[String:Any]へダウンキャスト
                let anyDictionary = anySnapshotTuple as? [String:Any]
                let setTimeDate = anyDictionary?["設定時刻"] //設定時刻からデータ取得
                var displayTimeDate = anyDictionary?["表示時刻"]
                // nilのとき
                if setTimeDate == nil {
                    displayTimeDate = "未設定"
                }
                // nil以外のとき
                self.timeLabelValue = displayTimeDate as? String // DB取得データをラベルへ保持
            }
        })
    }
}
extension SettingViewController: CustomCellADelegate {
    func textFieldShouldReturnAction() {
        self.locationLabelValue = "未入力"
        //特定のセル更新 row:0はcellAのみ更新
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
}

// 初動 Pikcerを動かさなかった場合 タップ後に
extension SettingViewController: CustomCellBDelegate {
    func addTapAction() {

        //初回タップ前 時刻未設定のとき
        let formatter1 = ISO8601DateFormatter()
        formatter1.formatOptions = .withFullDate
        formatter1.timeZone = TimeZone(abbreviation: "JST")
        let yearAndDateValue = formatter1.string(from: now)
        print(yearAndDateValue) // 2024-00-00


        let iso8610StringDate = "\(yearAndDateValue)T\(selectedDateTimeValue)+09:00"
        print(iso8610StringDate)// 2024-00-00T00:00:00+09:00

        let setTime = ["設定時刻": "\(iso8610StringDate)"]
        ref.child("allDevices/\(refToken!)/userInformation").updateChildValues(setTime) //設定時刻保存
        print(setTime)//23:00:00


        let displayTime = ["表示時刻": "\(selectedDateTimeValue)"]
        print(selectedDateTimeValue)//00:00:00
        ref.child("allDevices/\(refToken!)/userInformation").updateChildValues(displayTime)

        // デバイストークン保存
        let fcmToken = ["fcmToken": "\(refToken!)"]
        ref.child("allDevices/\(refToken!)/userInformation").updateChildValues(fcmToken)


        self.timeLabelValue = selectedDateTimeValue
        //特定のセル更新 row:0はcellAのみ更新
        let indexPath = IndexPath(row: 1, section: 0)
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
}
extension SettingViewController: CustomCellCDelegate {
    //ピッカーが動くと実行 動かないとフォーマットもされない senderを受け取り実行 Date型 → String型 labelに保持
    func changeDatePicker(changeSenderValue: UIDatePicker) {

        let formatter1 = ISO8601DateFormatter()
        formatter1.formatOptions = .withFullDate
        formatter1.timeZone = TimeZone(abbreviation: "JST")
        let yearAndDateValue = formatter1.string(from: now)
        print("yearAndDateValueは\(yearAndDateValue)") // 2024-00-00


        let formatter = ISO8601DateFormatter()
        selectedDateTimeValue = formatter.string(from: changeSenderValue.date)
        if let JST = TimeZone(abbreviation: "JST") { // (JST)
            var options: ISO8601DateFormatter.Options = [
                .withInternetDateTime,
                .withDashSeparatorInDate,
                .withColonSeparatorInTime,
                .withColonSeparatorInTimeZone]
            options.remove([
                .withYear, // 西暦 削除
                .withMonth, // 月 削除
                .withDay, // 日 削除
                .withTimeZone // +09:00 削除
            ])
            selectedDateTimeValue = ISO8601DateFormatter.string(from: changeSenderValue.date,
                                                                timeZone: JST,formatOptions: options)

            print("selectedDateTimeValueは\(selectedDateTimeValue)") //  JST 01:00:00+09:00
            let iso8610StringDate = "\(yearAndDateValue)T\(selectedDateTimeValue)+09:00"
            print(iso8610StringDate) //2024-00-00T00:00:00+09:00
        }
    }
}


extension SettingViewController: AlertDelegate {
    func Alert() {
        let alert = UIAlertController(title: "エラー", message: "英語で都市名を入力してください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}

extension SettingViewController: AlertDelegateAdd {
    func AlertAdd() {
        DispatchQueue.main.sync {
            let alert = UIAlertController(title: "エラー", message: "不明な都市名です。 通知を送れません", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
