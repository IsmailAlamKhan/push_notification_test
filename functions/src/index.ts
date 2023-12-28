import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

exports.sendPushNotify = functions.https.onRequest((request, response) => {
  const topic = request.body.topic;
  const title = request.body.title;
  const message = request.body.message;
  const data = request.body.data;
  if (!topic) {
    response.send({
      result: "Error!! You need to specify a topic.",
      data: null,
    });
    return;
  }

  const payload = {
    topic,
    notification: {
      title,
      body: message,
    },
    data,
  };

  admin
    .messaging()
    .send(payload)
    .then((res) => {
      functions.logger.info("res: " + res);
      response.send({
        result: "Success!! The notification has been sent.",
        data: res,
      });
    })
    .catch((err) => {
      functions.logger.info("err: " + err);
      response.send({
        result: "Error!! The notification has not been sent.",
        data: err,
      });
    });
});
