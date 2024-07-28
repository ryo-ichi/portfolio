/* eslint-disable no-case-declarations */
/* eslint-disable max-len */
/* eslint-disable require-jsdoc */
/* eslint-disable no-undef */
/* eslint-disable no-var */
/* eslint-disable quotes */


const {onValueWritten} = require("firebase-functions/v2/database"); // database.jsから機能を格納
const {onMessagePublished} = require('firebase-functions/v2/pubsub');
const admin = require("firebase-admin");
const {google} = require('googleapis');
var serviceAccount = require("./firebaseAdminSDK.json"); // requireでファイルインポート
const {logger} = require("firebase-functions"); // ログインポート
const axios = require('axios'); // axiosをインポート

// // adminから アクセス権をDBへ与える(データ取得のため)
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://rainydayappfirebase-8592c-default-rtdb.firebaseio.com"});

var db = admin.database();

const scheduler = google.cloudscheduler('v1');
const project = process.env.GCLOUD_PROJECT;
const location = 'us-central1'; // 変更が必要な場合はここを適宜変更

// userInformationが書き込まれたときトリガー
exports.onWrittenFunctionDefault = onValueWritten("/allDevices/{uid}/userInformation", async (event) => {
  logger.info("トリガーされた");

  var ref = db.ref(`/allDevices/${event.params.uid}/userInformation`);// userInformationから下のデータパス指定
  ref.once('value', async (snapshot) => { // 該当パスのデータ取得
    logger.info(snapshot.val());
    const userId = event.params.uid;
    const userData = snapshot.val(); // ユーザーデータ snapshot型 → any型に変換 データ取得
    logger.info(userId);
    logger.info(userData);

    // Cloud Schedulerを作成
    const client = await google.auth.getClient({
      scopes: ["https://www.googleapis.com/auth/cloud-platform"],
    });
    google.options({auth: client});
    const sanitizedUserId = userId.replace(/[^a-zA-Z\d_-]/g, '').slice(0, 500);
    const jobName = `projects/${project}/locations/${location}/jobs/schedule-${sanitizedUserId}`;
    const pubsubTopic = `projects/${project}/topics/myPubSubTopic`;
    logger.info(jobName);
    logger.info(pubsubTopic);
    const job = {
      name: jobName,
      schedule: '* * * * *', // 毎分
      timeZone: 'JST',
      pubsubTarget: {
        topicName: pubsubTopic,
        data: Buffer.from(JSON.stringify({userId})).toString('base64'), // メッセージデータ作成
      },
    };
    await scheduler.projects.locations.jobs.create({ // awaitがあることでジョブ作成処理が完全に読まれてからこの処理が読まれる
      parent: `projects/${project}/locations/${location}`,
      requestBody: job,
    });
    logger.info(`Scheduler created for user: ${userId}`);
  });
});


// Pub/Subトピックをトリガーにする関数 一つ目の関数から受け取ったユーザー情報をもとに気象情報を取得し、fcmを使ってpush通知を送信。
exports.sendWeatherNotification = onMessagePublished(`projects/${project}/topics/myPubSubTopic`, async (event) => {
  const messageData = event.data.message; // トピックのメッセージデータを取得(userID)
  const pubsubData = JSON.parse(Buffer.from(messageData.data, 'base64').toString('utf-8')); // データ形式変換
  const userId = pubsubData.userId; // トークンをuserIdへ格納
  const apiKey = 'aaf4b72a20ac58ffb2495f80071aca39';

  logger.info('sendWeatherNotification実行');
  logger.info(messageData);
  logger.info(`メッセージデータ: ${userId}`);

  const locationData = await getLocation(userId); // 都市名を渡す
  const setTimeData = await getSetTime(userId); // 設定時刻を渡す
  const weatherData = await getWeatherData(locationData, apiKey); // 気象IDを渡す
  const fcmToken = await getFcmToken(userId); // トークンを渡す

  // FCM通知の送信データ作成
  const message = {
    token: fcmToken,
    notification: {
      title: '今日は雨です',
      body: '傘を持参しましょう！低気圧なので体調に気をつけてください',
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: '今日は雨です',
            body: '傘を持参しましょう！低気圧なので体調に気をつけてください',
          },
          sound: 'default',
        },
      },
    },
  };

  weatherNotification(weatherData, message, setTimeData); // 3つの引数がnilでないとき実行
});


