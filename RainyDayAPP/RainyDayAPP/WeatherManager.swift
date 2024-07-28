//
//  WeatherManager.swift
//  RainyDayAPP
//
//  Created by 松原涼一 on 2023/11/14.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseMessaging



protocol AlertDelegateAdd {
    func AlertAdd()
}


// パースしたデータを集約する独自の型を定義
struct WeatherData: Decodable {
    let name:String
    let main: Main
    let weather: [Weather]
    
}

struct Main: Decodable {
    let temp: Double // 気温
}
struct Weather: Decodable {
    let id: Int // 天気状態のID
}


// DBインスタンス
var ref: DatabaseReference! = Database.database().reference()



struct WeatherManager {

    var delegate: AlertDelegateAdd?
    
    // 通信先のURLを作成 URLの元となる雛形を作る tokyoの現在の天気情報をURlを使ってとってくる
    let weatherURL = "https://api.openweathermap.org/data/2.5/weather?&appid=aaf4b72a20ac58ffb2495f80071aca39&units=metric"
    
    func fetchWeather(cityName:String) {
        
        let urlString = "\(weatherURL)&q=\(cityName)"
        
        //URL型へキャスト 以下の実装をメソッド内のクロージャ内で定義しないとエラーとなる
        if let url = URL(string: urlString) {
            // URLSessionをインスタンス化
            let urlSession = URLSession(configuration: .default)
            
            // インスタンスメソッド.dataTask()を呼びurlに該当するデータを取得
            let task = urlSession.dataTask(with: url, completionHandler: { data, response, error in
                //Data型のJSON(data)を出力
                print(data!)
                //Data型のJSONをテキストデータ(textData)へ変換して出力
                let textData = String(data: data!, encoding: .utf8)
                print(textData!)
                
                do {
                    let WeatherData = try JSONDecoder().decode(WeatherData.self, from: data!)
                    let weatherData = ["都市名": WeatherData.name, 
                                       "気温": WeatherData.main.temp,
                                       "気象ID": WeatherData.weather[0].id,
                                       "fcmToken": refToken!]as [String: Any]

                    guard let refToken = refToken else {
                            print("Error: refToken is nil")
                            return
                        }
                    ref.child("allDevices/\(refToken)/userInformation").updateChildValues(weatherData)

                    print(WeatherData.name) //都市名
                    print(WeatherData.main.temp) //気温
                    print(WeatherData.weather[0].id) //気象ID
                    print("リクエスト成功")
                }
                catch {
                    //URLリクエストが失敗するとパースもできないのでcatchが読まれる
                    print("リクエスト失敗\(error)")
                    delegate?.AlertAdd()
                }
            })
            task.resume()
        }
    }
}