async function getWeatherData(locationData, apiKey) {
  const apiUrl = `http://api.openweathermap.org/data/2.5/weather?q=${locationData}&appid=${apiKey}&units=metric&lang=ja`;
  try {
    const response = await axios.get(apiUrl);
    logger.info(response.data);// {"base":"stations", "clouds":{…}, "cod":200, "coord":{…}, "dt":1.720771818E9, "id":1861060, "main":{…}, "name":"日本", "rain":{…}, "sys":{…}, "timezone":32400, "visibility":10000, "weather":[…], "wind":{…}}
    logger.info(`weatherID: ${response.data.weather[0].id}`);// 520
    const weatherID = response.data.weather[0].id;
    return weatherID;
  } catch (error) {
    if (error.response) {
      logger.info('APIリクエストが失敗しました。ステータスコード:', error.response.status);
      logger.info('エラーメッセージ:', error.response.data);
      if (error.response.status === 401) {
        logger.info('APIキーが無効である可能性があります。');
      }
    } else {
      logger.info('リクエストの送信中にエラーが発生しました:', error.message);
    }
  }
}


// DB 都市名 取得 nillで処理中断
async function getLocation(userId) {
  var locationRef = db.ref(`/allDevices/${userId}/userInformation/都市名`);
  const locationSnapshot = await locationRef.once('value');
  const locationData = locationSnapshot.val();

  if (locationData === null || locationData === undefined) {
    throw new Error('都市名が存在しません');
  }
  logger.info(`locationData: ${locationData}`);
  return locationData;
}


// DB 設定時刻 取得 nillで処理中断
async function getSetTime(userId) {
  var setTimeRef = db.ref(`/allDevices/${userId}/userInformation/設定時刻`);
  const setTimeSnapshot = await setTimeRef.once('value');
  const setTimeData = setTimeSnapshot.val();

  if (setTimeData === null || setTimeData === undefined) {
    throw new Error('設定時刻が存在しません');
  }
  logger.info(`setTimeData: ${setTimeData}`);
  return setTimeData;
}


// DB fcmトークン 取得 nillで処理中断
async function getFcmToken(userId) {
  var tokenRef = db.ref(`/allDevices/${userId}/userInformation/fcmToken`);
  const tokenSnapshot = await tokenRef.once('value');
  const fcmToken = tokenSnapshot.val();

  if (fcmToken === null || fcmToken === undefined) {
    throw new Error('FCMトークンが存在しません');
  }
  logger.info(`fcmToken: ${fcmToken}`);
  return fcmToken;
}


// 取得気象IDで通知送信
function weatherNotification(weatherData, message, setTimeData) {
  logger.info(`weatherNotification実行`);
  const now = new Date(); // 現時刻
  const setTime = new Date(setTimeData); // ISO → UTC

  switch (true) {
    case (weatherData >= 200 && weatherData <= 232): // 雷雨 200以上232以下
      if (now.getUTCHours() === setTime.getUTCHours() && now.getUTCMinutes() === setTime.getUTCMinutes()) {
        sendFcmNotification(message); // 通知送信
      }
      break;
    case (weatherData >= 300 && weatherData <= 321): //  霧雨 300以上321以下
      if (now.getUTCHours() === setTime.getUTCHours() && now.getUTCMinutes() === setTime.getUTCMinutes()) {
        sendFcmNotification(message);
      }
      break;
    case (weatherData >= 500 && weatherData <= 531): //  雨 500以上531以下
      if (now.getUTCHours() === setTime.getUTCHours() && now.getUTCMinutes() === setTime.getUTCMinutes()) {
        sendFcmNotification(message);
      }
      break;
    default:
      logger.info(`通知に該当する気象IDではありません`);
  }
}

// 通知をデバイスへ送信
async function sendFcmNotification(message) {
  try {
    const response = await admin.messaging().send(message);
    logger.info('Successfully sent message:', response);
    return response;
  } catch (error) {
    logger.error('Error sending message:', error);
    throw error;
  }
}
